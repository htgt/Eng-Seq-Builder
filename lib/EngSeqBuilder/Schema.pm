package EngSeqBuilder::Schema;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $EngSeqBuilder::Schema::VERSION = '0.013';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use Moose;
use namespace::autoclean;
extends 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;

# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-06-13 14:32:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:63AiytREjDAEXmNFc0IPgA

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable( inline_constructor => 0 );
1;
