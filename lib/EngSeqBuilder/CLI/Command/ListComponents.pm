package EngSeqBuilder::CLI::Command::ListComponents;

use Moose;
use namespace::autoclean;

extends 'EngSeqBuilder::CLI::Command';

override abstract => sub {"List the components of the specified (compound) sequence"};

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
    my ( $self, $opts, $args ) = @_;
    my $components;

    if ( $self->type ) {
        $components = $self->eng_seq_builder->list_components( name => $self->name, type => $self->type );
    }
    else {
        $components = $self->eng_seq_builder->list_components( name => $self->name );
    }

    $self->_dump_components( $components, 0, 4 );

    return;
}

sub _dump_components {
    my ( $self, $components, $indent, $step ) = @_;

    if ( ref $components ) {
        for my $c ( @{ $components } ) {
            $self->_dump_components( $c, $indent + $step, $step );
        }
    }
    else {
        print join( '', ( q{ } ) x $indent, $components ) . "\n";
    }

    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
