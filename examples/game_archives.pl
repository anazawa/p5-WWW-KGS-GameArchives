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

GetOptions(\my %query, qw/user=s year=i month=i oldAccounts=s/);

my $game_archives = Net::KGS::GameArchives->new(
    cache => $cache,
);

my $result = $game_archives->search( %query );
my @games = @{ $result->games };

say "KGS Game Archives";

print "Games of KGS player ", $query{user};
if ( $query{year} and $query{month} ) {
    print ", $query{year}-$query{month}";
}
elsif ( $query{year} ) {
    print ", $query{year}";
}
say " (" . @games . " games)";

for my $game ( @games ) {
    say "-----";
    say "Viewable?: ", $game->is_viewable ? "Yes (" . $game->kifu_url . ")" : "No";
    say "Editor: ", $game->editor if $game->has_editor;
    say "White: ", join ", ", @{ $game->white } if $game->has_white;
    say "Black: ", join ", ", @{ $game->black } if $game->has_black;
    say "Setup: ", $game->setup;
    say "Start Time: ", $game->start_time;
    say "Type: ", $game->type;
    say "Result: ", $game->result;
}



