package WebService::Simple::Parser::KGS::GameArchives;
use strict;
use warnings;
use parent 'WebService::Simple::Parser';
use Web::Scraper;

sub parse_response {
    my ( $self, $response ) = @_;

    my $game_archives = scraper {
        process '//p', 'archive' => scraper {
            process '//a[contains(@href,".zip")]', 'zip_url' => '@href';
            process '//a[contains(@href,".tar.gz")]', 'tgz_url' => '@href';
        };
        process '//table/tr', 'games[]' => scraper {
            process '//td', 'summary[]' => 'TEXT';
            process '//td/a', 'kifu_url' => '@href';
        };
    };

    my $result = $game_archives->scrape( $response );

    my $games = $result->{games};
    shift @$games; # remove table heads

    for my $game ( @$games ) {
        my $summary = delete $game->{summary};
        splice @$summary, 2, 0, q{} if @$summary == 6; # <td colspan="2">
        $game->{is_viewable} = $summary->[0];
        $game->{white} = $summary->[1];
        $game->{black} = $summary->[2];
        $game->{setup} = $summary->[3];
        $game->{start_time} = $summary->[4];
        $game->{type} = $summary->[5];
        $game->{result} = $summary->[6];
    }

    $result;
}

1;
