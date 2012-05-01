package EngSeqBuilder::CLI::Command::FetchSeq;

use Moose;
use Bio::SeqIO;
use namespace::autoclean;

extends 'EngSeqBuilder::CLI::Command';

override abstract => sub {'Fetch the specified sequence (in any format supported by Bio::SeqIO)'};

has name => (
    is       => 'ro',
    isa      => 'Str',
    traits   => [ 'Getopt' ],
    required => 1
);

has type => (
    is     => 'ro',
    isa    => 'Str',
    traits => [ 'Getopt' ],
);

has format => (
    is      => 'ro',
    isa     => 'Str',
    traits  => [ 'Getopt' ],
    default => 'genbank'
);

sub execute {
    my ( $self, $opts, $args ) = @_;
    my $seq;
    if ( $self->type ) {
        $seq = $self->eng_seq_builder->fetch_seq( name => $self->name, type => $self->type );
    }
    else {
        $seq = $self->eng_seq_builder->fetch_seq( name => $self->name );
    }

    my $seq_io = Bio::SeqIO->new( -fh => \*STDOUT, -format => $self->format );

    $seq_io->write_seq( $seq );

    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
