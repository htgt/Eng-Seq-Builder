package EngSeqBuilder::CLI::Command::LoadCassette;

use Moose;
use Bio::SeqIO;
use Bio::SeqFeature::Generic;
use Bio::SeqUtils;
use EngSeqBuilder::Exception;
use EngSeqBuilder::Util qw( get_gateway_boundary is_exact_feature );
use MooseX::Types::Path::Class;
use namespace::autoclean;

extends 'EngSeqBuilder::CLI::Command';

override abstract => sub {"Load a cassette file into the database"};

has name => (
    is       => 'ro',
    isa      => 'Str',
    traits   => [ 'Getopt' ],
    required => 1
);

has stage => (
    is       => 'ro',
    isa      => 'Str',
    traits   => [ 'Getopt' ],
    required => 1,
);

has description => (
    is      => 'ro',
    isa     => 'Str',
    traits  => [ 'Getopt' ],
    default => ''
);

has append => (
    is      => 'ro',
    isa     => 'Str',
    traits  => [ 'Getopt' ],
    default => 'Standard',
);

has genbank_file => (
    is       => 'ro',
    isa      => 'Path::Class::File',
    traits   => [ 'Getopt' ],
    coerce   => 1,
    required => 1
);

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $seq_io = Bio::SeqIO->new( -fh => $self->genbank_file->openr, -format => 'genbank' );
    my $seq = $seq_io->next_seq;

    $self->eng_seq_builder->txn_do(
        sub {
            $self->create_cassette_seq( $seq );
            $self->eng_seq_builder->txn_rollback unless $self->commit;
        }
    );

    return;
}

sub create_cassette_seq {
    my ( $self, $seq ) = @_;

    my ( $R1_or_B1, $R2_or_B2 );
    if ( $self->stage eq 'final' ) {
        ( $R1_or_B1, $R2_or_B2 ) = ( 'B1', 'B2' );
    }
    elsif ( $self->stage eq 'intermediate' ) {
        ( $R1_or_B1, $R2_or_B2 ) = ( 'R1', 'R2' );
    }
    else {
        EngSeqBuilder::Exception->throw( 'Invalid vector stage: ' . $self->stage );
    }

    my $cassette_without_gateway = $self->_get_cassette_without_gateway( $seq );

    my $cassette_name = $self->name . '_without_gateway';

    $self->eng_seq_builder->create_simple_seq(
        name        => $cassette_name,
        type        => 'cassette',
        seq         => $cassette_without_gateway->seq,
        features    => [ grep { is_exact_feature( $_ ) } $cassette_without_gateway->get_SeqFeatures ],
        description => $self->description,
    );
    my $whole_seq_feature
        = Bio::SeqFeature::Generic->new( -primary => 'misc_feature', tag => { note => 'Synthetic Cassette' } );

    $self->eng_seq_builder->create_compound_seq(
        name => $self->name,
        type => $self->stage . '-cassette',
        components =>
            [ $self->append . '_B1_append', $R1_or_B1, $cassette_name, $R2_or_B2, $self->append . '_B2_append' ],
        whole_seq_feature => $whole_seq_feature,
    );

    return;
}

sub _get_cassette_without_gateway {
    my ( $self, $seq ) = @_;

    my $conf = $self->eng_seq_builder->config->gateway_boundaries_for( 'cassette', $self->stage );

    my ( $fivep_start,  $fivep_length )  = get_gateway_boundary( $seq, $conf->{ fivep } );
    my ( $threep_start, $threep_length ) = get_gateway_boundary( $seq, $conf->{ threep } );

    return Bio::SeqUtils->trunc_with_features( $seq, $fivep_start + $fivep_length + 1, $threep_start );
}

__PACKAGE__->meta->make_immutable;

1;

__END__
