package FrBr::Backup::App;

# $Id$
# $URL$

=head1 NAME

FrBr::Backup::App

=head1 DESCRIPTION

Basismodul fuer Backup-Anwendung mittels FTP

=cut

#---------------------------------------------------------------------------

use Moose;
use MooseX::StrictConstructor;
use Moose::Util::TypeConstraints;


use utf8;

with 'FrBr::Common::MooseX::FtpClient';

#-----------------------------------------

# Versionitis

my $Revis = <<'ENDE';
    $Revision$
ENDE
$Revis =~ s/^.*:\s*(\S+)\s*\$.*/$1/s;

use version; our $VERSION = qv("0.0.3"); $VERSION .= " r" . $Revis;

#############################################################################################

=head1 Eigenschaften

=cut

#-----------------------------------------


#-----------------------------------------

# Ändern der Eigenschaften einiger geerbter Attribute

sub _build_version {
    return $VERSION;
}

###########################################################################

=head1 METHODS

Spezielle Methoden und Methodenmodifizierer dieser Anwendung

=cut

#---------------------------------

around BUILDARGS => sub {

    my $orig = shift;
    my $class = shift;

    my %Args = @_;

    #warn "Bin in '" . __PACKAGE__ . "'\n";

#    $Args{'show_sql'} = 1 if $Args{'verbose'} and $Args{'verbose'} >= 3;

    return $class->$orig(%Args);

};

#---------------------------------

sub BUILD {

    my $self = shift;

    #warn "Bin in '" . __PACKAGE__ . "::BUILD'\n";

#    $self->_init_log();
#    $self->read_config_file();
#    $self->evaluate_config();

    # Darstellen der Objektstruktur
#    if ( $self->verbose >= 2 ) {
#        # Aufwecken der faulen Hunde
#        my $tmp = $self->pidbase;
#        $tmp = $self->pidfile;
#        $tmp = $self->progname;
#        $tmp = $self->basedir;
#        $self->debug( "Anwendungsobjekt vor der Db-Schema-Initialisierung: ", $self );
#    }

#    $self->debug( "Bereit zum Kampf - äh - was auch immer." );

}


###################################################################################

__PACKAGE__->meta->make_immutable;

1;

#------------------------------------------------------------------------------------------

__END__

# vim: noai: filetype=perl ts=4 sw=4 : expandtab
