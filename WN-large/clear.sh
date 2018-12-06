#!/bin/bash

## curl -XPOST http://localhost:9200/specimen/Specimen/_delete_by_query -d '{ "query": {"term": {"collectionType" : "testset_large"}} }'
## curl -XPOST http://localhost:9200/multimedia/MultiMediaObject/_delete_by_query -d '{ "query": {"term": {"collectionType" : "testset_large"}} }'
curl -XPOST http://localhost:9200/specimen/Specimen/_delete_by_query -d '{ "query": {"prefix": {"sourceSystemId" : "TEST/"}} }'
curl -XPOST http://localhost:9200/multimedia/MultiMediaObject/_delete_by_query -d '{ "query": {"prefix": {"associatedSpecimenReference" : "TEST."}} }'


curl -XPOST http://localhost:9200/specimen/_refresh
curl -XPOST http://localhost:9200/multimedia/_refresh





