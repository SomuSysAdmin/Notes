
library(ggplot2movies)
library(tidyverse)
library(scales)
library(DT)

moviesSubset = movies %>%
  filter(!is.na(budget)) %>%
  sample_n(100) %>%
  select(title, year, length, budget, rating, votes)

function(input, output) {
  
  output$dataTableVanilla = DT::renderDataTable({
    
    datatable(moviesSubset)
    
  })
  
  output$dataTableFormat = DT::renderDataTable({
    
    datatable(moviesSubset) %>% 
      formatCurrency("budget", "$") %>%
      formatRound("rating", 0) %>% 
      formatStyle("title",  color = 'green') %>%
      formatStyle("year",  backgroundColor = 'red')
    
  })
  
  output$dataTable = DT::renderDataTable({
    
    datatable(moviesSubset, options = list(searchHighlight = input$searchHighlight, 
                                           columnDefs = 
                                             list(list(className = "dt-center", targets = 0)),
                                           pageLength = input$pageLength,
                                           lengthMenu = c(1, 2, 3, 4) * input$pageLength,
                                           order = list(list(1, "asc"), list(4, "desc"))),
              class = paste(input$class),
              rownames = FALSE,
              colnames = c("Year" = 2, "Rating" = 5),
              caption = input$caption,
              filter = ifelse(input$filter, "top", "none"))
    
  })
  
  output$dataTableInteractive = renderText({

    c("You selected the following rows", input$dataTable_rows_selected)

    })
  
}
