use strict;
use warnings;

# FreeSerif, Quivira

############################################################################
                         package Prima::TeX;
############################################################################
our $VERSION = 0.01;

use Carp;

my $deg_to_rad = atan2(1, 1) / 45;

# XXX add FreeSerif from share directory if not found

#######################################################################
#                               TeX_out                               #
#######################################################################
# Usage        : $length = $widget->TeX_out('Solve $a^5 = 4$')
#              : $widget->TeX_out('Solve $a^5 = 4$', 50, 60)
# Purpose      : Measures length of mixed text and TeX math output,
#              : rendering if x and y positions are provided
# Arguments    : mixed text and TeX string; optional x and y coordinates
# Returns      : Length of TeX string as rendered, or as it would be
#              : rendered if no x/y starting position is provided
# Side Effects : none
# Throws       : no exceptions
# Comments     : This function honors the font->direction property.
#              : This is the user-facing function for Prima::TeX. Most
#              : of the magic happens in measure_or_draw_TeX
# See Also     : measure_or_draw_TeX
sub Prima::Drawable::TeX_out {
	my ($widget, $text, $startx, $starty) = @_;
	
	# Switch to our TeX font, FreeSerif
	my $font_backup = $widget->font->name;
	$widget->font->name("FreeSerif");
	
	my %op = (
		startx => $startx,
		starty => $starty,
		is_drawing => 1,
		cos => cos($widget->font->direction * $deg_to_rad),
		sin => sin($widget->font->direction * $deg_to_rad),
	) if defined $startx;
	$op{end_chunk} = '$';
	my $length = 0;
	
	while (length ($text) > 0) {
		# If it starts with something that looks like tex...
		if ($text =~ s/^\$([^\$]*\$)//) {
			local $_ = reverse($1);
			my ($dx) = measure_or_draw_TeX($widget, %op);
			$length += $dx;
			if ($op{is_drawing}) {
				$op{startx} += $op{cos} * $dx;
				$op{starty} += $op{sin} * $dx;
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
		if ($op{is_drawing}) {
			$widget->text_out($not_tex, $op{startx}, $op{starty});
			$op{startx} += $op{cos} * $dx;
			$op{starty} += $op{sin} * $dx;
		}
		$length += $dx;
	}
	
	# Switch back to the original font
	$widget->font->name($font_backup);
	
	# Always return the final width
	return $length;
}

#######################################################################
#                           Property Tables                           #
#######################################################################
# What follows is an enormous collection of property tables. Most of
# these are used to convert TeX commands to a sequence of unicode
# glyphs together with a set of rendering properties. The rendering
# properties include
#  * the glyph's ascent and descent, used for superscript placement and
#    overall height calculations,
#  * left padding and right padding, which can be distinct (the comma,
#    for example, has zero left padding but nonzero right padding),
#  * expectation for an infix operator, and (separately) indication as
#    to whether the current glyph could be a unary operator, which
#    effects how the padding for potentially unary operators is handled
# The ascent and descent information is particular to the FreeSerif font
# though a number of properties  could conceivably be computed from the
# font itself. Dmitry added the Prima::Drawable::get_font_def precisely
# so I could use it to calculate glyph properties, so if I decide to
# expand to fonts besides FreeSerif, that would be the tool to use.

use charnames qw(:loose);
my @name_for_digit = qw(ZERO ONE TWO THREE FOUR FIVE SIX SEVEN EIGHT NINE);

my $low_ascent = -0.2;   # characters like a, e, and \alpha
my $mild_ascent = -0.08; # the letter t
my $op_ascent = -0.1;    # ascent for all operators
my $descent = -0.1;      # for characters that have tails. The letter "f"
                         # is a funny case, and not always handled
                         # correctly. For now, it is always assumed to
                         # have a descent.
my $padding = " ";       # default padding around operators, etc

my %ascent_for = (
	(map { $_ => $low_ascent  } qw( a c e g m n o p q r s u v w x y z ) ),
	(map { $_ => $mild_ascent } qw( t ) ),
);
my %descent_for = map { $_ => $descent } qw( f g j p q y Q );

# Ascii characters that get special treatment
my %special_formatting = map {;
	$_ => {
		unicode => $_,
		lpad    => $padding,
		rpad    => $padding,
		ascent  => $op_ascent,
	}
} qw (+ - * / < > =);
$special_formatting{'-'}{unicode} = "\N{MINUS SIGN}";
$special_formatting{'*'}{unicode} = "\N{ASTERISK OPERATOR}";
$special_formatting{$_}->{can_be_unary} = 1 foreach qw(+ - * /);
delete $special_formatting{'/'}{ascent};
$special_formatting{'~'} = {
	unicode => ' ',
	next_op_infix => 'copy',
};
$special_formatting{','} = {
	unicode => ',',
	rpad => $padding,
};

# TeX symbolic macros (like \: as opposed to \sin) that get mapped to
# simple Unicode sequences
my %is_single_symbol_unisym = (
	',' => "\N{HAIR SPACE}",
	':' => "\N{THIN SPACE}",
	';' => ' ',
);
$_ = { unicode => $_, next_op_infix => 'copy' }
	foreach values %is_single_symbol_unisym;

# Operators that can be either unary or infix:
my %unary_ops = (
	times => "\N{MULTIPLICATION SIGN}",
	pm => "\N{PLUS-MINUS SIGN}",
	cap => "\N{INTERSECTION}",
	diamond => "\N{DIAMOND OPERATOR}",
	oplus => "\N{CIRCLED PLUS}",
	mp => "\N{MINUS-OR-PLUS SIGN}",
	cup => "\N{UNION}",
	bigtriangleup => "\N{WHITE UP-POINTING TRIANGLE}",
	ominus => "\N{CIRCLED MINUS}",
	uplus => "\N{MULTISET UNION}",
	bigtriangledown => "\N{WHITE DOWN-POINTING TRIANGLE}",
	otimes => "\N{CIRCLED TIMES}",
	div => "\N{DIVISION SIGN}",
	sqcap => "\N{SQUARE CAP}",
	triangleright => "\N{CONTAINS AS NORMAL SUBGROUP}",
	oslash => "\N{CIRCLED DIVISION SLASH}",
	cdot => "\N{DOT OPERATOR}",
	sqcup => "\N{SQUARE CUP}",
	triangleleft => "\N{NORMAL SUBGROUP OF}",
	odot => "\N{CIRCLED DOT OPERATOR}",
	star => "\N{STAR OPERATOR}",
	ast => "\N{ASTERISK OPERATOR}",
	vee => "\N{LOGICAL OR}",
	amalg => "\N{AMALGAMATION OR COPRODUCT}",
	bigcirc => "\N{LARGE CIRCLE}",
	setminus => "\N{REVERSE SOLIDUS OPERATOR}",
	wedge => "\N{LOGICAL AND}",
	dagger => "\N{DAGGER}",
	circ => "\N{RING OPERATOR}",
	bullet => "\N{BULLET OPERATOR}",
	wr => "\N{WREATH PRODUCT}",
	ddagger => "\N{DOUBLE DAGGER}",
);

# TeX macros that correspond to simple Unicode sequences, and which are
# operators. These will be merged into unisym below, together with a bit
# of breathing room.
my %normal_ops = (
	# Binary operators
	to => "\N{RIGHTWARDS ARROW}",
	
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
	nleq   => "\N{NEITHER LESS-THAN NOR EQUAL TO}",
	gt     => ">",
	ngtr   => "\N{NOT GREATER-THAN}",
	geq    => "\N{GREATER-THAN OR EQUAL TO}",
	ngeq   => "\N{NEITHER GREATER-THAN NOR EQUAL TO}",
	
	# Dots
	dots   => "\N{HORIZONTAL ELLIPSIS}",
	ldots  => "\N{HORIZONTAL ELLIPSIS}",
	cdots  => "\N{MIDLINE HORIZONTAL ELLIPSIS}",
	vdots  => "\N{VERTICAL ELLIPSIS}",
	ddots  => "\N{UP RIGHT DIAGONAL ELLIPSIS}",
	iddots => "\N{DOWN RIGHT DIAGONAL ELLIPSIS}",
);
my %low_ops = (
);

# Add padding for all ops
$_ = { lpad => $padding, rpad => $padding, unicode => $_ }
	foreach (values %normal_ops, values %low_ops, values %unary_ops);
# Add unary indication to unary ops
$_->{can_be_unary} = 1 foreach (values %unary_ops);
# Add descent for low ops
$_->{descent} = $descent foreach values %low_ops;

# These are given even more breathing room due to their importance:
my %extra_space_ops = (
	implies => "\N{LONG RIGHTWARDS DOUBLE ARROW}",
);
$_ = { lpad => $padding.$padding, rpad => $padding.$padding, unicode => $_ }
	foreach (values %extra_space_ops);

# These are rendered as upright Roman, i.e. normal ASCII, with a bit of
# breathing room on the right. These are insensitive to font faces like
# mathit and mathbf:
my %functions = map {
	$_ => {
		unicode => $_,
		rpad    => $padding,
	}
} qw( arccos arcsin arctan arg bmod cos cosh cot coth csc deg det dim
	exp gcd hom inf ker lg lim liminf limsup ln log max min sec sin
	sinh sup tan tanh Pr );

# Greek macros
my %greek = (
	alpha => "\N{MATHEMATICAL ITALIC SMALL alpha}",
	beta => "\N{MATHEMATICAL ITALIC SMALL beta}",
	Gamma => "\N{GREEK CAPITAL LETTER Gamma}",
	gamma => "\N{MATHEMATICAL ITALIC SMALL gamma}",
	varGamma => "\N{MATHEMATICAL ITALIC CAPITAL GAMMA}",
	Delta => "\N{GREEK CAPITAL LETTER Delta}",
	delta => "\N{MATHEMATICAL ITALIC SMALL delta}",
	varDelta => "\N{MATHEMATICAL ITALIC CAPITAL delta}",
	epsilon => "\N{MATHEMATICAL ITALIC epsilon SYMBOL}",
	varepsilon => "\N{MATHEMATICAL ITALIC SMALL epsilon}",
	zeta => "\N{MATHEMATICAL ITALIC SMALL zeta}",
	eta => "\N{MATHEMATICAL ITALIC SMALL eta}",
	Theta => "\N{GREEK CAPITAL LETTER Theta}",
	theta => "\N{MATHEMATICAL ITALIC SMALL theta}",
	varTheta => "\N{MATHEMATICAL ITALIC CAPITAL theta}",
	vartheta => "\N{MATHEMATICAL ITALIC THETA SYMBOL}",
	iota => "\N{MATHEMATICAL ITALIC SMALL iota}",
	kappa => "\N{MATHEMATICAL ITALIC SMALL kappa}",
	Lambda => "\N{GREEK CAPITAL LETTER Lamda}",
	lambda => "\N{MATHEMATICAL ITALIC SMALL lamda}",
	varLambda => "\N{MATHEMATICAL ITALIC CAPITAL lamda}",
	mu => "\N{MATHEMATICAL ITALIC SMALL mu}",
	nu => "\N{MATHEMATICAL ITALIC SMALL nu}",
	Xi => "\N{GREEK CAPITAL LETTER Xi}",
	xi => "\N{MATHEMATICAL ITALIC SMALL xi}",
	varXi => "\N{MATHEMATICAL ITALIC CAPITAL xi}",
	Pi => "\N{GREEK CAPITAL LETTER Pi}",
	pi => "\N{MATHEMATICAL ITALIC SMALL pi}",
	varPi => "\N{MATHEMATICAL ITALIC CAPITAL pi}",
	varpi => "\N{MATHEMATICAL ITALIC PI SYMBOL}",
	rho => "\N{MATHEMATICAL ITALIC SMALL rho}",
	Sigma => "\N{GREEK CAPITAL LETTER Sigma}",
	varrho => "\N{MATHEMATICAL ITALIC RHO SYMBOL}",
	sigma => "\N{MATHEMATICAL ITALIC SMALL sigma}",
	varSigma => "\N{MATHEMATICAL ITALIC CAPITAL sigma}",
	varsigma => "\N{MATHEMATICAL ITALIC SMALL FINAL SIGMA}",
	tau => "\N{MATHEMATICAL ITALIC SMALL tau}",
	Upsilon => "\N{GREEK CAPITAL LETTER upsilon}",
	upsilon => "\N{MATHEMATICAL ITALIC SMALL upsilon}",
	varUpsilon => "\N{MATHEMATICAL ITALIC CAPITAL upsilon}",
	Phi => "\N{GREEK CAPITAL LETTER Phi}",
	phi => "\N{MATHEMATICAL ITALIC PHI SYMBOL}",
	varPhi => "\N{MATHEMATICAL ITALIC CAPITAL PHI}",
	varphi => "\N{MATHEMATICAL ITALIC SMALL PHI}",
	chi => "\N{MATHEMATICAL ITALIC SMALL chi}",
	Psi => "\N{GREEK CAPITAL LETTER Psi}",
	psi => "\N{MATHEMATICAL ITALIC SMALL psi}",
	varPsi => "\N{MATHEMATICAL ITALIC CAPITAL psi}",
	Omega => "\N{GREEK CAPITAL LETTER Omega}",
	omega => "\N{MATHEMATICAL ITALIC SMALL omega}",
	varOmega => "\N{MATHEMATICAL ITALIC CAPITAL omega}",
);
# Convert to hashrefs
$_ = { unicode => $_, next_op_infix => 1 } foreach values %greek;
# Add ascent and descent information
$greek{$_}{ascent} = $low_ascent
	foreach qw(alpha gamma epsilon varepsilon eta iota kappa mu nu
		pi varpi rho varrho sigma varsigma tau upsilon varphi chi omega);
$greek{$_}{descent} = $descent
	foreach qw(beta gamma zeta eta mu xi rho varrho varsigma phi varphi
		chi psi);

my %spacing = (
	quad => "\N{EN QUAD}",
	qquad => "\N{EM QUAD}",
);
$_ = { unicode => $_ } foreach values %spacing;

my %misc_symbols = (
	nabla => "\N{NABLA}",
	partial => "\N{MATHEMATICAL ITALIC PARTIAL DIFFERENTIAL}",
	Re => "\N{BLACK-LETTER CAPITAL R}",
	Im => "\N{BLACK-LETTER CAPITAL I}",
	imath => "\N{MATHEMATICAL ITALIC SMALL DOTLESS I}",
	jmath => "\N{MATHEMATICAL ITALIC SMALL DOTLESS J}",
	ell => "\N{SCRIPT SMALL L}",
	hbar => "\N{PLANCK CONSTANT OVER TWO PI}",
	infty => "\N{INFINITY}",
);
# Convert to hashrefs and add any special ascent or descent info
$_ = { unicode => $_, next_op_infix => 1 } foreach values %misc_symbols;
$misc_symbols{imath}{ascent} = $misc_symbols{jmath}{ascent}
	= $misc_symbols{infty}{ascent} = $low_ascent;
$misc_symbols{jmath}{descent} = $descent;

my %big_things = (
	sum => "\N{N-ARY SUMMATION}",
	int => "\N{INTEGRAL}",
);
$_ = { unicode => $_, superscript => 0.8, subscript => -0.2 }
	foreach values %big_things;

# Continue with http://milde.users.sourceforge.net/LUCR/Math/unimathsymbols.xhtml
# for color, see http://tex.stackexchange.com/questions/21598/how-to-color-math-symbols
# for spacing: https://www.sharelatex.com/learn/Spacing_in_math_mode

# TeX macros that get mapped to simple Unicode sequences
my %is_unisym = (
	%normal_ops,
	%low_ops,
	%unary_ops,
	%extra_space_ops,
	%functions,
	%greek,
	%spacing,
	%misc_symbols,
	%big_things,
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

########################################################################
#                              next_chunk                              #
########################################################################
# Usage        : $chunk = next_chunk($widget, %ops)
# Purpose      : Nibbles on $_ until it has a single renderable chunk.
#              : Such a chunk is typically either a single letter or
#              : number, or it is a macro. Macros that require special
#              : handling return subrefs, and those that can be mapped
#              : directly to a sequence of unicode characters (such as
#              : \sin) are returned directly.
# Arguments    : $widget, which is only consulted for special-cased 
#              :          macro rendering
#              : %ops, a key/value pair of options. Only 'letter_face'
#              :       and 'number_face' are consulted
# Returns      : undef if whitespace until the end (beginning) of $_
#              : hashref of above properties if simple chunk; includes
#              :    keys unicode, and next_op_infix, among others
#              : subref if a more complex rendering process is necessary
# Side Effects : nibbles on the end of $_
# Throws       : no exceptions, though it warns about stray backslashes
# Comments     : This function can be thought of as the lexer for
#              : Prima::TeX. From a stream of bytes, it returns
#              : actionable object things. The actual measuring and
#              : rendering, however, is handled elsewhere.
# See Also     : measure_or_draw_TeX
sub next_chunk {
	my ($widget, %op) = (shift, @_);
	my $char = chop;
	# ignore spaces
	return if $char =~ /^\s$/;
	
	# Opening curly bracket denotes the start of a bare block. We'll
	# handle this with a particularly clever trick: just invoke
	# measure_or_draw_TeX on the sub-block!
	if ($char eq '{') {
		$_ .= '{';
		return \&measure_or_draw_TeX;
	}
	
	my $to_return = { unicode => $char, next_op_infix => 1 };
	# Roman letters, which use the letter face
	if ('A' le $char and $char le 'Z' or 'a' le $char and $char le 'z') {
		my $full_name = "$op{letter_face} CAPITAL $char";
		$full_name = "LATIN CAPITAL LETTER $char" unless $op{letter_face};
		$full_name =~ s/CAPITAL/SMALL/ if $char ge 'a';
		$to_return->{unicode}
			= $substitutes{$full_name} || eval "\"\\N{$full_name}\"";
		$to_return->{ascent} = $ascent_for{$char} if $ascent_for{$char};
		$to_return->{descent} = $descent_for{$char} if $descent_for{$char};
		return $to_return;
	}
	# single ASCII characters with special formatting (like spaces)
	return $special_formatting{$char} if $special_formatting{$char};
	# slash-commands, like \alpha, \hbar, \frac...
	if ($char eq '\\') {
		# handle single-char, symbolic commands
		my $next = chop;
		return $is_single_symbol_unisym{$next}
			if $is_single_symbol_unisym{$next};
		$_ .= $next; # didn't find, put back character
		
		# Get the command name. If we can't find it, just return a slash
		if (not s/([a-zA-Z]+)$//) {
			warn "Found stray backslash around ", reverse(substr($_, -5));
			return { unicode => '\\' };
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
		if ($to_return = $widget->can("render_tex_$command")) {
			return $to_return;
		}
		# custom parsing/rendering provided by this package, like \frac
		if ($to_return = __PACKAGE__->can("render_$command")) {
			return $to_return;
		}
		# what could be out here?
		return { unicode => "$char$command" };
	}
	
	# Digits. Italics make this really annoying.
	if ('0' le $char and $char le '9') {
		return generate_italic_digit_renderer($char)
			if $op{number_face} eq 'MATHEMATICAL ITALIC';
		$to_return->{unicode}
			= eval "\"\\N{$op{number_face} DIGIT $name_for_digit[$char]}\"";
	}
	
	# All done
	return $to_return;
}

#######################################################################
#                         measure_or_draw_TeX                         #
#######################################################################
# Usage        : ($width, $ascent, $descent)
#              :     = measure_or_draw_TeX($widget, %ops)
# Purpose      : Renders or measures the TeX in $_ using the provided
#              : widget and key/value options.
# Arguments    : $widget, which is used for measuring and rendering;
#              :       next_chunk also consults it for rendering subrefs
#              : %ops, a key/value pair of options including optional
#              :       letter_face, number_face, and end_chunk. If
#              :       is_drawing is a key with a true value, then other
#              :       required keys are startx, starty, cos, sin.
# Returns      : length of the TeX math, in pixels
#              : ascent as a fraction of the line height
#              : descent as a fraction of the line height
#              : whether the next operator can be an infix operator
# Side Effects : nibbles on the end of $_
# Throws       : no exceptions, though it warns about consecutive
#              : superscripts and subscripts
# Comments     : Expects TeX input, via $_, to be reversed
#              : uses chop for efficiency
# See Also     : next_chunk; TeX_out
# XXX          : This should probably refactored into a collection of
#              : smaller functions
sub measure_or_draw_TeX {
	my ($widget, %op) = (shift, 
		letter_face  => 'MATHEMATICAL ITALIC',
		number_face => '',
		@_
	);
	
	# Ignore whitespace
	s/\s+$//;
	
	# If no end-chunk specified, but first character is an opening
	# bracket, then take a closing bracket as the end chunk.
	my $end_chunk = delete $op{end_chunk};
	$end_chunk = '}' if not defined $end_chunk and s/\{$//;
	
	# If no end chunk given, then process only a single chunk.
	if (not defined $end_chunk) {
		# Easy: only grab a single chunk
		my $to_render = next_chunk($widget, %op);
		
		# Return an empty result if we got an empty chunk
		return (0, 0, 0) if not $to_render;
		
		# Make sure we have a ref
		if (not ref($to_render)) {
			warn "Internal error, next chunk returned non-ref $to_render";
			$to_render = { unicode => $to_render };
		}
		
		# If the "chunk" was a rendering subref, run it
		return $to_render->($widget, %op) if ref($to_render) eq ref(sub{});
		
		# Otherwise, render and/or measure the chunk ignoring padding.
		$widget->text_out($to_render->{unicode}, $op{startx}, $op{starty})
			if $op{is_drawing};
		return (
			$widget->get_text_width($to_render->{unicode}),
			$to_render->{ascent} || 0,
			$to_render->{descent} || 0
		);
	}
	
	# We'll need this throughout
	my $line_height = $widget->font->height;
	
	# Values to return. Ascent can be positive or negative, so to
	# differentiate between set and unset, we'll start that with undef.
	my $length = 0;
	my $ascent;
	my $descent = 0;
	
	# We need to increment lengths all over the place, but the quantities
	# that need to be updated depend on whether we're rendering or just
	# measuring. So, we wrap all of that into subrefs.
	my $increment_lengths = $op{is_drawing}
		? sub {
			my $dx = shift || 0;
			$op{startx} += $op{cos} * $dx;
			$op{starty} += $op{sin} * $dx;
			$length += $dx;
		}
		: sub { $length += shift || 0 };
	
	# We also need to track ascent and descent. I use this functionality
	# at least twice:
	my $update_ascent_descent;
	$update_ascent_descent = sub {
		$ascent = shift || 0;
		my $desc = shift || 0;
		$descent = $desc if $desc < $descent;
		# Change this function to actually compare ascent moving forward
		$update_ascent_descent = sub {
			my $asc = shift || 0;
			my $desc = shift || 0;
			$descent = $desc if $desc < $descent;
			$ascent = $asc if $asc > $ascent;
		};
	};
	
	# Needed for adding a bit of room for subscripts and superscripts
	my $hair_space = $widget->get_text_width("\N{HAIR SPACE}");
	
	# Turn the end chunk into a regex
	$end_chunk = quotemeta $end_chunk;
	
	# If the current chunk is an operator, we might render it as a
	# unary operator, or as an infix operator. We start off expecting
	# unary.
	my $next_op_infix = 0;
	
	# Some commands alter the rendering behavior until the end of the
	# current block. Such commands are responsible for supplying a hook
	# to execute at the end of the block to return the renderer to
	# normal.
	my @scope_hooks;
	
	# Parse until we find the end chunk
	my $prev_length = 1 + length;
	my $rpad; # undef means we haven't rendered anything yet.
	CONTIGUOUS: while (length > 0 and $prev_length > length
		and not s/$end_chunk$//)
	{
		$prev_length = length;
		my $to_render = '';
		my $next_step = 'render';
		# Pull out stuff to render directly
		CHUNK: while (length > 0 and not /[\_\^]$/) {
			my $next_chunk = next_chunk($widget, %op);
			next CHUNK if not defined $next_chunk; # skip whitespace
			
			# Make sure we have a ref
			if (not ref($next_chunk)) {
				warn "Internal error, next chunk returned non-ref $next_chunk";
				$next_chunk = { unicode => $next_chunk };
			}
			
			# If it's a subref, put that directly into our next step
			# and break out
			if (ref($next_chunk) eq ref(sub{})) {
				$next_step = $next_chunk;
				last CHUNK;
			}
			
			# Append our most recent chunk to direct rendering,
			# accounting for padding. If rpad is undef, then this is
			# the first thing to render, in which case we ignore lpad.
			if (defined $rpad) {
				$to_render .= $rpad;
				$to_render .= ($next_chunk->{lpad} || '')
					if not $next_chunk->{can_be_unary}
						or $next_op_infix;
			}
			$to_render .= $next_chunk->{unicode};
			
			# update ascent, descent, rpad, and next_op_infix
			$update_ascent_descent->(
				$next_chunk->{ascent}, $next_chunk->{descent});
			$rpad = $next_chunk->{rpad} || '';
			$rpad = '' if $next_chunk->{can_be_unary} and not $next_op_infix;
			$next_op_infix = $next_chunk->{next_op_infix}
				if 'copy' ne ($next_chunk->{next_op_infix} || '');
		}
		continue {
			# If our next chunk is the end chunk, pull it out and exit
			if (s/$end_chunk$//) {
				$next_step = 'done';
				last CHUNK
			}
		}
		
		# Render whatever we have on hand
		if (length($to_render) > 0) {
			$widget->text_out($to_render, $op{startx}, $op{starty})
				if $op{is_drawing};
			$increment_lengths->($widget->get_text_width($to_render));
		}
		
		# Call the next rendering subref, if there is one
		if (ref($next_step) eq ref(sub{})) {
			# handle previous right padding
			$increment_lengths->($widget->get_text_width($rpad))
				if $rpad;
			$rpad = '';
			# execute subref
			my ($dx, $asc, $desc, $infix, $scope_hook)
				= $next_step->($widget, %op);
			# update things we're tracking
			$increment_lengths->($dx);
			$update_ascent_descent->($asc, $desc);
			$infix ||= '';
			$next_op_infix = $infix unless $infix eq 'copy';
			# Add the scope hook, if supplied
			unshift @scope_hooks, $scope_hook
				if ref($scope_hook) and ref($scope_hook) eq ref(sub{});
		}
		
		# If we found the expected end chunk, we're done.
		if ($next_step eq 'done') {
			$_->() foreach @scope_hooks;
			return ($length, $ascent, $descent, $next_op_infix);
		}
		
		# Start again from the top unless we're working with subscripts
		# or superscripts
		my $char = chop;
		if ($char ne '^' and $char ne '_') {
			$_ .= $char;
			next CONTIGUOUS;
		}
		
		# Start by adding just a little bit of space
		$increment_lengths->($hair_space);
		
		# Adjust the font size
		my $original_font_size = $widget->font->size;
		$widget->font->size($original_font_size * 2 / 3);
		
		# Begin looking for superscripts and subscripts. Note that they
		# can appear in either order, hence the while loop.
		my ($sub_length, $super_length);
		SUP_SUB: while ($char eq '^' or $char eq '_') {
			if ($char eq '^') {
				if (defined $super_length) {
					my $original = reverse($_);
					warn("Found consecutive superscript (at $char$original); ignoring");
					# Eat up bad stuff, don't draw, ignore lengths
					measure_or_draw_TeX($widget, %op, is_drawing => 0);
					next SUP_SUB;
				}
				my %sup_op = %op;
				if ($op{is_drawing}) {
					my $superscript_offset = 0.35 * $line_height;
					$sup_op{startx} -= $op{sin} * $superscript_offset;
					$sup_op{starty} += $superscript_offset * $op{cos};
				}
				# XXX maybe should track ascent, but for now I'll just
				# take a superscript render as setting it to zero
				($super_length) = measure_or_draw_TeX($widget, %sup_op);
				$ascent = 0 if $ascent < 0;
			}
			elsif ($char eq '_') {
				if (defined $sub_length) {
					my $original = reverse($_);
					warn("Found consecutive superscript (at $char$original); ignoring");
					# Eat up bad stuff, don't draw, ignore lengths
					measure_or_draw_TeX($widget, %op, is_drawing => 0);
					next SUP_SUB;
				}
				my %sub_op = %op;
				if ($op{is_drawing}) {
					my $subscript_offset = -0.1 * $line_height;
					$sub_op{startx} -= $op{sin} * $subscript_offset;
					$sub_op{starty} += $subscript_offset * $op{cos};
				}
				# XXX maybe should track descent, but ignoring for now.
				($sub_length) = measure_or_draw_TeX($widget, %sub_op);
			}
		}
		continue {
			# Eat whitespace, get the next character
			s/\s+$//;
			$char = chop;
		}
		$widget->font->size($original_font_size);
		
		# update the length with the longer of the two distances
		$sub_length ||= 0;
		$super_length ||= 0;
		my $dx = $sub_length > $super_length ? $sub_length : $super_length;
		$increment_lengths->($dx);
		
		# Our last chop needs to be put back
		$_ .= $char;
	}
	$_->() foreach @scope_hooks;
	return ($length, $ascent, $descent);
}

###########
# Phantom #
###########

# \phantom eats up white space with the length of the given stuff. Easy:
# just turn off drawing.
sub render_phantom {
	return measure_or_draw_TeX(@_, is_drawing => 0);
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
	my ($widget, %op) = (shift, @_);
	my $length = 0;
	my $spc = "\N{HAIR SPACE}";
	my $increment_lengths = $op{is_drawing}
		? sub {
			my $dx = shift;
			$op{startx} += $op{cos} * $dx;
			$op{starty} += $op{sin} * $dx;
			$length += $dx;
		}
		: sub { $length += shift };
	
	# Render the opening brace
	my $opening_brace = chop;
	$opening_brace .= chop if $opening_brace eq '\\';
	$widget->text_out("$spc$is_brace{$opening_brace}",
		$op{startx}, $op{starty}) if $op{is_drawing};
	$increment_lengths->($widget->get_text_width("$spc$is_brace{$opening_brace}"));
	
	# Render the contents
	my $end_chunk = reverse('\right');
	my ($dx) = measure_or_draw_TeX($widget, %op,
		end_chunk => $end_chunk);
	$increment_lengths->($dx);
	
	# Render the closing brace
	my $closing_brace = chop;
	$closing_brace .= chop if $closing_brace eq '\\';
	$widget->text_out("$is_brace{$closing_brace}$spc",
		$op{startx}, $op{starty}) if $op{is_drawing};
	$increment_lengths->($widget->get_text_width("$is_brace{$closing_brace}$spc"));
	
	# XXX need to track ascent and descent eventually
	return ($length, 0, 0);
}

####################
# Font face macros #
####################
sub render_mathrm {
	return measure_or_draw_TeX(@_,
		letter_face => '', number_face => '');
}
sub render_mathbf {
	return measure_or_draw_TeX(@_,
		letter_face => 'MATHEMATICAL BOLD',
		number_face => 'MATHEMATICAL BOLD');
}
sub render_boldsymbol {
	return measure_or_draw_TeX(@_,
		letter_face => 'MATHEMATICAL BOLD ITALIC',
		number_face => 'MATHEMATICAL BOLD');
}
sub render_mathsf {
	return measure_or_draw_TeX(@_,
		letter_face => 'MATHEMATICAL SANS-SERIF',
		number_face => 'MATHEMATICAL SANS-SERIF');
}
sub render_mathit {
	return measure_or_draw_TeX(@_,
		letter_face => 'MATHEMATICAL ITALIC',
		number_face => 'MATHEMATICAL ITALIC');
}
# Whenever a number face of MATHEMATICAL ITALIC is detected in
# cunjunction with a digit, next_chunk returns a subref generated by
# this function, rather than producing a unicode character (because
# unicode does not have MATHEMATICAL ITALIC digits):
sub generate_italic_digit_renderer {
	my $digit = shift;
	return sub {
		my ($widget, %op) = (shift, @_);
		# Switch to italic font
		$widget->font->style(fs::Italic);
		# Render and measure
		$widget->text_out($digit, $op{startx}, $op{starty}) 
			if $op{is_drawing};
		my $width = $widget->get_text_width($digit);
		# Switch back
		$widget->font->style(fs::Normal);
		# Return width, ignore ascent and descent, and this expects
		# infix
		return ($width, 0, 0, 1);
	};
}

sub render_mathtt {
	return measure_or_draw_TeX(@_,
		letter_face => 'MATHEMATICAL MONOSPACE',
		number_face => 'MATHEMATICAL MONOSPACE');
}
sub render_mathbb {
	return measure_or_draw_TeX(@_,
		letter_face => 'MATHEMATICAL DOUBLE-STRUCK',
		number_face => 'MATHEMATICAL DOUBLE-STRUCK');
}
sub render_mathfrak {
	return measure_or_draw_TeX(@_,
		letter_face => 'MATHEMATICAL FRAKTUR',
		number_face => '');
}
sub render_mathcal {
	return measure_or_draw_TeX(@_,
		letter_face => 'MATHEMATICAL SCRIPT',
		number_face => '');
}
sub render_mathscr { # XXX NOTE IDENTICAL TO ABOVE; thanks Unicode
	return measure_or_draw_TeX(@_,
		letter_face => 'MATHEMATICAL SCRIPT',
		number_face => '');
}

##############
# Decorators #
##############

sub _render_decorator {
	my ($widget, %op) = (shift,
		ascent_adjustment => 0.2,
		decorator_height => 0.15,
		@_
	);
	my $asc_adj = delete $op{ascent_adjustment};
	my $dec_height = delete $op{decorator_height};
	
	# Render/measure the next chunk
	my ($length, $ascent, $descent) = measure_or_draw_TeX($widget, %op);
	
	# If we're drawing, then advance x and y, and draw the decorator
	if ($op{is_drawing}) {
		# Measure the length of the decorator and find the offset at
		# which we would center things
		my ($l, $r) = (@{$widget->get_text_box($op{decorator})})[0, 4];
		
		my $center_length = $length / 2 + ($r - $l) / 2;
		# Calculate drawing location, accounting for ascent, etc
		my $asc = ($ascent + $asc_adj) * $widget->font->height;
		my $x = $op{startx} + $op{cos} * $center_length - $op{sin} * $asc;
		my $y = $op{starty} + $op{sin} * $center_length + $op{cos} * $asc;
		# Draw the decorator
		$widget->text_out($op{decorator}, $x, $y);
	}
	
	# return chunk's length
	return ($length, $ascent + $dec_height, $descent);
}

# Get next chunk, and append with U+20D7, combining right arrow above
sub render_vec {
	return _render_decorator(@_, ascent_adjustment => 0.1,
		decorator_height => 0.2,
		decorator => "\N{COMBINING RIGHT ARROW ABOVE}");
}

sub render_ddot {
	return _render_decorator(@_, decorator => "\N{COMBINING DIAERESIS}");
}

sub render_dot {
	return _render_decorator(@_, decorator => "\N{COMBINING DOT ABOVE}");
}

sub render_hat {
	return _render_decorator(@_,
		decorator_height => 0.2,
		decorator => "\N{COMBINING CIRCUMFLEX ACCENT}");
}

sub render_tilde {
	return _render_decorator(@_,
		decorator => "\N{COMBINING TILDE}");
}

sub render_bar {
	return _render_decorator(@_, decorator => "\N{COMBINING MACRON}");
}


#############
# Fractions #
#############

sub render_frac {
	my ($widget, %op) = (shift, @_);
	my $line_height = $widget->font->height;
	
	# Strip leading whitespace
	s/\s+$//;
	
	# Reduce the font size
	my $original_font_size = $widget->font->size;
	$widget->font->size($original_font_size * 0.6);
	
	# Compute the widths of the numerator and denominator. Let them
	# chomp on $_; we'll restore it only if we're actually rendering.
	my $backup_to_render = $_;
	my ($bigger_length) = my ($upper_length)
		= measure_or_draw_TeX($widget, %op, is_drawing => 0);
	my ($lower_length) = measure_or_draw_TeX($widget, %op, is_drawing => 0);
	$bigger_length = $lower_length if $bigger_length < $lower_length;
	
	# Rendering?
	if ($op{is_drawing}) {
		$_ = $backup_to_render;
		# Render the numerator.
		my $vert_offset = 0.5 * $line_height;
		my $x = $op{startx} - $vert_offset * $op{sin};
		my $y = $op{starty} + $vert_offset * $op{cos};
		if ($upper_length < $lower_length) {
			my $dx = ($lower_length - $upper_length) / 2;
			$x += $op{cos} * $dx;
			$y += $op{sin} * $dx;
		}
		measure_or_draw_TeX($widget, %op, startx => $x, starty => $y);
		
		# Render the denominator.
		$vert_offset = -0.08 * $line_height;
		$x = $op{startx} - $vert_offset * $op{sin};
		$y = $op{starty} + $vert_offset * $op{cos};
		if ($lower_length < $upper_length) {
			my $dx = ($upper_length - $lower_length) / 2;
			$x += $op{cos} * $dx;
			$y += $op{sin} * $dx;
		}
		measure_or_draw_TeX($widget, %op, startx => $x, starty => $y);
		
		# Finish with the horizontal line
		$vert_offset = 0.45 * $line_height;
		$x = $op{startx} - $vert_offset * $op{sin};
		$y = $op{starty} + $vert_offset * $op{cos};
		my $x2 = $x + $op{cos} * $bigger_length;
		my $y2 = $y + $op{sin} * $bigger_length;
		my $backup_width = $widget->lineWidth;
		$widget->lineWidth($line_height / 15);
		my $backup_end = $widget->lineEnd;
		$widget->lineEnd(le::Flat);
		$widget->line($x, $y, $x2, $y2);
		$widget->lineWidth($backup_width);
		$widget->lineEnd($backup_end);
	}
	
	# Reset the font size and return the final computed length
	$widget->font->size($original_font_size);
	# XXX should handle ascent and descent better...
	return ($bigger_length, 0, 0);
}

sub render_nicefrac {
	die "Working here\n";
	# use DIVISION SLASH U+2215 or 
	# BIG SOLIDUS U+29f8
	# or FRACTION SLASH U+2044
}
sub render_sqrt {
	my ($widget, %op) = (shift, @_);
	
	# Strip leading whitespace
	s/\s+$//;
	
	# Set width and height factors, specific to font size
	my ($height_factor, $width_factor);
	
	# Measure the contents of the redical. In particular, we are
	# interested in the ascent, as this will dictate the size of our
	# radical symbol.
	my $backup_to_render = $_;
	my ($inner_length, $ascent, $descent)
		= measure_or_draw_TeX($widget, %op, is_drawing => 0);
	$_ = $backup_to_render;
	
	# Render the radical
	my $rad_length = $widget->get_text_width("\N{SQUARE ROOT}");
	my ($overline_startx, $overline_starty);
	if ($op{is_drawing}) {
		my $font_size = $widget->font->size;
		($height_factor, $width_factor)
			= $font_size > 113 ? (1.215, 0.86)
			: $font_size > 49 ? (1.23, 0.87)
			: $font_size > 22 ? (1.24, 0.9)
			: $font_size == 6 ? (1.3, 0.9)
			: (1.29, 0.9);
		$widget->text_out("\N{SQUARE ROOT}", $op{startx}, $op{starty});
		$overline_startx = sprintf('%d', $op{startx}
			+ $op{cos} * $rad_length * $width_factor);
		$op{startx} += $op{cos}*$rad_length;
		$overline_starty = sprintf('%d', $op{starty}
			+ $op{sin} * $rad_length * $width_factor);
		$op{starty} += $op{sin}*$rad_length;
	}
	
	# Render the interior contents
	measure_or_draw_TeX($widget, %op);
	
	# Draw the overline
	if ($op{is_drawing}) {
		# Change the font height so the scanline hits the top of the
		# square-root symbol
		my $backup_height = $widget->font->height;
		$widget->font->height($backup_height * $height_factor);
		# Make the width the same as the inner length
		$widget->font->width($inner_length*0.675 + $rad_length * 0.1);
		# Draw the (anti-aliased) line
		$widget->text_out("\N{HORIZONTAL SCAN LINE-1}", $overline_startx,
			$overline_starty);
		# Reset height; automatically resets width, too
		$widget->font->height($backup_height);
	}
	
	return ($rad_length + $inner_length, $ascent, $descent);
}

1;

=head1 NAME

Prima::TeX - adding TeX equation rendering to Prima

=head1 SYNOPSIS

 use Prima qw(Application TeX);
 Prima::MainWindow->create(
     text => 'TeX Demo',
     size => [500, 200],
     onPaint => sub {
         my $self = shift;
         $self->clear;
         # Simple equation
         $self->TeX_out('$a + b = c$', 10, 50);
         # More complex equation:
         $self->TeX_out('$\int_0^{10} x^2 dx = \frac{1000}{3}$', 10, 100);
     }
 );
 Prima->run;

=head1 DESCRIPTION

This module provides a method for L<Prima::Drawable> and its descendents
to render TeX mathematics. Currently it only supports inline formulas,
though I hope to add displayed formulas eventually.

The philosophy behind this module is that
L<Donald Knuth's TeX|https://en.wikipedia.org/wiki/TeX> provides an
excellent domain-specific language for describing mathematics. This
module merely implements this domain-specific lanague using the
facilities of Prima. It is not a full TeX rendering engine. However, I
do try awfully hard to get it to match the behavior of TeX as closely
as I can reasonably manage.

The primary method, C<Prima::Drawable::TeX_out>, can be used to render
TeX equations and/or to measure the width of such equations. For now, it
always uses the FreeSerif font for typesetting.

=head2 Basics

The contents of any mathematics that you want typeset should be
wrapped in a pair of dollar signs, i.e. 

 $widget->TeX_out('$1+ 10 =11$', 10, 120);

Whitespace is ignored, and the spacing between the glyphs depends upon
the mathematical context. For example, there is no appreciable space
between the digits of the numbers 10 and 11, but there will be space
between all of the operators and the numbers. Be default, Roman letters
are italic and numbers are not.

=head2 Font Faces

You can change the font face of your Roman letters and numbers with the
font face macros C<\mathrm>, C<\mathbf>, C<\boldsymbol>, C<\mathsf>,
C<\mathit>, C<\mathtt>, C<\mathbb>, C<\mathfrak>, C<\mathcal>, and
C<\mathscr>. Note, however, that the last two produce identical results
because Unicode (essentially) does not provide C<\mathscr>.

=head2 Superscripts and Subscripts

Prima::TeX recognizes superscripts and subscripts:

 $widget->TeX_out('$a^2_b = c^{1+1}$', 10, 120);

You do not need to wrap superscripts or subscripts in curly brackets
unless you want multiple characters to be rendered in the superscript or
subscript. When both a superscript and subscript are applied to
something, they are both rendered left justified. This differs from how
HTML renders superscripts and subscripts, but is consistent with TeX.

=head2 Common Recognized Macros

Prima::TeX recognizes many common TeX macros. Many of these are simply
mapped to corresponding Unicode characters, but some of these involve
special rendering. Macros that are simply expanded as unicode strings
include:

=over

=item Greek

All Greek letters recognized by TeX are rendered using Unicode. As with
TeX's functionality, the font face for these characters ignores the
font face of the surrounding scope.

=item Named Functions

Named functions, such as C<\sin> and C<\cos>, are recognized and
rendered using upright Roman regardless of the current font face. The
collection of recognized named functions includes C<\arccos>,
C<\arcsin>, C<\arctan>, C<\arg>, C<\bmod>, C<\cos>, C<\cosh>, C<\cot>,
C<\coth>, C<\csc>, C<\deg>, C<\det>, C<\dim>, C<\exp>, C<\gcd>, C<\hom>,
C<\inf>, C<\ker>, C<\lg>, C<\lim>, C<\liminf>, C<\limsup>, C<\ln>,
C<\log>, C<\max>, C<\min>, C<\sec>, C<\sin>, C<\sinh>, C<\sup>, C<\tan>,
C<\tanh>, and C<\Pr>.

=item Mathematical Operators

Many mathematical operators, including C<\pm>, C<\le>, C<\neq>,
C<\equiv>, and C<\to> (to name just a few) are recognized and mapped.
There are an B<enormous> number of operators and I simply have not had
time to add all of them. Patches welcome!

=item Special Symbols

A number of special symbols are recognized, including C<\nabla>,
C<\partial>, C<\Re>, C<\Im>, C<\imath>, C<\jmath>, C<\ell>, C<\hbar>,
and C<\infty>.

=item Big Symbols

Both C<\int> and C<\sum> are mapped to unicode characters, and special
consideration for superscript and subscript placement is in place.

=back

=head2 Decorators

A subset of the decorator macros are recognized, including C<vec>,
C<ddot>, C<dot>, C<hat>, C<tilde>, and C<bar>. Certainly more need to
be added!

=head2 Special Rendering

A number of macros require special rendering. The most important is
C<\frac>, and it is essentially fully implemented. The C<\sqrt> macro is
another important macro, and it is partially implemented. At the moment,
it does not pay attention to the ascent and descent of its interior, but
that shoud be fixed. It also does not pay attention to any argument,
i.e. the term in square brackets in C<\sqrt[3]{5}>, which would be the
cube root of five. Another macro that is planned but not yet implemented
is C<\nicefrac>.

=head2 Minor Extensions

In TeX, C<mathbb>, C<mathcal>, and C<mathscr> produce nonsensical output
for lower-cased letters and for numbers. These have perfectly sensible
renderings with unicode, so they are allowed and produce the output you
would have expected.

=cut
