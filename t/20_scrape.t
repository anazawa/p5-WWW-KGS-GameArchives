use strict;
use warnings;
use Net::KGS::GameArchives;
use Test::More tests => 1;

open my $fh, '<:encoding(UTF-8)', 't/input.txt';
my $input = join q{}, <$fh>;
close $fh;

my $archives = Net::KGS::GameArchives->new;
my $got = $archives->scrape( \$input, $archives->base_uri );

my $expected = do 't/expected.txt';

is_deeply $got, $expected;
