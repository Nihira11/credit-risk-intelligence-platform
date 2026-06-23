
packages <- c(
  # Data manipulation & wrangling
  "tidyverse",         # ggplot2, dplyr, tidyr, readr, etc.
  "data.table",        # Fast data manipulation
  "janitor",           # Data cleaning utilities
  
  # Database
  "RPostgres",         # PostgreSQL connection
  "DBI",               # Database interface
  
  # Statistical modeling
  "glm2",              # Enhanced GLM functions
  "car",               # VIF, diagnostics
  "lmtest",            # Model testing
  
  # Machine learning
  "xgboost",           # Gradient boosting
  "caret",             # ML framework
  "mltools",           # Additional ML tools
  
  # Model evaluation
  "ROCR",              # ROC/AUC curves
  "ModelMetrics",      # Gini, KS, lift
  "ConfusionMatrix",   # Confusion matrix utilities
  
  # Explainability
  "SHAP",              # SHAP values
  "shapr",             # SHAP explanations
  "lime",              # Local explanations
  
  # Credit-specific
  "scorecard",         # Scorecard generation (WOE, IV)
  
  # Visualization
  "ggplot2",           # Already in tidyverse, explicit for clarity
  "plotly",            # Interactive plots
  "DT",                # Interactive tables (Shiny)
  "gridExtra",         # Multi-plot layouts
  
  # Shiny
  "shiny",             # Web app framework
  "shinydashboard",    # Dashboard layouts
  "shinybusy",         # Loading indicators
  "bslib",             # Bootstrap themes
  
  # Reporting & documentation
  "rmarkdown",         # R markdown
  "knitr",             # Dynamic documents
  "kableExtra",        # Enhanced tables
  
  # Testing
  "testthat",          # Unit testing
  
  # Utilities
  "here",              # Path management
  "dotenv",            # Environment variables
  "glue",              # String interpolation
  "lubridate"          # Date/time handling
)

# Install missing packages only
new_packages <- packages[!(packages %in% installed.packages()[,"Package"])]
if(length(new_packages) > 0) {
  install.packages(new_packages, dependencies = TRUE)
  cat("✓ Installed:", length(new_packages), "new packages\n")
} else {
  cat("✓ All packages already installed\n")
}

# Load core packages for immediate use
library(tidyverse)
library(data.table)
library(DBI)
library(RPostgres)
library(xgboost)
library(caret)
library(ROCR)
library(shiny)
library(rmarkdown)

cat("Core packages loaded. Ready to start!\n")

devtools::install_github("cran/scorecard")  # If CRAN version lags
devtools::install_github("ModelOriented/DALEX")  # Advanced explainability

# Verify key packages
cat("\nPackage Versions:\n")
packages_check <- c("tidyverse", "xgboost", "shiny", "RPostgres", "caret")
for(pkg in packages_check) {
  ver <- packageVersion(pkg)
  cat(paste0(pkg, ": ", ver, "\n"))
}