package EngSeqBuilder::CLI::Command;

use Moose;
use MooseX::Types::Path::Class;
use EngSeqBuilder;
use Log::Log4perl ':levels';
use namespace::autoclean;

extends 'MooseX::App::Cmd::Command';
with 'MooseX::Log::Log4perl';

has configfile => (
    is       => 'ro',
    isa      => 'Path::Class::File',
    coerce   => 1,
    traits   => [ 'Getopt' ],
    cmd_flag => 'config'
);

has [ qw( commit debug verbose ) ] => (
    is      => 'ro',
    isa     => 'Bool',
    traits  => [ 'Getopt' ],
    default => 0
);

has log_layout => (
    is       => 'ro',
    isa      => 'Str',
    traits   => [ 'Getopt' ],
    default  => '%p %m%n',
    cmd_flag => 'log-layout'
);

has log_file => (
    is       => 'ro',
    isa      => 'Path::Class::File',
    coerce   => 1,
    traits   => [ 'Getopt' ],
    cmd_flag => 'log-file'
);

has eng_seq_builder => (
    is         => 'ro',
    isa        => 'EngSeqBuilder',
    traits     => [ 'NoGetopt' ],
    init_arg   => undef,
    lazy_build => 1
);

sub BUILD {
    my $self = shift;

    my $log_level
        = $self->debug   ? $DEBUG
        : $self->verbose ? $INFO
        :                  $WARN;

    my %log4p = (
        level  => $log_level,
        layout => $self->log_layout
    );

    if ( $self->log_file ) {
        $log4p{ file } = $self->log_file;
    }

    Log::Log4perl->easy_init( \%log4p );

    return;
}

sub _build_eng_seq_builder {
    my $self = shift;

    if ( $self->configfile ) {
        return EngSeqBuilder->new( configfile => $self->configfile );
    }
    else {
        return EngSeqBuilder->new();
    }
}

override command_names => sub {

    # from App::Cmd::Command
    my ( $name ) = ( ref( $_[ 0 ] ) || $_[ 0 ] ) =~ /([^:]+)$/;

    # split camel case into words
    my @parts = $name =~ m/[[:upper:]](?:[[:upper:]]+|[[:lower:]]*)(?=\Z|[[:upper:]])/g;

    if ( @parts ) {
        return join '-', map {lc} @parts;
    }
    else {
        return lc $name;
    }
};

__PACKAGE__->meta->make_immutable;

1;

__END__
