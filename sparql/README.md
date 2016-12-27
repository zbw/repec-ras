# SPARQL queries

Currently, the queries use an endpoint which can be addressed only within the ZBW network.

Query | Description
------|------------
[dbpedia_repec_wd](http://zbw.eu/beta/sparql-lab/?endpoint=http://172.16.10.102:3030/ebds/query&queryRef=https://api.github.com/repos/zbw/repec_ras/contents/sparql/dbpedia_repec_wd.rq) | Connect from dbpedia to wikidata in order to relate repec ids to wikidata items
[gnd_ras](http://zbw.eu/beta/sparql-lab/?endpoint=http://172.16.10.102:3030/ebds/query&queryRef=https://api.github.com/repos/zbw/repec_ras/contents/sparql/gnd_ras.rq) | Mappings gnd ./. repec author servicewith wikidata items linked by gnd
