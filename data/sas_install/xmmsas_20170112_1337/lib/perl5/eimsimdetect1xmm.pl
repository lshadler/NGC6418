# This perl task is designed to be called from eimsim. You should not run it from the command line, but instead submit its name to eimsim via the --dettask parameter.
#
# Note that 1XMM made use of the following task versions:
#	eboxdetect-4.13.1
#	emldetect-4.32.1
#	esplinemap-4.0.3
#	srcmatch-3.15.1
#
# Note that this routine cannot cope with multiple exposures per instrument.

my ($testFlag);
my ($command, $instKwd);

sub eimsimdetect1xmm {

  use SAS;
  use eimsimperlsubs;

  my $taskname = "eimsimdetect1xmm";

  my ($band, $j, $evlist, $imageset, $status, $mode, $command);
  my ($pix_delta_x, $pix_delta_y, $n_mask_pixels, $sky_area);
  my ($idbandlo, $idbandhi, $ecf);

  # Prints all output to stderr:
  select(STDERR);

  #......................................................................
  # Read and check parameters:

  my $num_entries = parameterCount('obsidroots');
SAS::error('noObsIds', "There must be at least one member in the "
."list --obsidroots") if ($num_entries <= 0);

### Just for the present, because we can't yet combine source lists from different obs:
SAS::error('notYetAvailable', "Sorry, can't yet combine source lists from more than 1 observation.") if ($num_entries > 1);

  my @obsid_roots = ();
  foreach my $i (0 .. $num_entries-1) {
    $obsid_roots[$i] = stringParameter('obsidroots', $i);
  }

  $testFlag         = booleanParameter('astest');
  $eimsimperlsubs::testFlag = $testFlag;

  my $first_stage   = stringParameter('entrystage');
  my $last_stage    = stringParameter('finalstage');
#  my $ref_band      = stringParameter('refband');
  my $prod_subdir   = stringParameter('prdssubdir');
  my $simop_subdir  = stringParameter('simopsubdir');
  my $simgen_subdir = stringParameter('simgensubdir');
  my $template_set  = stringParameter('srcspecset');
  my $raw_det_list  = stringParameter('srclistset');
  my $stream_num    = intParameter('streamnumber');
  my $id_number     = intParameter('idnumber');

#  my $likemin = realParameter('likemin');
#  my $mlmin   = realParameter('mlmin');
my $likemin = 8;
my $mlmin   = 10;

  $stream_num =~ s/^0+//; # chop off any leading zeros
  $id_number  =~ s/^0+//; # chop off any leading zeros
  my $stream_num_str = '0'x(2-length($stream_num))."$stream_num";
  my $id_number_str  = '0'x(4-length($id_number)) ."$id_number";
  my $id_str = "S$stream_num_str"."F$id_number_str";

  #......................................................................
  # Read ECF data from template file.
  #
  if (!-d "$simgen_subdir") {
    SAS::warning('noGenericSimOutputSubdir', "Directory $simgen_subdir not found; I'll try to mkdir it.");
SAS::error('mkdirFailed', "Couldn't mkdir $simgen_subdir.")
    if (system("mkdir -p $simgen_subdir"));
SAS::error('noSimOutputSubdir', "Directory $simgen_subdir not found.")
    if (!-d "$simgen_subdir");
  }

  my $temp_ascii = "$simgen_subdir/Sim_temp_$id_str.txt";

  my ($ecf_ref, $sim_fluxDensityToFlux)
    = &eimsimperlsubs::readEcfs($template_set, $temp_ascii, $testFlag);
  my @ecf_info = @{$ecf_ref};
SAS::error('noEcfsFound', "No ECF entries were returned by readEcfs.")
  if (@ecf_info <= 0);

SAS::error('badEcfStructure', "No instrument data returned in the ECF hash.")
  if (!defined($ecf_info[0]{'instrums'}));

  #......................................................................
  # Check the product structure and obtain hashes of obsids, instruments and bands from it:

  my ($obsid_ref, $used_bands_ref, $filters_ref)
    = &eimsimperlsubs::checkProds($prod_subdir, @obsid_roots);
  my %obs_ids = %{$obsid_ref};
  my @used_bands = @{$used_bands_ref};
  my %filters = %{$filters_ref};

  # Check that all bands, and all combos of instrument/filter, are present in the ecf hash:
  #
  my ($instexpids_ref, $band_to_i_ref)
    = &eimsimperlsubs::checkBandInstFilt($used_bands_ref, $filters_ref, $ecf_ref);
  my %orig_instexpids = %{$instexpids_ref};
  my %band_to_i = %{$band_to_i_ref};

  # Restrict the instexpids to 1 exposure per instrument:
  #
  my %instexpids = ();
  foreach my $obsid_root (@obsid_roots) {
    my $obsid = $obs_ids{$obsid_root};
    my @orig_instexpids = @{$orig_instexpids{$obsid}};
    my @instexpid_list = ();
    foreach my $trial_inst_uc (qw(PN M1 M2)) {
      foreach my $instexpid (@orig_instexpids){
        my $inst_uc = substr($instexpid, 0, 2);
        if ($inst_uc eq $trial_inst_uc) {
          push @instexpid_list, $instexpid;
        last;
        }
      }
    }
SAS::error('bug', "bug") if (!defined($instexpid_list[0]));
    $instexpids{$obsid} = [@instexpid_list];
  }

  #......................................................................
  # Set up all file names and other variables:

  my $kwd_file = "$simop_subdir/Sim_kwds_$id_str.txt";

  my %bkgmap_strings = ();
  my %boxlocalsets = ();
  my %boxmapsets = ();
  my %boxmapsets_list = ();
  my %cifs = ();
  my %detmasksets = ();
#  my %evlists = ();
  my %expmap_strings = ();
  my %expmaps = ();
  my %final_src_lists = ();
  my %htmlSummary = ();
#  my %inst_uc_lists = ();
#  my %filter_lists = ();
  my %mlsets = ();
  my %mlsets_list = ();
  my %obs_src_lists = ();
  my %sim_images = ();
  my %simage_strings = ();
  my %splinemaps = ();
  my %srcmatchsets = ();
  foreach my $obsid_root (@obsid_roots) {
    my $prod_dir  = "$obsid_root/$prod_subdir";
    my $simop_dir = "$obsid_root/$simop_subdir";

    my $obsid = $obs_ids{$obsid_root};

    $cifs{$obsid}         = "$prod_dir/P$obsid".  "OBX000CALIND0000.FIT";
    $srcmatchsets{$obsid} = "$simop_dir/P$id_str"."EPX000OBSMLI0000.FIT";
    $htmlSummary{$obsid}  = "$simop_dir/P$id_str"."EPX000OBSMLI0000.HTM";
    $obs_src_lists{$obsid}      = "$simop_dir/P$id_str"."EPX000EMSRLI0000.FIT";
###    $final_src_lists{$obsid}      = "$simop_dir/Sim_$id_str"."_finalSrcList.fits";
$final_src_lists{$obsid} = $raw_det_list;

    my @mlsets_seq = ();
    my @boxmapsets_seq = ();
    foreach my $instexpid (@{$instexpids{$obsid}}) {
      $detmasksets{$obsid}{$instexpid}  = "$simop_dir/Sim_$instexpid"
        ."_edetectMask.fits";

      $boxlocalsets{$obsid}{$instexpid} = "$simop_dir/P$id_str$instexpid"
        ."EBLSLI0000.FIT";

      $boxmapsets{$obsid}{$instexpid}   = "$simop_dir/P$id_str$instexpid"
        ."EBMSLI0000.FIT";
      push @boxmapsets_seq, $boxmapsets{$obsid}{$instexpid};

      $mlsets{$obsid}{$instexpid}       = "$simop_dir/P$id_str$instexpid"
        ."EMSRLI0000.FIT";
      push @mlsets_seq, $mlsets{$obsid}{$instexpid};

      my @simage_list = ();
      my @expmap_list = ();
      my @bkgmap_list = ();
      foreach my $band (@used_bands) {
        $expmaps{$obsid}{$instexpid}{$band}
          = "$prod_dir/P$obsid$instexpid"
          ."EXPMAP$band"."000.FIT";

        push @expmap_list, $expmaps{$obsid}{$instexpid}{$band};

        $sim_images{$obsid}{$instexpid}{$band}
          = "$simop_dir/P$id_str$instexpid"
          ."IMAGE_$band"."000.FIT";

        push @simage_list, $sim_images{$obsid}{$instexpid}{$band};

        $splinemaps{$obsid}{$instexpid}{$band}="$simop_dir/"
          ."Sim_$id_str$instexpid"."_splineMap_$band.fits";

        push @bkgmap_list, $splinemaps{$obsid}{$instexpid}{$band};
      }
      $simage_strings{$obsid}{$instexpid}  = join(' ', @simage_list);
      $expmap_strings{$obsid}{$instexpid}  = join(' ', @expmap_list);
      $bkgmap_strings{$obsid}{$instexpid}  = join(' ', @bkgmap_list);
    }
    $mlsets_list{$obsid}      = join(' ', @mlsets_seq);
    $boxmapsets_list{$obsid}  = join(' ', @boxmapsets_seq);
#
#    my @inst_uc_list = ();
#    my @filter_list = ();
#    foreach my $instexpid (@{$instexpids{$obsid}}){
#      my $inst_uc = substr($instexpid, 0, 2);
#SAS::error('noFilterThisInst', "Couldn't find a filter for instexpid $instexpid.")
#      if (!defined($filters{$obsid}{$instexpid}));
#
#      push @inst_uc_list, $inst_uc;
#      push @filter_list, $filters{$obsid}{$instexpid};
#    }
#    $inst_uc_lists{$obsid} = \@inst_uc_list;
#    $filter_lists{$obsid} = \@filter_list;
  }

  #......................................................................
  # Read ECF info from the sim images and setup ecf and band lists and arrays:

  my %idbandlos = ();
  my %idbandhis = ();
  my %ecfs = ();
  my %ranges = ();
  my %band_lo_strings = ();
  my %band_hi_strings = ();
  my %ecf_strings = ();
  my %inst_uc_lists = ();
  my %filter_lists = ();

  foreach my $obsid_root (@obsid_roots) {
    my $obsid = $obs_ids{$obsid_root};

    foreach my $instexpid (@{$instexpids{$obsid}}) {
      my @band_lo_list = ();
      my @band_hi_list = ();
      my @ecf_list = ();
      foreach my $band (@used_bands) {
        my $i = $band_to_i{$band};
        my @band_ranges = @{$ecf_info[$i]{'edges'}};
        my $idbandlo = $band_ranges[0            ]{'lo'};
        my $idbandhi = $band_ranges[$#band_ranges]{'hi'};
        $idbandlo = sprintf "%5d", $idbandlo;
        $idbandhi = sprintf "%5d", $idbandhi;
        $idbandlo =~ s/^\s+//;
        $idbandhi =~ s/^\s+//;
        $idbandlos{$obsid}{$instexpid}{$band} = "$idbandlo";
        $idbandhis{$obsid}{$instexpid}{$band} = "$idbandhi";
        $ranges{$obsid}{$instexpid}{$band} = [@band_ranges];
        push @band_lo_list, "$idbandlo";
        push @band_hi_list, "$idbandhi";

        my $ecf = 999; # default
        if (!$testFlag) {
          my $imageset = $sim_images{$obsid}{$instexpid}{$band};
SAS::error('noSimImage', "Couldn't find $imageset.") if (!-e "$imageset");

          $ecf = &eimsimperlsubs::readFITSKeyword($imageset, 'ECF');
          $ecf = sprintf "%9.6f", $ecf;
          $ecf =~ s/^\s+//;
        }

        $ecfs{$obsid}{$instexpid}{$band} = $ecf;
        push @ecf_list, $ecf;
      }

      $band_lo_strings{$obsid}{$instexpid} = join(' ', @band_lo_list);
      $band_hi_strings{$obsid}{$instexpid} = join(' ', @band_hi_list);
      $ecf_strings{$obsid}{$instexpid}     = join(' ', @ecf_list);
    }

    my @inst_uc_list = ();
    my @filter_list = ();
    foreach my $instexpid (@{$instexpids{$obsid}}){
      my $inst_uc = substr($instexpid, 0, 2);
SAS::error('noFilterThisInst', "Couldn't find a filter for instexpid $instexpid.")
      if (!defined($filters{$obsid}{$instexpid}));

      push @inst_uc_list, $inst_uc;
      push @filter_list, $filters{$obsid}{$instexpid};
    }
    $inst_uc_lists{$obsid} = \@inst_uc_list;
    $filter_lists{$obsid} = \@filter_list;
  }

  #......................................................................
  # Decide where to go:

  if($first_stage eq 'boxlocal') {
    goto BOXLOCAL;
  } elsif($first_stage eq 'splinemap') {
    goto SPLINEMAP;
  } elsif($first_stage eq 'boxmap') {
    goto BOXMAP;
  } elsif($first_stage eq 'mldetect') {
    goto MLDETECT;
  } elsif($first_stage eq 'srcmatch') {
    goto SRCMATCH;
  } elsif($first_stage eq 'listconvert') {
    goto LISTCONVERT;
#  } elsif($first_stage eq 'addboxcols') {
#    goto ADDBOXCOLS;
  } elsif($first_stage eq 'addkwds') {
    goto ADDKWDS;
  } elsif($first_stage eq 'ratetoflux') {
    goto RATETOFLUX;
#  } elsif($first_stage eq 'finalize') {
#    goto FINALIZE;
  } elsif($first_stage eq 'cleanup') {
    goto CLEANUP;
  } else {
SAS::error('badEntryStage', "Unrecognized entry stage $first_stage.");
  }

  #......................................................................
  # Start main routine:

  # . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
  BOXLOCAL:
  print "*************** start BOXLOCAL ***************\n\n";

  foreach my $obsid_root (@obsid_roots) {
    my $obsid = $obs_ids{$obsid_root};

    my $cif = $cifs{$obsid};
SAS::error('noCif', "Couldn't find CIF $cif.") if (!-e "$cif");
    $ENV{'SAS_CCF'} = "$cif";

    foreach my $instexpid (@{$instexpids{$obsid}}) {
      foreach my $band (@used_bands) {
        my $expmap = $expmaps{$obsid}{$instexpid}{$band};
SAS::error('noExpMapSet', "Couldn't find $expmap") if (!-e "$expmap");
        my $sim_image = $sim_images{$obsid}{$instexpid}{$band};
SAS::error('noImageSet', "Couldn't find $sim_image")
        if (!$testFlag && !-e "$sim_image");
      }

      my $detmaskset = $detmasksets{$obsid}{$instexpid};
SAS::error('noDetMaskSet', "Couldn't find $detmaskset")  if (!$testFlag && !-e "$detmaskset");

      my $simage_string  = $simage_strings{ $obsid}{$instexpid};
      my $expmap_string  = $expmap_strings{ $obsid}{$instexpid};
      my $boxlocalset    = $boxlocalsets{   $obsid}{$instexpid};
      my $ecf_string     = $ecf_strings{    $obsid}{$instexpid};
      my $band_lo_string = $band_lo_strings{$obsid}{$instexpid};
      my $band_hi_string = $band_hi_strings{$obsid}{$instexpid};

      $command = "eboxdetect "
      ."imagesets='$simage_string' "
      ."expimagesets='$expmap_string' "
      ."detmasksets=$detmaskset "
      ."boxlistset=$boxlocalset "
      ."usemap=false "
      ."likemin=$likemin "
      ."boxsize=5 "
      ."withdetmask=true "
      ."withexpimage=true "
      ."ecf='$ecf_string' "
#  ."hrdef='$ebox_hrdef' "
      ."pimin='$band_lo_string' "
      ."pimax='$band_hi_string' "
      ;

SAS::error('eboxLocalFailed', "Couldn't run eboxdetect in local mode.")
      if (&run("$command"));
    }
  }

  goto ENDD if ($last_stage eq 'boxlocal');

  # . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
  SPLINEMAP:
  print "************** start SPLINEMAP ***************\n\n";

  foreach my $obsid_root (@obsid_roots) {
    my $obsid = $obs_ids{$obsid_root};

    my $cif = $cifs{$obsid};
SAS::error('noCif', "Couldn't find CIF $cif.") if (!-e "$cif");
    $ENV{'SAS_CCF'} = "$cif";

    foreach my $instexpid (@{$instexpids{$obsid}}) {
      my $boxlocalset = $boxlocalsets{$obsid}{$instexpid};
SAS::error('noBoxLocalSet', "Couldn't find $boxlocalset")
      if (!$testFlag && !-e "$boxlocalset");

      my $detmaskset = $detmasksets{$obsid}{$instexpid};
SAS::error('noDetMaskSet', "Couldn't find $detmaskset")
      if (!$testFlag && !-e "$detmaskset");

      foreach my $band (@used_bands) {
        my $sim_image = $sim_images{$obsid}{$instexpid}{$band};
SAS::error('noImageSet', "Couldn't find $sim_image")
        if (!$testFlag && !-e "$sim_image");

        my $splinemap = $splinemaps{$obsid}{$instexpid}{$band};
        my $idbandlo  = $idbandlos{ $obsid}{$instexpid}{$band};
        my $idbandhi  = $idbandhis{ $obsid}{$instexpid}{$band};

        $command = "esplinemap "
        ."boxlistset=$boxlocalset "
        ."scut=0.001 "
        ."idband=$band "
        ."imageset=$sim_image "
        ."detmaskset=$detmaskset "
        ."withexpimage=no "
        ."withdetmask=yes "
        ."nsplinenodes=16 "
        ."bkgimageset=$splinemap "
        ."pimin=$idbandlo "
        ."pimax=$idbandhi "
        ;

SAS::error('esplinemapFailed', "Couldn't run esplinemap on band $band.")
        if (&run("$command"));
      }
    }
  }

  goto ENDD if ($last_stage eq 'splinemap');

  # . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
  BOXMAP:
  print "**************** start BOXMAP ****************\n\n";

  foreach my $obsid_root (@obsid_roots) {
    my $obsid = $obs_ids{$obsid_root};

    my $cif = $cifs{$obsid};
SAS::error('noCif', "Couldn't find CIF $cif.") if (!-e "$cif");
    $ENV{'SAS_CCF'} = "$cif";

    foreach my $instexpid (@{$instexpids{$obsid}}) {
      foreach my $band (@used_bands) {
        my $expmap = $expmaps{$obsid}{$instexpid}{$band};
SAS::error('noExpMapSet', "Couldn't find $expmap") if (!-e "$expmap");
        my $splinemap = $splinemaps{$obsid}{$instexpid}{$band};
SAS::error('noSplineMapSet', "Couldn't find $splinemap")
        if (!$testFlag && !-e "$splinemap");

        my $sim_image = $sim_images{$obsid}{$instexpid}{$band};
SAS::error('noImageSet', "Couldn't find $sim_image")
        if (!$testFlag && !-e "$sim_image");
      }

      my $detmaskset = $detmasksets{$obsid}{$instexpid};
SAS::error('noDetMaskSet', "Couldn't find $detmaskset")
      if (!$testFlag && !-e "$detmaskset");

      my $simage_string  = $simage_strings{ $obsid}{$instexpid};
      my $expmap_string  = $expmap_strings{ $obsid}{$instexpid};
      my $bkgmap_string  = $bkgmap_strings{ $obsid}{$instexpid};
      my $boxmapset      = $boxmapsets{     $obsid}{$instexpid};
      my $ecf_string     = $ecf_strings{    $obsid}{$instexpid};
      my $band_lo_string = $band_lo_strings{$obsid}{$instexpid};
      my $band_hi_string = $band_hi_strings{$obsid}{$instexpid};

      $command = "eboxdetect "
      ."imagesets='$simage_string' "
      ."expimagesets='$expmap_string' "
      ."bkgimagesets='$bkgmap_string' "
      ."detmasksets=$detmaskset "
      ."boxlistset=$boxmapset "
      ."usemap=true "
      ."likemin=$likemin "
      ."boxsize=5 "
      ."withdetmask=true "
      ."withexpimage=true "
      ."ecf='$ecf_string' "
#  ."hrdef='$ebox_hrdef' "
      ."pimin='$band_lo_string' "
      ."pimax='$band_hi_string' "
      ;

SAS::error('eboxMapFailed', "Couldn't run eboxdetect in map mode.")
      if (&run("$command"));
    }
  }

  goto ENDD if ($last_stage eq 'boxmap');

  # . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
  MLDETECT:
  print "*************** start MLDETECT ***************\n\n";

  foreach my $obsid_root (@obsid_roots) {
    my $obsid = $obs_ids{$obsid_root};

    my $cif = $cifs{$obsid};
SAS::error('noCif', "Couldn't find CIF $cif.") if (!-e "$cif");
    $ENV{'SAS_CCF'} = "$cif";

    foreach my $instexpid (@{$instexpids{$obsid}}) {
      my $inst_uc = substr($instexpid, 0, 2);

      foreach my $band (@used_bands) {
        my $expmap = $expmaps{$obsid}{$instexpid}{$band};
SAS::error('noExpMapSet', "Couldn't find $expmap") if (!-e "$expmap");
        my $splinemap = $splinemaps{$obsid}{$instexpid}{$band};
SAS::error('noSplineMapSet', "Couldn't find $splinemap")
        if (!$testFlag && !-e "$splinemap");

        my $sim_image = $sim_images{$obsid}{$instexpid}{$band};
SAS::error('noImageSet', "Couldn't find $sim_image")
        if (!$testFlag && !-e "$sim_image");
      }

#      my $detmaskset = $detmasksets{$obsid}{$instexpid};
#
#SAS::error('noDetMaskSet', "Couldn't find $detmaskset")
#      if (!$testFlag && !-e "$detmaskset");

      my $boxmapset = $boxmapsets{$obsid}{$instexpid};
SAS::error('noBoxMapSet', "Couldn't find $boxmapset")
      if (!$testFlag && !-e "$boxmapset");

      my $simage_string  = $simage_strings{ $obsid}{$instexpid};
      my $expmap_string  = $expmap_strings{ $obsid}{$instexpid};
      my $bkgmap_string  = $bkgmap_strings{ $obsid}{$instexpid};
      my $mlset          = $mlsets{         $obsid}{$instexpid};
      my $ecf_string     = $ecf_strings{    $obsid}{$instexpid};
      my $band_lo_string = $band_lo_strings{$obsid}{$instexpid};
      my $band_hi_string = $band_hi_strings{$obsid}{$instexpid};

      $command = "emldetect "
      ."imagesets='$simage_string' "
      ."expimagesets='$expmap_string' "
      ."bkgimagesets='$bkgmap_string' "
      ."boxlistset=$boxmapset "
      ."mllistset=$mlset "
      ."ecf='$ecf_string' "
#      ."hrm1def='$hrm1def' "
#      ."hrm2def='$hrm2def' "
#      ."hrpndef='$hrpndef' "
#      ."withxidband=Y "
."withxidband=no "
#      ."xidm1def='$xid_band_list_str' "
#      ."xidm2def='$xid_band_list_str' "
#      ."xidpndef='$xid_band_list_str' "
#      ."xidecf=$xidecf{$filter} "
      ."determineerrors=Y "
      ."mlmin=$mlmin "
      ."pimin='$band_lo_string' "
      ."pimax='$band_hi_string' "
      ;

SAS::error('emldetectFailed', "Couldn't run emldetect.") if (&run("$command"));
    }
  }

  goto ENDD if ($last_stage eq 'mldetect');

  # . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
  SRCMATCH:
  print "*************** start SRCMATCH ***************\n\n";

  foreach my $obsid_root (@obsid_roots) {
    my $obsid = $obs_ids{$obsid_root};

### does srcmatch need a CCF? Try unsetting the envar and see what happens.

    foreach my $instexpid (@{$instexpids{$obsid}}) {
      my $mlset = $mlsets{$obsid}{$instexpid};
SAS::error('noMlSrcListSet', "Couldn't find $mlset")
      if (!$testFlag && !-e "$mlset");
    }

    $command = "srcmatch "
    ."inputlistsets='$mlsets_list{$obsid}' "
    ."outputlistset=$srcmatchsets{$obsid} "
    ."htmloutput=$htmlSummary{$obsid} "
    ."maxerr=4 "
    ."systerr=2.5 "
    ."useomlistset=no "
    ;

SAS::error('srcmatchFailed', "Couldn't run srcmatch.")
    if (&run("$command"));
  }

  goto ENDD if ($last_stage eq 'srcmatch');

  # . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
  LISTCONVERT:
  print "************* start LISTCONVERT **************\n\n";

# NOTE! This operation will insert NULL for columns ML_ID_SRC and BOX_ID_SRC where ID_INST==0. The reason for this is that source detection in the present script is performed separately on each instrument. The different instruments will thus in general have different *_ID_SRC numbers, and no sensible summary value is therefore possible. Note further that this causes knock-on effects within script sections ADDBOXCOLS and RATETOFLUX.

  foreach my $obsid_root (@obsid_roots) {
    my $obsid = $obs_ids{$obsid_root};

    my $srcmatchset = $srcmatchsets{$obsid};
SAS::error('noSrcMatchSet', "Couldn't find $srcmatchset")
    if (!$testFlag && !-e "$srcmatchset");

    $command = "edetaux "
    ."inset=$srcmatchset "
    ."outset=$obs_src_lists{$obsid} "
    ."function=convert "
    ;

SAS::error('srcmatchFailed', "Couldn't run edetaux in 'convert' mode.")
    if (&run("$command"));
  }

  goto ENDD if ($last_stage eq 'listconvert');

#  # . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
#  ADDBOXCOLS:
#  print "************* start ADDBOXCOLS ***************\n\n";
#
## NOTE! Due to reasons outlined in script section LISTCONVERT above, NULL values are present in columns ML_ID_SRC and BOX_ID_SRC where ID_INST==0. Within the present section, this leads to NULL values at ID_INST==0 for all eboxdetect columns added. Note further that this causes knock-on effects within script section RATETOFLUX.
#
#  foreach my $obsid_root (@obsid_roots) {
#    my $obsid = $obs_ids{$obsid_root};
#
#    my $obs_src_list = $obs_src_lists{$obsid};
#SAS::error('noEpicSrcListSet', "Couldn't find $obs_src_list")
#    if (!$testFlag && !-e "$obs_src_list");
#
#    foreach my $instexpid (@{$instexpids{$obsid}}) {
##      my $mlset = $mlsets{$obsid}{$instexpid};
##SAS::error('noMlSrcListSet', "Couldn't find $mlset")
##      if (!$testFlag && !-e "$mlset");
##
#      # Copy over some useful columns from the eboxdetect output:
#
##      $command = "edetaux "
##      ."inset=$mlset "
##      ."outset=$obs_src_list "
##      ."function=addboxid "
##      ;
##
##SAS::error('addBoxListColumnsFailed', "Couldn't add BOX_ID_SRC from $mlset.")
##      if (&run("$command"));
#
#      my $boxmapset = $boxmapsets{$obsid}{$instexpid};
#SAS::error('noBoxMapSet', "Couldn't find $boxmapset")
#      if (!$testFlag && !-e "$boxmapset");
#
#      $command = "edetaux "
#      ."inset=$boxmapset "
#      ."outset=$obs_src_list "
#      ."function=addboxcols "
#      ;
#
#SAS::error('addBoxListColumnsFailed', "Couldn't add columns from $boxmapset.")
#      if (&run("$command"));
#    }
#
##    $command = "edetaux "
##    ."outset=$obs_src_list "
##    ."function=sky2pix "
##    ;
##
##SAS::error('skyToPixelsFailed', "Couldn't convert ra/dec to X_IMA/Y_IMA.")
##    if (&run("$command"));
##
#### Not needed any more since srccompare calculates X_IMA/Y_IMA from the RA/DEC values.
#  }
#
#  goto ENDD if ($last_stage eq 'addboxcols');


  # . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
  ADDKWDS:
  print "*************** start ADDKWDS ****************\n\n";

  foreach my $obsid_root (@obsid_roots) {
    my $obsid = $obs_ids{$obsid_root};

    my $obs_src_list = $obs_src_lists{$obsid};
SAS::error('noEpicSrcListSet', "Couldn't find $obs_src_list")
    if (!$testFlag && !-e "$obs_src_list");

#    $command = "newcolgen "
#    ."tab=$obs_src_list".":SRCLIST "
#    ."newcolumnlist='STREAM_N FIELD_N' "
#    ."newcolvaluelist='$stream_num $id_number' "
#    ;
#
#SAS::error('addColsFailed', "Couldn't add stream & field numbers to "
#."list of detected sources.")
#    if (&run("$command"));

open(KWDS, ">$kwd_file") if (!$testFlag);

    my $max_inst_id = 0;
    foreach my $instexpid (@{$instexpids{$obsid}}) {
      my $inst_uc = substr($instexpid, 0, 2);

      if      ($inst_uc eq 'PN') {
        $instKwd = 'IDINST_1';
        if ($max_inst_id < 1) {$max_inst_id = 1;}
      } elsif ($inst_uc eq 'M1') {
        $instKwd = 'IDINST_2';
        if ($max_inst_id < 2) {$max_inst_id = 2;}
      } elsif ($inst_uc eq 'M2') {
        $instKwd = 'IDINST_3';
        if ($max_inst_id < 3) {$max_inst_id = 3;}
      } else {
SAS::error('badInstrument', "Didn't recognize instrument code $inst_uc.")
      }

print KWDS "$instKwd = $inst_uc\n"
   if (!$testFlag);

      my $max_band_id = 0;
      foreach my $band (@used_bands) {
        if ($max_band_id < $band) {$max_band_id = $band;}

        my $ecf = $ecfs{$obsid}{$instexpid}{$band};

print KWDS "$inst_uc"."_$band"."_ECF = $ecf \/[10^-11 counts cm^2 erg^-1] Flux to rate\n"
   if (!$testFlag);

        my @band_ranges = @{$ranges{$obsid}{$instexpid}{$band}};
        if (!defined($band_ranges[0])) {
SAS::error('noBandRanges', "*****.")
        } elsif (@band_ranges == 1) {
          my $elo = $band_ranges[0]{'lo'};
          my $ehi = $band_ranges[0]{'hi'};

print KWDS "$inst_uc"."_$band"."_ELO = $elo \/[eV]\n"
   if (!$testFlag);
print KWDS "$inst_uc"."_$band"."_EHI = $ehi \/[eV]\n"
   if (!$testFlag);
        } else {
          my $num_ranges = @band_ranges;

print KWDS "$inst_uc"."_$band"."_NER = $num_ranges \/ Number of subranges in energy band $band\n"
   if (!$testFlag);
          foreach my $i (0 .. $#band_ranges) {
            my $range = $i + 1;
            my $elo = $band_ranges[$i]{'lo'};
            my $ehi = $band_ranges[$i]{'hi'};
print KWDS "$inst_uc"."_$band"."ELO$range = $elo \/[eV]\n"
   if (!$testFlag);
print KWDS "$inst_uc"."_$band"."EHI$range = $ehi \/[eV]\n"
   if (!$testFlag);
          }
        }
      } # end loop $band

print KWDS "$inst_uc"."_NBNDS = $max_band_id \/Max ID_BAND this instrument\n"
      if (!$testFlag);
    } # end loop $instexpid

print KWDS "N_INSTR = $max_inst_id \/Max value of ID_INST\n"
   if (!$testFlag);

    foreach my $instexpid (@{$instexpids{$obsid}}) {
      my $inst_uc = substr($instexpid, 0, 2);

      if (!$testFlag) {
        my $mlset = $mlsets{$obsid}{$instexpid};
SAS::error('noMlSrcListSet', "Couldn't find $mlset")
        if (!-e "$mlset");

        my $pix_delta_x = &eimsimperlsubs::readFITSKeyword($mlset, 'TCDELT1');
        my $pix_delta_y = &eimsimperlsubs::readFITSKeyword($mlset, 'TCDELT2');

SAS::error('getPixelDimsFailed', "Couldn't retrieve pixel dimensions.")
        if ($pix_delta_x == 0 || $pix_delta_y == 0);

        my $detmaskset = $detmasksets{$obsid}{$instexpid};
SAS::error('noDetMaskSet', "Couldn't find $detmaskset")
        if (!-e "$detmaskset");

        $command = "fimgstat "
        ."infile=$detmaskset "
        ."threshlo=INDEF "
        ."threshup=INDEF "
        ;

        my @lines = `$command | grep sum`;

SAS::error('getAreaDetMaskFailed', "Couldn't get area of detmask.")
        if (!defined($lines[0]));

        if ($lines[0] =~ /=\s*(\d+)/) {
          $n_mask_pixels = $1;
        } else {
SAS::error('getAreaDetMaskFailed', "Couldn't get area of detmask.");
        }

        $sky_area = abs($n_mask_pixels * $pix_delta_x * $pix_delta_y);
      } else { # $testFlag is set
        $sky_area = 999;
      }

print KWDS "$inst_uc"."_SKY_A = $sky_area \/[deg^2] Area of detection mask.\n"
   if (!$testFlag);
    }

close(KWDS) if (!$testFlag);

$command = "fmodhead "
."infile=$obs_src_list'[SRCLIST]' "
."tmpfil=$kwd_file"
;
#print ">>\n$command\n>>\n";
SAS::error('addKeywordsFailed', "Couldn't add keywords from file $kwd_file.")
    if (&run("$command"));

  } # end foreach my $obsid_root

  goto ENDD if ($last_stage eq 'addkwds');


  # . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
  RATETOFLUX:
  print "************** start RATETOFLUX **************\n\n";

# NOTE! Due to reasons outlined in script sections LISTCONVERT and ADDBOXCOLS above, NULL values are present in columns ML_ID_SRC, BOX_ID_SRC, and all columns copied from the eboxdetect list, where ID_INST==0. Within the present section, this leads to NULL values throughout for all eboxdetect columns added.

  foreach my $obsid_root (@obsid_roots) {
    my $obsid = $obs_ids{$obsid_root};

    my $obs_src_list = $obs_src_lists{$obsid};
SAS::error('noObservationSrcListSet', "Couldn't find $obs_src_list.")
    if (!$testFlag && !-e "$obs_src_list");

    my $raw_det_list = $final_src_lists{$obsid};
    my @filter_list = @{$filter_lists{$obsid}};
    my @inst_uc_list = @{$inst_uc_lists{$obsid}};

    $command = "eratetoflux "
    ."srcspecset=$template_set "
    ."insrclistset=$obs_src_list "
    ."outsrclistset=$raw_det_list "
    ."idcol=ML_ID_SRC "
    ."filters='".join(' ', @filter_list)."' "
    ."instrums='".join(' ', @inst_uc_list)."' "
    ."bands='".join(' ', @used_bands)."' "
    ;

SAS::error('eratetofluxFailed', "Couldn't convert rates to fluxes.")
    if (&run("$command"));
  }

  goto ENDD if ($last_stage eq 'ratetoflux');


  # . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
#  FINALIZE:
#  print "**************** start ATTBIN ****************\n\n";

#### esky2det stuff here

#### source plot stuff here

#### extended source stuff here


#  $command = "esensmap "
#  ."bkgimagesets='$xid_splinemap_list_str' "
#  ."detmasksets=$detmask "
#  ."expimagesets='$xid_expmap_list_str' "
#  ."sensimageset=$sensemapset "
#  ;
#
#&quit("Couldn't run esensmap.", 13)
#if (&run("$command"));

  CLEANUP:
  print "*************** start CLEANUP ****************\n\n";

#  if ($cleanup) {
    &cleanup($temp_ascii);
    &cleanup($kwd_file);
    foreach my $obsid_root (@obsid_roots) {
      my $obsid = $obs_ids{$obsid_root};
      &cleanup($srcmatchsets{$obsid});
      &cleanup($htmlSummary{$obsid});
      &cleanup($obs_src_lists{$obsid});
      foreach my $instexpid (@{$instexpids{$obsid}}) {
        &cleanup($boxlocalsets{$obsid}{$instexpid});
        &cleanup($boxmapsets{$obsid}{$instexpid});
        &cleanup($mlsets{$obsid}{$instexpid});
        foreach my $band (@used_bands) {
          &cleanup($sim_images{$obsid}{$instexpid}{$band});
          &cleanup($splinemaps{$obsid}{$instexpid}{$band});
        } # end foreach $band (@used_bands)
      } # end foreach $instexpid (@{$instexpids{$obsid}})
    } # end foreach $obsid_root (@obsid_roots)
#  } # end if cleanup

  ENDD:

}

  #---------------------------------------------------------------------
  sub cleanup {
  #---------------------------------------------------------------------

    my ($filename) = @_;

    if (-e "$filename"){
      $command = "rm $filename";
SAS::error('rmFailed', "Couldn't delete $filename.")
      if (&run("$command"));
    }

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
  sub getELimits {
  #---------------------------------------------------------------------

    my ($imageset) = @_;
    my ($lostatus, $histatus, $status, $nbands);

    my $idbandlo = 0;
    my $idbandhi = 0;
    my @band_ranges = ();

    ($lostatus, $idbandlo) = &getKeywordValue($imageset, 0, 'ELO');
    ($histatus, $idbandhi) = &getKeywordValue($imageset, 0, 'EHI');

    if ($lostatus || $histatus) {
      ($status, $nbands) = &getKeywordValue($imageset, 0, 'N_ERANGS');
      if (! $status) {
        foreach my $range (0 .. $nbands-1) {
          ($lostatus, $idbandlo) = &getKeywordValue($imageset, 0, "ELO$range");
          ($histatus, $idbandhi) = &getKeywordValue($imageset, 0, "EHI$range");

          if ($lostatus || $histatus) {
            $status = -1;
        last;
          }

          push @band_ranges, {'lo'=>$idbandlo, 'hi'=>$idbandhi};
        }
      }

    } else {
      push @band_ranges, {'lo'=>$idbandlo, 'hi'=>$idbandhi};
    }

  return ($status, @band_ranges);
  }

  #---------------------------------------------------------------------
  sub getELimits_old {
  #---------------------------------------------------------------------

    my ($imageset) = @_;
    my ($lostatus, $histatus, $status, $nbands);

    my $idbandlo = 0;
    my $idbandhi = 0;

    ($lostatus, $idbandlo) = &getKeywordValue($imageset, 0, 'ELO');
    ($histatus, $idbandhi) = &getKeywordValue($imageset, 0, 'EHI');
    if ($lostatus || $histatus) {
      ($status, $nbands) = &getKeywordValue($imageset, 0, 'N_ERANGS');
      if (! $status) {
        ($lostatus, $idbandlo) = &getKeywordValue($imageset, 0, 'ELO1');
        ($histatus, $idbandhi) = &getKeywordValue($imageset, 0, 'EHI$nbands');
        if ($lostatus || $histatus) {$status = -1}
      }
    }

  return ($status, $idbandlo, $idbandhi);
  }

