fluidPage(
  
  # Title panel
  titlePanel("Animated trend"),
  
  # Typical sidebar layout with text input
  sidebarLayout(
    sidebarPanel(
       textInput("title", "Plot title", value = "Your title here"),
       sliderInput("animation", "Trend over time",
                   min = 0, max = 80, value = 0, step = 5,
                   animate = animationOptions(interval = 1000, loop = TRUE))
    ),
    
    # Plot is placed in main panel
    mainPanel(
       plotOutput("moviePlot")
    )
  )
)
