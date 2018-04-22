library(png)

function(input, output){
  
  output$image = renderImage({
    
    list(src = paste0('Cats', input$pickOutput, '.jpg'),
         contentType = 'image/jpeg',
         width = 400)
  }, deleteFile = FALSE)
  
  output$ASCII = renderImage({
    
    theText = "0111001101101000011010010110111001111001001000000111001001110101011011000110010101110011"
    
    myBin = as.numeric(unlist(strsplit(theText, split = NULL)))
    
    myBin = rep(myBin, each = 5)
    
    writePNG(matrix(rep(myBin, 100), byrow = TRUE, ncol = 440), target = "temp.png")
    
    list(src = "temp.png",
         contentType = 'image/png',
         width = 600)
  }, deleteFile = TRUE)
    
}