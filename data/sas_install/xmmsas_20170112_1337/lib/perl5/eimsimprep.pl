# This perl task is the first that should be run. You should run it before you run eimsimbatch. You should run eimsimprep once only, and in only one 'stream'.
#
# eimsimprep calls a detection-specific prep task; the name of this should be supplied via the --detpreptask parameter.

my ($testFlag);
my ($command);

sub eimsimprep {

  use SAS;
  use eimsimperlsubs;

  my $taskname = "eimsimprep";

  # Prints all output to stderr:
  select(STDERR);

  #......................................................................
  # Read and check parameters:

  my $num_entries = parameterCount('obsidroots');
SAS::error('noObsIds', "There must be at least one member in the "
."list --obsidroots") if ($num_entries <= 0);

  my @obsid_roots = ();
  foreach my $i (0 .. $num_entries-1) {
    $obsid_roots[$i] = stringParameter('obsidroots', $i);
#print "$obsid_roots[$i]\n";
  }
#exit;

  $testFlag            = booleanParameter('astest');
  my $testFlagStr = &boolToStr($testFlag);

  my $first_stage      = stringParameter('entrystage');
  my $last_stage       = stringParameter('finalstage');
  my $ref_band         = intParameter('refband'); # for making sky mask
  my $prod_subdir      = stringParameter('prdssubdir');
  my $simop_subdir     = stringParameter('simopsubdir');
  my $simgen_subdir    = stringParameter('simgensubdir');
  my $pseudoprod_subdir = stringParameter('pseudoprodsubdir');
  my $padsizearcsec    = realParameter('padsizearcsec');
  my $template_set     = stringParameter('srcspecset');
  my $dettaskstyle     = stringParameter('dettaskstyle');
  my ($det_prep_script, $det_type);
  if ($dettaskstyle eq 'user') {
    $det_prep_script  = stringParameter('detpreptask');

    if (    $det_prep_script eq 'eimsimdetprep1xmm') {
      $det_type  = '1xmm';
    } elsif($det_prep_script eq 'eimsimdetprep2xmm') {
      $det_type  = '2xmm';
    } else {
      $det_type  = '';
    }
#    unlink("eimsim_config");

  } elsif($dettaskstyle eq 'auto') {
    $det_type  = stringParameter('dettype');
    if ($det_type eq '1xmm') {
      $det_prep_script  = 'eimsimdetprep1xmm';
    } elsif($det_type eq '2xmm') {
      $det_prep_script  = 'eimsimdetprep2xmm';
    } else {
SAS::error('badDetType', "Didn't recognize the choice $det_type.");
    }

#    system("echo $det_type > eimsim_config");

  } else {
SAS::error('badDetTaskStyle', "Didn't recognize the choice $dettaskstyle.");
  }

  system("echo $det_type > eimsim_config");

#  my $temp_ascii       = stringParameter('tempascii');
#  my $temp_set         = stringParameter('tempset');
#  my $stream_num       = intParameter('streamnumber');

  # Check that template file has the right keyword:
  #
  if ($dettaskstyle eq 'auto') {
    my $det_type_kwd = &eimsimperlsubs::readFITSKeyword($template_set, 'FLUX_SCALES', 'DET_TYPE');
    if ($det_type eq '1xmm') {
      SAS::warning('badDetTypeKwd', "You asked for source-detection type 1XMM but the template file is not appropriate for this.")
      if (defined($det_type_kwd) && $det_type_kwd ne '1XMM');
    } elsif($det_type eq '2xmm') {
      SAS::warning('badDetTypeKwd', "You asked for source-detection type 2XMM but the template file is appropriate for 1XMM.")
      if (defined($det_type_kwd) && $det_type_kwd eq '1XMM');
    } else {
SAS::error('badDetType', "Didn't recognize the choice $det_type.");
    }
  }

  #......................................................................
  # Read ECF data from template file. In the present script this is just
  # needed for the list of instruments and the list of bands.
  #
  if (!-d "$simgen_subdir") {
    SAS::warning('noGenericSimOutputSubdir', "Directory $simgen_subdir not found; I'll try to mkdir it.");
SAS::error('mkdirFailed', "Couldn't mkdir $simgen_subdir.")
    if (system("mkdir -p $simgen_subdir"));
SAS::error('noSimOutputSubdir', "Directory $simgen_subdir not found.")
    if (!-d "$simgen_subdir");
  }

  my $temp_ascii = "$simgen_subdir/Sim_temp.txt";
  my $temp_set = "$simgen_subdir/Sim_tempSet.fits";

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
  my %instexpids = %{$instexpids_ref};
  my %band_to_i = %{$band_to_i_ref};



############ emphasise in the doco that band and inst info is defined by the product set!

############ note that products are still required even if astest=yes.




  #......................................................................
  # Setup file names:

#  $stream_num =~ s/^0+//; # chop off any leading zeros
#  $id_number  =~ s/^0+//; # chop off any leading zeros
#  my $stream_num_str = '0'x(2-length($stream_num))."$stream_num";
#  my $id_number_str  = '0'x(4-length($id_number)) ."$id_number";
#  my $id_str = "S$stream_num_str"."F$id_number_str";

  my $temp_image_set   = "$simgen_subdir/Sim_tempImage.fits";
  my $temp_sel_set = "$simgen_subdir/Sim_tempTab.fits";
  my $temp_mask_set = "$simgen_subdir/Sim_tempMask.fits";
#********* cleanup these 3.
  my $inv_sensy_set = "$simgen_subdir/Sim_inverseSensitivityMap.fits";

  my %attitude_sets = ();
  my %cifs = ();
  my %evlists = ();
  my %expmap_refs = ();
  my %imgdef_refs = ();
  my %padmasksets = ();
  my %expmaps = ();
  my %imgdefs = ();
  my %nonvigs = ();
  my %bkg_cts_images = ();
#  my @list_exp_maps = ();
  foreach my $obsid_root (@obsid_roots) {
    my $prod_dir       = "$obsid_root/$prod_subdir";
    my $simop_dir      = "$obsid_root/$simop_subdir";
    my $pseudoprod_dir = "$obsid_root/$pseudoprod_subdir";

    if (!-d "$simop_dir") {
      SAS::warning('noSimOutputSubdir', "Directory $simop_dir not found; I'll try to mkdir it.");
SAS::error('mkdirFailed', "Couldn't mkdir $simop_dir.")
      if (system("mkdir -p $simop_dir"));
SAS::error('noSimOutputSubdir', "Directory $simop_dir not found.")
      if (!-d "$simop_dir");
    }

    if (!-d "$pseudoprod_dir") {
     SAS::warning('noPseudoProdSubdir', "Directory $pseudoprod_dir not found; I'll try to mkdir it.");
SAS::error('mkdirFailed', "Couldn't mkdir $pseudoprod_dir.")
      if (system("mkdir -p $pseudoprod_dir"));
SAS::error('noSimOutputSubdir', "Directory $pseudoprod_dir not found.")
      if (!-d "$pseudoprod_dir");
    }

    my $obsid = $obs_ids{$obsid_root};

    $attitude_sets{$obsid} = "$prod_dir/P$obsid"."OBX000ATTTSR0000.FIT";
    $cifs{$obsid}          = "$prod_dir/P$obsid"."OBX000CALIND0000.FIT";

    foreach my $instexpid (@{$instexpids{$obsid}}) {
      $imgdef_refs{"$obsid$instexpid"} = "$prod_dir/P$obsid$instexpid"
        ."IMAGE_$ref_band"."000.FIT";
      $expmap_refs{"$obsid$instexpid"} = "$prod_dir/P$obsid$instexpid"
        ."EXPMAP$ref_band"."000.FIT";

      $padmasksets{$obsid}{$instexpid} = "$simop_dir/Sim_$instexpid"
        ."_paddedMask.fits";

      if (substr($instexpid, 0, 2) eq 'PN') {
        $evlists{$obsid}{$instexpid} = "$prod_dir/P$obsid$instexpid"
          ."PIEVLI0000.FIT";
      } else {
        $evlists{$obsid}{$instexpid} = "$prod_dir/P$obsid$instexpid"
          ."MIEVLI0000.FIT";
      }

      foreach my $band (@used_bands) {
	$imgdefs{$obsid}{$instexpid}{$band} = "$prod_dir/P$obsid$instexpid"
	  ."IMAGE_$band"."000.FIT";
        $expmaps{$obsid}{$instexpid}{$band} = "$prod_dir/P$obsid$instexpid"
          ."EXPMAP$band"."000.FIT";

        $nonvigs{$obsid}{$instexpid}{$band} = "$pseudoprod_dir/P$obsid$instexpid"
          ."NVGMAP$band"."000.FIT";

        $bkg_cts_images{$obsid}{$instexpid}{$band} = "$simop_dir/Sim_$instexpid"
          ."_BKGMAP_$band.fits";
      } # end foreach $band
    } # end foreach $instexpid (@{$instexpids{$obsid}})
  } # end foreach $obsid_root (@obsid_roots)

  #......................................................................
  # Set up ecf and band lists and arrays:

  my %idbandlos = ();
  my %idbandhis = ();
  my %bkgrates = ();
  foreach my $obsid_root (@obsid_roots) {
    my $obsid = $obs_ids{$obsid_root};

    foreach my $instexpid (@{$instexpids{$obsid}}) {
      my $inst_uc = substr($instexpid, 0, 2);
      my $filter = $filters{$obsid}{$instexpid}; # ie, the filter specified by the event list.
#print "Filter is $filter\n";
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

        my %filter_lists = %{$ecf_info[$i]{'instrums'}};
SAS::error('noBkgRates', "The template set does not contain a background rate for inst $inst_uc, filter $filter.") if (!exists($filter_lists{$inst_uc}{$filter}{'BG'}));
        my $bg = $filter_lists{$inst_uc}{$filter}{'BG'};
#print "inst $inst_uc, filter $filter BG = $bg\n";
        $bkgrates{$obsid}{$instexpid}{$band} = $bg;
      }
    }
  }

  #......................................................................
  # Now load the bkgrates and vigfractions.

  my %vigbkgrates = ();
  my %nonvigbkgrates = ();

  my $bkg_style = stringParameter('bkgstyle');
  if ($bkg_style eq 'user') {
    #....................................................................
    # Now load the bkgrates and vigfractions. NOTE that each of these
    # lists MUST contain either 1 entry each OR the same number of
    # elements as there are bands in the ECF table of the template file.

    my @user_bkgrates = ();

    $num_entries = parameterCount('bkgrates');
SAS::error('noBkgRates', "There must be at least one member in the "
."list --bkgrates") if ($num_entries <= 0);

    # --bkgrates should be in units of counts / arcsec^2 / s.
    #
    if ($num_entries == 1) {
      foreach my $i (0 .. $#used_bands) {
        $user_bkgrates[$i] = realParameter('bkgrates', 0);
      }

    } elsif($num_entries == @used_bands) {
      foreach my $i (0 .. $num_entries-1) {
        $user_bkgrates[$i] = realParameter('bkgrates', $i);
      }

    } else {
SAS::error('badNumBkgRates', "There should be the same number of --bkgrates (and --vigfractions) as the number of bands.");
    }

    my @vigfractions = ();

    $num_entries = parameterCount('vigfractions');
    if ($num_entries == 1) {
      foreach my $i (0 .. $#used_bands) {
        $vigfractions[$i] = realParameter('vigfractions', 0);
      }

    } elsif($num_entries == @used_bands) {
      foreach my $i (0 .. $num_entries-1) {
        $vigfractions[$i] = realParameter('vigfractions', $i);
      }

    } else {
SAS::error('badNumVigFractions', "There should be the same number of --vigfractions (and --bkgrates) as the number of bands.");
    }

#    foreach my $band (@used_bands) {
#      my $bkg_rate = shift @bkgrates;
#      my $vig_frac = shift @vigfractions;
#      $vigbkgrates{$band} = $bkg_rate * $vig_frac;
#      $nonvigbkgrates{$band}  = $bkg_rate * (1-$vig_frac);
#     }
    foreach my $obsid_root (@obsid_roots) {
      my $obsid = $obs_ids{$obsid_root};
      foreach my $instexpid (@{$instexpids{$obsid}}) {
        foreach my $band (@used_bands) {
          my $bkg_rate = shift @user_bkgrates;
          my $vig_frac = shift @vigfractions;
          $vigbkgrates{   $obsid}{$instexpid}{$band} = $bkg_rate * $vig_frac;
          $nonvigbkgrates{$obsid}{$instexpid}{$band} = $bkg_rate * (1-$vig_frac);
        }
      }
    }
  } elsif ($bkg_style eq 'products') {
    # do nothing.

  } elsif ($bkg_style eq 'srcspecset') {
    my $vig_frac = 0.2; ################### for now.

    foreach my $obsid_root (@obsid_roots) {
      my $obsid = $obs_ids{$obsid_root};
      foreach my $instexpid (@{$instexpids{$obsid}}) {
        my $filter = $filters{$obsid}{$instexpid};
        foreach my $band (@used_bands) {
          my $bkg_rate = $bkgrates{$obsid}{$instexpid}{$band};
          $vigbkgrates{   $obsid}{$instexpid}{$band} = $bkg_rate * $vig_frac;
          $nonvigbkgrates{$obsid}{$instexpid}{$band} = $bkg_rate * (1-$vig_frac);
        }
      }
    }
  } else {
SAS::error('badBkgStyle', "--bkgstyle value of '$bkg_style' not recognized.");
  }

  #......................................................................
  # Decide where to go:

  if ($first_stage eq 'detprep') {
    goto DETPREP;

  } elsif ($first_stage eq 'makeskymasks') {
    goto MAKESKYMASKS;

  } elsif ($first_stage eq 'makenonvig') {
    goto MAKENONVIG;

  } elsif ($first_stage eq 'makebkgmap') {
    goto MAKEBKGMAP;

  } elsif ($first_stage eq 'sensmaps') {
    goto SENSMAPS;

  } elsif ($first_stage eq 'addskyarea') {
    goto ADDSKYAREA;

  } elsif ($first_stage eq 'cleanup') {
    goto CLEANUP;

  } elsif ($first_stage eq 'end') {
    SAS::warning('noAction', "Value --entrystage=end means that no tasks are run.");
    goto ENDD;

  } else {
SAS::error('badEntryStage', "Unrecognized entry stage $first_stage.");
  }

  #......................................................................
  # Start main routine:

  DETPREP:
#  print "**************** start DETPREP ***************\n\n";
  SAS::message($SAS::AppMsg, $SAS::VerboseMsg,
    "**************** start DETPREP ***************\n");

  my $det_prep_path = `which $det_prep_script`;
  chomp ($det_prep_path);
  if (-e "$det_prep_path") {
SAS::error('detPrepTaskNotExecutable', "--detpreptask $det_prep_script is not executable.")
    if (!-x "$det_prep_path");
  } else {
SAS::error('noDetPrepTask', "--detpreptask $det_prep_script not found.");
  }

  $command = "$det_prep_script "
  ."obsidroots='".join(' ', @obsid_roots)."' "
  ."prdssubdir=$prod_subdir "
  ."simopsubdir=$simop_subdir "
  ."astest=$testFlagStr "
  ."refband=$ref_band "
  ."srcspecset=$template_set "
#  ."tempascii=$temp_ascii "
  ;

#  print "\ninvoke $command\n\n";
  SAS::message($SAS::AppMsg, $SAS::VerboseMsg, "invoke $command\n");

SAS::error('detPrepTaskFailed', "Couldn't run $det_prep_script.") if (system("$command"));

  goto ENDD if ($last_stage eq 'detprep');


  MAKESKYMASKS:
#  print "************* start MAKESKYMASKS *************\n\n";
  SAS::message($SAS::AppMsg, $SAS::VerboseMsg,
    "************* start MAKESKYMASKS *************\n");

  # This routine calculates the location and size of a great circle which encloses all the fields of view supplied via the parameter --insets. Exposure maps are used for this purpose. Note that it is not necessary to supply this algorithm with exposure maps from all bands of a particular observation/exposure since the instrument pointing information is all that is required.
  #
  # Individual sky masks are also calculated for each obs/instexpid combination.

  foreach my $expmap (values %expmap_refs) {
SAS::error('noExpMap', "Couldn't find $expmap.") if (!-e "$expmap");
  }

SAS::error('noTemplate', "Can't find $template_set.") if (!-e "$template_set");

  $command = "mosaicprep "
  ."expmapsets='".join(' ', values(%expmap_refs))."' "
  ."srcspecset=$template_set "
  ."padsize=$padsizearcsec "
  ;

SAS::error('makeSkyTemplateFailed', "Couldn't run mosaicprep.") if (&run("$command"));

  foreach my $obsid_root (@obsid_roots) {
    my $obsid = $obs_ids{$obsid_root};

    foreach my $instexpid (@{$instexpids{$obsid}}) {
      my $expmapset = $expmap_refs{"$obsid$instexpid"};
      my $padmaskset = $padmasksets{$obsid}{$instexpid};

      $command = "padmask "
      ."expmapset=$expmapset "
      ."maskset=$padmaskset "
      ."tempset=$temp_set "
      ."padsize=$padsizearcsec "
      ;

SAS::error('makeSkyMaskFailed', "Couldn't make sky mask for $obsid, $instexpid.")
      if (&run("$command"));
    }
  }

  goto ENDD if ($last_stage eq 'makeskymasks');


  MAKENONVIG:
#  print "************** start MAKENONVIG **************\n\n";
  SAS::message($SAS::AppMsg, $SAS::VerboseMsg,
    "************** start MAKENONVIG **************\n");

  my $argusedss = "";	# Default: eexpmap Version 4.0 or later
  $argusedss = "usedss=no " if (&isoptdefined("eexpmap", "usedss"));
  if ($argusedss eq "") {
    SAS::message($SAS::AppMsg, $SAS::VerboseMsg,
      "The version of eexpmap is later than 3.x.  Use IMAGEs, not EXPMAPs.\n");
  }

  foreach my $obsid_root (@obsid_roots) {
    my $obsid = $obs_ids{$obsid_root};

    my $need_to_make_at_least_1 = 0;
    foreach my $instexpid (@{$instexpids{$obsid}}) {
      foreach my $band (@used_bands) {
        my $nonvigset = $nonvigs{$obsid}{$instexpid}{$band};
        if (!-e "$nonvigset"){
          $need_to_make_at_least_1 = 1;
      last;
        }
      }
    last if $need_to_make_at_least_1;
    }
#  next if (!$need_to_make_at_least_1);
    if (!$need_to_make_at_least_1){
      SAS::message($SAS::AppMsg, $SAS::VerboseMsg,
        "All NONVIG exposure maps already exist for obsid $obsid.\n");
  next;
    }

    my $cif = $cifs{$obsid};
SAS::error('noCif', "Can't find CIF $cif.") if (!-e "$cif");
    $ENV{'SAS_CCF'} = "$cif";

    my $ahf = $attitude_sets{$obsid};
SAS::error('noAttFile', "Can't find $ahf.") if (!-e "$ahf");

    foreach my $instexpid (@{$instexpids{$obsid}}) {
      my $eventset  = $evlists{$obsid}{$instexpid};
SAS::error('noEventList', "Can't find $eventset.") if (!-e "$eventset");

      my $imageset;
      if ($argusedss eq "") {
	$imageset = $imgdef_refs{"$obsid$instexpid"};
      } else {
	$imageset = $expmap_refs{"$obsid$instexpid"};
      }
SAS::error('noImage', "Can't find $imageset.") if (!-e "$imageset");

      foreach my $band (@used_bands) {
#        my $imageset  = $images{$obsid}{$instexpid}{$band};
#SAS::error('noImage', "Can't find $imageset.") if (!-e "$imageset");
        my $nonvigset = $nonvigs{$obsid}{$instexpid}{$band};
      next if (-e "$nonvigset");

        my $idbandlo = $idbandlos{$obsid}{$instexpid}{$band};
        my $idbandhi = $idbandhis{$obsid}{$instexpid}{$band};

        $command = "eexpmap "
        ."imageset=$imageset "
        # just need it for wcs, dss(gti) and image size I guess.
        ."attitudeset=$ahf "
        ."eventset=$eventset "
        ."expimageset=$nonvigset "
        ."withvignetting=no "
        ."attrebin=2 "
        ."pimin=$idbandlo "
        ."pimax=$idbandhi "
	.$argusedss 
        # ."usedss=no "		# Invalid for newer versions (>=4.0) of eexpmap
        ;

SAS::error('makeNonVigMapFailed', "Couldn't make nonvig exposure map.")
        if (&run("$command"));
      }
    }	# foreach my $instexpid (@{$instexpids{$obsid}})
  }	# foreach my $obsid_root (@obsid_roots)

  goto ENDD if ($last_stage eq 'makenonvig');


  MAKEBKGMAP:
#  print "************** start MAKEBKGMAP **************\n\n";
  SAS::message($SAS::AppMsg, $SAS::VerboseMsg,
    "************** start MAKEBKGMAP **************\n");

  if ($bkg_style eq 'products') {
    SAS::warning('noActionRequired', "You set parameter --bkgstyle to 'products'; bkg maps are assumed to have been made already.");

  } else {
    foreach my $obsid_root (@obsid_roots) {
      my $obsid = $obs_ids{$obsid_root};

      foreach my $instexpid (@{$instexpids{$obsid}}) {
        foreach my $band (@used_bands) {
          my $nonvigset = $nonvigs{$obsid}{$instexpid}{$band};
SAS::error('noNonVigMap', "Can't find $nonvigset.") if (!$testFlag && !-e "$nonvigset");
          my $expmapset = $expmaps{$obsid}{$instexpid}{$band};
SAS::error('noExpMap', "Can't find $expmapset.") if (!-e "$expmapset");
          my $bkg_cts_image = $bkg_cts_images{$obsid}{$instexpid}{$band};

          my $vigbkgrate    = $vigbkgrates{   $obsid}{$instexpid}{$band};
          my $nonvigbkgrate = $nonvigbkgrates{$obsid}{$instexpid}{$band};

          # --vigbkgrate and --nonvigrate should both be in units of counts / arcsec^2 / s.
          #
          $command = "bkgtemplategen "
          ."expmapset=$expmapset "
          ."nonvigset=$nonvigset "
          ."bkgmapset=$bkg_cts_image "
          ."vigbkgrate=$vigbkgrate "
          ."nonvigrate=$nonvigbkgrate "
          ;

SAS::error('makeBkgMapFailed', "Couldn't run bkgtemplategen.")
          if (&run("$command"));
        }
      }
    }
  }

  goto ENDD if ($last_stage eq 'makebkgmap');


  SENSMAPS:
#  print "*************** start SENSMAPS ***************\n\n";
  SAS::message($SAS::AppMsg, $SAS::VerboseMsg,
    "*************** start SENSMAPS ***************\n");

#  foreach $obsid_root (@obsid_roots) {
#    $obsid = $obs_ids{$obsid_root};
#    $prod_dir = "$obsid_root/$prod_subdir";
#    $inter_dir = "$obsid_root/$inter_subdir";
#    @instexpids = keys(%{$expmaps{$obsid}});
#
#    $command = "esensmap_single "
#    ."prdsdir=$prod_dir "
#    ."interdir=$inter_dir "
#    ."instexpids='".join(' ', @instexpids)."' "
#    ."obsid=$obsid "
#    ."astest=$params{'astest'} "
#    ."cleanup=yes "
#    ;
#
#    print "\ninvoke $command\n\n";
#
#&quit("Couldn't make sensitivity maps.", 26) if (system("$command"));
## Not using &run() here because we want esensmap_single to be run whether
## $params{'astest'} is set or not. $params{'astest'} is passed to
## esensmap_single and so is also effective therein.
#  }


#****** for the present, make a pseudo-$inv_sensy_set by adding together all the ref-band exposure maps. At present the $inv_sensy_set is just used as a mask to flag sim sources which fall within areas of >0 exposure and so are detectable in principle.

  foreach my $expmap (values %expmap_refs) {
SAS::error('noExpMap', "Couldn't find $expmap.") if (!-e "$expmap");
  }

  $command = "emosaic "
  ."imagesets='".join(' ', values(%expmap_refs))."' "
  ."withexposure=no "
  ."mosaicedset=$inv_sensy_set "
  ;

SAS::error('makeInverseSensitivityFailed', "Couldn't run emosaic.")
  if (&run("$command"));

  goto ENDD if ($last_stage eq 'sensmaps');


  ADDSKYAREA:
#  print "************** start ADDSKYAREA **************\n\n";
  SAS::message($SAS::AppMsg, $SAS::VerboseMsg,
    "************** start ADDSKYAREA **************\n");

SAS::error('noInverseSensitivitySet', "Couldn't find $inv_sensy_set.")
  if (!$testFlag && !-e "$inv_sensy_set");

  $command = "immask "
  ."imageset=$inv_sensy_set "
  ."maskset=$temp_mask_set "
  ."tempset=$temp_sel_set "
  ."tempimageset=$temp_image_set "
  ."expression='VAL>0.0' "
  ;

SAS::error('makeMaskFailed', "Couldn't run immask.")
  if (&run("$command"));

  my $total_sky_area = 999; # default
  if (!$testFlag) {
SAS::error('noMaskSet', "Couldn't find $temp_mask_set")
    if (!-e $temp_mask_set);

    my $pix_delta_x = abs(&eimsimperlsubs::readFITSKeyword($temp_mask_set, 'CDELT1'));
    my $pix_delta_y = abs(&eimsimperlsubs::readFITSKeyword($temp_mask_set, 'CDELT2'));

SAS::error('getPixelDimsFailed', "Couldn't retrieve pixel dimensions.")
    if ($pix_delta_x == 0 || $pix_delta_y == 0);

    SAS::message($SAS::AppMsg, $SAS::VerboseMsg, "Mask pixels are $pix_delta_x by $pix_delta_y degrees.\n");

    $command = "fimgstat "
    ."infile=$temp_mask_set "
    ."threshlo=INDEF "
    ."threshup=INDEF "
    ;

    SAS::message($SAS::AppMsg, $SAS::VerboseMsg, "invoke $command\n");

    my @lines = `$command | grep sum`;

SAS::error('getAreaDetMaskFailed', "Couldn't get area of detmask.")
    if (!defined($lines[0]));

    my $n_mask_pixels = 0;
    if ($lines[0] =~ /=\s*(\d+)/) {
      $n_mask_pixels = $1;
    } else {
SAS::error('getAreaDetMaskFailed', "Couldn't get area of detmask.");
    }

    SAS::message($SAS::AppMsg, $SAS::VerboseMsg, "$n_mask_pixels mask pixels found.\n");

#    $total_sky_area = abs($n_mask_pixels * $pix_delta_x * $pix_delta_y);
    $total_sky_area = $n_mask_pixels * $pix_delta_x * $pix_delta_y;
  }

  $command = "fparkey "
  ."value=$total_sky_area "
  ."fitsfile=$inv_sensy_set"."'[0]' "
  ."keyword='SKY_AREA' "
  ."comm='[deg^2] Total area in which srcs are detectable.' "
  ."add=yes "
  ;

SAS::error('fparkeyFailed', "Couldn't add SKY_AREA keyword to $inv_sensy_set.")
  if (&run("$command"));

  goto ENDD if ($last_stage eq 'addskyarea');


  CLEANUP:
#  print "**************** start CLEANUP ***************\n\n";
  SAS::message($SAS::AppMsg, $SAS::VerboseMsg,
    "**************** start CLEANUP ***************\n");

  &cleanup($temp_image_set);
  &cleanup($temp_sel_set);
  &cleanup($temp_mask_set);
  &cleanup($inv_sensy_set);

  foreach my $obsid_root (@obsid_roots) {
    my $obsid = $obs_ids{$obsid_root};
    foreach my $instexpid (@{$instexpids{$obsid}}) {
      &cleanup($padmasksets{$obsid}{$instexpid});

      foreach my $band (@used_bands) {
        &cleanup($bkg_cts_images{$obsid}{$instexpid}{$band});
      } # end foreach $band
    } # end foreach $instexpid (@{$instexpids{$obsid}})
  } # end foreach $obsid_root (@obsid_roots)

  $det_prep_path = `which $det_prep_script`;
  chomp ($det_prep_path);
  if (-e "$det_prep_path") {
SAS::error('detPrepTaskNotExecutable', "--detpreptask $det_prep_script is not executable.")
    if (!-x "$det_prep_path");
  } else {
SAS::error('noDetPrepTask', "--detpreptask $det_prep_script not found.");
  }

  $command = "$det_prep_script "
  ."obsidroots='".join(' ', @obsid_roots)."' "
  ."entrystage=cleanup "
  ."finalstage=cleanup "
  ."prdssubdir=$prod_subdir "
  ."simopsubdir=$simop_subdir "
  ."astest=$testFlagStr "
  ."refband=$ref_band "
  ."srcspecset=$template_set "
  ."tempascii=$temp_ascii "
  ;

#  print "\ninvoke $command\n\n";
  SAS::message($SAS::AppMsg, $SAS::VerboseMsg, "invoke $command\n");

SAS::error('detPrepTaskFailed', "Couldn't run $det_prep_script cleanup.")
  if (system("$command"));


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
  sub boolToStr {
  #---------------------------------------------------------------------

    my ($bool_val) = @_;

    if ($bool_val){
  return 'yes';
    } else {
  return 'no';
    }

  }


# sub getsastaskversion {
#   ## Input: (Command)
#    aral% perl -e '$_=`eexpmap --version`; chop; /^[^(]+ \([^\-]*\-(\d+)\.(\d+)\.(\d+)\)/; $sastaskver=$1+$2/10+$3/10000; print $sastaskver,"\n"'
# }

sub isoptdefined {
  ## Input: (Command, Parameter)
  ## Return: 1 if yes, 0 otherwise.
  ## Description: Command is a SAS command.  Parameter is e.g. 'usedss'.
  ## Example: $opt9="usedss=no " if (&isoptdefined("eexpmap", "usedss"))
  ## Note: It is unefficent to call this subroutine repeatedly
  ##       for the same command.

  my($com) = shift;	# SAS-command name
  my($optname) = shift;	# Option parameter name
  my($optnamere) = quotemeta($optname);
  my($flagprmnow)=0;
  my($isoptexisting)=0;

  open(SASCOMARGTEST, "$com -h|") or die "Failed to run '$com -h'";
  while (<SASCOMARGTEST>){
    if (/^\s*Parameters\s*:/) {
      $flagprmnow=1;
      next;
    } elsif ($flagprmnow) {
      next;
    } elsif (/^\s*$optnamere /) {
      $isoptexisting=1;
      last;
    }
  }
  close(SASCOMARGTEST);

  $isoptexisting;
}

1;
