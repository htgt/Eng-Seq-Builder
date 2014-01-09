#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';

use Getopt::Long;
use Pod::Usage;
use LIMS2::Model;
use Bio::SeqIO;
use LIMS2::Model::Util::EngSeqParams qw( generate_well_eng_seq_params );
use Log::Log4perl ':easy';

{

    my $log_level = $WARN;
    GetOptions(
        'help'          => sub { pod2usage( -verbose    => 1 ) },
        'man'           => sub { pod2usage( -verbose    => 2 ) },
        'debug'         => sub { $log_level = $DEBUG },
        'verbose'       => sub { $log_level = $INFO },
        'plate_name=s'  => \my $plate_name,
        'well_name=s'   => \my $well_name,
        'well_id=s'     => \my $well_id,
        'cassette=s'    => \my $cassette,
        'backbone=s'    => \my $backbone,
        'recombinase=s' => \my @recombinases,
        'config=s'      => \my $config,
        'format=s'      => \my $format,
    ) or pod2usage(2);
    Log::Log4perl->easy_init( { level => $log_level, layout => '%p %m%n' } );

    my $model = LIMS2::Model->new( user => 'lims2' );

    my $eng_seq_builder = $config ? EngSeqBuilder->new( configfile => $config )
                                  : EngSeqBuilder->new;

    my %params;
    if ( $well_id ) {
        $params{well_id} = $well_id;
    }
    elsif( $plate_name && $well_name ) {
        $params{plate_name} = $plate_name;
        $params{well_name} = $well_name;
    }
    else {
        die( 'Need well_id, or plate_name and well_name' );
    }

    $params{cassette} = $cassette if $cassette;
    $params{backbone} = $backbone if $backbone;
    $params{recombinase} = \@recombinases if @recombinases;

    my ( $method, $well, $eng_seq_params ) = generate_well_eng_seq_params( $model, \%params );

	my $seq = $eng_seq_builder->$method( %{ $eng_seq_params } );

    my $seq_io = Bio::SeqIO->new( -fh => \*STDOUT, -format => $format || 'genbank' );
    $seq_io->write_seq( $seq );
}

__END__

=head1 NAME

lims2-genbank.pl - generate genbank file for lims2 well

=head1 SYNOPSIS

  lims2-genbank.pl [options]

      --help            Display a brief help message
      --man             Display the manual page
      --debug           Debug output
      --verbose         Verbose output
      --plate_name      Name of LIMS2 plate
      --well_name       Name of well on plate
      --well_id         Well ID
      --cassette        Specify / override cassette value
      --backbone        Specify / override backbone value
      --recombinase     Specify / override recombinase ( can specify multiple times )
      --config          Custom config for EngSeqBuilder
      --format          Format of sequence output, default Genbank

=head1 DESCRIPTION

Produces a genbank file representing a specified well in LIMS2.
You must provide a plate and well name or a well_id.
You can override the cassette, backbone and recombinase values of the well if you want to.

=head1 AUTHOR

Sajith Perera

=head1 BUGS

None reported... yet.

=head1 TODO

=cut
