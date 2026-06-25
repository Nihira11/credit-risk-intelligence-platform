# Credit Risk Intelligence Platform

A credit risk scoring system built with **R, PostgreSQL, and Shiny**, using the Home Credit Default Risk dataset. The goal is an end-to-end pipeline: relational data in Postgres → feature engineering in R → an interpretable credit scorecard → an interactive Shiny dashboard.

---

## Why this project

Most credit models in production are interpretable by design, because lenders must be able to explain *why* an applicant was declined. This project follows that real-world approach: a logistic-regression scorecard as the core model, with gradient boosting (XGBoost) as a comparison benchmark – and a focus on the parts that actually differentiate good credit work: feature engineering from relational history, domain-standard metrics (Gini, KS, Information Value), and honest temporal validation.

## Dataset

[Home Credit Default Risk](https://www.kaggle.com/datasets/julianocosta/home-credit) – ~307K loan applications across 7 relational tables, roughly an 8% default rate.

The raw CSVs are **not** committed to this repo (they're large and governed by Kaggle's terms). Download them and place in `data/raw/`. Sizes for reference:

| File                        | Size     | Grain                          |
|-----------------------------|----------|--------------------------------|
| application_train.csv       | 8.3 MB   | one row per applicant (target) |
| bureau.csv                  | 170 MB   | one row per prior credit       |
| bureau_balance.csv          | 22.3 MB  | monthly bureau snapshots       |
| credit_card_balance.csv     | 424.6 MB | monthly credit-card history    |
| installments_payments.csv   | 723.1 MB | one row per installment paid   |
| POS_CASH_balance.csv        | 23.3 MB  | monthly POS/cash loan history  |
| previous_application.csv    | 100.9 MB | one row per prior application  |

The large multi-row tables are why this project uses PostgreSQL – aggregating 723 MB of installment history in-database is far saner than loading it all into R memory.

## Tech stack

| Layer       | Tool                          |
|-------------|-------------------------------|
| Data store  | PostgreSQL 17                 |
| Modeling    | R (tidyverse, glm, xgboost)   |
| Dashboard   | Shiny                         |
| Environment | RStudio project (`.Rproj`)    |

## Project structure

```
credit-risk-intelligence-platform/
├── data/
│   ├── raw/              # Original Kaggle CSVs (not committed)
│   ├── processed/        # Cleaned data (not committed)
│   └── features/         # Engineered features (not committed)
│
├── sql/
│   ├── 01_create_tables.sql
│   ├── 02_feature_engineering.sql
│   ├── 03_create_analytics_table.sql
│   └── 04_validation_splits.sql
│
├── R/
│   ├── db_connection.R   # PostgreSQL connection helpers
│   ├── feature_utils.R   # IV / WOE / binning functions
│   ├── model_utils.R     # training + metrics (Gini, KS, lift)
│   ├── scorecard.R       # points-based scorecard logic
│   └── shiny_helpers.R   # shared Shiny utilities
│
├── notebooks/
│   ├── 01_eda.Rmd
│   ├── 02_feature_selection.Rmd
│   ├── 03_modeling.Rmd
│   ├── 04_scorecard_generation.Rmd
│   └── 05_model_validation.Rmd
│
├── shiny_app/
│   ├── app.R
│   ├── pages/
│   │   ├── 01_performance.R
│   │   ├── 02_scorecard.R
│   │   ├── 03_risk_tool.R
│   │   └── 04_insights.R
│   ├── www/             # style.css, logo.png
│   └── data/            # pre-computed data for the app
│
├── scorecard_output/    # final scorecard + metrics (generated)
│
├── docs/
│   ├── METHODOLOGY.md
│   ├── FEATURE_DEFINITIONS.md
│   └── MODEL_COMPARISON.md
│
├── tests/
│   ├── test_features.R
│   └── test_scorecard.R
│
├── requirements.R       # package list – run once to install
├── README.md
├── .gitignore
└── credit-risk-intelligence-platform.Rproj
```
---

**Author**  
Nihira Sharma  
Data Science & Analytics  
University of Sydney
