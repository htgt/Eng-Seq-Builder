#!perl

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}


use strict;
use warnings;

use Test::Most 'bail';
use File::Find;

sub expected_package_name($) {
  my $file = shift;
  $file =~ s{^.*lib/}{};
  $file =~ s{\.pm$}{};
  $file =~ s/\//::/g;
  return $file;
}

sub found_package_name($) {
  my $file = shift;

  # we assume first package name found is actual
  open my $fh, '<', $file or die "Could not open $file for reading: $!";
  my $package;
  while ( my $line = <$fh> ) {
    next unless $line =~ /^\s*package\s+((?:\w+)(::\w+)*)/;
    return $1;
  }
}

my @files;
find(
  sub {
    return unless $_ =~ /\.pm\z/ and -f $_;
    # nothing to skip
    push @files, [ $File::Find::name, found_package_name $_, expected_package_name $File::Find::name ];
  },
  'lib',
);

plan tests => scalar( @files ) || 1;

if ( @files ) {
    for my $file ( @files ) {
        my ( $file, $have, $want ) = @$file;
        is $have, $want, "Package name correct for $file";
    }
}
else {
    ok 1, 'no modules to test';
}
