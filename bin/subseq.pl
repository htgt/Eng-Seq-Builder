#!/usr/bin/env perl
#
# $HeadURL$
# $LastChangedRevision$
# $LastChangedDate$
# $LastChangedBy$
#

use strict;
use warnings FATAL => 'all';
use autodie;

use Getopt::Long;
use Pod::Usage;
use IO::File;
use IO::Handle;
use Bio::SeqIO;
use Bio::SeqUtils;

GetOptions(
    'help'       => sub { pod2usage( -verbose => 1 ) },
    'man'        => sub { pod2usage( -verbose => 2 ) },
    'start=i'    => \my $start,
    'end=i'      => \my $end,
    'format=s'   => \my $format,
) or pod2usage(2);

$format ||= 'genbank';

my $ifh;

if ( @ARGV ) {
    my $filename = shift @ARGV;
    $ifh = IO::File->new( $filename, O_RDONLY );    
}
else {
    $ifh = IO::Handle->new->fdopen( fileno(STDIN), 'r' );
}

my $ofh = IO::Handle->new->fdopen( fileno(STDOUT), 'w' );

my $seq_in = Bio::SeqIO->new( -fh => $ifh );

my $seq = $seq_in->next_seq;

my $seq_out = Bio::SeqIO->new( -fh => $ofh, -format => $format );

$start = 1
    unless defined $start;
$end = $seq->length
    unless defined $end;

my $trunc_seq = Bio::SeqUtils->trunc_with_features( $seq, $start, $end );

$seq_out->write_seq( $trunc_seq );

__END__

=head1 NAME

subseq.pl - Describe the usage of script briefly

=head1 SYNOPSIS

subseq.pl [options] args

      -opt --long      Option description

=head1 DESCRIPTION

Stub documentation for subseq.pl, 

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
