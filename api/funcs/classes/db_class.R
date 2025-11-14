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
method(print, sqlite_mng) <- function(x) {
  cat("SQLiteManager\n")
  cat("  Database:", x@db_path, "\n")
  cat("  Connected:", x@store$is_connected, "\n")
  cat("  Connection:", "\n")
  print(get_connection(x))
  invisible(x)
}

# Register generics
get_connection <- new_generic("get_connection", "dbm")
# Method to establish connection
method(get_connection, sqlite_mng) <- function(dbm) {
  return(dbm@store$connection)
}


# Register generics
set_connection <- new_generic("set_connection", "dbm")
# Method to establish connection
method(set_connection, sqlite_mng) <- function(dbm, new_connection) {
  dbm@store$connection <- new_connection
  return(invisible(dbm))
}


# Register generics
db_connect <- new_generic("db_connect", "dbm")
# Method to establish connection
method(db_connect, sqlite_mng) <- function(dbm) {
  tryCatch(
    {
      dbm@store$db <- adbcdrivermanager::adbc_database_init(
        adbcsqlite::adbcsqlite(),
        uri = dbm@db_path
      )

      set_connection(
        dbm,
        dbm@store$db |>
          adbcdrivermanager::adbc_connection_init()
      )

      dbm@store$is_connected <- TRUE

      message("Successfully connected to database: ", dbm@db_path)
      return(invisible(dbm))
    },
    error = function(e) {
      stop("Failed to connect to database: ", e$message)
    }
  )
}

# Register generics
is_connected <- new_generic("is_connected", "dbm")
# Method to check if connection is alive
method(is_connected, sqlite_mng) <- function(dbm) {
  if (is.null(get_connection(dbm))) {
    dbm@store$is_connected <- FALSE
    return(FALSE)
  }

  tryCatch(
    {
      # Try a simple query to check connection
      result <- get_connection(dbm) |>
        adbcdrivermanager::read_adbc("SELECT 1")
      dbm@store$is_connected <- TRUE
      return(TRUE)
    },
    error = function(e) {
      dbm@store$is_connected <- FALSE
      return(FALSE)
    }
  )
}

# Register generics
reconnect <- new_generic("reconnect", "dbm")

# Method to reconnect with retries
method(reconnect, sqlite_mng) <- function(dbm) {
  max_retries <- dbm@store$max_retries

  for (attempt in seq_len(max_retries)) {
    tryCatch(
      {
        message("Reconnection attempt ", attempt, " of ", max_retries)
        db_connect(dbm)

        if (is_connected(dbm)) {
          message("Reconnection successful!")
          return(invisible(dbm))
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
db_get_query <- new_generic("db_get_query", "dbm")

# Method to execute query with automatic reconnection
method(db_get_query, sqlite_mng) <- function(dbm, sql_query, ...) {
  tryCatch(
    {
      # Check connection before executing
      if (!is_connected(dbm)) {
        message("Connection lost, attempting to reconnect...")
        reconnect(dbm)
      }

      # Execute query
      result <- execute_query(dbm, sql_query, ...)

      return(result)
    },
    error = function(e) {
      message("Query failed (attempt): ", e$message)
      message("Attempting reconnection and retry...")

      tryCatch(
        {
          reconnect(dbm)
          Sys.sleep(1)
          # Execute query
          result <- execute_query(dbm, sql_query, ...)

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
db_disconnect <- new_generic("db_disconnect", "dbm")

# Method to disconnect
method(db_disconnect, sqlite_mng) <- function(dbm) {
  if (is.null(get_connection(dbm))) {
    message("No active connection to disconnect")
    return(invisible(dbm))
  }

  tryCatch(
    {
      # Run GC to ensure any unreleased Result objects are cleaned up
      gc(full = TRUE) # Clean up before disconnecting

      # first release connection
      adbcdrivermanager::adbc_connection_release(
        get_connection(dbm)
      )

      # then release database
      dbm@store$db |>
        adbcdrivermanager::adbc_database_release()

      set_connection(dbm, NULL)
      dbm@store$is_connected <- FALSE
      message("Disconnected from database: ", dbm@db_path)
    },
    error = function(e) {
      warning("Error during disconnect: ", e$message)
      # Force cleanup even if error occurs
      set_connection(dbm, NULL)
      dbm@store$is_connected <- FALSE
    }
  )

  invisible(dbm)
}

# Helper function for query execution
execute_query <- function(dbm, sql_query, ...) {
  get_connection(dbm) |>
    adbcdrivermanager::read_adbc(sql_query, ...) |>
    data.table::as.data.table()
}

# # # Usage example:
# db <- sqlite_mng("data/dummy_data.db", max_retries = 3L)
# print(db)
# db_connect(db)
# get_connection(db) # Should return a valid connection object
# is_connected(db) # Should return TRUE if connection is alive

# # This will automatically reconnect if there's an issue
# result <- db_get_query(db, "SELECT * FROM iris_data LIMIT 10")

# db_disconnect(db)
# get_connection(db) # Should return NULL after disconnect
# print(db)
