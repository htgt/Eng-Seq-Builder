package EngSeqBuilder::Rfetch;

use Moose::Role;
use EngSeqBuilder::Exception;
use EngSeqBuilder::Rfetch::EnsEMBL;
use Hash::MoreUtils qw( slice_def );
use namespace::autoclean;

requires qw( config );

has _cached_rfetch_helpers => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { +{} }
);

sub _rfetch_helper {
    my ( $self, $species, $version ) = @_;

    return $self->_cached_rfetch_helpers->{ $species }->{ $version } ||= EngSeqBuilder::Rfetch::EnsEMBL->new(
        species => $species,
        version => $version,
        config  => $self->config
    );

}

sub rfetch_seq {
    my ( $self, %params ) = @_;

    my $seq = $self->_rfetch_helper( @params{ 'species', 'version' } )->fetch_seq(
        slice_def \%params, qw( seq_region_name seq_region_start seq_region_end seq_region_strand
            include_transcript targeted )
    );

    if ( my $f = $params{ whole_feature_name } ) {
        confess( 'whole_feature_name param sent to rfetch_seq is not a Bio::SeqFeatureI object' )
            unless $f->isa( 'Bio::SeqFeatureI' );
        $f->start( 1 );
        $f->end( length( $seq->seq ) );

        confess( 'Unable to add whole_seq_feature to rfetch_seq' )
            unless $seq->add_SeqFeature( $f );
    }
    return $seq;
}

1;

__END__
