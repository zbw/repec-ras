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
use Text::Truncate;
use URI::Escape;

my $INPUT_FN = $ARGV[0] || undef;
my $ENDPOINT = 'http://zbw.eu/beta/sparql/repec/query';
my $QUERY_FN = '../sparql/ras_missing_in_wikidata.rq';
my $LIMIT    = 24;

my $result_data;
if ( -f $INPUT_FN ) {

  # read cached result - for developmnet
  my $json = read_file($INPUT_FN);
  $result_data = decode_json($json);

} else {

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
}

my $gnd_retrieved           = "|S813|+2017-02-01T00:00:00Z/10";
my $ras_retrieved           = "|S813|+2017-05-01T00:00:00Z/10";
my $gnd_reference_statement = "|S143|Q36578$gnd_retrieved";
##my $gnd_comment =
##  '|S2315|en:"Initial name form and German description text stem from GND"';
my $mapping_reference_statement =
    "|S1476|en:\"Derived from ZBW\'s RAS-GND authors mapping\""
  . "|S854|\"https://github.com/zbw/repec-ras/blob/master/doc/RAS-GND-author-id-mapping.md\"";
##my $ras_comment =
##'|S2315|en:"Initial list of affiliations in the description and possible alias names stem from RePEc Author Service"';

my $count;
foreach my $entry ( @{ $result_data->{results}->{bindings} } ) {

  # Limit the numer of results
  # (data checking required)
  $count++;
  last if $count > $LIMIT;

  # set record specific source statements
  my $gnd_source_statement = "|S248|Q36578|S227|\"$entry->{gndId}{value}\""
    . "|S1476|de:\"$entry->{gndName}{value}\"$gnd_retrieved";
  my $ras_source_statement = "|S248|Q206316|S2428|\"$entry->{rasId}{value}\""
    . "|S1476|en:\"$entry->{rasName}{value}\"$ras_retrieved";

  # swap gnd name pairs
  my $name = $entry->{gndName}->{value};
  if ( $name =~ m/^(.*?), (.*)$/ ) {
    $name = "$2 $1";
  }

  # create statements on stdout
  # (for copy&paste plus - for old quickstatements - replacing "|" by TAB)
  my $gendered_occupation;
  print "CREATE\n";

  # names and aliases
  foreach my $lang (qw/ en de fr it es pt /) {
    print "LAST|L$lang|\"$name\"\n";
    if ( lc($name) ne lc( $entry->{rasName}{value} ) ) {
      print "LAST|A$lang|\"$entry->{rasName}{value}\"\n";
    }
  }

  # human, gender, occupation
  print "LAST|P31|Q5$gnd_source_statement\n";    # human
  if ( $entry->{gender}{value} eq 'female' ) {
    $gendered_occupation = 'Wirtschaftswissenschaftlerin';
    print "LAST|P21|Q6581072$gnd_source_statement\n";
  } elsif ( $entry->{gender}{value} eq 'male' ) {
    $gendered_occupation = 'Wirtschaftswissenschaftler';
    print "LAST|P21|Q6581097$gnd_source_statement\n";
  } else {
    $gendered_occupation = 'Wirtschaftswissenschaftler/in';
  }

  # description
  print "LAST|Dde|\"",
    create_description(
    $gendered_occupation,
    $entry->{info}{value},
    $entry->{worksFor}{value}
    ),
    "\"\n";
  print "LAST|Den|\"",
    create_description( 'economist', $entry->{worksFor}{value} ), "\"\n";

  # occupaton and life data
  print "LAST|P106|Q188094$ras_source_statement\n";    # economist
  if (exists $entry->{birthDate}) {
    my $date = $entry->{birthDate}{value};
    if (length($date) eq 4) {
      $date = "${date}-01-01T00:00:00Z/9";
    } elsif (length($date) eq 10) {
      $date = "${date}T00:00:00Z/11";
    } else {
      # ignore dates which are not year or day
      $date = undef;
    }
    if ($date) {
      print "LAST|P569|+$date$gnd_source_statement\n";
    }
  }
  if (exists $entry->{deathDate}) {
    my $date = $entry->{deathDate}{value};
    if (length($date) eq 4) {
      $date = "${date}-01-01T00:00:00Z/9";
    } elsif (length($date) eq 10) {
      $date = "${date}T00:00:00Z/11";
    } else {
      # ignore dates which are not year or day
      $date = undef;
    }
    if ($date) {
      print "LAST|P570|+$date$gnd_source_statement\n";
    }
  }

  # external IDs
  print
"LAST|P227|\"$entry->{gndId}->{value}\"$gnd_reference_statement\n";
  print
"LAST|P2428|\"$entry->{rasId}->{value}\"$mapping_reference_statement\n";
}

#########################

sub create_description {
  my $occupation     = shift || die "param missing\n";
  my $info           = shift;
  my $alternate_info = shift;

  # maximum total length of the description in wd
  my $max_width_total = 250;
  my $max_width_description = $max_width_total - ( length($occupation) + 3 );

  # build description
  my $description = $info;
  if ( not $description or $description eq $occupation ) {
    $description = $alternate_info;
  }

  if ($description) {

    # make sure that description fits the total width
    $description = truncstr( $description, $max_width_description );

    $description = "$occupation ($description)";
  } else {
    $description = $occupation;
  }
  return $description;
}

