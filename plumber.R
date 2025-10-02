# section: ----------------------------------
source("global.R")
# section: ----------------------------------
main_file <- "routes/main_routes.R"

plumb(main_file) |>
  pr_set_debug(TRUE) |>
  pr_run(port = 8000)
