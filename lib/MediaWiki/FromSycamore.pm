package MediaWiki::FromSycamore;

use strict;
use warnings;
use utf8::all;
use Data::Dumper;
use feature 'say';
use XML::LibXML::Reader;
use XML::Simple; #seriously sometimes I just want a tree
use Time::Piece;
use File::Path 'make_path';
use MIME::Base64;

our $DEBUG = 1;
our %macro_conversions = (
	'br' => sub { "<br/>" },
	'recentchanges' => sub { '#REDIRECT [[Special:RecentChanges]]' },
	'stop' => 'stop',
	'image' => \&_insert_image,
	'heart' => sub { '♥' },
	'nbsp' => sub { '&nbsp;' },
	'anchor' => sub {
		my $name = $_[1][0] =~ s/\s/_/rg;
		qq{<div id="$name"></div>} },
	'comments' => 'comments',
	'mailto' => \&_mailTo_macro,
	'tableofcontents' => sub {
		$_[1]->[0] && $_[1]->[0] eq 'right'
			? '<div style="float:right">__TOC__</div>'
			: '__TOC__' },
	'address' => 'address',
	'footnote' => \&_footnote_macro,
	'pagecount' => 'NUMBEROFPAGES',
	'usercount' => 'NUMBEROFUSERS',
	'file' => sub { "[[media:$_[1]->[0]]]" },

);
our %propercased_name;
our %file_names;
my $current_parse_page;

my %alignments = ( qw/ ( left : center ) right ^ top v bottom / );
my %align_type = ( qw/ ( align : align ) align ^ valign v valign / );

sub register_template {
	my ($self, $macro, $template) = @_;
	return 0 unless defined $template;
	$macro_conversions{$macro} = $template;
	return 1;
}

sub register_propercased_names {
	my ($self, @args) = @_;
	for my $x (@args) {
		if (ref($x) eq "ARRAY") {
			$propercased_name{lc($_)} = $_ for @$x;
		}
		else { $propercased_name{lc($x)} = $x }
	}
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
	$wc =~ s/(?:X--|(?<!-)--X)(.+?)(?:X--|(?<!-)--X)/<strike>$1<\/strike>/g;

	# Macros [[Foo(a,b)]] to {{foo|a|b}}
	$wc =~ s/\[\[ (\w+) (?: \( ([^\)]+) \) )? \]\]/macro2template(lc($1), $2)/xeg;
	# This needs to be fixed for quoted strings ^
	# ... actually I just hacked around that later
	# TODO: see if images need to be renamed

	# Links ["foo" bar] to [[foo|bar]]
	$wc =~ s/\["([^"]+)"(?: ([^\]]+))?\]/_internal_link_rw($1, $2)/eg;
	# interwiki links... for now assume a simple interwiki map
	$wc =~ s/\[wiki:([^:\n]+):"[^"]"(?: ([^\]]+))?\]/
		$3 ? "[[$1:$2]]" : "[[$1:$2|$3]]"/eg;

	# Definiton lists
	$wc =~ s/^ +([^:\n]+):: ?/; $1\n/g;

	# increase header level by one to deal with <h1> mediawiki brokenness
	$wc =~ s/^ *(=++)(.*)\1$/
		$2 eq ' ' ? '<div style="clear:both"><\/div>' :
		"=$1$2$1="/eg;

	my @rows;
	$wc =~ s/(?{ @rows = (); 1;})(?:^ *(\|\|.*)\|\|(?:\n|\z)(?{push @rows, $1;}))+/
		table_reformat(@rows)/meg;

	# Convert bullet points
	my %bullets = (
		'*' => '*', '1' => '#', 'I' => '#', 'A' => '#', 'a' => '#', ' ' => ':'
	);
	$wc =~ s/^( ++)([1IaA]\.(?:\#\d++)? +|\* *)?/
		($bullets{substr(($2||" "), 0, 1)} x (length($1) || 1)) . " "/meg;
	#^ does not really support offsets, except to parse them.
	# Same with numbering systems

	$wc =~ s/---?/—/g;

	return $wc;
}

sub table_reformat {
	my @rows = @_;
	my (%tabletraits);

	for my $r (@rows) {
		my %rowtraits = ();
		my @cells = split /(?=\|\|++)/, $r;
		for my $c (@cells) {
			my %celltraits = ();
			$c =~ s/^((?:\|\|)+)//;
			$celltraits{colspan} = length($1)/2 if length($1)/2 > 2;
			if ($c =~ s/^\&lt;(.*?)\&gt;//) {
				my $traitslist = $1;
				while ($traitslist =~ s/((?:table|row)?+)(\w+)\ *=\ *"([^\"]*)"//) {
					my ($type, $attr, $data) = (lc($1), lc($2), $3);
					if ($type eq 'table') {
						$tabletraits{$attr} = $data;
					} elsif ($type eq 'row') {
						$rowtraits{$attr} = $data;
					} else {
						$celltraits{$attr} = $data;
					}
				}
				# and the short attributes...
				# srsly just ignore pathological cases
				if ($traitslist =~ /\W/) {
					$traitslist =~ s/\-(\d+)// and $celltraits{colspan} = $1;
					$traitslist =~ s/\|(\d+)// and $celltraits{rowspan} = $1;
					$traitslist =~ s/(\#[0-9a-fA-F]{6,6})// and $celltraits{bgcolor} = $1;
					$traitslist =~ s/(\d+%)// and $celltraits{width} = $1;
					while ($traitslist =~ s/([(:)^v])/ /) { $celltraits{$align_type{$1}} = $alignments{$1} }
				}

				my $tlist = make_traits_string(\%celltraits);
				$c = "$tlist|$c" if $tlist;
			}
		}
		$r = "\n|-" . make_traits_string(\%rowtraits) . "\n|"
			. join("\n|", @cells);
	}
	return "{|" . make_traits_string(\%tabletraits)
		. join("", @rows)
		. "\n|}\n";

	sub make_traits_string {
		my $traits = shift;
		my $tlist = '';
		my %slist = ();
		foreach my $k (sort keys %$traits) {
			my $v = $traits->{$k};
			if ($k eq 'colspan' or $k eq 'align' or $k eq 'valign' or $k eq 'class' or $k eq 'rowspan') {
				$tlist .= " $k=\"$v\"";
			} elsif ($k eq 'bgcolor') {
				$slist{'background-color'} = $v
			} elsif ($k eq 'border' or $k eq 'bordercolor') {
				$slist{border} //= ($traits->{border} // '1') . "px solid " . ($traits->{bordercolor} // "black");
			} else {
				$slist{$k} = $v
			}
		}
		my $style = join '; ', map { "$_: $slist{$_}" } sort keys %slist;
		$tlist .= " style=\"$style\"" if $style;
		return $tlist;
	}

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
	my @args = split / *, */, $arglist if $arglist;
	my $name = $macro_conversions{$macro};
	if (ref($name) eq "CODE") {
		return $name->($macro, \@args);
	}
	$name //= $macro;

	return "{{". join('|', $name, @args). "}}";
}

# Macro functions
sub _insert_image {
	my (undef, $arglist) = @_;
	my ($filename, @args) = @$arglist;
	$filename = $file_names{$current_parse_page}{$filename} // $filename;
	my @captionbits;  #sorry I know this is hacky
	my $type = undef;
	for (@args) {
		if ($_ =~ /^\d+$/)        { $_ .= "px" }
		elsif ($_ eq "thumbnail") { $_ = undef; $type = "thumb" }
		elsif ($_ eq "noborder")  { $_ = undef }
		elsif ($_ eq "right" or $_ eq "left")  { ; }
		else { s/^"|"$//g; push @captionbits, $_; $_ = undef }
	}
	my $caption = join(', ', @captionbits) || undef;
	$type ||= "frame" if $caption;
	return "[[File:" . join("|", grep {defined $_} $filename, $type, @args, $caption) . ']]';
}

sub _internal_link_rw {
	my ($link, $text) = @_;
	$text ||= '';

	if (my $pc = $propercased_name{lc($link)}) {
		$text = $link unless $text;
		$link = $pc;
	}
	if (ucfirst($text) eq $link) { $link = $text }
	if ($link eq $text) { $text = '' }

	$link =~ s/^Users\//User:/i;
	return $text ? "[[$link|$text]]" : "[[$link]]";
}

sub _mailTo_macro {
	my ($text) = @{$_[1]};
	$text =~ s/AT/\@/g;
	$text =~ s/DOT/./g;
	$text =~ s/[[:upper:]\s]+//g;
	return $text;
}

sub _footnote_macro {
	my $arglist = $_[1];
	my $note = join ', ', @$arglist;
	return $note ? "<ref>$note</ref>" : "<references/>";
}

#### XML handling ####
sub convert_XML_wikitext {
	my $self = shift;
	my %options = @_;

	my $outfh;
	if ($options{output}) {
		open $outfh, ">", $options{output} or die "can't open output";
	} else {
		$outfh = *STDOUT;
	}

	my $reader = XML::LibXML::Reader->new(location => $options{input},
			huge => 1)
		   or die "cannot read $options{input}\n";
	$reader->read;
	die "this does not appear to be a sycamore file"
		unless $reader->name() eq 'sycamore';

	$reader->nextElement('page');

	my $xs = XML::Simple->new('ForceArray' => ['version']);

	print $outfh qq/<mediawiki xml:lang="en">\n/;

	do {
		die $reader->name if $reader->name ne 'page';

		# Once we have a bite-sized chunk, go ahead and turn it
		# into a data structure
		# Yes I realize I'm parsing it twice :/
		my $page = $xs->XMLin( $reader->readOuterXml() );

		my $title = $page->{propercased_name};
		my $restrictions = undef;

		say STDERR "Converting $title" if $DEBUG;
		print $outfh "<page>\n",
			"<title>", clean_page_name($title), "</title>\n",
			($restrictions || "");

		$current_parse_page = $title;
		print $outfh $self->render_revision($_) for @{$page->{version}};

		print $outfh "</page>\n\n";

	} while $reader->nextSiblingElement('page') > 0;

	if ($reader->nextElement('file') > 0) {
	do {
		my ($page, $deleted, $name, $uploaduid, $uploadip, $time) =
			map { $reader->getAttribute($_) // '' }
				qw/name attached_to_pagename_propercased uploaded_by_ip uploaded_by uploaded_time deleted/;
		next if $deleted eq "True";

		$name = clean_page_name($name);
		print $outfh "<page>\n",
			"<title>$name</title>\n",
			"<ns>6</ns>\n";

		print $outfh $self->render_revision( {
			user_ip => $uploadip,
			user_edited => $uploaduid,
			edit_time => $time,
			text => 'Import from Wiki Spot wiki' });

		print $outfh "</page>\n\n";
	} while $reader->nextSiblingElement('file') > 0;
	}

	print $outfh "</mediawiki>\n";
}

# uh, random stuff to make sure our XML is clean
our %encode = ( qw/ ' &apos; " &quot; & &amp; < &lt; > &gt; /);
sub clean_page_name { # and no pipes in MW page names
	$_ = shift;
	s/[|<>]//g;
	s/(['"&])/$encode{$1}/gr;
}
sub encode_entities_mut { $_[0] =~ s/(['"&<>])/$encode{$1}/g; }

sub render_revision {
	my ($self, $v) = @_;

	my $ip = $v->{user_ip};
	my $uid = $v->{user_edited};
	my $time = gmtime( $v->{edit_time} )->datetime;
	my $wikitext = $self->convert_wikicode($v->{text});
	encode_entities_mut($wikitext);

	my $contributor = ($uid ? "<username>$uid</username>" : "")
		. ($ip  ? "<ip>$ip</ip>" : "");

	my $comment = $v->{comment} // '';
	$comment =~ s/\["([^"]+)"(?: ([^\]]+))?\]/_internal_link_rw($1, $2)/eg;
	encode_entities_mut($comment);

	return "<revision>\n",
			"<timestamp>", $time, "Z</timestamp>\n",
			"<contributor>", $contributor, "</contributor>\n",
			"<comment>", $comment, "</comment>\n",
			"<text>", $wikitext, "</text>\n",
		"</revision>\n";
}

sub load_propercased_names_from_XML {
	my $self = shift;
	my %options = @_;

	my $reader = XML::LibXML::Reader->new(location => $options{input},
			huge => 1)
		   or die "cannot read $options{input}\n";
	$reader->read;
	die "this does not appear to be a sycamore file"
		unless $reader->name() eq 'sycamore';

	$reader->nextElement('page');
	do {
		my $name = $reader->getAttribute('propercased_name');
		$propercased_name{lc($name)} = $name;
	} while $reader->nextSiblingElement('page') > 0;

	$self->extract_files($reader, $options{files});

	$reader->finish();
}

sub extract_files {
	my ($self, $reader, $extract_destination) = @_;
	$reader->nextElement('file') or return;
	my %seen_names;
	if ($extract_destination) {
		if (-d $extract_destination and -w _ ) { ; } # all good here
		elsif ( ! -e _ and make_path($extract_destination) ) { ; } # ok that worked
		else { die "Cannot write images to $extract_destination: not a writable directory and could not be created"; }
	}

	do {{
		my ($name, $page, $deleted) =
			map { $reader->getAttribute($_) // '' }
				qw/name attached_to_pagename_propercased deleted/;
		next if $deleted eq "True";

		# Determine what to call this on disk and save the info
		# for the wikicode translation phase
		my $newname;
		if (exists $seen_names{$name}) {
			$newname = ("$page~~$name" =~ s~[/|<>]~~gr);
			die "unresolved duplicate name $page~~$name" if exists $seen_names{$newname};
			$seen_names{$newname} = undef;
			$file_names{$page}{$name} = $newname;
		}
		else {
			$newname = ($name =~  s~[/|<>]~~gr);
			$seen_names{$name} = undef;
			$file_names{$page}{$name} = $newname;
		}

		if ($extract_destination) {
			say STDERR "Extracting file $name as $newname" if $DEBUG;
			open my $fh, ">:bytes", "$extract_destination/$newname" or die "Error: Couldn't write $extract_destination/$newname";
			print $fh decode_base64( $reader->readInnerXml() );
			close $fh;
		}

	#TODO: make a skeleton page for each uploaded file

	}} while $reader->nextSiblingElement('file') > 0;
}

1;
