package EngSeqBuilder::CLI::Command::LoadSimpleSeq;

use Moose;
use Bio::SeqIO;
use EngSeqBuilder::Util qw( is_exact_feature );
use namespace::autoclean;

extends 'EngSeqBuilder::CLI::Command';

override abstract => sub {'Load a simple sequence and its features into the database'};

has name => (
    is       => 'ro',
    isa      => 'Str',
    traits   => [ 'Getopt' ],
    required => 1
);

has type => (
    is       => 'ro',
    isa      => 'Str',
    traits   => [ 'Getopt' ],
    required => 1
);

has description => (
    is      => 'ro',
    isa     => 'Str',
    traits  => [ 'Getopt' ],
    default => ''
);

has format => (
    is      => 'ro',
    isa     => 'Str',
    traits  => [ 'Getopt' ],
    default => 'genbank'
);

has include_inexact => (
    is      => 'ro',
    isa     => 'Bool',
    traits  => [ 'Getopt' ],
    default => 0
);

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $seq_io;
    if ( @{ $args } ) {
        $seq_io = Bio::SeqIO->new( -file => $args->[ 0 ], -format => $self->format );
    }
    else {
        $seq_io = Bio::SeqIO->new( -fh => \*STDIN, -format => $self->format );
    }

    my $seq = $seq_io->next_seq;

    $self->eng_seq_builder->txn_do(
        sub {
            $self->eng_seq_builder->create_simple_seq(
                name        => $self->name,
                description => $self->description,
                type        => $self->type,
                seq         => $seq->seq,
                features    => $self->_get_features( $seq ),
            );
            $self->eng_seq_builder->txn_rollback unless $self->commit;
        }
    );

    return;
}

sub _get_features {
    my ( $self, $seq ) = @_;

    my @features;

    if ( $self->include_inexact ) {
        @features = $seq->get_SeqFeatures;
    }
    else {
        @features = grep { is_exact_feature( $_ ) } $seq->get_SeqFeatures;
    }

    return \@features;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
