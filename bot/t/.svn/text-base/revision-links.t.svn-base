use strict;
use warnings;
use Test::More tests => 6;

BEGIN { use_ok('IrcLog::WWW'); }

sub link_text {
    my $text = shift;
    my $c = 1;
    my $h = IrcLog::WWW::message_line({
            id          => 1,
            nick        => 'somebody',
            timestamp   => gmtime,
            message     => $text,
            line_number => 1,
            prev_nick   => '',
            colors      => [],
            self_url    => '/',
            channel     => 'perl6',
            },
            \$c
        );
    my $msg = $h->{MESSAGE};
    if ($msg =~ m{<a [^>]+>([^<]*)</a>}){
        return $1;
    } else {
        return undef;
    }
}

my @tests = (
        {
            test    => 'r',
            result  => undef,
            desc    => qq{single 'r' doesn't linkify},
        },
        {
            test    => 'r123',
            result  => 'r123',
            desc    => qq{'r123' linkifies},
        },
        {
            test    => 'br123',
            result  => undef,
            desc    => qq{revision links within words don't linkify},
        },
        {
            test    => 'r0123',
            result  => undef,
            desc    => 'r0\d+ does not linkify',
        },
        {
            test    => 'r' . chr(2) . '123',
            result  => 'r123',
            desc    => 'revision links with chr(02) after the r still work',
        }
        );

for my $h (@tests){
    is(link_text($h->{test}), $h->{result}, $h->{desc});
}
