# Define the S7 class for SQLite database management
SQLiteManager <- new_class(
  "SQLiteManager",
  properties = list(
    db_path = class_character,
    state = class_environment, # Environment for mutable state
    max_retries = class_integer
  ),
  constructor = function(
    db_path,
    max_retries = 3L
  ) {
    # Create environment to hold mutable state
    state_env <- new.env(parent = emptyenv())
    state_env$connection <- NULL
    state_env$is_connected <- FALSE

    obj <- new_object(
      S7_object(),
      db_path = db_path,
      state = state_env,
      max_retries = as.integer(max_retries)
    )

    return(obj)
  }
)

# Register generics
get_connection <- new_generic("get_connection", "self")
# Method to establish connection
method(get_connection, SQLiteManager) <- function(self) {
  return(self@state$connection)
}


# Register generics
set_connection <- new_generic("set_connection", "self")
# Method to establish connection
method(set_connection, SQLiteManager) <- function(self, new_connection) {
  self@state$connection <- new_connection
  return(invisible(self))
}


# Register generics
db_connect <- new_generic("db_connect", "self")
# Method to establish connection
method(db_connect, SQLiteManager) <- function(self) {
  tryCatch(
    {
      set_connection(
        self,
        adbcdrivermanager::adbc_database_init(
          adbcsqlite::adbcsqlite(),
          uri = self@db_path
        ) |>
          adbcdrivermanager::adbc_connection_init()
      )

      self@state$is_connected <- TRUE

      message("Successfully connected to database: ", self@db_path)
      return(invisible(self))
    },
    error = function(e) {
      stop("Failed to connect to database: ", e$message)
    }
  )
}

# Method to check if connection is alive
method(is_connected, SQLiteManager) <- function(self) {
  return(self@state$is_connected)
}

# Now you can use it:
db <- SQLiteManager("api/data/dummy_data.db", max_retries = 3L)
db_connect(db) # This modifies the connection in the environment
