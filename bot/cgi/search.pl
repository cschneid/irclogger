#!/usr/bin/perl
use warnings;
use strict;
use Date::Simple qw(today);
use CGI::Carp qw(fatalsToBrowser);
use Encode::Guess;
use CGI;
use Encode;
use HTML::Entities;
use HTML::Template;
use Config::File;
use List::Util qw(min max);
use lib 'lib';
use IrcLog qw(get_dbh);
use IrcLog::WWW qw(http_header message_line my_encode my_decode);
use utf8;
#use Data::Dumper;
#$DATA::Dumper::indent = 0;

my $conf = Config::File::read_config_file("cgi.conf");
my $base_url = $conf->{BASE_URL} || "/";
my $days_per_page = 10;
my $lines_per_day = 50; # not yet used

my $lines_of_context = 2;

my $q = new CGI;
print http_header();
my $t = HTML::Template->new(
        filename => "template/search.tmpl",
		global_vars => 1,
        die_on_bad_params => 0,
);
$t->param(BASE_URL => $base_url);
my $start = $q->param("start") || 0;

my $offset = $q->param("offset") || 0;
die unless $offset =~ m/^\d+$/;

my $dbh = get_dbh();
{
    # populate the select box with possible channel names to search in
    my @channels; 
    my $q1 = $dbh->prepare("SELECT DISTINCT channel FROM irclog ORDER BY channel");
    $q1->execute();
    my $ch = $q->param('channel') || 'perl6';
	$ch =~ s/^\#//;
    $t->param(CURRENT_CHANNEL => $ch, CHANNEL => $ch);
    while (my @row = $q1->fetchrow_array){
		$row[0] =~ s/^\#//;
        if ($ch eq $row[0]){
            push @channels, {CHANNEL => $row[0], SELECTED => 1};
        } else {
            push @channels, {CHANNEL => $row[0]};
        }
    }

    # populate the size of the select box with channel names
    $t->param(CHANNELS => \@channels);
    if (@channels >= 5 ){
        $t->param(CH_COUNT => 5);
    } else {
        $t->param(CH_COUNT => scalar @channels);
    }
}

my $nick = decode('utf8', $q->param('nick') || '');
#my $qs = decode('utf8', $q->param('q') || '');
my $qs = $q->param('q') || '';
$qs = my_decode($qs);


$t->param(NICK => encode('utf8', $nick));
$t->param(Q => $qs);
my $short_channel = decode('utf8', $q->param('channel') || 'perl6');
# guard against old URLs:
$short_channel =~ s/^#//;
my $channel = '#' .$short_channel;


if (length($nick) or length($qs)){



	my @sql_conds = ('channel = ? AND NOT spam');
	my @args = ($channel);
	if (length $nick){
		push @sql_conds, '(nick = ? OR nick = ?)';
		push @args, $nick, "* $nick";
	}
	if (length $qs) {
		push @sql_conds, 'MATCH(line) AGAINST(?)';
		push @args, $qs;
	}
	my $sql_cond = 'WHERE ' . join(' AND ', @sql_conds);

#	warn $sql_cond;
#	warn join '|', @args;

    my $q0 = $dbh->prepare("SELECT COUNT(DISTINCT day) FROM irclog $sql_cond");
    my $q1 = $dbh->prepare("SELECT DISTINCT day FROM irclog $sql_cond "
			. "ORDER BY day DESC LIMIT $days_per_page OFFSET $offset");
    my $q2 = $dbh->prepare("SELECT id, day FROM irclog "
			. $sql_cond . ' AND day = ? ORDER BY id');
	my $q3 = $dbh->prepare('SELECT id, timestamp, nick, line FROM irclog '
			. 'WHERE day = ? AND id >= ? AND id <= ? ORDER BY id ASC');

    $q0->execute(@args);
    my $result_count = ($q0->fetchrow_array);
    $t->param(DAYS_COUNT => $result_count);
    $t->param(DAYS_LOWER => $offset + 1);
    $t->param(DAYS_UPPER => min($offset + $days_per_page, $result_count));

    my @result_pages;
    my $p = 1;
    for (my $o = 0; $o <= $result_count; $o += $days_per_page){
	    push @result_pages, { OFFSET => $o, PAGE => $p++ };
    }
    $t->param(RESULT_PAGES => \@result_pages);

    $q1->execute(@args);
    my @days;
    my $c = 0;

	my $line_number = 1; # not really needed any more

    while (my @row = $q1->fetchrow_array){

		# should be smaller than any index in the `id` column:
		my $last_context = -5e10;

        my $prev_nick = "";
        my @lines;
        $q2->execute(@args, $row[0]);
        while (my ($found_id, $found_day) = $q2->fetchrow_array){

			# determine the context range:
			my $lower = max($last_context + 1, $found_id - $lines_of_context);
			my $upper = $found_id + $lines_of_context;
			$last_context = $upper;

			# retrieve context from database
			$q3->execute( $found_day, $lower, $upper );
			while (my @r2 = $q3->fetchrow_array){
				my %args = (
							id			=> $r2[0],
							nick		=> decode('utf8', $r2[2]),
							timestamp	=> $r2[1], 
							message		=> $r2[3],
							line_number => $line_number++, 
							prev_nick	=> $prev_nick, 
							colors		=> [], 
							link_url	=> $base_url . "out.pl?channel=$short_channel;date=$row[0]",
							channel		=> $channel,
							date		=> $found_day,
						);
				$args{search_found} = 'search_found' if $r2[0] == $found_id;
			
				push @lines, message_line(
						\%args,
						\$c, 
						);   
			}
        }
        push @days, { 
            URL     => $base_url . "out.pl?channel=$short_channel;date=$row[0]",
            DAY     => $row[0],
            LINES   => \@lines,
        };
    }
    $t->param(DAYS => \@days);

}

print my_encode($t->output);
#print $t->output;

sub hexdump {
	my $str = shift;
	my $res = q{};
	for (0 .. length($str) - 1){
		$res .= sprintf "%%%x", ord(substr $str, $_, 1);
	}
	return $res;
}

sub search_with_context {
    my ($q2, $q3) = @_;
    my @ids;
    my $day;
    ($ids[0], $day) = $q2->fetchrow_array();



}

