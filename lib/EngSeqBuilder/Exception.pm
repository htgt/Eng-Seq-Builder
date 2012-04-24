package EngSeqBuilder::Exception;
{
  $EngSeqBuilder::Exception::VERSION = '0.003';
}

use Moose;
extends 'Throwable::Error';

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );

1;

__END__
