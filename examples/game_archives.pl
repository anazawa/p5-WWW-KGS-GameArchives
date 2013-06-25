use strict;
use warnings;
use feature qw/say/;
use Net::KGS::GameArchives;

my $game_archives = Net::KGS::GameArchives->new;
my $result = $game_archives->search({ user => 'anazawa' });

for my $game ( @{$result->games} ) {
    say "-----";
    say "Viewable?: ", $game->is_viewable ? "Yes (" . $game->kifu_url .")" : "No";
    say "White: ", $game->white;
    say "Black: ", $game->black;
    say "Setup: ", $game->setup;
    say "Start Time: ", $game->start_time;
    say "Type: ", $game->type;
    say "Result: ", $game->result;
}

