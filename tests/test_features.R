# ============================================================================
# tests/test_features.R
# Sanity checks on the WOE modelling dataset and metric functions
# These guard the data contract the model depends on
# Run with: testthat::test_dir("tests")
# ============================================================================

library(testthat)
library(dplyr)

.src <- if (file.exists("R/model_utils.R")) "R/model_utils.R" else "../R/model_utils.R"
source(.src)

.data_path <- if (file.exists("data/processed/modeling_dataset_woe.csv"))
  "data/processed/modeling_dataset_woe.csv" else
    "../data/processed/modeling_dataset_woe.csv"

# -----

test_that("compute_gini is 0 for random and ~1 for perfect ranking", {
  set.seed(1)
  y <- rbinom(1000, 1, 0.2)
  # perfect predictor
  perfect <- ifelse(y == 1, 0.9, 0.1)
  expect_gt(compute_gini(y, perfect), 0.9)
  # random predictor ~ 0
  rand <- runif(1000)
  expect_lt(abs(compute_gini(y, rand)), 0.15)
})

test_that("compute_auc lies in [0, 1] and equals (gini+1)/2", {
  set.seed(2)
  y <- rbinom(500, 1, 0.3); p <- runif(500)
  auc <- compute_auc(y, p); gini <- compute_gini(y, p)
  expect_true(auc >= 0 && auc <= 1)
  expect_equal(auc, (gini + 1) / 2, tolerance = 1e-6)
})

test_that("compute_ks lies in [0, 1]", {
  set.seed(3)
  y <- rbinom(500, 1, 0.3); p <- runif(500)
  ks <- compute_ks(y, p)
  expect_true(ks >= 0 && ks <= 1)
})

# -----

test_that("modelling dataset exists and has a target column", {
  skip_if_not(file.exists(.data_path), "modeling_dataset_woe.csv not found")
  df <- readr::read_csv(.data_path, show_col_types = FALSE)
  expect_true("target" %in% names(df))
})

test_that("target is binary 0/1 with a plausible default rate", {
  skip_if_not(file.exists(.data_path), "modeling_dataset_woe.csv not found")
  df <- readr::read_csv(.data_path, show_col_types = FALSE)
  expect_setequal(unique(df$target), c(0, 1))
  dr <- mean(df$target)
  expect_true(dr > 0.02 && dr < 0.20)   # Home Credit ~8%
})

test_that("WOE features are numeric and within a sane range", {
  skip_if_not(file.exists(.data_path), "modeling_dataset_woe.csv not found")
  df <- readr::read_csv(.data_path, show_col_types = FALSE)
  # WOE columns only - exclude the target and the SK_ID_CURR identifier
  woe_cols <- setdiff(names(df), c("target", "SK_ID_CURR"))
  expect_true(all(sapply(df[woe_cols], is.numeric)))
  # WOE values rarely exceed |10|; flag if they do
  rng <- range(unlist(df[woe_cols]), na.rm = TRUE)
  expect_true(rng[1] > -10 && rng[2] < 10)
})

test_that("row count matches the Home Credit applicant population", {
  skip_if_not(file.exists(.data_path), "modeling_dataset_woe.csv not found")
  df <- readr::read_csv(.data_path, show_col_types = FALSE)
  expect_equal(nrow(df), 307511)
})

test_that("SK_ID_CURR is present for traceability and fairness joins", {
  skip_if_not(file.exists(.data_path), "modeling_dataset_woe.csv not found")
  df <- readr::read_csv(.data_path, show_col_types = FALSE)
  expect_true("SK_ID_CURR" %in% names(df))
  expect_equal(anyDuplicated(df$SK_ID_CURR), 0)   # IDs must be unique
})