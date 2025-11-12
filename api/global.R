source("dependencies.R")
source("funcs/data_funcs/dm_funcs.R")
source("funcs/classes/db_class.R")
# section: ----------------------------------
sqlite_db <<- sqlite_mng("data/dummy_data.db") |>
  db_connect()

{
  # setup a daemon with required objects
  daemons(1L, dispatcher = FALSE)

  # setup the global environment of the daemon
  setup_status <- everywhere({
    source("dependencies.R")
    source("funcs/classes/db_class.R")
    sqlite_db <<- sqlite_mng("data/dummy_data.db") |>
      db_connect()
  })
}

# check setup status
print(setup_status[[1]]$data)
