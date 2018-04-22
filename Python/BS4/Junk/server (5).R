
library(tidyverse)
library(ggplot2movies)
library(DT)

moviesSubset = movies %>%
  filter(!is.na(budget)) %>%
  sample_n(10) %>%
  select(title, year, length, budget, rating, votes)

function(input, output) {
  
  output$table = DT::renderDataTable({
    
    datatable(moviesSubset)
  })
  
  output$downloadData = downloadHandler(filename = "data.csv",
    content = function(file) {
      
      if(!is.null(input$table_rows_selected)){
        
        theData = moviesSubset[input$table_rows_selected, ]
        
      } else {
        
        theData = moviesSubset
      }
      
      write.csv(theData, file)
    }
  )
  
  output$updatedTable <- DT::renderDataTable({

    if (is.null(input$file)) return()
    
    datatable(read.csv(input$file$datapath))
  })
  
}
