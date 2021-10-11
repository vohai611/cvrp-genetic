# read vrp files
read_vrp_bench = function(path) {
  
  # metadata
  data = read_lines(path, n_max = 6)
  name = data[c(1,3)]
  
  optimal = data[2] %>% 
    str_extract(" No of trucks: \\d+, Optimal value: \\d+")
  
  metadata = c(name, optimal)
  
  # read capacity
  capacity = data[6] %>% parse_number()
  
  # read and parse file content
  file = read_delim(path, skip = 7, col_names = F, delim = " ")
  
  demand_section = which(file[1] == "DEMAND_SECTION")
  
  
  file1 = file %>%  
    slice_head(n= demand_section - 1 ) %>% 
    select(-X1) %>% 
    rename_with(~c("node", "x", "y")) %>% 
    rowwise() %>% 
    # add noise, to make sure nodes are not in exact same point
    mutate(x= x + runif(1,0,.001))
  
  file2 = file %>% 
    slice((demand_section+1): (nrow(.)- 4)) %>% 
    select(demand = X2)
  
  file = bind_cols(file1, file2)
  
  list(metadata = metadata,
       capacity = capacity,
       file = file)
  
}


  
