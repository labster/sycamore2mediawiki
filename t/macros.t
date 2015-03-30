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
is convert("[[HEART]] "), "♥ ", "macros are case insensitive";

is convert("foo[[nbsp]]bar"), "foo&nbsp;bar", "[[nbsp]]";
is convert("[[stop]]"), "{{stop}}", "[[stop]]";
is convert("[[MailTo(foo ARR ATT example XDOT com)]]"), "foo\@example.com", "[[MailTo]]";


is convert("1[[FootNote(hey)]]"), '1<ref>hey</ref>', "basic footnote";
is convert("1[[FootNote(hey, everyone!)]]"), '1<ref>hey, everyone!</ref>', "footnote with comma";



is convert('[[Anchor(matey arr)]]'), '<div id="matey_arr"></div>', "[[Anchor]]";
is convert('[[PageCount]]'), '{{NUMBEROFPAGES}}', "[[PageCount]]";

is convert(qq{[[Image(image.jpg, thumbnail, "A photo by ["users/PhilipNeustrom"]")]]}),
	qq{[[File:image.jpg|thumb|A photo by [[User:PhilipNeustrom]]]]},
	"Image captions ok, usernames";
is convert(qq{[[Image(image.jpg, right, 279, thumbnail, "Library Stacks")]]}),
	qq{[[File:image.jpg|thumb|right|279px|Library Stacks]]},
	"floating image with size";
is convert(qq/[[Image(basic.png)]]/),
	"[[File:basic.png]]",
	"basic image";
is convert(qq/[[Image(basic.png, "a pic")]]/),
	"[[File:basic.png|frame|a pic]]",
	"caption forces 'frame'";

is convert(qq/[[Include(Foo)]]/), "{{:Foo}}", "Main namespace include";
is convert("[[Include(Users/Bar/Baz)]]"), "{{User:Bar/Baz}}", "User ns transclude";


done_testing;
