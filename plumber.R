# plumber.R
# section: ----------------------------------
source("api/global.R")
# section: ----------------------------------
main_file <- "api/routes/main_routes.R"

plumb(main_file) |>
  pr_set_debug(TRUE) |>
  pr_hook(
    "exit",
    function() {
      message("Plumber app shutting down. Stopping mirai daemons...")
      # This function terminates all currently running daemons
      daemons(0)
      message("mirai daemons stopped.")
    }
  ) |>
  pr_run()
