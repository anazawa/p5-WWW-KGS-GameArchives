use strict;
use warnings;
use feature qw/say/;
use Cache::FileCache;
use Getopt::Long;
use Net::KGS::GameArchives;
use Time::Piece;

my $cache = Cache::FileCache->new({
    cache_root         => './cache',
    namespace          => 'Net::KGS::GameArchives',
    default_expires_in => '1M',,
});

GetOptions(\my %query, qw/user=s year=i month=i old_accounts tags/)
    or exit 1;

my $game_archives = Net::KGS::GameArchives->new(
    #cache => $cache,
    %query,
);

my $result = $game_archives->parse;
my @games = @{ $result->games };

say "KGS Game Archives";

if ( $result->tagged_by ) {
    print "Games tagged by ", $result->tagged_by;
}
else {
    print "Games of KGS player ", $query{user};
}

if ( $query{month} ) {
    my $year = $query{year} || gmtime->year;
    print ", $year-$query{month}";
}
elsif ( $query{year} ) {
    print ", $query{year}";
}
say " (" . @games . " games)";

for my $game ( @games ) {
    say "-----";
    say "Viewable?: ", $game->is_viewable ? "Yes (" . $game->kifu_url . ")" : "No";
    say "Editor: ", $game->editor->as_string if $game->has_editor;
    say "White: ", join ", ", map { $_->as_string } @{ $game->white } if $game->has_white;
    say "Black: ", join ", ", map { $_->as_string } @{ $game->black } if $game->has_black;
    say "Handicap: ", $game->handicap if $game->has_handicap;
    say "Size: ", $game->size, 'x', $game->size;
    say "Start Time: ", $game->start_time;
    say "Type: ", $game->type;
    say "Result: ", $game->result;
    say "Tag: ", $game->tag if $game->has_tag;
}



