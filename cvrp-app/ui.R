library(shiny)
library(here)
library(tidyverse)
library(waiter)
library(shinyjs)
library(shinyWidgets)
source(here("R/utils.R"))

benchmark_file = list.files(here("benchmark-data/A/"), pattern = "*.vrp",full.names = TRUE)
names(benchmark_file) = list.files(here("benchmark-data/A/"), pattern = "*.vrp")


parameter_tabs <- tabsetPanel(
  id = "algo_tab",
  type = "hidden",
  tabPanel("Nearest neighbor",
           numericInput("nn_iter", "Numer of iteration", value = 1, min = 1, max =1000)
  ),
  tabPanel("Genetic", 
           numericInput("ga_maxiter", "Number of generation:", min = 10, max = 2000,
                       value = 100),
           sliderInput("ga_pmutation", "Permutation ratio", min = 0, max = 0.4, value = 0.1)
  ),
  tabPanel("Simulated annealing",
           numericInput("sa_iter", "Number of iteration", value = 100, min = 100, max = 2000),
           numericInput("sa_init_temp", "Initial temperature", value= 100, min =100, max =1000),
           radioButtons("sa_temp_func", "Temperatutre function: ", choices = c("normal", "square", "log")),
           sliderInput("sa_alpha", "Alpha", value = 0.1, min = 0.1, max = 0.5, step = 0.05)
  )
)

input_option_tab = tabsetPanel(
  id = "input_tab",
  type = "hidden",
  tabPanel("Benchmark data",
           selectInput("benchmark_file",label = "Choose bench mark file:", choices = benchmark_file),
  ),
  tabPanel("User data",
           fileInput("upload", 'Upload', placeholder = "Accept CSV as Benchmark data form"),
           numericInput("user_capacity", "Truck capacity", min = 1, max = 2000,value = 100)))


ui = fluidPage(
  useShinyjs(),
  waiter::use_waiter(),
  
  titlePanel("C-VRP solver using heuristic algorithms"),
  
  sidebarLayout(fluid = T,
    
    sidebarPanel(width = 3,
      # choose problem ----------
      radioButtons("input_options", h3("Input data"), 
                   choices = c("Benchmark data", "User data")),
      input_option_tab,
      actionButton("preview", "Preview data"),
      # choose algorithm ---------
      radioButtons("algo", h3("Choose algorithm"), 
                   choices = c("Nearest neighbor", "Genetic", "Simulated annealing")),
      h3("Algorithm parameters"),
      parameter_tabs,
      uiOutput("run_ui"),
      progressBar(id = "progress_feedback",
                  value = 0,total = 100,  display_pct = TRUE)
    
    ),
    
    mainPanel(width = 9,
      tabsetPanel(
        id = "main_panel",
        tabPanel("Preview data",
                 br(),
                 column(3,
                   tableOutput("preview_data")
                 ),
                 column(6,
                 plotOutput("preview_data_plot", width= "120%"),
                 )
                 ),
        tabPanel("Result",
                 column(8, 
                        div(style = 'overflow-y: scroll; width:100%', verbatimTextOutput("result")),
                        plotOutput("plot_result",width = "120%")
                        )
                )
        #tabPanel("Addtional", textOutput('console'))
        )
        )
     
      
    )
    )
  

# test UI
# server_test = function(input, output, session){}
#  shinyApp(ui, server_test)

