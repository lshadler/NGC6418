# -*- cperl -*-
#
# $Id: SasServer.pm,v 1.7 2013/02/18 15:06:32 eojero Exp $
#
package SasServer;
require Net::FTP;
use Carp;
use strict;

my $server = 'xmm.esac.esa.int';
my $base   = '/pub/sasdev/private';
my $bdir   = $base . '/releases/';
my $updir  = $base . '/pkg-uploads';
my $buildir= $base . '/build-uploads';

my $pkgdir = $bdir . '/packages';
my $mandir = $bdir . '/manifests';

my $master_md5 = 'MD5SUMS';

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = {};
  my $log = shift;

  if(defined $ENV{'SAS_FTP_SERVER'}){
    $server = $ENV{'SAS_FTP_SERVER'};
  }
  if(defined $ENV{'SAS_FTP_DIR'}){
    $bdir = $ENV{'SAS_FTP_DIR'};
    $pkgdir = $bdir . '/packages';
    $mandir = $bdir . '/manifests';
  }

  $self->{logger} = $log;

  &$log("SAS server        : $server\n");
#  &$log("Packages in       : $pkgdir\n");
#  &$log("Manifests in      : $mandir\n");
#  &$log("Package uploads in: $updir\n");
#  &$log("Build uploads in  : $buildir\n");

  &$log("Connect and login ... ");
  my $ftp = Net::FTP->new($server) or
    croak("Cannot connect to $server\n");
  $ftp->login('anonymous', 'sasdev@xmm.esac.esa.int') or
    croak("Cannot login to $server\n");
  $ftp->binary();
  &$log("  ok\n");
  $self->{ftp} = $ftp;
  bless $self, $class;
  return $self;
}

sub _print {
  my $self = shift;
  &{$self->{logger}}(shift);
}

sub _get_file {
  my $self = shift;
  my $file = shift or return;
  my $ftp = $self->{ftp};
  if(not $ftp->ls($file)){
    croak("$file does not seem to be in the server. Report this.\n");
  }
  my $size = $ftp->size($file) / 1024.;
  $self->_print(sprintf "Fetching %s [%3.0f kB] ... ", $file, $size);
  my $tstart = time();
  if(not $ftp->get($file)){
    croak("Error while fetching $file.\n");
  }
  my $tstop = time();
  my $dt = $tstop - $tstart;
  $dt = 0.5 if ($dt <= 0.5);
  $self->_print(sprintf "done [%3.0f kB/s]", $size/$dt);
  return $size;
}

sub _put_file {
  my $self = shift;
  my $file = shift or return;
  my $ftp = $self->{ftp};
  if(!-r $file){
    croak("Cannot access $file\n");
  }
  my $size = -s $file;
  $size /= 1024.;
  $self->_print(sprintf "Uploading %s [%3.0f kB] ... ", $file, $size);
  my $tstart = time();
  if(not $ftp->put($file)){
    croak("Error while uploading $file\n");
  }
  my $tstop = time();
  my $dt = $tstop - $tstart;
  $dt = 0.5 if ($dt <= 0.5);
  $self->_print(sprintf "done [%3.0f kB/s]", $size/$dt);
  return $size;
}

sub get_md5sums {
  my $self = shift;
  my $ftp = $self->{ftp};
  $ftp->cwd($pkgdir) or croak("Cannot change directory to $pkgdir.\n");
  $self->_get_file($master_md5);
  $self->_print("\n");
  return $master_md5;
}

sub get_packages {
  my $self = shift;
  my $pkgs = shift or return;
  my $ftp = $self->{ftp};
  $ftp->cwd($pkgdir);

  my $totransfer = 0;
  foreach my $pkg (@{$pkgs}){
    my $size = $ftp->size($pkg) / 1024.;
    $totransfer += $size;
  }

  $self->_print(sprintf("Total ftp transfer will contain %d packages for %3.1f kbytes\n", scalar @{$pkgs}, $totransfer));

  my $transfered = 0;
  foreach my $pkg (@{$pkgs}){
    $transfered += $self->_get_file($pkg);
    $self->_print(sprintf " %3.1f %% complete.\n", $transfered/$totransfer*100);
  }
}

sub send_build_report {
  my $self = shift;
  my $file = shift or return;
  my $ftp = $self->{ftp};
  $ftp->cwd($buildir) or croak("Cannot change directory to $buildir\n");
  $self->_put_file($file);
  $self->_print("\n");
}


sub send_package {
  my $self = shift;
  my $pkg = shift or return;
  my $ftp = $self->{ftp};
  $ftp->cwd($updir) or croak("Cannot change directory to $updir\n");
  $self->_put_file($pkg);
  $self->_print("\n");
  $self->_put_file($pkg . ".asc");
  $self->_print("\n");
}


sub get_package {
  my $self = shift;
  my $pkg = shift or return;
  my $ftp = $self->{ftp};
  $ftp->cwd($pkgdir) or croak("Cannot change directory to $pkgdir\n");
  $ftp->_get_file($pkg);
  $self->_print("\n");
}

sub get_manifest {
  my $self = shift;
  my $alias = shift or return;
  my $manifest = $alias . '_md5sums';
  if($alias =~ /_md5sums$/){
    $manifest = $alias;
  }
  my $ftp = $self->{ftp};
  $ftp->cwd($mandir) or croak("Cannot change directory to $mandir\n");
  if($ftp->ls($manifest)){
    $self->_get_file($manifest);
    $self->_print("\n");
    return $manifest;
  } else {
    $self->_print("The manifest $manifest does not exist on the server: $alias is an alias.\n");
    $self->_get_file($alias);
    $self->_print("\n");
    return $alias;
  }
}

sub close {
  my $self = shift;
  $self->{ftp}->close();
}

sub list_manifests {
  my $self = shift;
  my $ftp = $self->{ftp};
  $ftp->cwd($mandir) or croak("Cannot change directory to $mandir\n");
  my @m = $ftp->ls("*_md5sums");
  print "There are ", scalar @m," manifests on the server:\n";
  foreach my $m (reverse sort @m) {
    $m =~ s/_md5sums$//;
    print "--> $m\n";
  }
}


sub list_packages {
  my $self = shift;
  my $ftp = $self->{ftp};
  $ftp->cwd($pkgdir) or croak("Cannot change directory to $pkgdir\n");
  my @p = $ftp->ls("*.tgz");
  print "There are ", scalar @p," packages on the server:\n";
  foreach my $p (sort @p) {
    print "--> $p\n";
  }
}

1;
