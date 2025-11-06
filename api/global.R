source("dependencies.R")
source("api/funcs/dm_funcs.R")
# section: ----------------------------------
{
  daemons(1L, dispatcher = FALSE)
  everywhere({
    source("dependencies.R")
  })
}
