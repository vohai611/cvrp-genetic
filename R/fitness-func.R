library(tidyverse)

# generate full route (including path to depot) by supply the order of point to visit
gen_route = function(.order, capacity, demand) {
  names(.order) = .order
  
  ## algorithm
  cur_cap  = capacity
  path = 1
  
  for(i in .order) {
    if (cur_cap < demand[i])  {
      path = c(path, 1,i)
      cur_cap = capacity - demand[i]
    } else {
      path = c(path, i)
      cur_cap = cur_cap - demand[i]
    }
    
  }
  path = c(path, 1)
  path
}

compute_distance = function(path, distance){
  dist = embed(path ,2) %>%
    distance[.] %>% 
    sum()
  - dist
}

Rcpp::sourceCpp("cpp/fitness-func.cpp")

# fitness function (compute distance from the order of point visiting)
fitness = function(.order, capacity, demand, distance) {
  gen_routeC(.order, capacity, demand) %>% 
    compute_distance(distance)
}





