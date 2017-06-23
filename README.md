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


