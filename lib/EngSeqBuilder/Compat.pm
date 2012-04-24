package EngSeqBuilder::Compat;

use strict;
use warnings FATAL => 'all';

use Moose;
use Data::Dump 'pp';
use namespace::autoclean;

extends 'EngSeqBuilder';

sub vector_seq {
    my ( $self, %params ) = @_;

    $self->log->trace( sub { 'vector_seq: ' . pp( \%params ) } );

    my $design_type = delete $params{ design_type };

    my $cassette = { name => delete $params{ cassette } };
    my $backbone = { name => delete $params{ backbone } };

    $self->_convert_recombinase_params( \%params );

    if ( $design_type =~ /^KO/ ) {
        $params{ u_insertion } = $cassette;
        $params{ d_insertion } = { name => 'LoxP' };
        $params{ backbone }    = $backbone;
        $self->conditional_vector_seq( %params );
    }
    elsif ( $design_type =~ /^Ins/ ) {
        $params{ insertion } = $cassette;
        $params{ backbone }  = $backbone;
        $self->insertion_vector_seq( %params );
    }
    elsif ( $design_type =~ /^Del/ ) {
        $params{ insertion } = $cassette;
        $params{ backbone }  = $backbone;
        return $self->deletion_vector_seq( %params );
    }
    else {
        EngSeqBuilder::Exception->throw( "Unknown design type $design_type" );
    }
}

sub allele_seq {
    my ( $self, %params ) = @_;

    $self->log->trace( sub { 'allele_seq: ' . pp( \%params ) } );

    my $design_type   = delete $params{ design_type };
    my $targeted_trap = delete $params{ targeted_trap };

    my $cassette = { name => delete $params{ cassette } };

    $self->_convert_recombinase_params;

    if ( $targeted_trap ) {
        $params{ u_insertion } = $cassette;
        delete $params{ loxp_start };
        delete $params{ loxp_end };
        $self->targeted_trap_allele_seq( %params );
    }
    elsif ( $design_type =~ /^KO/ ) {
        $params{ u_insertion } = $cassette;
        $params{ d_insertion } = { name => 'LoxP' };
        $self->conditional_allele_seq( %params );
    }
    elsif ( $design_type =~ /^Ins/ ) {
        $params{ insertion } = $cassette;
        $self->insertion_allele_seq( %params );
    }
    elsif ( $design_type =~ /^Del/ ) {
        $params{ insertion } = $cassette;
        $self->deletion_allele_seq( %params );
    }
    else {
        EngSeqBuilder::Exception->throw( "Unknown design type $design_type" );
    }
}

sub _convert_recombinase_params {
    my ( $self, $params ) = @_;

    my @recombinase;
    if ( delete $params->{ apply_flp } ) {
        push @recombinase, 'flp';
    }
    elsif ( delete $params->{ apply_cre } ) {
        push @recombinase, 'cre';
    }
    elsif ( delete $params->{ apply_flp_cre } ) {
        push @recombinase, 'flp', 'cre';
    }

    if ( @recombinase ) {
        $params->{ recombinase } = \@recombinase;
    }
}

__PACKAGE__->meta->make_immutable;

1;

__END__
