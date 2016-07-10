use strict;
use warnings;
use Prima qw(Application ComboBox Label);
use Prima::TeX;

# We'll populate this below.
my %explanations;

# This is our starting example
my $tex = 'basic numbers: $10.1 + 12.4=22.5$',

# Create the main window. We'll render the TeX output directly onto this
# window, and we'll pack the drop-down boxes and explanation label, too.
my $font_size = 15;
my $wDisplay = Prima::MainWindow->create(
	text => 'TeX Demo',
	size => [500, 200],
	font => { name => 'FreeSerif' },
	onPaint => sub {
		my $self = shift;
		$self->clear;
		$self->font->size($font_size);
		my $tex_to_show = $tex =~ s/^.*: //r;
		Prima::TeX::TeX_out($self, $tex_to_show, 10, 50);
		$self->line(0, 50, $self->width, 50);
		$self->line(0, 50 + $self->font->height, $self->width, 50 + $self->font->height);
	}
);

# This label contains an explanation of what we're looking for with each
# drop-down example.
my $label = $wDisplay->insert(Label =>
	place => {
		x => 10, relwidth => 1, width => -20,
		y => 0, height => 50, anchor => 'sw',
	},
	text => '',
	wordWrap => 1,
);

# The user can change the font size with this drop-down:
$wDisplay->insert(ComboBox =>
	place => {
		anchor => 'sw',
		height => 30, rely => 1, y => -30,
		relx => 1, x => -100, width => 100,
	},
	style => cs::DropDownList,
	items => [ 10 .. 64 ],
	onChange => sub {
		$font_size = shift->text;
		$wDisplay->repaint;
	},
);

# This combo-box contains the list of example equations. The user can
# also enter TeX expressions of their own.
$wDisplay->insert(ComboBox => 
	place => {
		anchor => 'sw',
		height => 30, rely => 1, y => -30,
		x => 0, width => -100, relwidth => 1,
	},
	style => cs::DropDown,
	text => $tex,
	items => [
		# Basic numerals and operator positioning
		$tex,
		'positive/negative signs: $-5 - 10 + -5 = -20$',
		'variables: $ab + c > d$',
		# Superscripts and subscripts
		'superscripts: $10^6 = 1 / 10^{-6}$',
		'subscripts: $a_1 + b_{1} = c_{12}$',
		'superscript spacing: $x^{-1}x + \sin^{-1} x + \sin x$',
		# Font faces
		'default math font: $A^1 + B^2 + a^b = \alpha^\beta$',
		'mathrm: $\mathrm{A^1 + B^2 + a^b = \alpha^\beta}$',
		'mathbf: $\mathbf{A^1 + B^2 + a^b = \alpha^\beta}$',
		'boldsymbol: $\boldsymbol{A^1 + B^2 + a^b = \alpha^\beta}$',
		'mathsf: $\mathsf{A^1 + B^2 + a^b = \alpha^\beta}$',
		'mathit: $\mathit{A^1 + B^2 + a^b = \alpha^\beta}$',
		'mathtt: $\mathtt{A^1 + B^2 + a^b = \alpha^\beta}$',
		'mathbb: $\mathbb{A^1 + B^2 + a^b = \alpha^\beta}$',
		'mathfrak: $\mathfrak{A^1 + B^2 + a^b = \alpha^\beta}$',
		'mathcal: $\mathcal{A^1 + B^2 + a^b = \alpha^\beta}$',
		'mathscr: $\mathscr{A^1 + B^2 + a^b = \alpha^\beta}$',
		# Controlling spacing
		'brace-enclosed operators: $a + b {+} c$',
		'spacing and superscripts: $5\,000\,000 = 5\times10^6$',
		'superscripts: $10^3$',
		'brace handling: $10^foo$',
		'greek and other symbols: $\sigma + \ell + 5$',
		'superscripts and subscripts: $10^{foo}_{foo}$',
		'$N^{\alpha\theta}_\gamma$',
		'$10^f_f$ $N^f_f$',
		'$\sigma_\ell + 5 + \Omega$',
		'$\sigma_{\ell} + 5$',
		'$N^{a + b+c}$',
		'$\sin(\theta)$',
		'$\sin \left(\theta\right)$',
		'$N \to \infty$',
		'$\sum_{i=1}^{100} x_i$',
		'$\int_{x=0}^{1} x^2 \, dx$',
		
		# binary operator spacing
		'$a + b$',
		'$a \times b$',
		
		# Failed parse
		'$\int_{x=0}^{1} x^2 \, dx',
		'$\unkown{x}$',
		
		'$\ddot\theta \ddot a \ddot i \ddot P \ddot t \ddot +$',
		'$\vec\theta \vec a \vec i \vec P \vec t \vec +$',
		
		'$\hat{\tilde{\ddot{\vec\theta}}} \vec a \vec i \vec P \vec t \vec +$',
		
		'123 $\alpha_3$ 456',
		'$h \to 0$',
		'$\mathcal{A} \to \mathcal{B}$',
		'$\mathfrak{C} \to \mathfrak{D}$',
		'$\Im \left\{ 1 + e^{\imath \, \theta} \right\}$',
		
		'$2 \nless 1, 1 \leq 2, 4 ~ 5\cdots, a \propto b$',
		'$2 + A^a_1 \frac{fabc}{123}$',
		'$2 + A^a_1 \frac{\pi}{4}$',
		
		'$\vec{x} + \vec{y} = \vec{z}$',
		'$m\ddot{x} = -k x + A \dot{v}$',
		'$m\vec{\ddot{A}} = -k \vec{A}$',
		'$\ddot{A} \ddot{N} \ddot{AN} \dot{A} \dot{N} \dot{AN}$',
		
		'$\ddot\theta \tilde{f} \tilde{G} \hat{a} \hat G \bar a \bar{G}$'
	],
	onChange => sub {
		$tex = shift->text;
		$wDisplay->repaint;
		my ($tag) = $tex =~ /^(.*):/;
		$label->text($explanations{$tag || ''} || '');
	}
);

# Here are our explanation of each example.
%explanations = (
	'basic numbers' => <<EXP,
Numerals are upright. Spacing between numerals and decimal point are all
unnoticible. There is spacing between the numbers and the operators.
EXP
	'positive/negative signs' => <<EXP,
Binary operators have plenty of space around them. Unary operators are
tightly affixed to their operands.
EXP
	'superscripts' => <<EXP,
Superscripts render just below the top of the line, and can group.
EXP
	'subscripts' => <<EXP,
Subscripts render just above the bottom of the line, and can be grouped.
EXP
	'variables' => <<EXP,
Variables are rendered in italic. Consecutive variables have no spacing
between them.
EXP
	'brace-enclosed operators' => <<EXP,
The second addition symbol is enclosed within braces, discarding the
operator's padding.
EXP
	'superscript spacing' => <<EXP,
Tight or broad spacing propogates "through" superscripts. Two letters
have no spacing, whereas there is room between sine and its argument.
EXP
);

# And finally, run it!
$label->text($explanations{'basic numbers'});
run Prima;
