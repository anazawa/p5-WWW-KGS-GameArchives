use inc::Module::Install;

all_from 'lib/Net/KGS/GameArchives.pm';

repository 'https://github.com/anazawa/p5-Net-KGS';

requires 'Mouse';
requires 'WebService::Simple';
requires 'Web::Scraper';
requires 'parent';
requires 'Time::Piece';

test_requires 'Test::More' => '0.98';

tests 't/*.t xt/*.t';

WriteAll;
