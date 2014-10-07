#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';

use IO::File;
use IO::Handle;
use Bio::SeqIO;
use Bio::SeqUtils;

use EngSeqBuilder;

my $esb = EngSeqBuilder->new;

my $crispr_vector_seq = $esb->crispr_vector_seq(
    crispr_seq => 'GGGGATATCGGCCCCAAGTT',
    backbone   => { name => 'U6_BsaI_gRNA' },
    display_id => 'test_crispr',
    crispr_id  => '1234',
    species    => 'human',
);

print $crispr_vector_seq->is_circular;

my $ofh = IO::Handle->new->fdopen( fileno(STDOUT), 'w' );
my $seq_out = Bio::SeqIO->new( -fh => $ofh, -format => 'genbank' );
$seq_out->write_seq( $crispr_vector_seq );

# in file
#GGGGATATCGGCCCCAAGTT
# in db
#GGGGATATCGGCCCCAAGTTTGG

#GGGGATATCGGCCCCAAGTT - 20
#GGGGATATCGGCCCCAAGTTTGG - 23
