return_msg <- function(msg = "") {
  list(msg = paste0("The message is: '", msg, "'"))
}

return_plot <- function() {
  rand <- rnorm(100)
  hist(rand)
}

return_sum <- function(a, b) {
  as.numeric(a) + as.numeric(b)
}
