# ============================================================================
# tests/test_scorecard.R
# Verifies the scorecard engine: PDO scaling, card construction, scoring
# and decision bands
# Run with: testthat::test_dir("tests") or testthat::test_dir("../tests")
# ============================================================================

library(testthat)
library(dplyr)

# locate scorecard.R whether tests run from project root or tests/
.src <- if (file.exists("R/scorecard.R")) "R/scorecard.R" else "../R/scorecard.R"
source(.src)

# fixtures: a tiny 2-feature model and matching WOE bins
fake_coefs <- c("(Intercept)" = -2.0,
                "feat_a_woe"  = -0.8,
                "feat_b_woe"  = -0.5)

fake_bins <- data.frame(
  variable = c("feat_a", "feat_a", "feat_a",
               "feat_b", "feat_b"),
  bin      = c("low", "mid", "high", "lo", "hi"),
  woe      = c(-0.6, 0.0, 0.7, -0.4, 0.5),
  stringsAsFactors = FALSE
)

scaling <- make_scaling(base_score = 600, base_odds = 50, pdo = 20)

# -----

test_that("make_scaling derives factor and offset correctly", {
  expect_equal(scaling$factor, 20 / log(2), tolerance = 1e-9)
  expect_equal(scaling$offset, 600 - (20 / log(2)) * log(50), tolerance = 1e-9)
})

test_that("a higher base_score shifts the offset up", {
  s2 <- make_scaling(base_score = 700)
  expect_gt(s2$offset, scaling$offset)
})

# -----

card <- build_scorecard(fake_coefs, fake_bins, scaling)

test_that("card has one row per feature-bin and integer points", {
  expect_equal(nrow(card), nrow(fake_bins))
  expect_true(all(card$points == round(card$points)))
})

test_that("points increase with WOE within a feature (lower risk = more points)", {
  # beta is negative, factor positive => points = base - factor*beta*woe
  # so higher WOE yields higher points
  a <- card %>% filter(coef_name == "feat_a_woe") %>% arrange(woe)
  expect_true(all(diff(a$points) >= 0))
})

test_that("NA coefficients are dropped from the card", {
  coefs_na <- c(fake_coefs, "feat_c_woe" = NA_real_)
  bins_na <- rbind(fake_bins,
                   data.frame(variable = "feat_c", bin = "x", woe = 0.1))
  card_na <- build_scorecard(coefs_na, bins_na, scaling)
  expect_false("feat_c_woe" %in% card_na$coef_name)
})

# -----

test_that("score_from_woe returns one score per row", {
  dat <- data.frame(feat_a_woe = c(-0.6, 0.7), feat_b_woe = c(-0.4, 0.5))
  s <- score_from_woe(dat, fake_coefs, scaling, verbose = FALSE)
  expect_length(s, 2)
  expect_true(all(is.finite(s)))
})

test_that("lower-risk applicant scores higher than higher-risk", {
  safe  <- data.frame(feat_a_woe = 0.7,  feat_b_woe = 0.5)   # high WOE = safe
  risky <- data.frame(feat_a_woe = -0.6, feat_b_woe = -0.4)
  expect_gt(score_from_woe(safe, fake_coefs, scaling, verbose = FALSE),
            score_from_woe(risky, fake_coefs, scaling, verbose = FALSE))
})

test_that("score is monotonic decreasing in predicted probability", {
  dat <- data.frame(feat_a_woe = c(-0.6, 0.0, 0.7),
                    feat_b_woe = c(-0.4, 0.0, 0.5))
  sc <- score_from_woe(dat, fake_coefs, scaling, verbose = FALSE)
  pr <- sapply(seq_len(nrow(dat)), function(i) {
    b <- fake_coefs[-1]
    logit <- fake_coefs[["(Intercept)"]] + sum(as.numeric(dat[i, names(b)]) * b)
    1 / (1 + exp(-logit))
  })
  expect_true(cor(sc, pr) < 0)   # higher probability -> lower score
})

test_that("NA coefficients do not poison scores", {
  coefs_na <- c(fake_coefs, "feat_c_woe" = NA_real_)
  dat <- data.frame(feat_a_woe = 0.0, feat_b_woe = 0.0, feat_c_woe = 0.0)
  s <- score_from_woe(dat, coefs_na, scaling, verbose = FALSE)
  expect_true(is.finite(s))
})

# -----

test_that("assign_decision respects cutoffs", {
  d <- assign_decision(c(500, 560, 600), decline_cut = 545, approve_cut = 575)
  expect_equal(as.character(d), c("DECLINE", "REVIEW", "APPROVE"))
})

test_that("assign_decision returns an ordered factor", {
  d <- assign_decision(560, 545, 575)
  expect_s3_class(d, "factor")
  expect_equal(levels(d), c("DECLINE", "REVIEW", "APPROVE"))
})