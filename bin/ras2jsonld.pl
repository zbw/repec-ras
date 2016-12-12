#!/usr/bin/perl
# nbt, 1.12.2016

# Convert repec author records to jsonld

# based on:

##
## run redson --help or redson -h for a brief help message.
##
## Copyright (c) 2016 by Thomas Krichel.
##
## This program is free software; you can redistribute it and/or modify it
## under the same terms as Perl itself.

## Standard Library

use strict;
use Data::Dumper;
use File::Find;
use Getopt::Long;
# use JSON;
use IO::File;

BEGIN {
  eval { require JSON; };
  if ( $@ ) {
    "I need the JSON module.\n";
    exit (0);
  }
}

# jsonld context file
my $CONTEXT = 'file:///opt/repec_ras/etc/ras_context.jsonld';

my $json = JSON->new->allow_nonref;


## program information
my $VERSION = "0.1";            
my $ProgrammName="redson";
my $ProgrammVersion="1.$VERSION";
my $ProgrammDescription='JSON output for ReDIF data';
my $ProgrammAuthor='Thomas Krichel';
my $ProgrammAuthorEmail="krichel\@openlib.org";
my $prog_string="- $ProgrammName v$ProgrammVersion -- $ProgrammDescription -\n".
  "\tby $ProgrammAuthor ($ProgrammAuthorEmail)\n\n";

my $help_message = <<END_OF_HELP;
Use: 
    redson [ OPTIONS ] [ file-or-directory_1 file-or-dirctory_2 ... ]

Some options:
  -h or --help 
     shows this help message and quits
  -l log_file
     logs to the file log_file
  -p prettyprints the output

See perldoc redson for more options and other information.
END_OF_HELP

## check for help
my $i = 0;
my $help; 
while ( $ARGV[$i] ) {
  my $para = $ARGV[$i];
  if ( ( $para eq '-h' ) 
       or ( $para eq '--help' ) 
       or ( $para eq '-help' ) 
     ) {
    $help = 1;
  }
  $i++;
}
if( $help ) {
  print $help_message;
  exit;
}


use ReDIF::init;

BEGIN { 
  ReDIF::initialize( {'print_results' => 0 } );
}

## specification
    
use ReDIF::Spec ();

my $spec_file = $ReDIF::CONFIG{'spec_full_name'} ;

my $spec_object = ReDIF::Spec -> new( $spec_file );

my $redif_home      = $ReDIF::CONFIG{'redif_home'};
my $redif_home_type = $ReDIF::CONFIG{'redif_home_type'};
my $local_data_dir  = $ReDIF::CONFIG{'data_path'} || '';

my $address  = $ReDIF::CONFIG{'address'};
my $archive  = $ReDIF::CONFIG{'archive_id'};
#  my $authority = $ReDIF::CONFIG{'authority_id'};

binmode( STDOUT, ":utf8" );
my %opt;
&GetOptions ( \%opt,
              ## log file
              'l=s',
              ## help 
              'h', 'help',
              ## don't do the local archive
              'x',
              ## indent
              'i',
              ## pretty
              'p',
              ## space
              's');

## the log file
my $log_file = $opt{'l'} // '';
my $log;
if($log_file) {
  $log = IO::File->new();
  my $opened=$log->open("> $log_file");
  if(not $opened) {
    die "I can not open the log file '$log_file'.\n";
    exit;
  }
  $log->binmode(':utf8');
}

my $dir_string= defined $redif_home ? ( $redif_home, " (type: $redif_home_type)" ) : 'not identified';

my $log_start= "configuration: \n".
  "\tredif.spec file   : ".$spec_file."\n".
  "\tredif.spec version: ".$spec_object->version. "\n".
  "\tReDIF home dir    : ".$dir_string."\n".
  "\tlocal data dir    : ".$local_data_dir."\n";

if($log) {
  print $log $prog_string,$log_start;
}

if($log) {
  if ( defined $redif_home ) {
    print $log "Start as ReDIF archive <$address> at dir $redif_home" , 
      " (type: $redif_home_type)\n";
  }  
  else {
    print $log "I found no ReDIF home setting.\n";
  }
}

my $message_threshold = 2;
my $check_local_archive_dir = 1;
my $source_quote = 1;
my $unicode_output = 0;

###    Continuing the command-line options analysis
  
if ( (defined $opt{'h'}) or (defined $opt{'help'}) ) {
  die "Help options should have been treated above.";
}

if ( defined $opt{'p'} ) {
  if($log) {
    print $log "I see the option '-p'. I will pretty-print.\n"; 
  }
  $json = $json->pretty(1);
}

if( defined $opt{'s'} ) {
  if($opt{'p'} and $log) {
    print $log "You have already set -p, thus -s has no effect\n";
  }
  else {
    if($log) {
      print $log "I see the option '-s'. I will add space.\n"; 
    }
    $json = $json->space_before(1);
    $json = $json->space_after(1);
  }
}

if ( defined $opt{'i'} ) {
  if($opt{'p'}) {
    if($log) {
      print $log "You have already set -p, thus -i has no effect.\n";
    }
  }
  else {
    if($log) {
      print $log "You gave me option '-i'. I will indent.\n"; 
    }
    $json = $json->indent(1);
  }
}

if ( defined $opt{'x'} ) {
  $check_local_archive_dir = 0;
  if($log) {
    print $log "option '-x': I will not read the local data directory.\n"; 
  }
}

## source reporting
if ( defined $opt{'s'} ) {
  $source_quote = 1;
  if($log) {
    print $log "option '-n': I will quote source files on errors and warnings.\n";
  }
}


my @check_list = @ARGV;

my %Options = (
               'build_template_hash' => 0,
               'quote_source' => 0,
               'message_threshold' => $message_threshold,
               'use_parser_input' => 1,
               'redif_specification' => $spec_object,
               'utf8_output' => 1,
              );


use ReDIF::Parser qw( &redif_open_file 
                      &redif_get_next_template 
                      &redif_get_next_template_good_or_bad ) ;

ReDIF::Parser::redif_set_parser_options( %Options );

if($log) {
  print $log "\n";
}

## global records counter
my $count_records=0;
## state variable if a comma has been printed
my $comma_printed=0;

print '{ "@context": "', $CONTEXT, '",', "\n", '  "@graph": ', "\n";
print '[';
if($opt{'p'} or $opt{'i'}) {
  print "\n";
}

if ( scalar @check_list ) {
  if($log) {
    print $log "Reading ", ( join ', ', @check_list ) , "\n";
  }
  foreach my $file ( @check_list ) {
    if ( -e $file ) {
      if ( -f _ ) {
        checkfile ( $file );
      }
      elsif ( -d _ ) {
        if($log) {
          print $log "I go into directory: '$file'\n";
        }
        find( \&wanted, $file ) ;
      }
      elsif($log) {
        print $log "I can't read '$file'\n";
      }
    }
    elsif($log) {
      print $log "I am not sure what '$file'? is.\n";
    }
  } 
}
else {
  if ( $check_local_archive_dir ) {
    if ( defined $local_data_dir ) {
      if($log) {
        print $log "going into directory: $local_data_dir\n";
      }
      find( \&wanted, $local_data_dir ) ;
    }
    else {
      if($log) {
        print $log "Local data directory is unknown: specify ReDIF home";
      }
    }
  }
  else {
    if($log) {
      print $log "Nothing to check." ;
    }    
  }
}

if($opt{'p'} or $opt{'i'}) {
  print "\n";
}
print "]\n";
print "}\n";

if($log) {
  print $log "\n";
  $log->close();
}

####################################################

sub wanted {
  if (/\.(?:rdf|redif)$/i) {
    my $file = $_;
    checkfile( $File::Find::name, $_ );
  }
}

sub checkfile {
  my $filename      = shift ;
  my $local_name    = shift || $filename;
  my $file_type = '';
  my $ok;
  if($log) {
    print $log "file $filename: ";
  }
  redif_open_file( $local_name );
  my $good_templates=0;
  my $bad_templates=0;
  while ( 1 ) {
    my $t = redif_get_next_template_good_or_bad();
    if ( not $t ) {
      last;
    }
    else {
      if ( not defined $ok ) {
        $ok = 1 ;
      }
    }

    ## record-separating comma
    if($count_records and not $comma_printed) {
      print ',';
      $comma_printed=1;
      if( $opt{'p'} or $opt{'i'}) {
        print "\n";
      }
    }
    $count_records++;
    if ( $t->{'ENCODING'} eq 'invalid' ) {
      if ( $t->{'ERRORS'} ) {
        print $log "\nI found a unicode template with charset problems.";
      }
    }
    if ( $t->{'MESSAGES'} and $log) {
      print $log "\n", $t->{'REPORT'};
      $ok = 0;
    }
    if ( $t->{'RESULT'} eq 'good' ) {
      $good_templates++;
    }
    else {
      $bad_templates++;
      next;
    }    

    $t = transform2ld($t);

    my $text = $json->encode($t);  
    ## indent the record if required
    if( $opt{'p'} or $opt{'i'}) {
      $text='   '.$text;
      $text=~s|\n|\n   |g;
    }
    print "$text";
    $comma_printed=0;
    if ( $ok and $log) {
      print $log "OK ($good_templates)";
    }
    elsif ( not defined $ok ) {
      if($log) {
        print $log "empty or foreign file";
      }
    }
    if($log) {
      print $log "\n";
    }
  }
}

sub transform2ld {
  my $t = shift;

  my $ld;
  $ld->{'@id'} = 'ras:' . $t->{'short-id'}[0];
  $ld->{'name-full'} = $t->{'name-full'}[0];

  # publications
  my @pub_types = qw/ article book paper /;
  my $pub_count = 0;
  foreach my $pub_type (@pub_types) {
    if ($t->{"author-$pub_type"}) {
      $pub_count += scalar(@{$t->{"author-$pub_type"}});
    }
  }
  $ld->{"publications_count"} = $pub_count;

  # affiliations (concatenate multiple affiliation strings)
  my @affiliations;
  foreach my $workplace (@{$t->{'workplace'}}) {
    push(@affiliations, $workplace->{'name'}[0]);
  }
  if (scalar(@affiliations) gt 0) {
    $ld->{affiliation} = join('; ', @affiliations);
  }

  return $ld;
}


############################################################################

1;

__END__

=head1 NAME

redson - ReDIF data JSON reader

=head1 SYNOPSIS

redson [-l log_file ] [ -i ] [ -s ] [ -p ] [ -x ] 
[ --spec specification-file | --redif.spec specification-file ]
[ --rdir ReDIF-home-dir | --redif.home ReDIF-home-dir ]
[ file-or-directory_1 file-or-dirctory_2 ... ]

=head1 DESCRIPTION

This utility is part of ReDIF-perl suite.  It's purpose is to read
ReDIF data in JSON format. The output is JSON.

Redson reads the files named on the command line or searches the named
directories for files with the ".rdf" or ".redif" extensions.  If you
asked for a log, that log may contain a detailed report about the
problems found with the data. Or it may say "OK" for each file.

If not a single file or directory is specified on the command line to
be checked, then the local RePEc archive (or other ReDIF-home's data
directory) will be checked, unless '-x' option is present.

=head1 MAIN OPTIONS

=over 4

=item -l log_file

Log to the file log_file. Your script will die if it can't open the file.

=item -i

Indent json output.

=item -s

Add spaces before and after values in the json output.

=item -p

Prettyprint the json oput. That's the same as -i and -s combined.

=item -x

Do not check local RePEc archive (or stand-alone ReDIF-home's data/
dir).  This option only makes sense when no file/directory is given on
the command line and you have set the log file with -l. Then it makes
redson run in "read no ReDIF" mode.  It only checks the configuration,
and reports it to you in the log. 

=back 

=head1 GENERAL ReDIF SOFTWARE OPTIONS

=over 4

=item --spec FILE-OR-DIR, --redif.spec FILE-OR-DIR

specifies a ReDIF specification filename to use.  If the option
parameter FILE-OR-DIR is a valid directory name, then "redif.spec"
file will be searched for in that directory and will be used if
present.  If the parameter is not a directory, but contains a slash or
backslash character, it is assumed to be a full path filename of the
'redif.spec' file to use.  If the parameter is not a directory and has
no slash/backslash in it, then it is treated as a name of the file to
be used instead of 'redif.spec' in the default specification
directory, which depends on the specified or otherwise given ReDIF home
directory.

So giving "--spec ./spec" would make redson to look for redif.spec in
that directory, and abort if not found.

Giving "--spec /home/ivan/special-redif.spec" would mean that that file 
would be checked and used if found, or redson will abort.

Giving "--spec new-redif.spec" means that in the default
"redif.spec"'s directory file "new-redif.spec" will be searched and
used if found. Otherwise redson aborts.

Option --redif.spec is equivalent.


=item --rhome REDIFDIR, --redif.home REDIFDIR

Sets the directory of your RePEc archive or ReDIF home.  Overrides
REDIFDIR (and REDIFHOME) environment variables and other settings.

=back

=head1 TO DO

=over 4

=item * 

an option to turn off recursive directory treatment

fix the $revision for the ReDIF spec file. 

=back


=head1 AUTHOR

Thomas Krichel for the RePEc project

The development of this software was funded by Sultan Orazbayev. 

=cut




