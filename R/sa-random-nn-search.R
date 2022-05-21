# SA function

# temp function
current_temp = function(iter, init_temp= 100, .fun = c("normal", "square", "log"), alpha) {
  .fun = match.arg(.fun)
  switch (.fun,
    normal = init_temp / (1+alpha * iter),
    square = init_temp/ (1+ alpha * iter^2),
    log = init_temp/ (1+ alpha * log(1 + iter))
  )
  
}



# simulated annealing function

sa_search = function(fitness, distance,x,  
                     niter = 10000, init_temp= 1000, .fun= "normal", alpha = .1) {

  # p stand for path
  # f stand for fitness
  # cur
  # best
  # neighbor
  
  best_p <- cur_p <- neighbor_p <- x
  best_f <- cur_f <- neighbor_f <- exec(fitness, x = x, distance = distance)
  
  if(length(x) ==1) return(lst(niter, best_p, best_f))
  
  
  for( i in 1:niter) {
    message(i)
   
    temp = current_temp(i, init_temp, .fun, alpha)
    
    # find neighbor by chose two nodes and reverse the line
    swap = sample(length(x), 2)
    neighbor_p[swap[1]:swap[2]] = rev(cur_p[swap[1]:swap[2]])
     
    neighbor_f = exec(fitness,x = neighbor_p,distance = distance )
    
    # update current state
    if (neighbor_f > cur_f || runif(1) < exp(-(neighbor_f - cur_f) / temp) ) {
      cur_p = neighbor_p
      cur_f = neighbor_f
    }
    # update best state
    if ( neighbor_f >  best_f) {
      message(paste("find new best:", best_f))
      best_p = neighbor_p
      best_f = neighbor_f
    }
  }
  return(lst(niter, best_p, best_f))
}



# SA for sub tour by random nn ---------------------------------------------------------------------------

# gen route by random nn
fbest_random_nn = function(capacity, demand, distance, rep = 100) {
  best  = random_nn(capacity, demand,distance)
  
  for(i in 1:rep)  {
    message(i)
    cur = random_nn(capacity,demand, distance)
    if( cur$distance < best$distance) best = cur
  }
  best
}



# divide large route to sub tour (tour start and end at depot)
divide_subtour = function(path) {
  sub_tour = which(path == 1)
  cut_path = list()
  for(i in 1:(length(sub_tour)-1)) {
    cut_path[[i]] = path[sub_tour[i]:sub_tour[i+1]]  
  }
  cut_path %>% 
    modify(~ .x[.x!= 1])
}


# fitness for sub route only
subtour_fitness = function(x, distance) {
  x= c(1,x,1)
  compute_distance(x,distance)
}

# run simulated annealing for each sub tour (list input)
sa_tour  = function(path, distance, niter= 10000, init_temp= 1000, .fun= "normal", alpha = .1){
  path %>% 
    modify(~ { .x %>% 
        sa_search(fitness = subtour_fitness ,distance= distance,
                  x = ., niter = niter, init_temp = init_temp, .fun = .fun, alpha = alpha) %>% 
        .$best_p
    })
}

result_sa_tour = function(sa_tour) {
  sa_tour %>% 
    modify(~c(.x,1)) %>% 
    reduce(c,.init = 1)
}
