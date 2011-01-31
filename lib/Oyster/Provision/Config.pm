package Oyster::Provision::Config;
use Moose;
use namespace::autoclean;

for my $attr (qw( name size image pub_ssh )) {
    has $attr => (
        isa       => 'Str',
        is        => 'ro',
        writer    => "_${attr}",
        predicate => "has_${attr}",
        required  => 1,
    );
}

1
__END__
