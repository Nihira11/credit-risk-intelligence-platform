packages <- c(
  # Core data work 
  "tidyverse",     # dplyr, ggplot2, readr, tidyr, etc.
  "data.table",    # fast reading/handling of the large CSVs
  "janitor",       # quick data cleaning helpers

  # Database (R <-> PostgreSQL) 
  "DBI",           # generic database interface
  "RPostgres",     # the PostgreSQL driver

  # Modeling 
  "xgboost",       # gradient boosting (comparison model)
  "car",           # VIF / multicollinearity checks
  "ROCR",          # ROC curves and AUC

  # Credit-specific 
  "scorecard",     # WOE binning, Information Value, scorecard tools

  # Reporting 
  "rmarkdown",     # render the analysis notebooks
  "knitr",         # used by rmarkdown
  "DT",            # interactive tables (also used in Shiny)
  "plotly",        # interactive charts

  # Shiny
  "shiny",
  "shinydashboard",

  # Utilities
  "here",          # tidy file paths within the project
  "scales"         # nice axis labels and percentages
)

# Install only the ones you don't already have
to_install <- packages[!(packages %in% installed.packages()[, "Package"])]

if (length(to_install) > 0) {
  message("Installing ", length(to_install), " package(s): ",
          paste(to_install, collapse = ", "))
  install.packages(to_install)
} else {
  message("All required packages are already installed.")
}

message("\nDone. You can now load packages with library(), e.g. library(tidyverse).")