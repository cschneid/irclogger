#!/usr/bin/perl
use CGI::Carp qw(fatalsToBrowser);
use strict;
use warnings;
use Config::File;
use HTML::Template;
use lib 'lib';
use IrcLog qw(get_dbh);
use IrcLog::WWW qw(http_header);

use Cache::FileCache;

print http_header();
my $cache = new Cache::FileCache( { 
		namespace 		=> 'irclog',
		} );

my $data;
$data = $cache->get('index');
if ( ! defined $data){
	$data = get_index();
	$cache->set('index', $data, '5 hours');
}
print $data;

sub get_index {

	my $dbh = get_dbh();

	my $conf = Config::File::read_config_file('cgi.conf');
	my $base_url = $conf->{BASE_URL} || q{/irclog/};

	my $sth = $dbh->prepare("SELECT DISTINCT channel FROM irclog");
	$sth->execute();

	my @channels;

	while (my @row = $sth->fetchrow_array()){
		$row[0] =~ s/^\#//;
		push @channels, { channel => $row[0] };
	}

	my $template = HTML::Template->new(
			filename => 'template/index.tmpl',
			loop_context_vars   => 1,
			global_vars         => 1,
            die_on_bad_params   => 0,
    );
	$template->param(BASE_URL => $base_url);
	$template->param( channels => \@channels );


	return $template->output;
}
