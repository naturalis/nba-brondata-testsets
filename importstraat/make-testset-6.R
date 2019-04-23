require('nbaR')
source('utils.R')

## dataframe with summary of which is updated, deleted, etc
ids <- list()
ids$specimen <- list()
ids$multimedia <- list()
ids$taxon <- list()

## scenario 6) real-world use-case
##    Start:           
##           specimen:
##                    BRAHMS: 10
##                    CRS: 10
##                    OBS: 10
##                         - deletelist: 10, can be arbitrary
##                    XC: 10
##
##           multimedia: All the ones associated with the specimens
##
##           taxon:
##                 NSR: 10+
##                 COL: 10+
##                         the ones that match with the SNGs with our specimens
##
##

dir <- "6_start"
create_dirs(dir)

sc <- SpecimenClient$new()
tc <- TaxonClient$new()
mc <- MultimediaClient$new()

specimens <- list()

for (ss in c('BRAHMS', 'CRS', 'OBS', 'XC')) {

    ## get the specimen data
    qc <- QueryCondition$new(field="associatedMultiMediaUris.format", operator="NOT_EQUALS")
    qc2 <- QueryCondition$new(field="sourceSystem.code", operator="EQUALS", value=ss)

    ## OBS does not have multimedia
    if (ss == "OBS") {
        qs <- QuerySpec$new(conditions=list(qc2), size=20)
    } else {
        qs <- QuerySpec$new(conditions=list(qc, qc2), size=20)
    }
    res <- sc$query(querySpec=qs)
    cat("Found ", res$content$totalSize, " specimens for ", ss, "\n")
    sp <- lapply(res$content$resultSet, function(x)x$item)
    
    specimens <- c(specimens, sp)    
}

## get the multimedia data
spec_ids <- sapply(specimens, function(x)x$id)

multimedias <- unlist(lapply(spec_ids, function(x){
    res <- mc$query(queryParams=list('associatedSpecimenReference'=x))
    lapply(res$content$resultSet, function(x)x$item)
}))

## get taxon data
sngs <- unlist(sapply(specimens, function(x)x$identifications[[1]]$scientificName$scientificNameGroup))
qc <- QueryCondition$new(field="acceptedName.scientificNameGroup", operator="IN", value=sngs)
res <- tc$query(querySpec=QuerySpec$new(conditions=list(qc), size=1000))
taxa <- sapply(res$content$resultSet, function(x)x$item)

## make delete list for OBS
##qc <- QueryCondition$new(field="id", operator="NOT_IN", value=spec_ids)
qc2 <- QueryCondition$new(field="sourceSystem.code", operator="EQUALS", value="OBS")
res <- sc$query(querySpec=QuerySpec$new(conditions=list(qc2)))
obs_delete_ids <- sapply(res$content$resultSet, function(x)x$item$id)
obs_delete_ids <- paste("del", obs_delete_ids, sep="_")

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

## write specimens to file
specimens_crs <- specimens[which(lapply(specimens, function(x)x$sourceSystem$code)=='CRS')]
specimens_obs <- specimens[which(lapply(specimens, function(x)x$sourceSystem$code)=='OBS')]
specimens_brahms <- specimens[which(lapply(specimens, function(x)x$sourceSystem$code)=='BRAHMS')]
specimens_xc <- specimens[which(lapply(specimens, function(x)x$sourceSystem$code)=='XC')]

file <- file.path(dir, "crs/specimen", 'scenario-6-start.json')
cat(sapply(specimens_crs, function(x)x$toJSONString(pretty=FALSE)), file=file, sep="\n")
system(paste0(paste0("touch ", dir, "/crs/specimen/upload_ready")))

file <- file.path(dir, "waarneming/specimen", 'scenario-6-start.json')
cat(sapply(specimens_obs, function(x)x$toJSONString(pretty=FALSE)), file=file, sep="\n")
system(paste0(paste0("touch ", dir, "/waarneming/specimen/upload_ready")))

file <- file.path(dir, "brahms/specimen", 'scenario-6-start.json')
cat(sapply(specimens_brahms, function(x)x$toJSONString(pretty=FALSE)), file=file, sep="\n")
system(paste0(paste0("touch ", dir, "/brahms/specimen/upload_ready")))

file <- file.path(dir, "xenocanto/specimen", 'scenario-6-start.json')
cat(sapply(specimens_xc, function(x)x$toJSONString(pretty=FALSE)), file=file, sep="\n")
system(paste0(paste0("touch ", dir, "/xenocanto/specimen/upload_ready")))

## write delete-idx.txt
file <- file.path(dir, "waarneming/specimen", 'delete-idx.txt')
cat(obs_delete_ids, sep="\n", file=file)
system(paste0(paste0("touch ", dir, "/waarneming/specimen/upload_ready")))


## write multimedia to file
## sometimes sourceInstitutionID and sourceID not set!
multimedias <- lapply(multimedias, function(x){
    x$sourceInstitutionID = "Naturalis Biodiversity Center"
    if (is.null(x$sourceID)) {
        cat("SourceID for ", x$id, " is NULL, setting to CRS\n")
        x$sourceID = "CRS"
    }
    ##    x$sourceID=x$sourceSystem$code
    for (i in seq_along(x$identifications)) {
        x$identifications[[i]]$taxonomicEnrichments=NULL
    }
    x})

multimedias_crs <- multimedias[which(lapply(multimedias, function(x)x$sourceSystem$code)=='CRS')]
## multimedias_obs <- multimedias[which(lapply(multimedias, function(x)x$sourceSystem$code)=='OBS')]
multimedias_brahms <- multimedias[which(lapply(multimedias, function(x)x$sourceSystem$code)=='BRAHMS')]
multimedias_xc <- multimedias[which(lapply(multimedias, function(x)x$sourceSystem$code)=='XC')]

file <- file.path(dir, "crs/multimedia", 'scenario-6-start.json')
cat(sapply(multimedias_crs, function(x)x$toJSONString(pretty=FALSE)), file=file, sep="\n")
system(paste0(paste0("touch ", dir, "/crs/multimedia/upload_ready")))

##file <- file.path(dir, "waarneming/multimedia", 'scenario-6-start.json')
##cat(sapply(multimedias_obs, function(x)x$toJSONString(pretty=FALSE)), file=file, sep="\n")
##system(paste0(paste0("touch ", dir, "/waarneming/multimedia/upload_ready")))

file <- file.path(dir, "brahms/multimedia", 'scenario-6-start.json')
cat(sapply(multimedias_brahms, function(x)x$toJSONString(pretty=FALSE)), file=file, sep="\n")
system(paste0(paste0("touch ", dir, "/brahms/multimedia/upload_ready")))

file <- file.path(dir, "xenocanto/multimedia", 'scenario-6-start.json')
cat(sapply(multimedias_xc, function(x)x$toJSONString(pretty=FALSE)), file=file, sep="\n")
system(paste0(paste0("touch ", dir, "/xenocanto/multimedia/upload_ready")))

## write taxa to file

## split taxa in NSR and COL taxa
taxa_col <- taxa[which(lapply(taxa, function(x)x$sourceSystem$code)=='COL')]
taxa_nsr <- taxa[which(lapply(taxa, function(x)x$sourceSystem$code)=='NSR')]

## write taxa to file
file <- file.path(dir, "col", "taxon", "scenario-6-start.json")
cat(sapply(taxa_col, function(x)x$toJSONString(pretty=FALSE)), file=file, sep="\n")
system(paste0(paste0("touch ", dir, "/col/taxon/upload_ready")))

file <- file.path(dir, "nsr", "taxon", "scenario-6-start.json")
cat(sapply(taxa_nsr, function(x)x$toJSONString(pretty=FALSE)), file=file, sep="\n")
system(paste0(paste0("touch ", dir, "/nsr/taxon/upload_ready")))

## ids
ids$specimen$initial <- sapply(specimens, function(x)x$id)
ids$taxon$initial <- sapply(taxa, function(x)x$id)
ids$multimedia$initial <- sapply(multimedias, function(x)x$id)
ids$specimen$deleted <- obs_delete_ids


##    Test:           
##         Specimen: 
##                  CRS:
##                       updated: 
##                       new:     
##                       unchanged:

dir <- "6_test"
create_dirs(dir)

specimens_test <- list()
multimedias_test <- multimedias



## specimens: update a few, make new ones, and delete one for each set
for (ss in c('BRAHMS', 'CRS', 'XC')) {
    i <- which(sapply(specimens, function(x)x$sourceSystem$code==ss))
    sp <- specimens[i]

    ## first one is deleted
    del_id <- sp[[1]]$id
    sp <- sp[2:length(sp)]    
    ids$specimen$deleted <- c(ids$specimen$deleted, del_id)
        
    ## also need to delete the multimedia associated with the specimen!
    del_mm_idx <- which(sapply(multimedias, function(x)x$associatedSpecimenReference==del_id))
    del_mm_ids <- sapply(multimedias_test[del_mm_idx], function(x)x$id)
    multimedias_test <- multimedias_test[-del_mm_idx]
    ids$multimedia$deleted <- c(ids$multimedia$deleted, del_mm_ids)
    
    ## first five ones of new set are updated
    for (i in 1:5) {
        sp[[i]]$identifications[[1]]$defaultClassification$family <- "updated_family"
    }        
    ids_up <- sapply(1:5, function(i)sp[[i]]$id)
    ids$specimen$updated <- c(ids$specimen$updated, ids_up)
    
    ## get five new specimens
    qs <- QuerySpec$new(conditions=list(QueryCondition$new(field='sourceSystem.code', operator='EQUALS', value=ss)), from=21, size=5)
    res <- sc$query(querySpec=qs)
    s <- lapply(res$content$resultSet, function(x)x$item)
    ids_new <- sapply(s, function(x)x$id)
    sp <- c(sp, s)
    ids$specimen$new <- ids_new
    
    specimens_test <- c(specimens_test, sp)
}

## handle the "OBS" species
## one gets deleted
i <- which(sapply(specimens, function(x)x$sourceSystem$code=="OBS"))
sp <- specimens[i]
obs_delete_ids_test <- sp[[1]]$id
## update 5 existing
for (i in 1:5) {
    sp[[i]]$identifications[[1]]$defaultClassification$family <- "updated_family"
}        
ids_up <- sapply(1:5, function(i)sp[[i]]$id)
ids$specimen$updated <- c(ids$specimen$updated, ids_up)

## Incremental update: add only the updated ones!!!
specimens_test <- c(specimens_test, sp[1:5])

## Multimedia: Update e.g. Licence, make new records for existing specimen
## also : add one per source system!
for (ss in c('BRAHMS', 'CRS', 'XC')) {
    indices <- which(sapply(multimedias_test, function(x)x$sourceSystem$code==ss))

    ## add one by copying the first one
    mm <- multimedias_test[[indices[1]]]
    mm_new <- mm$clone()
    mm_new$id <- paste0("NEW_", mm_new$id)
    multimedias_test <- c(multimedias_test, mm_new)

    ids$multimedia$new <- c(ids$multimedia$new, mm_new$id)    
    
    ## update the first three of them
    for (i in 1:3) {
        ## no entry in the NBA has this below license
        multimedias_test[[indices[i]]]$license <- "CC0 1.0"
    }
    ids$multimedia$updated <- c(ids$multimedia$updated, sapply(1:3, function(i)multimedias_test[[indices[i]]]$id))    
}

## Taxa: update one, delete for one SNG
taxa_test <- taxa

## delete taxa for sng
sng_del <- sngs[1]
idx <- which(sapply(taxa, function(x)x$acceptedName$scientificNameGroup== sng_del))[1]
del_id <- taxa_test[[idx]]$id
taxa_test <- taxa_test[-idx]
ids$taxon$deleted <- del_id

for (ss in c('COL', 'NSR')) {
    indices <- which(lapply(taxa, function(x)x$sourceSystem$code)==ss)
    taxa_tmp <- taxa_test[indices]
    taxa_tmp[1] <- lapply(taxa_tmp[1], function(x){x$taxonRemarks="updated taxon remarks"; x})
    
    taxa_test[indices] <- taxa_tmp

    cat("Updated taxon with ID ", taxa_tmp[[1]]$id, "\n")
    ids$taxon$updated <- c(ids$taxon$updated, taxa_tmp[[1]]$id)
    
}


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

## write specimens_test to file
specimens_test_crs <- specimens_test[which(lapply(specimens_test, function(x)x$sourceSystem$code)=='CRS')]
specimens_test_obs <- specimens_test[which(lapply(specimens_test, function(x)x$sourceSystem$code)=='OBS')]
specimens_test_brahms <- specimens_test[which(lapply(specimens_test, function(x)x$sourceSystem$code)=='BRAHMS')]
specimens_test_xc <- specimens_test[which(lapply(specimens_test, function(x)x$sourceSystem$code)=='XC')]

file <- file.path(dir, "crs/specimen", 'scenario-6-test.json')
cat(sapply(specimens_test_crs, function(x)x$toJSONString(pretty=FALSE)), file=file, sep="\n")
system(paste0(paste0("touch ", dir, "/crs/specimen/upload_ready")))

file <- file.path(dir, "waarneming/specimen", 'scenario-6-test.json')
cat(sapply(specimens_test_obs, function(x)x$toJSONString(pretty=FALSE)), file=file, sep="\n")
system(paste0(paste0("touch ", dir, "/waarneming/specimen/upload_ready")))

file <- file.path(dir, "brahms/specimen", 'scenario-6-test.json')
cat(sapply(specimens_test_brahms, function(x)x$toJSONString(pretty=FALSE)), file=file, sep="\n")
system(paste0(paste0("touch ", dir, "/brahms/specimen/upload_ready")))

file <- file.path(dir, "xenocanto/specimen", 'scenario-6-test.json')
cat(sapply(specimens_test_xc, function(x)x$toJSONString(pretty=FALSE)), file=file, sep="\n")
system(paste0(paste0("touch ", dir, "/xenocanto/specimen/upload_ready")))

## write delete-idx.txt
file <- file.path(dir, "waarneming/specimen", 'delete-idx.txt')
cat(obs_delete_ids_test, sep="\n", file=file)
system(paste0(paste0("touch ", dir, "/waarneming/specimen/upload_ready")))


## write multimedia to file
## sometimes sourceInstitutionID and sourceID not set!
multimedias_test <- lapply(multimedias_test, function(x){
    x$sourceInstitutionID = "Naturalis Biodiversity Center"
    if (is.null(x$sourceID)) {
        cat("SourceID for ", x$id, " is NULL, setting to CRS\n")
        x$sourceID = "CRS"
    }
    ##    x$sourceID=x$sourceSystem$code
    for (i in seq_along(x$identifications)) {
        x$identifications[[i]]$taxonomicEnrichments=NULL
    }
    x})

multimedias_test_crs <- multimedias_test[which(lapply(multimedias_test, function(x)x$sourceSystem$code)=='CRS')]
## multimedias_test_obs <- multimedias_test[which(lapply(multimedias_test, function(x)x$sourceSystem$code)=='OBS')]
multimedias_test_brahms <- multimedias_test[which(lapply(multimedias_test, function(x)x$sourceSystem$code)=='BRAHMS')]
multimedias_test_xc <- multimedias_test[which(lapply(multimedias_test, function(x)x$sourceSystem$code)=='XC')]

file <- file.path(dir, "crs/multimedia", 'scenario-6-test.json')
cat(sapply(multimedias_test_crs, function(x)x$toJSONString(pretty=FALSE)), file=file, sep="\n")
system(paste0(paste0("touch ", dir, "/crs/multimedia/upload_ready")))

##file <- file.path(dir, "waarneming/multimedia", 'scenario-6-test.json')
##cat(sapply(multimedias_test_obs, function(x)x$toJSONString(pretty=FALSE)), file=file, sep="\n")
##system(paste0(paste0("touch ", dir, "/waarneming/multimedia/upload_ready")))

file <- file.path(dir, "brahms/multimedia", 'scenario-6-test.json')
cat(sapply(multimedias_test_brahms, function(x)x$toJSONString(pretty=FALSE)), file=file, sep="\n")
system(paste0(paste0("touch ", dir, "/brahms/multimedia/upload_ready")))

file <- file.path(dir, "xenocanto/multimedia", 'scenario-6-test.json')
cat(sapply(multimedias_test_xc, function(x)x$toJSONString(pretty=FALSE)), file=file, sep="\n")
system(paste0(paste0("touch ", dir, "/xenocanto/multimedia/upload_ready")))

## write taxa_test to file

## split taxa_test in NSR and COL taxa_test
taxa_test_col <- taxa_test[which(lapply(taxa_test, function(x)x$sourceSystem$code)=='COL')]
taxa_test_nsr <- taxa_test[which(lapply(taxa_test, function(x)x$sourceSystem$code)=='NSR')]

## write taxa_test to file
file <- file.path(dir, "col", "taxon", "scenario-6-test.json")
cat(sapply(taxa_test_col, function(x)x$toJSONString(pretty=FALSE)), file=file, sep="\n")
system(paste0(paste0("touch ", dir, "/col/taxon/upload_ready")))

file <- file.path(dir, "nsr", "taxon", "scenario-6-test.json")
cat(sapply(taxa_test_nsr, function(x)x$toJSONString(pretty=FALSE)), file=file, sep="\n")
system(paste0(paste0("touch ", dir, "/nsr/taxon/upload_ready")))


## write ids to file
dfsp <- stack(ids$specimen)
dfsp$type <- 'specimen'

dfmm <- stack(ids$multimedia)
dfmm$type <- 'multimedia'

dftx <- stack(ids$taxon)
dftx$type <- 'taxon'

df <- rbind(dfsp, dfmm, dftx)
colnames(df) <- c('id', 'status', 'datatype')

write.table(df, file.path(dir, 'ids.tsv'), sep='\t', row.names=FALSE, quote=FALSE)







