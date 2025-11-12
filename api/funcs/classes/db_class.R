# Define the S7 class for SQLite database management
sqlite_mng <- new_class(
  "sqlite_mng",
  properties = list(
    db_path = class_character,
    store = class_environment # Environment for mutable store
  ),
  constructor = function(
    db_path,
    max_retries = 3L
  ) {
    # Create environment to hold mutable store
    store_env <- new.env(parent = emptyenv())
    store_env$connection <- NULL
    store_env$is_connected <- FALSE
    store_env$max_retries <- as.integer(max_retries)

    obj <- new_object(
      S7_object(),
      db_path = db_path,
      store = store_env
    )

    return(obj)
  }
)

# Register generics
get_connection <- new_generic("get_connection", "self")
# Method to establish connection
method(get_connection, sqlite_mng) <- function(self) {
  return(self@store$connection)
}


# Register generics
set_connection <- new_generic("set_connection", "self")
# Method to establish connection
method(set_connection, sqlite_mng) <- function(self, new_connection) {
  self@store$connection <- new_connection
  return(invisible(self))
}


# Register generics
db_connect <- new_generic("db_connect", "self")
# Method to establish connection
method(db_connect, sqlite_mng) <- function(self) {
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

      self@store$is_connected <- TRUE

      message("Successfully connected to database: ", self@db_path)
      return(invisible(self))
    },
    error = function(e) {
      stop("Failed to connect to database: ", e$message)
    }
  )
}

# Register generics
is_connected <- new_generic("is_connected", "self")
# Method to check if connection is alive
method(is_connected, sqlite_mng) <- function(self) {
  if (is.null(get_connection(self))) {
    self@store$is_connected <- FALSE
    return(FALSE)
  }

  tryCatch(
    {
      # Try a simple query to check connection
      result <- get_connection(self) |>
        adbcdrivermanager::read_adbc("SELECT 1")
      self@store$is_connected <- TRUE
      return(TRUE)
    },
    error = function(e) {
      self@store$is_connected <- FALSE
      return(FALSE)
    }
  )
}

# Print method for better display
method(print, sqlite_mng) <- function(self) {
  cat("SQLiteManager\n")
  cat("  Database:", self@db_path, "\n")
  cat("  Connected:", self@store$is_connected, "\n")
  cat("  Connection:", "\n")
  print(get_connection(self))
  invisible(self)
}

# Now you can use it:
db <- sqlite_mng("api/data/dummy_data.db", max_retries = 3L)
db_connect(db) # This modifies the connection in the environment
is_connected(db) # Should return TRUE if connection is alive
