library(shiny)
library(here)
benchmark_file = file = list.files(here("benchmark-data/A/"), pattern = "*.vrp")

parameter_tabs <- tabsetPanel(
  id = "params",
  type = "hidden",
  tabPanel("Nearest neighbor",
           numericInput("mean", "mean", value = 1),
           numericInput("sd", "standard deviation", min = 0, value = 1)
  ),
  tabPanel("Genetic", 
           sliderInput("maxiter", "Choose number of generation:", min = 10, max = 2000,
                       value = 100),
           # set seed
           numericInput("seed", "Set seed:", value = 1),
  ),
  tabPanel("Simulated annealing",
           numericInput("rate", "rate", value = 1, min = 0),
  )
)

ui <- fluidPage(
  
  titlePanel("C-VRP"),
  
  sidebarLayout(
    
    sidebarPanel(
      # choose problem
      selectInput("benchmark_file",label = "Choose bench mark file:",choices = benchmark_file),
      # choose algorithm
      radioButtons("algo", "Choose algorithm", choices = c("Nearest neighbor", "Genetic", "Simulated annealing")),
      h2("Choose parameter"),
      li
      parameter_tabs,
    ),
    mainPanel()
    )
  )

# test UI
server = function(input, output, session){
  observeEvent(input$algo, {
    updateTabsetPanel(session = session, "params", selected  = input$algo)
  })
}
shinyApp(ui, server)
