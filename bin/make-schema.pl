#!/usr/bin/env perl
#
# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/Eng-Seq-Builder/trunk/bin/make-schema.pl $
# $LastChangedRevision: 5302 $
# $LastChangedDate: 2011-06-17 14:52:30 +0100 (Fri, 17 Jun 2011) $
# $LastChangedBy: rm7 $
#

use strict;
use warnings FATAL => 'all';

use Getopt::Long;
use Pod::Usage;
use Term::ReadPassword 'read_password';
use DBIx::Class::Schema::Loader 'make_schema_at';
use FindBin;
use File::Spec;

{
    
    my $pg_host        = $ENV{PGHOST};
    my $pg_port        = $ENV{PGPORT};
    my $pg_database    = 'eng_seq_devel';
    my $pg_user        = $ENV{PGUSER} || $ENV{USER};
    my $pg_password;
    my $dump_directory = "$FindBin::Bin/../lib";
    my $debug;

    GetOptions(
        'help'             => sub { pod2usage( -verbose => 1 ) },
        'man'              => sub { pod2usage( -verbose => 2 ) },
        'debug'            => \$debug,
        'host=s'           => \$pg_host,
        'port=s'           => \$pg_port,
        'database=s'       => \$pg_database,
        'user=s'           => \$pg_user,
        'password=s'       => \$pg_password,
        'dump-directory=s' => \$dump_directory,
    ) or pod2usage(2);

    die "Database name must be specified\n"
        unless defined $pg_database;
    
    $pg_password = get_password( $pg_user, $pg_host )
        unless defined $pg_password;

    my $dsn = get_dsn( $pg_host, $pg_port, $pg_database );
    
    make_schema_at(
        'EngSeqBuilder::Schema',
        {
            debug          => $debug,
            dump_directory => File::Spec->canonpath( $dump_directory ),
            use_moose      => 1,
            components     => [qw( InflateColumn::DateTime )]
        },
        [ $dsn, $pg_user, $pg_password, { on_connect_do => 'SET ROLE eng_seq_devel_ro' } ]
    );
}

sub get_dsn {
    my ( $pg_host, $pg_port, $pg_database ) = @_;

    my $dsn = 'dbi:Pg:dbname=' . $pg_database;
    if ( $pg_host ) {
        $dsn .= ';host=' . $pg_host;
    }
    if ( $pg_port ) {
        $dsn .= ';port=' . $pg_port;
    }

    return $dsn;
}

sub get_password {
    my ( $pg_user, $pg_host ) = @_;

    my $pw_prompt = "Password for $pg_user";
    if ( $pg_host ) {
        $pw_prompt .= '@' . $pg_host;
    }
    $pw_prompt .= ': ';

    my $pg_password = read_password( $pw_prompt );

    return $pg_password;
}

__END__

=head1 NAME

make-schema.pl - Describe the usage of script briefly

=head1 SYNOPSIS

make-schema.pl [options] args

      -opt --long      Option description

=head1 DESCRIPTION

Stub documentation for make-schema.pl, 

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
