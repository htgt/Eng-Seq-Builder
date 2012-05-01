package EngSeqBuilder::CLI::Command::LoadComponent;

use Moose;
use MooseX::Types::Path::Class;
use EngSeqBuilder::Util qw( is_exact_feature );
use Bio::SeqIO;
use Bio::SeqUtils;
use YAML::Any;
use namespace::autoclean;

extends 'EngSeqBuilder::CLI::Command';

override abstract => sub {'Load component data into the database'};

has name => (
    is       => 'ro',
    isa      => 'Str',
    traits   => [ 'Getopt' ],
    required => 1
);

has type => (
    is       => 'ro',
    isa      => 'Str',
    traits   => [ 'Getopt' ],
    required => 1,
);

has description => (
    is     => 'ro',
    isa    => 'Str',
    traits => [ 'Getopt' ],
);

has sequence_file => (
    is       => 'ro',
    isa      => 'Path::Class::File',
    traits   => [ 'Getopt' ],
    coerce   => 1,
    required => 1
);

sub execute {
    my ( $self, $opts, $args ) = @_;

    my $seq_io            = Bio::SeqIO->new( -fh => $self->sequence_file->openr );
    my $seq               = $seq_io->next_seq;
    my @this_seq_features = grep { is_exact_feature( $_ ) } $seq->get_SeqFeatures;

    my @optional_args;
    push @optional_args, ( description => $self->description )  if $self->description;
    push @optional_args, ( features    => \@this_seq_features ) if @this_seq_features;

    $self->eng_seq_builder->txn_do(
        sub {
            $self->eng_seq_builder->create_simple_seq(
                name => $self->name,
                type => $self->type,
                seq  => $seq->seq,
                @optional_args
            );
            $self->eng_seq_builder->txn_rollback unless $self->commit;
        }
    );

    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
