# load libraries: ----------------------------------

source("api/dependencies.R")

# create a db: ----------------------------------
# Open a new connection to a database
db <- adbc_database_init(
  adbcsqlite::adbcsqlite(),
  uri = "api/data/dummy_data.db"
)

# establish connection
conn <- adbc_connection_init(db)

# write iris data to the database
conn |>
  write_adbc(
    tbl = iris,
    db_or_con = _,
    target_table = "iris_data"
  )

# append iris data multiple times to create a large dataset
for (i in 1:4e3) {
  if (i %% 100 == 0) {
    print(i)
    print(Sys.time())
  }

  conn |>
    write_adbc(
      tbl = iris,
      db_or_con = _,
      target_table = "iris_data",
      mode = "append"
    )
}

# convert to file size in MB
file.info("api/data/dummy_data.db")$size / 2^20 # check file size

# release all connection: ----------------------------------
adbc_connection_release(conn)
adbc_database_release(db)
