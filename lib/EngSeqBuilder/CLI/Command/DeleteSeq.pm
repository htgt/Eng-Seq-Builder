package EngSeqBuilder::CLI::Command::DeleteSeq;

use Moose;
use Bio::SeqIO;
use Const::Fast;
use List::MoreUtils qw( any );
use namespace::autoclean;

extends 'EngSeqBuilder::CLI::Command';

override abstract => sub {'Delete the specified eng_seq'};

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

sub execute {
    my ( $self, $opt, $args ) = @_;

    $self->eng_seq_builder->txn_do(
        sub {
            if ( $self->type ) {
                $self->eng_seq_builder->delete_seq( name => $self->name, type => $self->type );
            }
            else {
                $self->eng_seq_builder->delete_seq( name => $self->name );
            }

            $self->eng_seq_builder->txn_rollback unless $self->commit;
        }
    );

    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
