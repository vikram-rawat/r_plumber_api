# plumber.R
# setwd("api")
# getwd()
# section: ----------------------------------
source("global.R")
# section: ----------------------------------
main_file <- "routes/main_routes.R"

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
