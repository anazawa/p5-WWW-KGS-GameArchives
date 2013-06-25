package WebService::Simple::KGS::GameArchives;
use strict;
use warnings;
use parent 'WebService::Simple';

__PACKAGE__->config(
    base_url => 'http://www.gokgs.com/gameArchives.jsp',
    response_parser => { module => 'KGS::GameArchives' },
);

1;
