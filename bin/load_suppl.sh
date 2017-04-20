#!/bin/sh
# nbt, 24.11.2016

# create or reload a supplementary graph

if [ $# -lt 2 ]
then
  echo "Usage: `basename $0` {graph} (relative or ablsolute paths)"
  exit
fi

# TODO make this the first parameter (and replace old version in ebds)
DATASET=repec

GRAPH=$1
shift
FILES=$*

if [ `pgrep -f fuseki` ]; then
  ENDPOINT=http://localhost:3030/$DATASET
elif [ `pgrep -f tomcat` ]; then
  ENDPOINT=http://localhost:8080/fuseki/$DATASET
else
  echo "Error: Fuseki not running"
  exit 1
fi

BASEURI=http://zbw.eu/beta
SERVICE_URI=$BASEURI/sparql-service
SERVICE_DDURI=$SERVICE_URI/dd

DATA_URI=$ENDPOINT/data
QUERY_URI=$ENDPOINT/query
UPDATE_URI=$ENDPOINT/update
TDB_DIR=../var/$DATASET/latest/tdb

graph_name=$BASEURI/$GRAPH/ng

statistics_file=../var/$DATASET/latest/rdf/dataset_statistics.ttl
turtle_type=application/x-turtle

PREFIXES="
prefix dc: <http://purl.org/dc/elements/1.1/>
prefix dcterms: <http://purl.org/dc/terms/>
prefix owl: <http://www.w3.org/2002/07/owl#>
prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#>
prefix sd: <http://www.w3.org/ns/sparql-service-description#>
prefix skos: <http://www.w3.org/2004/02/skos/core#>
prefix void: <http://rdfs.org/ns/void#>
prefix xhv: <http://www.w3.org/1999/xhtml/vocab#>
prefix xsd: <http://www.w3.org/2001/XMLSchema#>
"

# delete complete graph
curl -X DELETE --silent $DATA_URI?graph=$graph_name

# statistics for void handled separately
if [ $GRAPH == "void" ]; then
  # if statistics_file already exists, assume that it had been produced properly from
  # the currently existing $DATASET graph
  if [ ! -f $statistics_file ]; then
    curl -X POST --silent $QUERY_URI --data "query=`cat ../sparql/construct_dataset_statistics.rq`" > $statistics_file
  fi
  curl -X POST --silent -H "Content-Type: $turtle_type" --data @$statistics_file $DATA_URI?graph=$graph_name > /dev/null
fi

# stop running service
if [ `pgrep -f fuseki` ]; then
  restart=fuseki
  /opt/fuseki2/fuseki stop
  sleep 5
fi
if [ `pgrep -f tomcat` ]; then
  restart=tomcat
  service tomcat stop
  sleep 10
fi

# load the data
echo "$FILES"
java -cp /opt/fuseki2/fuseki-server.jar tdb.tdbloader --loc=$TDB_DIR --graph=$graph_name $FILES ## 2>&1 | tee -a $LOG

# restart service
if [ "$restart" == "fuseki" ]; then
  /opt/fuseki2/fuseki start
  sleep 5
fi
if [ "$restart" == "tomcat" ]; then
  service tomcat start
  sleep 10
fi

# load metadata into default (service) graph
statement="
$PREFIXES
insert {
  <$SERVICE_DDURI> sd:namedGraph <$graph_name> .
  <$graph_name> a sd:NamedGraph ;
      dcterms:title \"$GRAPH graph for $DATASET\" ;
      sd:name <$graph_name> .
}
where {}
"
curl -X POST --silent --data "update=$statement" $UPDATE_URI > /dev/null

