#!/usr/bin/env perl
#
# $HeadURL$
# $LastChangedRevision$
# $LastChangedDate$
# $LastChangedBy$
#

use strict;
use warnings FATAL => 'all';

use Getopt::Long;
use HTGT::DBFactory;
use EngSeqBuilder::Compat;
use Bio::SeqIO;
use HTGT::Utils::DesignFinder::Gene;
use Try::Tiny;

{

    GetOptions( \my %options, qw( cassette=s backbone=s design=s config=s format=s targeted_trap vector allele ) );

    my $htgt = HTGT::DBFactory->connect( 'eucomm_vector' );

    my $design = get_design( $htgt, $options{design} );

    my $eng_seq_builder = $options{config} ? EngSeqBuilder::Compat->new( configfile => $options{config} )
                                           : EngSeqBuilder::Compat->new;

    my $seq;
    
    if ( $options{vector} ) {
        $seq = get_vector_seq( $eng_seq_builder, $design, $options{cassette}, $options{backbone} );
    }
    elsif ( $options{allele} ) {
        $seq = get_allele_seq( $eng_seq_builder, $design, $options{cassette}, $options{targeted_trap} );        
    }
    else {
        die "One of --vector or --allele must be specified\n";
    }

    my $seq_io = Bio::SeqIO->new( -fh => \*STDOUT, -format => $options{format} || 'genbank' );
    $seq_io->write_seq( $seq );    
}

sub get_vector_seq {
    my ( $eng_seq_builder, $design, $cassette, $backbone ) = @_;

    die "--cassette must be specified\n" unless defined $cassette;
    die "--backbone must be specified\n" unless defined $backbone;

    return $eng_seq_builder->vector_seq(
        get_design_params( { design => $design, cassette => $cassette, backbone => $backbone } ),
        cassette     => $cassette,
        backbone     => $backbone,
    );    
}

sub get_allele_seq {
    my ( $eng_seq_builder, $design, $cassette, $targeted_trap ) = @_;

    die "--cassette must be specified\n" unless defined $cassette;

    return $eng_seq_builder->allele_seq(
        get_design_params( { design => $design, targeted_trap => $targeted_trap, cassette => $cassette } ),
        cassette      => $cassette,
        targeted_trap => $targeted_trap ? 1 : 0,
    );
}

sub get_design_params {
    my $args = shift;

    my $design_info = $args->{design}->info;

    my @params = (
        chromosome  => $design_info->chr_name,
        strand      => $design_info->chr_strand,
        transcript  => $design_info->target_transcript->stable_id,
        design_type => $design_info->type,
        design_id   => $args->{design}->design_id,
        map { $_ => $design_info->$_ }
            qw( five_arm_start five_arm_end three_arm_start three_arm_end ),
    );

    my $mutation_type = _get_mutation_type( $design_info->type, $args->{targeted_trap} );
    my $mgi_gene = $design_info->mgi_gene;
    my $project_ids = _get_design_projects( $args );

    push @params, ( display_id => _create_display_id( $mutation_type, $project_ids, $mgi_gene->mgi_accession_id ) );
    push @params, ( description => _create_seq_description( $mutation_type, $project_ids, $mgi_gene->marker_symbol, $args->{backbone} ) );

    return @params if $design_info->type =~ /^Del/ || $design_info->type =~ /^Ins/;
    push @params, map { $_ => $design_info->$_ } qw( target_region_start target_region_end );
    push @params, map { $_ => $design_info->$_ } qw( loxp_start loxp_end ) if $args->{targeted_trap};

    return @params;
}

sub _get_transcript_id {
    my $ensembl_gene_id = shift;
    return unless $ensembl_gene_id;

    my $gene = HTGT::Utils::DesignFinder::Gene->new( ensembl_gene_id => $ensembl_gene_id );

    my $transcript;
    try {
        $transcript = $gene->template_transcript;
    }
    catch {
        die $_ unless $_ =~ m/Failed to find a template transcript/;        
        $transcript = ( $gene->all_transcripts )[0];
    };
    return $transcript->stable_id; 
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

sub _get_design_projects {
    my $args = shift;
    my $design = $args->{design};
    my @projects;

    if ( $args->{backbone} ){
        @projects = $design->projects->search(
            { cassette => $args->{cassette}, backbone => $args->{backbone} },
            { columns  => [qw/project_id/] } );
    }
    else {
        @projects = $design->projects->search( 
            { cassette => $args->{cassette} }, 
            { columns => [qw/project_id/] } );
    }

    my @project_ids = map { $_->project_id } @projects;

    unless ( scalar(@project_ids) ) {
        my $msg = 'No project found for design: ' . $design->design_id
                . ' with cassette: ' . $args->{cassette};
        $msg .= ' and backbone: ' . $args->{backbone} if $args->{backbone};
        #die $msg;
        return 'None';
    }

    return join ':', @project_ids;
}

sub get_design {
    my ( $htgt, $design_spec ) = @_;

    $design_spec ||= '';
    
    my $design;
    
    if ( $design_spec =~ /^\d+$/ ) {
        $design = $htgt->resultset( 'Design' )->find( { design_id => $design_spec } )
            || die "Failed to retrieve design $design_spec\n";
    }
    elsif ( my ( $plate_name, $well_name ) = $design_spec =~ m/^(\w+)_(\w+)$/ ) {
        my $well = $htgt->resultset( 'Well' )->find(
            {
                'plate.name'   => $plate_name,
                'me.well_name' => $well_name
            },
            {
                join => 'plate'
            }
        ) or die "Failed to retrieve well ${plate_name}_${well_name}\n";

        $design = $well->design_instance->design;
    }
    else {
        die "Invalid design specification: '$design_spec'\n";
    }

    return $design;
}

__END__
