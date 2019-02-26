require('nbaR')
require('httr')

base_url <- "http://145.136.242.167:8080/v2"

## dataframe with summary of which is updated, deleted, etc
ids <- list()
ids$specimen <- list()
ids$multimedia <- list()
ids$taxon <- list()

## scenario 3) update taxa and enrichments, check impact for specimen
##    Start:
##           specimen: BRAHMS (20), 10 match with NSR and 10 match with COL (SNG match)
##           multimedia: BRAHMS (>=20)
##           taxon: NSR, COL (whole)

sc <- SpecimenClient$new(basePath=base_url)
tc <- TaxonClient$new(basePath=base_url)
mc <- MultimediaClient$new()

dir <- "3_start"
dir.create(dir)

specimens <- NULL
taxa <- NULL
multimedia <- NULL

## sngs <- c('vitex pinnata', 'dracocephalum parviflorum')

##qc1 <- QueryCondition$new(field="defaultClassification.kingdom", operator="EQUALS", value="Plantae")
##qc2 <- QueryCondition$new(field="sourceSystem.code", operator="EQUALS", value="NSR")

##qs <- QuerySpec$new(size=10000, conditions=list(qc1, qc2))
##res <- tc$query(querySpec=qs)
##sngs <- unique(sapply(res$content$resultSet, function(x)x$item$acceptedName$scientificNameGroup))

for (ss in c('NSR', 'COL')) { 

    ## get sngs from BRAHMS with 
    qc1 <- QueryCondition$new(field="defaultClassification.kingdom", operator="EQUALS", value="Plantae")
    qc2 <- QueryCondition$new(field="sourceSystem.code", operator="EQUALS", value=ss)
    qs <- QuerySpec$new(size=1000, conditions=list(qc1, qc2))
    res <- tc$query(querySpec=qs)
    all_sngs <- unique(sapply(res$content$resultSet, function(x)x$item$acceptedName$scientificNameGroup))
    cnts <- sapply(all_sngs, function(x){
        res <- sc$query(queryParams=list("identifications.scientificName.scientificNameGroup"=x))
        cnt <- 0
    for (r in res$content$resultSet) {
        cnt <- cnt + length(r$item$associatedMultiMediaUris)
    }
        cnt
    }
    )
    ## take first 10 SNGs for which we have specimens with multimedia
    sngs <- names(sort(cnts, decreasing=T)[1:10])
    cat("SNGs: \n")
    cat(sngs)
    cat("\n")
    
    for (sng in sngs) {
        
        ## take specimen matching COL SNG 'bombus terrestris', with some multimedia
        qc <- QueryCondition$new(field="identifications.scientificName.scientificNameGroup",
                                 operator="EQUALS",
                                 value=sng)
##        qc2 <- QueryCondition$new(field="associatedMultiMediaUris.format",
##                                  operator="NOT_EQUALS")
##        qc3 <- QueryCondition$new(field="sourceSystem.code",
##                                  operator="EQUALS",
##                                  value="BRAHMS")    
        qs <- QuerySpec$new(size=1000, conditions=list(qc))##, qc2, qc3))
        res <- sc$query(querySpec=qs)
        cat("Found ", res$content$totalSize, " specimens\n")
        
        ## select a specimen 
        specimens <- c(specimens, lapply(res$content$resultSet, function(x)x$item)[1])
        
        res <- tc$query(queryParams=list("acceptedName.scientificNameGroup"=sng, "sourceSystem.code"=ss))
        taxa <- c(taxa, lapply(res$content$resultSet, function(x)x$item))    
    }
}

## get the multimedia documents associated with our specimens
spec_ids <- sapply(specimens, function(x)x$id)

for (sp in spec_ids) {
    cat("Species id : ", sp, "\n")
    res <- mc$query(queryParams=list(associatedSpecimenReference=sp))
    cat("Number of multimedia hits: ", res$content$totalSize, "\n")
    if (res$content$totalSize == 0) {
        cat("No multimedia for ", sp, "\n")
    }
    else {
        mms <- lapply(res$content$resultSet, function(x)x$item)
        multimedia <- c(multimedia, mms)
    }    
}

## write specimen to file
file <- file.path(dir, 'specimen.json')
cat(sapply(specimens, function(x)x$toJSONString(pretty=FALSE)), file=file, sep="\n")

## write taxa to file
file <- file.path(dir, 'taxa.json')
cat(sapply(taxa, function(x)x$toJSONString(pretty=FALSE)), file=file, sep="\n")

## write multimedia to file
file <- file.path(dir, 'multimedia.json')
cat(sapply(multimedia, function(x)x$toJSONString(pretty=FALSE)), file=file, sep="\n")

## extract ids
ids$specimen$initial <- sapply(specimens, function(x)x$id)
## ids$taxon$initial <- sapply(taxa, function(x)x$id)
ids$multimedia$initial <- sapply(multimedia, function(x)x$id)

##    Test:
##           specimen: BRAHMS (20), all updated with new SNG
##           multimedia: BRAHMS, updated with new SNG
##           taxon: NSR, COL, delete 5 records each, update SNGs in 10 records!

dir <- "3_test"
dir.create(dir)

## update specimens
specimens_test <- lapply(specimens, function(x){
    sng <- x$identifications[[1]]$scientificName$scientificNameGroup
    x$identifications[[1]]$scientificName$scientificNameGroup <- paste(sng, "updated")
    x
}
)
ids$specimen$updated <- sapply(specimens_test, function(x)x$id)

## update multimedia
multimedia_test <- lapply(multimedia, function(x){
    sng <- x$identifications[[1]]$scientificName$scientificNameGroup
    x$identifications[[1]]$scientificName$scientificNameGroup <- paste(sng, "updated")
    x
}
)
ids$multimedia$updated <- sapply(multimedia_test, function(x)x$id)

## update taxa
taxa_test <- lapply(taxa, function(x){
    sng <- x$acceptedName$scientificNameGroup
    x$acceptedName$scientificNameGroup <- paste(sng, "updated")
    x
}
)
ids$taxa$updated <- sapply(taxa_test, function(x)x$id)

## save specimen
file <- file.path(dir, 'specimen.json')
cat(sapply(specimens_test, function(x)x$toJSONString(pretty=FALSE)), file=file, sep="\n")

## save multimedia
file <- file.path(dir, 'multimedia.json')
cat(sapply(multimedia_test, function(x)x$toJSONString(pretty=FALSE)), file=file, sep="\n")

## save taxa
file <- file.path(dir, 'taxa.json')
cat(sapply(taxa_test, function(x)x$toJSONString(pretty=FALSE)), file=file, sep="\n")

## delete 5 taxa from COL and NSR
delete_col <- sapply(tc$query(queryParams=list(sourceSystem.code="COL"))$content$resultSet[1:5], function(x)x$item$id)
delete_nsr <- sapply(tc$query(queryParams=list(sourceSystem.code="NSR"))$content$resultSet[1:5], function(x)x$item$id)

ids$taxa$deleted <- c(delete_col, delete_nsr)

## make files with records removed, move to directory and zip!
system(paste0("grep -v \"", paste(delete_nsr, collapse="\\|"), "\" nsr.json > nsr_test.json && mv nsr_test.json ", dir))
system(paste0("grep -v \"", paste(delete_col, collapse="\\|"), "\" col.json > col_test.json && mv col_test.json ", dir))
system(paste0("zip nsr_test.json.zip ", dir, "/nsr_test.json"))
system(paste0("zip col_test.json.zip ", dir, "/col_test.json"))


## write ids to file
dfsp <- stack(ids$specimen)
dfsp$type <- 'specimen'

dfmm <- stack(ids$multimedia)
dfmm$type <- 'multimedia'

dftx <- stack(ids$taxa)
dftx$type <- 'taxon'


df <- rbind(dfsp, dfmm, dftx)
colnames(df) <- c('id', 'status', 'datatype')

write.table(df, file.path(dir, 'ids.tsv'), sep='\t', row.names=FALSE, quote=FALSE)

