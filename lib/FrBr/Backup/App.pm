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
use DateTime;
use Math::BigInt;

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

use version; our $VERSION = qv("0.9.1"); $VERSION .= " r" . $Revis;

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

#---------------------------------------------------------------------------

=head2 backup_copies_monthly

Wieviele monatliche Backup-Kopien sollen aufbewahrt werden?

=cut

has 'backup_copies_monthly' => (
    is              => 'rw',
    isa             => 'UnsignedInt',
    traits          => [ 'Getopt' ],
    lazy            => 1,
    required        => 1,
    builder         => '_build_backup_copies_monthly',
    documentation   => 'Int: Wieviele monatliche Backup-Kopien sollen aufbewahrt werden? (default: 2).',
    cmd_flag        => 'backup-copies-monthly',
    cmd_aliases     => [ 'copies-monthly' ],
);

#--------------------

sub _build_backup_copies_monthly {
    return 3;
}

#---------------------------------------------------------------------------

=head2 backup_copies_weekly

Wieviele wöchentliche Backup-Kopien sollen aufbewahrt werden?

=cut

has 'backup_copies_weekly' => (
    is              => 'rw',
    isa             => 'UnsignedInt',
    traits          => [ 'Getopt' ],
    lazy            => 1,
    required        => 1,
    builder         => '_build_backup_copies_weekly',
    documentation   => 'Int: Wieviele wöchentliche Backup-Kopien sollen aufbewahrt werden? (default: 2).',
    cmd_flag        => 'backup-copies-weekly',
    cmd_aliases     => [ 'copies-weekly' ],
);

#--------------------

sub _build_backup_copies_weekly {
    return 2;
}

#---------------------------------------------------------------------------

=head2 backup_copies_daily

Wieviele tägliche Backup-Kopien sollen aufbewahrt werden?

=cut

has 'backup_copies_daily' => (
    is              => 'rw',
    isa             => 'UnsignedInt',
    traits          => [ 'Getopt' ],
    lazy            => 1,
    required        => 1,
    builder         => '_build_backup_copies_daily',
    documentation   => 'Int: Wieviele tägliche Backup-Kopien sollen aufbewahrt werden? (default: 2).',
    cmd_flag        => 'backup-copies-daily',
    cmd_aliases     => [ 'copies-daily' ],
);

#--------------------

sub _build_backup_copies_daily {
    return 3;
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

}

#---------------------------------------------------------------------------

after 'evaluate_config' => sub {

    my $self = shift;

    #return if $self->configuration_evaluated;
    $self->debug( "Werte Backup-Konfigurationsdinge aus ..." );
    return unless $self->config and keys %{ $self->config };

    my @ConfigKeys = qw( copies_yearly copies_monthly copies_weekly copies_daily);

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
        for my $f ( 'pidbase', 'pidfile', 'backup_copies_yearly', 'backup_copies_monthly', 'backup_copies_weekly', 'backup_copies_daily', ) {
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

    my $now = DateTime->now;
    my $dir_template = $now->strftime('%Y-%m-%d_%%02d');
    my $backup_dir;
    $self->debug( sprintf( "Backup-Verzeichnis-Template: '%s'", $dir_template ) );

    my $list = [];
    $list = $self->dir_list();
    $self->debug( "Ergebnis des Directory-Listings: ", [ map { $_->{'name'} } @$list ] );

    {
        my $i = 0;
        my $found = 1;
        while ( $found ) {
            $backup_dir = sprintf( $dir_template, $i );
            $self->debug( sprintf( "Suche nach neuem Backup-Verzeichnis: %s", $backup_dir ) );
            $found = undef;
            for my $dir ( map { $_->{'name'} } @$list ) {
                $found = 1 if $dir =~ /^\Q$backup_dir\E$/i;
            }
            $i++;
        }
    }
    $self->debug( sprintf( "Neues Backup-Verzeichnis gefunden: '%s'", $backup_dir ) );

    my $type_mapping = {
        'yearly'    => {},
        'monthly'   => {},
        'weekly'    => {},
        'daily'     => {},
        'other'     => {},
    };

    $type_mapping->{'yearly'}{ $backup_dir } = 1 if $now->month == 1 and $now->day == 1;    # 1. Januar
    $type_mapping->{'monthly'}{ $backup_dir } = 1 if $now->day == 1;                        # 1. des Monats
    $type_mapping->{'weekly'}{ $backup_dir } = 1 if $now->day_of_week == 7;                 # Sonntag
    $type_mapping->{'daily'}{ $backup_dir } = 1;                                            # Jeder Tag


    $self->map_dirs2types( $type_mapping, $list );
    $self->debug( "Zuordnung der gefundenen Verzeichnisse zu Backup-Typen: ", $type_mapping );

    my $dirs_delete = {};

    for my $type ( 'yearly', 'monthly', 'weekly', 'daily' ) {

        my $f = 'backup_copies_' . $type;
        my $max = $self->$f();
        $max = 0 if $max < 0;

        $self->debug( sprintf( "Maximale Zahl an Backup-Sets für '%s': %d", $type, $max ) );

        while ( scalar( keys %{ $type_mapping->{$type} } ) > $max ) {
            my $key = [ sort { lc($a) cmp lc($b) } keys %{ $type_mapping->{$type} } ]->[0];
            $self->debug( sprintf( "Lösche Key '%s' in Typ '%s' ...", $key, $type ) );
            delete $type_mapping->{$type}{$key};
        }

    }
    $self->debug( "Verbliebene Zuordnungen zu Backup-Typen: ", $type_mapping );

    for my $dir ( map { $_->{'name'} } @$list ) {
        my $do_delete = 1;
        for my $type ( 'yearly', 'monthly', 'weekly', 'daily', 'other' ) {
            if ( $type_mapping->{$type}{$dir} ) {
                $do_delete = undef;
            }
        }
        $dirs_delete->{$dir} = 1 if $do_delete;
    }
    $self->debug( "Verzeichnisse, die gelöscht werden sollen: ", $dirs_delete );

    $self->remove_recursive( sort { lc($a) cmp lc($b) } keys %$dirs_delete ) if keys %$dirs_delete;

    $self->ftp->mkdir( $backup_dir );
    if ( $self->ftp->cwd( $backup_dir ) ) {
        for my $f ( glob( '*' ) ) {
            next unless -f $f;
            my $fsize = -s $f;
            $self->info( sprintf( "Transferiere Datei '%s' (%s Byte%s) ...", $f, $fsize, ( $fsize > 1 ? 's' : '' ) ) );
            $self->ftp->put( $f );
        }
        $self->ftp->cdup;
    }
    else {
        $self->error( sprintf( "Wechsel in das Verzeichnis '%s' hat nicht geklappt: %s", $backup_dir, $self->ftp->message ) );
    }

    $list = $self->dir_list();
    $self->debug( "Ergebnis des Directory-Listings: ", [ map { $_->{'name'} } @$list ] ) if $self->verbose >= 3;

    my $total_size = Math::BigInt->new(0);

    my @Items = sort { lc($a) cmp lc($b) } map { $_->{'name'} } @$list;
    if ( @Items ) {
        my @Sizes = $self->disk_usage( @Items );
        my $i = 0;
        my $title = sprintf "Verbrauchter Speicherplatz in '%s':", $self->ftp_remote_dir;
        my $len = length($title);
        my $line = '=' x $len;
        printf "\n%s\n%s\n\n", $title, $line;
        my $max = length('Gesamt:');
        for my $item ( @Items ) {
            $max = length($item) if length($item) > $max;
        }
        while ( $i < scalar( @Items ) ) {
            my $item = $Items[$i];
            my $size = $Sizes[$i] || 0;
            $total_size->badd( Math::BigInt->new( $size ) );
            printf "%-*s %13s Byte%s\n", ( $max + 1 ), $item, $size, ( $size > 1 ? 's' : '' );
            $i++;
        }

        printf "\n%-*s %13s Bytes\n", ( $max + 1 ), 'Gesamt:', $total_size->bstr;

        printf "\n%s\n\n", $line;
    }

    # PID-File wieder wegschmeissen
    $self->debug( sprintf( "Lösche PID-File '%s' ...", $self->pidfile->file ) );
    $self->pidfile->remove if $self->pidfile->pid == $$;

}

#---------------------------------

sub map_dirs2types {

    my $self = shift;
    my $type_mapping = shift;
    my $list = shift;

    for my $entry ( @$list ) {

        # Nur Verzeichnisse gehören zum ordentlichen Backup
        if ( $entry->{'type'} ne 'd' ) {
            $type_mapping->{'other'}{ $entry->{'name'} } = 1;
            next;
        }

        my ( $year, $month, $day );
        unless ( ( $year, $month, $day ) = $entry->{'name'} =~ /^\s*(\d+)[_\-](\d+)[_\-](\d+)/ ) {
            # Passt nicht ins Namensschema
            $type_mapping->{'other'}{ $entry->{'name'} } = 1;
            next;
        }

        my $dt;
        eval {
            $dt = DateTime->new( year => $year, month => $month, day => $day, time_zone => $self->local_timezone );
        };
        if ( $@ ) {
            $self->debug( sprintf( "Ungültige Datumsangabe in '%s': %s", $entry->{'name'}, $@ ) );
            $type_mapping->{'other'}{ $entry->{'name'} } = 1;
            next;
        }

        $type_mapping->{'yearly'}{ $entry->{'name'} } = 1 if $dt->month == 1 and $dt->day == 1;     # 1. Januar
        $type_mapping->{'monthly'}{ $entry->{'name'} } = 1 if $dt->day == 1;                        # 1. des Monats
        $type_mapping->{'weekly'}{ $entry->{'name'} } = 1 if $dt->day_of_week == 7;                 # Sonntag
        $type_mapping->{'daily'}{ $entry->{'name'} } = 1;                                           # Jeder Tag

    }

}

###################################################################################

__PACKAGE__->meta->make_immutable;

1;

#------------------------------------------------------------------------------------------

__END__

# vim: noai: filetype=perl ts=4 sw=4 : expandtab
