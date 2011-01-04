use strict;
use warnings;
use Test::More tests => 5;

BEGIN { use_ok('IrcLog::WWW'); }

ok( IrcLog::WWW::http_header() =~ m/^Status: 200 OK$/sm, "Return status is '200 OK'");
{
	local $ENV{HTTP_ACCEPT};
	ok( IrcLog::WWW::http_header() 
			=~ m{^Content-Type: text/html; charset=utf-8$}sm, 
		"Default Content-Type is text/html, charset is utf-8");
}

{
	local $ENV{HTTP_ACCEPT} = qq{application/xhtml+xml;q=1,text/xhtml;qs=0.3};
	ok( IrcLog::WWW::http_header() 
			=~ m{^Content-Type: application/xhtml\+xml; charset=utf-8$}sm, 
		"Environment HTTP_ACCEPT changes Content-Type to xhtml");

	ok( IrcLog::WWW::http_header({no_xhtml => 1}) 
			=~ m{^Content-Type: text/html; charset=utf-8$}sm, 
		"Option {no_xhtml => 1} overwrites Environment variable");
}

