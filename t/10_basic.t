use strict;
use warnings;
use WWW::KGS::GameArchives;
use Test::More tests => 3;

my $archives = WWW::KGS::GameArchives->new;

isa_ok $archives, 'WWW::KGS::GameArchives';
can_ok $archives, qw( user_agent base_uri query scrape );
is $archives->base_uri, 'http://www.gokgs.com/gameArchives.jsp';
