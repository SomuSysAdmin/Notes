
fluidPage(
  
  titlePanel("Graphics control"),
  
  sidebarLayout(
    sidebarPanel(
      selectInput("pickOutput",
                  "Pick output",
                  list("1", "2", "3"))
    ),
    
    mainPanel(
      tabsetPanel(
        tabPanel("Image", imageOutput("image", width = 400, height = 300)),
        tabPanel("ASCII", imageOutput("ASCII", width = 400, height = 300))
      )
    )
  )
)
