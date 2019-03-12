require('nbaR')
require('httr')
source('utils.R')

base_url <- "http://145.136.242.167:8080/v2"

## dataframe with summary of which is updated, deleted, etc
ids <- list()
ids$specimen <- list()
ids$multimedia <- list()
ids$taxon <- list()

## scenario 4) existing taxa (NSR), import new specimens with enrichments
##    Start:           
##           taxon: NSR (whole)

sc <- SpecimenClient$new(basePath=base_url)
tc <- TaxonClient$new(basePath=base_url)
mc <- MultimediaClient$new()

dir <- "4_start"
create_dirs(dir)

## copy whole nsr
system(paste0('cp nsr.json ', dir, "/", "nsr/taxon/scenario-4-start.json"))
system(paste0(paste0("touch ", dir, "/nsr/taxon/upload_ready")))



##    Test:
##           specimen: BRAHMS (20), matching SNGs in NSR
##           multimedia: BRAHMS, associated with the specimen
##           taxon: NSR (whole)

dir <- "4_test"
create_dirs(dir)

## copy whole nsr
system(paste0('cp nsr.json ', dir, "/", "nsr/taxon/scenario-4-test.json"))
system(paste0(paste0("touch ", dir, "/nsr/taxon/upload_ready")))

specimens <- NULL
taxa <- NULL
multimedia <- NULL

## get sngs from BRAHMS with multimedia
qc1 <- QueryCondition$new(field="defaultClassification.kingdom", operator="EQUALS", value="Plantae")
qc2 <- QueryCondition$new(field="sourceSystem.code", operator="EQUALS", value="NSR")
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
## take first 20 SNGs for which we have specimens with multimedia
sngs <- names(sort(cnts, decreasing=T)[1:20])
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
    ## taxa <- c(taxa, lapply(res$content$resultSet, function(x)x$item))    
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
file <- file.path(dir, "brahms/specimen", 'scenario-4-start.json')
cat(sapply(specimens, function(x)x$toJSONString(pretty=FALSE)), file=file, sep="\n")
system(paste0(paste0("touch ", dir, "/brahms/specimen/upload_ready")))

## write multimedia to file
file <- file.path(dir, "brahms/multimedia", 'scenario-4-start.json')
cat(sapply(multimedia, function(x)x$toJSONString(pretty=FALSE)), file=file, sep="\n")
system(paste0(paste0("touch ", dir, "/brahms/multimedia/upload_ready")))

## extract ids
ids$specimen$new <- sapply(specimens, function(x)x$id)
## ids$taxon$initial <- sapply(taxa, function(x)x$id)
ids$multimedia$new <- sapply(multimedia, function(x)x$id)

## write ids to file
dfsp <- stack(ids$specimen)
dfsp$type <- 'specimen'

dfmm <- stack(ids$multimedia)
dfmm$type <- 'multimedia'

df <- rbind(dfsp, dfmm)
colnames(df) <- c('id', 'status', 'datatype')

write.table(df, file.path(dir, 'ids.tsv'), sep='\t', row.names=FALSE, quote=FALSE)

