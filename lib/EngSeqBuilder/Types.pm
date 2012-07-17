package EngSeqBuilder::Types;
use warnings FATAL => 'all';
use strict;

use MooseX::Types -declare => [
    qw(
          VectorStage
          Species
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
    where { $_ == 1 or $_ == -1 },
    message {"The strand you provided, $_, is invalid; strand must be either +1 or -1"};

subtype Species,
    as Str,
    where { $_ =~ m/^(human|mouse)$/i },
    message { "The species you provided, $_, is invalid; species should be either 'human' or 'mouse'" };

1;
