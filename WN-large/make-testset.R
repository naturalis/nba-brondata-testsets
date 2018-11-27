library('nbaR')
set.seed(111)

filename <- 'testrecord.json'
str <- readChar(filename, file.info(filename)$size)

sp <- Specimen$new()
sp$fromJSONString(str)

sp$id <- NULL

filenr <- 1
for (i in 1:20000000) {

    if (i%%50000 == 1) {
        cat("Writing file #", filenr, ", index: ", i, "\n")
        sink(paste0('testset_large_', filenr,'.json'))
    }
    
    current.id <- paste0("TEST.", i, ".tt")
    sp$unitID <- current.id
    sp$sourceSystemId=paste0("TEST/", current.id)
    sp$unitGUID <- paste0("http://data.biodiversitydata.nl/naturalis/specimen/TEST/", current.id)
    sp$collectionType <- "testset_large"
    cat('{"index":{}}\n')
    cat(sp$toJSONString(pretty=FALSE), "\n")
    
    if (i%%50000 == 0) {
        filenr <- filenr + 1    
        sink()
    }
}
