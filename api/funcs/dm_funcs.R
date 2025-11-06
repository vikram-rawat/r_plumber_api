return_msg <- function() {
  return("Hello, World! I am running plumber API with mirai support.")
}

return_csv <- function() {
  main_dt <- list()
  for (i in 1:1e3) {
    main_dt[[i]] <- iris
  }

  result <- data.table::rbindlist(main_dt)

  return(result)
}

return_aync_csv <- function() {
  mirai(
    {
      # 1. Call the function using the name 'my_func' from the .args list.
      # 2. Make sure any dependencies (like rbindlist) are available.
      my_func()
    },
    .args = list(
      # Pass the function 'return_msg' object, but assign it to the name 'my_func'
      # which will be used inside the mirai expression.
      my_func = return_csv
    )
  )
}
