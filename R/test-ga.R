library(tidyverse)
library(tidygraph)
library(ggraph)
library(igraph)
source("R/fitness-func.R")
source("R/random_nn.R")
source("R/utils.R")
## test all my function 

df = read_vrp_bench("data-input/A/A-n69-k9.vrp")

meta_data = df$metadata
capacity =  df$capacity
df = df$file

# compute distance
distance = dist(df[, c(2,3)], upper =T, diag = T ) %>% as.matrix()

best =random_nn(capacity ,demand = df$demand,distance = distance)
# for (i in 1:10000) {
# a= random_nn(capacity ,demand = df$demand,distance = distance)
# print(i)
# if ( a$distance < best$distance) best = a
# }

# generate initial population
suggest_pop = suggest_random_nn(100, capacity = capacity ,demand = df$demand,distance = distance)

# run GA
library(GA)

system.time({
rs = ga(type = "permutation", fitness = fitness,
        capacity =capacity,
        df$demand,
        distance  = distance, 
        lower = 2, upper = max(df$node), 
        mutation = gaperm_swMutation, popSize = 20, pmutation = 0.1, maxiter = 30000,
        suggestions = suggest_pop)
})

# islands GA (limit popsize = 10)

system.time({
  rs = gaisl(type = "permutation", fitness = fitness,
          capacity = capacity,
          df$demand,
          distance  = distance, 
          lower = 2, upper = max(df$node), numIslands = 4,
          mutation = gaperm_swMutation, popSize = 10, pmutation = 0.1, maxiter = 50000, 
          suggestions = suggest_pop,
          run = 2000)
})

# check result
summary(rs)
plot(rs)

# get result distance
fitness_val  = round(rs@fitnessValue,2)

# pull result out
rs_path = rs@solution[1,] %>% 
  gen_route(100, df$demand)


# Visualizing result -------------------------------------------------------------------------------------

rs_path = rs_path %>% embed(2) %>% 
  as_tibble(.name_repair = ~c("from", "to")) %>% 
  mutate(group = cumsum(to == 1))

my_col = paletteer::paletteer_d("ggsci::category20b_d3")


df %>% left_join(rs_path, by = c("node" = "from")) %>% 
  left_join(df, suffix = c("_from", "_to"), by= c('to' = 'node')) %>% 
  ggplot(aes(x = x_from, y_from, color = as_factor(group) ))+
  geom_point()+
  geom_curve(aes(xend = x_to, yend =y_to), 
             arrow = arrow(angle = 10, type = "closed"), 
             curvature = 0,
             alpha = .2)+
  geom_label(aes(label = node), position = position_nudge(x= 1, y = 1))+
  labs(title = paste("Result", meta_data[1]),
       subtitle = paste0("Total distance: ",fitness_val, "\n",
                         meta_data[3])) +
  scale_color_manual(values = my_col) +
  theme_void()
  

route
