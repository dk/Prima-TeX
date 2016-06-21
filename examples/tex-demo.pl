use strict;
use warnings;
use PDL;
use Prima qw(Application ComboBox);
use Prima::TeX;

my $tex = '$a + b = c$';
my $font_size = 15;
my $wDisplay = Prima::MainWindow->create(
	text => 'TeX Demo',
	size => [500, 200],
	font => { name => 'FreeSerif' },
	onPaint => sub {
		my $self = shift;
		$self->clear;
		$self->font->size($font_size);
		Prima::TeX::TeX_out($self, $tex, 10, 50);
	}
);

# Insert a list box for the font size
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

# Insert the combo box and the font size selection at the upper part
$wDisplay->insert(ComboBox => 
	place => {
		anchor => 'sw',
		height => 30, rely => 1, y => -30,
		x => 0, width => -100, relwidth => 1,
	},
	style => cs::DropDown,
	text => $tex,
	items => [
		'$foo$',
		'$10$',
		'$10^3$',
		'$10^foo$',
		'$\sigma + \ell + 5$',
		'$10^{foo}_{foo}$',
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
	}
);
run Prima;
