use strict;
use warnings;
use feature qw/say/;
use Net::KGS::GameArchives;

my $game_archives = Net::KGS::GameArchives->new;
my $result = $game_archives->search( user => 'hvk', year => 2013, month => 5);

#use Data::Dumper;
#print Dumper $result;
#__END__

for my $game ( @{$result->games} ) {
    say "-----";
    say "Viewable?: ", $game->is_viewable ? "Yes (" . $game->kifu_url .")" : "No";
    say "Editor: ", $game->editor if $game->editor;
    say "White: ", join ", ", @{ $game->white } if $game->white;
    say "Black: ", join ", ", @{ $game->black } if $game->black;
    say "Setup: ", $game->setup;
    say "Start Time: ", $game->start_time;
    say "Type: ", $game->type;
    say "Result: ", $game->result;
}

