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

is convert('["Basic Link"]'), "[[Basic Link]]", "basic linking";
is convert('["Link" with alt]'), "[[Link|with alt]]", "link with alt";
is convert('[http://example.com alt]'), '[http://example.com alt]', "http link unchanged";

is convert("#redirect Foo page\n"), "#redirect [[Foo page]]\n",
	"redirect";

is convert(qq/ * Indent 1\n  * Indent 2/),
  qq/* Indent 1\n** Indent 2/, "bullet indentation";
is convert( qq/ Space indentation\n   level 3/),
	qq/: Space indentation\n::: level 3/, "space indent to colons";
is convert( " 1. Numeric\n 1. List"),
	"# Numeric\n# List", "basic numeric indentation";


is convert("''italic''"), "''italic''", "italic no change";
is convert("A ,,subscript,,here"), "A <sub>subscript</sub>here",
	"subscripts";
is convert("A ^*^ superscript"), "A <sup>*</sup> superscript",
	"superscripts";
is convert("--> foo bar <--"), "<center> foo bar </center>",
	"centering";
is convert("A__under__line"), "A<u>under</u>line",
	"underlines";


is convert("pret-X--a--X-porter"), "pret-<strike>a</strike>-porter",
	"strikethrough";
is convert("pret---XaX---porter X--"), "pret—Xa<strike>-porter </strike>",
	"strikethrough doesn't do ---";
is convert("X--FooX-- and --XBar--X"), "<strike>Foo</strike> and <strike>Bar</strike>",	"strikethrough --X and X-- equivalence";

is convert("= Header ="), "== Header ==",
	"top level headers are at least ==";
is convert(" == Indented header =="),
	"=== Indented header ===", "Indentations removed from headers";


done_testing;