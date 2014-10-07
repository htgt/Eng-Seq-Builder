#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';

use IO::File;
use IO::Handle;
use Bio::SeqIO;
use Bio::SeqUtils;

my $filename = shift @ARGV;
my $ifh = IO::File->new( $filename, O_RDONLY );    

my $ofh = IO::Handle->new->fdopen( fileno(STDOUT), 'w' );

my $seq_in = Bio::SeqIO->new( -fh => $ifh );

my $seq = $seq_in->next_seq;

my $seq_out = Bio::SeqIO->new( -fh => $ofh, -format => 'genbank' );

# empty vector
#my $backbone_seq = Bio::SeqUtils->trunc_with_features( $seq, 640 , $seq->length ); 
#my $append_backbone_seq = Bio::SeqUtils->trunc_with_features( $seq, 1, 613 );
# crispr vector
my $crispr_seq = Bio::SeqUtils->trunc_with_features( $seq, 614, 633 );
my $backbone_seq = Bio::SeqUtils->trunc_with_features( $seq, 634 , $seq->length ); 
my $append_backbone_seq = Bio::SeqUtils->trunc_with_features( $seq, 1, 613 );

# backbone seq
#Bio::SeqUtils->cat( $backbone_seq, $append_backbone_seq );
#$seq_out->write_seq( $backbone_seq );

print STDERR $crispr_seq->seq;
# crispr vector with crispr as front
Bio::SeqUtils->cat( $crispr_seq, $backbone_seq, $append_backbone_seq );
$seq_out->write_seq( $crispr_seq );

