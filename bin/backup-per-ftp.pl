#!/usr/bin/perl

# $Id$
# $URL$

use strict;
use warnings;

use utf8;

use Encode qw( decode_utf8 encode_utf8 );

# Own modules
use FindBin;
use lib "$FindBin::Bin/../lib";

use FrBr::Backup::App;

use version; our $VERSION = qv("0.0.1");

my $opts = {
#    'progname' => 'backup-per-ftp',
};

my $app = FrBr::Backup::App->new_with_options(%$opts);
$app->evaluate_common_options();

#exit($app->exit_code);
exit 0;


#--------------------------------------------------------------------------------

__END__

# vim: noai : ts=4 fenc=utf-8 filetype=perl expandtab :
