use strict;
use warnings;
use feature qw/say/;
use Getopt::Long;
use Net::KGS::GameArchives;
use Time::Piece;
use Cache::FileCache;

my $cache = Cache::FileCache->new({
    cache_root         => './cache',
    namespace          => 'Net::KGS::GameArchives',
    default_expires_in => '5m',
});

GetOptions(\my %query, qw/user=s year=i month=i oldAccounts=s/);

my $game_archives = Net::KGS::GameArchives->new( cache => $cache );
my $result = $game_archives->search( %query );

my $user = $query{user};
my $total_hits = scalar @{ $result->games };

my @num2month = ( undef, qw(Jan Feb Mar Apr May Jun Aug Sep Oct Nov Dec) );
my $now = localtime;
my $year = $query{year} || $now->year;
my $month = $num2month[ $query{month} || $now->mon ];

binmode STDOUT => ':utf8';

say "KGS Game Archives";
say "Games of KGS player $user, $month $year ($total_hits games)";
say ".zip format: ", $result->zip_url if $result->zip_url;
say ".tar.gz format: ", $result->tgz_url if $result->tgz_url;

for my $game ( @{$result->games} ) {
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


