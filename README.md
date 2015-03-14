# sycamore2mediawiki
Convert Sycamore and WikiSpot wikicode to Mediawiki format

Summary
-------

Sycamore is the wiki software that powers Wikispot.org,
 as well as a host of other services.  As Wiki Spot is
 turning off its namesake service in a few weeks, a way
 out will be necessary for the users who need a new place
 to have a wiki.

This software converts wikicode from Sycamore syntax to MediaWiki.
Mediawiki is the software best known for powering Wikipedia,
but it is used on a large range of wikis, is actively developed,
and is relatively secure.  It's also kind of a mess in its internals,
but this is because it's written in PHP and is highly customizable.

Status
------

I'd say we're in a middle alpha.  It's usuable, but known to be incomplete. 
Use at your own peril.  If you have development skills,
ask for a commit bit or send me pull requests please. :)

How to Use
----------

I finally have a basic CLI utility.  You can download the repository
by git cloning the URL to your right.  In there, there's a perl script
called `sycamore2mediawiki` which does what it says on the tin.

The first argument to `sycamore2mediawiki` is an input file.  If the
input file is a XML file, it will attempt to convert the entire text
of the Sycamore wiki dump into MediaWiki format.  Otherwise, it will
assume you gave it a page of wikitext that you want to convert from
Sycamore to Mediawiki format.

The optional second argument is an output file.  If omitted, the
output is printed on the standard output (i.e. your terminal).

Convert a normal file:

	> echo '  * ["A Link" Link]' > baz.txt
	> ./sycamore2mediawiki baz.txt
	** [[A Link|Link]]

Convert an XML dump:

	> sycamore2mediawiki Wiki_dump.xml mediawiki_dump.xml files_output_directory

The last two arguments are optional here -- if you omit the output
directory, files will be parsed for renaming, but not output.

Note that we're still in beta, so these transformations aren't
perfect. Tests and feedback are welcome to get this perfect.

Known issues: crappy API.  It's hard to be motivated to do
a good design on a program that will have limited usefulness in
2 months.

Using this just to extract files
--------------------------------

You can produce an XML output file which you then throw away,
just to make an files directory.  File names are the same as
before, if unique, and with mediawiki metacharacters removed.
(That is `[/<>|]`).  If the name was not unique, the file name is
prefixed with its original Sycamore page name and two tildes (`~~`).

Because of how badly Mediawiki handles file import -- it can
only read a directory and add everything there to the wiki --
we only output the current, non-deleted revision of each file.
There is currently no way of extracting previous versions
of files, but you can probably figure out how if you need it.
Or you know, click the issues icon to the right and ask me.

Incidentally, the files are encoded in base64, which makes for
some pretty huge XML nodes.  You can manually extract file
information and pipe it to base64 on the command line, if you
need.

API
---

So, this is written in Perl -- probably badly.  I mean, at some point, I
should probably make instances of this class work.

Anyway, if you want to convert wikicode, try:

	my $newpage = MediaWiki::FromSycamore->convert_wikicode( $a_page_of_wiki_markup );

The other thing you might be interested in is changing the way Sycamore
macros convert into new wikicode.  We have a few defaults, but you might
just want to choose a new template name for Mediawiki, or perhaps eliminate
the content of said macros altogether.

	# String version (simple transforms)
	MediaWiki::FromSycamore->register_template( 'Address', 'streetaddress');
	# changes "[[Address(123 Sesame Street)]]" to
	# to "{{streetaddress|123 Sesame Street}}"

	# Subroutine version (complex)
	MediaWiki::FromSycamore->register_template( "nbsp",
		sub { '&nbsp;' });
	# changes "[[nbsp]]" to "&nbsp;" in new version

The first argument passed to the sub given in `register_template`
is the name of the macro, the second is an arrayref of the arguments.

There's more here, like XML dumps, but I'm too lazy to document right
now, just look at sycamore2mediawiki.


Where to get new hosting
------------------------

Personally, I recommend [Orain](https://meta.orain.org/wiki/) as a non-profit,
 free host of Mediawiki wikis.  Their service fits the same domain of wikis
that Wikispot used to host.  Orain does not use advertising.

Other options include [ShoutWiki](http://www.shoutwiki.com/wiki/) and
[Wikia](http://www.wikia.com/Wikia).  Wikia has great search engine coverage
and a large community -- but once content goes up there, it will never ever
come down.  Wikia is know to be aggressive with advertising and keeping
as much content as possible.

Development Plan
----------------

* Get a parser working (done)
* Write tests (mostly done)
* Develop scripts that convert from Sycamore export format to Mediawiki format (done)
* TODO: Make sure everything actually imports to Mediawiki

Authors
-------

Brent Laabs <bslaabs@gmail.com>
