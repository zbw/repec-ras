#!/bin/env perl
# nbt, 24.4.2017

# Transform GND-Repec-mapping file (Mail Kim 5.12.16)

use strict;
use warnings;

use Data::Dumper;
use File::Slurp;
use JSON qw'decode_json encode_json';

my $in_fn = '../var/ras/gnd_ras_mapping1/src/repec_econis.link_authors.sim.filtered.best.json';

open(my $in_fh, '<', $in_fn) or die "Could not open $in_fn: $!\n";


while (my $line = <$in_fh>) {
  my $rec = decode_json($line);
  #print Dumper $rec;
  my $ras = $rec->{sim}[0]{repec}{handle};
  my $gnd_structure = $rec->{sim}[0]{econbiz}{identifier_pnd};
  my @gnds;
  if (ref($gnd_structure) eq 'ARRAY') {
    @gnds = @{$gnd_structure};
  } else {
    push(@gnds, $gnd_structure);
  }

  foreach my $gnd (@gnds) {
    print "<http://authors.repec.org/pro/$ras> <http://purl.org/dc/terms/identifier> <http://d-nb.info/gnd/$gnd> .\n";
  }

}
