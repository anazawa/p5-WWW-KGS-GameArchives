use inc::Module::Install;

all_from 'lib/Net/KGS/GameArchives.pm';
readme_from 'lib/Net/KGS/GameArchives.pm';

repository 'https://github.com/anazawa/p5-Net-KGS';

requires 'Moo';
requires 'Web::Scraper';
requires 'parent';
requires 'Time::Piece';
requires 'URI';

test_requires 'Test::More' => '0.98';

tests 't/*.t xt/*.t';

WriteAll;
