#!/bin/sh
# nbt, 13.13.2016

# download and extract file with repecId assignments from dbpedia

# Adapt VERSION to the current dbpedia version
VERSION="2016-04"

TARGET_DIR=../var/dbpedia/latest/rdf

cd $TARGET_DIR
/bin/rm -f *.bz2

SOURCE=http://downloads.dbpedia.org/$VERSION/core-i18n/en/infobox_properties_mapped_en.ttl.bz2
TARGET=infobox_properties_mapped_en.ttl

if [ ! -f $TARGET ]; then
  wget --quiet $SOURCE
  lbunzip2 --quiet *.bz2
  echo $TARGET created
else
  echo $TARGET already exists
fi

SOURCE=http://downloads.dbpedia.org/$VERSION/core-i18n/en/interlanguage_links_en.ttl.bz2
TARGET=wikidata_links_en.ttl

if [ ! -f $TARGET ]; then
  wget --quiet $SOURCE
  bzgrep -h 'sameAs> <http://www.wikidata' *.bz2 > $TARGET
  rm *.bz2
  echo $TARGET created
else
  echo $TARGET already exists
fi

