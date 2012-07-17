package EngSeqBuilder::Exception;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $EngSeqBuilder::Exception::VERSION = '0.008';
}
## use critic


use Moose;
extends 'Throwable::Error';

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );

1;

__END__
