#!/bin/sh
# nbt, 13.13.2016

# download and extract file with repecId assignments from dbpedia

# Adapt VERSION to the current dbpedia version
VERSION="2016-04"

SOURCE=http://downloads.dbpedia.org/$VERSION/core-i18n/en/infobox_properties_mapped_en.ttl.bz2
TARGET_DIR=../var/dbpedia/latest/rdf
TARGET=$TARGET_DIR/infobox_properties_mapped_en.ttl

if [ ! -f $TARGET ]; then
  cd $TARGET_DIR
  wget $SOURCE
  bunzip2 *.bz2
  echo $TARGET created
else
  echo $TARGET already exists
fi
