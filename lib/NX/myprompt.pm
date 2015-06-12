package NX::myprompt;

use strict;
use warnings;
use 5.010;
use Getopt::Long qw( GetOptions );
use Pod::Usage qw( pod2usage );
use File::Which qw( which );
use Capture::Tiny qw( capture );
use Shell::Guess;
use Shell::Config::Generate 0.09;

# ABSTRACT: Custom tcsh prompt for me
# VERSION

=head1 SEE ALSO

=over 4

=item L<myprompt>

=back

=cut

sub main
{
  shift; # class
  local @ARGV = @_;
  
  my $shell;
  my $help;
  my $version;
  
  GetOptions(
    'cshrc'     => sub { $shell = Shell::Guess->c_shell      },
    'shrc'      => sub { $shell = Shell::Guess->bourne_shell },
    'help|h'    => \$help,
    'version|v' => \$version,
  );
  
  pod2usage({ -verbose => 2 }) if $help;

  if($version)
  {
    say 'NX::myprompt version ', ($NX::myprompt::VERSION // 'dev');
    return 1;
  }
  
  elsif($shell)
  {
    return generate_rc($shell);
  }
  
  else
  {
    return generate_prompt();
  }
}

sub generate_rc
{
  my $shell  = shift;
  my $config = Shell::Config::Generate->new;
  
  generate_rc_ls($config);
  generate_rc_grep($config);
  
  $config->set_alias( rm => 'rm -i' );
  $config->set_alias( mv => 'mv -i' );
  $config->set_alias( cp => 'cp -i' );
  $config->set_alias( 'cpan-upload' => 'cpan-upload --user plicease' );

  if(which 'bsdtar')
  {
    $config->set_alias( tar => 'bsdtar' );
  }
  
  if($^O eq 'darwin')
  {
    $config->set_alias( ldd => 'otool -L' );
  }

  if((!! which 'ppkg-config') && (! which 'pkg-config'))
  {
    $config->set_alias( 'pkg-config' => 'ppkgconfig' );
  }

  generate_rc_df($config);  
  generate_rc_ed($config);
  generate_rc_locale($config);
  $config->set( LC_COLLATE => 'C' );

  if(which 'less')
  {
    $config->set( PAGER => 'less' );
  }

  print $config->generate( $shell );
  
  if($shell->is_c)
  {
    say 'uncomplete *';
    say 'unset autologout';
    say 'unhash';
    say 'nobeep';
  }
  
  0;
}

sub generate_rc_locale
{
  my($config) = @_;
  
  capture {
    if(grep /^en_US\.UTF-8$/, `locale -a`)
    {
      $config->set( LANG => 'en_US.UTF-8' );
    }
  };
}

sub generate_rc_ls
{
  my($config) = @_;

  my($out, undef) = capture {
    system 'ls', '--version';
  };
  if($out =~ /GNU/)
  {
    $config->set_alias( ls => 'ls -CF --color=auto' );
  }
  elsif(which 'gls')
  {
    $config->set_alias( ls => 'gls -CF --color=auto' );
  }
  
  $config->set_alias( dir => 'ls -l' );
}

sub generate_rc_grep
{
  my($config) = @_;
  
  foreach my $cmd (qw( grep egrep rgrep ))
  {
    my($out, undef) = capture {
      system $cmd, '--version';
    };
    if($out =~ /GNU/)
    {
      $config->set_alias( $cmd => "$cmd --color=auto" );
    }
    elsif(which "g$cmd")
    {
      $config->set_alias( $cmd => "g$cmd --color=auto" );
    }
  }
}

sub generate_rc_df
{
  my($config) = @_;
  
  my($out, undef) = capture {
    system 'df', '--version';
  };
  if($out =~ /GNU/)
  {
    $config->set_alias( df => 'df -h' );
  }
  elsif(which 'gdf')
  {
    $config->set_alias( df => 'gdf -h' );
  }
  else
  {
    $config->set_alias( df => 'df -h' );
  }
}

sub generate_rc_ed
{
  my($config) = @_;
  
  my $ed = (!!which 'nano') ? 'nano' : 'vi';

  if($ed eq 'nano')
  {
    $config->set_alias( nano => 'nano -w -z -x' );
    $config->set_alias( pico => 'nano' );
  }
  
  $config->set( VISUAL     => $ed );
  $config->set( EDITOR     => $ed );
}

sub generate_prompt
{
  0;
}

1;
