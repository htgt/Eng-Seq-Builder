#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';

use Bio::SeqIO;
use FindBin '$Bin';
use Test::Most;

BEGIN { use_ok 'EngSeqBuilder::SiteSpecificRecombination', ':all' }

my @TESTS = (
    {
        file    => 'one.gbk',
        actions => [
            {
                ssr    => 'flp',
                length => 31592
            },
            {
                ssr    => 'cre',
                length => 35268
            },
            {
                ssr    => 'flp_and_cre',
                length => 30275
            },
        ],
        name   => '3 loxp, 2 frt seq'
    },
    {
        file    => 'two.gbk',
        actions => [
            {
                ssr    => 'flp',
                length => 31367
            },
            {
                ssr   => 'cre',
                length => 36360
            },
        ],
        name   => '2 loxp, 2 frt seq',
    },
    {
        file    => 'six.gbk',
        actions => [
            {
                ssr    => 'flp',
                length => 32406
            },
            {
                ssr    => 'cre',
                length => 35268
            },
            {
                ssr    => 'flp_and_cre',
                length => 30275
            },
        ],
        name   => '3 loxp, 2 frt seq -ve strand'
    },
    {
        file    => 'two.gbk',
        actions => [
            {
                ssr    => 'flp_and_cre',
                length => 31367
            },
        ],
        name    => '2 loxp, 2 frt, fail apply_flp_cre, only flp applied'
    },
    {
        file    => 'three.gbk',
        actions => [
            {
                ssr    => 'cre',
                length => 35268
            },
        ],
        name    => '1 loxp, fail apply_cre'
    },
    {
        file    => 'four.gbk',
        actions => [
            {
                ssr    => 'flp',
                length => 38271,
            },
        ],
        name   => '1 frt, fail apply_flp'
    },
    {
        file    => 'five.gbk',
        actions => [
            {
                ssr    => 'cre',
                length => 38271,
            },
        ],
        name   => 'no loxp, fail apply_cre'
    },
    {
        file    => 'seven.gbk',
        actions => [
                        {
                               ssr    => 'dre',
                               length => 21886
                        },
                   ],
        name    => '2 rox'
    },
);

my %SUBS = (
    cre         => \&apply_cre,
    flp         => \&apply_flp,
    dre         => \&apply_dre,
    flp_and_cre => \&apply_flp_cre,
);

for my $t (@TESTS) {
    my $file = "$Bin/test_files/" . $t->{file};
    
    my $seqin = Bio::SeqIO->new( -file => $file, -format => 'GenBank' )
        or die 'failed to create Bio::SeqIO object';
    my $seq = $seqin->next_seq;

    for my $action ( @{ $t->{actions} } ) {
        my $test_name = $t->{name} . ' apply ' . $action->{ssr};
        ok my $modified_seq = $SUBS{ $action->{ssr} }->($seq), $test_name;
        is $modified_seq->length, $action->{length}, $test_name . ', return seq length is correct';
    }
}

done_testing();

sub apply_flp_cre{
    my $seq = shift;

    my $applied_flp_seq = apply_flp( $seq );

    return apply_cre( $applied_flp_seq );
}
