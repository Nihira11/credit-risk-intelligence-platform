# ============================================================================
# CREDIT RISK INTELLIGENCE PLATFORM - Scorecard Dashboard
# Nihira Sharma  |  shiny_app/app.R  (modular entry point)
#
# This is the thin shell: it loads packages, data, shared helpers and the
# brand theme, sources the four page modules in pages/, then assembles them
# into a navbar app. Each page's UI + server lives in its own pages/*.R file.
# ============================================================================

library(shiny)
library(bslib)
library(bsicons)
library(ggplot2)
library(dplyr)
library(tidyr)
library(readr)
library(scales)
library(DT)

# Brand
source("pages/theme.R", local = TRUE)

# Data Loading (shared)
find_file <- function(name, subdirs = c("data", "../outputs",
                                        "../data/processed", "../scorecard_output")) {
  for (d in subdirs) {
    p <- file.path(d, name)
    if (file.exists(p)) return(p)
  }
  stop("Could not find ", name, " - copy it into shiny_app/data/")
}

scorecard   <- readRDS(find_file("scorecard.rds"))
test_scored <- readRDS(find_file("test_scored.rds"))
test_woe    <- readRDS(find_file("test_with_predictions.rds"))

card       <- scorecard$card
scaling    <- scorecard$scaling
cutoffs    <- scorecard$cutoffs
coefs      <- scorecard$model_coefs
band_ref   <- scorecard$band_reference
validation <- scorecard$validation

# Sahred Helpers  (scoring, naming)
score_from_woe <- function(woe_vec, model_coefs, scaling) {
  intercept <- model_coefs[["(Intercept)"]]
  betas <- model_coefs[names(model_coefs) != "(Intercept)"]
  betas <- betas[!is.na(betas)]
  feats <- names(betas)
  x <- as.numeric(woe_vec[feats]); x[is.na(x)] <- 0
  logit <- as.numeric(intercept + sum(x * betas[feats]))
  round(scaling$offset - scaling$factor * logit)
}

prob_from_woe <- function(woe_vec, model_coefs) {
  intercept <- model_coefs[["(Intercept)"]]
  betas <- model_coefs[names(model_coefs) != "(Intercept)"]
  betas <- betas[!is.na(betas)]
  feats <- names(betas)
  x <- as.numeric(woe_vec[feats]); x[is.na(x)] <- 0
  logit <- as.numeric(intercept + sum(x * betas[feats]))
  1 / (1 + exp(-logit))
}

decide <- function(score, cutoffs) {
  if (score < cutoffs$decline) "DECLINE"
  else if (score >= cutoffs$approve) "APPROVE"
  else "REVIEW"
}

pretty_name <- function(x) {
  x |> sub("_woe$", "", x = _) |> gsub("_", " ", x = _) |> tools::toTitleCase()
}

# Derived Feature Info  (shared by Scorecard Explorer + Risk Tool + Insights)
model_feats <- names(coefs)[names(coefs) != "(Intercept)"]
model_feats <- model_feats[!is.na(coefs[model_feats])]
model_feats <- intersect(model_feats, names(test_woe))

feat_stats <- tibble(
  feature = model_feats,
  min_woe = sapply(model_feats, function(f) min(test_woe[[f]], na.rm = TRUE)),
  med_woe = sapply(model_feats, function(f) median(test_woe[[f]], na.rm = TRUE)),
  max_woe = sapply(model_feats, function(f) max(test_woe[[f]], na.rm = TRUE))
)

top_drivers <- card %>%
  group_by(coef_name) %>%
  summarise(swing = max(points) - min(points), .groups = "drop") %>%
  semi_join(tibble(coef_name = model_feats), by = "coef_name") %>%
  arrange(desc(swing)) %>% slice_head(n = 6) %>% pull(coef_name)

median_woe_vec  <- setNames(feat_stats$med_woe, feat_stats$feature)
overall_default <- mean(test_scored$target)
gini_val <- validation$`From Scorecard`[validation$Metric == "Gini"]
ks_val   <- validation$`From Scorecard`[validation$Metric == "KS"]
auc_val  <- validation$`From Scorecard`[validation$Metric == "AUC"]

# Source Page Moodules  (each defines a _ui(id) and _server(id) function)
source("pages/01_performance.R", local = TRUE)
source("pages/02_scorecard.R",   local = TRUE)
source("pages/03_risk_tool.R",   local = TRUE)
source("pages/04_insights.R",    local = TRUE)

# UI
ui <- page_navbar(
  title = "Credit Risk Intelligence",
  theme = app_theme,
  fillable = FALSE,
  header = tags$head(includeCSS("www/style.css")),
  
  nav_panel("Performance",       performance_ui("perf")),
  nav_panel("Scorecard Explorer", scorecard_ui("card")),
  nav_panel("Risk Tool",         risk_tool_ui("risk")),
  nav_panel("Insights",          insights_ui("ins")),
  
  nav_spacer(),
  nav_item(tags$span(class = "navbar-tag", "Home Credit · logistic scorecard"))
)

# Server
server <- function(input, output, session) {
  performance_server("perf")
  scorecard_server("card")
  risk_tool_server("risk")
  insights_server("ins")
}

shinyApp(ui, server)