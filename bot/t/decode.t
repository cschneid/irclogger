use strict;
use warnings;
use Encode qw(encode decode);

#use Smart::Comments;
use Test::Base tests => 10;
use IrcLog::WWW qw(my_encode);

run {
    my $block = shift;
    my $name = $block->name;
    my $str = $block->str;
    for my $enc (split /\s+/, $block->enc) {
        my $utf8 = decode('utf8', $str);
        my $bytes = encode($enc, $utf8);
        ### $bytes
        my $got = my_encode($bytes);
        is $got, $str, "$name - $enc";
    }
};

__DATA__

=== TEST 1: Simplified Chinese
--- str: 你好，world！
--- enc: GB2312 big5 utf8



=== TEST 2: Traditional Chinese
--- str: 我想要你 hello 的身份證號碼
--- enc: big5 utf8



=== TEST 3: latin-1
--- str: gaal: mØØse!
--- enc: latin1 utf8



=== TEST 4: more latin
--- str
test: umlaute: ä ü ö
--- enc: latin1 utf8



=== TEST 5: unknown encodings...
--- str
<moritz> more unicode test: 수도쿠
--- enc: utf8

