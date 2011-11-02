#!/usr/bin/perl

use strict;
use warnings;

use utf8;

use Encode qw( decode_utf8 encode_utf8 );

# Own modules
use FindBin;
use lib "$FindBin::Bin/../lib";

#use FrBr::Backup::App;
require FrBr::Backup::App;

use version; our $VERSION = qv("0.0.2");

my $opts = {
    'progname' => 'backup-per-ftp',
    'ftp_auto_login' => 0,
};

my $app = FrBr::Backup::App->new_with_options(%$opts);

$app->run();

exit($app->exit_code);
#exit 0;


#--------------------------------------------------------------------------------

__END__

# vim: noai : ts=4 fenc=utf-8 filetype=perl expandtab :
