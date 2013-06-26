package Net::KGS::GameArchives;
use Mouse;
use Net::KGS::GameArchives::Result;
use URI;
use Web::Scraper;

has base_url => (
    is => 'ro',
    isa => 'URI',
    default => sub { URI->new('http://www.gokgs.com/gameArchives.jsp') },
);

has param => (
    is => 'rw',
    isa => 'HashRef',
    default => sub { {} },
);

sub search {
    my $self  = shift;
    my %param = @_ == 1 ? %{$_[0]} : @_;

    my $request_url = $self->base_url->clone;
    $request_url->query_form( %{ $self->param }, %param );

    my $result = scraper {
        process '//table[1]//tr', 'games[]' => scraper {
            process '//td', 'summary[]' => 'TEXT';
            process '//a[contains(@href,".sgf")', 'kifu_url' => '@href';
            process '//td[2]//a', 'white[]' => 'TEXT';
            process '//td[3]//a', 'black[]' => 'TEXT';
        };
        process '//a[contains(@href,".zip")]', 'zip_url' => '@href';
        process '//a[contains(@href,".tar.gz")]', 'tgz_url' => '@href';
    }->scrape( $request_url );

    my $games = $result->{games};
    shift @$games; # remove table heads

    for my $game ( @$games ) {
        my $summary = delete $game->{summary};
        if ( @$summary == 6 ) { # <td colspan="2">
            my $users = delete $game->{white};
            if ( @$users == 3 ) { # Review
                $game->{editor} = $users->[0];
                $game->{white}  = [ $users->[1] ];
                $game->{black}  = [ $users->[2] ];
            }
            elsif ( @$users == 5 ) { # Rengo Review
                $game->{editor} = $users->[0];
                $game->{white}  = [ @{$users}[1,2] ];
                $game->{black}  = [ @{$users}[3,4] ];
            }
            else { # Demonstration
                delete $game->{black};
                $game->{editor} = $users->[0];
            }
            $game->{is_viewable} = $summary->[0];
            $game->{setup}       = $summary->[2];
            $game->{start_time}  = $summary->[3];
            $game->{type}        = $summary->[4];
            $game->{result}      = $summary->[5];
        }
        else {
            $game->{is_viewable} = $summary->[0];
            $game->{setup}       = $summary->[3];
            $game->{start_time}  = $summary->[4];
            $game->{type}        = $summary->[5];
            $game->{result}      = $summary->[6];
        }
    }

    Net::KGS::GameArchives::Result->new( $result );
}

__PACKAGE__->meta->make_immutable;

1;
