#!/bin/env perl
# nbt, 27.4.2017

# Get missing properties from a mapping and create statements
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

my %config = (
  gnd_ras => {
    name => 'ZBW\'s RAS-GND authors mapping',
    url =>
'https://github.com/zbw/repec-ras/blob/master/doc/RAS-GND-author-id-mapping.md',
    graph => 'http://zbw.eu/beta/gndRas2/ng',
    first => {
      graph          => 'http://zbw.eu/beta/gnd/ng',
      name           => 'GND ID',
      label_property => 'gndo:preferredNameForThePerson',
      wd_property    => 'P227',
      stub           => 'http://d-nb.info/gnd/',
    },
    second => {
      graph          => 'http://zbw.eu/beta/repec/ng',
      name           => 'RePEc Short-ID',
      label_property => 'foaf:name',
      wd_property    => 'P2428',
      stub           => 'http://authors.repec.org/pro/',
    },
  },
  stw_gnd => {}
);

# params
my ( $mapping_name, $direction, $source, $target );
if ( @ARGV < 1 ) {
  print "usage: $0 vocab {reverse}\n";
  exit;
} elsif ( not grep( /^$ARGV[0]$/, keys %config ) ) {
  print "vocab must be one of [ ", join( ' ', keys %config ), " ]\n";
  exit;
} else {
  $mapping_name = $ARGV[0];
  $direction = $ARGV[1] || 'straight';
}

# set source and target
my $mapping = $config{$mapping_name};
if ( $direction eq 'reverse' ) {
  $source = 'second';
  $target = 'first';
} else {
  $source = 'first';
  $target = 'second';
}

# currently cannot be used, because quickstatements only supports formal source
# properties
$mapping->{title} = "Via $mapping->{$source}{wd_property} "
  . "lookup, derived from $mapping->{name}";

my $ENDPOINT = 'http://zbw.eu/beta/sparql/repec/query';
my $QUERY_FN = '../sparql/missing_ids_in_wikidata_from_mapping.rq';

# initialize rest client
my $client = REST::Client->new();

# get query and encode it
my $query = read_file($QUERY_FN);

# replace values clause
my $insert_value_ref = {
  '?mappingGraph'  => "<$mapping->{graph}>",
  '?sourceGraph'   => "<$mapping->{$source}{graph}>",
  '?sourceLblProp' => $mapping->{$source}{label_property},
  '?sourceWdProp'  => "wdt:$mapping->{$source}{wd_property}",
  '?sourceStub'    => "\"$mapping->{$source}{stub}\"",
  '?targetGraph'   => "<$mapping->{$target}{graph}>",
  '?targetLblProp' => $mapping->{$target}{label_property},
  '?targetWdProp'  => "wdt:$mapping->{$target}{wd_property}",
  '?targetStub'    => "\"$mapping->{$target}{stub}\"",
};
$query = change_values_in_query( $query, $insert_value_ref );

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
#  last if $count > 100;

  # create statements on stdout
  print "$entry->{wdId}->{value}|"
    . "$mapping->{$target}{wd_property}|\"$entry->{targetId}->{value}\"|"
    . "S1476|en:\"$mapping->{title}\"|"
    . "S854|\"$mapping->{url}\"\n";
}

#############################################

sub change_values_in_query {
  my $query            = shift or die "param missing\n";
  my $insert_value_ref = shift or die "param missing\n";

  # parse VALUES clause
  my ( $variables_ref, $value_ref ) = parse_values($query);

  # replace values
  foreach my $variable ( keys %$value_ref ) {
    if ( defined( $insert_value_ref->{$variable} ) ) {
      $value_ref->{$variable} = $insert_value_ref->{$variable};
    }
  }
  $query = insert_modified_values( $query, $variables_ref, $value_ref );

  return $query;
}

sub parse_values {
  my $query = shift or die "param missing\n";

  $query =~ m/ values \s+\(\s+ (.*?) \s+\)\s+\{ \s+\(\s+ (.*?) \s+\)\s+\} /ixms;

  my @variables  = split( /\s+/, $1 );
  my @values_tmp = split( /\s+/, $2 );
  my %value;
  for ( my $i = 0 ; $i < scalar(@variables) ; $i++ ) {
    $value{ $variables[$i] } = $values_tmp[$i];
  }
  return \@variables, \%value;
}

sub insert_modified_values {
  my $query         = shift or die "param missing\n";
  my $variables_ref = shift or die "param missing\n";
  my $value_ref     = shift or die "param missing\n";

  # create new values clause
  my @values;
  foreach my $variable (@$variables_ref) {
    push( @values, $$value_ref{$variable} );
  }
  my $values_clause =
      ' values ( '
    . join( ' ', @$variables_ref )
    . " ) {\n    ( "
    . join( ' ', @values )
    . " )\n  }";

  # insert into query
  $query =~ s/\svalues .*? \s+\)\s+\}/$values_clause/ixms;
  return $query;
}

