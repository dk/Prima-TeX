use strict;
use warnings;
use PDL;
use Prima qw(Application);
use Prima::TeX;

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
		Prima::TeX::TeX_out($self, '$foo$', 10, 475);
		Prima::TeX::TeX_out($self, '$10$', 10, 460);
		Prima::TeX::TeX_out($self, '$10^3$', 10, 445);
		Prima::TeX::TeX_out($self, '$10^foo$', 10, 430);
		Prima::TeX::TeX_out($self, '$\sigma + \ell + 5$', 10, 415);
		Prima::TeX::TeX_out($self, '$10^{foo}_{foo}$', 10, 400);
		Prima::TeX::TeX_out($self, '$N^{\alpha\theta}_\gamma$', 10, 385);

#		$self->font->size(20);
#		Prima::TeX::TeX_out($self, '$10^f_f$ $N^f_f$', 50, 400);
		
		Prima::TeX::TeX_out($self, '$\sigma_\ell + 5 + \Omega$', 10, 370);
		Prima::TeX::TeX_out($self, '$\sigma_{\ell} + 5$', 10, 355);
		Prima::TeX::TeX_out($self, '$N^{a + b+c}$', 10, 340);
		Prima::TeX::TeX_out($self, '$\sin(\theta)$', 10, 325);
		Prima::TeX::TeX_out($self, '$\sin \left(\theta\right)$', 10, 310);
		Prima::TeX::TeX_out($self, '$N \to \infty$', 10, 295);
		Prima::TeX::TeX_out($self, '$\sum_{i=1}^{100} x_i$', 10, 280);
		Prima::TeX::TeX_out($self, '$\int_{x=0}^{1} x^2 \, dx$', 10, 265);
		
		# Custom macros
		Prima::TeX::TeX_out($self, '$1 2 3$', 10, 240);
		Prima::TeX::TeX_out($self, '$\test 1 2 3 \test$', 10, 225);
		
		# binary operator spacing
		Prima::TeX::TeX_out($self, '$a + b$', 10, 205);
		Prima::TeX::TeX_out($self, '$a \times b$', 10, 190);
		
		
		#Prima::TeX::TeX_out($self, '123 $\alpha_3$ 456', 150, 150);
		#Prima::TeX::TeX_out($self, '$3 \times 4$', 150, 130);
		#Prima::TeX::TeX_out($self, '$( a^2 + b^2 )^{1/2}$', 150, 100);
		
		#$self->fill_ellipse(200, 200 + $self->font->height, 2, 2);
		#$self->font->direction(90);
		#$self->fill_ellipse(200, 200, 2, 2);
		#$self->text_out('test', 200, 200);
		#print "When direction is 90, width of 'why hello there' is ", $self->get_text_width('why hello there'), "\n";
		
		Prima::TeX::TeX_out($self, '123 $\alpha_3$ 456', 300, 300);
		Prima::TeX::TeX_out($self, '$h \to 0$', 300, 285);
		Prima::TeX::TeX_out($self, '$\mathcal{A} \to \mathcal{B}$', 300, 270);
		Prima::TeX::TeX_out($self, '$\mathfrak{C} \to \mathfrak{D}$', 300, 255);
		Prima::TeX::TeX_out($self, '$\Im \left\{ 1 + e^{\imath \, \theta} \right\}$', 300, 240);
		
		# Explicit code points for ...
		# Big Summation
		$self->text_out("\x{23B2}", 300, 220);
		$self->text_out("\x{23B3}", 300, 205);
		# Big Parenthesis
		$self->text_out("\x{239B}", 325, 220);
		$self->text_out("\x{239D}", 325, 205);
		
		# And back to our regular broadcast
		Prima::TeX::TeX_out($self, '$2 \nless 1, 1 \leq 2, 4 ~ 5\cdots, a \propto b$', 335, 212);
		Prima::TeX::TeX_out($self, '$2 + A^a_1 \frac{abc}{123}$', 335, 190);
		Prima::TeX::TeX_out($self, '$2 + A^a_1 \frac{\pi}{4}$', 335, 175);
		
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
