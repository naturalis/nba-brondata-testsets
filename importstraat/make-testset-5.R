require('nbaR')
source('utils.R')

## dataframe with summary of which is updated, deleted, etc
ids <- list()
ids$specimen <- list()
ids$multimedia <- list()
ids$taxon <- list()

## scenario 5) existing taxa (NSR), import new specimens with enrichments
##    Start:           
##           specimen: 100 CRS
##           multimedia: associated with the spcimen (let's do at least 100)
##           waarnemingen: 10, will be deleted
##           NSR: 100

dir <- "5_start"
create_dirs(dir)

sc <- SpecimenClient$new()
tc <- TaxonClient$new()
mc <- MultimediaClient$new()

## gather specimen data
qc <- QueryCondition$new(field="associatedMultiMediaUris.format",
                         operator="NOT_EQUALS")
qc2 <- QueryCondition$new(field="sourceSystem.code", operator="EQUALS", value="CRS")

qs <- QuerySpec$new(size=100, conditions=list(qc))
res <- sc$query(querySpec=qs)

specimens <- lapply(res$content$resultSet, function(x)x$item)

## get WN data (10)
qc <- QueryCondition$new(field="sourceSystem.code", operator="EQUALS", value="OBS")
qs <- QuerySpec$new(size=10, conditions=list(qc))
res <- sc$query(querySpec=qs)

specimens <- c(specimens, lapply(res$content$resultSet, function(x)x$item))

## gather multimedia data
spec_ids <- sapply(specimens, function(x)x$id)

multimedias <- unlist(lapply(spec_ids, function(x){
    res <- mc$query(queryParams=list('associatedSpecimenReference'=x))
    lapply(res$content$resultSet, function(x)x$item)
}))

## gather taxon data
qc <- QueryCondition$new(field="sourceSystem.code", operator="EQUALS", value="NSR")
qs <- QuerySpec$new(size=100, conditions=list(qc))

res <- tc$query(querySpec=qs)
taxa <- lapply(res$content$resultSet, function(x)x$item)

## delete gatheringEvent.coordinates.geoShape
for (i in seq_along(specimens)) {
    for (j in seq_along(specimens[[i]]$gatheringEvent$siteCoordinates)) {
        specimens[[i]]$gatheringEvent$siteCoordinates[[j]]$geoShape=NULL
    }
    ## delete also taxonomic enrichments
    for (j in seq_along(specimens[[i]]$identifications)) {
        specimens[[i]]$identifications[[j]]$taxonomicEnrichments = NULL
    }    
}

## delete taxonomic enrichments from multimedia:
for (i in seq_along(multimedias)) {
    for (j in seq_along(multimedias[[i]]$identifications)) {
        multimedias[[i]]$identifications[[j]]$taxonomicEnrichments = NULL
    }    
}

## sometimes sourceInstitutionID and sourceID not set!
multimedias <- lapply(multimedias, function(x){
    x$sourceInstitutionID = "Naturalis Biodiversity Center"
    x$sourceID="CRS"
    x})

## split specimens in CRS and OBS taxa
specimens_crs <- specimens[which(lapply(specimens, function(x)x$sourceSystem$code)=='CRS')]
specimens_obs <- specimens[which(lapply(specimens, function(x)x$sourceSystem$code)=='OBS')]

## write specimen to file
file <- file.path(dir, "crs/specimen", 'scenario-5-start.json')
cat(sapply(specimens_crs, function(x)x$toJSONString(pretty=FALSE)), file=file, sep="\n")
system(paste0(paste0("touch ", dir, "/crs/specimen/upload_ready")))

file <- file.path(dir, "waarneming/specimen", 'scenario-5-start.json')
cat(sapply(specimens_obs, function(x)x$toJSONString(pretty=FALSE)), file=file, sep="\n")
system(paste0(paste0("touch ", dir, "/waarneming/specimen/upload_ready")))

## write multimedia to file
file <- file.path(dir, "crs/multimedia", 'scenario-5-start.json')
cat(sapply(multimedias, function(x)x$toJSONString(pretty=FALSE)), file=file, sep="\n")
system(paste0(paste0("touch ", dir, "/crs/multimedia/upload_ready")))

## write taxa to file
file <- file.path(dir, "nsr/taxon", 'scenario-5-start.json')
cat(sapply(taxa, function(x)x$toJSONString(pretty=FALSE)), file=file, sep="\n")
system(paste0(paste0("touch ", dir, "/nsr/taxon/upload_ready")))

ids$specimen$initial <- sapply(specimens, function(x)x$id)
ids$taxon$initial <- sapply(taxa, function(x)x$id)
ids$multimedia$initial <- sapply(multimedias, function(x)x$id)

##    Test:           
##           specimen: delete 50
##           multimedia: delete the associated ones
##           NSR: delete 50
##           waarnemingen: put ids of all 10 in file delete-ids.txt

dir <- "5_test"
create_dirs(dir)

## specimen
specimens_test <- specimens[1:50]
spec_test_ids <- sapply(specimens_test, function(x)x$id)
del_ids <- sapply(specimens[51:100], function(x)x$id)

ids$specimen$deleted <- del_ids

## multimedia
multimedias_test<- unlist(lapply(spec_test_ids, function(x){
    res <- mc$query(queryParams=list('associatedSpecimenReference'=x))
    lapply(res$content$resultSet, function(x)x$item)
}))
mm_test_ids <- sapply(multimedias_test, function(x)x$id)

## ids$multimedia$test <- sapply(multimedia, function(x)x$id)
ids$multimedia$deleted <- ids$multimedia$initial[which(!ids$multimedia$initial %in% mm_test_ids)]

## specimen
taxa_test <- taxa[1:50]
spec_test_ids <- sapply(taxa_test, function(x)x$id)
del_ids <- sapply(taxa[51:100], function(x)x$id)

ids$taxon$deleted <- del_ids

## delete gatheringEvent.coordinates.geoShape
for (i in seq_along(specimens_test)) {
    for (j in seq_along(specimens_test[[i]]$gatheringEvent$siteCoordinates)) {
        specimens_test[[i]]$gatheringEvent$siteCoordinates[[j]]$geoShape=NULL
    }
    ## delete also taxonomic enrichments
    for (j in seq_along(specimens_test[[i]]$identifications)) {
        specimens_test[[i]]$identifications[[j]]$taxonomicEnrichments = NULL
    }    
}

## delete taxonomic enrichments from multimedia:
for (i in seq_along(multimedias_test)) {
    for (j in seq_along(multimedias_test[[i]]$identifications)) {
        multimedias_test[[i]]$identifications[[j]]$taxonomicEnrichments = NULL
    }    
}

## sometimes sourceInstitutionID and sourceID not set!
multimedias_test <- lapply(multimedias_test, function(x){
    x$sourceInstitutionID = "Naturalis Biodiversity Center"
    x$sourceID="CRS"
    x})

## write deleted specimens to delete-ids.txt
file <- file.path(dir, "waarneming/specimen", 'delete-idx.txt')
cat(sapply(specimens_obs, function(x)x$id), sep="\n", file=file)
system(paste0(paste0("touch ", dir, "/waarneming/specimen/upload_ready")))

## write specimen to file
file <- file.path(dir, "crs/specimen", 'scenario-5-test.json')
cat(sapply(specimens_test, function(x)x$toJSONString(pretty=FALSE)), file=file, sep="\n")
system(paste0(paste0("touch ", dir, "/crs/specimen/upload_ready")))

## write multimedia to file
file <- file.path(dir, "crs/multimedia", 'scenario-5-test.json')
cat(sapply(multimedias_test, function(x)x$toJSONString(pretty=FALSE)), file=file, sep="\n")
system(paste0(paste0("touch ", dir, "/crs/multimedia/upload_ready")))

## write taxa to file
file <- file.path(dir, "nsr/taxon", 'scenario-5-test.json')
cat(sapply(taxa_test, function(x)x$toJSONString(pretty=FALSE)), file=file, sep="\n")
system(paste0(paste0("touch ", dir, "/nsr/taxon/upload_ready")))

## write ids to file
dfsp <- stack(ids$specimen)
dfsp$type <- 'specimen'

dfmm <- stack(ids$multimedia)
dfmm$type <- 'multimedia'

df <- rbind(dfsp, dfmm)
colnames(df) <- c('id', 'status', 'datatype')

write.table(df, file.path(dir, 'ids.tsv'), sep='\t', row.names=FALSE, quote=FALSE)



