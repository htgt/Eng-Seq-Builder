package EngSeqBuilder::Genbank::HTGT;

use strict;
use warnings;

use Moose;

with 'EngSeqBuilder::Genbank';
use HTGT::DBFactory;

has htgt => (
    is    => 'rw',
    isa   => 'HTGTDB',
    lazy  => 1,
    builder => '_htgt_connect',
);

sub _htgt_connect{
  	return HTGT::DBFactory->connect( 'eucomm_vector' );
}

sub get_design {
    my ( $self, $design_spec ) = @_;

    $design_spec ||= '';
    
    my $design;
    
    if ( $design_spec =~ /^\d+$/ ) {
        $design = $self->htgt->resultset( 'Design' )->find( { design_id => $design_spec } )
            || die "Failed to retrieve design $design_spec\n";
    }
    elsif ( my ( $plate_name, $well_name ) = $design_spec =~ m/^(\w+)_(\w+)$/ ) {
        my $well = $self->htgt->resultset( 'Well' )->find(
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

###### TIDY THIS UP ######
sub get_design_projects {
    my ($self, $args) = @_;
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
        my $msg = 'No project found for design: ' . $design->design_id;
        #die $msg;
        return 'None';
    }

    return join ':', @project_ids;
}

1;
