package MyTest::EngSeqBuilder;

use strict;
use warnings FATAL => 'all';

use base qw( Test::Class Class::Data::Inheritable );

BEGIN {
    __PACKAGE__->mk_classdata( 'class' => 'EngSeqBuilder' );
    __PACKAGE__->mk_classdata( 'schema' );
    __PACKAGE__->mk_classdata( 'eng_seq_builder' );
    __PACKAGE__->mk_classdata( 'conffile' );
}

use Test::Most;
use Bio::SeqIO;
use EngSeqBuilder;
use EngSeqBuilder::Schema;
use Const::Fast;
use IO::String;
use File::Temp;
use YAML;

const my %CONFIG => (
    pg_database  => 'not used',
    pg_user      => 'not used',
    pg_password  => 'not used',
    ensembl_host => 'ensembldb.ensembl.org',
    ensembl_user => 'anonymous',
);

const my $B1 => <<'EOT';
LOCUS       pR6K_R1R2_ZP_synvec           25 bp    dna     linear   UNK 
ACCESSION   unknown
KEYWORDS    .
FEATURES             Location/Qualifiers
     misc_feature    complement(1..25)
                     /note="B1 site"
BASE COUNT       12 a      4 c      4 g      5 t
ORIGIN      
        1 acaagtttgt acaaaaaagc tgaac
//
EOT

const my $B2 => <<'EOT';
LOCUS       pR6K_R1R2_ZP_synvec           25 bp    dna     linear   UNK 
ACCESSION   unknown
KEYWORDS    .
FEATURES             Location/Qualifiers
     misc_feature    1..25
                     /note="B2 site"
BASE COUNT        5 a      4 c      6 g     10 t
ORIGIN      
        1 gttcagcttt cttgtacaaa gtggt
//
EOT

const my $ZEO_PHES_CASSETTE => <<'EOT';
LOCUS       pR6K_R1R2_ZP_synvec         1614 bp    dna     linear   UNK 
ACCESSION   unknown
KEYWORDS    .
FEATURES             Location/Qualifiers
     promoter        29..99
                     /note="EM7 promoter"
     CDS             100..474
                     /note="ZeoR"
     gene            508..1503
                     /note="PheS"
BASE COUNT      356 a    436 c    477 g    345 t
ORIGIN      
        1 gggccgcgat atcgctagct cgatcgagca cgtgttgaca attaatcatc ggcatagtat
       61 atcggcatag tataatacga caaggtgagg aactaaacca tggccaagtt gaccagtgcc
      121 gttccggtgc tcaccgcgcg cgacgtcgcc ggagcggtcg agttctggac cgaccggctc
      181 gggttctccc gggacttcgt ggaggacgac ttcgccggtg tggtccggga cgacgtgacc
      241 ctgttcatca gcgcggtcca ggaccaggtg gtgccggaca acaccctggc ctgggtgtgg
      301 gtgcgcggcc tggacgagct gtacgccgag tggtcggagg tcgtgtccac gaacttccgg
      361 gacgcctccg ggccggccat gaccgagatc ggcgagcagc cgtgggggcg ggagttcgcc
      421 ctgcgcgacc cggccggcaa ctgcgtgcac ttcgtggccg aggagcagga ctgagaattc
      481 gaacgaacca gtgtcaccac tgacacaatg aggaaaacca tgtcacatct cgcagaactg
      541 gttgccagtg cgaaggcggc cattagccag gcgtcagatg ttgccgcgtt agataatgtg
      601 cgcgtcgaat atttgggtaa aaaagggcac ttaacccttc agatgacgac cctgcgtgag
      661 ctgccgccag aagagcgtcc ggcagctggt gcggttatca acgaagcgaa agagcaggtt
      721 cagcaggcgc tgaatgcgcg taaagcggaa ctggaaagcg ctgcactgaa tgcgcgtctg
      781 gcggcggaaa cgattgatgt ctctctgcca ggtcgtcgca ttgaaaacgg cggtctgcat
      841 ccggttaccc gtaccatcga ccgtatcgaa agtttcttcg gtgagcttgg ctttaccgtg
      901 gcaaccgggc cggaaatcga agacgattat cataacttcg atgctctgaa cattcctggt
      961 caccacccgg cgcgcgctga ccacgacact ttctggtttg acactacccg cctgctgcgt
     1021 acccagacct ctggcgtaca gatccgcacc atgaaagccc agcagccacc gattcgtatc
     1081 atcgcgcctg gccgtgttta tcgtaacgac tacgaccaga ctcacacgcc gatgttccat
     1141 cagatggaag gtctgattgt tgataccaac atcagcttta ccaacctgaa aggcacgctg
     1201 cacgacttcc tgcgtaactt ctttgaggaa gatttgcaga ttcgcttccg tccttcctac
     1261 ttcccgttta ccgaaccttc tgcagaagtg gacgtcatgg gtaaaaacgg taaatggctg
     1321 gaagtgctgg gctgcgggat ggtgcatccg aacgtgttgc gtaacgttgg catcgacccg
     1381 gaagtttact ctggtttcgg cttcgggatg gggatggagc gtctgactat gttgcgttac
     1441 ggcgtcaccg acctgcgttc attcttcgaa aacgatctgc gtttcctcaa acagtttaaa
     1501 taaggcagga atagattatg aaattcagtg aactgtggtt acgcgaatgg gtgaacccgg
     1561 cgattgatag cgatgcgctg gcaaatcaaa tcactatggc gctctagagt cgac
//
EOT

const my $OAB1 => <<'EOT';
LOCUS       pR6K_R1R2_ZP_synvec           20 bp    dna     linear   UNK 
ACCESSION   unknown
KEYWORDS    .
FEATURES             Location/Qualifiers
BASE COUNT        8 a      6 c      4 g      2 t
ORIGIN      
        1 aaggcgcata acgataccac
//
EOT

const my $CAB1 => <<'EOT';
LOCUS       pR6K_R1R2_ZP_synvec            7 bp    dna     linear   UNK 
ACCESSION   unknown
KEYWORDS    .
FEATURES             Location/Qualifiers
BASE COUNT        3 a      1 c      1 g      2 t
ORIGIN      
        1 gatatca
//
EOT
    
const my $OAB2 => <<'EOT';
LOCUS       pR6K_R1R2_ZP_synvec           20 bp    dna     linear   UNK 
ACCESSION   unknown
KEYWORDS    .
FEATURES             Location/Qualifiers
BASE COUNT        4 a      4 c      7 g      5 t
ORIGIN      
        1 tctatagtcg cagtaggcgg
//
EOT
    
const my $CAB2 => <<'EOT';
LOCUS       pR6K_R1R2_ZP_synvec            7 bp    dna     linear   UNK 
ACCESSION   unknown
KEYWORDS    .
FEATURES             Location/Qualifiers
BASE COUNT        2 a      1 c      1 g      3 t
ORIGIN      
        1 tgatatc
//
EOT

const my $R1 => <<'EOT';
LOCUS       pR6K_R1R2_ZP_synvec          125 bp    dna     linear   UNK 
ACCESSION   unknown
KEYWORDS    .
FEATURES             Location/Qualifiers
     misc_feature    complement(1..125)
                     /note="R1 Gateway"
     misc_feature    complement(1..25)
                     /note="B1 site"
BASE COUNT       61 a     18 c     14 g     32 t
ORIGIN      
        1 acaagtttgt acaaaaaagc tgaacgagaa acgtaaaatg atataaatat caatatatta
       61 aattagattt tgcataaaaa acagactaca taatactgta aaacacaaca tatccagtca
      121 ctatg
//
EOT

const my $R2 => <<'EOT';
LOCUS       pR6K_R1R2_ZP_synvec          125 bp    dna     linear   UNK 
ACCESSION   unknown
KEYWORDS    .
FEATURES             Location/Qualifiers
     misc_feature    1..125
                     /note="R2 Gateway"
     misc_feature    101..125
                     /note="B2 site"
BASE COUNT       32 a     14 c     20 g     59 t
ORIGIN      
        1 catagtgact ggatatgttg tgttttacag tattatgtag tctgtttttt atgcaaaatc
       61 taatttaata tattgatatt tatatcattt tacgtttctc gttcagcttt cttgtacaaa
      121 gtggt
//
EOT

const my $ZEO_PHES_CASSETTE_WITH_APPENDS => <<'EOT';
LOCUS       pR6K_R1R2_ZP_synvec         1918 bp    DNA     circular 15-JAN-2007 
ACCESSION   unknown
KEYWORDS    .
FEATURES             Location/Qualifiers
     misc_feature    complement(28..152)
                     /note="R1 Gateway"
     misc_feature    complement(28..52)
                     /note="B1 site"
     promoter        181..251
                     /note="EM7 promoter"
     CDS             252..626
                     /note="ZeoR"
     gene            660..1655
                     /note="PheS"
     misc_feature    1767..1891
                     /note="R2 Gateway"
     misc_feature    1867..1891
                     /note="B2 site"
BASE COUNT      466 a    480 c    524 g    448 t
ORIGIN      
        1 aaggcgcata acgataccac gatatcaaca agtttgtaca aaaaagctga acgagaaacg
       61 taaaatgata taaatatcaa tatattaaat tagattttgc ataaaaaaca gactacataa
      121 tactgtaaaa cacaacatat ccagtcacta tggggccgcg atatcgctag ctcgatcgag
      181 cacgtgttga caattaatca tcggcatagt atatcggcat agtataatac gacaaggtga
      241 ggaactaaac catggccaag ttgaccagtg ccgttccggt gctcaccgcg cgcgacgtcg
      301 ccggagcggt cgagttctgg accgaccggc tcgggttctc ccgggacttc gtggaggacg
      361 acttcgccgg tgtggtccgg gacgacgtga ccctgttcat cagcgcggtc caggaccagg
      421 tggtgccgga caacaccctg gcctgggtgt gggtgcgcgg cctggacgag ctgtacgccg
      481 agtggtcgga ggtcgtgtcc acgaacttcc gggacgcctc cgggccggcc atgaccgaga
      541 tcggcgagca gccgtggggg cgggagttcg ccctgcgcga cccggccggc aactgcgtgc
      601 acttcgtggc cgaggagcag gactgagaat tcgaacgaac cagtgtcacc actgacacaa
      661 tgaggaaaac catgtcacat ctcgcagaac tggttgccag tgcgaaggcg gccattagcc
      721 aggcgtcaga tgttgccgcg ttagataatg tgcgcgtcga atatttgggt aaaaaagggc
      781 acttaaccct tcagatgacg accctgcgtg agctgccgcc agaagagcgt ccggcagctg
      841 gtgcggttat caacgaagcg aaagagcagg ttcagcaggc gctgaatgcg cgtaaagcgg
      901 aactggaaag cgctgcactg aatgcgcgtc tggcggcgga aacgattgat gtctctctgc
      961 caggtcgtcg cattgaaaac ggcggtctgc atccggttac ccgtaccatc gaccgtatcg
     1021 aaagtttctt cggtgagctt ggctttaccg tggcaaccgg gccggaaatc gaagacgatt
     1081 atcataactt cgatgctctg aacattcctg gtcaccaccc ggcgcgcgct gaccacgaca
     1141 ctttctggtt tgacactacc cgcctgctgc gtacccagac ctctggcgta cagatccgca
     1201 ccatgaaagc ccagcagcca ccgattcgta tcatcgcgcc tggccgtgtt tatcgtaacg
     1261 actacgacca gactcacacg ccgatgttcc atcagatgga aggtctgatt gttgatacca
     1321 acatcagctt taccaacctg aaaggcacgc tgcacgactt cctgcgtaac ttctttgagg
     1381 aagatttgca gattcgcttc cgtccttcct acttcccgtt taccgaacct tctgcagaag
     1441 tggacgtcat gggtaaaaac ggtaaatggc tggaagtgct gggctgcggg atggtgcatc
     1501 cgaacgtgtt gcgtaacgtt ggcatcgacc cggaagttta ctctggtttc ggcttcggga
     1561 tggggatgga gcgtctgact atgttgcgtt acggcgtcac cgacctgcgt tcattcttcg
     1621 aaaacgatct gcgtttcctc aaacagttta aataaggcag gaatagatta tgaaattcag
     1681 tgaactgtgg ttacgcgaat gggtgaaccc ggcgattgat agcgatgcgc tggcaaatca
     1741 aatcactatg gcgctctaga gtcgaccata gtgactggat atgttgtgtt ttacagtatt
     1801 atgtagtctg ttttttatgc aaaatctaat ttaatatatt gatatttata tcattttacg
     1861 tttctcgttc agctttcttg tacaaagtgg ttgatatctc tatagtcgca gtaggcgg
//
EOT

const my @SIMPLE_SEQS => (
    {
        name => 'Intermediate cassette B1 oligo append sequence',
        type => 'OAB1',
        gbk  => $OAB1
    },
    {
        name => 'Intermediate cassette B1 cassette append sequence',
        type => 'CAB1',
        gbk  =>  $CAB1 
    },
    {
        name => 'Standard B1 gateway site',
        type => 'B1',
        gbk  => $B1
    },
    {
        name => 'Standard R1 gateway site',
        type => 'R1',
        gbk  => $R1
    },
    {
        name => 'Zeo PheS cassette',
        type => 'cassette',
        gbk  =>  $ZEO_PHES_CASSETTE
    },
    {
        name => 'Standard B2 gateway site',
        type => 'B2',
        gbk  => $B2
    },
    {
        name => 'Standard R2 gateway site',
        type => 'R2',
        gbk  => $R2
    },
    {
        name => 'Intermediate cassette B2 cassette append sequence',
        type => 'CAB2',
        gbk  => $CAB2           
    },
    {
        name => 'Intermediate cassette B2 oligo append sequence',
        type => 'OAB2',
        gbk  => $OAB2
    }
);

const my @COMPOUND_SEQS => (
    {
        name => 'Intermediate cassette B1 append sequence',
        type => 'AB1',
        components => [ 'Intermediate cassette B1 oligo append sequence', 'Intermediate cassette B1 cassette append sequence' ]
    },
    {
        name => 'Intermediate cassette B2 append sequence',
        type => 'AB1',
        components => [ 'Intermediate cassette B2 cassette append sequence', 'Intermediate cassette B2 oligo append sequence'  ]
    },
    {
        name => 'Standard Zeo PheS intermediate cassette with gateway B sites',
        type => 'cassette-B',
        components => [ 'Intermediate cassette B1 append sequence',
                        'Standard B1 gateway site',
                        'Zeo PheS cassette',
                        'Standard B2 gateway site',
                        'Intermediate cassette B2 append sequence'
                    ]
    },
    {
        name => 'Standard Zeo PheS intermediate cassette with gateway R sites',
        type => 'cassette-R',
        components => [ 'Intermediate cassette B1 append sequence',
                        'Standard R1 gateway site',
                        'Zeo PheS cassette',
                        'Standard R2 gateway site',
                        'Intermediate cassette B2 append sequence'
                    ]
    },
);

sub _bio_seq {
    my ( $class, $seq_str ) = @_;

    my $ifh = IO::String->new( $seq_str );
    my $seq_io = Bio::SeqIO->new( -fh => $ifh, -format => 'genbank' );

    return $seq_io->next_seq;
}
    
sub make_fixtures : Tests( startup => 2 ) {
    my $test = shift;

    if ( $ENV{ENG_SEQ_BUILDER_TEST_CONFIG} ) {
        $test->conffile( $ENV{ENG_SEQ_BUILDER_TEST_CONFIG} );
        return 'Using configured database';
    }
    
    lives_ok {
        my $schema = EngSeqBuilder::Schema->connect( 'dbi:SQLite:dbname=:memory:', '', '', { AutoCommit => 1 } );
        $schema->deploy;        
        $schema->populate( 'EngSeqType', [
            [ 'name' ],
            map [ $_ ], qw( R1 R2 R3 R4 B1 B2 B3 B4 AB1 AB2 AB3 AB4 OAB1 OAB2 OAB3 OAB4 CAB1 CAB2 CAB3 CAB4
                            A5Lox A3Lox cassette cassette-R cassette-L cassette-B
                            backbone backbone-R backbone-L backbone-B )
        ] );
        $test->schema( $schema );    
    } 'deploy schema';

    lives_ok {
        my $conffile = File::Temp->new( SUFFIX => '.yaml' );
        $conffile->print( YAML::Dump( \%CONFIG ) );
        system 'cat', $conffile;
        $test->conffile( $conffile );
    } 'create conffile';
}

sub constructor : Tests( setup => 3 ) {
    my $test = shift;

    can_ok $test->class, 'new';

    my %args;
    if ( $ENV{ENG_SEQ_BUILDER_TEST_CONFIG} ) {
        $args{configfile} = $test->conffile;
    }
    else {
        $args{configfile} = $test->conffile->filename;
        $args{schema}     = $test->schema;
    }
    ok my $eng_seq_builder = $test->class->new( \%args ),
        '...the constructor succeeds';
    isa_ok $eng_seq_builder, $test->class, '...the object it returns';

    $test->eng_seq_builder( $eng_seq_builder );    
}

# prefixed method with '_' to ensure it runs before the create_compound_seq method
sub _create_simple_seq : Tests {
    my $test = shift;

    can_ok $test->eng_seq_builder, 'create_simple_seq';

    for my $seq ( @SIMPLE_SEQS ) {
        my $bio_seq = $test->_bio_seq( $seq->{gbk} );        
        ok my $eng_seq = $test->eng_seq_builder->create_simple_seq(
            name     => $seq->{name},
            type     => $seq->{type},
            seq      => $bio_seq->seq,
            features => [ $bio_seq->get_SeqFeatures ]
        ), "...create_simple_seq '$seq->{name}' should succeed";

        isa_ok $eng_seq, 'Bio::SeqI', '...the object it returns';

        is $eng_seq->seq, $bio_seq->seq, '...the generated bio_seq has the expected sequence';

        my @expected_features = $bio_seq->get_SeqFeatures;
        my @features = $eng_seq->get_SeqFeatures;
    
        is scalar(@expected_features), scalar(@features), '...the generated bio_seq has the expected number of features';
    }
}

sub create_compound_seq : Tests {
    my $test = shift;

    can_ok $test->eng_seq_builder, 'create_compound_seq';

    for my $seq ( @COMPOUND_SEQS ) {
        ok my $eng_seq = $test->eng_seq_builder->create_compound_seq(
            name       => $seq->{name},
            type       => $seq->{type},
            components => $seq->{components}
        ), "...create_compound_seq '$seq->{name}' should succeed";

        isa_ok $eng_seq, 'Bio::SeqI', '...the object it returns';
    }    
}

sub list_seqs : Tests {
    my $test = shift;

    can_ok $test->eng_seq_builder, 'list_seqs';

    {        
        ok my $seqs = $test->eng_seq_builder->list_seqs, '...the method should succeed with to args';
        isa_ok $seqs, 'ARRAY', '...the object it returns';
        isa_ok $seqs->[0], 'HASH', '...the first element of the list is a hash';
        ok $seqs->[0]{type}, '...the hash has a type';
        ok $seqs->[0]{name}, '...the hash has a name';        
    }

    {
        ok my $seqs = $test->eng_seq_builder->list_seqs( type => 'B1' ),
            '...the method should succeed with a type arg';
        is @{$seqs}, 1, '...there is 1 B1 seq';
    }        
}

sub list_components : Tests {
    my $test = shift;

    can_ok $test->eng_seq_builder, 'list_components';

    {
        my $name = 'Intermediate cassette B1 oligo append sequence';        
        ok my $components = $test->eng_seq_builder->list_components( name => $name ),
            '...the method should succeed for a simple seq';
        is $components, $name, '...components of a simple_seq is the seq itself';
    }

    {
        my $name = 'Intermediate cassette B1 append sequence';
        ok my $components = $test->eng_seq_builder->list_components( name => $name ),
            '...the method should succeed for a compound seq';
        is_deeply $components, [ $name, 
                                 [ 'Intermediate cassette B1 oligo append sequence',
                                   'Intermediate cassette B1 cassette append sequence' ]
                             ], '...componets of a compound seq are a bit deeper';
    }
}
    
sub fetch_seq : Tests {
    my $test = shift;

    can_ok $test->eng_seq_builder, 'fetch_seq';

    for my $s ( @SIMPLE_SEQS, @COMPOUND_SEQS ) {
        ok my $seq = $test->eng_seq_builder->fetch_seq( name => $s->{name}, type => $s->{type} ),
            "fetch_seq $s->{name} ($s->{type})";
        isa_ok $seq, 'Bio::SeqI';
    }    
}

sub fetch_zeo_phes_cassette_with_appends : Tests {
    my $test = shift;

    my $expected_bio_seq = $test->_bio_seq( $ZEO_PHES_CASSETTE_WITH_APPENDS );

    ok my $actual_bio_seq = $test->eng_seq_builder->fetch_seq(
        name => 'Standard Zeo PheS intermediate cassette with gateway R sites',
        type => 'cassette-R'
    ), 'retrieve Standard Zeo PheS intermediate cassette with gateway R sites';

    is $actual_bio_seq->length, $expected_bio_seq->length, 'sequence has expected length';

    is_deeply $test->_features_array( $actual_bio_seq ), $test->_features_array( $expected_bio_seq ),
        'sequence has expected features';
}

# Prefixed with 'x_' to ensure it runs after the fetch_ tests

sub x_delete_seq :Tests {    
    my $test = shift;

    can_ok $test->eng_seq_builder, 'delete_seq';

    throws_ok {
        $test->eng_seq_builder->delete_seq( name => 'Standard B1 gateway site', type => 'B1' )
    } qr/cannot delete a component of a compound sequence/;

    $test->_delete( 'Standard Zeo PheS intermediate cassette with gateway R sites', 'cassette-R' );
    $test->_delete( 'Standard Zeo PheS intermediate cassette with gateway B sites', 'cassette-B' );
    $test->_delete( 'Intermediate cassette B1 append sequence', 'AB1' );
}

sub _delete {    
    my ( $test, $name, $type ) = @_;

    ok $test->eng_seq_builder->delete_seq( name => $name, type => $type ), "delete $name ($type)";
    throws_ok {
        $test->eng_seq_builder->fetch_seq( name => $name, type => $type )
    } qr/Found no sequences with name '$name' of type '$type'/;
}

sub _features_array {
    my ( $self, $bio_seq ) = @_;

    my @features;

    for my $feature ( $bio_seq->get_all_SeqFeatures ) {
        my %feature_data = (
            # omit source_tag as this is populated by the GenBank parser but not by us
            #source_tag  => $feature->source_tag, 
            primary_tag => $feature->primary_tag,
            start       => $feature->start,
            end         => $feature->end,
            strand      => $feature->strand,
            tags        => { map { $_ => [ $feature->get_tag_values( $_ ) ] } $feature->get_all_tags },
        );
        $feature_data{seq} = $feature->seq->seq if $feature->seq;
        push @features, \%feature_data;
    }

    return [ sort { $a->{primary_tag} cmp $b->{primary_tag} || $a->{start} <=> $b->{start} } @features ];
}

sub _exon_ids {
    my ( $self, $bio_seq ) = @_;

    my @exon_ids;
 EXON:
    for my $exon ( grep { $_->primary_tag eq 'exon' } $bio_seq->get_all_SeqFeatures ) {
        for my $note ( $exon->get_tag_values( 'note' ) ) {
            if ( ( my $exon_id ) = $note =~ m/^exon_id=(.+)$/ ) {
                push @exon_ids, $exon_id;
                next EXON;                
            }
        }
    }

    return \@exon_ids;
}

1;

__END__
