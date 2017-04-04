# SPARQL queries

Currently, the queries use an endpoint which can be addressed only within the ZBW network.

Query | Description
------|------------
[dbpedia_repec_wd](http://zbw.eu/beta/sparql-lab/?endpoint=http://172.16.10.102:3030/ebds/query&queryRef=https://api.github.com/repos/zbw/repec-ras/contents/sparql/dbpedia_repec_wd.rq) | Connect from dbpedia to wikidata in order to relate repec ids to wikidata items ([result](http://zbw.eu/beta/sparql-lab/result?resultRef=https://api.github.com/repos/zbw/repec-ras/contents/sparql/results/dbpedia_repec_wd.dbpedia_2016-04.ras_2016-12-13.wikidata_2016-11-07.json))
[gnd_ras](http://zbw.eu/beta/sparql-lab/?endpoint=http://172.16.10.102:3030/ebds/query&queryRef=https://api.github.com/repos/zbw/repec-ras/contents/sparql/gnd_ras.rq) | Mappings gnd ./. repec author servicewith wikidata items linked by gnd
[count_gnd_ras_rank](http://zbw.eu/beta/sparql-lab/?endpoint=http://172.16.10.102:3030/ebds/query&queryRef=https://api.github.com/repos/zbw/repec-ras/contents/sparql/count_gnd_ras_rank.rq) | Count the gnd-ras mappings and the percentage of top authors covered by it
[ras_mix_n_match](http://zbw.eu/beta/sparql-lab/?endpoint=http://172.16.10.102:3030/ebds/query&queryRef=https://api.github.com/repos/zbw/repec-ras/contents/sparql/ras_mix_n_match.rq) | Create input for [Wikidata Mix'n'match](https://tools.wmflabs.org/mix-n-match/#/) for top economists

