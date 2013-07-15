use strict;
use warnings;
use WWW::KGS::GameArchives;
use Test::More tests => 3;
use t::Util qw/slurp/;

my $datadir = 't/data/user';
my $archives = WWW::KGS::GameArchives->new;

my $input = slurp("$datadir/input.html");

my $got = $archives->scrape( \$input, $archives->base_uri );
ok delete $got->{version} == $archives->VERSION;

my $expected = do "$datadir/expected.pl";
ok delete $expected->{version} >= 0.03;

is_deeply $got, $expected;
