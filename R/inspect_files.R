library(tidyverse)

files <- c(
  "application_train.csv",
  "bureau.csv",
  "bureau_balance.csv",
  "credit_card_balance.csv",
  "installments_payments.csv",
  "POS_CASH_balance.csv",
  "previous_application.csv"
)

for (f in files) {
  cat("\n", "=" %>% str_dup(60), "\n")
  cat("FILE:", f, "\n")
  cat("=" %>% str_dup(60), "\n")
  
  filepath <- file.path("data/raw", f)
  
  df <- read_csv(filepath, n_max = 100, show_col_types = FALSE)
  
  cat("  Dimensions (first 100 rows):", nrow(df), "rows ×", ncol(df), "columns\n\n")
  
  spec_df <- spec(df)
  print(spec_df)
  
  cat("\n  Column names (for schema):\n")
  print(names(df))
  
  cat("\n")
}