return_msg <- function() {
  return("I am running plumber API with mirai support.")
}

return_csv <- function() {
  result <- sqlite_db |>
    db_get_query("SELECT * FROM iris_data limit 10")
  return(result)
}

return_aync_csv <- function() {
  mirai({
    # Call the function
    return_csv()
  })
}
