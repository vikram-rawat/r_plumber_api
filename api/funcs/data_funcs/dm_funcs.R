return_msg <- function() {
  return("I am running plumber API with mirai support.")
}

return_csv <- function() {
  result <- get_iris_data_sql |>
    rs_execute(
      stmt_arg_name = "sql_query",
      dbm = sqlite_db
    )

  return(result)
}

return_aync_csv <- function() {
  mirai(
    {
      # Call the function
      my_func()
    },
    .args = list(
      # define all parameters here
      my_func = return_csv
    )
  )
}
