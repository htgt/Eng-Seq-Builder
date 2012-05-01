package EngSeqBuilder::CLI::Command::LoadSeq;

use Moose;
use Bio::SeqIO;
use Bio::SeqFeature::Generic;
use Bio::SeqUtils;
use EngSeqBuilder::Exception;
use EngSeqBuilder::Util qw( get_gateway_boundary is_exact_feature );
use MooseX::Types::Path::Class;
use namespace::autoclean;

extends 'EngSeqBuilder::CLI::Command';

override abstract => sub {"Load a sequence file into the database"};

has name => (
    is       => 'ro',
    isa      => 'Str',
    traits   => [ 'Getopt' ],
    required => 1
);

has description => (
    is      => 'ro',
    isa     => 'Str',
    traits  => [ 'Getopt' ],
    default => ''
);

has type => (
    is       => 'ro',
    isa      => 'Str',
    traits   => [ 'Getopt' ],
    required => 1
);

has genbank_file => (
    is       => 'ro',
    isa      => 'Path::Class::File',
    traits   => [ 'Getopt' ],
    coerce   => 1,
    required => 1
);

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $seq_io = Bio::SeqIO->new( -fh => $self->genbank_file->openr, -format => 'genbank' );
    my $seq = $seq_io->next_seq;

    $self->eng_seq_builder->txn_do(
        sub {
            $self->eng_seq_builder->create_simple_seq(
                name        => $self->name,
                type        => $self->type,
                seq         => $seq->seq,
                description => $self->description,
                features    => [ $seq->get_SeqFeatures ],
            );
            $self->eng_seq_builder->txn_rollback unless $self->commit;
        }
    );

    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
