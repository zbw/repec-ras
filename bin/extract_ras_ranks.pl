#!/usr/bin/env perl
# nbt, 23.12.2016

# extract ras uris and ranking from IDEAS pages

use strict;
use warnings;

use open ":encoding(utf8)";

use WWW::Mechanize;

# the ranking pages from IDEAS
my %PAGE = (
  Top10pct       => 'https://ideas.repec.org/top/top.person.all.html',
  Top10pctFemale => 'https://ideas.repec.org/top/top.women.html',
);

my $RDF_DIR = '../var/ras/latest/rdf';

my $mech = WWW::Mechanize->new();

foreach my $ranking ( keys %PAGE ) {

  my $response = $mech->get( $PAGE{$ranking} );

  # extract ranking version from page
  $mech->content() =~ m:<h1>Top .*?, as of (.*?)</h1>:i;
  die "No version information found on page\n" unless $1;

  my $version = $1;
  $version =~ s/ //g;
  $version = lc($version);

  my $out_fn = "$RDF_DIR/rasRank$ranking-$version.nt";
  open( my $out_fh, '>', $out_fn ) or die "Could not open $out_fn: $!\n";

  my @links = $mech->links();
  my $rank  = 1;
  for my $link (@links) {

    # match typical ras link
    next unless $link->url =~ m:^/[a-z]/(p[a-z]{2}\d{1,4})\.html:;

    print $out_fh "<http://authors.repec.org/pro/$1> "
      . "<http://dbpedia.org/ontology/rank> \"$rank\" "
      ##. "<http://zbw.eu/beta/ebds/ras$ranking-$version/ng>"
      . ". \n";
    $rank++;
  }
  close $out_fn;

  print "$rank lines written to $out_fn\n";
}
