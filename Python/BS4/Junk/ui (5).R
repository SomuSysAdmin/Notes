
library(DT)

fluidPage(
  
  sidebarLayout(
    sidebarPanel(
      downloadButton("downloadData", "Download data"),
      fileInput("file", "Upload data")

    ),
    
    mainPanel(
      dataTableOutput("table"),
      dataTableOutput("updatedTable")
      )
    )
  )