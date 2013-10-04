package EngSeqBuilder::CLI;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $EngSeqBuilder::CLI::VERSION = '0.011';
}
## use critic


use Moose;
use namespace::autoclean;

extends 'MooseX::App::Cmd';

__PACKAGE__->meta->make_immutable;

1;

__END__
