#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';

use IO::File;
use IO::Handle;
use Bio::SeqIO;
use Bio::SeqUtils;
use EngSeqBuilder::SiteSpecificRecombination qw( _merge_synthetic_cassette_features );

my $filename = shift @ARGV;
my $ifh = IO::File->new( $filename, O_RDONLY );

my $ofh = IO::Handle->new->fdopen( fileno(STDOUT), 'w' );

my $seq_in = Bio::SeqIO->new( -fh => $ifh );

my $seq = $seq_in->next_seq;

my $seq_out = Bio::SeqIO->new( -fh => $ofh, -format => 'genbank' );

my $mod_seq = _merge_synthetic_cassette_features( $seq );

$seq_out->write_seq( $mod_seq );
