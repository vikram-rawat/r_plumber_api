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
    store_env$db <- NULL
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

# Print method for better display
method(print, sqlite_mng) <- function(self) {
  cat("SQLiteManager\n")
  cat("  Database:", self@db_path, "\n")
  cat("  Connected:", self@store$is_connected, "\n")
  cat("  Connection:", "\n")
  print(get_connection(self))
  invisible(self)
}

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
      self@store$db <- adbcdrivermanager::adbc_database_init(
        adbcsqlite::adbcsqlite(),
        uri = self@db_path
      )

      set_connection(
        self,
        self@store$db |>
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

# Register generics
reconnect <- new_generic("reconnect", "self")

# Method to reconnect with retries
method(reconnect, sqlite_mng) <- function(self) {
  max_retries <- self@store$max_retries

  for (attempt in seq_len(max_retries)) {
    tryCatch(
      {
        message("Reconnection attempt ", attempt, " of ", max_retries)
        db_connect(self)

        if (is_connected(self)) {
          message("Reconnection successful!")
          return(invisible(self))
        }
      },
      error = function(e) {
        if (attempt < max_retries) {
          message("Reconnection failed: ", e$message)
          message("Waiting 1 second before retry...")
          Sys.sleep(1)
        } else {
          stop(
            "Failed to reconnect after ",
            max_retries,
            " attempts: ",
            e$message
          )
        }
      }
    )
  }

  stop("Failed to reconnect after ", max_retries, " attempts")
}

# Register generics
db_get_query <- new_generic("db_get_query", "self")

# Method to execute query with automatic reconnection
method(db_get_query, sqlite_mng) <- function(self, sql_query, ...) {
  tryCatch(
    {
      # Check connection before executing
      if (!is_connected(self)) {
        message("Connection lost, attempting to reconnect...")
        reconnect(self)
      }

      # Execute query
      result <- get_connection(self) |>
        adbcdrivermanager::read_adbc(sql_query, ...) |>
        data.table::as.data.table()

      return(result)
    },
    error = function(e) {
      message("Query failed (attempt): ", e$message)
      message("Attempting reconnection and retry...")

      tryCatch(
        {
          reconnect(self)
          Sys.sleep(1)
          # Execute query
          result <- get_connection(self) |>
            adbcdrivermanager::read_adbc(sql_query, ...) |>
            data.table::as.data.table()
          return(result)
        },
        error = function(reconnect_error) {
          stop("Failed to recover from error: ", reconnect_error$message)
        }
      )
    }
  )
}

# Register generic
db_disconnect <- new_generic("db_disconnect", "self")

# Method to disconnect
method(db_disconnect, sqlite_mng) <- function(self) {
  if (is.null(get_connection(self))) {
    message("No active connection to disconnect")
    return(invisible(self))
  }

  tryCatch(
    {
      self@store$db |> adbcdrivermanager::adbc_database_release()
      adbcdrivermanager::adbc_connection_release(get_connection(self))
      set_connection(self, NULL)
      self@store$is_connected <- FALSE
      message("Disconnected from database: ", self@db_path)
    },
    error = function(e) {
      warning("Error during disconnect: ", e$message)
      # Force cleanup even if error occurs
      set_connection(self, NULL)
      self@store$is_connected <- FALSE
    }
  )

  invisible(self)
}

# # Usage example:
# db <- sqlite_mng("api/data/dummy_data.db", max_retries = 3L)
# print(db)
# db_connect(db)
# get_connection(db) # Should return a valid connection object
# is_connected(db) # Should return TRUE if connection is alive

# # This will automatically reconnect if there's an issue
# result <- db_get_query(db, "SELECT * FROM iris_data LIMIT 10")

# db_disconnect(db)
# get_connection(db) # Should return NULL after disconnect
# print(db)
