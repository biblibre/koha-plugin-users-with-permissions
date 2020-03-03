package Koha::Plugin::Com::BibLibre::UsersByPermissions;

use Modern::Perl;

use base qw(Koha::Plugins::Base);

use C4::Context;
use C4::Auth;
use Koha::Patrons;

our $VERSION = '1.0';

our $metadata = {
    name            => 'Users by Permissions',
    author          => 'BibLibre',
    description     => 'Display users by permissions',
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

    my $template = $self->get_template( { file => 'templates/home.tt' } );

    # Superlibrarians
    my @superlibrarians_loop;
    my $superlibrarian_patrons = Koha::Patrons->search(
        {
            flags => 1,
        },
        {
            order_by => { -desc => 'borrowernumber' },
        }
    );
    while ( my $superlibrarian_patron = $superlibrarian_patrons->next ) {
        push @superlibrarians_loop, { patron => $superlibrarian_patron };
    }

    # Other staff
    my @staffs_loop;
    my $staff_patrons = Koha::Patrons->search(
        {
            flags => { '>' => 0, '!=' => 1 },
        },
        {
            order_by => { -desc => 'flags', -desc => 'borrowernumber' },
        }
    );
    while ( my $staff_patron = $staff_patrons->next ) {
        my $userflags = C4::Auth::getuserflags( $staff_patron->flags, $staff_patron->userid );
        push @staffs_loop, {
            patron    => $staff_patron,
            userflags => $userflags,
        };
    }

    $template->param(
        superlibrarians => \@superlibrarians_loop,
        staffs          => \@staffs_loop,
    );

    return $self->output_html( $template->output() );
}

1;
