# plumber.R

#* Echo back the input
#* @serializer csv
#* @get /echo
return_msg

#* Plot a histogram
#* @serializer png
#* @get /plot
return_plot

#* Return the sum of two numbers
#* @param a The first number to add
#* @param b The second number to add
#* @post /sum
return_sum
