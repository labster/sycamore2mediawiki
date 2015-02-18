# sycamore2mediawiki
Convert Sycamore and WikiSpot wikicode to Mediawiki format

Summary
=======

Sycamore is the wiki software that powers Wikispot.org, as well as a host of other services.  As Wiki Spot is turning off its namesake service in a few weeks, a way out will be necessary for the users who need a new place to have a wiki.

This software converts wikicode from Sycamore syntax to MediaWiki.  Mediawiki is the software best known for powering Wikipedia, but it is used on a large range of wikis, is actively developed, and is relatively secure.  It's also kind of a mess in its internals, but this is because it's written in PHP and is highly customizable.

Status
======

Not even an alpha release yet.  Use at your own peril.  If you have development skills, ask for a commit bit or send me pull requests please. :)

How to Use
==========

Yeah, not even close to ready.  Wait a week.

Where to get new hosting
========================

Personally, I recommend [Orain](https://meta.orain.org/wiki/) as a non-profit, free host of Mediawiki wikis.  Their service fits the same domain of wikis that Wikispot used to host.  Orain does not use advertising.

Other options include ShoutWiki and Wikia.  Wikia has great search engine coverage and a large community -- but once content goes up there, it will never ever come down.  Wikia is know to be aggressive with advertising and keeping as much content as possible.

Development Plan
================

* Get a parser working
* Write tests
* Develop scripts that convert from Sycamore export format to Mediawiki format.

Authors
=======

Brent Laabs <bslaabs@gmail.com>
