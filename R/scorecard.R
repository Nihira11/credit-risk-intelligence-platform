# ============================================================================
# Converts a logistic regression (fit on WOE features) into an industry-standard
# points scorecard via PDO scaling, scores applicants, and assigns decision bands
#
# Metric functions (Gini/KS/AUC) live in model_utils.R - not duplicated here
# ============================================================================

library(dplyr)
library(tidyr)

# 1. scaling params (PDO method)
# score = Offset + Factor * ln(odds_good)
#   factor = PDO / ln(2)
#   offset = base_score - Factor * ln(base_odds)
# higher score => lower default risk (like FICO)
make_scaling <- function(base_score = 600, base_odds = 50, pdo = 20) {
  factor <- pdo / log(2)
  offset <- base_score - factor * log(base_odds)
  list(
    base_score = base_score,
    base_odds  = base_odds,
    pdo        = pdo,
    factor     = factor,
    offset     = offset
  )
}

# 2. normalise woe_bins into a tidy table
# accepts the scorecard::woebin() output, which is either a list of
# data.frames (one per variable) or a single combined data.frame/data.table
# returns a tidy table with at least: variable, bin, woe
tidy_woe_bins <- function(woe_bins) {
  if (is.data.frame(woe_bins)) {
    bins <- as.data.frame(woe_bins)
  } else if (is.list(woe_bins)) {
    bins <- dplyr::bind_rows(lapply(woe_bins, as.data.frame))
  } else {
    stop("woe_bins must be a data.frame or a list of data.frames")
  }
  
  required <- c("variable", "bin", "woe")
  missing  <- setdiff(required, names(bins))
  if (length(missing) > 0) {
    stop("woe_bins is missing required columns: ", paste(missing, collapse = ", "))
  }
  
  bins %>%
    dplyr::select(
      variable, bin, woe,
      dplyr::any_of(c("count", "count_distr", "badprob", "bin_iv", "total_iv"))
    )
}

# 3. build the bin-level points card
# for each (feature, bin):
#   points = base_points_per_feature - Factor * beta_i * WOE_bin
# where base_points_per_feature = (Offset - Factor * intercept) / n_features
# summing the points of an applicant's matched bins reproduces their score
#
# model_coefs: named numeric from coef(glm); feature names like "days_employed_woe"
# woe_bins:    scorecard::woebin() output (variable names typically WITHOUT _woe)
build_scorecard <- function(model_coefs, woe_bins, scaling) {
  bins <- tidy_woe_bins(woe_bins)
  
  intercept <- model_coefs[["(Intercept)"]]
  betas     <- model_coefs[names(model_coefs) != "(Intercept)"]
  
  # drop aliased/NA coefficients (collinear features R could not estimate)
  betas  <- betas[!is.na(betas)]
  n_feat <- length(betas)
  
  coef_df <- tibble::tibble(
    coef_name = names(betas),
    beta      = as.numeric(betas)
  )
  
  # map coefficient names to bin variable names. Detect whether the WOE suffix
  # needs stripping by checking which mapping overlaps the bins table
  bin_vars <- unique(bins$variable)
  stripped <- sub("_woe$", "", coef_df$coef_name)
  
  if (mean(stripped %in% bin_vars) >= mean(coef_df$coef_name %in% bin_vars)) {
    coef_df$variable <- stripped          # bins use raw names (typical)
  } else {
    coef_df$variable <- coef_df$coef_name # bins already carry _woe
  }
  
  base_points_per_feature <- (scaling$offset - scaling$factor * intercept) / n_feat
  
  card <- bins %>%
    dplyr::inner_join(coef_df, by = "variable") %>%
    dplyr::mutate(
      points = round(base_points_per_feature - scaling$factor * beta * woe)
    ) %>%
    dplyr::arrange(variable, woe) %>%
    dplyr::select(
      variable, coef_name, bin, woe, beta, points,
      dplyr::any_of(c("count", "badprob"))
    )
  
  if (nrow(card) == 0) {
    stop("Scorecard join produced 0 rows — model feature names do not match ",
         "woe_bins variable names. Check the _woe suffix convention.")
  }
  
  attr(card, "base_points_per_feature") <- base_points_per_feature
  attr(card, "scaling") <- scaling
  card
}

# 4. score from woe-transformed data (fast, exact)
# when data already holds WOE values (columns ending in _woe), the score is a
# direct linear transform of the model logit - no bin lookup needed, and it is
# guaranteed identical to summing the card's bin points
#   logit  = intercept + sum(beta_i * WOE_i)
#   score  = Offset - Factor * logit   (negative: higher score = lower risk)
score_from_woe <- function(data_woe, model_coefs, scaling, verbose = TRUE) {
  intercept <- model_coefs[["(Intercept)"]]
  betas     <- model_coefs[names(model_coefs) != "(Intercept)"]
  
  # drop aliased/NA coefficients: R sets these to NA for collinear features,
  # and they contribute nothing to the linear predictor
  na_betas <- names(betas)[is.na(betas)]
  if (length(na_betas) > 0 && verbose) {
    message("score_from_woe: dropping ", length(na_betas),
            " feature(s) with NA coefficient (collinear/aliased): ",
            paste(na_betas, collapse = ", "))
  }
  betas <- betas[!is.na(betas)]
  
  feats <- names(betas)
  missing <- setdiff(feats, names(data_woe))
  if (length(missing) > 0) {
    stop("data_woe is missing model features: ", paste(missing, collapse = ", "))
  }
  
  # build the feature matrix defensively: drop tibble/grouping, coerce each
  # column to numeric explicitly, then assemble a plain numeric matrix
  df <- as.data.frame(data_woe)[, feats, drop = FALSE]
  num_list <- lapply(df, function(col) as.numeric(as.character(col)))
  X <- matrix(unlist(num_list, use.names = FALSE),
              nrow = nrow(df), ncol = length(feats),
              dimnames = list(NULL, feats))
  
  na_per_col <- colSums(is.na(X))
  if (any(na_per_col > 0) && verbose) {
    bad <- na_per_col[na_per_col > 0]
    message("score_from_woe: NAs found in ", length(bad), " feature(s):")
    for (nm in names(bad)) message("   ", nm, ": ", bad[[nm]], " NA(s)")
    message("Imputing these NAs with 0 (neutral WOE) so scoring can proceed.")
  }
  X[is.na(X)] <- 0
  
  b <- betas[feats]
  logit <- as.numeric(intercept + X %*% b)
  score <- scaling$offset - scaling$factor * logit
  round(score)
}

# 5. score a single applicant from the card (loan-officer demo path)
# applicant_woe: named list/vector of a person's WOE values per feature
#                (names like "days_employed_woe")
# returns the summed points using the card's per-bin points (nearest WOE bin)

score_applicant <- function(applicant_woe, card) {
  total <- 0
  for (cn in unique(card$coef_name)) {
    if (!cn %in% names(applicant_woe)) next
    woe_val <- as.numeric(applicant_woe[[cn]])
    rows <- card[card$coef_name == cn, ]
    # match to the bin whose stored WOE is closest to the applicant's WOE
    idx <- which.min(abs(rows$woe - woe_val))
    total <- total + rows$points[idx]
  }
  round(total)
}

score_batch <- function(data_woe, card) {
  apply(data_woe, 1, function(row) score_applicant(as.list(row), card))
}

# 6. decision bands
assign_decision <- function(score, decline_cut = 580, approve_cut = 640) {
  out <- dplyr::case_when(
    score <  decline_cut ~ "DECLINE",
    score >= approve_cut ~ "APPROVE",
    TRUE                 ~ "REVIEW"
  )
  factor(out, levels = c("DECLINE", "REVIEW", "APPROVE"))
}

# flexible band assignment from a cutoffs table with lower_score/upper_score/band
assign_band <- function(score, cutoffs) {
  matched <- cutoffs %>%
    dplyr::filter(lower_score <= score & score <= upper_score) %>%
    dplyr::pull(band)
  if (length(matched) == 0) NA_character_ else matched[1]
}