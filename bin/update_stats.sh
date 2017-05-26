#!/bin/sh

cd /opt/repec-ras/sparql
for query in mapping_stats wd_mapping_statistics wd_top_mapping_statistics; do
  s-query.sh ebds ${query}.rq > results/${query}.json
done

EBDS_VERSION="ebds_2017-02-01"

cd /opt/sparql-queries/wikidata
for query in count_ebds_pers; do
  s-query.sh ebds ${query}.rq > results/${query}.${EBDS_VERSION}.json
done
