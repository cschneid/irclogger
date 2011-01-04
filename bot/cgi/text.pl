#!/usr/bin/perl
use warnings;
use strict;
use Carp qw(confess);
use CGI::Carp qw(fatalsToBrowser);
use CGI;
use Encode;
use HTML::Entities;
# evil hack: Text::Table lies somewhere near /irclog/ on the server...
use lib '../lib';
use lib 'lib';
use IrcLog qw(get_dbh gmt_today);
use IrcLog::WWW qw(my_encode);
use Text::Table;

my $default_channel = 'perl6';

# End of config

my $q = new CGI;
my $dbh = get_dbh();
my $channel = $q->param('channel') || $default_channel;

my $date = $q->param('date') || gmt_today;

if ($channel !~ m/^\w+\z/sx){
    # guard against channel=../../../etc/passwd or so
    confess 'Invalid channel name';
}
my $db = $dbh->prepare('SELECT nick, timestamp, line FROM irclog '
        . 'WHERE day = ? AND channel = ? AND NOT spam ORDER BY id');
$db->execute($date, '#' . $channel);


print "Content-Type: text/html;charset=utf-8\n\n";
print <<HTML_HEADER;
<html>
<head>
<title>IRC Logs</title>
</head>
<body>
<pre>
HTML_HEADER

my $table = Text::Table->new(qw(Time Nick Message));

while (my $row = $db->fetchrow_hashref){
    next unless length($row->{nick});
    my ($hour, $minute) =(gmtime $row->{timestamp})[2,1];  
    $table->add(
            sprintf("%02d:%02d", $hour, $minute),
            $row->{nick},
            $row->{line},
            );
}
my $text = encode_entities($table, '<>&');
print encode("utf-8", $text);

print "</pre></body></html>\n"



# vim: sw=4 ts=4 expandtab
