# setwd("api/")
# getwd()
# source: ----------------------------------
source("dependencies.R")
source("funcs/data_funcs/dm_funcs.R")
source("funcs/classes/db_class.R")
# create variables: ----------------------------------
sqlite_db <- sqlite_mng("data/dummy_data.db") |>
  db_connect()

get_iris_data_sql <- rs_read_query(
  filepath = "data/sql/get_iris_data.sql",
  method = "db_get_query"
)

# section: ----------------------------------
{
  # setup a daemon with required objects
  daemons(1L, dispatcher = FALSE)

  # setup the global environment of the daemon
  setup_status <- everywhere({
    source("dependencies.R")
    source("funcs/classes/db_class.R")
    sqlite_db <<- sqlite_mng("data/dummy_data.db") |>
      db_connect()

    get_iris_data_sql <<- rs_read_query(
      filepath = "data/sql/get_iris_data.sql",
      method = "db_get_query"
    )
  })
}

# check setup status
print(setup_status[[1]]["data"])
