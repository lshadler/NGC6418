#!perl
#
# Service functions used by modules, etc.
#

package ModuleResources;

require 5.005;

# rgw 05-Jan-1998
# dah 20-Nov-2000 Change findFile so it returns an empty array in array 
#                 context if no files are found.
# dah 13-Dec-2000 Downgrade 'ambiguous file' in fileInfo from error to info.
# djf 21-Aug-2001 Added fetch for orbit no to getObservationProperties

# System modules
use English;
use Carp;
use strict qw{vars subs};
#use Experimental::Exception;
use Exporter;
use Cwd;
use File::Basename qw(basename);
use File::Copy qw(copy);
use POSIX qw(:fcntl_h :sys_wait_h :signal_h strftime);
use Time::HiRes qw(time sleep);

use vars qw(@ISA @EXPORT);
@ISA=qw(Exporter);
@EXPORT=qw(
    allComplete
    allIgnored
    complete
    copyFile
    doCommand
    energyBand
    energyConversionFactor
    exception
    fileExists
    findFile
    getExposureProperty
    hardnessBands
    hasFITSKeyword
    ignore
    ignored
    info
    listExposures
    newFile
    numberFITSRows
    readFITSKeyword
    start
    success
    thisInstrument
);

  #---------------------------------------------------------------------
  sub allComplete {
  #---------------------------------------------------------------------
    my (%args) = @_;

    if (defined($args{module})) {
      my $module = $args{module};
      if (defined($args{instrument})) {
        my $inst = $args{instrument};
        if (defined($args{stream})) {
  return 0 if (!complete(%args) && !ignored(%args));
        } else { # cycle thru all the streams
          foreach my $stream (keys(%{$main::moduleStatus{$module}{$inst}})) {
            $args{stream} = $stream;
  return 0 if (!allComplete(%args));
          }
        }
      } else { # cycle thru all the insts
        foreach my $inst (keys(%{$main::moduleStatus{$module}})) {
          $args{instrument} = $inst;
  return 0 if (!allComplete(%args));
        }
      }
    } else { # cycle thru all the modules
      foreach my $module (keys(%main::moduleStatus)) {
        $args{module} = $module;
  return 0 if (!allComplete(%args));
      }
    }

  return 1;
  }

  #---------------------------------------------------------------------
  sub allIgnored {
  #---------------------------------------------------------------------
    my (%args) = @_;

    if (defined($args{module})) {
      my $module = $args{module};
      if (defined($args{instrument})) {
        my $inst = $args{instrument};
        if (defined($args{stream})) {
  return 0 if (!ignored(%args));
        } else { # cycle thru all the streams
          foreach my $stream (keys(%{$main::moduleStatus{$module}{$inst}})) {
            $args{stream} = $stream;
  return 0 if (!allIgnored(%args));
          }
        }
      } else { # cycle thru all the insts
        foreach my $inst (keys(%{$main::moduleStatus{$module}})) {
          $args{instrument} = $inst;
  return 0 if (!allIgnored(%args));
        }
      }
    } else { # cycle thru all the modules
      foreach my $module (keys(%main::moduleStatus)) {
        $args{module} = $module;
  return 0 if (!allIgnored(%args));
      }
    }

  return 1;
  }

  #---------------------------------------------------------------------
  sub complete {
  #---------------------------------------------------------------------
    my (%args) = @_;
    my ($module, $inst, $stream);

    if (defined($args{module})) {
      $module = $args{module};
    } else {
      $module = $main::currentModule;
    }

    if (defined($args{instrument})) {
      $inst = $args{instrument};
    } else {
      $inst = $main::currentInst;
    }

    if (defined($args{stream})) {
      $stream = $args{stream};
    } else {
      $stream = $main::currentStream;
    }

#print "sub complete(): module=$module\n";
#print "sub complete(): inst=$inst\n";
#print "sub complete(): stream=$stream\n";

#die "No status info for module $module" if (!defined($main::moduleStatus{$module}));
SAS::error('noStatusInfo', "No status info for module $module")
    if (!defined($main::moduleStatus{$module}));

    my %moduleStatusHash = %{$main::moduleStatus{$module}};

#die "No status info for instrument $inst, module $module" if (!defined($moduleStatusHash{$inst}));
SAS::error('noStatusInfo', "No status info for instrument $inst, module $module")
    if (!defined($moduleStatusHash{$inst}));

    my %instStatusHash = %{$moduleStatusHash{$inst}};

#die "No status info for stream $stream, instrument $inst, module $module" if (!defined($instStatusHash{$stream}));
SAS::error('noStatusInfo', "No status info for stream $stream, instrument $inst, module $module")
    if (!defined($instStatusHash{$stream}));

    my $streamStatus = $instStatusHash{$stream};

#    my @inst_list = ();
#    if ($inst eq 'epic') {
#      @inst_list = qw(epn emos1 emos2);
#    } elsif ($inst eq 'rgs') {
#      @inst_list = qw(rgs1 rgs2);
#    } elsif ($inst eq 'all') {
#      @inst_list = qw(epn emos1 emos2 rgs1 rgs2 om);
#    } else {
###      if ($main::moduleStatus{$module}{$inst}{$stream} eq 'complete') {
if ($streamStatus eq 'complete') {
  return 1;
      } else {
  return 0;
      }
#    }
#
#    foreach my $sub_inst (@inst_list) {
#  return 0 if (!&complete(
#       module     => $module
#      ,instrument => $sub_inst
#      ,stream     => $stream));
#    }
#  return 1;

  }

  #---------------------------------------------------------------------
  sub copyFile {
  #---------------------------------------------------------------------
    my %args = @_;

#die "Need source and destination arguments to copyFile"
SAS::error('badCopyFileArgs', "Need source and destination arguments to copyFile")
    if (!defined($args{source}) || !defined($args{destination}));

    my $command = "cp $args{source} $args{destination}";
    my $status = 0;

#    print "\ninvoke $command\n\n";
    SAS::message($SAS::AppMsg, $SAS::VerboseMsg, "invoke $command\n");
    if (!$main::testFlag) {
      $status = system($command);
#      $status = 0 if ($status);
    } else {
  return 1;
    }

  return $status;
  }

  #---------------------------------------------------------------------
  sub doCommand {
  #---------------------------------------------------------------------

#print "starting doCommand\n";
#print "testFlag = $main::testFlag\n";

    my ($taskname0, %args) = @_;
    my $status = 1;
#    if ($main::testflag) {$status = 0}

    my $command = "$taskname0";
    my @pars = keys(%args);
    foreach my $par (@pars){
      my $value = $args{"$par"};
#print "  par, value: $par $value\n";
      if (ref($value) eq 'ARRAY') {
        my @temparray = @{$value};
	if ( grep(/[']/, @temparray) ){ #'
          $command .= " $par=".'"'.join(' ', @temparray).'"';
	} else {
          $command .= " $par='".join(' ', @temparray)."'";
	}
      } elsif (ref($value)) { # can't deal with other types of reference
#print "Leaving doCommand. status=0\n";
  return 1;
      } elsif ($value =~ /\s+/) { # argument contains whitespace
	if ( $value =~ /[']/ ) { # '
          $command .= " $par=".'"'.$value.'"';
	} else {
          $command .= " $par='".$value."'";
	}
      } else {
        $command .= " $par=$value";
      }
    }

    $status = 0;

#    print "\ninvoke $command\n\n";
    SAS::message($SAS::AppMsg, $SAS::VerboseMsg, " ");
    if ( $command =~ /['"]/ ) { # "'
      print "invoke ".$command."\n";	# SAS::message would cause an error!
    } else {
      SAS::message($SAS::AppMsg, $SAS::VerboseMsg, "invoke ".$command."\n");
    }
    if (!$main::testFlag) {
      $status = system($command);
#print "status=$status\n";
#      $status = 0 if ($status);
    } else {
#print "Leaving doCommand. status=1\n";
  return 1;
    }

#print "Leaving doCommand. status=$status\n";
  return !$status;
  }

  #---------------------------------------------------------------------
  sub energyBand {
  #---------------------------------------------------------------------
    my ($band, $hilo) = @_;

#die "Must give band and side as arguments to energyBand"
SAS::error('badEnergyBandArgs', "Must give band and side as arguments to energyBand")
    if (!defined($band) || !defined($hilo));

#die "Side must be 0 or 1"
SAS::error('badEnergyBandArgSide', "Side must be 0 or 1")
    if ($hilo != 0 && $hilo != 1);

    my @ecf_info = @{$main::ecf_ref};
SAS::error('noEcfsFound', "No ECF entries were returned by readEcfs.")
#die "No ECF entries were returned by readEcfs."
    if (@ecf_info <= 0);

    my $band_edge = 0;
    my $band_found = 0;
    foreach my $i (0 .. $#ecf_info) {
SAS::error('badEcfStructure', "No band id data returned in the ECF hash.")
      if (!defined($ecf_info[$i]{'bandid'}));

      my $test_band = $ecf_info[$i]{'bandid'};
      if ($test_band eq $band){
        $band_found = 1;
        my @band_ranges = @{$ecf_info[$i]{'edges'}};

        if ($hilo == 0) {
          $band_edge = $band_ranges[0            ]{'lo'};
        } else {
          $band_edge = $band_ranges[$#band_ranges]{'hi'};
        }
    last;
      }
    }

SAS::error('badBand', "Can't find energy boundaries for band $band.")
    if (!$band_found);

  return $band_edge;
  }

  #---------------------------------------------------------------------
  sub energyConversionFactor {
  #---------------------------------------------------------------------
    my ($inst_lc, $filter, $band) = @_;

    my $inst_uc = $main::inst_lc2uc{$inst_lc};
#SAS::error('filterNotYetSupported', "Can't yet get ECF for filter $filter.")
#    if (uc($filter) !~ 'THIN');

    my @ecf_info = @{$main::ecf_ref};
SAS::error('noEcfsFound', "No ECF entries were returned by readEcfs.")
    if (@ecf_info <= 0);

SAS::error('badEcfStructure', "No instrument data returned in the ECF hash.")
    if (!defined($ecf_info[0]{'instrums'}));

    my $ecf;
    my $band_found = 0;
    foreach my $i (0 .. $#ecf_info) {
      my $test_band = $ecf_info[$i]{'bandid'};
      if ($test_band eq $band){
        $band_found = 1;
        my %filter_lists = %{$ecf_info[$i]{'instrums'}};
SAS::error('filterNotYetSupported', "Can't yet get ECF for filter $filter.")
#        if (!defined($filter_lists{$inst_uc}{uc($filter)}));
        if (!defined($filter_lists{$inst_uc}{uc($filter)}{'ECF'}));
##        $ecf = $filter_lists{$inst_uc}{'THIN'};
#        $ecf = $filter_lists{$inst_uc}{uc($filter)};
        $ecf = $filter_lists{$inst_uc}{uc($filter)}{'ECF'};
    last;
      }
    }
SAS::error('noEcfThisBand', "Can't find ECF for band $band.")
    if (!$band_found);

  return $ecf;
  }

  #---------------------------------------------------------------------
  sub energyConversionFactor_old {
  #---------------------------------------------------------------------
    my ($inst_lc, $filter, $band) = @_;

    my $inst_uc = $main::inst_lc2uc{$inst_lc};
#    my $temp_ascii = "$main::simgen_subdir/Sim_temp.txt";
SAS::error('filterNotYetSupported', "Can't yet get ECF for filter $filter.")
#die "Can't yet get ECF for filter $filter."
    if (uc($filter) !~ 'THIN');

#print "template_set = $main::template_set\n";
#die "bleah";

#    my ($ref, $sim_fluxDensityToFlux)
#      = &eimsimperlsubs::readEcfs_new($main::template_set, $temp_ascii, $main::testFlag);
    my @ecf_info = @{$main::ecf_ref};
SAS::error('noEcfsFound', "No ECF entries were returned by readEcfs.")
#die "No ECF entries were returned by readEcfs."
    if (@ecf_info <= 0);

SAS::error('badEcfStructure', "No instrument data returned in the ECF hash.")
#die "No instrument data returned in the ECF hash."
    if (!defined($ecf_info[0]{'instrums'}));

    my $ecf;
    my $band_found = 0;
    foreach my $i (0 .. $#ecf_info) {
      my $test_band = $ecf_info[$i]{'bandid'};
      if ($test_band eq $band){
        $band_found = 1;
        my %filter_lists = %{$ecf_info[$i]{'instrums'}};
#        $ecf = $filter_lists{$inst_uc}{uc($filter)};
$ecf = $filter_lists{$inst_uc}{'THIN'};
    last;
      }
    }
#die "Can't find ECF for band $band."
SAS::error('noEcfThisBand', "Can't find ECF for band $band.")
    if (!$band_found);

#print "ECF for inst $inst_uc".", band $band is $ecf\n";

  return $ecf;
  }

  #---------------------------------------------------------------------
  sub exception {
  #---------------------------------------------------------------------
#print "sub exception(): module=$main::currentModule\n";
#print "sub exception(): inst=$main::currentInst\n";
#print "sub exception(): stream=$main::currentStream\n";

    $main::moduleStatus{$main::currentModule}{$main::currentInst}
      {$main::currentStream} = 'exception';

  return 0;
  }

  #---------------------------------------------------------------------
  sub fileExists {
  #---------------------------------------------------------------------

    my (%args) = @_;

    if ($main::testFlag || -e "$args{file}") {
  return 1;
    } else {
  return 0;
    }
  }

  #---------------------------------------------------------------------
  sub findFile {
  #---------------------------------------------------------------------

    my (%args) = @_;

    my ($inst_lc, $expid, $band, $inst_uc, $srcid, $sim_prefix, $prod_prefix, $pseudo_prod_prefix);

    my $content = lc($args{content});

    if (defined($args{instrument})) {
      $inst_lc = $args{instrument};
    } else {
      $inst_lc = 'obs';
    }

    if (defined($args{exp_id})) {
      $expid = $args{exp_id};
    } else {
      $expid = 'X000';
    }

    if (defined($args{band})) {
      $band  = $args{band};
    } else {
      $band  = '0';
    }

    if (defined($args{src_num})) {
      $srcid   = $args{src_num};
      $srcid   = ('0'x(3-length($srcid))).$srcid;
    } else {
      $srcid  = '000';
    }

    $inst_uc = $main::inst_lc2uc{$inst_lc};

    if (defined($args{instrument})) {
#print "main::simop_dir=$main::simop_dir\n";
#print "main::prod_dir=$main::prod_dir\n";
#print "main::pseudoprod_dir=$main::pseudoprod_dir\n";
#print "main::id_str=$main::id_str\n";
#print "main::obsid=$main::obsid\n";
#print "inst_uc=$inst_uc\n";
#print "expid=$expid\n";
      $sim_prefix         = "$main::simop_dir"     ."/P$main::id_str$inst_uc$expid";
      $prod_prefix        = "$main::prod_dir"      ."/P$main::obsid$inst_uc$expid";
      $pseudo_prod_prefix = "$main::pseudoprod_dir"."/P$main::obsid$inst_uc$expid";
    }

    my $file;
    if ($content eq 'epic image'){
      $file = "$sim_prefix"."IMAGE_$band"."000.FIT";

    } elsif($content eq 'epic exposure map') {
      $file = "$prod_prefix"."EXPMAP$band"."000.FIT";

    } elsif($content eq 'non-vig exposure map') {
      $file = "$pseudo_prod_prefix"."NVGMAP$band"."000.FIT";

    } elsif($content eq 'image event list') { # $expid should be normal
      $file = "$main::simop_dir/Sim_$inst_uc$expid"."_imageEventList_$band.fits";
#      if ($inst_uc eq 'PN') {
##        $file = "$main::prod_dir/$file_prefix"."PIEVLI0000.FIT";
#        $file = "$sim_prefix"."PIEVLI$band"."000.FIT";
#      } else {
##        $file = "$main::prod_dir/$file_prefix"."MIEVLI0000.FIT";
#        $file = "$sim_prefix"."MIEVLI$band"."000.FIT";
#      }

    } elsif($content eq 'image merged event list') { # $expid should be X000
      $file = "$main::simop_dir/Sim_$inst_uc$expid"."_imageEventList_$band.fits";
#      if ($inst_uc eq 'PN') {
#        $file = "$sim_prefix"."PIEVLI$band"."000.FIT";
#      } else {
#        $file = "$sim_prefix"."MIEVLI$band"."000.FIT";
#      }

    } elsif($content eq 'intermediate merged event list') {
      $file = "$main::simop_dir/Sim_$inst_uc$expid"."_intermediateMergedEventList_$srcid.fits";
#      if ($inst_uc eq 'PN') {
#        $file = "$sim_prefix"."PIEVLI000$srcid.FIT";
#      } else {
#        $file = "$sim_prefix"."MIEVLI000$srcid.FIT";
#      }

    } elsif ($content eq 'merged image'){
      $file = "$sim_prefix"."IMAGE_$band"."000.FIT";

    } elsif($content eq 'merged exposure map') {
      $file = "$sim_prefix"."EXPMAP$band"."000.FIT";

    } elsif ($content eq 'generic temporary dataset'){
      $file = "$main::simgen_subdir/Sim_tempImage_$main::id_str.fits";

    } elsif($content eq 'merged non-vig exp map') {
      $file = "$sim_prefix"."NVGMAP$band"."000.FIT";

    } elsif($content eq 'added exposure map') {
      $file = "$main::simop_dir/P$main::id_str$inst_uc"."Y000EXPMAP$band"."000.FIT";

    } elsif($content eq 'epic merged background map') { # should have $expid=X000.
      $file = "$sim_prefix"."BKGMAP$band"."000.FIT";

    } elsif($content eq 'merged background map') { # should have usual $expid.
      $file = "$sim_prefix"."BKGMAP$band"."000.FIT";

    } elsif($content eq 'epic detection mask') {
      $file = "$main::simop_dir/Sim_$inst_uc$expid"."_edetectMask.fits";

    } elsif($content eq 'epic observation box-local source list') {
      $file = "$sim_prefix"."EBLSLI0000.FIT";

    } elsif($content eq 'epic observation box-map source list') {
      $file = "$sim_prefix"."EBMSLI0000.FIT";

    } elsif($content eq 'epic observation ml source list') {
      $file = "$sim_prefix"."EMSRLI0000.FIT";

    } elsif($content eq 'ml xid source list') {
      $file = "$sim_prefix"."EMSRLI9000.FIT";

    } elsif($content eq 'temporaryimage') {
      $file = "$main::simop_dir/Sim_$inst_uc$expid"."_tempImage.fits";

    } elsif($content eq 'epic observation sensitivity map') {
      $file = "$main::simop_dir/Sim_$inst_uc$expid"."_sensitivityMap.fits";

    } else {
#die "Don't recognise content string $content";
SAS::error('badFindFileArgContent', "Don't recognise content string $content");
    }

  return $file;
  }

  #---------------------------------------------------------------------
  sub getExposureProperty {
  #---------------------------------------------------------------------

    my %d=@ARG;

    # Check argument
    my $exposure_property=lc $d{'name'};
    die 'Exposure property not defined'
      unless $exposure_property;
    die "Property '$exposure_property' not known"
      unless grep(/$exposure_property/, qw(exp_id exp_start exp_stop exp_duration
			     filter detector datamode));

    my %exp_prop_2_kwd_name = (
      exp_id       => 'EXP_ID',
      exp_start    => 'DATE-OBS',
      exp_stop     => 'DATE-END',
#      exp_duration => 'TELAPSE',
      exp_duration => 'ONTIME',
      filter       => 'FILTER',
      detector     => 'INSTRUME',
      datamode     => 'DATAMODE'
    );

    my $kwd_name = $exp_prop_2_kwd_name{$exposure_property};

    my $inst_lc=$d{'instrument'};
    my $expid=$d{'exp_id'};

#print "inst=$inst_lc   expid=$expid    kwd_name=$kwd_name\n";
    my $evlist = $main::evlists{$inst_lc}{$expid};
#print "evlist=$evlist\n";

    my $kwd = readFITSKeyword(
      file => $evlist
      , extension => 'EVENTS'
      , keyword => uc($kwd_name)
    );
#print "kwd=$kwd\n";

  return $kwd;
  }

  #---------------------------------------------------------------------
  sub hardnessBands {
  #---------------------------------------------------------------------
  return [1, 1, 2, 2, 3, 3];
  }

  #---------------------------------------------------------------------
  sub hasFITSKeyword {
  #---------------------------------------------------------------------

  return 1 if ($main::testFlag);

    my %d=@ARG;

    my $file      = $d{file};
    my $extension = $d{extension};
    my $keyword   = $d{keyword};
#print "file=$file\n";
#print "extension=$extension\n";
#print "keyword=$keyword\n";

    my $kwd = readFITSKeyword(
      file        => $file
      , extension => $extension
      , keyword   => $keyword
    );
#print "kwd=$kwd\n";

    if (!defined($kwd) || $kwd eq '') {
  return 0;
    } else {
  return 1;
    }

  }

  #---------------------------------------------------------------------
  sub ignore {
  #---------------------------------------------------------------------
#print "sub ignore(): module=$main::currentModule\n";
#print "sub ignore(): inst=$main::currentInst\n";
#print "sub success(): stream=$main::currentStream\n";

    $main::moduleStatus{$main::currentModule}{$main::currentInst}
      {$main::currentStream} = 'ignored';

  return 1;
  }

  #---------------------------------------------------------------------
  sub ignored {
  #---------------------------------------------------------------------
    my (%args) = @_;
    my ($module, $inst, $stream);

    if (defined($args{module})) {
      $module = $args{module};
    } else {
      $module = $main::currentModule;
    }

    if (defined($args{instrument})) {
      $inst = $args{instrument};
    } else {
      $inst = $main::currentInst;
    }

    if (defined($args{stream})) {
      $stream = $args{stream};
    } else {
      $stream = $main::currentStream;
    }

#print "sub ignored(): module=$module\n";
#print "sub ignored(): inst=$inst\n";
#print "sub ignored(): stream=$stream\n";

#    my @inst_list = ();
#    if ($inst eq 'epic') {
#      @inst_list = qw(epn emos1 emos2);
#    } elsif ($inst eq 'rgs') {
#      @inst_list = qw(rgs1 rgs2);
#    } elsif ($inst eq 'all') {
#      @inst_list = qw(epn emos1 emos2 rgs1 rgs2 om);
#    } else {
      if ($main::moduleStatus{$module}{$inst}{$stream} eq 'ignored') {
  return 1;
      } else {
  return 0;
      }
#    }
#
#    foreach my $sub_inst (@inst_list) {
#  return 0 if (!&complete(
#       module     => $module
#      ,instrument => $sub_inst
#      ,stream     => $stream));
#    }
#  return 1;

  }

  #---------------------------------------------------------------------
  sub info {
  #---------------------------------------------------------------------
    my ($message) = @_;
#    print "#INFO() $message\n";
    SAS::message($SAS::AppMsg, $SAS::VerboseMsg, "#INFO() $message");
  }

  #---------------------------------------------------------------------
  sub listExposures {
  #---------------------------------------------------------------------
    my (%args) = @_;
    my $inst   = $args{'instrument'};
    my @exp_ids = @{$main::expIds{$inst}};

  return @exp_ids;
  }

  #---------------------------------------------------------------------
  sub newFile {
  #---------------------------------------------------------------------

    my $file = findFile(@_);

    my (%args) = @_;
    my ($inst_lc, $expid, $band, $inst_uc, $srcid, $sim_prefix);

    my $content = lc($args{content});

    if (defined($args{instrument})) {
      $inst_lc = $args{instrument};
    } else {
      $inst_lc = 'obs';
    }

    if (defined($args{exp_id})) {
      $expid = $args{exp_id};
    } else {
      $expid = 'X000';
    }

    if (defined($args{band})) {
      $band  = $args{band};
    } else {
      $band  = '0';
    }

    if (defined($args{src_num})) {
      $srcid   = $args{src_num};
      $srcid   = ('0'x(3-len($srcid))).$srcid;
    } else {
      $srcid  = '000';
    }

    $main::newFiles{$content}{$inst_lc}{$expid}{$band}{$srcid} = $file;

    unlink $file if (!$main::testFlag && -e "$file");
    # Necessary because the modules call some ftools without clobber.

  return $file;
  }

  #---------------------------------------------------------------------
  sub numberFITSRows {
  #---------------------------------------------------------------------
  return 1; # just for test purposes.
####
  }

  #---------------------------------------------------------------------
  sub readFITSKeyword {
  #---------------------------------------------------------------------

    my ($rump, $next_quote);

    my %args = @_;

#die "Need file and keyword arguments to readFITSKeyword"
SAS::error('badReadFITSKeywordArgs',"Need file (".$args{file}.") and keyword (".$args{keyword}.") arguments to readFITSKeyword")
    if (!defined($args{file}) || !defined($args{keyword}));

    my $file = $args{file};
    my $kwd_name = $args{keyword};
#print "keyname=$kwd_name\n";

    my $value;
    if ($main::testFlag && !-e "$file") {
#print "keyname=$kwd_name\n";
      if (    $kwd_name eq 'BKGDSCRN'){
        $value = 1;
      } elsif($kwd_name eq 'EXPID01') {
        $value = 'X000';
#print "value=$value\n";
      } elsif($kwd_name eq 'EXPID02') {
      } elsif($kwd_name eq 'FILTER') {
        $value = 'Thin';
      } elsif($kwd_name eq 'ONTIME') {
        $value = 1;
      } elsif($kwd_name eq 'DATAMODE') {
        $value = 'Imaging';
      } else {
        $value = '999';
      }
  return $value;
    }

    my $command;
    if (defined($args{extension})){
      my $ext = $args{extension};
      $command = "fkeyprint '$file"."[$ext]' $kwd_name";
    } else {
      $command = "fkeyprint $file"."+0 $kwd_name";
    }

    my @lines = `$command`;
    foreach (@lines){
      chomp;
      if (/^$kwd_name\s*=\s*/) {
        $rump = $'; #' # bit after ';' is just to fool the gedit colourer.
        if (substr($rump, 0, 1) eq "'") { # then value is a string;
          $next_quote = index($rump, "'", 1);
          if ($next_quote > 0) {
            $value = substr($rump, 1, $next_quote - 1);
    last;
          }

        } else {
          if ($rump =~ /\s*\//) { # then there is a comment.
            $value = $`; #` # bit after ';' is just to fool the gedit colourer.
          } else { # there is no comment.
            $value = $rump;
            $value =~ s/\s+$//;
          }
    last;
        }
      }
    }

#print "\n* $value *\n\n";
#exit 1;

  return $value;
  }

  #---------------------------------------------------------------------
  sub start {
  #---------------------------------------------------------------------
#print "sub start(): module=$main::currentModule\n";
#print "sub start(): inst=$main::currentInst\n";
#print "sub start(): stream=$main::currentStream\n";

    $main::moduleStatus{$main::currentModule}{$main::currentInst}
      {$main::currentStream} = 'queued';
  }

  #---------------------------------------------------------------------
  sub success {
  #---------------------------------------------------------------------
#print "sub success(): module=$main::currentModule\n";
#print "sub success(): inst=$main::currentInst\n";
#print "sub success(): stream=$main::currentStream\n";

    $main::moduleStatus{$main::currentModule}{$main::currentInst}
      {$main::currentStream} = 'complete';

  return 2;
  }

  #---------------------------------------------------------------------
  sub thisInstrument {
  #---------------------------------------------------------------------
  return $main::currentInst;
  }

  #---------------------------------------------------------------------
  sub template {
  #---------------------------------------------------------------------

  }

1;
