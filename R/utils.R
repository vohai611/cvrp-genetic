
# Read benchmark data -----------------------------------------------------------------------------------


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
  
  # compute distance
  distance = dist(file[, c(2,3)], upper =T, diag = T ) %>% as.matrix()
  
  list(metadata = metadata,
       capacity = capacity,
       distance = distance,
       file = file)
  
}

# Read user input file ---------------------------------------------------------------------------------------
read_user_input = function(input, capacity){
   file = read_csv(input$datapath) %>% 
     rename(x = x1, y = x2)
  distance = dist(file[, c(2,3)], upper = T, diag = T ) %>% as.matrix()
  list(file = file, capacity = capacity, distance = distance)
}





# Visualize path ----------------------------------------------------------------------------------------
# color pallete
my_col = paletteer::paletteer_d("ggsci::category20b_d3")

map_preview = function(file){
  
  a1 = file %>% 
    mutate(depot = if_else(node == 1, T, F))
    
  
  a1 %>% 
    ggplot(aes(x,y, color = depot))+
    geom_point(size = 2) +
    geom_label(data=  a1[1, ], label = "DEPOT", color = my_col[9], fill = "transparent", nudge_x = 1, nudge_y = 1)+
    geom_label(data= a1[-1, ], aes(label = demand),nudge_x = 1, nudge_y = .2, color = my_col[2], fill = "transparent")+
    scale_color_manual(values = my_col[1:2])+
    guides(color= "none")+
    labs(title = "Depot and customer **positions**",
         subtitle = "Number in labels are customer demand")+
    theme_light()+
    theme(plot.title = ggtext::element_markdown(family = "Monaco",size = 20))
}

vrp_map = function(file, result) {
  fitness_val = result$distance
  rs_path = result$path
  
  rs_path = rs_path %>% embed(2) %>% 
    as_tibble(.name_repair = ~c("from", "to")) %>% 
    mutate(group = cumsum(to == 1))
  
  
  
  df = file$file %>% left_join(rs_path, by = c("node" = "from")) %>% 
    left_join(file$file, suffix = c("_from", "_to"), by= c('to' = 'node'))
    
    ggplot(df, aes(x = x_from, y_from, color = as_factor(group) ))+
    geom_point(size = 3)+
    geom_label(data=  df[1, ], label = "DEPOT", color = my_col[9], fill = "transparent", nudge_x = 1, nudge_y = 1)+
    geom_curve(aes(xend = x_to, yend =y_to), 
               curvature = 0,
               alpha = .7, show.legend = F)+
    geom_label(data = df[-1, ], 
               aes(label = node), position = position_nudge(x= 1, y = 1),fill = "grey96",
               show.legend = F)+
    labs(title = paste0("Result of data set: ", file$metadata[1]),
         subtitle = paste0("Total distance: ",fitness_val, "\n",
                           file$metadata[3]),
         color= "Sub-tour",
         x = "x",
         y = "y") +
    scale_color_manual(values = my_col) +
    theme_minimal()
}

  
