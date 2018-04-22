
library(ggplot2movies)
library(tidyverse)
library(scales)

function(input, output) {
  
  # reactive plot
  
  output$moviePlot = renderPlot({
    
    # set up data
    
    budgetByYear = summarise(group_by(movies, year), 
                             m = mean(budget, na.rm = TRUE))
    
    budgetByYear = budgetByYear[complete.cases(budgetByYear), ]
    
    # set up smoothed data
    
    smoothData = subset(budgetByYear, 
                        year > quantile(year, 
                                        input$animation / 100) &
                        year <= quantile(year, 
                                         (input$animation + 20) / 100))
    
    # plot
    
    ggplot(budgetByYear, 
           aes(x = year, y = m)) + geom_line() + 
      scale_y_continuous(labels = scales::comma) +
      ggtitle(input$title) + 
      geom_smooth(data = smoothData,
                  method = "lm",
                  colour = "black")
    
  })
  
}
