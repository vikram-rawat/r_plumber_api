# # section: ----------------------------------
# source("api/global.R")
# # section: ----------------------------------
# main_file <- "api/routes/main_routes.R"

# plumb(main_file) |>
#   pr_set_debug(TRUE) |>
#   pr_hook(
#     "exit",
#     function() {
#       message("Plumber app shutting down. Stopping mirai daemons...")
#       # This function terminates all currently running daemons
#       daemons(0)
#       message("mirai daemons stopped.")
#     }
#   ) |>
#   pr_run()


# plumber.R

#* Echo back the input
#* @serializer csv
#* @get /echo1
function() {
  main_dt <- list()
  for (i in 1:1e3) {
    main_dt[[i]] <- iris
  }

  result <- data.table::rbindlist(main_dt)

  return(result)
}
