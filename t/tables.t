#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use lib qw< lib ../lib >;
use MediaWiki::FromSycamore;
use utf8::all;

sub convert {
	MediaWiki::FromSycamore->convert_wikicode( shift );
}

sub tb { #table boilerplate
	return "{|\n|-\n" . shift . "|}";
}


is convert(
"||foo||bar||
||baz||quux||
"),
"{|
|-
|foo
|bar
|-
|baz
|quux
|}
",
	"basic table";

is convert(
"||foo||bar||

||baz||quux||
"),
"{|
|-
|foo
|bar
|}

{|
|-
|baz
|quux
|}
",
	"2 tables";

is convert('||foo||<bgcolor="red">bar||'),
	"{|\n|-\n|foo\n| style=\"background-color: red\"|bar\n\|}\n",
	"colored cell";
is convert('||foo||<colspan="2" bgcolor="red">bar||'),
	"{|\n|-\n|foo\n| colspan=\"2\" style=\"background-color: red\"|bar\n\|}\n",
	"colspan";
is convert('||foo||<#cccccc(50%v-2>bar||'),
	"{|\n|-\n|foo\n| align=\"left\" colspan=\"2\" valign=\"bottom\" style=\"background-color: #cccccc; width: 50%\"|bar\n\|}\n",
	"short attributes";

is convert('||baz||<rowbgcolor="cyan">quux||'),
	qq/{|\n|- style="background-color: cyan"\n|baz\n|quux\n\|}\n/,
	"row color";
is convert('||<tableclass="wikitable" tableborder="3">baz||<rowbgcolor="cyan">quux||'),
	qq/{| class="wikitable" style="border: 3px solid black"\n|- style="background-color: cyan"\n|baz\n|quux\n\|}\n/,
	"table attributes";
is convert('||<tableborder="3" tablebordercolor="#999" tablebgcolor="magenta">baz||quux||'),
	qq/{| style="background-color: magenta; border: 3px solid #999"\n|-\n|baz\n|quux\n\|}\n/,
	"table border with bordercolor and background";

done_testing;
