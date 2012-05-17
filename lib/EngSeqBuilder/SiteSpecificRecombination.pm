package EngSeqBuilder::SiteSpecificRecombination;

use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => { exports => [ qw( apply_recombinase apply_cre apply_flp apply_dre) ] };

use Bio::Seq;
use Bio::SeqUtils;
use Bio::Range;
use Const::Fast;
use EngSeqBuilder::Util qw( is_exact_feature clone_bio_seq );
use Log::Log4perl qw( :easy );
use Carp qw( confess );

const my %SSR_TARGET_SEQS => (
    LOXP => 'ATAACTTCGTATAGCATACATTATACGAAGTTAT',
    FRT  => 'GAAGTTCCTATTCCGAAGTTCCTATTCTCTAGAAAGTATAGGAACTTC',
    ROX  => 'TAACTTTAAATAATTGGCATTATTTAAAGTTA'
);

const my @ANNOTATIONS => ( 'display_id', 'species', 'desc', 'is_circular', );

sub apply_recombinase {
    my ( $seq, $recombinase ) = @_;

    if ( $recombinase eq 'cre' ) {
        return apply_cre( $seq );
    }

    if ( $recombinase eq 'dre' ) {
        return apply_dre( $seq );
    }

    if ( $recombinase eq 'flp' ) {
        return apply_flp( $seq );
    }

    confess "Unrecognized recombinase: '$recombinase'";
}

sub apply_cre {
    my $seq = shift;

    DEBUG( 'apply_cre' );

    return apply_specified_recombinase( $seq, 'LOXP' );
}

sub apply_dre {
    my $seq = shift;

    DEBUG( 'apply_dre' );

    return apply_specified_recombinase( $seq, 'ROX' );
}

sub apply_flp {
    my $seq = shift;

    DEBUG( 'apply_flp' );

    return apply_specified_recombinase( $seq, 'FRT' );
}

sub apply_specified_recombinase{
    my ( $seq, $target ) = @_;

    my $site = _find_ssr_target( $seq, $target);

    my $modified_seq = _recombinate_sequence( $site, $seq );

    return _clean_sequence( $modified_seq, $seq );
}

sub _clean_sequence {
    my ( $modified_seq, $seq ) = @_;

    #add back annotation
    for my $annotation ( @ANNOTATIONS ) {
        $modified_seq->$annotation( $seq->$annotation )
            if $seq->$annotation;
    }

    #comments have been duplicated, replace with original comments
    $modified_seq->annotation->remove_Annotations( 'comment' );

    for my $annotation ( $seq->annotation->get_Annotations( 'comment' ) ) {
        $modified_seq->annotation->add_Annotation( 'comment', $annotation );
    }

    return $modified_seq;
}

sub _recombinate_sequence {
    my ( $ssr_sites, $seq ) = @_;

    # Clone the Bio::Seq object as we're about to mutate it and want
    # to leave the original untouched
    $seq = clone_bio_seq( $seq );

    if ( @{ $ssr_sites } < 2 ) {
        WARN "Not applying recombinase: fewer than 2 site-specific recombination sites found in " . $seq->display_id;
        return $seq;
    }

    my $modified_seq = Bio::Seq->new( -alphabet => 'dna', );

    my $first_site = $ssr_sites->[ 0 ];
    my $last_site  = $ssr_sites->[ -1 ];

    # Remove inexact features as features missing a start or end cause
    # a blow-up in trunc_with_features()
    my @features = grep { is_exact_feature( $_ ) } $seq->get_SeqFeatures;
    $seq->remove_SeqFeatures;
    $seq->add_SeqFeature( @features );

    Bio::SeqUtils->cat(
        $modified_seq,
        Bio::SeqUtils->trunc_with_features( $seq, 1, $first_site->start - 1 ),
        Bio::SeqUtils->trunc_with_features( $seq, $last_site->start, $seq->length )
    );

    return $modified_seq;
}

sub _find_ssr_target {
    my ( $seq, $target ) = @_;
    my @target_sites;

    EngSeqBuilder::Exception->throw( "Unexpected target ssr sequence: $target" )
        unless exists $SSR_TARGET_SEQS{ $target };

    my $target_sequence = $SSR_TARGET_SEQS{ $target };
    my $target_length   = length( $target_sequence );

    my $result = index( $seq->seq, $target_sequence );
    my $offset = 0;
    while ( $result != -1 ) {
        my $site = Bio::Range->new(
            -start => $result + 1,
            -end   => $result + $target_length
        );
        push @target_sites, $site;

        $offset = $result + 1;
        $result = index( $seq->seq, $target_sequence, $offset );
    }

    if ( @target_sites == 1 ) {
        WARN "Only one $target site found in given sequence, can not carry out recombination";
    }
    elsif ( @target_sites == 0 ) {
        WARN "No $target sites found in sequence";
    }

    return \@target_sites;
}

1;
