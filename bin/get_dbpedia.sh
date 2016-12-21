#!/bin/sh
# nbt, 13.13.2016

# download and extract files with repecId assignments from dbpedia
# and with sameAs links to wikidata

# Adapt VERSION to the current dbpedia version
VERSION="2016-04"

TARGET_DIR=../var/ras/latest/rdf

cd $TARGET_DIR
/bin/rm -f *.bz2

FILE=infobox_properties_mapped_en.ttl.bz2
SOURCE=http://downloads.dbpedia.org/$VERSION/core-i18n/en/$FILE
TARGET=dbpedia_repecid.ttl

if [ ! -f $TARGET ]; then
  wget --quiet $SOURCE
  # extract repec id statements
  bzgrep '<http://dbpedia.org/property/repecId>' $FILE > $TARGET
  echo $TARGET created
else
  echo $TARGET already exists
fi

FILE=interlanguage_links_en.ttl.bz2
SOURCE=http://downloads.dbpedia.org/$VERSION/core-i18n/en/$FILE
TARGET=dbpedia_wikidata_links.ttl

if [ ! -f $TARGET ]; then
  wget --quiet $SOURCE
  # extract sameAs wikidata statements
  bzgrep 'sameAs> <http://www.wikidata' $FILE > $TARGET
  echo $TARGET created
else
  echo $TARGET already exists
fi

