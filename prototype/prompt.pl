#!/usr/bin/env perl

use strict;
use warnings;
use Path::Class qw( dir );
use Git::Wrapper;
use File::HomeDir;
use Sys::Hostname qw( hostname );
use String::Truncate qw( elide );

my $red     = "%{\033[1;31m%}";
my $green   = "%{\033[0;32m%}";
my $yellow  = "%{\033[1;33m%}";
my $blue    = "%{\033[1;34m%}";
my $magenta = "%{\033[1;35m%}";
my $cyan    = "%{\033[1;36m%}";
my $white   = "%{\033[0;37m%}";
my $end     = "%{\033[0m%}";

my $hostname = hostname();
$hostname =~ s/\..*$//;

my $char = $> ? '%' : '#';

my $user = $ENV{USER} || 'unknown-user';

$user = $user =~ /^(ollisg|root)$/ ? '' : " \<$yellow$user$end\>";

my $dir = dir->absolute;
if("$dir" eq dir( File::HomeDir->my_home ))
{
  $dir = '~';
}
else
{
  $dir = $dir->basename;
  $dir = '/' if $dir eq '';
}

$dir = elide $dir, 18;

my $git = Git::Wrapper->new(".");
my($branch) = eval { grep { s/^\* //; } $git->branch };
unless($@)
{
  $branch =~ s/^\(detached from (.*)\)/$1/;
  $dir .= " $cyan$branch";
}

print "$white$hostname$end$user \[$green$dir$end\]$char \n";
