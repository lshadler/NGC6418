# You need to run eimsimprep before running eimsimbatch.
#
# You may run several invocations of eimsimbatch from the same directory if you submit different stream numbers for each one.
#
# eimsimbatch calls the perl task eimsim.

my ($testFlag);

my ($command, $new_fvtmp, $i, $stopfile);#, $instexpid, $prefix, $band);

sub eimsimbatch {

  use SAS;

  my $taskname = "eimsimbatch";

  # Prints all output to stderr:
  select(STDERR);

  #......................................................................
  # Read and check non-slave parameters:

  my @start_times = times;

  my $num_entries = parameterCount('obsidroots');
SAS::error('noObsIds', "There must be at least one member in the "
."list --obsidroots") if ($num_entries <= 0);

  my @obsid_roots = ();
  foreach $i (0 .. $num_entries-1) {
    $obsid_roots[$i] = stringParameter('obsidroots', $i)
  }

  my $stream_num   = intParameter('streamnumber');
  my $nfields      = intParameter('nfields');
  my $start_num    = intParameter('startatn');
#  my $apply_corr   = booleanParameter('applycorr');
  my $next_on_fail = booleanParameter('nextonfail');

  $testFlag        = booleanParameter('astest');
  my $testFlagStr = &boolToStr($testFlag);
  my $cleanUp = booleanParameter('cleanup');
#  my $cleanUpStr = &boolToStr($cleanUp);

  $stream_num =~ s/^0+//; # chop off any leading zeros

  my $makeBlankFields = !booleanParameter('withsimsources');
  my $withsimsources_str = &boolToStr(booleanParameter('withsimsources'));

  my $with_det_entry_stage = booleanParameter('withdetentrystage');
  my $with_det_entry_str = &boolToStr($with_det_entry_stage);
  my $with_det_final_stage = booleanParameter('withdetfinalstage');
  my $with_det_final_str = &boolToStr($with_det_final_stage);

  my $dettaskstyle     = stringParameter('dettaskstyle');
  if ($dettaskstyle eq 'user') {
    if (-e "eimsim_config"){
      my ($det_type)  = `cat eimsim_config`;
      chomp($det_type);

      my $det_script  = stringParameter('dettask');
      if (    $det_script eq 'eimsimdetect1xmm' && $det_type ne '1xmm') {
SAS::error('nonMatchingPrepAndDet', "The requested detection task does not match the type ($det_type) of the preparation.");
      } elsif($det_script eq 'eimsimdetect2xmm' && $det_type ne '2xmm') {
SAS::error('nonMatchingPrepAndDet', "The requested detection task does not match the type ($det_type) of the preparation.");
      }
    }

  } elsif($dettaskstyle eq 'auto') {
SAS::error('noConfigFile', "Couldn't find eimsim_config.")
    if (!-e "eimsim_config");
  } else {
SAS::error('badDetTaskStyle', "Didn't recognize the choice $dettaskstyle.");
  }

  #......................................................................
  # General setup:

  my $lockfile = "lock_$stream_num";
SAS::error('lockFileExists', "Lock file $lockfile exists!") if (-e "$lockfile");
SAS::error('writeLockFileFailed', "Couldn't make lock file $lockfile.")
  if (!$testFlag && system("touch $lockfile"));

  my $old_fvtmp = $ENV{"FVTMP"};
  if (defined($old_fvtmp) && -e $old_fvtmp){
    $new_fvtmp = "$old_fvtmp/stream_$stream_num";
  } else {
    $new_fvtmp = "./fvtemp/stream_$stream_num";
  }

SAS::error('mkdirFailed', "Can't mkdir $new_fvtmp")
  if (!-e "$new_fvtmp" && system("mkdir -p $new_fvtmp"));

  $ENV{"FVTMP"} = $new_fvtmp;

  #......................................................................
  # Main routine:

  my $stop_num = $start_num + $nfields - 1;
  for($i=$start_num; $i<=$stop_num; $i++) {

    #....................................................................
    # Check stop file:

    $stopfile = "stop_$stream_num";
    if (-e "$stopfile") {
      unlink("$lockfile");
SAS::error('gracefulStop', "Stop file $stopfile found.");
    }

    $command = "eimsim "
    ."obsidroots='".join(' ', @obsid_roots)."' "
    ."entrystage=".stringParameter('entrystage')." "
    ."finalstage=".stringParameter('finalstage')." "
    ."refband=".stringParameter('refband')." "
    ."prdssubdir=".stringParameter('prdssubdir')." "
    ."simopsubdir=".stringParameter('simopsubdir')." "
    ."simgensubdir=".stringParameter('simgensubdir')." "
    ."streamnumber=$stream_num "
    ."idnumber=$i "
    ."srcspecset=".stringParameter('srcspecset')." "
    ."withsimsources=$withsimsources_str "
#    ."energyfraction=".realParameter('energyfraction')." "
#    ."fluxcutoff=".realParameter('fluxcutoff')." "
    ."dettaskstyle=".stringParameter('dettaskstyle')." "
    ."withdetentrystage=$with_det_entry_str "
    ."withdetfinalstage=$with_det_final_str "
#    ."cleanup=$cleanUpStr "
    ."astest=$testFlagStr "
    ;

    if (!$makeBlankFields){
      $command .= "energyfraction=".realParameter('energyfraction')." ";
      $command .= "fluxcutoff=".realParameter('fluxcutoff')." ";
#      $command .= "faintsourcewidth=".realParameter('faintsourcewidth')." ";
      my $withFluxOffset  = booleanParameter('withfluxoffset');
      my $withFluxOffset_str = &boolToStr($withFluxOffset);
      $command .= "withfluxoffset=$withFluxOffset_str ";
      if ($withFluxOffset){
        $command .= "fluxoffset=".realParameter('fluxoffset')." ";
      }
    }

    if ($dettaskstyle eq 'user') {
      $command .= "dettask=".stringParameter('dettask')." ";
    }

    if ($with_det_entry_stage) {
      $command .= "detentrystage=".stringParameter('detentrystage')." ";
    }
    if ($with_det_final_stage) {
      $command .= "detfinalstage=".stringParameter('detfinalstage')." ";
    }

#    print "\ninvoke $command\n\n";
    SAS::message($SAS::AppMsg, $SAS::VerboseMsg, "invoke $command\n");
    if (system("$command")) {
SAS::error('eimsimFailed', "Couldn't run eimsim, iteration $i.")
      if (!$next_on_fail);

      SAS::warning('eimsimFailed', "Couldn't run eimsim, iteration $i.");
    }

  next if (!$cleanUp);

    $command = "eimsim "
    ."obsidroots='".join(' ', @obsid_roots)."' "
    ."entrystage=cleanup "
    ."finalstage=cleanup "
    ."refband=".stringParameter('refband')." "
    ."prdssubdir=".stringParameter('prdssubdir')." "
    ."simopsubdir=".stringParameter('simopsubdir')." "
    ."simgensubdir=".stringParameter('simgensubdir')." "
    ."streamnumber=$stream_num "
    ."idnumber=$i "
    ."dettaskstyle=".stringParameter('dettaskstyle')." "
    ."astest=$testFlagStr "
    ;

    if ($dettaskstyle eq 'user') {
      $command .= "dettask=".stringParameter('dettask')." ";
    }

    SAS::message($SAS::AppMsg, $SAS::VerboseMsg, "invoke $command\n");
    if (system("$command")) {
SAS::error('eimsimFailed', "Couldn't run eimsim cleanup, iteration $i.")
      if (!$next_on_fail);

      SAS::warning('eimsimFailed', "Couldn't run eimsim cleanup, iteration $i.");
    }
  }

  ENDD:

#  if (!$apply_corr) {
#SAS::message($SAS::AppMsg, $SAS::VerboseMsg, "Don't forget! Param --applycorr was not set. Your figures "
#    ."for completeness and/or reliability will therefore not be optimum. "
#    ."To get the best figures you should run eimsimfinalize, "
#    ."check the correction models against the results, then run "
#    ."eimsimbatch with --entrystage=compare and --applycorr=yes.");
#  }

  unlink("$lockfile");

  $command = "rm -rf $new_fvtmp";
SAS::error('rmFvtmpFailed', "Can't rm $new_fvtmp")
  if (system("$command"));

  my @end_times = times;
  my $proc_time_sec = $end_times[2] - $start_times[2] + $end_times[3]
    - $start_times[3];

  SAS::message($SAS::AppMsg, $SAS::VerboseMsg, "Execution time: $proc_time_sec seconds.");

}

  #---------------------------------------------------------------------
  sub run {
  #---------------------------------------------------------------------
  # $testFlag should be defined globally.

    my ($command) = @_;
    my $status = 0;

#    print "\ninvoke $command\n\n";
    SAS::message($SAS::AppMsg, $SAS::VerboseMsg, "invoke $command\n");
    if (!$testFlag) {
      $status = system($command);
    }

  return $status;
  }

  #---------------------------------------------------------------------
  sub boolToStr {
  #---------------------------------------------------------------------

    my ($bool_val) = @_;

    if ($bool_val){
  return 'yes';
    } else {
  return 'no';
    }

  }
