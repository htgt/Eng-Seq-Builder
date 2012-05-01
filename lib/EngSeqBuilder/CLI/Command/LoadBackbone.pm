package EngSeqBuilder::CLI::Command::LoadBackbone;

use Moose;
use Bio::SeqIO;
use Bio::SeqFeature::Generic;
use Bio::SeqUtils;
use EngSeqBuilder::Exception;
use EngSeqBuilder::Util qw( get_gateway_boundary is_exact_feature );
use MooseX::Types::Path::Class;
use namespace::autoclean;

extends 'EngSeqBuilder::CLI::Command';

override abstract => sub {"Load a backbone file into the database"};

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
            $self->create_backbone_seq( $seq );
            $self->eng_seq_builder->txn_rollback unless $self->commit;
        }
    );

    return;
}

sub create_backbone_seq {
    my ( $self, $seq ) = @_;

    my ( $R3_or_B3, $R4_or_B4 );
    if ( $self->stage eq 'intermediate' ) {
        ( $R3_or_B3, $R4_or_B4 ) = ( 'R3', 'R4' );
    }
    elsif ( $self->stage eq 'final' ) {
        ( $R3_or_B3, $R4_or_B4 ) = ( 'B3', 'B4' );
    }
    else {
        EngSeqBuilder::Exception->throw( 'Invalid vector stage: ' . $self->stage );
    }

    my $backbone_without_gateway = $self->_get_backbone_without_gateway( $seq );

    my $backbone_name = $self->name . '_without_gateway';

    $self->eng_seq_builder->create_simple_seq(
        name        => $backbone_name,
        type        => 'backbone',
        seq         => $backbone_without_gateway->seq,
        features    => [ grep { is_exact_feature( $_ ) } $backbone_without_gateway->get_SeqFeatures ],
        description => $self->description
    );

    my $whole_seq_feature
        = Bio::SeqFeature::Generic->new( -primary => 'misc_feature', tag => { note => 'Synthetic Backbone' } );
    $self->eng_seq_builder->create_compound_seq(
        name              => $self->name,
        type              => $self->stage . '-backbone',
        components        => [ 'Standard_B4_append', $R4_or_B4, $backbone_name, $R3_or_B3, 'Standard_B3_append' ],
        whole_seq_feature => $whole_seq_feature,
    );

    return;
}

sub _get_backbone_without_gateway {
    my ( $self, $seq ) = @_;

    my $conf = $self->eng_seq_builder->config->gateway_boundaries_for( 'backbone', $self->stage );

    my ( $fivep_start,  $fivep_length )  = get_gateway_boundary( $seq, $conf->{ fivep } );
    my ( $threep_start, $threep_length ) = get_gateway_boundary( $seq, $conf->{ threep } );

    my $backbone;

    if ( $fivep_start < $threep_start ) {
        $backbone = Bio::SeqUtils->trunc_with_features( $seq, $fivep_start + $fivep_length + 1, $threep_start );
    }
    else {
        $backbone = Bio::SeqUtils->trunc_with_features( $seq, $fivep_start + $fivep_length + 1, $seq->length );
        my $append_component = Bio::SeqUtils->trunc_with_features( $seq, 1, $threep_start );
        Bio::SeqUtils->cat( $backbone, $append_component );
    }

    return $backbone;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
