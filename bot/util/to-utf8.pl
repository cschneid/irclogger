#!/usr/bin/perl
use warnings;
use strict;
use IrcLog qw(get_dbh);
use IrcLog::WWW qw(my_decode);
use Encode qw(encode);

my $dbh = get_dbh;
#$dbh->do("ALTER TABLE irclog charset=utf8");

my $read = $dbh->prepare('SELECT id, line FROM irclog');
my $write = $dbh->prepare('UPDATE irclog SET line = ? WHERE id = ?');

$read->execute();
my $c = 0;
while (my ($id, $line) = $read->fetchrow_array()){
	$write->execute(my_decode($line), $id);
	$c++;
	if ($c % 1000 == 0){
		print "Count: $c\n";
	}
}
print "$c lines done\n";
