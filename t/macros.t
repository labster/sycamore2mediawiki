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

is convert("[[heart]] "), "♥ ", "[[heart]]";
is convert("foo[[nbsp]]bar"), "foo&nbsp;bar", "[[nbsp]]";
is convert("[[stop]]"), "{{stop}}", "[[stop]]";

is convert(qq{[[Image(image.jpg, thumbnail, "A photo by ["users/PhilipNeustrom"]")]]}),
	qq{[[File:image.jpg|thumb|A photo by [[User:PhilipNeustrom]]]]},
	"Image captions ok, usernames";



done_testing;
