use strict;
use warnings;
use Data::Dumper;
use Net::KGS::GameArchives;

my $archives = Net::KGS::GameArchives->new;
my $result = $archives->query( user => 'hvk', month => 7 );

{
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Indent = 1;
    print Dumper $result;
}
