require('nbaR')
require('httr')
source('utils.R')

base_url <- "https://api.biodiversitydata.nl/v2"

## dataframe with summary of which is updated, deleted, etc
ids <- list()
ids$specimen <- list()
ids$multimedia <- list()

## scenario 1) Update Specimen and Multimedia (without enrichment)
##    Start:
##           specimen: XC (10)
##           multimedia: XC (20)
##           delete index: XC (0)
##           taxon: NSR (whole)

## specimen XC (10)
dir <- "1_start"
create_dirs(dir)

sc <- SpecimenClient$new(basePath=base_url)
res <- sc$query(queryParams=list('sourceSystem.code'='XC'))
specimens <- lapply(res$content$resultSet, function(x)x$item)

## delete gatheringEvent.coordinates.geoShape
for (i in seq_along(specimens)) {
    for (j in seq_along(specimens[[i]]$gatheringEvent$siteCoordinates)) {
        specimens[[i]]$gatheringEvent$siteCoordinates[[j]]$geoShape=NULL
    }
}

ids$specimen$initial <- sapply(specimens, function(x)x$id)


file <- file.path(paste0(dir, "/xenocanto/specimen/"), 'scenario-1-start.json')
cat(sapply(specimens, function(x)x$toJSONString(pretty=FALSE)), file=file, sep="\n")
system(paste0(paste0("touch ", dir, "/xenocanto/specimen/upload_ready")))

## multimedia XC (20)
mc <- MultimediaClient$new(basePath=base_url)
qs <- QuerySpec$new(size=20,
                    conditions=list(QueryCondition$new(
                                        field='sourceSystem.code',
                                        operator='EQUALS', value='XC')))
res <- mc$query(querySpec=qs)
multimedias <- lapply(res$content$resultSet, function(x)x$item)
for (m in multimedias) {m$sourceID="Xeno-canto"}

ids$multimedia$initial <- sapply(multimedias, function(x)x$id)

file <- file.path(paste0(dir, "/xenocanto/multimedia/"), 'scenario-1-start.json')
cat(sapply(multimedias, function(x)x$toJSONString(pretty=FALSE)), file=file, sep="\n")
system(paste0(paste0("touch ", dir, "/xenocanto/multimedia/upload_ready")))

## taxon: whole NSR
##system('unzip nsr.json.zip')
system(paste0('cp nsr.json ', dir, "/", "nsr/taxon/scenario-1-start.json"))
system(paste0(paste0("touch ", dir, "/nsr/taxon/upload_ready")))

##    Test:
##           specimen: 5 updated, 2 unchanged, 3 deleted, 10 new
##           multimedia: 5 updated, 2 unchanged, 3 deleted, 10 new
dir <- "1_test"
create_dirs(dir)

## delete 3 specimens
specimens_test <- specimens[1:7]
specimens_deleted <- specimens[8:10]
ids$specimen$deleted <- sapply(specimens_deleted, function(x)x$id)

## update 5 specimens
updated <- vector()
for (i in seq_len(5)) {
    specimens_test[[i]]$identifications[[1]]$defaultClassification$genus <- 'updated_genus'
    updated <- c(updated, specimens_test[[i]]$id)
}
ids$specimen$updated <- updated

## 10 new specimens
qs <- QuerySpec$new(conditions=list(QueryCondition$new(field='sourceSystem.code', operator='EQUALS', value='XC')), from=11)
res <- sc$query(querySpec=qs)
specimens <- lapply(res$content$resultSet, function(x)x$item)
specimens_test <- c(specimens_test, specimens)
ids$specimen$new <- sapply(specimens, function(x)x$id)
ids$specimen$unchanged <- setdiff(ids$specimen$initial, c(ids$specimen$deleted, ids$specimen$updated, ids$specimen$new))

## save specimens test
file <- file.path(dir, "xenocanto/specimen", 'scenario-1-test.json')
cat(sapply(specimens_test, function(x)x$toJSONString(pretty=FALSE)), file=file, sep="\n")
system(paste0(paste0("touch ", dir, "/xenocanto/specimen/upload_ready")))

## delete 3 multimedia
multimedias_test <- multimedias[1:7]
multimedias_deleted <- multimedias[8:10]
ids$multimedia$deleted <- sapply(multimedias_deleted, function(x)x$id)

## update 5 multimedia
updated <- vector()
for (i in seq_len(5)) {
    multimedias_test[[i]]$identifications[[1]]$scientificName$fullScientificName <- 'updated_scientific_name'
    updated <- c(updated, multimedias_test[[i]]$id)
}
ids$multimedia$updated <- updated

## 10 new multimedia
qs <- QuerySpec$new(size=10,
                    conditions=list(QueryCondition$new(
                                        field='sourceSystem.code',
                                        operator='EQUALS', value='XC')), from=11)
res <- mc$query(querySpec=qs)
multimedias <- lapply(res$content$resultSet, function(x)x$item)
multimedias_test <- c(multimedias_test, multimedias)
## for (m in multimedias_test) {m$sourceID="Xeno-canto"}

ids$multimedia$new <- sapply(multimedias, function(x)x$id)
ids$multimedia$unchanged <- setdiff(ids$multimedia$initial, c(ids$multimedia$deleted, ids$multimedia$updated, ids$multimedia$new))

## save multimedia
file <- file.path(dir, "xenocanto/multimedia", 'scenario-1-test.json')
cat(sapply(multimedias_test, function(x)x$toJSONString(pretty=FALSE)), file=file, sep="\n")
system(paste0(paste0("touch ", dir, "/xenocanto/multimedia/upload_ready")))

## save taxon
system(paste0('cp nsr.json ', dir, "/", "nsr/taxon/scenario-1-test.json"))
system(paste0(paste0("touch ", dir, "/nsr/taxon/upload_ready")))

## write ids to file
dfsp <- stack(ids$specimen)
dfsp$type <- 'specimen'

dfmm <- stack(ids$multimedia)
dfmm$type <- 'multimedia'

df <- rbind(dfsp, dfmm)
colnames(df) <- c('id', 'status', 'datatype')

write.table(df, file.path(dir, 'ids.tsv'), sep='\t', row.names=FALSE, quote=FALSE)
