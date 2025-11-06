# plumber.R

#* Echo back the input
#* @serializer csv
#* @get /
function() {
  return(iris)
}
