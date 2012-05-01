package EngSeqBuilder::CLI::Command::AddFeature;

use Moose;
use Bio::SeqIO;
use namespace::autoclean;
use Bio::SeqFeatureI;
use Data::Dump qw( pp );

extends 'EngSeqBuilder::CLI::Command';

override abstract => sub {'Add a new feature to a sequence in the database'};

has name => (
    is       => 'ro',
    isa      => 'Str',
    traits   => [ 'Getopt' ],
    required => 1
);

has type => (
    is     => 'ro',
    isa    => 'Str',
    traits => [ 'Getopt' ],
);

has start => (
    is         => 'ro',
    isa        => 'Int',
    traits     => [ 'Getopt' ],
    lazy_build => 1
);

has end => (
    is         => 'ro',
    isa        => 'Int',
    traits     => [ 'Getopt' ],
    lazy_build => 1
);

has primary_tag => (
    is       => 'ro',
    isa      => 'Str',
    traits   => [ 'Getopt' ],
    required => 1,
    cmd_flag => 'primary-tag'
);

has tags => (
    is       => 'ro',
    isa      => 'HashRef',
    traits   => [ 'Getopt' ],
    default  => sub { {} },
    cmd_flag => 'tag'
);

has strand => (
    is      => 'ro',
    isa     => 'Int',
    traits  => [ 'Getopt' ],
    default => 1,
);

has whole_seq_feature => (
    is       => 'ro',
    isa      => 'Bool',
    default  => 0,
    traits   => [ 'Getopt' ],
    cmd_flag => 'whole-seq-feature'
);

has seq => (
    is         => 'ro',
    isa        => 'EngSeqBuilder::Schema::Result::EngSeq',
    init_arg   => undef,
    lazy_build => 1
);

sub _build_start {
    my $self = shift;

    if ( $self->whole_seq_feature ) {
        return 1;
    }

    confess "--start or --whole-seq-feature must be specified";
}

sub _build_end {
    my $self = shift;

    if ( $self->whole_seq_feature ) {
        return $self->seq->length;
    }

    confess "--end or --whole-seq-feature must be specified";
}

sub _build_seq {
    my $self = shift;

    if ( $self->type ) {
        return $self->eng_seq_builder->_fetch_seq( $self->name, $self->type ); ## no critic(ProtectPrivateSubs)
    }
    else {
        return $self->eng_seq_builder->_fetch_seq( $self->name ); ## no critic(ProtectPrivateSubs)
    }
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $feature = Bio::SeqFeature::Generic->new(
        -start   => $self->start,
        -end     => $self->end,
        -primary => $self->primary_tag,
        -strand  => $self->strand,
        -tag     => $self->tags,
    );
    $self->log->info( 'Adding ' . $self->primary_tag . ' with tags ' . pp( $self->tags ) );
    $self->eng_seq_builder->txn_do(
        sub {
            $self->seq->add_features( [ $feature ] );
            $self->eng_seq_builder->txn_rollback unless $self->commit;
        }
    );

    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
