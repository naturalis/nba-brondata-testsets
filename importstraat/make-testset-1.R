require('nbaR')
require('httr')

## dataframe with summary of which is updated, deleted, etc
ids <- list()

## scenario 1) Update Specimen and Multimedia (without enrichment)
##    Start:
##           specimen: XC (10)
##           multimedia: XC (20)
##           delete index: XC (0)
##           taxon: NSR (whole)

## specimen XC (10)
dir <- "1_start"
dir.create(dir)
sc <- SpecimenClient$new()
res <- sc$query(queryParams=list('sourceSystem.code'='XC'))
specimens <- lapply(res$content$resultSet, function(x)x$item)

## delete gatheringEvent.coordinates.geoShape
for (i in seq_along(specimens)) {
    for (j in seq_along(specimens[[i]]$gatheringEvent$siteCoordinates)) {
        specimens[[i]]$gatheringEvent$siteCoordinates[[j]]$geoShape=NULL
    }
}

ids$initial <- sapply(specimens, function(x)x$id)

file <- file.path(dir, 'specimen.json')
cat(sapply(specimens, function(x)x$toJSONString(pretty=FALSE)), file=file, sep="\n")

## multimedia XC (10)
mc <- MultimediaClient$new()
qs <- QuerySpec$new(size=20,
                    conditions=list(QueryCondition$new(
                                        field='sourceSystem.code',
                                        operator='EQUALS', value='XC')))
res <- mc$query(querySpec=qs)
multimedias <- lapply(res$content$resultSet, function(x)x$item)

file <- file.path(dir, 'multimedia.json')
cat(sapply(multimedias, function(x)x$toJSONString(pretty=FALSE)), file=file, sep="\n")


## taxon: whole NSR
##system('unzip nsr.json.zip')
system(paste('cp nsr.json.zip', dir))

##    Test:
##           specimen: 5 updated, 2 unchanged, 3 deleted, 10 new
dir <- "1_test"
dir.create(dir)

specimens_test <- specimens[1:7]
specimens_deleted <- specimens[8:10]
ids$deleted <- sapply(specimens_deleted, function(x)x$id)
updated <- vector()
for (i in seq_len(5)) {
    specimens_test[[i]]$identifications[[1]]$defaultClassification$genus <- 'updated_genus'
    updated <- c(updated, specimens_test[[i]]$id)
}
ids$updated <- updated

## 10 new specimens
qs <- QuerySpec$new(conditions=list(QueryCondition$new(field='sourceSystem.code', operator='EQUALS', value='XC')), from=11)
res <- sc$query(querySpec=qs)
specimens <- lapply(res$content$resultSet, function(x)x$item)
specimens_test <- c(specimens_test, specimens)
ids$new <- sapply(specimens, function(x)x$id)
ids$unchanged <- setdiff(ids$initial, c(ids$deleted, ids$updated, ids$new))

## save specimens test
file <- file.path(dir, 'specimen.json')
cat(sapply(specimens_test, function(x)x$toJSONString(pretty=FALSE)), file=file, sep="\n")

## write ids to file
write.table(stack(ids), file.path(dir, 'ids.tsv'), sep='\t', row.names=FALSE, quote=FALSE)



