#! /usr/bin/perl -w
#
# NAME: boxchain
# VERSION: 0.1
#
# Developer: Ian Stewart		SSC-LUX
#
# TODO:
################################################################################

my ($testflag);
my $taskname = "boxchain";

sub boxchain {

  use SAS;

  my ($i, @boxhalfsizes, @imagesets, @bkgmapsets, @expmapsets, @groupids, @groupedImages, @groupedBkgMaps, @groupedExpMaps, $g, $boxhalfsize, $boxsize, $command, @addedImage, @addedBkgMap, @addedExpMap, @boxAddedImage, @boxAddedBkgMap);

#  my $taskname = "boxchain";

###  my $apm = $SAS::AppMsg;
###  my $vbs = $SAS::VerboseMsg;
###  my $nsy = $SAS::NoisyMsg;

  # Prints all output to stderr:
  select(STDERR);

  #......................................................................
  # Read and check parameters:

#***** specify temp file names (or at a least fname root) on CL!

  my $numImages = parameterCount('imagesets');
###SAS::error('tooFewImages', "dummy") if ($numImages <= 0);

###SAS::error('wrongNumBkgMaps', "dummy") if ($numImages != parameterCount('bkgmapsets'));
###SAS::error('wrongNumExpMaps', "dummy") if ($numImages != parameterCount('expmapsets'));
###SAS::error('wrongNumGroupIds', "dummy") if ($numImages != parameterCount('groupids'));

&quit("Too few images", 1) if ($numImages <= 0);
&quit("Wrong num bkg maps", 2) if ($numImages != parameterCount('bkgmapsets'));
&quit("Wrong num exp maps", 3) if ($numImages != parameterCount('expmapsets'));
&quit("Wrong num groups", 4) if ($numImages != parameterCount('groupids'));

  my $minGroupId = intParameter('groupids', 0);
  my $maxGroupId = $minGroupId;
  foreach $i (0 .. $numImages-1) {
    $imagesets[$i]  = stringParameter('imagesets', $i);
    $bkgmapsets[$i] = stringParameter('bkgmapsets', $i);
    $expmapsets[$i] = stringParameter('expmapsets', $i);
    $groupids[$i]   = intParameter('groupids', $i);

    if ($groupids[$i] < $minGroupId) {$minGroupId = $groupids[$i];}
    if ($groupids[$i] > $maxGroupId) {$maxGroupId = $groupids[$i];}

    push @{$groupedImages[ $groupids[$i]]}, $imagesets[$i];
    push @{$groupedBkgMaps[$groupids[$i]]}, $bkgmapsets[$i];
    push @{$groupedExpMaps[$groupids[$i]]}, $expmapsets[$i];
  }

  my @groups = ();
  foreach $g ($minGroupId .. $maxGroupId) {
  next if (!defined($groupedImages[$g]));
    push @groups, $g;
  }

  my $numBoxSizes = parameterCount('boxhalfsizes');
###SAS::error('tooFewBoxHalfSizes', "dummy") if ($numBoxSizes <= 0);
&quit("tooFewBoxHalfSizes", 5) if ($numBoxSizes <= 0);

  foreach $i (0 .. $numBoxSizes-1) {
    $boxhalfsizes[$i] = intParameter('boxhalfsizes', $i);
  }

  my $srcListSet = stringParameter('srclistset');
  my $likemin = realParameter('likemin');
  $testflag = booleanParameter('astest');
  my $cleanup = booleanParameter('cleanup');

  #......................................................................
  # Setup file names:

  @addedImage = ();
  @addedBkgMap = ();
  @addedExpMap = ();
  @boxAddedImage = ();
  @boxAddedBkgMap = ();
  foreach $g (@groups) {
    $addedImage[$g]  = "temp_addedImage_$g.ds";
    $addedBkgMap[$g] = "temp_addedBkgMap_$g.ds";
    $addedExpMap[$g] = "temp_addedExpMap_$g.ds";
    $boxAddedImage[$g]  = "temp_boxAddedImage_$g.ds";
    $boxAddedBkgMap[$g] = "temp_boxAddedBkgMap_$g.ds";
  }

  my $detmask = "temp_detMask.ds";

  #......................................................................
  # Main processing:

  if ($testflag) {
###    SAS::warning('testFlagSet', "Script testflag is set. No output "
&warn("Script testflag is set. No output "
      ."will be produced.");
  }


  # Run imweightadd:

  foreach $g (@groups) {
my $imagesets = join(' ', @{$groupedImages[$g]});
my $bkgmapsets = join(' ', @{$groupedBkgMaps[$g]});
my $expmapsets = join(' ', @{$groupedExpMaps[$g]});
    $command = "imweightadd "
    ."imagesets='$imagesets' "
    ."bkgmapsets='$bkgmapsets' "
    ."expmapsets='$expmapsets' "
    ."outimageset=$addedImage[$g] "
    ."outbkgmapset=$addedBkgMap[$g] "
    ."outexpmapset=$addedExpMap[$g] "
    ;

###SAS::error('imweightaddFailed', "dummy") if (&run("$command"));
&quit("imweightaddFailed", 6) if (&run("$command"));
  }


  # Make detmask:

  unlink($detmask);

  if ($numImages == 1) {
    $command = "cp $expmapsets[0] $detmask";
    &run("$command");

  } else {
    $command = "farith "
    ."infil1=$expmapsets[0] "
    ."infil2=$expmapsets[1] "
    ."outfil=$detmask "
    ."ops=ADD "
    ;

    &run("$command");

    foreach $i (2 .. $numImages-1) {
      $command = "farith "
      ."infil1=$expmapsets[$i] "
      ."infil2=$detmask "
      ."outfil=tempDetMask.ds "
      ."ops=ADD; mv tempDetMask.ds $detmask"
      ;

      &run("$command");
    }
  }

###SAS::error('farithFailed', "dummy") if (!$testflag && !-e "$detmask");
&quit("farithFailed", 7) if (!$testflag && !-e "$detmask");


  foreach $boxhalfsize (@boxhalfsizes) {
    if ($boxhalfsize <= 0) {
      system("cp $addedImage[$g] $boxAddedImage[$g]");
      system("cp $addedBkgMap[$g] $boxAddedBkgMap[$g]");

    } else {
      $boxsize = 2*$boxhalfsize+1;

      # Convolve images, bkgmaps:

      foreach $g (@groups) {
        $command = "asmooth "
        ."inset=$addedImage[$g] "
        ."outset=$boxAddedImage[$g] "
        ."smoothstyle=simple "
        ."convolverstyle=squarebox "
        ."width=$boxsize "
        ."normalize=no "
        ;

###SAS::error('asmoothFailed', "dummy") if (&run("$command"));
&quit("asmoothFailed", 8) if (&run("$command"));

        $command = "asmooth "
        ."inset=$addedBkgMap[$g] "
        ."outset=$boxAddedBkgMap[$g] "
        ."smoothstyle=simple "
        ."convolverstyle=squarebox "
        ."width=$boxsize "
        ."normalize=no "
        ;

###SAS::error('asmoothFailed', "dummy") if (&run("$command"));
&quit("asmoothFailed", 9) if (&run("$command"));
      }
    }

    # Run boxdetect:

my $imagesets = join(' ', @boxAddedImage[@groups]);
my $bkgmapsets = join(' ', @boxAddedBkgMap[@groups]);

    $command = "boxdetect "
#    ."imagesets='".join(' ', @boxAddedImage)."' "
#    ."bkgmapsets='".join(' ', @boxAddedBkgMap)."' "
."boximagesets='$imagesets' "
."boxbkgmapsets='$bkgmapsets' "
    ."detmaskset=$detmask "
    ."boxhalfsize=$boxhalfsize "
    ."filemode=append "
    ."srclistset=$srcListSet "
    ."likemin=$likemin "
    ;

###SAS::error('boxdetectFailed', "dummy") if (&run("$command"));
&quit("boxdetectFailed", 10) if (&run("$command"));

  }

  $command = "flagconfused "
  ."srclistset=$srcListSet "
  ;

###SAS::error('flagconfusedFailed', "dummy") if (&run("$command"));
&quit("flagconfusedFailed", 11) if (&run("$command"));

  #......................................................................
  # Cleanup:

  if ($cleanup) {
    foreach $g (@groups) {
      unlink($addedImage[$g]);
      unlink($addedBkgMap[$g]);
      unlink($addedExpMap[$g]);
      unlink($boxAddedImage[$g]);
      unlink($boxAddedBkgMap[$g]);
    }

    unlink($detmask);
  }

exit 0;
}

  #---------------------------------------------------------------------
  sub run {
  #---------------------------------------------------------------------
  # $testflag should be defined globally.

###    use SAS;

    my ($command) = @_;
    my $status = 0;

###    SAS::message($SAS::VerboseMsg, "invoke $command\n\n");
print "\ninvoke $command\n";
    if (!$testflag) {
      $status = system($command);
    }

  return $status;
  }

  #----------------------------------------------------------------------
  sub tell {
  #----------------------------------------------------------------------

    my ($message) = @_;

    my $whole_message = "\n";
    if (defined($taskname)) {
      $whole_message .= "$taskname: ";
    }
    $whole_message .= "$message\n";
    print $whole_message;
  }

  #----------------------------------------------------------------------
  sub warn {
  #----------------------------------------------------------------------

    my ($message) = @_;

    my $whole_message = "\n** ";
    if (defined($taskname)) {
      $whole_message .= "$taskname: ";
    }
    $whole_message .= "warning: $message\n";
    print $whole_message;
  }

  #----------------------------------------------------------------------
  sub quit {
  #----------------------------------------------------------------------

    my ($message, $status) = @_;

    my $whole_message = "\n** ";
    if (defined($taskname)) {
      $whole_message .= "$taskname: ";
    }
    $whole_message .= "ERROR! $message\n";
    print $whole_message;

exit $status;
  }
