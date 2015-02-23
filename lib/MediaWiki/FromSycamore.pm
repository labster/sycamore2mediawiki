package MediaWiki::FromSycamore;

use strict;
use warnings;
use utf8::all;


our %macro_conversions = (
	'br' => sub { "<br/>" },
	'RecentChanges' => sub { '#REDIRECT [[Special:RecentChanges]]' },
	'stop' => 'stop',
	'Image' => \&_insert_image,
	'heart' => sub { '♥' },
	'nbsp' => sub { '&nbsp;' },
	'Anchor' => sub { "<a name=\"$_[1]\">" },
	'Comments' => 'comments',
	'MailTo' => \&_mailTo_macro,
	'TableOfContents' => sub {
		$_[1]->[0] eq 'right'
			? '<div style="float:right">__TOC__</div>'
			: '__TOC__' },
	'address' => 'address',
	'FootNote' => \&_footnote_macro,
	'PageCount' => 'NUMBEROFPAGES',
	'UserCount' => 'NUMBEROFUSERS',
	'File' => sub { "[[media:$_[1]->[0]]]" },

);

sub register_template {
	my ($self, $macro, $template) = @_;
	return 0 unless defined $template;
	$macro_conversions{$macro} = $template;
	return 1;
}

sub convert_wikicode {
	my ($self, $wc) = @_;

	#redirects
	$wc =~ s/^\#redirect \K(.*)(\n|\z)/[[$1]]$2/ and return $wc;

	# since <> are significant in Mediawiki, we need to encode them
	$wc =~ s/</&lt;/g;
	$wc =~ s/>/&gt;/g;

	# Convert {{{}}} to <nowiki>
	$wc =~ s/\{\{\{ *\n(.*?) *\n\}\}\}/ _indent($1) /egx;
	$wc =~ s/\{\{\{ (.*?)\}\}\}/<nowiki>$1<\/nowiki>/gx;
	# need to hide nowiki here

	# Add HTML tags from sycamore wikicode formatting
	$wc =~ s/--\&gt;(.+?)\&lt;--/<center>$1<\/center>/g;
	$wc =~ s/\^(.+?)\^/<sup>$1<\/sup>/g;
	$wc =~ s/,,(.+?),,/<sub>$1<\/sub>/g;
	$wc =~ s/__(.+?)__/<u>$1<\/u>/g;
	$wc =~ s/--X(.+?)X--/<strike>$1<\/strike>/g;

	# Macros [[Foo(a,b)]] to {{foo|a|b}}
	$wc =~ s/\[\[ (\w+) (?: \( [^\)]+ \) )? \]\]/macro2template($1, $2)/xeg;
	# This needs to be fixed for quoted strings ^

	# Links ["foo" bar] to [[foo|bar]]
	$wc =~ s/\["([^"]+)"(?: ([^\]]+))?\]/$2 ? "[[$1|$2]]" : "[[$1]]"/eg;
	# interwiki links... for now assume a simple interwiki map
	$wc =~ s/\[wiki:([^:\n]+):"[^"]"(?: ([^\]]+))?\]/
		$3 ? "[[$1:$2]]" : "[[$1:$2|$3]]"/eg;

	# Definiton lists
	$wc =~ s/^ +([^:\n]+):: ?/; $1\n/g;

	# increase header level by one to deal with <h1> mediawiki brokenness
	$wc =~ s/^ +(=+)(.*)\1$/
		$2 eq ' ' ? '<div style="clear:both"><\/div>' :
		"=$1$2$1="/eg;

	# Convert bullet points
	my %bullets = (
		'*' => '*', '1' => '#', 'I' => '#', 'A' => '#', 'a' => '#', ' ' => ':'
	);
	$wc =~ s/^( ++)([1IaA]\.(?:\#\d++)? +|\* *)?/
		($bullets{substr(($2||" "), 0, 1)} x (length($1) || 1)) . " "/meg;
	#^ does not really support offsets, except to parse them.
	# Same with numbering systems

	$wc =~ s/---?/—/g;

	# BIG TODO: Tables


	return $wc;
}

sub _indent {
	my $text = shift;
	my @lines;
	for (split /\n/, @lines) {
		$_ = " " . $_ unless /^ /;
		push @lines, $_;
	}
	return join "\n", @lines;
}

sub macro2template {
	my ($macro, $arglist) = @_;
	my @args = split / *, */, $arglist;
	my $name = $macro_conversions{$macro};
	if (ref($name) == "CODE") {
		return $name->($macro, \@args);
	}
	$name //= $macro;

	return "{{", join('|', $name, @args), "}}";
}

# Macro functions
sub _insert_image {
	my (undef, $arglist) = @_;
	my ($filename, @args) = @$arglist;
	for (@args) {
		$_ .= "px" if $_ =~ /^\d+$/;
		$_ = "thumb" if $_ =~ "thumbnail"
	}
	return "[[File:" . join("|", $filename, @args) . ']]';
}

sub _mailto_macro {
	my ($text) = @{$_[1]};
	$text =~ s/AT/\@/g;
	$text =~ s/DOT/./g;
	$text =~ s/[[:upper:]]+//g;
	return $text;
}

sub _footnote_macro {
	my $arglist = $_[1];
	my $note = join ', ', @$arglist;
	return $note ? "<ref>$note</ref>" : "<references/>";
}