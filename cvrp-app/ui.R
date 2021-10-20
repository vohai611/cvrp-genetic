library(shiny)
library(here)
library(tidyverse)
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

ui = fluidPage(
  
  titlePanel("C-VRP"),
  
  sidebarLayout(
    
    sidebarPanel(
      # choose problem
      selectInput("benchmark_file",label = "Choose bench mark file:",choices = benchmark_file),
      actionButton("preview", "Preview data"),
      # choose algorithm
      radioButtons("algo", "Choose algorithm", 
                   choices = c("Nearest neighbor", "Genetic", "Simulated annealing")),
      h2("Choose parameter"),
      parameter_tabs,
      actionButton("run", "Run")
    ),
    
    mainPanel(
      tabsetPanel(
        tabPanel("Preview data",tableOutput("preview_data")),
        tabPanel("Result",
                 div(style = 'overflow-y: scroll', verbatimTextOutput("result")),
                 fluidRow(plotOutput("plot_result"))
                ),
        tabPanel("Addtional", textOutput('console'))
        )
        )
     
      
    )
    )
  

# test UI
# server_test = function(input, output, session){}
#  shinyApp(ui, server_test)

