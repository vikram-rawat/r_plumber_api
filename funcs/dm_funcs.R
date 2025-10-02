return_msg <- function() {
  main_dt <- list()
  for (i in 1:1e6) {
    main_dt[[i]] <- iris
  }

  result <- rbindlist(main_dt)

  return(result)
}

return_plot <- function() {
  rand <- rnorm(100)
  result <- hist(rand)
  return(result)
}

return_sum <- function(a, b) {
  return <- as.numeric(a) + as.numeric(b)
  return(return)
}
