library(shiny)
library(here)
library(tidyverse)
library(GA)

# Rcpp not work on mac M1
if (Sys.info()['machine'] != "x86_64")  gaControl("useRcpp" = FALSE)

source(here("R/utils.R"))
source(here("R/random_nn.R"))
source(here("R/sa-random-nn-search.R"))
source(here("R/fitness-func.R"))

server <- function(input, output, session) {
  observeEvent(input$algo, {
    updateTabsetPanel(session = session, "algo_tab", selected  = input$algo)
  })
  ## hidden UI - input options-----------
  observeEvent(input$input_options,
               { updateTabsetPanel(session = session,"input_tab", selected = input$input_options)
               })
  
  observeEvent(input$preview,{ 
    updateTabsetPanel(session = session, "main_panel", selected = "Preview data")
    output$run_ui = renderUI(actionButton("run", "Run"))
  })
  
  #hide run button if change benchmark file
  observeEvent({
    input$benchmark_file
    input$input_options
  },{
    output$run_ui  = renderUI("")
  })
  
  observeEvent(input$run, 
               updateTabsetPanel(session = session, "main_panel", selected = "Result"))
  
  # Process input
  file_data = eventReactive(input$preview, 
                            if( input$input_options == "Benchmark data") read_vrp_bench(input$benchmark_file) else {
                              read_user_input(input$upload, input$user_capacity)})
  
  ## preview data  ------------
  
  output$preview_data = renderTable({
    req(input$preview)
    isolate(file_data()$file)
  })
  
  # preview data plot 
  output$preview_data_plot = renderPlot({
    req(input$preview)
    file_data()$file %>% map_preview()
  },height = 800)
  
  ## write output------------------------
  search_result = eventReactive(input$run,{
    req(input$run)
    
    # show waiter
    waiter::Waiter$new(id = c("plot_result", "result"),
                       color = waiter::transparent(.6),
                       html = waiter::spin_3())$show()
    
    isolate({
      if(input$algo == "Nearest neighbor") {
        x = withCallingHandlers({fbest_random_nn(capacity = file_data()$capacity,
                                                 file_data()$file$demand,
                                                 file_data()$distance, rep = input$nn_iter)},
                                message = function(m) {
                                  x = current_progress( 100 *as.numeric(m$message) / input$nn_iter)
                                  if (is.na(x)) current_progress() else x
                                  updateProgressBar(session, id = "progress_feedback", value = current_progress(), total = 100, unit_mark = "%")
                                  
                                })
        
      } else if ( input$algo == "Genetic") {
        suggest_pop = suggest_random_nn(100, 
                                        capacity = file_data()$capacity,
                                        demand = file_data()$file$demand, 
                                        distance = file_data()$distance)
        
        # run GA
        
        rs = withCallingHandlers({
          shinyjs::html("progress_feedback", " ")
          ga(type = "permutation",
             monitor = TRUE,
             fitness = fitness,
             capacity = file_data()$capacity,
             demand = file_data()$file$demand,
             distance  = file_data()$distance, 
             lower = 2, upper = nrow(file_data()$file), 
             mutation = gaperm_swMutation, popSize = 100,
             pmutation = input$ga_pmutation,
             maxiter = input$ga_maxiter,
             suggestions = suggest_pop)
          
        },
        message = function(m) {
          current_progress({
            x = 100 * str_extract(m$message, "\\d+") |> as.numeric() / input$ga_maxiter
            if (is.na(x)) current_progress() else x
          })
          updateProgressBar(session, id = "progress_feedback", value = current_progress(), total = 100, unit_mark = "%")
        })
        
        x = list()
        x$path = rs@suggestions[1,] %>% gen_route(file_data()$capacity, file_data()$file$demand)
        x$distance = -rs@fitnessValue
        
      } else if (input$algo == "Simulated annealing") {
        candidate = fbest_random_nn(file_data()$capacity, 
                                    file_data()$file$demand,
                                    file_data()$distance,
                                    rep = 100)
        
        a = withCallingHandlers({candidate$path %>% 
          divide_subtour() %>% 
          sa_tour(distance = file_data()$distance,
                  niter = input$sa_iter,
                  init_temp = input$sa_init_temp,
                  .fun = input$sa_temp_func,
                  alpha= input$sa_alpha
          )
        }, message = function(m){
          x = current_progress( 100 *as.numeric(m$message) / input$sa_iter)
          if (is.na(x)) current_progress() else x
          updateProgressBar(session, id = "progress_feedback", value = current_progress(), total = 100, unit_mark = "%")
        })
        
        x = list()
        x$path = a %>% result_sa_tour()
        x$distance = a %>% result_sa_tour() %>% 
          fitness(file_data()$capacity, file_data()$file$demand, file_data()$distance)
        x$distance = - x$distance
      }
      x
    })
  })
  
  ## Progress value -----
  current_progress = reactiveVal(0)
 
  ### hide and reset to 0 progressBar after run 
  observeEvent(req(current_progress() == 100),{
    hide(id = "progress")
    updateProgressBar(session, id = "progress_feedback", value = 0, total = 100, unit_mark = "%")
    
  })
  ### show progress bar after click run
  observeEvent(input$run, {
    shinyjs::show(id = "progress")
  })
  
  ## render result: path + total distance-----
  
  
  output$result = renderText({
    req(input$run)
    
    isolate({
      x = paste(search_result()$path, collapse = " ")
      no_truck = str_count(x, " 1 ") + 1 
      paste("Path:", x, 
            "\nDistance:", search_result()$distance,
            "\nNumber of trucks used:", no_truck)
    })
  })
  
  # draw visualize vrp
  output$plot_result = renderPlot({
    req(input$run)
    isolate({
      vrp_map(file_data(), search_result())
    })
    
  },height = 800)
  
  
  
  
}


