# Credit Risk Intelligence Platform

A complete credit risk platform that predicts whether a loan applicant may default and converts the prediction into an easy-to-understand credit score.

The project uses more than 58 million records from the Home Credit dataset. It covers the full process—from building features in PostgreSQL and training models to validating the final scorecard and deploying it in an interactive Shiny dashboard.

**[▶ Live dashboard](https://nihirasharma.shinyapps.io/credit-risk-intelligence-platform/)** &nbsp;·&nbsp; **[Methodology](docs/METHODOLOGY.md)** &nbsp;·&nbsp; **[Model comparison](docs/MODEL_COMPARISON.md)**

> Built using R, PostgreSQL, tidyverse, scorecard, XGBoost and Shiny

![Dashboard – Performance page 1](screenshots/dashboard_performance.png)
![Dashboard – Performance page 2](screenshots/performance_table.png)

---

## Project Overview

This project creates a complete credit risk process similar to those used by banks and other financial companies.

It includes:

- Combining data from several related tables
- Creating applicant features using SQL
- Using Weight of Evidence (WOE) to prepare variables
- Using Information Value (IV) to select useful features
- Training Logistic Regression and XGBoost models
- Creating a credit scorecard
- Building loan approval rules
- Testing model accuracy, stability, calibration, and fairness
- Deploying the results in an interactive dashboard

The main goal was to build a credit scoring system that is **clear, explainable, stable, and suitable for business decisions**. The project does not simply choose the model with the highest accuracy. It also considers whether the model can explain why an applicant received a certain score.

Using clean Home Credit data without information leakage, a Gini score of around 0.31 is realistic for this project. Much higher results on this dataset may indicate that future information was accidentally used during training.

---

## Key Results

| Area | Results |
| -------- | --------------- |
| **Dataset** | 307,511 applicants created from more than 58 million raw records |
| **Final Model** | Logistic Regression using 16 variables |
| **Performance** | AUC 0.66 · Gini 0.31 · KS 0.23 |
| **Calibration** | MSE 0.0001; predicted default rates closely match actual rates |
| **Population Stability** | Train-to-test PSI close to 0, showing stable samples |
| **Decision Strategy** | 22% automatically approved with a 3.6% default rate, compared with 8.1% overall |
| **Fairness Assessment** | Tested across gender and age groups, with no additional difference beyond existing default rates |
| **Database** | PostgreSQL feature engineering across seven source tables |
| **Testing** | 28 tests created with `testthat` |

---

## Interactive Dashboard

The project is available as an interactive [Shiny dashboard](https://nihirasharma.shinyapps.io/credit-risk-intelligence-platform/) with four main pages.

### Performance

This page shows:
- Main model performance scores
- Credit score distribution
- Loan approval strategy
- Default rate for each score group

### Scorecard Explorer

This page allows users to:
- View every variable used by the scorecard
- Explore how values are divided into groups
- See how many points each group receives
- Understand how each variable affects the final score

### Risk Tool

This page allows users to:
- Score an individual loan applicant
- View the points given by each variable
- See the final credit score and risk decision
- Change applicant details and see how the score changes

### Insights

This page includes:
- Feature importance
- Lift analysis
- Logistic Regression and XGBoost comparison
- Scorecard performance
- Main business findings

**Risk Tool:** 
![Risk Tool](screenshots/risk_tool.png)

**Insights:** 
![Insights](screenshots/insights.png)

*The dashboard is hosted on the free shinyapps.io plan. It may take a few seconds to start if it has been inactive*

---

## Project Pipeline

```
Raw Home Credit Tables
7 tables and more than 58 million rows
        │
        ▼
Feature Engineering in PostgreSQL
        │
        ▼
Analytics Dataset
307,511 applicants and around 100 features
        │
        ▼
WOE Transformation and IV Feature Selection
22 features selected
        │
        ▼
Logistic Regression
16 features after removing strongly related variables
        │
        ├── XGBoost used as a comparison model
        ▼
Credit Scorecard
Points created using PDO scaling
        │
        ▼
Model Validation
ROC · Gini · KS · calibration · PSI · fairness
        │
        ▼
Interactive Shiny Dashboard
```

---

## Project Notebooks

The full process is explained through five HTML notebooks. They can be opened directly in a browser through GitHub Pages.

* [01 – Exploratory Data Analysis](https://nihira11.github.io/credit-risk-intelligence-platform/notebooks/01_eda.html)
* [02 – Feature Selection using WOE & IV](https://nihira11.github.io/credit-risk-intelligence-platform/notebooks/02_feature_selection.html)
* [03 – Model Development](https://nihira11.github.io/credit-risk-intelligence-platform/notebooks/03_modeling.html)
* [04 – Scorecard Generation](https://nihira11.github.io/credit-risk-intelligence-platform/notebooks/04_scorecard_generation.html)
* [05 – Model Validation](https://nihira11.github.io/credit-risk-intelligence-platform/notebooks/05_model_validation.html)

---

## Model Selection

Both Logistic Regression and XGBoost were trained and compared.

XGBoost achieved a slightly higher test Gini score of around 0.01. However, it also showed more overfitting:
- XGBoost training Gini: 0.38
- XGBoost test Gini: 0.32

Logistic Regression was chosen as the final model because it provides:
- Clear explanations for every prediction
- Stable performance on new data
- Easy-to-understand relationships between variables and risk
- Direct conversion into a credit scorecard
- Greater transparency for business and regulatory review

This makes Logistic Regression more suitable for an explainable credit risk system, even though XGBoost performed slightly better.

A full comparison is available in [MODEL_COMPARISON.md](docs/MODEL_COMPARISON.md)

---

## Model Validation

The model was tested in the same main areas that a financial model-risk team would review before approving it.

### Discrimination
AUC, Gini, KS, and ROC curves were used to check how well the model separates applicants who default from those who do not.

### Calibration
The predicted default rates were compared with the actual default rates. The model achieved an MSE of **0.0001**, showing that its predicted probabilities closely follow the observed results.

### Stability
The Population Stability Index (PSI) was used to compare the training and test samples. The PSI was close to zero, showing that the applicant distributions were stable across both samples.

### Fairness
Predicted risk was reviewed across gender and age groups. The results showed that the model followed differences already present in the observed default rates without creating additional differences between these groups.

---

## Tech Stack

| Category | Tools |
| -------- | -------------- |
| **Database** | PostgreSQL |
| **Programming** | R |
| **Wrangling** | Tidyverse |
| **Modeling** | `glm` · `scorecard` · xgboost · `caret` |
| **Dashboard** | Shiny · `bslib` |
| **Testing** | `testthat` |


---

## Repository structure

```
credit-risk-intelligence-platform/
│
├── data/
│   ├── raw/                                # Original Home Credit data (not tracked)
│   └── processed/                          # Processed and WOE-transformed data
│
├── docs/
│   ├── FEATURE_DEFINITIONS.md              # Data dictionary and feature descriptions
│   ├── METHODOLOGY.md                      # full project method
│   └── MODEL_COMPARISON.md                 # Logistic Regression and XGBoost comparison
│
├── notebooks/
│   ├── 01_eda.Rmd / .html                  # Data exploration
│   ├── 02_feature_selection.Rmd / .html    # WOE transformation and IV selection
│   ├── 03_modeling.Rmd / .html             # lLogistic Regression and XGBoost training
│   ├── 04_scorecard_generation.Rmd / .html # Credit scorecard creation
│   └── 05_model_validation.Rmd / .html     # Performance, calibration, stability, and fairness
│
├── outputs/
│   ├── *.csv                               # Metrics, scorecard tables, and summaries
│   └── *.rds                               # Saved R model files (ignored in Git)
│
├── screenshots/                            # dashboard screenshots
│   ├── dashboard_performance.png
│   ├── scorecard.png
│   ├── risk_tool.png
│   ├── risk_decline.png
│   └── insights.png
│
├── R/
│   ├── db_connection.R                     # PostgreSQL connection functions
│   ├── inspect_files.R                     # Data checking functions
│   ├── model_utils.R                       # Feature and model functions
│   └── scorecard.R                         # Scorecard functions
│
├── scorecard_output/
│   └── test_scored.csv                     # Example scored applicants
│
├── shiny_app/
│   ├── app.R                               # Main dashboard file
│   ├── pages/                              # Dashboard pages
│   ├── data/                               # dDashboard data and scorecard files
│   └── www/                                # CSS and other design files
│
├── sql/
│   ├── 01_create_tables.sql                # Creates the database tables
│   └── 02_feature_engineering.sql          # Creates the analytics dataset
│
├── tests/
│   ├── test_features.R                     # Tests for created features
│   └── test_scorecard.R                    # Tests for scorecard calculations
│
├── .gitignore
├── README.md
├── requirements.R                          # Required R packages
└── credit-risk-intelligence-platform.Rproj
```
---

## Running the Project

1. Download the [Home Credit Default Risk](https://www.kaggle.com/c/home-credit-default-risk) dataset into `data/raw/`
2. Import the raw CSV files into PostgreSQL
3. Execute `sql/01_create_tables.sql` then `sql/02_feature_engineering.sql` in order to generate the analytics dataset
4. Run notebooks 01–05 in order from the main project folder
5. Start the Shiny dashboard:
   ```
   shiny::runApp("shiny_app")
   ```

See [METHODOLOGY.md](docs/METHODOLOGY.md) for the complete process and implementation details.

---

*Built by Nihira Sharma. Dataset: Home Credit Default Risk dataset form Kaggle*
