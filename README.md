Code for working with the RePEC Author Serice
---------------------------------------------

The [RePEC Author Serice](https://authors.repec.org/) (RAS) identifies authors
of the [Research Papers in Economics](http://repec.org/) data set. The RAS data
is entered by the authors themselves.

RAS authors often are linked to their Institutions, for which RePEc provides a
directory of [Economics Departments, Institutes and Research Centers in the
World](https://edirc.repec.org/).

## Transforming the RAS and EDIRC archives to JSON-LD/RDF

**[redif2jsonld.pl](bin/redif2jsonld.pl):** Currently a very simple
transformation based on an existing script by Thomas Krichel. 

**[extract_ras_ranks.pl](bin/extract_ras_ranks.pl):** Extracts ranking
information from RePEc's [Top 10%
Authors](https://ideas.repec.org/top/top.person.all.html) and [Top 10% Female
Economists](https://ideas.repec.org/top/top.women.html).


[ras context](etc/ras_context.jsonld), [edirc
context](etc/edirc_context.jsonld) and examples in
[jsonld](var/ras/example1/rdf/example1.jsonld) and
[turtle](var/ras/example1/rdf/example1.ttl).

