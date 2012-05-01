package EngSeqBuilder::CLI::Command::IntermediateVectorSeq;

use Moose;
use Bio::SeqIO;
use namespace::autoclean;

extends 'EngSeqBuilder::CLI::Command';

override abstract => sub {'Fetch an intermediate vector sequence (in any format supported by Bio::SeqIO)'};

has [ qw( cassette backbone chromosome ) ] => (
    is       => 'ro',
    isa      => 'Str',
    traits   => [ 'Getopt' ],
    required => 1
);

has [ qw( homology_arm_start homology_arm_end cassette_start cassette_end loxp_start loxp_end strand ) ] => (
    is       => 'ro',
    isa      => 'Int',
    traits   => [ 'Getopt' ],
    required => 1
);

has [ qw( name description species assembly transcript ) ] => (
    is       => 'ro',
    isa      => 'Str',
    traits   => [ 'Getopt' ],
    required => 0
);

has format => (
    is      => 'ro',
    isa     => 'Str',
    traits  => [ 'Getopt' ],
    default => 'genbank'
);

sub execute {
    my ( $self, $opts, $args ) = @_;

    my $seq = $self->eng_seq_builder->intermediate_vector_seq(
        map { defined $self->$_ ? ( $_ => $self->$_ ) : () }
            qw( species assembly chromosome strand
            homology_arm_start homology_arm_end
            cassette_start cassette_end
            loxp_start loxp_end
            cassette backbone transcript )
    );

    if ( my $name = $self->name ) {
        $name =~ s/\s+/_/g;
        $seq->display_id( $name );
    }

    if ( my $desc = $self->description ) {
        $seq->desc( $desc );
    }

    my $seq_io = Bio::SeqIO->new( -fh => \*STDOUT, -format => $self->format );

    $seq_io->write_seq( $seq );

    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
