#!/usr/bin/perl
use warnings;
use strict;
use Date::Simple qw(date);
use CGI::Carp qw(fatalsToBrowser);
use CGI;
use HTML::Entities;
use HTML::Template;
use Config::File;
use HTML::Calendar::Simple;
use Cache::FileCache;
use lib 'lib';
use IrcLog qw(get_dbh gmt_today);

my $q = new CGI;
my $channel = $q->url_param('channel');
print "Content-Type: text/html; charset=utf-8\n\n";

my $cache_name = $channel . '|' . gmt_today();

my $cache = new Cache::FileCache( { 
		namespace 		=> 'irclog',
		} );
my $data = $cache->get($cache_name);
if (! defined $data){
    $data = get_channel_index();
    $cache->set($data, '2 hours');
}
print $data;

sub get_channel_index {

    my $conf = Config::File::read_config_file('cgi.conf');
    my $base_url = $conf->{BASE_URL} || q{/};
    my $t = HTML::Template->new(
            filename            => 'template/channel-index.tmpl',
            die_on_bad_params   => 0,
    );

    my $dbh = get_dbh();

    # we are evil and create a calendar entry for month between the first 
    # and last date
    my $q3 = $dbh->prepare('SELECT DISTINCT day FROM irclog WHERE channel = ?');


    $t->param(CHANNEL  => $channel);
    $t->param(BASE_URL => $base_url);
    $t->param(CALENDAR => calendar_for_channel($channel, $q3, $base_url)); 
    return $t->output;
}

sub calendar_for_channel {
    my ($channel, $query, $base_url)  = @_;
    $query->execute('#' . $channel);
    $channel =~ s/\A\#//smx;
    my %cals;
    while (my ($day) = $query->fetchrow_array){
        # extract year and month part: (YYYY-MM)
        my $key = substr $day, 0, 7;
        # day
        my $d = substr $day, 8;

        # create calendar
        if (not exists $cals{$key}){
            my ($year, $month) = split m/-/smx, $key;
            $cals{$key} = HTML::Calendar::Simple->new({
                    year  => $year,
                    month => $month,
                    });
        }

        # populate calendar with links
        $cals{$key}->daily_info({
                day      => $d,
                day_link => "$base_url$channel/$day",
                });
    }

    # now generate the HTML output
    my $html = q{};
    my $sorter = sub {
        my ($l, $r) = @_;
        return 12 * $cals{$l}->year + $cals{$l}->month
            <=> 12 * $cals{$r}->year + $cals{$r}->month;
    };

    for my $cal (reverse sort { &$sorter($a, $b) } keys %cals){
        $html .= qq{\n<div class="calendar">}
            . $cals{$cal}->calendar_month
            . qq{</div>\n}
    }

    return $html;
}

# vim: syn=perl sw=4 ts=4 expandtab
