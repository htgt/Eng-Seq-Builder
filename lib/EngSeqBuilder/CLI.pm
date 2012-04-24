package EngSeqBuilder::CLI;
{
  $EngSeqBuilder::CLI::VERSION = '0.001';
}

use Moose;
use namespace::autoclean;

extends 'MooseX::App::Cmd';

__PACKAGE__->meta->make_immutable;

1;

__END__
