library(scorecard)
library(pROC)
library(ROCR)
library(dplyr)

# WOE transformation
apply_woe <- function(data, woe_bins) {
  scorecard::woebin_ply(data, woe_bins)
}

# metrics
compute_gini <- function(actual, predicted) {
  roc_obj <- roc(actual, predicted, quiet = TRUE)
  gini <- (2 * auc(roc_obj) - 1)
  return(as.numeric(gini))
}

compute_ks <- function(actual, predicted) {
  pred_obj <- prediction(predicted, actual)
  ks_perf <- performance(pred_obj, measure = "tpr", x.measure = "fpr")
  tpr <- unlist(ks_perf@y.values)
  fpr <- unlist(ks_perf@x.values)
  max(tpr - fpr, na.rm = TRUE)
}

compute_auc <- function(actual, predicted) {
  roc_obj <- roc(actual, predicted, quiet = TRUE)
  as.numeric(auc(roc_obj))
}

compute_calibration <- function(actual, predicted, n_bins = 10) {
  tibble(
    pred = predicted,
    actual = actual
  ) %>%
    mutate(bin = cut(pred, breaks = seq(0, 1, 1/n_bins))) %>%
    group_by(bin) %>%
    summarise(
      n = n(),
      expected = mean(pred, na.rm = TRUE),
      observed = mean(actual, na.rm = TRUE),
      error = abs(expected - observed),
      .groups = "drop"
    )
}

compute_lift_decile <- function(actual, predicted) {
  pop_rate <- mean(actual)
  tibble(
    rank = rank(-predicted, ties.method = "random"),
    actual = actual
  ) %>%
    mutate(decile = cut(rank, breaks = seq(0, length(rank), length(rank)/10))) %>%
    group_by(decile) %>%
    summarise(
      n = n(),
      defaults = sum(actual),
      default_rate = mean(actual),
      lift = mean(actual) / pop_rate,
      .groups = "drop"
    ) %>%
    arrange(desc(decile))
}

# scorecard
score_applicant <- function(applicant_woe, scorecard) {
  score <- 0
  for (feature in names(applicant_woe)) {
    if (feature %in% scorecard$variable) {
      woe_val <- applicant_woe[[feature]]
      matched <- scorecard %>%
        filter(variable == feature, woe_min <= woe_val & woe_val < woe_max)
      if (nrow(matched) > 0) {
        score <- score + matched$points[1]
      }
    }
  }
  score
}

score_batch <- function(data_woe, scorecard) {
  apply(data_woe, 1, function(row) score_applicant(as.list(row), scorecard))
}

assign_band <- function(score, cutoffs) {
  matched <- cutoffs %>%
    filter(lower_score <= score & score <= upper_score) %>%
    pull(band)
  if (length(matched) == 0) NA_character_ else matched[1]
}

# validation
check_missing <- function(data, threshold = 0.5) {
  missing_pct <- colMeans(is.na(data))
  sort(missing_pct[missing_pct > threshold], decreasing = TRUE)
}

check_outliers <- function(data, feature = NULL, lower_q = 0.01, upper_q = 0.99) {
  vec <- if (!is.null(feature)) data[[feature]] else data
  lower <- quantile(vec, lower_q, na.rm = TRUE)
  upper <- quantile(vec, upper_q, na.rm = TRUE)
  outliers <- sum(vec < lower | vec > upper, na.rm = TRUE)
  
  list(
    lower = lower,
    upper = upper,
    count_outliers = outliers,
    pct_outliers = 100 * outliers / length(vec)
  )
}

validate_woe_bounds <- function(data) {
  anomalies <- tibble()
  for (col in names(data)) {
    if (is.numeric(data[[col]])) {
      min_val <- min(data[[col]], na.rm = TRUE)
      max_val <- max(data[[col]], na.rm = TRUE)
      if (min_val < -10 || max_val > 10) {
        anomalies <- bind_rows(anomalies, tibble(
          feature = col, min_woe = min_val, max_woe = max_val
        ))
      }
    }
  }
  anomalies
}

# summary
create_metrics_summary <- function(actual, predicted, model_name = "Model") {
  tibble(
    Model = model_name,
    Gini = round(compute_gini(actual, predicted), 4),
    KS = round(compute_ks(actual, predicted), 4),
    AUC = round(compute_auc(actual, predicted), 4),
    `Default Rate` = round(mean(actual), 4),
    `N Defaults` = sum(actual),
    `N Total` = length(actual)
  )
}

print_model_summary <- function(actual, predicted, model_name = "Model") {
  cat("\n")
  cat(paste(rep("═", 60), collapse = ""), "\n")
  cat("MODEL:", model_name, "\n")
  cat(paste(rep("═", 60), collapse = ""), "\n")
  cat("Gini:", round(compute_gini(actual, predicted), 4), "\n")
  cat("KS:", round(compute_ks(actual, predicted), 4), "\n")
  cat("AUC:", round(compute_auc(actual, predicted), 4), "\n")
  cat("Default Rate:", round(100 * mean(actual), 2), "%\n")
  cat("Defaults:", sum(actual), "/", length(actual), "\n")
  cat(paste(rep("═", 60), collapse = ""), "\n\n")
}