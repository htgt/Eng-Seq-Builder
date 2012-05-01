package EngSeqBuilder::CLI::Command::ListSeqs;

use Moose;
use Text::Table;
use namespace::autoclean;

extends 'EngSeqBuilder::CLI::Command';

override abstract => sub {"List all sequences (optionally, of the specified type)"};

has type => (
    is     => 'ro',
    isa    => 'Str',
    traits => [ 'Getopt' ]
);

has match => (
    is     => 'ro',
    isa    => 'Str',
    traits => [ 'Getopt' ]
);

has wanted => (
    is         => 'ro',
    isa        => 'CodeRef',
    traits     => [ 'NoGetopt' ],
    lazy_build => 1
);

sub _build_wanted {
    my $self = shift;

    my $match = $self->match;

    return sub {1}
        unless defined $match;

    my $rx = qr/$match/;

    return sub { $_[ 0 ]->{ name } =~ $rx };
}

sub execute {
    my ( $self, $opts, $args ) = @_;

    my $table;

    if ( $self->type ) {
        my @seqs = grep { $self->wanted->( $_ ) } @{ $self->eng_seq_builder->list_seqs( type => $self->type ) };
        $table = Text::Table->new( "Name" );
        for my $seq ( sort { $a->{ name } cmp $b->{ name } } @seqs ) {
            $table->add( $seq->{ name } );
        }
    }
    else {
        my @seqs = grep { $self->wanted->( $_ ) } @{ $self->eng_seq_builder->list_seqs };
        $table = Text::Table->new( "Type", "Name" );
        for my $seq ( sort { $a->{ type } cmp $b->{ type } || $a->{ name } cmp $b->{ name } } @seqs ) {
            $table->add( $seq->{ type }, "'" . $seq->{ name } . "'" );
        }
    }

    print $table;

    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
