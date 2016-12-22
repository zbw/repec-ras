#!/bin/env perl

#

use strict;
use warnings;
use open ":encoding(utf8)";

use Data::Dumper;
use JSON qw'decode_json encode_json';
use POSIX qw(strftime);
use REST::Client;
use URI::Escape;
use WWW::Github::Files;

# extract from Kims json file
my $OUT_FN = '../var/pers_examples/example2/map/gnd_ras_mapping.example.txt';
my $ENDPOINT   = 'http://172.16.10.102:3030/ebds/query';

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
print $out_fh $beacon_header;

# queries are downloaded from a github repository
my $gitfiles = WWW::Github::Files->new(
  author => 'zbw',
  resp   => 'repec_ras',
  branch => 'master',
);

# initialize rest client
my $client = REST::Client->new();

# get query from github and encode it
my $query = uri_escape( $gitfiles->get_file("/sparql/gnd_ras.rq") );

# create GET url
my $url = $ENDPOINT . '?query=' . $query;

# execute the request (may also ask for 'text/csv') and write response to file
$client->GET( $url, { 'Accept' => 'application/sparql-results+json' } );

my $result_data = decode_json( $client->responseContent() );

foreach my $entry ( @{ $result_data->{results}->{bindings} } ) {

  print $out_fh $entry->{gndId}->{value}, '|', $entry->{rasLabel}->{value};
  if ($entry->{affiliations}{value}) {
    print $out_fh ' (', $entry->{affiliations}->{value}, ')';
  }
  print $out_fh '|', $entry->{rasId}->{value}, "\n";
}

close $out_fh;

