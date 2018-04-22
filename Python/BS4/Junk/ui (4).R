
library(DT)

fluidPage(
  
  # Title panel
  titlePanel("Data tables"),
  
  sidebarLayout(
    sidebarPanel(
      checkboxInput("searchHighlight", "Search highlight"),
      sliderInput("pageLength", "Page length", 
                  min = 5, max = 10, step = 1, value = 5),
      checkboxGroupInput("class", "CSS Class", 
                         list("Compact" = "compact", 
                              "Hover highlighting" = "hover", 
                              "Striped rows" = "stripe")),
      textInput("caption", "Caption", value = "Table 1: Some data"),
      checkboxInput("filter", "Add filter")
      
    ),
    
    mainPanel(
      tabsetPanel(
        tabPanel("Vanilla", dataTableOutput("dataTableVanilla")),
        tabPanel("Format", dataTableOutput("dataTableFormat")),
        tabPanel("Configurable", dataTableOutput("dataTable"), 
                 textOutput("dataTableInteractive"))
      )
    )
  )
)