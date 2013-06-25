use strict;
use Test::More tests => 5;

BEGIN {
    use_ok 'WebService::Simple::KGS::GameArchives';
    use_ok 'WebService::Simple::Parser::KGS::GameArchives';
    use_ok 'Net::KGS::GameArchives';
    use_ok 'Net::KGS::GameArchives::Result';
    use_ok 'Net::KGS::GameArchives::Result::Game';
}
