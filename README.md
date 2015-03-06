# sycamore2mediawiki
Convert Sycamore and WikiSpot wikicode to Mediawiki format

Summary
-------

Sycamore is the wiki software that powers Wikispot.org, as well as a host of other services.  As Wiki Spot is turning off its namesake service in a few weeks, a way out will be necessary for the users who need a new place to have a wiki.

This software converts wikicode from Sycamore syntax to MediaWiki.  Mediawiki is the software best known for powering Wikipedia, but it is used on a large range of wikis, is actively developed, and is relatively secure.  It's also kind of a mess in its internals, but this is because it's written in PHP and is highly customizable.

Status
------

Not even an alpha release yet.  Use at your own peril.  If you have development skills, ask for a commit bit or send me pull requests please. :)

How to Use
----------

Currently, all you can do is convert wikicode.  Note that we're still in beta, so these transformations aren't perfect. If you want to do this,
try:

	my $newpage = MediaWiki::FromSycamore->convert_wikicode( $a_page_of_wiki_markup );

Support for reading XML dumps directly is forthcoming.  Stay tuned.

The other thing you might be interested in is changing the way Sycamore
macros convert into new wikicode.  We have a few defaults, but you might
just want to choose a new template name for Mediawiki, or perhaps eliminate the content of said macros altogether.

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


Where to get new hosting
------------------------

Personally, I recommend [Orain](https://meta.orain.org/wiki/) as a non-profit, free host of Mediawiki wikis.  Their service fits the same domain of wikis that Wikispot used to host.  Orain does not use advertising.

Other options include [ShoutWiki](http://www.shoutwiki.com/wiki/) and [Wikia](http://www.wikia.com/Wikia).  Wikia has great search engine coverage and a large community -- but once content goes up there, it will never ever come down.  Wikia is know to be aggressive with advertising and keeping as much content as possible.

Development Plan
----------------

* Get a parser working
* Write tests
* Develop scripts that convert from Sycamore export format to Mediawiki format.

Authors
-------

Brent Laabs <bslaabs@gmail.com>
