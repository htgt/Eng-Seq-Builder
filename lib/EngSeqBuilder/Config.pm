package EngSeqBuilder::Config;

use Moose;
use EngSeqBuilder::Exception;
use namespace::autoclean;

with 'MooseX::SimpleConfig';

has pg_database => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has pg_host => (
    is  => 'ro',
    isa => 'Str'
);

has pg_port => (
    is  => 'ro',
    isa => 'Str',
);

has pg_user => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has pg_password => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has pg_options => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub {
        +{  AutoCommit => 1,
            RaiseError => 1,
            PrintError => 0
        };
    }
);

has dsn => (
    is         => 'ro',
    isa        => 'Str',
    init_arg   => undef,
    lazy_build => 1
);

has gateway_boundaries => (
    isa      => 'HashRef',
    reader   => '_gateway_boundaries',
    required => 1,
);

has [ qw( max_vector_seq_length max_allele_seq_length ) ] => (
    is       => 'ro',
    isa      => 'Int',
    required => 1
);

sub _build_dsn {
    my $self = shift;

    my $dsn = 'dbi:Pg:dbname=' . $self->pg_database;
    if ( $self->pg_host ) {
        $dsn .= ';host=' . $self->pg_host;
    }
    if ( $self->pg_port ) {
        $dsn .= ';port=' . $self->pg_port;
    }

    return $dsn;
}

has db_connect_params => (
    isa        => 'ArrayRef',
    init_arg   => undef,
    traits     => [ 'Array' ],
    handles    => { db_connect_params => 'elements' },
    lazy_build => 1
);

sub _build_db_connect_params {
    my $self = shift;

    return [ $self->dsn, $self->pg_user, $self->pg_password, $self->pg_options ];
}

has ensembl_host => (
    is      => 'ro',
    isa     => 'Str',
    default => 'ensembldb.ensembl.org'
);

has ensembl_port => (
    is  => 'ro',
    isa => 'Int'
);

has ensembl_user => (
    is      => 'ro',
    isa     => 'Str',
    default => 'anonymous'
);

has ensembl_registry => (
    is         => 'ro',
    isa        => 'Str',
    init_arg   => undef,
    lazy_build => 1
);

sub _build_ensembl_registry {
    my $self = shift;

    my %args = (
        -host => $self->ensembl_host,
        -user => $self->ensembl_user,
    );

    if ( $self->ensembl_port ) {
        $args{ -port } = $self->ensembl_port;
    }

    require Bio::EnsEMBL::Registry;

    Bio::EnsEMBL::Registry->load_registry_from_db( %args );

    return 'Bio::EnsEMBL::Registry';
}

sub gateway_boundaries_for {
    my ( $self, $cassette_or_backbone, $vector_stage ) = @_;

    my $boundaries = $self->_gateway_boundaries->{ $cassette_or_backbone }->{ $vector_stage }
        or
        EngSeqBuilder::Exception->throw( "No gateway boundaries configured for $vector_stage $cassette_or_backbone" );

    return $boundaries;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Config - Perl extension for blah blah blah

=head1 SYNOPSIS

   use Config;
   blah blah blah

=head1 DESCRIPTION

Stub documentation for Config, 

Blah blah blah.

=head2 EXPORT

None by default.

=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Ray Miller, E<lt>rm7@htgt-web.internal.sanger.ac.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Ray Miller

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
