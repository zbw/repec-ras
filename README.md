Code for working with the RePEC Author Serice
---------------------------------------------

The [RePEC Author Serice](https://authors.repec.org/) (RAS) identifies authors
of the [Research Papers in Economics](http://repec.org/) data set. The RAS data
is entered by the authors themselves.

## Transforming the RAS archive to JSON-LD/RDF

**[redif2jsonld.pl](bin/redif2jsonld.pl):** Currently a very simple
transformation based on an existing script by Thomas Krichel. 

[context](etc/ras_context.jsonld) and examples in
[jsonld](var/ras/example1/rdf/example1.jsonld) and
[turtle](var/ras/example1/rdf/example1.ttl).

