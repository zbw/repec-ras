#!/bin/env perl
# nbt, 18.12.2016

# Create Beacon file for RePEc-ShortID properties of Wikidata
# mapped from GND properties

use strict;
use warnings;
##use open ":encoding(utf8)";
 
use Data::Dumper;
use File::Slurp;
use JSON qw'decode_json encode_json';
use POSIX qw(strftime);
use REST::Client;
use URI::Escape;

# extract from Kims json file
my $OUT_FN = '../var/pers_examples/example2/map/gnd_ras_mapping.example.csv';
my $ENDPOINT   = 'http://172.16.10.102:3030/ebds/query';
my $QUERY_FN = '../sparql/gnd_ras.rq';

my $timestamp = strftime "%Y-%m-%d", localtime;
my $beacon_header = <<"EOF";
#DESCRIPTION: Mapping from GND-ID to Repec-ShortID
#CREATOR: ZBW - Leibniz Information Centre for Economics
#CONTACT: j.neuberti\@zbw.eu
#HOMEPAGE: http://zbw.eu
#TIMESTAMP: $timestamp
#PREFIX: http://d-nb.info/gnd/
#ANNOTATION: RePEC author name
#TARGET: https://authors.repec.org/pro/
#WDSOURCEPROPERTY: P227
#WDTARGETPROPERTY: P2428

EOF

open( my $out_fh, '>', $OUT_FN )
  or die "Could not open $OUT_FN: $!\n";
binmode($out_fh, ":utf8");
binmode(STDOUT, ":utf8");
print $out_fh "source, target, annotation\n";

print $beacon_header;

# initialize rest client
my $client = REST::Client->new();

# get query and encode it
my $query = read_file($QUERY_FN);
$query = uri_escape($query);

# create GET url
my $url = $ENDPOINT . '?query=' . $query;

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

  print $entry->{gndId}->{value}, '|', $entry->{rasLabel}->{value};
##  if ($entry->{affiliations}{value}) {
##    print $out_fh ' (', $entry->{affiliations}->{value}, ')';
##  }
  print '|', $entry->{rasId}->{value}, "\n";
  print $out_fh "$entry->{gndId}->{value}, $entry->{rasId}->{value}, \"$entry->{rasLabel}->{value}\"\n";
}

close $out_fh;

