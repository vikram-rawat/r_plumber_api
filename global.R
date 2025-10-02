source("dependencies.R")
source("funcs/dm_funcs.R")
# section: ----------------------------------
daemons(3L, dispatcher = FALSE)
everywhere({
  source("dependencies.R")
})
