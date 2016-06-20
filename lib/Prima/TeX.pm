use strict;
use warnings;

# FreeSerif, Quivira

############################################################################
                         package Prima::TeX;
############################################################################
our $VERSION = 0.01;

use Carp;

######################################
# Usage        : ????
# Purpose      : ????
# Arguments    : ????
# Returns      : ????
# Side Effects : none
# Throws       : no exceptions
# Comments     : none
# See Also     : n/a

# Assumes rendering if startx and starty are supplied; otherwise just
# computes the length of the rendered string.
my $deg_to_rad = atan2(1, 1) / 45;

sub TeX_out {
	my ($widget, $text, $startx, $starty) = @_;
	my $angle = $widget->font->direction * $deg_to_rad;
	
	my $length = 0;
	my $is_drawing = defined $starty;
	
	while (length ($text) > 0) {
		# If it starts with something that looks like tex...
		if ($text =~ s/^\$([^\$]*\$)//) {
			local $_ = reverse($1);
			my $dx = measure_or_draw_TeX($widget, '$', $startx, $starty);
			$length += $dx;
			if ($is_drawing) {
				$startx += cos($angle) * $dx;
				$starty += sin($angle) * $dx;
			}
		}
		# If a pair of dollar-signs remains, then only pull off up to
		# the dollar-sign
		my $not_tex;
		if (($text =~ tr/$/$/) > 1) {
			$text =~ s/^([^\$]*)//;
			$not_tex = $1;
		}
		else {
			# Pull off non-tex text
			$not_tex = $text;
			$text = '';
		}
		next if length($not_tex) == 0;
		my $dx = $widget->get_text_width($not_tex);
		if ($is_drawing) {
			$widget->text_out($not_tex, $startx, $starty);
			$startx += cos($angle) * $dx;
			$starty += sin($angle) * $dx;
		}
		$length += $dx;
	}
	
	# Always return the final width
	return $length;
}

use charnames qw(:loose);
my @name_for_digit = qw(ZERO ONE TWO THREE FOUR FIVE SIX SEVEN EIGHT NINE);

# Ascii characters that get special treatment
my %special_formatting = (
	'+' => "\N{THIN SPACE}+\N{THIN SPACE}",
	'-' => "\N{THIN SPACE}\N{MINUS SIGN}\N{THIN SPACE}",
	'/' => "\N{DIVISION SLASH}",
	',' => ",\N{THIN SPACE}",
	'<' => "\N{THIN SPACE}<\N{THIN SPACE}",
	'>' => "\N{THIN SPACE}>\N{THIN SPACE}",
	'~' => "\N{THIN SPACE}\N{TILDE OPERATOR}\N{THIN SPACE}",
	'=' => "\N{THIN SPACE}=\N{THIN SPACE}",
);

# TeX symbolic macros (like \: as opposed to \sin) that get mapped to
# simple Unicode sequences
my %is_single_symbol_unisym = (
	',' => "\N{HAIR SPACE}",
	':' => "\N{THIN SPACE}",
	';' => ' ',
);

# TeX macros that correspond to simple Unicode sequences, and which are
# operators. These will be merged into unisym below, together with a bit
# of breathing room.
my %is_uniop = (
	# Binary operators
	to => "\N{RIGHTWARDS ARROW}",
	pm => "\N{PLUS-MINUS SIGN}",
	times => "\N{MULTIPLICATION SIGN}",
	
	# Equalities
	neq    => "\N{NOT EQUAL TO}",
	ne     => "\N{NOT EQUAL TO}",
	equiv  => "\N{IDENTICAL TO}",
	approx => "\N{ALMOST EQUAL TO}",
	cong   => "\N{APPROXIMATELY EQUAL TO}",
	simeq  => "\N{ASYMPTOTICALLY EQUAL TO}",
	propto => "\N{PROPORTIONAL TO}",
	
	# Comparisons
	lt     => "<",
	nless  => "\N{NOT LESS-THAN}",
	leq    => "\N{LESS-THAN OR EQUAL TO}",
	gt     => ">",
	ngtr   => "\N{NOT GREATER-THAN}",
	geq    => "\N{GREATER-THAN OR EQUAL TO}",
	
	# Dots
	dots   => "\N{HORIZONTAL ELLIPSIS}",
	ldots  => "\N{HORIZONTAL ELLIPSIS}",
	cdots  => "\N{MIDLINE HORIZONTAL ELLIPSIS}",
	vdots  => "\N{VERTICAL ELLIPSIS}",
	ddots  => "\N{UP RIGHT DIAGONAL ELLIPSIS}",
	iddots => "\N{DOWN RIGHT DIAGONAL ELLIPSIS}",
);
# Wrap with spaces
$_ = "\N{THIN SPACE}$_\N{THIN SPACE}" foreach values %is_uniop;

# Continue with https://oeis.org/wiki/List_of_LaTeX_mathematical_symbols
# for color, see http://tex.stackexchange.com/questions/21598/how-to-color-math-symbols
# for spacing: https://www.sharelatex.com/learn/Spacing_in_math_mode

# TeX macros that get mapped to simple Unicode sequences
my %is_unisym = (
	%is_uniop,
	
	# Operators
	nabla => "\N{NABLA}",
	
	# Functions
	sin => "sin",
	cos => "cos",
	tan => "tan",
	
	# Big things
	sum => "\N{N-ARY SUMMATION}",
	int => "\N{INTEGRAL}",
	
	# spacing
	quad => "\N{EN QUAD}",
	qquad => "\N{EM QUAD}",
	
	# Special characters
	Re => "\N{BLACK-LETTER CAPITAL R}",
	Im => "\N{BLACK-LETTER CAPITAL I}",
	imath => "\N{MATHEMATICAL ITALIC SMALL DOTLESS I}",
	jmath => "\N{MATHEMATICAL ITALIC SMALL DOTLESS J}",
	ell => "\N{SCRIPT SMALL L}",
	hbar => "\N{PLANCK CONSTANT OVER TWO PI}",
	infty => "\N{INFINITY}",
	
	# Greek
	alpha => "\N{MATHEMATICAL ITALIC SMALL alpha}",
	beta => "\N{MATHEMATICAL ITALIC SMALL beta}",
	Gamma => "\N{GREEK CAPITAL LETTER Gamma}",
	gamma => "\N{MATHEMATICAL ITALIC SMALL gamma}",
	Delta => "\N{GREEK CAPITAL LETTER Delta}",
	delta => "\N{MATHEMATICAL ITALIC SMALL delta}",
	epsilon => "\N{MATHEMATICAL ITALIC SMALL epsilon}",
	zeta => "\N{MATHEMATICAL ITALIC SMALL zeta}",
	eta => "\N{MATHEMATICAL ITALIC SMALL eta}",
	Theta => "\N{GREEK CAPITAL LETTER Theta}",
	theta => "\N{MATHEMATICAL ITALIC SMALL theta}",
	vartheta => "\N{MATHEMATICAL ITALIC THETA SYMBOL}",
	iota => "\N{MATHEMATICAL ITALIC SMALL iota}",
	kappa => "\N{MATHEMATICAL ITALIC SMALL kappa}",
	Lambda => "\N{GREEK CAPITAL LETTER Lamda}",
	lambda => "\N{MATHEMATICAL ITALIC SMALL lamda}",
	mu => "\N{MATHEMATICAL ITALIC SMALL mu}",
	nu => "\N{MATHEMATICAL ITALIC SMALL nu}",
	Xi => "\N{GREEK CAPITAL LETTER Xi}",
	xi => "\N{MATHEMATICAL ITALIC SMALL xi}",
	Pi => "\N{GREEK CAPITAL LETTER Pi}",
	pi => "\N{MATHEMATICAL ITALIC SMALL pi}",
	rho => "\N{MATHEMATICAL ITALIC SMALL rho}",
	Sigma => "\N{GREEK CAPITAL LETTER Sigma}",
	sigma => "\N{MATHEMATICAL ITALIC SMALL sigma}",
	varsigma => "\N{MATHEMATICAL ITALIC SMALL FINAL SIGMA}",
	tau => "\N{MATHEMATICAL ITALIC SMALL tau}",
	upsilon => "\N{MATHEMATICAL ITALIC SMALL upsilon}",
	Phi => "\N{GREEK CAPITAL LETTER Phi}",
	phi => "\N{MATHEMATICAL ITALIC PHI SYMBOL}",
	varphi => "\N{MATHEMATICAL ITALIC SMALL PHI}",
	chi => "\N{MATHEMATICAL ITALIC SMALL chi}",
	Psi => "\N{GREEK CAPITAL LETTER Psi}",
	psi => "\N{MATHEMATICAL ITALIC SMALL psi}",
	Omega => "\N{GREEK CAPITAL LETTER Omega}",
	omega => "\N{MATHEMATICAL ITALIC SMALL omega}",
	
	partial => "\N{MATHEMATICAL ITALIC PARTIAL DIFFERENTIAL}",
);

# Devise a system to account for gaps in the unicode table. Glyphs that
# appeared before the system became systematized are not repeated in
# Unicode, so the systematic name has to be mapped to the non-systematic
# one. The most aggregious, I think, is italic small h.
my %substitutes = (
	# lower-case italic h
	'MATHEMATICAL ITALIC SMALL h' => "\N{planck constant}",
	# Lots of script letters
	'MATHEMATICAL SCRIPT CAPITAL B' => "\N{SCRIPT CAPITAL B}",
	'MATHEMATICAL SCRIPT CAPITAL E' => "\N{SCRIPT CAPITAL E}",
	'MATHEMATICAL SCRIPT CAPITAL F' => "\N{SCRIPT CAPITAL F}",
	'MATHEMATICAL SCRIPT CAPITAL H' => "\N{SCRIPT CAPITAL H}",
	'MATHEMATICAL SCRIPT CAPITAL I' => "\N{SCRIPT CAPITAL I}",
	'MATHEMATICAL SCRIPT CAPITAL L' => "\N{SCRIPT CAPITAL L}",
	'MATHEMATICAL SCRIPT CAPITAL M' => "\N{SCRIPT CAPITAL M}",
	'MATHEMATICAL SCRIPT CAPITAL R' => "\N{SCRIPT CAPITAL R}",
	# Fraktur
	'MATHEMATICAL FRAKTUR CAPITAL C' => "\N{BLACK-LETTER CAPITAL C}",
	'MATHEMATICAL FRAKTUR CAPITAL H' => "\N{BLACK-LETTER CAPITAL H}",
	'MATHEMATICAL FRAKTUR CAPITAL I' => "\N{BLACK-LETTER CAPITAL I}",
	'MATHEMATICAL FRAKTUR CAPITAL R' => "\N{BLACK-LETTER CAPITAL R}",
	'MATHEMATICAL FRAKTUR CAPITAL Z' => "\N{BLACK-LETTER CAPITAL Z}",
	
	
);

sub next_chunk {
	my ($widget, $letter_face, $number_face) = @_;
	my $char = chop;
	# ignore spaces
	return '' if $char =~ /^\s$/;
	# Roman letters, which use the letter face
	if ('A' le $char and $char le 'Z' or 'a' le $char and $char le 'z') {
		my $full_name = "$letter_face CAPITAL $char";
		$full_name =~ s/CAPITAL/SMALL/ if $char ge 'a';
		return $substitutes{$full_name} if exists $substitutes{$full_name};
		return eval "\"\\N{$full_name}\"";
	}
	# single ASCII characters with special formatting (like spaces)
	return $special_formatting{$char} if $special_formatting{$char};
	# slash-commands, like \alpha, \hbar, \frac...
	if ($char eq '\\') {
		# handle single-char, symbolic commands
		my $next = chop;
		return $is_single_symbol_unisym{$next}
			if exists $is_single_symbol_unisym{$next};
		$_ .= $next; # didn't find, put back character
		
		# Get the command name. If we can't find it, just return a slash
		if (not s/([a-zA-Z]+)$//) {
			warn "Found stray backslash around ", reverse(substr($_, -5));
			return '\\';
		}
		my $command = reverse $1;
		
		# \hbar, \prime, \pm, \alpha, etc
		return $is_unisym{$command} if $is_unisym{$command};
		
		# custom parsing/rendering provided by widget's tex macros
		if (exists $widget->{tex_macros}
			and exists $widget->{tex_macros}{$command})
		{
			return $widget->{tex_macros}{$command};
		}
		# custom parsing/rendering provided by widget method
		if (my $to_return = $widget->can("render_tex_$command")) {
			return $to_return;
		}
		# custom parsing/rendering provided by this package, like \frac
		if (my $to_return = __PACKAGE__->can("render_$command")) {
			return $to_return;
		}
		# what could be out here?
		warn "How did we get here?";
		return $char;
	}
	# Digits
	return eval "\"\\N{$number_face DIGIT $name_for_digit[$char]}\""
		if '0' le $char and $char le '9';
	# Everything else
	return $char;
}

# Expects TeX argument (offset 1) to be reversed; uses chop for efficiency.
sub measure_or_draw_TeX {
	my ($widget, $end_chunk, $startx, $starty, $letter_face,
		$number_face) = @_;
	my $is_drawing = defined $starty;
	my $length = 0;
	my $angle = $widget->font->direction * $deg_to_rad;
	
	$letter_face = 'MATHEMATICAL ITALIC' if not defined $letter_face;
	$number_face = '' if not defined $number_face;
	
	# Ignore whitespace
	s/\s+$//;
	
	# If no end-chunk specified, but first character is an opening
	# bracket, then take a closing bracket as the end chunk.
	$end_chunk = '}' if $end_chunk eq '' and s/\{$//;
	
	# If no end chunk given, then process only a single chunk.
	if ($end_chunk eq '') {
		# Easy: only grab a single chunk
		my $to_render = next_chunk($widget, $letter_face, $number_face);
		# If the "chunk" was a rendering subref, run it
		return $to_render->($widget, $startx, $starty, $letter_face, $number_face)
			if ref($to_render);
		# Otherwise, render and/or measure the chunk
		$widget->text_out($to_render, $startx, $starty) if $is_drawing;
		return $widget->get_text_width($to_render);
	}
	
	# We need to increment lengths all over the place, but the quantities
	# that need to be updated depend on whether we're rendering or just
	# measuring. So, we wrap all of that into subrefs.
	my $increment_lengths = defined $startx
		? sub {
			my $dx = shift;
			$startx += cos($angle) * $dx;
			$starty += sin($angle) * $dx;
			$length += $dx;	
		}
		: sub { $length += shift };
	
	# Needed for adding a bit of room for subscripts and superscripts
	my $hair_space = $widget->get_text_width("\N{HAIR SPACE}");
	
	my %is_special = map { $_ => 1 } qw(_ ^ { );
	# Turn the end chunk into a regex
	$end_chunk = quotemeta $end_chunk;
	
	# Parse until we find the end chunk
	CONTIGUOUS: while (length > 0 and not s/$end_chunk$//) {
		# Pull out stuff to render directly
		my $to_render = '';
		my $next_step = 'render';
		CHUNK: while (length > 0 and not /[\_\^\{]$/) {
			my $next_chunk = next_chunk($widget, $letter_face, $number_face);
			# If it's a subref, put that directly into our next step
			# and break out
			if (ref($next_chunk)) {
				$next_step = $next_chunk;
				last CHUNK;
			}
			# Append our most recent chunk to direct rendering
			$to_render .= $next_chunk;
			# If our next chunk is the end chunk, pull it out and exit
			if (s/$end_chunk$//) {
				$next_step = 'done';
				last CHUNK
			}
		}
		
		# Render whatever we have on hand
		if (length($to_render) > 0) {
			$widget->text_out($to_render, $startx, $starty)
				if $is_drawing;
			$increment_lengths->($widget->get_text_width($to_render));
		}
		
		# Call the next rendering subref, if there is one
		$increment_lengths->($next_step->($widget, $startx,
			$starty, $letter_face, $number_face)) if ref($next_step);
		
		# If we found the expected end chunk, we're done.
		return $length if $next_step eq 'done';
		
		# Start again from the top unless we're working with subscripts
		# or superscripts
		my $char = chop;
		if ($char ne '^' and $char ne '_') {
			$_ .= $char;
			next CONTIGUOUS;
		}
		
		# Start by adding just a little bit of space
		$increment_lengths->($hair_space);
		
		my ($sub_length, $super_length);
		while ($char eq '^' or $char eq '_') {
			my $original_font_size = $widget->font->size;
			my $line_height = $widget->font->height;
			$widget->font->size($original_font_size * 2 / 3);
			if ($char eq '^') {
				if (defined $super_length) {
					my $original = reverse($_);
					croak("Cannot have two superscripts or subscripts in a "
						."row (at $char$original)");
				}
				my ($x, $y);
				if ($is_drawing) {
					my $superscript_offset = 0.45 * $line_height;
					$x = $startx - sin($angle) * $superscript_offset;
					$y = $starty + $superscript_offset * cos($angle);
				}
				$super_length = measure_or_draw_TeX($widget, '', $x, $y);
			}
			elsif ($char eq '_') {
				if (defined $sub_length) {
					my $original = reverse($_);
					croak("Cannot have two superscripts or subscripts in a "
						."row (at $char$original)");
				}
				my ($x, $y);
				if ($is_drawing) {
					my $subscript_offset = -0.1 * $line_height;
					$x = $startx - sin($angle) * $subscript_offset;
					$y = $starty + $subscript_offset * cos($angle);
				}
				$sub_length = measure_or_draw_TeX($widget, '', $x, $y);
			}
			$widget->font->size($original_font_size);
			# Eat whitespace, get the next character
			s/\s+$//;
			$char = chop;
		}
		
		# update the length with the longer of the two distances
		$sub_length ||= 0;
		$super_length ||= 0;
		my $dx = $sub_length > $super_length ? $sub_length : $super_length;
		$increment_lengths->($dx + $hair_space);
		
		# Our last chop needs to be put back
		$_ .= $char;
	}
	return $length;
}

###########
# Bracing #
###########
my %is_brace = (
	'.' => '',
	'(' => '(',
	')' => ')',
	'\{' => '{',
	'\}' => '}',
);

sub render_left {
	my ($widget, $startx, $starty, $letter_face, $number_face) = @_;
	my $is_drawing = defined $startx;
	my $length = 0;
	my $angle = $widget->font->direction * $deg_to_rad;
	my $spc = "\N{HAIR SPACE}\N{HAIR SPACE}";
	my $increment_lengths = defined $startx
		? sub {
			my $dx = shift;
			$startx += cos($angle) * $dx;
			$starty += sin($angle) * $dx;
			$length += $dx;	
		}
		: sub { $length += shift };
	
	# Render the opening brace
	my $opening_brace = chop;
	$opening_brace .= chop if $opening_brace eq '\\';
	$widget->text_out("$spc$is_brace{$opening_brace}", $startx, $starty)
		if $is_drawing;
	$increment_lengths->($widget->get_text_width("$spc$is_brace{$opening_brace}"));
	
	# Render the contents
	my $end_chunk = reverse('\right');
	my $dx = measure_or_draw_TeX($widget, $end_chunk, $startx,
		$starty, $letter_face, $number_face);
	$increment_lengths->($dx);
	
	# Render the closing brace
	my $closing_brace = chop;
	$closing_brace .= chop if $closing_brace eq '\\';
	$widget->text_out("$is_brace{$closing_brace}$spc", $startx, $starty)
		if $is_drawing;
	$increment_lengths->($widget->get_text_width("$is_brace{$closing_brace}$spc"));
	
	return $length;
}

####################
# Font face macros #
####################
sub render_mathrm {
	my ($widget, $startx, $starty, $letter_face, $number_face) = @_;
	return measure_or_draw_TeX($widget, '', $startx, $starty,
		'', '');
}
sub render_mathbf {
	my ($widget, $startx, $starty, $letter_face, $number_face) = @_;
	return measure_or_draw_TeX($widget, '', $startx, $starty,
		'MATHEMATICAL BOLD', 'MATHEMATICAL BOLD');
}
sub render_boldsymbol {
	my ($widget, $startx, $starty, $letter_face, $number_face) = @_;
	return measure_or_draw_TeX($widget, '', $startx, $starty,
		'MATHEMATICAL BOLD ITALIC', 'MATHEMATICAL BOLD');
}
sub render_mathsf {
	my ($widget, $startx, $starty, $letter_face, $number_face) = @_;
	return measure_or_draw_TeX($widget, '', $startx, $starty,
		'MATHEMATICAL SANS-SERIF', 'MATHEMATICAL SANS-SERIF');
}
sub render_mathit {
	my ($widget, $startx, $starty, $letter_face, $number_face) = @_;
	return measure_or_draw_TeX($widget, '', $startx, $starty,
		'MATHEMATICAL ITALIC', 'MATHEMATICAL ITALIC');
}
sub render_mathtt {
	my ($widget, $startx, $starty, $letter_face, $number_face) = @_;
	return measure_or_draw_TeX($widget, '', $startx, $starty,
		'MATHEMATICAL MONOSPACE', 'MATHEMATICAL MONOSPACE');
}
sub render_mathbb {
	my ($widget, $startx, $starty, $letter_face, $number_face) = @_;
	return measure_or_draw_TeX($widget, '', $startx, $starty,
		'MATHEMATICAL DOUBLE-STRUCK', 'MATHEMATICAL DOUBLE-STRUCK');
}
sub render_mathfrak {
	my ($widget, $startx, $starty, $letter_face, $number_face) = @_;
	return measure_or_draw_TeX($widget, '', $startx, $starty,
		'MATHEMATICAL FRAKTUR', 'MATHEMATICAL FRAKTUR');
}
sub render_mathcal {
	my ($widget, $startx, $starty, $letter_face, $number_face) = @_;
	return measure_or_draw_TeX($widget, '', $startx, $starty,
		'MATHEMATICAL SCRIPT', 'MATHEMATICAL SCRIPT');
}
sub render_mathscr { # XXX NOTE IDENTICAL TO ABOVE; thanks Unicode
	my ($widget, $startx, $starty, $letter_face, $number_face) = @_;
	return measure_or_draw_TeX($widget, '', $startx, $starty,
		'MATHEMATICAL SCRIPT', 'MATHEMATICAL SCRIPT');
}

##############
# Decorators #
##############

sub _render_decorator {
	my ($widget, $startx, $starty, $letter_face, $number_face, $decorator) = @_;
	
	# Render/measure the next chunk
	my $length = measure_or_draw_TeX($widget, '', $startx, $starty);
	
	# If we're drawing, then advance x and y, and draw the vector arrow
	if (defined $startx) {
#		my $hair_space = $widget->get_text_width("\N{HAIR SPACE}");
		my $angle = $widget->font->direction * $deg_to_rad;
#		$startx += cos($angle) * ($length + $hair_space);
#		$starty += sin($angle) * ($length + $hair_space);
		$startx += cos($angle) * $length;
		$starty += sin($angle) * $length;
		$widget->text_out($decorator, $startx, $starty);
	}
	
	# return chunk's length
	return $length;
}

# Get next chunk, and append with U+20D7, combining right arrow above
sub render_vec {
	return _render_decorator(@_, "\N{HAIR SPACE}\N{COMBINING RIGHT ARROW ABOVE}");
}

sub render_ddot {
	return _render_decorator(@_, "\N{COMBINING DIAERESIS}");
}

sub render_dot {
	return _render_decorator(@_, "\N{COMBINING DOT ABOVE}");
}

sub render_hat {
	return _render_decorator(@_, "\N{COMBINING CIRCUMFLEX ACCENT}");
}

sub render_tilde {
	return _render_decorator(@_, "\N{COMBINING TILDE}");
}

sub render_bar {
	return _render_decorator(@_, "\N{COMBINING MACRON}");
}


#############
# Fractions #
#############

sub render_frac {
	my ($widget, $startx, $starty, $letter_face, $number_face) = @_;
	my $angle = $widget->font->direction * $deg_to_rad;
	my $line_height = $widget->font->height;
	
	# Strip leading whitespace
	$_[1] =~ s/\s+$//;
	
	# Reduce the font size
	my $original_font_size = $widget->font->size;
	$widget->font->size($original_font_size * 0.6);
	
	# Compute the widths of the numerator and denominator. Let them
	# chomp on $_; we'll restore it only if we're actually rendering.
	my $backup_to_render = $_;
	my $bigger_length = my $upper_length = measure_or_draw_TeX($widget, '');
	my $lower_length = measure_or_draw_TeX($widget, '');
	$bigger_length = $lower_length if $bigger_length < $lower_length;
	
	# Rendering?
	if (defined $startx) {
		$_ = $backup_to_render;
		# Render the numerator.
		my $vert_offset = 0.5 * $line_height;
		my $x = $startx - $vert_offset * sin($angle);
		my $y = $starty + $vert_offset * cos($angle);
		if ($upper_length < $lower_length) {
			my $dx = ($lower_length - $upper_length) / 2;
			$x += cos($angle) * $dx;
			$y += sin($angle) * $dx;
		}
		measure_or_draw_TeX($widget, '', $x, $y);
		
		# Render the denominator.
		$vert_offset = -0.05 * $line_height;
		$x = $startx - $vert_offset * sin($angle);
		$y = $starty + $vert_offset * cos($angle);
		if ($lower_length < $upper_length) {
			my $dx = ($upper_length - $lower_length) / 2;
			$x -= cos($angle) * $dx;
			$y -= sin($angle) * $dx;
		}
		measure_or_draw_TeX($widget, '', $x, $y);
		
		# Finish with the horizontal line
		$vert_offset = 0.5 * $line_height;
		$x = $startx - $vert_offset * sin($angle);
		$y = $starty + $vert_offset * cos($angle);
		my $x2 = $x + cos($angle) * $bigger_length;
		my $y2 = $y + sin($angle) * $bigger_length;
		$widget->line($x, $y, $x2, $y2);
	}
	
	# Reset the font size and return the final computed length
	$widget->font->size($original_font_size);
	return $bigger_length;
}

sub render_nicefrac {
	die "Working here\n";
	# use DIVISION SLASH U+2215 or 
	# BIG SOLIDUS U+29f8
	# or FRACTION SLASH U+2044
}
# For square root, consider HORIZONTAL SCAN LINE 1, U+23ba
# square root is U+221a
# Also, use get_text_box to get the upper right corner of the square-root

1;
__END__
sub old_TeX_out {
	my ($widget, $text, $startx, $starty) = @_;
	my $angle = $widget->font->direction * $deg_to_rad;
	
	my $length = 0;
	my $is_drawing = defined $starty;
	
	while (length ($text) > 0) {
		# If it starts with something that looks like tex...
		if ($text =~ s/^\$([^\$]*\$)//) {
			my $reverse_tex = reverse process_escaped_characters($1);
			# Set an italic font
			my $prev_font_style = $widget->font->style;
			$widget->font->style(fs::Italic);
			# Render and/or measure the tex
			my $dx = measure_or_draw_TeX($widget, $reverse_tex, '$', $startx, $starty);
			$length += $dx;
			if ($is_drawing) {
				$startx += cos($angle) * $dx;
				$starty += sin($angle) * $dx;
			}
			# Restore the font style
			$widget->font->style($prev_font_style);
		}
		# Pull off non-tex text
		$text =~ s/^([^\$]*)//;
		my $not_tex = $1;
		next if length($not_tex) == 0;
		my $dx = $widget->get_text_width($not_tex);
		if ($is_drawing) {
			$widget->text_out($not_tex, $startx, $starty);
			$startx += cos($angle) * $dx;
			$starty += sin($angle) * $dx;
		}
		$length += $dx;
	}
	
	# Always return the final width
	return $length;
}

# Assumes that the widget's font is already set up for this text, and
# that the tex string has been reversed, which means we can slowly eat
# characters off the end using chop. To determine if we are rendering or
# just measuring, check the definedness of starty. We chop directly off
# of the second argument, $_[1], so that our parser can "eat" characters
# that it has parsed.
sub old_measure_or_draw_TeX {
	my ($widget, $end_char, $startx, $starty) = @_;
	my $is_drawing = defined $starty;
	my $length = 0;
	my $angle = $widget->font->direction * $deg_to_rad;
	
	# Ignore whitespace
	my $char = chop $_[1];
	$char = chop $_[1] while $char eq ' ';
	
	# If no end char given, then we check the first character to see if
	# it's an opening brace.
	if ($end_char eq '') {
		if ($char eq '{') {
			# Assign closing brace as our end char
			$end_char = '}';
			$char = chop $_[1];
		}
		else {
			# No two super/subscripts in a row
			if ($char eq '_' or $char eq '^') {
				my $original = reverse($_[1]);
				croak("Cannot have two superscripts or subscripts in a "
					."row (at $char$original)");
			}
			# render a single-character
			$widget->font->style(fs::Normal) if $not_italic{$char};
			$widget->text_out($char, $startx, $starty) if $is_drawing;
			my $dx = $widget->get_text_width($char);
			$widget->font->style(fs::Italic);
			return $dx;
		}
	}
	
	# Parse until we find the end char
	while (length($_[1]) > 0) {
		my $is_currently_italic = 1 - ($not_italic{$char} || 0);
		# Pull out stuff to render directly
		my $direct_render = '';
		while (length($_[1]) > 0 and $char !~ /[\^_\{$end_char]/) {
			my $char_is_italic = 1 - ($not_italic{$char} || 0);
			last if $char_is_italic != $is_currently_italic;
			$direct_render .= $char if $char ne ' ';
			$char = chop $_[1];
		}
		if (length($direct_render) > 0) {
			$widget->font->style(fs::Normal) unless $is_currently_italic;
			my $dx = $widget->get_text_width($direct_render);
			if ($is_drawing) {
				$widget->text_out($direct_render, $startx, $starty);
				$startx += cos($angle) * $dx;
				$starty += sin($angle) * $dx;
			}
			$widget->font->style(fs::Italic) unless $is_currently_italic;
			$length += $dx;
		}
		
		# What we do next depends on the character just popped off. If
		# we found the expected end character, we're done
		return $length if $char eq $end_char;
		
		# Handle superscripts and subscripts next
		my ($sub_length, $super_length);
		while ($char eq '^' or $char eq '_') {
			my $original_font_size = $widget->font->size;
			my $line_height = $widget->font->height;
			$widget->font->size($original_font_size * 2 / 3);
			if ($char eq '^') {
				if (defined $super_length) {
					my $original = reverse($_[1]);
					croak("Cannot have two superscripts or subscripts in a "
						."row (at $char$original)");
				}
				my ($x, $y);
				if ($is_drawing) {
					my $superscript_offset = 0.5 * $line_height;
					$x = $startx - sin($angle) * $superscript_offset;
					$y = $starty + $superscript_offset * cos($angle);
				}
				$super_length = measure_or_draw_TeX($widget, '', $x, $y);
			}
			elsif ($char eq '_') {
				if (defined $sub_length) {
					my $original = reverse($_[1]);
					croak("Cannot have two superscripts or subscripts in a "
						."row (at $char$original)");
				}
				my ($x, $y);
				if ($is_drawing) {
					my $subscript_offset = -0.25 * $line_height;
					$x = $startx - sin($angle) * $subscript_offset;
					$y = $starty + $subscript_offset * cos($angle);
				}
				$sub_length = measure_or_draw_TeX($widget, '', $x, $y);
			}
			$widget->font->size($original_font_size);
			# Eat whitespace
			$char = chop $_[1];
			$char = chop $_[1] while $char eq ' ';
		}
		# dx is the longer of the two distances
		$sub_length ||= 0;
		$super_length ||= 0;
		my $dx = $sub_length > $super_length ? $sub_length : $super_length;
		# Update the length and starting positions
		$length += $dx;
		if ($is_drawing) {
			$startx += cos($angle) * $dx;
			$starty += sin($angle) * $dx;
		}
	}
	return $length if $char eq $end_char;
	croak("Encountered unexpected end of tex string");
}

my %codepoint_for = (
	# Greek
	alpha => "\x{3B1}",
	beta => "\x{3B2}",
	Gamma => "\x{393}",
	gamma => "\x{3B3}",
	Delta => "\x{394}",
	delta => "\x{3B4}",
	epsilon => "\x{3B5}",
	zeta => "\x{3B6}",
	eta => "\x{3B7}",
	Theta => "\x{398}",
	theta => "\x{3B8}",
	vartheta => "\x{3D1}",
	iota => "\x{3B9}",
	kappa => "\x{3BA}",
	Lambda => "\x{39B}",
	lambda => "\x{3BB}",
	mu => "\x{3BC}",
	nu => "\x{3BD}",
	Xi => "\x{39E}",
	xi => "\x{3BE}",
	Pi => "\x{3A0}",
	pi => "\x{3C0}",
	rho => "\x{3C1}",
	Sigma => "\x{3A3}",
	sigma => "\x{3C3}",
	varsigma => "\x{3C2}",
	tau => "\x{3C4}",
	upsilon => "\x{3C5}",
	Phi => "\x{3A6}",
	phi => "\x{3D5}",
	varphi => "\x{3C6}",
	chi => "\x{3C7}",
	Psi => "\x{3A8}",
	psi => "\x{3C8}",
	Omega => "\x{3A9}",
	omega => "\x{3C9}",
	
	ell => "\x{2113}",
	times => "\N{MULTIPLICATION SIGN}",
	gt => '>',
	lt => '<',
	
);

sub process_escaped_characters {
	my $tex = shift;
	# Replaces common tex characters that have corresponding unicode
	# code points
	
	$tex =~ s{\\([a-zA-Z]+)}{ $codepoint_for{$1} || "\\$1" }eg;
	
	return $tex;
}

1;

=head1 NAME

Prima::TeX - adding TeX equation rendering to Prima

=head1 NOTES

Prima comes with the F<fontdlg.pl> script in the F<examples> directory,
making it easy to explore the various font faces on a machine. On my
Linux machine, there appear to be four basic approaches that a font
uses for typesetting mathematics:

=over

=item No Typesetting

Many fonts only provide latin and greek letters. They might provide some
operators, but their coverage is far from complete. This happens with
surprising regularity for system fonts, which seem to focus on providing
wider support for arabic, hindi, etc. C<Bitstream Charter> is the worst,
failing to provide even greek letters. C<Century Schoolbook L> provides
cyrillic characters, but no greek ones. C<Arial> provides full coverage
of greek, at least.

=item Basic Unicode Support

Unicode codepoints exist for all latin and greek letters as well as the
important mathematics operators. This is the case for C<DroidSerif>

=item Wide Unicode Support

Unicode codepoints exist for all latin and greek letters, important
mathematics operators, and some "math typesetting" characters.
C<DejaVu Serif> falls into this category. For example, it does not
include fraktur settings of the latin alphabet.

=item Complete Unicode Support, not Prima accessible

A few font faces provide complete unicode coverage (described below) but
somehow provide bad data to Prima, so Prima has incorrect notions about
line height. This is the case for C<Latin Modern Math> and the "Math"
subfonts under C<TeX Gyre>. For example, C<TeX Gyre Schola> has a
corresponding C<TeX Gyre Schola Math>; Prima obtains correct font metrics
from the former but not the latter. I suspect that a work-around for the
"Math" subfonts could be devised in which the non-math font is queried
for information like internal leading.

=item Complete Unicode Support

All useful Unicode codepoints exist, including those typically associated
with changes in font syling, such as C<MATHEMATICAL SMALL ITALIC F>.
These include characters for script fonts, double-struck, fraktur,
san-serif, even monospace. C<FreeSerif> is one of the few that appears
to have complete coverage.

=item Multiple Fonts within a Family

Some collections of fonts restrict their tables to only contain a small
number (128?) of entries. Between various fonts in the family, they
provide coverage of all math symbols and font faces. The C<MathJax_...>
fonts are one such example; these use Unicode code-points for greek
symbols and mathematical operators, but provide double-struck, fraktur,
and other font faces using multiple fonts, and the ASCII codepoints. In
contrast, the C<...10> fonts such as C<cmex10>, C<cmmi10>, C<msbm10>,
etc, use a font-specific encoding that is not compatible with utf-8.

=back

Obviously, I have lots of possible approaches. The simples option is to
require the user to indicate a font with complete unicode support. In
fact, I could create an Alien package for FreeSerif and simply rely on
that package for TeX typesetting. For now, I will simply rely on full
unicode support (i.e. FreeSerif) and add other capabilities, such as
changing the font style, if I decide it's worth doing.

=head2 Recognized Macros

Prima::TeX recognizes macros for:

=over

=item Greek

All Greek letters are recognized and rendered using Unicode.

=item Mathematical Comparsions

The mathematical comparisons, including C<\le>, C<\neq>, C<\equiv>, etc.


=back

the Greek letters. It also recognizes

 \times    multiplication symbol

 \gt, \lt  greater and less than symbols
 \ge, \le  
 lt, gt, 
	to => "\N{THIN SPACE}\N{RIGHTWARDS ARROW}\N{THIN SPACE}",
	times => "\N{MULTIPLICATION SIGN}",
	gt => "\N{THIN SPACE}>\N{THIN SPACE}",
	lt => "\N{THIN SPACE}<\N{THIN SPACE}",
	nabla => "\N{NABLA}",
	ell => "\N{SCRIPT SMALL L}",
	hbar => "\N{PLANCK CONSTANT OVER TWO PI}",
	pm => "\N{THIN SPACE}\N{PLUS-MINUS SIGN}\N{THIN SPACE}",
	sin => "sin",
	cos => "cos",
	tan => "tan",
	infty => "\N{INFINITY}",
	sum => "\N{N-ARY SUMMATION}",
	int => "\N{INTEGRAL}",
	quad => "\N{EN QUAD}",
	qquad => "\N{EM QUAD}",
	Re => "\N{BLACK-LETTER CAPITAL R}",
	Im => "\N{BLACK-LETTER CAPITAL I}",
	imath => "\N{MATHEMATICAL ITALIC SMALL DOTLESS I}",
	jmath => "\N{MATHEMATICAL ITALIC SMALL DOTLESS J}",

=head2 Minor Extensions

In TeX, C<mathbb>, C<mathcal>, and C<mathscr> produce nonsensical output
for lower-cased letters and for numbers. These have perfectly sensible
renderings with unicode, so they are allowed and produce the output you
would have expected.

=cut
