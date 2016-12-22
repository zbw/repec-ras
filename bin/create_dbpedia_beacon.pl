#!/bin/env perl
# nbt, 22.12.2016

# Create Beacon file for RePEc-ShortID properties of Wikidata
# derived from en.wikipedia via dbpedia

use strict;
use warnings;
use open ":encoding(utf8)";

use Data::Dumper;
use File::Slurp;
use JSON qw'decode_json encode_json';
use POSIX qw(strftime);
use REST::Client;
use URI::Escape;

my $ENDPOINT = 'http://172.16.10.102:3030/ebds/query';
my $QUERY_FN = '../sparql/dbpedia_repec_wd.rq';

my $timestamp = strftime "%Y-%m-%d", localtime;
my $beacon_header = <<"EOF";
#DESCRIPTION: RePEc-ShortID properties for wikidata from en.wikipedia via dbpedia
#CREATOR: ZBW - Leibniz Information Centre for Economics
#CONTACT: j.neuberti\@zbw.eu
#HOMEPAGE: http://zbw.eu
#TIMESTAMP: $timestamp
#PREFIX: http://www.wikidata.org/entity/
#ANNOTATION: RePEC author name
#TARGET: https://authors.repec.org/pro/
#WDTARGETPROPERTY: P2428

EOF

print $beacon_header;

# get query from github and encode it
my $query = read_file($QUERY_FN);
$query = uri_escape($query);

# create GET url
my $url = $ENDPOINT . '?query=' . $query;

# initialize rest client
my $client = REST::Client->new();

# execute the request (may also ask for 'text/csv') and write response to file
$client->GET( $url, { 'Accept' => 'application/sparql-results+json' } );
my $result_data;
eval {
  my $json = $client->responseContent();
  $result_data = decode_json($json);
};
if ($@) {
  die "Error parsing response: ", $client->responseContent(), "\n";
}

foreach my $entry ( @{ $result_data->{results}->{bindings} } ) {

  print $entry->{wdId}->{value}, '|', $entry->{wdLabel}->{value};
##  if ( $entry->{affiliations}{value} ) {
##    print ' (', $entry->{affiliations}->{value}, ')';
##  }
  print '|', $entry->{rasId}->{value}, "\n";
}

