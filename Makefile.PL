use inc::Module::Install;

all_from 'lib/Net/KGS/GameArchives.pm';
readme_from 'lib/Net/KGS/GameArchives.pm';

repository 'https://github.com/anazawa/p5-Net-KGS-GameArchives';

requires 'Web::Scraper';
requires 'URI';
requires 'Carp';

test_requires 'Test::More' => '0.98';

tests 't/*.t xt/*.t';

WriteAll;
