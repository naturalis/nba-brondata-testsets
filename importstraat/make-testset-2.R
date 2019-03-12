require('nbaR')
source('utils.R')


ids <- list()
ids$specimen <- list()
ids$multimedia <- list()
ids$taxon <- list()

## scenario 2) Fresh import specimen, multimedia, taxa, with enrichment

##    Start:
##           empty

##    Test:
##           CRS specimen: >= 20, for 10 there should be SNG match with NSR and for 10 with COL
##           CRS multimedia: >=1, should be associated with one of our specimens
##           NSR taxon: 10, match with specimen on SNG
##           COL taxon: 10, match with specimen on SNG

sc <- SpecimenClient$new()
tc <- TaxonClient$new()
mc <- MultimediaClient$new()

dir <- "2_start"
create_dirs(dir)
dir <- "2_test"
create_dirs(dir)
specimens <- NULL
taxa <- NULL
multimedia <- NULL

## take specimen matching COL SNG 'felis catus'
#qs <- QuerySpec$new(size=10000, conditions=list(
#                                    QueryCondition$new(field="identifications.scientificName.scientificNameGroup",
#                                                       operator="EQUALS",
#                                                       value="felis catus")))
#res <- sc$query(querySpec=qs)

#specimens <- c(specimens, lapply(res$content$resultSet[1:10], function(x)x$item))

## sngs <- c("felis catus", "bombus terrestris", "bos taurus", "macropipus depurator", "turdus fuscescens", "treron pompadora", "turnix nana nana")

sngs <- c("dendrocopos major major","falco vespertinus","oenanthe oenanthe leucorhoa","oenanthe oenanthe oenanthe","fringilla montifringilla","plectrophenax nivalis nivalis","limosa limosa limosa","calidris canutus islandica","anser erythropus","fringilla coelebs coelebs","caracara plancus","falco peregrinus peregrinus","falco naumanni","pernis apivorus","gavia stellata","larus canus canus","uria aalge albionis","uria aalge aalge","vanellus vanellus","tringa totanus robusta","calidris alpina alpina","buteo buteo buteo")

for (sng in sngs) {
    cat("sng : ", sng, "\n")
    ## take specimen matching COL SNG 'bombus terrestris', with some multimedia
    qc <- QueryCondition$new(field="identifications.scientificName.scientificNameGroup",
                             operator="EQUALS",
                             value=sng)
    qc2 <- QueryCondition$new(field="associatedMultiMediaUris.format",
                              operator="NOT_EQUALS")
    qs <- QuerySpec$new(size=10000, conditions=list(qc, qc2))
    res <- sc$query(querySpec=qs)
    cat("Found ", res$content$totalSize, " specimens\n")
    if (res$content$totalSize > 0) {

        sp <- lapply(res$content$resultSet, function(x)x$item)
        if (length(sp) > 10) {
            sp <- sp[1:10]
        }
        specimens <- c(specimens, sp)        
        ## get the taxa for felis catus from NSR and COL
        res <- tc$query(queryParams=list("acceptedName.scientificNameGroup"=sng))
        cat("Found ", res$content$totalSize, " taxa\n")
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
file <- file.path(dir, "crs", "specimen", 'scenario-2-test.json')
cat(sapply(specimens, function(x)x$toJSONString(pretty=FALSE)), file=file, sep="\n")
system(paste0(paste0("touch ", dir, "/crs/specimen/upload_ready")))

## split taxa in NSR and COL taxa
taxa_col <- taxa[which(lapply(taxa, function(x)x$sourceSystem$code)=='COL')]
taxa_nsr <- taxa[which(lapply(taxa, function(x)x$sourceSystem$code)=='NSR')]

## write taxa to file
file <- file.path(dir, "col", "taxon", "scenario-2-test.json")
cat(sapply(taxa_col, function(x)x$toJSONString(pretty=FALSE)), file=file, sep="\n")
system(paste0(paste0("touch ", dir, "/col/taxon/upload_ready")))

file <- file.path(dir, "nsr", "taxon", "scenario-2-test.json")
cat(sapply(taxa_nsr, function(x)x$toJSONString(pretty=FALSE)), file=file, sep="\n")
system(paste0(paste0("touch ", dir, "/nsr/taxon/upload_ready")))


## write multimedia to file
file <- file.path(dir, 'crs', 'multimedia', 'scenario-2-test.json')
cat(sapply(multimedia, function(x)x$toJSONString(pretty=FALSE)), file=file, sep="\n")
system(paste0(paste0("touch ", dir, "/crs/multimedia/upload_ready")))

## extract ids
ids$specimen$new <- sapply(specimens, function(x)x$id)
ids$taxon$new <- sapply(taxa, function(x)x$id)
ids$multimedia$new <- sapply(multimedia, function(x)x$id)

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

