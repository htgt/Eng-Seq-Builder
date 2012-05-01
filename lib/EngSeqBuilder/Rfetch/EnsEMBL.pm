package EngSeqBuilder::Rfetch::EnsEMBL;

use Moose;
use MooseX::Params::Validate;
use Bio::Seq;
use Bio::SeqFeature::Gene::Exon;
use EngSeqBuilder::Exception;
use namespace::autoclean;

has config => (
    is       => 'ro',
    isa      => 'EngSeqBuilder::Config',
    required => 1,
    handles  => [ 'ensembl_registry' ]
);

has species => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has version => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has slice_adaptor => (
    is         => 'ro',
    isa        => 'Bio::EnsEMBL::DBSQL::SliceAdaptor',
    init_arg   => undef,
    lazy_build => 1
);

sub _build_slice_adaptor {
    my $self = shift;

    return $self->ensembl_registry->get_adaptor( $self->species, 'core', 'slice' );
}

has transcript_adaptor => (
    is         => 'ro',
    isa        => 'Bio::EnsEMBL::DBSQL::TranscriptAdaptor',
    init_arg   => undef,
    lazy_build => 1
);

sub _build_transcript_adaptor {
    my $self = shift;
    return $self->ensembl_registry->get_adaptor( $self->species, 'core', 'transcript' );
}

sub fetch_seq {
    my ( $self, @args ) = @_;

    my %params = validated_hash(
        \@args,
        seq_region_name    => { isa => 'Str' },
        seq_region_start   => { isa => 'Int' },
        seq_region_end     => { isa => 'Int' },
        seq_region_strand  => { isa => 'Int' },
        include_transcript => { isa => 'Str', optional => 1 },
        targeted           => { isa => 'Bool', optional => 1 }
    );

    # EnsEMBL expects start <= end
    if ( $params{ seq_region_start } > $params{ seq_region_end } ) {
        @params{ 'seq_region_start', 'seq_region_end' } = @params{ 'seq_region_end', 'seq_region_start' };
    }

    my $slice
        = $self->slice_adaptor->fetch_by_region( 'chromosome',
        @params{ qw( seq_region_name seq_region_start seq_region_end seq_region_strand ) },
        $self->version );

    my $seq = Bio::Seq->new(
        -alphabet => 'dna',
        -seq      => $slice->seq
    );

    if ( exists $params{ include_transcript } and $params{ include_transcript } ) {
        $self->_annotate_exons( %params, seq => $seq, slice => $slice );
    }

    return $seq;
}

sub _annotate_exons {
    my ( $self, %params ) = @_;

    my ( $seq, $slice, $strand, $transcript_id, $targeted )
        = @params{ qw( seq slice seq_region_strand include_transcript targeted ) };

    my $exons = $self->_exons_on_slice( $slice, $strand, $transcript_id );

    my $exon_count = 0;
    for my $exon ( @{ $exons } ) {
        $exon_count++;
        my $note = $targeted ? "target exon $exon_count " . $exon->stable_id : $exon->stable_id;
        my ( $exon_start, $exon_end ) = ( $exon->start, $exon->end );

        my $fragment_type;
        if ( $exon_end > $slice->length and $exon_start < 1 ) {
            $exon_start    = 1;
            $exon_end      = $slice->length;
            $fragment_type = "central";
        }
        elsif ( $exon_end > $slice->length ) {
            $exon_end      = $slice->length;
            $fragment_type = "5'";
        }
        elsif ( $exon_start < 1 ) {
            $exon_start    = 1;
            $fragment_type = "3'";
        }
        $note .= " $fragment_type fragment" if $fragment_type;

        my $exon_feature = Bio::SeqFeature::Gene::Exon->new(
            -display_name => $exon->stable_id,
            -start        => $exon_start,
            -end          => $exon_end,
            -strand       => $exon->strand,
            -tag          => {
                note    => $note,
                db_xref => 'ENSEMBL:' . $exon->stable_id
            }
        );

        $exon_feature->add_tag_value( 'type', 'targeted' ) if $targeted;
        $seq->add_SeqFeature( $exon_feature );
    }

    return;
}

sub _exons_on_slice {
    my ( $self, $slice, $strand, $transcript_id ) = @_;
    my $exons;

    my $transcript = $self->transcript_adaptor->fetch_by_stable_id( $transcript_id )
        or EngSeqBuilder::Exception->throw( "Failed to retrieve transcript $transcript_id" );
    my %is_wanted = map { $_->stable_id => 1 } @{ $transcript->get_all_Exons };
    $exons = [ grep { $is_wanted{ $_->stable_id } } @{ $slice->get_all_Exons } ];

    return $exons;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
