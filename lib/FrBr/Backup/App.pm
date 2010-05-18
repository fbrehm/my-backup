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

use utf8;

use MooseX::Types::Path::Class;
use Path::Class;

extends 'FrBr::Common::MooseX::App';

with 'FrBr::Common::MooseX::Role::Config';
with 'FrBr::Common::MooseX::Role::FtpClient';
with 'MooseX::Daemonize::WithPidFile';

#-----------------------------------------

# Versionitis

my $Revis = <<'ENDE';
    $Revision$
ENDE
$Revis =~ s/^.*:\s*(\S+)\s*\$.*/$1/s;

use version; our $VERSION = qv("0.0.4"); $VERSION .= " r" . $Revis;

#############################################################################################

=head1 Eigenschaften

=cut

has pidbase => (
    is              => 'rw',
    isa             => 'Path::Class::Dir',
    metaclass       => 'Getopt',
    lazy            => 1,
    required        => 1,
    coerce          => 1,
    default         => sub { Path::Class::Dir->new('', 'var', 'run') },
    documentation   => 'Verzeichnis, in dem die PID-Datei abgelegt wird.',
    cmd_flag        => 'pidbase',
);

#---------------------------------------------------------------------------

=head2 backup_copies_yearly

Wieviele jährliche Backup-Kopien sollen aufbewahrt werden?

=cut

has 'backup_copies_yearly' => (
    is              => 'rw',
    isa             => 'UnsignedInt',
    traits          => [ 'Getopt' ],
    lazy            => 1,
    required        => 1,
    builder         => '_build_backup_copies_yearly',
    documentation   => 'Int: Wieviele jährliche Backup-Kopien sollen aufbewahrt werden? (default: 2).',
    cmd_flag        => 'backup-copies-yearly',
    cmd_aliases     => [ 'copies-yearly' ],
);

#--------------------

sub _build_backup_copies_yearly {
    return 2;
}

#-----------------------------------------

# Ändern der Eigenschaften einiger geerbter Attribute

sub _build_version {
    return $VERSION;
}

sub _build_ftp_auto_login {
    return 0;
}

sub _build_ftp_auto_init {
    return 0;
}

sub _build_ftp_host {
    return 'backup.serverkompetenz.de';
}

sub _build_ftp_user {
    return 'backup-user';
}

sub _build_ftp_local_dir {
    return dir->new( '/var/backup' );
}

sub _build_ftp_remote_dir {
    return dir->new( '/backup' );
}

#------------------------------------------

has '+pidfile' => (
    documentation   => 'PID-Datei',
);

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

## PID file related stuff ...

sub init_pidfile {
    my $self = shift;
    my $file = file->new( $self->pidbase, $self->progname . '.pid' );
    my $fname = $file->stringify;
    confess "Cannot write to $fname" unless (-e $fname ? -w $fname : -w $self->pidbase);
    $self->debug( sprintf( "PID-File: '%s'", $fname ) );
    MooseX::Daemonize::Pid::File->new( file => $fname );
}

# backwards compat,
sub check      { (shift)->pidfile->is_running }
sub save_pid   { (shift)->pidfile->write      }
sub remove_pid { (shift)->pidfile->remove     }
sub get_pid    { (shift)->pidfile->pid        }

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

#---------------------------------------------------------------------------

after 'evaluate_config' => sub {

    my $self = shift;

    #return if $self->configuration_evaluated;
    $self->debug( "Werte Backup-Konfigurationsdinge aus ..." );
    return unless $self->config and keys %{ $self->config };

    my @ConfigKeys = qw( copies_yearly );

    for my $key ( keys %{ $self->config } ) {

        my $val = $self->config->{$key};

        for my $p ( @ConfigKeys ) {
            my $f = 'backup_' . $p;
            my $r = $p;
            $r =~ s/_/\[_-\]\?/g;
            $r = "^backup[_\-]?$r\$";
            $self->debug( sprintf( "Regex 1: '%s'", $r ) ) if $self->verbose >= 4;
            unless ( $self->used_cmd_params->{$f} ) {
                if ( $key =~ /$r/i ) {
                    $self->debug( sprintf( "Gefunden: \$self->config->{%s} -> '%s'", $key, ( defined $val ? $val : '<undef>' ) ) ) if $self->verbose >= 2;
                    $self->$f($val);
                }
            }
        }

        if ( $key =~ /^pidbase$/i and $val ) {
            unless ( $self->used_cmd_params->{'pidbase'} ) {
                $self->debug( sprintf( "Gefunden: \$self->config->{%s} -> '%s'", $key, $val ) ) if $self->verbose >= 2;
                $self->pidbase($val);
            }
        }

    }

    for my $key ( keys %{ $self->config } ) {
        if ( lc($key) eq 'backup' and ref( $self->config->{$key} ) and ref( $self->config->{$key} ) eq 'HASH' ) {
            for my $ftp_key ( keys %{ $self->config->{$key} } ) {

                my $val = $self->config->{$key}{$ftp_key};

                for my $p ( @ConfigKeys ) {

                    my $f = 'backup_' . $p;
                    my $r = $p;
                    $r =~ s/_/\[_-\]\?/g;
                    $r = "^$r\$";
                    $self->debug( sprintf( "Regex 2: '%s'", $r ) ) if $self->verbose >= 4;

                    unless ( $self->used_cmd_params->{$f} ) {
                        if ( $ftp_key =~ /$r/i ) {
                            $self->debug( sprintf( "Gefunden: \$self->config->{%s}{%s} -> '%s'", $key, $ftp_key, ( defined $val ? $val : '<undef>' ) ) ) if $self->verbose >= 2;
                            $self->$f($val);
                        }
                    }

                }

            }
        }
    }

};

#---------------------------------------------------------------------------

after 'init_app' => sub {

    my $self = shift;

    return if $self->app_initialized;

    $self->debug( "Initialisiere ..." );

    if ( $self->verbose >= 2 ) {

        my $tmp;
        for my $f ( 'pidbase', 'pidfile', 'backup_copies_yearly', ) {
            $tmp = $self->$f();
        }

    }

};

#---------------------------------

=head2 run( )

Die eigentliche Startroutine der Anwendung.

=cut

sub run {

    my $self = shift;

    # Gucken, ob es ein PID-File gibt und ob da etwas sinnvolles drin steht
    if ($self->pidfile->is_running) {
        $self->exit_code($self->OK);
        my $msg = sprintf( "%s läuft noch mit PID (%s)", $self->progname, $self->pidfile->pid );
        $self->info($msg);
        #$self->status_message($msg);
        return !($self->exit_code);
    }
    # PID-File schreiben
    $self->debug( sprintf( "Schreibe PID-File '%s' ...", $self->pidfile->file ) );
    $self->pidfile->pid($$);
    $self->pidfile->write;

    $self->info( "Verbinde mich FTP-Server ..." );

    unless ( $self->init_ftp() ) {
        $self->exit_code( 5 );
        return;
    }

    unless ( $self->login_ftp() ) {
        $self->exit_code( 6 );
        return;
    }

    $self->info( "Beginne Backup." );

    # Erst mal nur zum Spielen ...
    #$self->ftp->cwd;
    my $list = [];
    $list = $self->dir_list();
    $self->debug( "Ergebnis des Directory-Listings: ", $list );

    # PID-File wieder wegschmeissen
    $self->debug( sprintf( "Lösche PID-File '%s' ...", $self->pidfile->file ) );
    $self->pidfile->remove if $self->pidfile->pid == $$;

}

###################################################################################

__PACKAGE__->meta->make_immutable;

1;

#------------------------------------------------------------------------------------------

__END__

# vim: noai: filetype=perl ts=4 sw=4 : expandtab
