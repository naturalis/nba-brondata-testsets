#!/bin/bash

# This script is for importing specimen test records
# in JSON format into the NBA. Argument: filename of
# JSON file containing the data to import

# Check input
FILE=$1

if [ ! -e $FILE ] || [ -z $FILE ]; then
   echo "Usage: $0 <file.json> "
   exit
fi

echo "Attempting to import entries from file $FILE"

# server IP is hard coded, you can get it with command: 
# docker exec nbatest_elasticsearch_1 ip addr show
SERVER=http://172.18.0.3:9200

# also index and doctype are hard-coded
INDEX="specimen"
DOCTYPE="Specimen"

# parse input file with multiple json records
while read ENTRY; do
    curl -w "\n" -XPOST $SERVER/$INDEX/$DOCTYPE -d "$ENTRY"
done < $FILE
      
echo "DONE $0"
