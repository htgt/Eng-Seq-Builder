package EngSeqBuilder::Util;

use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => { exports => [ qw( is_exact_feature get_gateway_boundary clone_bio_seq ) ] };

use Bio::Seq;
use EngSeqBuilder::Exception;

sub is_exact_feature {
    my $feature = shift;

    my $location = $feature->location;

    return
           defined $location->start_pos_type
        && $location->start_pos_type eq 'EXACT'
        && defined $location->end_pos_type
        && $location->end_pos_type eq 'EXACT';
}

sub _get_gateway_pos_and_length {
    my ( $target, $gateway_seq ) = @_;

    my @start_index;
    my $pos = -1;
    while ( ( $pos = index( $target->seq, $gateway_seq, $pos ) ) > -1 ) {
        push @start_index, $pos;
        $pos++;
    }

    if ( @start_index == 0 ) {
        return;
    }
    elsif ( @start_index > 1 ) {
        EngSeqBuilder::Exception->throw(
            'Found multiple instances of gateway boundary in sequence ' . $target->display_id );
    }

    # XXX Can we use $gateway->length instead of length($gateway->seq)?
    # Saj say's he's noticed contradictory results from Bio::Seq.
    return ( shift @start_index, length( $gateway_seq ) );
}

## no critic(RequireFinalReturn)
sub get_gateway_boundary {
    my ( $seq, $boundary_seqs ) = @_;

    for my $boundary ( @{ $boundary_seqs } ) {
        $boundary =~ s/\s+//g;
        if ( my ( $start, $length ) = _get_gateway_pos_and_length( $seq, uc $boundary ) ) {
            return ( $start, $length );
        }
    }

    EngSeqBuilder::Exception->throw( "Failed to locate gateway boundary in " . $seq->display_id );
}
## use critic

sub clone_bio_seq {
    my $seq = shift;

    EngSeqBuilder::Exception->throw( 'Object [$seq] ' . 'of class [' . ref( $seq ) . '] should be a Bio::PrimarySeqI ' )
        unless $seq->isa( 'Bio::PrimarySeqI' );

    my $cloned_seq = Bio::Seq->new(
        -alphabet    => $seq->alphabet,
        -display_id  => $seq->display_id,
        -is_circular => $seq->is_circular,
        -seq         => $seq->seq
    );

    # move Annotations
    if ( $seq->isa( "Bio::AnnotatableI" ) ) {
        foreach my $key ( $seq->annotation->get_all_annotation_keys() ) {
            foreach my $value ( $seq->annotation->get_Annotations( $key ) ) {
                $cloned_seq->annotation->add_Annotation( $key, $value );
            }
        }
    }

    # move SeqFeatures
    if ( $seq->isa( 'Bio::SeqI' ) ) {
        for my $feat ( $seq->get_SeqFeatures ) {
            $cloned_seq->add_SeqFeature( $feat );
        }
    }

    return $cloned_seq;
}

1;

__END__

