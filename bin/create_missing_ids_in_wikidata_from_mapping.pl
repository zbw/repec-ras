#!/bin/env perl
# nbt, 27.4.2017

# Get missing properties from a mapping (via SPARQL query) and create
# statements for https://tools.wmflabs.org/quickstatements/
# (to be inserted by copy&paste)

# Can be configured to use either a generic or a specialized query
# The query is expected to return ?wdId, ?sourceId and ?targetId

use strict;
use warnings;
use open ":encoding(utf8)";

binmode STDOUT, ":utf8";

use Data::Dumper;
use File::Slurp;
use JSON qw'decode_json encode_json';
use REST::Client;
use URI::Escape;

# number of statements produced, used to replace a limit clause in the query
my $LIMIT = 4000;

# default settings, can be overridden by %config
my $ENDPOINT = 'http://zbw.eu/beta/sparql/repec/query';
my $QUERY_FN = '../sparql/missing_ids_in_wikidata_from_mapping.rq';

# if "source_authority" is set, the information is derived directly from an
# authority, otherwies from a 3rd party mapping loaded into graphs of a custom
# endpoint
my %config = (
  gnd_ras => {
    has_reverse => 1,
    name        => 'ZBW\'s RAS-GND authors mapping',
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
  viaf_gnd => {
    has_reverse      => 0,
    name             => "VIAF's mapping to GND",
    endpoint         => 'http://localhost:3030/viaf/query',
    query_fn         => '/opt/sparql-queries/viaf/missing_gnd_id_for_viaf.rq',
    source_authority => {
      item => 'Q54919',                     # VIAF
      date => '+2017-04-01T00:00:00Z/10',
    },
    first => {
      name        => 'VIAF ID',
      wd_property => 'P214',
    },
    second => {
      name        => 'GND ID',
      wd_property => 'P227',
    },
  },
  ideas_ras => {
    has_reverse => 0,
    name        => 'Wikidata internal mapping from IDEAS to RAS id',
    endpoint    => 'https://query.wikidata.org/bigdata/namespace/wdq/sparql',
    query_fn => '/opt/sparql-queries/wikidata/missing_repec_id_from_ideas.rq',
    source_authority => undef,    # Wikidata itself
    first            => {
      name        => 'IDEAS person ID',
      wd_property => 'P3649',
    },
    second => {
      name        => 'RePEc Short-ID',
      wd_property => 'P2428',
    }
  }
);

# add source property names for beeing usesd in reference statements
# (e.g., S214 instead of P214)
foreach my $mapping_name ( keys %config ) {

  foreach my $position (qw/ first second /) {
    my $source_property = $config{$mapping_name}{$position}{wd_property};
    $source_property =~ s/^P(\d+)$/S$1/;
    $config{$mapping_name}{$position}{wd_sourceproperty} = $source_property;
  }
}

# params
my ( $mapping_name, $direction, $source, $target );
if ( @ARGV < 1 ) {
  print "usage: $0 vocab {reverse}\n";
  exit 1;
} elsif ( not grep( /^$ARGV[0]$/, keys %config ) ) {
  print "vocab must be one of [ ", join( ' ', keys %config ), " ]\n";
  exit 1;
} else {
  $mapping_name = $ARGV[0];
  $direction = $ARGV[1] || 'straight';
}

# set source and target
my $mapping = $config{$mapping_name};
if ( $direction eq 'reverse' ) {
  if ( $mapping->{has_reverse} ) {
    $source = 'second';
    $target = 'first';
  } else {
    print "Mapping $mapping_name has no support for 'reverse'\n";
    exit 1;
  }
} else {
  $source = 'first';
  $target = 'second';
}

# source title (and url) currently can be used only in quickstatements2
$mapping->{title} = "Via $mapping->{$source}{wd_property} "
  . "lookup, derived from $mapping->{name}";

# initialize rest client
my $client = REST::Client->new();

# get SPARQL query
my $query =
  read_file( defined $mapping->{query_fn} ? $mapping->{query_fn} : $QUERY_FN );

# for generic query, replace values
if ( not defined $mapping->{query_fn} ) {

  # replace the values clause of the query
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

}

# replace limit clause (if exists)
$query =~ s/limit (\d+)$/limit $LIMIT/i;

$query = uri_escape($query);

# create GET url
my $url =
    ( defined $mapping->{endpoint} ? $mapping->{endpoint} : $ENDPOINT )
  . '?query='
  . $query;

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

  # reference statement
  my $reference_statement;
  if ( $mapping_name eq 'gnd_ras' ) {

    # special cse
    $reference_statement =
      "|S1476|en:\"$mapping->{title}\"|S854|\"$mapping->{url}\"";
  } else {
    $reference_statement =
      defined $mapping->{source_authority}
      ? "|S248|$mapping->{source_authority}{item}|"
      . "$mapping->{$source}{wd_sourceproperty}|\"$entry->{sourceId}->{value}\"|"
      . "S813|$mapping->{source_authority}{date}"
      : '';
  }

  # create statements on stdout
  print "$entry->{wdId}->{value}|"
    . "$mapping->{$target}{wd_property}|\"$entry->{targetId}->{value}\""
    . "$reference_statement\n";
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

