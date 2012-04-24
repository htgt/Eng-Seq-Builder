package EngSeqBuilder::Types;
{
  $EngSeqBuilder::Types::VERSION = '0.003';
}
use warnings FATAL => 'all';
use strict;

use MooseX::Types -declare => [
    qw(
        VectorStage
        Strand
        )
];

use MooseX::Types::Moose qw( Str Int );

subtype VectorStage,
    as Str,
    where { $_ eq 'intermediate' or $_ eq 'final' },
    message {"The vector stage you provided, $_, is invalid, must be either 'final' or 'intermediate'"};

subtype Strand,
    as Int,
    where { $_ eq 1 or $_ eq -1 },
    message {"The strand you provided, $_, is invalid; strand must be either +1 or -1"};

1;
