
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Module and CLI for creating engineered sequences",
  "AUTHOR" => "Ray Miller, Sajith Perera",
  "BUILD_REQUIRES" => {
    "Class::Data::Inheritable" => 0,
    "English" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "FindBin" => 0,
    "IO::String" => 0,
    "Test::Class" => 0,
    "Test::More" => "0.88",
    "Test::Most" => 0,
    "YAML" => 0,
    "base" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Eng-Seq-Builder",
  "EXE_FILES" => [
    "bin/eng-seq-builder"
  ],
  "LICENSE" => "perl",
  "NAME" => "Eng::Seq::Builder",
  "PREREQ_PM" => {
    "Bio::Annotation::Collection" => 0,
    "Bio::Annotation::Comment" => 0,
    "Bio::EnsEMBL::Registry" => 0,
    "Bio::Range" => 0,
    "Bio::Seq" => 0,
    "Bio::SeqFeature::Gene::Exon" => 0,
    "Bio::SeqFeature::Generic" => 0,
    "Bio::SeqFeatureI" => 0,
    "Bio::SeqIO" => 0,
    "Bio::SeqUtils" => 0,
    "Bio::Species" => 0,
    "Carp" => 0,
    "Const::Fast" => 0,
    "DBIx::Class::Core" => 0,
    "DBIx::Class::Schema" => 0,
    "DBIx::Connector" => 0,
    "Data::Dump" => 0,
    "Hash::MoreUtils" => 0,
    "List::MoreUtils" => 0,
    "List::Util" => 0,
    "Log::Log4perl" => 0,
    "Moose" => 0,
    "Moose::Role" => 0,
    "MooseX::App::Cmd" => 0,
    "MooseX::App::Cmd::Command" => 0,
    "MooseX::ClassAttribute" => 0,
    "MooseX::Log::Log4perl" => 0,
    "MooseX::NonMoose" => 0,
    "MooseX::Params::Validate" => 0,
    "MooseX::SimpleConfig" => 0,
    "MooseX::Types" => 0,
    "MooseX::Types::Moose" => 0,
    "MooseX::Types::Path::Class" => 0,
    "Sub::Exporter" => 0,
    "Text::Table" => 0,
    "Throwable::Error" => 0,
    "Try::Tiny" => 0,
    "YAML::Any" => 0,
    "namespace::autoclean" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.009",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



