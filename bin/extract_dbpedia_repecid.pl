#!/bin/env perl

# extracts repecId statements from dbpedia

use strict;
use warnings;

use URI::Escape;

my $IN = $ARGV[0] || die "Usage: $0 {inputfilename}\n";

open (my $in_fh, '<', $IN) or die "Could not open $IN: $!\n";

while  (<$in_fh>) {
  next unless m/repecId/;

  m|(<http://dbpedia\.org/resource/(.*)?>) <http://dbpedia\.org/property/repecId> |;
  next unless $1;

  print $_;

  # create a pagelink statement (instead of reading it from dbpedia)
  my $dbpedia = $1;
  my $page = $2;
  $page =~ tr/_/ /;
  $page = uri_escape($page);
  print "$1 <http://xmlns.com/foaf/0.1/isPrimaryTopicOf> <https://en.wikipedia.org/wiki/$page> .\n";
}

