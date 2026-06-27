library(tidyverse)
library(ROCR)

# metric: Gini coefficient
# Gini = 2 * AUC - 1
# range: 0 (random) to 1 (perfect)
# Credit industry standard; Gini ≥ 0.40 is "good"
compute_gini <- function(actual, predicted) {
  # actual: binary target (0/1 or TRUE/FALSE)
  # predicted: numeric probability (0–1)
  
  df <- tibble(actual = actual, predicted = predicted) %>%
    arrange(desc(predicted))
  
  # AUC via ROCR
  pred_rocr <- ROCR::prediction(predictions = df$predicted, 
                                labels = df$actual)
  auc <- ROCR::performance(pred_rocr, "auc")@y.values[[1]]
  
  # Gini = 2*AUC - 1
  gini <- 2 * auc - 1
  
  return(gini)
}

# metric: Kolmogorov-Smirnov (KS) statistic
# KS = max(% defaults caught - % non-defaults caught) at any threshold
# range: 0 (random) to 1 (perfect)
# Credit standard; KS ≥ 0.20 is "good"
compute_ks <- function(actual, predicted) {
  # actual: binary target (0/1)
  # predicted: numeric probability (0–1)
  
  df <- tibble(actual = actual, predicted = predicted) %>%
    arrange(desc(predicted))
  
  # use ROCR
  pred_rocr <- ROCR::prediction(predictions = df$predicted,
                                labels = df$actual)
  ks_perf <- ROCR::performance(pred_rocr, "tpr", "fpr")
  
  # KS is max(TPR - FPR)
  tpr <- ks_perf@y.values[[1]]
  fpr <- ks_perf@x.values[[1]]
  ks <- max(tpr - fpr)
  
  return(ks)
}

# metric: AUC (Area Under ROC Curve)
# range: 0.5 (random) to 1 (perfect)
compute_auc <- function(actual, predicted) {
  df <- tibble(actual = actual, predicted = predicted)
  
  pred_rocr <- ROCR::prediction(predictions = df$predicted,
                                labels = df$actual)
  auc <- ROCR::performance(pred_rocr, "auc")@y.values[[1]]
  
  return(auc)
}

# metric: calibration plot data
# grps predictions into deciles; checks if predicted probability ≈ observed default rate
compute_calibration <- function(actual, predicted, n_bins = 10) {
  # actual: binary target
  # predicted: numeric probability
  # returns: tibble with expected vs. observed rates per bin
  
  df <- tibble(
    predicted = predicted,
    actual = actual
  ) %>%
    mutate(
      bin = cut(predicted, 
                breaks = seq(0, 1, 1/n_bins),
                labels = paste0("Bin_", 1:n_bins),
                include.lowest = TRUE)
    ) %>%
    group_by(bin) %>%
    summarise(
      n = n(),
      expected_rate = mean(predicted),
      observed_rate = mean(actual),
      n_defaults = sum(actual),
      .groups = "drop"
    ) %>%
    filter(!is.na(bin))  # Remove NA bin if any
  
  return(df)
}

# metric: Lift-by-Decile
# ranks applicants by score (high risk first); shows % of defaults captured in top deciles
compute_lift <- function(actual, predicted) {
  # actual: binary target
  # predicted: numeric probability
  # returns: tibble with lift metrics per decile
  
  # Calculate overall default rate first
  overall_default_rate <- mean(actual)
  
  df <- tibble(
    predicted = predicted,
    actual = actual
  ) %>%
    mutate(
      rank = rank(-predicted, ties.method = "random"),  # Rank by score (descending)
      percentile = rank / n(),  # 0–1
      decile = ceiling(percentile * 10)  # 1–10 (decile 1 = top 10%)
    ) %>%
    group_by(decile) %>%
    summarise(
      n_applicants = n(),
      n_defaults = sum(actual),
      observed_default_rate = mean(actual),
      lift = mean(actual) / overall_default_rate,
      .groups = "drop"
    ) %>%
    arrange(decile) %>%
    mutate(
      cumulative_applicants = cumsum(n_applicants),
      cumulative_defaults = cumsum(n_defaults),
      cumulative_capture_rate = cumulative_defaults / sum(n_defaults)
    )
  
  return(df)
}

# metric: confusion matrix at default threshold (50%)
compute_confusion_matrix <- function(actual, predicted, threshold = 0.5) {
  predicted_class <- ifelse(predicted >= threshold, 1, 0)
  
  tp <- sum(predicted_class == 1 & actual == 1)
  tn <- sum(predicted_class == 0 & actual == 0)
  fp <- sum(predicted_class == 1 & actual == 0)
  fn <- sum(predicted_class == 0 & actual == 1)
  
  sensitivity <- tp / (tp + fn)  # TPR: % defaults caught
  specificity <- tn / (tn + fp)  # TNR: % non-defaults correctly identified
  precision <- tp / (tp + fp)    # positive predictive value
  
  return(list(
    tp = tp, tn = tn, fp = fp, fn = fn,
    sensitivity = sensitivity,
    specificity = specificity,
    precision = precision,
    threshold = threshold
  ))
}

# summary metrics table
summarise_metrics <- function(actual, predicted, model_name = "Model") {
  tibble(
    Model = model_name,
    Gini = round(compute_gini(actual, predicted), 4),
    KS = round(compute_ks(actual, predicted), 4),
    AUC = round(compute_auc(actual, predicted), 4),
    Default_Rate = round(mean(actual), 4)
  )
}

# export
cat("Metric functions loaded\n")
cat("  - compute_gini()\n")
cat("  - compute_ks()\n")
cat("  - compute_auc()\n")
cat("  - compute_calibration()\n")
cat("  - compute_lift()\n")
cat("  - compute_confusion_matrix()\n")
cat("  - summarise_metrics()\n")