use strict;
use warnings;
use Prima qw(Application TeX);

use charnames qw(:loose);

my $wDisplay = Prima::MainWindow->create(
	text    => 'TeX Test',
	size	=> [500, 500],
	font => {
#		size => 15,
		name => 'FreeSerif',
	},
	onPaint => sub {
		my $self = shift;
		$self->clear;
		$self->TeX_out('$foo$', 10, 475);
		$self->TeX_out('$10$', 10, 460);
		$self->TeX_out('$10^3$', 10, 445);
		$self->TeX_out('$10^foo$', 10, 430);
		$self->TeX_out('$\sigma + \ell + 5$', 10, 415);
		$self->TeX_out('$10^{foo}_{foo}$', 10, 400);
		$self->TeX_out('$N^{\alpha\theta}_\gamma$', 10, 385);

#		$self->font->size(20);
#		$self->TeX_out('$10^f_f$ $N^f_f$', 50, 400);
		
		$self->TeX_out('$\sigma_\ell + 5 + \Omega$', 10, 370);
		$self->TeX_out('$\sigma_{\ell} + 5$', 10, 355);
		$self->TeX_out('$N^{a + b+c}$', 10, 340);
		$self->TeX_out('$\sin(\theta)$', 10, 325);
		$self->TeX_out('$\sin \left(\theta\right)$', 10, 310);
		$self->TeX_out('$N \to \infty$', 10, 295);
		$self->TeX_out('$\sum_{i=1}^{100} x_i$', 10, 280);
		$self->TeX_out('$\int_{x=0}^{1} x^2 \, dx$', 10, 265);
		
		# Custom macros
		$self->TeX_out('$1 2 3$', 10, 240);
		$self->TeX_out('$\test 1 2 3 \test$', 10, 225);
		
		# binary operator spacing
		$self->TeX_out('$a + b$', 10, 205);
		$self->TeX_out('$a \times b$', 10, 190);
		
		# Failed parse
		$self->TeX_out('$\int_{x=0}^{1} x^2 \, dx', 10, 160);
		$self->TeX_out('$\unkown{x}$', 10, 145);
		
		$self->TeX_out('$\ddot\theta \ddot a \ddot i \ddot P \ddot t \ddot +$', 10, 130);
		$self->TeX_out('$\vec\theta \vec a \vec i \vec P \vec t \vec +$', 10, 110);
		
		$self->TeX_out('$\hat{\tilde{\ddot{\vec\theta}}} \vec a \vec i \vec P \vec t \vec +$', 10, 85);
		
		#$self->TeX_out('123 $\alpha_3$ 456', 150, 150);
		#$self->TeX_out('$3 \times 4$', 150, 130);
		#$self->TeX_out('$( a^2 + b^2 )^{1/2}$', 150, 100);
		
		#$self->fill_ellipse(200, 200 + $self->font->height, 2, 2);
		#$self->font->direction(90);
		#$self->fill_ellipse(200, 200, 2, 2);
		#$self->text_out('test', 200, 200);
		#print "When direction is 90, width of 'why hello there' is ", $self->get_text_width('why hello there'), "\n";
		
		$self->TeX_out('123 $\alpha_3$ 456', 300, 300);
		$self->TeX_out('$h \to 0$', 300, 285);
		$self->TeX_out('$\mathcal{A} \to \mathcal{B}$', 300, 270);
		$self->TeX_out('$\mathfrak{C} \to \mathfrak{D}$', 300, 255);
		$self->TeX_out('$\Im \left\{ 1 + e^{\imath \, \theta} \right\}$', 300, 240);
		
		# Explicit code points for ...
		# Big Summation
		$self->text_out("\x{23B2}", 300, 220);
		$self->text_out("\x{23B3}", 300, 205);
		# Big Parenthesis
		$self->text_out("\x{239B}", 325, 220);
		$self->text_out("\x{239D}", 325, 205);
		
		# And back to our regular broadcast
		$self->TeX_out('$2 \nless 1, 1 \leq 2, 4 ~ 5\cdots, a \propto b$', 335, 212);
		$self->TeX_out('$2 + A^a_1 \frac{fabc}{123}$', 335, 190);
		$self->TeX_out('$2 + A^a_1 \frac{\pi}{4}$', 335, 175);
		
		$self->text_out("\x{221a}", 325, 150);
		$self->line(325 + $self->get_text_width("\x{221a}") - 1, 150 + $self->font->height, 350, 150 + $self->font->height);
		
		$self->text_out("\x{20d7}", 325, 100);
		$self->text_out("a", 325, 100);
		$self->text_out("x\x{20d7} + y\x{20d7} = z\x{20d7}", 325, 85);
		
		$self->TeX_out('$\vec{x} + \vec{y} = \vec{z}$', 325, 70);
		$self->TeX_out('$m\ddot{x} = -k x + A \dot{v}$', 325, 55);
		$self->TeX_out('$m\vec{\ddot{A}} = -k \vec{A}$', 325, 40);
		$self->TeX_out('$\ddot{A} \ddot{N} \ddot{AN} \dot{A} \dot{N} \dot{AN}$', 325, 25);
		
		$self->TeX_out('$\ddot\theta \tilde{f} \tilde{G} \hat{a} \hat G \bar a \bar{G}$' . " f\x{303} a\x{305}", 325, 10);
	},
);

# Add a custom macro, for the fun of it!
$wDisplay->{tex_macros} = {
	test => sub {
		print "Test!\n";
		return 0;
	},
};

run Prima;
