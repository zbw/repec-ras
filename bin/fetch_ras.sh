#!/bin/sh

# nbt, 8.12.2016

# Fetch a current copy of the Repec Author Service archive

RAS_URL=rsync://sync.repec.org/RePEc-ReDIF/per/
RAS_LOCAL_DIR=../var/ras/latest/src/per

rsync -v -a --delete $RAS_URL $RAS_LOCAL_DIR


