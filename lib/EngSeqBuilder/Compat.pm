package EngSeqBuilder::Compat;

use strict;
use warnings FATAL => 'all';

use Moose;
use Data::Dump 'pp';
use namespace::autoclean;

extends 'EngSeqBuilder';

## no critic(RequireFinalReturn)
sub vector_seq {
    my ( $self, %params ) = @_;

    $self->log->trace( sub { 'vector_seq: ' . pp( \%params ) } );

    my $design_type = delete $params{design_type};

    my $cassette = { name => delete $params{cassette} };
    my $backbone = { name => delete $params{backbone} };

    $self->_convert_recombinase_params( \%params );

    if ( $design_type =~ /^KO/ ) {
        $params{u_insertion} = $cassette;
        $params{d_insertion} = { name => 'LoxP' };
        $params{backbone}    = $backbone;
        return $self->conditional_vector_seq(%params);
    }

    if ( $design_type =~ /^Ins/ ) {
        $params{insertion} = $cassette;
        $params{backbone}  = $backbone;
        return $self->insertion_vector_seq(%params);
    }

    if ( $design_type =~ /^Del/ ) {
        $params{insertion} = $cassette;
        $params{backbone}  = $backbone;
        return $self->deletion_vector_seq(%params);
    }

    EngSeqBuilder::Exception->throw("Unknown design type $design_type");
}
## use critic

## no critic(RequireFinalReturn)
sub allele_seq {
    my ( $self, %params ) = @_;

    $self->log->trace( sub { 'allele_seq: ' . pp( \%params ) } );

    my $design_type   = delete $params{design_type};
    my $targeted_trap = delete $params{targeted_trap};

    my $cassette = { name => delete $params{cassette} };

    $self->_convert_recombinase_params;

    if ($targeted_trap) {
        $params{u_insertion} = $cassette;
        delete $params{loxp_start};
        delete $params{loxp_end};
        return $self->targeted_trap_allele_seq(%params);
    }

    if ( $design_type =~ /^KO/ ) {
        $params{u_insertion} = $cassette;
        $params{d_insertion} = { name => 'LoxP' };
        return $self->conditional_allele_seq(%params);
    }

    if ( $design_type =~ /^Ins/ ) {
        $params{insertion} = $cassette;
        return $self->insertion_allele_seq(%params);
    }

    if ( $design_type =~ /^Del/ ) {
        $params{insertion} = $cassette;
        return $self->deletion_allele_seq(%params);
    }

    EngSeqBuilder::Exception->throw("Unknown design type $design_type");
}
## use critic

sub _convert_recombinase_params {
    my ( $self, $params ) = @_;

    my @recombinase;
    if ( delete $params->{apply_flp} ) {
        push @recombinase, 'flp';
    }
    elsif ( delete $params->{apply_cre} ) {
        push @recombinase, 'cre';
    }
    elsif ( delete $params->{apply_flp_cre} ) {
        push @recombinase, 'flp', 'cre';
    }

    if (@recombinase) {
        $params->{recombinase} = \@recombinase;
    }

    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
