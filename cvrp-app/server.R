library(shiny)
library(here)
library(tidyverse)
source(here("R/utils.R"))
source(here("R/random_nn.R"))
source(here("R/sa-random-nn-search.R"))
source(here("R/fitness-func.R"))
vrp_map = function(file, result) {
  fitness_val = result$distance
  rs_path = result$path
  
  rs_path = rs_path %>% embed(2) %>% 
    as_tibble(.name_repair = ~c("from", "to")) %>% 
    mutate(group = cumsum(to == 1))
  
  my_col = paletteer::paletteer_d("ggsci::category20b_d3")
  
  
  file$file %>% left_join(rs_path, by = c("node" = "from")) %>% 
    left_join(file$file, suffix = c("_from", "_to"), by= c('to' = 'node')) %>% 
    ggplot(aes(x = x_from, y_from, color = as_factor(group) ))+
    geom_point()+
    geom_curve(aes(xend = x_to, yend =y_to), 
               arrow = arrow(angle = 10, type = "closed"), 
               curvature = 0,
               alpha = .7, show.legend = F)+
    geom_label(aes(label = node), position = position_nudge(x= 1, y = 1),
               show.legend = F)+
    labs(title = paste0("Result of data set: ", file$metadata[1]),
         subtitle = paste0("Total distance: ",fitness_val, "\n",
                           file$metadata[3]),
         color= "Sub-tour") +
    scale_color_manual(values = my_col) +
    theme_void()
}



server <- function(input, output, session) {
  observeEvent(input$algo, {
    updateTabsetPanel(session = session, "algo_tab", selected  = input$algo)
  })
  
  # Process input
  file = eventReactive(input$preview, input$benchmark_file)
  nn_iter = eventReactive(input$preview, input$nn_iter)
  
  file_data = reactive(read_vrp_bench(file()))
  
  
  # run and get the result
  
  output$preview_data = renderTable({
    req(input$preview)
    isolate(file_data()$file)
  })
  
  # write output
  search_result = reactive({
    req(input$run)
    
    isolate({
      if(input$algo == "Nearest neighbor") {
        x = fbest_random_nn(capacity = file_data()$capacity,
                            file_data()$file$demand,
                            file_data()$distance, rep = nn_iter())
        
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
        x$path = rs@suggestions[1,] %>% gen_route(df$capacity, df$file$demand)
        x$distance = -rs@fitnessValue
        
      } else if (input$algo == "Simulated Annealing") {
      x= 2
      }
      x
      })
  })
  
  output$result = renderText({
    paste(paste(search_result()$path, collapse = " "),
          "\nResult distance: ", search_result()$distance)
  })
  
  
  output$plot_result = renderPlot({
    vrp_map(file_data(), search_result())

  })
  
  
}
shinyApp(ui, server)


