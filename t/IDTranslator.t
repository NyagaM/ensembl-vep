# Copyright [2016-2017] EMBL-European Bioinformatics Institute
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#      http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use strict;
use warnings;

use Test::More;
use Test::Exception;
use FindBin qw($Bin);

use lib $Bin;
use VEPTestingConfig;

my $test_cfg = VEPTestingConfig->new();

my $cfg_hash = $test_cfg->base_testing_cfg;

## BASIC TESTS
##############

# use test
use_ok('Bio::EnsEMBL::VEP::IDTranslator');



SKIP: {
  my $db_cfg = $test_cfg->db_cfg;

  eval q{
    use Bio::EnsEMBL::Test::TestUtils;
    use Bio::EnsEMBL::Test::MultiTestDB;
    1;
  };

  my $can_use_db = $db_cfg && scalar keys %$db_cfg && !$@;

  ## REMEMBER TO UPDATE THIS SKIP NUMBER IF YOU ADD MORE TESTS!!!!
  skip 'No local database configured', 18 unless $can_use_db;

  my $multi = Bio::EnsEMBL::Test::MultiTestDB->new('homo_vepiens') if $can_use_db;
  
  my $idt = Bio::EnsEMBL::VEP::IDTranslator->new({%$cfg_hash, %$db_cfg, offline => 0, database => 1});
  ok($idt, 'new is defined');

  is($idt->param('input_data', 'rs142513484'), 'rs142513484', 'set input_data');

  is(ref($idt), 'Bio::EnsEMBL::VEP::IDTranslator', 'check class');

  ok($idt->init(), 'init');
  ok($idt->{parser}, 'init sets parser');
  ok($idt->{input_buffer}, 'init sets input_buffer');

  $idt->reset();
  ok(!$idt->{parser}, 'reset deletes parser');
  ok(!$idt->{input_buffer}, 'reset deletes input_buffer');
  ok(!$idt->param('input_data'), 'reset deletes input_data');

  throws_ok {$idt->translate()} qr/No input data/, 'translate - no input';

  foreach my $input(qw(
    rs142513484
    21:g.25585733C>T
    ENST00000352957.8:c.991G>A
    NM_017446.3:c.991G>A
    ENSP00000284967.6:p.Ala331Thr
    NP_059142.2:p.Ala331Thr
  )) {
    is_deeply(
      $idt->translate($input),
      [
        {
          "hgvsp" => [
             "ENSP00000284967.6:p.Ala331Thr",
             "NP_059142.2:p.Ala331Thr",
             "XP_011527953.1:p.Ala289Thr"
          ],
          "hgvsc" => [
             "ENST00000307301.11:c.*18G>A",
             "ENST00000352957.8:c.991G>A",
             "NM_017446.3:c.991G>A",
             "NM_080794.3:c.*18G>A",
             "XM_011529651.1:c.865G>A"
          ],
          "input" => $input,
          "id" => [
             "rs142513484"
          ],
          "hgvsg" => [
             "21:g.25585733C>T"
          ]
        }
      ],
      'translate - '.$input
    );
  }

  my $bak = $idt->param('fields');
  $idt->param('fields', ['hgvsg']);
  is_deeply(
    $idt->translate("rs142513484"),
    [
      {
        "input" => "rs142513484",
        "hgvsg" => [
           "21:g.25585733C>T"
        ]
      }
    ],
    'translate - limit fields'
  );
  $idt->param('fields', $bak);

  $idt->param('input_file', $test_cfg->{idt_vcf});
  my $results = $idt->translate_all();

  is_deeply(
    [map {$_->{hgvsg}->[0]} @$results],
    ['21:g.25585733C>T', '21:g.25587701T>C', '21:g.25587758G>A'],
    'translate_all'
  );
};

done_testing();