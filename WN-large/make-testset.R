library('nbaR')
library('lexicon')
library('countrycode')
set.seed(111)

filename_sp<- 'testrecord-specimen.json'
str_sp <- readChar(filename_sp, file.info(filename_sp)$size)

filename_mm<- 'testrecord-multimedia.json'
str_mm <- readChar(filename_mm, file.info(filename_mm)$size)

sp <- Specimen$new()
sp$fromJSONString(str_sp)

mm <- MultiMediaObject$new()
mm$fromJSONString(str_mm)

sp$id <- NULL
mm$id <- NULL

filenr <- 1
for (i in 1:20000000) {
    
    
    ## Specimen record
    current.id <- paste0("TEST.", i, ".tt")
    sp$unitID <- current.id
    sp$sourceSystemId=paste0("TEST/", i)
    sp$unitGUID <- paste0("http://data.biodiversitydata.nl/naturalis/specimen/TEST/", current.id)
    sp$collectionType <- "Observations"  
    sp$assemblageID <- paste0(i, "@OBS")
    sp$sourceSystem$code <- "OBS"
    sp$sourceSystem$name <- "Observation.org - Nature observations"
    
    
    ## put some random stuff in there!
    last <- sample(freq_last_names$Surname, 1)
    first <- sample(freq_first_names$Name, 1)
    second <- paste0(sample(LETTERS, 1), ".")
    sp$collectorsFieldNumber <- paste0(last, ", ", first, " ", second)
    
    continent <- codelist$continent[! is.na(codelist$continent)][sample(1:length(codelist$continent[! is.na(codelist$continent)]))[1]]
    country <- sample(codelist$country.name.en, 1)
    sp$gatheringEvent$worldRegion <- continent
    sp$gatheringEvent$continent <- continent
    sp$gatheringEvent$country <- country
    p <- Person$new()
    p$fullName <- paste0(last, ", ", first, " ", second)
    sp$gatheringEvent$gatheringPersons <- list(p)

    str <- sample(sw_jockers, 1)
    str2 <- sample(sw_fry_1000, 1)
    str <- paste(str, str2)
    sp$gatheringEvent$locality <- str
    sp$gatheringEvent$localityText <- paste(continent, country, str, sep=",")

    scname <- paste(sample(key_sentiment_jockers$word, 1), sample(sw_fry_1000, 1))
    sp$identifications[[1]]$scientificName$fullScientificName <- scname

    ## Multimedia record
    mm$unitID <- current.id
    mm$collectionType <- "Observations"  
    mm$associatedSpecimenReference <- current.id
    mm$gatheringEvents <- list(sp$gatheringEvent)
    mm$sourceSystemId <- as.character(i)
    mm$unitID <- paste0("OBS.", i, "_img")
    sa <- ServiceAccessPoint$new()
    sa$format <- "image/jpeg"
    sa$variant <- "Best Quality"
    sa$accessUri <- paste0("https://observation.org/photo/", i, ".jpg")
    mm$serviceAccessPoints <- list(sa)    
    cat('{"index":{}}\n', append=TRUE, file=paste0('specimen-', filenr, '.json'))
    cat('{"index":{}}\n', append=TRUE, file=paste0('multimedia-', filenr, '.json'))
    cat(sp$toJSONString(pretty=FALSE), "\n", append=TRUE, file=paste0('specimen-', filenr, '.json'))
    cat(mm$toJSONString(pretty=FALSE), "\n", append=TRUE, file=paste0('multimedia-', filenr, '.json'))
    
    if (i%%50000 == 0) {
        filenr <- filenr + 1    
	cat("Wrote set #", filenr, " to file")
    }
}


