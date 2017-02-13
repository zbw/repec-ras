#!/bin/sh

# nbt, 8.12.2016

# Fetch a current copy of the RePEc EDIRC archive

EDIRC_URL=rsync://sync.repec.org/RePEc-ReDIF/edi/inst/
EDIRC_LOCAL_DIR=../var/edirc/latest/src/inst

rsync -v -a --delete $EDIRC_URL $EDIRC_LOCAL_DIR


