source("dependencies.R")
source("funcs/data_funcs/dm_funcs.R")
source("funcs/classes/db_class.R")
# section: ----------------------------------
sqlite_db <- sqlite_mng("data/dummy_data.db", max_retries = 3L) |>
  db_connect()

{
  daemons(1L, dispatcher = FALSE)
  everywhere({
    source("dependencies.R")
    source("funcs/classes/db_class.R")
    sqlite_db <- sqlite_mng("api/data/dummy_data.db", max_retries = 3L) |>
      db_connect()
  })
}
