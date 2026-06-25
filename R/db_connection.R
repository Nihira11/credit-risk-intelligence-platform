# PostgreSQL connection for Credit Risk Intelligence Platform
get_db_connection <- function() {
  library(DBI)
  library(RPostgres)
  
  # Read credentials from .Renviron
  db_user <- Sys.getenv("CREDIT_DB_USER")
  db_password <- Sys.getenv("CREDIT_DB_PASSWORD")
  db_host <- Sys.getenv("CREDIT_DB_HOST", unset = "localhost")
  db_port <- as.integer(Sys.getenv("CREDIT_DB_PORT", unset = "5432"))
  db_name <- Sys.getenv("CREDIT_DB_NAME", unset = "credit_risk")
  
  # Create connection
  con <- dbConnect(
    RPostgres::Postgres(),
    user = db_user,
    password = db_password,
    host = db_host,
    port = db_port,
    dbname = db_name
  )
  
  return(con)
}