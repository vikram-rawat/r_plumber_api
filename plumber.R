# plumber.R

#* Echo back the input
#* @serializer csv
#* @get /echo1
function() {
  main_dt <- list()
  for (i in 1:1e3) {
    main_dt[[i]] <- iris
  }

  result <- data.table::rbindlist(main_dt)

  return(result)
}
