#!/bin/sh
# 15.2.2018

# Get complete Wikidata - RePEc author mapping from Wikidata's SPARQL endpoint

ENDPOINT='https://query.wikidata.org/bigdata/namespace/wdq/sparql'
QUERY='PREFIX wdt: <http://www.wikidata.org/prop/direct/>
#
select ?rasId ?wd
where {
  ?wd wdt:P2428 ?rasId .
  # filter out possible "unknown value" entries
  filter(isLiteral(?rasId))
}
order by ?rasId
'

# send query via HTTP, require result in CSV
curl --silent -d "query=$QUERY" -H 'Accept: text/csv' $ENDPOINT

