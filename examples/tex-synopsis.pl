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
