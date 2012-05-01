package EngSeqBuilder::CLI::Command::ReplaceSeqFeatures;

use Moose;
use Bio::SeqIO;
use namespace::autoclean;
use MooseX::Types::Path::Class;

extends 'EngSeqBuilder::CLI::Command';

override abstract => sub {'Replace all the features on the specified sequnce with those in the GenBank file'};

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

has genbank_file => (
    is       => 'ro',
    isa      => 'Path::Class::File',
    traits   => [ 'Getopt' ],
    coerce   => 1,
    required => 1,
    cmd_flag => 'genbank-file'
);

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $eng_seq;
    if ( $self->type ) {
        $eng_seq = $self->eng_seq_builder->_fetch_seq( $self->name, $self->type ); ## no critic(ProtectPrivateSubs)
    }
    else {
        $eng_seq = $self->eng_seq_builder->_fetch_seq( $self->name ); ## no critic(ProtectPrivateSubs)
    }

    die "Features can only be replaced on simple sequences\n"
        unless $eng_seq->class eq 'simple';

    my $seq_io = Bio::SeqIO->new( -fh => $self->genbank_file->openr, -format => 'genbank' );
    my $bio_seq = $seq_io->next_seq
        or die "Failed to read sequence from " . $self->genbank_file;

    die "Sequences must be identical\n"
        unless $bio_seq->seq eq $eng_seq->simple_eng_seq->seq;

    $self->eng_seq_builder->txn_do(
        sub {
            $eng_seq->delete_seq_features;
            my @features = $bio_seq->get_SeqFeatures;
            $eng_seq->add_features( \@features );
        }
    );

    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
