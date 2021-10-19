# random nearest neighbor
random_nn = function(capacity, demand, distance) {
  path = 1
  all_point = 2:length(demand)
  while (TRUE) {
    if (length(all_point) == 1) {
      path = c(path, all_point, 1)
      break
    }
    if (length(all_point) == 0)
      break
    
    # loop1, diem khoi dau cho 1 route
    cur_cap = capacity
    init = sample(all_point, 1)
    path = c(path, init)
    cur_cap = cur_cap - demand[init]
    # xoa diem
    all_point = all_point[all_point != init]
    # loop 2 nearest neighbor trong loop cho den het capacity
    while (TRUE) {
      avail_point = all_point[demand[all_point] < cur_cap]
      if (length(avail_point) == 0) {
        path = c(path, 1)
        break
      }
      cur_point = distance[avail_point, init] %>% which.min() %>% names() %>% as.numeric()
      if (length(cur_point) == 0)
        cur_point = avail_point
      init = cur_point
      path = c(path, cur_point)
      cur_cap = cur_cap - demand[cur_point]
      all_point = all_point[all_point != cur_point]
    }
  }
  
  total_distance = embed(path , 2) %>% distance[.] %>% sum()
  return(list(path = path, distance =  total_distance))
  
}

# generate multiple random_nn(), (as population for GA )

suggest_random_nn = function(n, capacity, demand, distance) {
  map(1:n,  ~ random_nn(capacity, demand, distance)$path) %>%
    modify( ~ .x[.x != 1]) %>%
    reduce(rbind)
}
