library(here)
library(tidyverse)
library(tidygraph)
library(ggraph)
library(igraph)
source("R/fitness-func.R")
source("R/random_nn.R")
source("R/utils.R")
source("R/sa-random-nn-search.R")

# read input

df = read_vrp_bench(here("benchmark-data/A/A-n33-k5.vrp"))

meta_data = df$metadata
capacity =  df$capacity
distance = df$distance
df = df$file


# generate multiple random_nn() path and divide each path to subtour:

candidate = fbest_random_nn(capacity, df$demand, distance, rep = 1000)


a = candidate$path %>% divide_subtour() %>% sa_tour(distance = distance,
                                                   niter = 100000,
                                                   init_temp = 1000)

# pull path output
a %>% result_sa_tour()
# pull total distance out

a %>% result_sa_tour() %>% 
  fitness(capacity, df$demand, distance)

