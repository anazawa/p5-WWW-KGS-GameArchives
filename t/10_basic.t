use strict;
use warnings;
use Net::KGS::GameArchives;
use Test::More tests => 3;

my $archives = Net::KGS::GameArchives->new;

isa_ok $archives, 'Net::KGS::GameArchives';
can_ok $archives, qw( user_agent base_uri query scrape );
is $archives->base_uri, 'http://www.gokgs.com/gameArchives.jsp';
