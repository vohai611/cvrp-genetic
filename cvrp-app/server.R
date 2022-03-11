library(shiny)
library(here)
library(tidyverse)
source(here("R/utils.R"))
source(here("R/random_nn.R"))
source(here("R/sa-random-nn-search.R"))
source(here("R/fitness-func.R"))

server <- function(input, output, session) {
  observeEvent(input$algo, {
    updateTabsetPanel(session = session, "algo_tab", selected  = input$algo)
  })
  
  # Process input
  file = eventReactive(input$preview, input$benchmark_file)
  
  file_data = reactive(read_vrp_bench(file()))
  
  
  # preview data
  
  output$preview_data = renderTable({
    req(input$preview)
    isolate(file_data()$file)
  })
  
  # preview data plot 
  output$preview_data_plot = renderPlot({
    req(input$preview)
    file_data()$file %>% map_preview()
  })
  
  # write output
  search_result = reactive({
    req(input$run)
    
    isolate({
      if(input$algo == "Nearest neighbor") {
        x = fbest_random_nn(capacity = file_data()$capacity,
                            file_data()$file$demand,
                            file_data()$distance, rep = input$nn_iter)
        
      } else if ( input$algo == "Genetic") {
        suggest_pop = suggest_random_nn(100, 
                                        capacity = file_data()$capacity,
                                        demand = file_data()$file$demand, 
                                        distance = file_data()$distance)
        
        # run GA
        library(GA)
        rs = ga(type = "permutation", fitness = fitness,
                capacity = file_data()$capacity,
                demand = file_data()$file$demand,
                distance  = file_data()$distance, 
                lower = 2, upper = nrow(file_data()$file), 
                mutation = gaperm_swMutation, popSize = 100,
                pmutation = input$ga_pmutation,
                maxiter = input$ga_maxiter,
                suggestions = suggest_pop)
        
        
        x= list()
        x$path = rs@suggestions[1,] %>% gen_route(file_data()$capacity, file_data()$file$demand)
        x$distance = -rs@fitnessValue
        
      } else if (input$algo == "Simulated annealing") {
        candidate = fbest_random_nn(file_data()$capacity, 
                                    file_data()$file$demand,
                                    file_data()$distance,
                                    rep = 100)
        
        a = candidate$path %>% divide_subtour() %>% sa_tour(distance = file_data()$distance,
                                                            niter = input$sa_iter,
                                                            init_temp = input$sa_init_temp,
                                                            .fun = input$sa_temp_func,
                                                            alpha= input$sa_alpha
                                                            )
        
        x = list()
        x$path = a %>% result_sa_tour()
        x$distance = a %>% result_sa_tour() %>% 
          fitness(file_data()$capacity, file_data()$file$demand, file_data()$distance)
        x$distance = - x$distance
      }
      x
      })
  })
  
  # render resultl: path + total distance
  
  output$result = renderText({
    req(input$run)
    
    isolate({
    paste(paste(search_result()$path, collapse = " "),
          "\nResult distance:", search_result()$distance)
    })
  })
  
  # draw visualize vrp
  output$plot_result = renderPlot({
    req(input$run)
    isolate({
    vrp_map(file_data(), search_result())
    })

  })
  
  
 
  
}


