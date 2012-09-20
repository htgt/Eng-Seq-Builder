package EngSeqBuilder::Genbank;

use strict;
use warnings;

use Moose::Role;
use Moose::Util::TypeConstraints;

requires qw(get_design get_design_projects);

use HTGT::DBFactory;
use EngSeqBuilder;
use Bio::SeqIO;
use HTGT::Utils::DesignFinder::Gene;
use Try::Tiny;
use Scalar::Util qw(openhandle);

has cassette => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has backbone => (
    is       => 'ro',
    isa      => 'Str',
    required => 0,
);

has design_id => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has config => (
    is       => 'ro',
    isa      => 'Str',
    required => 0,
);

has targeted_trap => (
    is       => 'ro',
    isa      => 'Bool',
    required => 0,
);

has type => (
    is       => 'ro',
    isa      => enum([qw[ vector allele ]]),
    required => 1,
);

has filehandle => (
    is       => 'ro',
    required => 0,
    default  => sub{ \*STDOUT },
);

has _get_seq_method => (
	is       => 'rw',
	isa      => 'Str',
	required => 0,
);

sub BUILD{
	my $self = shift;

	if ($self->type eq 'vector'){
		$self->_get_seq_method('get_vector_seq');
	}
	elsif ($self->type eq 'allele'){
		$self->_get_seq_method('get_allele_seq');
	}
	else{
		# This should never happen
		die ("Error: no get_seq method available for ".$self->type);
	}

	unless (openhandle($self->filehandle)){
		die("filehandle attribute ".$self->filehandle." is not an open filehandle");
	}
}

sub write_genbank{
	my $self = shift;

	my $design = $self->get_design( $self->design_id );

    my $eng_seq_builder = $self->config ? EngSeqBuilder->new( {configfile => $self->config} )
                                        : EngSeqBuilder->new;

    my $get_seq = $self->_get_seq_method;
    my $seq = $self->$get_seq( $eng_seq_builder, $design );

    my $seq_io = Bio::SeqIO->new( -fh => $self->filehandle, -format => 'genbank' );
    $seq_io->write_seq( $seq );

    return;
}

sub get_vector_seq {
    my ( $self, $eng_seq_builder, $design ) = @_;

    die "--backbone must be specified\n" unless defined $self->backbone;

    my %params = (
        $self->get_design_params( { design => $design, backbone => $self->backbone } ),
    );

    my $design_type = delete $params{design_type};

    my $cassette = {name => $self->cassette};
    my $backbone = {name => $self->backbone};

    if ( $design_type =~ /^KO/ ) {
        $params{u_insertion} = $cassette;
        $params{d_insertion} = { name => 'LoxP' };
        $params{backbone}    = $backbone;
        return $eng_seq_builder->conditional_vector_seq(%params);
    }

    if ( $design_type =~ /^Ins/ ) {
        $params{insertion} = $cassette;
        $params{backbone}  = $backbone;
        return $eng_seq_builder->insertion_vector_seq(%params);
    }

    if ( $design_type =~ /^Del/ ) {
        $params{insertion} = $cassette;
        $params{backbone}  = $backbone;
        return $eng_seq_builder->deletion_vector_seq(%params);
    }

    die("Unknown design type $design_type");
}

sub get_allele_seq {
    my ( $self, $eng_seq_builder, $design ) = @_;

    my %params = (
        $self->get_design_params( { design => $design, targeted_trap => $self->targeted_trap } ),
    );

    my $design_type   = delete $params{design_type};

    my $targeted_trap = $self->targeted_trap ? 1 : 0;
    my $cassette = {name => $self->cassette};

    if ($targeted_trap) {
        $params{u_insertion} = $cassette;
        delete $params{loxp_start};
        delete $params{loxp_end};
        return $eng_seq_builder->targeted_trap_allele_seq(%params);
    }

    if ( $design_type =~ /^KO/ ) {
        $params{u_insertion} = $cassette;
        $params{d_insertion} = { name => 'LoxP' };
        return $eng_seq_builder->conditional_allele_seq(%params);
    }

    if ( $design_type =~ /^Ins/ ) {
        $params{insertion} = $cassette;
        return $eng_seq_builder->insertion_allele_seq(%params);
    }

    if ( $design_type =~ /^Del/ ) {
        $params{insertion} = $cassette;
        return $eng_seq_builder->deletion_allele_seq(%params);
    }

    die("Unknown design type $design_type");
}

sub get_design_params {
    my ($self, $args) = @_;

    my $design_info = $args->{design}->info;

    my @params = (
        chromosome  => $design_info->chr_name,
        strand      => $design_info->chr_strand,
        transcript  => $design_info->target_transcript->stable_id,
        design_type => $design_info->type,
        design_id   => $self->design_id,
        map { $_ => $design_info->$_ }
            qw( five_arm_start five_arm_end three_arm_start three_arm_end ),
    );

    my $mutation_type = _get_mutation_type( $design_info->type, $args->{targeted_trap} );
    my $mgi_gene = $design_info->mgi_gene;
    my $project_ids = $self->get_design_projects( $args );

    push @params, ( display_id => _create_display_id( $mutation_type, $project_ids, $mgi_gene->mgi_accession_id ) );
    push @params, ( description => _create_seq_description( $mutation_type, $project_ids, $mgi_gene->marker_symbol, $args->{backbone} ) );

    return @params if $design_info->type =~ /^Del/ || $design_info->type =~ /^Ins/;
    push @params, map { $_ => $design_info->$_ } qw( target_region_start target_region_end );
    push @params, map { $_ => $design_info->$_ } qw( loxp_start loxp_end ) if $args->{targeted_trap};

    return @params;
}

sub _get_mutation_type {
    my ( $design_type, $targeted_trap ) = @_;
    my $mutation_type;

    $mutation_type
        = $design_type =~ /^Del/                   ? 'deletion'
        : $design_type =~ /^KO/ && $targeted_trap  ? 'non-conditional'
        : $design_type =~ /^KO/ && !$targeted_trap ? 'KO-first, conditional ready'
        :                                             undef;

    unless ($mutation_type) {
        die 'Mutation type could not be set for design_type: ' . $design_type;
    }

    return $mutation_type;
}

sub _create_display_id {
    my ( $mutation_type, $project_ids, $mgi_accession_id ) = @_;

    my $formated_mutation_type = $mutation_type =~ 'KO-first' ? 'KO-first_condition_ready' : $mutation_type;
    return  $formated_mutation_type . '_' . $project_ids . '_' . $mgi_accession_id;
}

sub _create_seq_description {
    my ( $mutation_type, $project_ids, $marker_symbol, $backbone ) = @_;

    my $seq_description = 'Mus musculus targeted ';
    $seq_description .= $mutation_type . ', lacZ-tagged mutant';
    $seq_description .= $backbone ? 'vector' : 'allele';
    $seq_description .= $marker_symbol;
    $seq_description .= ' targeting project(s): ' . $project_ids;

    return $seq_description;
}

1;

__END__
