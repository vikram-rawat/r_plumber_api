return_msg <- function() {
  return("I am running plumber API with mirai support.")
}

return_csv <- function(dbm = sqlite_db) {
  result <- dbm |>
    db_get_query("SELECT * FROM iris_data limit 10")
  return(result)
}

return_aync_csv <- function() {
  mirai(
    {
      # Call the function
      my_func(sqlite_db)
    },
    .args = list(
      # define functions
      my_func = return_csv,
      sqlite_db = sqlite_db
    )
  )
}
