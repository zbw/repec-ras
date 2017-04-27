#!/bin/env perl
# nbt, 11.4.2017

# get ras data missing in Wikidata and create statements 
# for https://tools.wmflabs.org/wikidata-todo/quick_statements.php

use strict;
use warnings;
use open ":encoding(utf8)";

binmode STDOUT, ":utf8";

use Data::Dumper;
use File::Slurp;
use JSON qw'decode_json encode_json';
use REST::Client;
use URI::Escape;

my $ENDPOINT = 'http://zbw.eu/beta/sparql/repec/query';
my $QUERY_FN = '../sparql/ras_missing_in_wikidata.rq';

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

my $count;
foreach my $entry ( @{ $result_data->{results}->{bindings} } ) {
  
  # Limit the numer of results
  # (data checking required)
  $count++;
  last if $count > 100;

  # truncate description (max field length 250)
  my $description = $entry->{description}->{value};
  if (length($description) > 250) {
    $description = substr($description, 0, 244) . '...)';
  }

  # create statements on stdout
  # (for copy&paste plus replacing "__" by TAB)
  print "CREATE\n";
  print "LAST__Len__\"$entry->{name}->{value}\"\n";
  print "LAST__Den__\"$description\"\n";
  print "LAST__P2428__\"$entry->{id}->{value}\"\n";
  print "LAST__P31__Q5\n";       # human
  print "LAST__P21__Q6581072\n"; # female
  print "LAST__P106__Q188094\n"; # economist
}
