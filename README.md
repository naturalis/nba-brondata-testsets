# NBA - BRONDATA - TESTSETS

### Overview
This repository holds controlled test data sets for NBA (regression) testing. The data can be imported into the NBA via the script `import_data.sh`.

### Requirements
An `sh` shell and `cURL` and Elastic Search running, with all the NBA indices and mappings defined.

### How to use
Run scipt `import_data.sh` using a JSON file name with the data to be imported as argument, e.g:
    
    ./import_data.sh testset_specimen_panthera.json 

Note that the IP and port of Elastic Search is hard-coded in the import script. Find out IP and port with:

    docker exec nbatest_elasticsearch_1 ip addr show

### Deleting the data
Can be done with `delete_by_query` (see [Elastic docs](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-delete-by-query.html)), with querying the
name of the testset, for instance:

`curl -XPOST http://145.136.240.125:32741/specimen/Specimen/_delete_by_query -d '{ "query": {"term": {"collectionType" : "testset_specimen_panthera"}} }'`

Be careful, though.

