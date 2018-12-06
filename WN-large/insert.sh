#!/bin/bash
for i in {1..400}; do curl -XPOST http://localhost:9200/specimen/Specimen/_bulk --data-binary "@/home/ubuntu/nba-brondata-testsets/WN-large/testset_large_$i.json"; done
