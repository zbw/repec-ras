#!/bin/env perl
# nbt, 11.4.2017

# Dump certain properties from Wikidata

use strict;
use warnings;
use open ":encoding(utf8)";

binmode STDOUT, ":utf8";

use Data::Dumper;
use File::Slurp;
use JSON qw'decode_json encode_json';
use REST::Client;
use URI::Escape;

my $ENDPOINT  = 'https://query.wikidata.org/bigdata/namespace/wdq/sparql';

# wikidata properties to dump
my %property = (
  'repec' => 'P2428',
  'gnd'   => 'P227',
);

# initialize rest client
my $client = REST::Client->new();

foreach my $prop ( keys %property ) {

  my $query = <<"EOF";
prefix wdt: <http://www.wikidata.org/prop/direct/>
select *
where {
  ?wd wdt:$property{$prop} ?id .
}
EOF
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

    # check for illegal gnd id values (with right-to-left mark)
    if ( $prop eq 'gnd' ) {
      # DOES NOT WORK!
      next
        unless $entry->{id}->{value} =~
        m/^(1|1[01])\d{7}[0-9X]|[47]\d{6}-\d|[1-9]\d{0,7}-[0-9X]|3\d{7}[0-9X]$/;
      next if $entry->{id}->{value} =~ m/\x{E2808F}/;
    }

    # print as ntriples
    print '<', $entry->{wd}->{value},
      "> <http://www.wikidata.org/prop/direct/$property{$prop}> ", 
      "\"$entry->{id}->{value}\" . \n";
  }
}
