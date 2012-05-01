package EngSeqBuilder::CLI::Command::CreateCompoundSeq;

use Moose;
use EngSeqBuilder::Exception;
use namespace::autoclean;

extends 'EngSeqBuilder::CLI::Command';

override abstract => sub {"Create a compound sequence from the listed components"};

has [ qw( name type ) ] => (
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

has primary_tag => (
    is       => 'ro',
    isa      => 'Str',
    traits   => [ 'Getopt' ],
    cmd_flag => 'primary-tag'
);

has tags => (
    is       => 'ro',
    isa      => 'HashRef',
    traits   => [ 'Getopt' ],
    default  => sub { {} },
    cmd_flag => 'tag'
);

sub execute {
    my ( $self, $opts, $args ) = @_;

    EngSeqBuilder::Exception->throw( "No components specified" )
        unless @{ $args };

    my %params = (
        name        => $self->name,
        type        => $self->type,
        description => $self->description,
        components  => $args
    );

    if ( $self->primary_tag ) {
        my $feature = Bio::SeqFeature::Generic->new(
            -primary_tag => $self->primary_tag,
            -tag         => $self->tags
        );
        $params{ whole_seq_feature } = $feature;
    }

    $self->eng_seq_builder->txn_do(
        sub {
            $self->eng_seq_builder->create_compound_seq( %params );
            $self->eng_seq_builder->txn_rollback unless $self->commit;
        }
    );

    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
