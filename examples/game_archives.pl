use strict;
use warnings;
use feature qw/say/;
use Cache::FileCache;
use Getopt::Long;
use Net::KGS::GameArchives;
use Time::Piece;

my $cache = Cache::FileCache->new({
    cache_root         => '/tmp',
    namespace          => 'Net::KGS::GameArchives',
    default_expires_in => '30m',
});

GetOptions(\my %query, qw/user=s year=i month=i day=i oldAccounts=s/);

my $game_archives = Net::KGS::GameArchives->new(
    cache => $cache,
    user  => delete $query{user},
);

my $result = $game_archives->search( %query );
my @games = @{ $result->games };

#use Devel::Peek;
#use utf8;
#my $s = $games[0]->setup;
#Dump $s;

#warn $s eq "19\x{d7}19 " ? 1 : 0;

warn $games[0]->white_rank->[0];
#warn '"', $games[0]->result, '"';


__END__

#binmode STDOUT => ':utf8';

say "KGS Game Archives";

print "Games of KGS player ", $game_archives->user;
if ( $query{year} and $query{month} and $query{day} ) {
    print ", $query{year}-$query{month}-$query{day}";
}
elsif ( $query{year} and $query{month} ) {
    print ", $query{year}-$query{month}";
}
elsif ( $query{year} ) {
    print ", $query{year}";
}
say " (" . @games . " games)";

for my $game ( @games ) {
    say "-----";
    say "Viewable?: ", $game->is_viewable ? "Yes (" . $game->kifu_url . ")" : "No";
    say "Editor: ", $game->editor if $game->editor;
    say "White: ", join ", ", @{ $game->white } if $game->white;
    say "Black: ", join ", ", @{ $game->black } if $game->black;
    say "Setup: ", $game->setup;
    say "Start Time: ", $game->start_time;
    say "Type: ", $game->type;
    say "Result: ", $game->result;
}



