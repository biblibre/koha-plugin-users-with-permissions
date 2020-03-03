package Koha::Plugin::Com::BibLibre::UsersByPermissions;

use Modern::Perl;

use base qw(Koha::Plugins::Base);

use C4::Context;

our $VERSION = '1.0';

our $metadata = {
    name   => 'Users by Permissions',
    author => 'BibLibre',
    description => 'Display users by permissions',
    date_authored   => '2020-03-01',
    date_updated    => '2020-03-01',
    minimum_version => '18.11.00.000',
    maximum_version => undef,
    version         => $VERSION,
};

sub new {
    my ( $class, $args ) = @_;

    $args->{'metadata'} = $metadata;
    $args->{'metadata'}->{'class'} = $class;

    my $self = $class->SUPER::new($args);

    return $self;
}

sub tool {
    my ( $self, $args ) = @_;

    my $template = $self->get_template({ file => 'templates/home.tt' });

    return $self->output_html( $template->output() );
}

1;
