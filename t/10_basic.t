use strict;
use warnings;
use WWW::KGS::GameArchives;
use Test::More tests => 6;

my $archives = WWW::KGS::GameArchives->new;

isa_ok $archives, 'WWW::KGS::GameArchives';

can_ok $archives, qw(
    base_uri
    user_agent
    _has_user_agent
    _build_user_agent
    _scraper
    _build_scraper
    scrape
    query
);

isa_ok $archives->base_uri, 'URI';
is $archives->base_uri->as_string, 'http://www.gokgs.com/gameArchives.jsp';

isa_ok $archives->_scraper, 'Web::Scraper';
isa_ok $archives->user_agent, 'LWP::UserAgent';
