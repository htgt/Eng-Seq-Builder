package EngSeqBuilder::Exception;

use Moose;
extends 'Throwable::Error';

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );

1;

__END__
