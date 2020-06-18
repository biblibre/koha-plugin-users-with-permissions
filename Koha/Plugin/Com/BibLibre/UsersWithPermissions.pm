package Koha::Plugin::Com::BibLibre::UsersWithPermissions;

use Modern::Perl;

use base qw(Koha::Plugins::Base);

use C4::Context;
use C4::Auth;
use Koha::Patrons;

our $VERSION = '1.2';

our $metadata = {
    name            => 'Users with Permissions',
    author          => 'BibLibre',
    description     => 'Display users with permissions',
    date_authored   => '2020-03-01',
    date_updated    => '2020-06-18',
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

# Mandatory even if does nothing
sub install {
    my ( $self, $args ) = @_;
 
    return 1;
}
 
# Mandatory even if does nothing
sub upgrade {
    my ( $self, $args ) = @_;
 
    return 1;
}
 
# Mandatory even if does nothing
sub uninstall {
    my ( $self, $args ) = @_;
 
    return 1;
}

sub tool {
    my ( $self, $args ) = @_;

    my $template = $self->get_template( { file => 'templates/home.tt' } );

    # Superlibrarians
    my @superlibrarians_loop;
    my $superlibrarian_patrons = Koha::Patrons->search( { flags => 1 } );
    while ( my $superlibrarian_patron = $superlibrarian_patrons->next ) {
        push @superlibrarians_loop, { patron => $superlibrarian_patron };
    }

    # Other staff
    my @staffs_loop;
    my $staff_patrons = Koha::Patrons->search( { flags => { '>' => 0, '!=' => 1 } } );
    while ( my $staff_patron = $staff_patrons->next ) {
        my $userflags = _getuserflags( $staff_patron->flags, $staff_patron->userid );
        push @staffs_loop,
          {
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

# Inspired by C4::Auth::getuserflags
sub _getuserflags {
    my $flags  = shift;
    my $userid = shift;
    my $dbh    = @_ ? shift : C4::Context->dbh;
    my $userflags;

    my $all_subperms = C4::Auth::get_all_subpermissions();

    my $sth = $dbh->prepare("SELECT bit, flag, defaulton FROM userflags");
    $sth->execute;

    while ( my ( $bit, $flag, $defaulton ) = $sth->fetchrow ) {
        if ( ( $flags & ( 2**$bit ) ) || $defaulton ) {
            if ( exists $all_subperms->{$flag} ){
                $userflags->{$flag} = $all_subperms->{$flag}; # add all sub-permissions
            } else {
                $userflags->{$flag} = 1; # no sub-permissions
            }
        }
    }

    # get subpermissions and merge with top-level permissions
    my $user_subperms = C4::Auth::get_user_subpermissions($userid);
    foreach my $flag ( keys %$user_subperms ) {
        $userflags->{$flag} = $user_subperms->{$flag};
    }

    return $userflags;
}

1;
