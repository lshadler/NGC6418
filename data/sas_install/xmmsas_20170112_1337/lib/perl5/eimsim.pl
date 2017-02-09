# You would not normally expect to run eimsim from the command line. The correct action is to run eimsimprep once, then eimsimbatch in as many streams as desired. eimsimbatch calls eimsim.
#
# eimsim calls a source detection task; the name of this should be supplied via the --dettask parameter.


my ($testFlag);
my ($command, $det_first_stage, $det_last_stage, $energy_fraction, $cutoff_flux, $withFluxOffset, $fluxOffset);

sub eimsim {

  use SAS;
  use eimsimperlsubs;

  my $taskname = "eimsim";

  # Prints all output to stderr:
  select(STDERR);

  #......................................................................
  # Read and check parameters:

  my $num_entries = parameterCount('obsidroots');
SAS::error('noObsIds', "There must be at least one member in the "
."list --obsidroots") if ($num_entries <= 0);

  my @obsid_roots = ();
  foreach my $i (0 .. $num_entries-1) {
    $obsid_roots[$i] = stringParameter('obsidroots', $i)
  }

  my $first_stage      = stringParameter('entrystage');
  my $last_stage       = stringParameter('finalstage');
  my $ref_band         = stringParameter('refband');
  my $prod_subdir      = stringParameter('prdssubdir');
  my $simop_subdir     = stringParameter('simopsubdir');
  my $simgen_subdir    = stringParameter('simgensubdir');
#  my $pseudoprod_subdir = stringParameter('pseudoprodsubdir');
  my $stream_num       = intParameter('streamnumber');
  my $id_number        = intParameter('idnumber');
  my $template_set     = stringParameter('srcspecset');
  my $makeBlankFields  = !booleanParameter('withsimsources');
  if (!$makeBlankFields){
    $energy_fraction  = realParameter('energyfraction');
    $cutoff_flux      = realParameter('fluxcutoff');
#    $faint_src_width  = realParameter('faintsourcewidth');
    $withFluxOffset  = booleanParameter('withfluxoffset');
    if ($withFluxOffset){
      $fluxOffset = realParameter('fluxoffset');
    }
  }
  my $dettaskstyle     = stringParameter('dettaskstyle');
  my ($det_script, $det_type);
  if ($dettaskstyle eq 'user') {
    $det_script  = stringParameter('dettask');
  } elsif($dettaskstyle eq 'auto') {
SAS::error('noConfigFile', "Couldn't find eimsim_config.")
    if (!-e "eimsim_config");

    ($det_type)  = `cat eimsim_config`;
    chomp($det_type);
    if ($det_type eq '1xmm') {
      $det_script  = 'eimsimdetect1xmm';
    } elsif($det_type eq '2xmm') {
      $det_script  = 'eimsimdetect2xmm';
    } else {
SAS::error('badDetType', "Didn't recognize the choice $det_type.");
    }
  } else {
SAS::error('badDetTaskStyle', "Didn't recognize the choice $dettaskstyle.");
  }

  my $with_first       = booleanParameter('withdetentrystage');
  if ($with_first) {
    $det_first_stage   = stringParameter('detentrystage');
  }
  my $with_last        = booleanParameter('withdetfinalstage');
  if ($with_last) {
    $det_last_stage    = stringParameter('detfinalstage');
  }
#  my $do_eddington     = booleanParameter('witheddington');
my $do_eddington = 'no';
#  my $cleanup          = booleanParameter('cleanup');

  $testFlag            = booleanParameter('astest');

  $stream_num =~ s/^0+//; # chop off any leading zeros
  $id_number  =~ s/^0+//; # chop off any leading zeros
  my $stream_num_str = '0'x(2-length($stream_num))."$stream_num";
  my $id_number_str  = '0'x(4-length($id_number)) ."$id_number";
  my $id_str = "S$stream_num_str"."F$id_number_str";

  my $num_sub_pixels = 10;

  #......................................................................
  # Read ECF and flux data from template file.
  #
  if (!-d "$simgen_subdir") {
    SAS::warning('noGenericSimOutputSubdir', "Directory $simgen_subdir not found; I'll try to mkdir it.");
SAS::error('mkdirFailed', "Couldn't mkdir $simgen_subdir.")
    if (system("mkdir $simgen_subdir"));
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

  foreach my $obsid_root (@obsid_roots) {
    my $simop_dir = "$obsid_root/$simop_subdir";
    if (!-d "$simop_dir") {
      SAS::warning('noSimOutputSubdir', "Directory $simop_dir not found; I'll try to mkdir it.");
SAS::error('mkdirFailed', "Couldn't mkdir $simop_dir.")
      if (system("mkdir -p $simop_dir"));
SAS::error('noSimOutputSubdir', "Directory $simop_dir not found.")
      if (!-d "$simop_dir");
    }
  }

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

  my $simsrclistset    = "$simgen_subdir/Sim_srcList_$id_str.fits";
  my $raw_det_list     = "$simgen_subdir/Sim_rawDetList_$id_str.fits";
  my $temp_image_set   = "$simgen_subdir/Sim_tempImage_$id_str.fits";
  my $temp_srclist_set = "$simgen_subdir/Sim_tempSrcList_$id_str.fits";
  my $inv_sensy_set    = "$simgen_subdir/Sim_inverseSensitivityMap.fits";

  my %bkg_cts_images = ();
  my %cifs = ();
  my %cts_images = ();
  my %expmap_refs = ();
  my %expmaps = ();
  my %list_bright_flux_img = ();
  my %padmasksets = ();
  my %flux_images_bright = ();
  my %flux_images_faint = ();
  my %src_cts_images = ();
  my %src_rate_images = ();
  my %sim_images = ();

  foreach my $obsid_root (@obsid_roots) {
    my $prod_dir       = "$obsid_root/$prod_subdir";
    my $simop_dir      = "$obsid_root/$simop_subdir";

    my $obsid = $obs_ids{$obsid_root};

    $cifs{$obsid} = "$prod_dir/P$obsid"."OBX000CALIND0000.FIT";

    foreach my $instexpid (@{$instexpids{$obsid}}) {
      $expmap_refs{$obsid}{$instexpid} = "$prod_dir/P$obsid$instexpid"
        ."EXPMAP$ref_band"."000.FIT";

      $padmasksets{$obsid}{$instexpid} = "$simop_dir/Sim_$instexpid"
        ."_paddedMask.fits";

      $flux_images_faint{$obsid}{$instexpid}
        = "$simop_dir/Sim_$id_str$instexpid"
        ."_faintFluxImage.fits";

      my @bright_img_list = ();

      foreach my $band (@used_bands) {
        $expmaps{$obsid}{$instexpid}{$band} = "$prod_dir/P$obsid$instexpid"
          ."EXPMAP$band"."000.FIT";

        $src_cts_images{$obsid}{$instexpid}{$band}
          = "$simop_dir/Sim_$id_str$instexpid"
          ."_countsImage_$band.fits";

        $src_rate_images{$obsid}{$instexpid}{$band}
          = "$simop_dir/Sim_$id_str$instexpid"
          ."_rateImage_$band.fits";

        $cts_images{$obsid}{$instexpid}{$band}
          = "$simop_dir/Sim_$id_str$instexpid"
          ."_CTSIMG_$band.fits";

        $sim_images{$obsid}{$instexpid}{$band} = "$simop_dir/P$id_str$instexpid"
          ."IMAGE_$band"."000.FIT";

        $bkg_cts_images{$obsid}{$instexpid}{$band} = "$simop_dir/Sim_$instexpid"
          ."_BKGMAP_$band.fits";

        $flux_images_bright{$obsid}{$instexpid}{$band}
          = "$simop_dir/Sim_$id_str$instexpid"
          ."_brightFluxImage_$band".".fits";

        push @bright_img_list, $flux_images_bright{$obsid}{$instexpid}{$band};
      } # end foreach $band (@used_bands)

      $list_bright_flux_img{$obsid}{$instexpid}  = join(' ', @bright_img_list);

    } # end foreach $instexpid (@{$instexpids{$obsid}})
  } # end foreach $obsid_root (@obsid_roots)

#  foreach my $inst_uc ('M1','M2','PN') {
#######
#    $ximaerrcorrsets{$inst_uc} = 'xima_err_corrector.ds';
#    $yimaerrcorrsets{$inst_uc} = 'yima_err_corrector.ds';
#    $ratecorrsets{   $inst_uc} = "rate_corrector_$inst_inter{$inst_uc}.ds";
#  }

  #......................................................................
  # Setup ecf and band lists and arrays:

  my %ecfs = ();
  foreach my $obsid_root (@obsid_roots) {
    my $obsid = $obs_ids{$obsid_root};

    foreach my $instexpid (@{$instexpids{$obsid}}) {
      my $inst_uc = substr($instexpid, 0, 2);
      my $filter = $filters{$obsid}{$instexpid}; # ie, the filter specified by the event list.
      foreach my $band (@used_bands) {
        my $i = $band_to_i{$band};
        my %filter_lists = %{$ecf_info[$i]{'instrums'}};
#        my $filter = $filters{$obsid}{$instexpid};
#        my $ecf = $filter_lists{$inst_uc}{$filter};
        my $ecf = $filter_lists{$inst_uc}{$filter}{'ECF'};
        $ecfs{$obsid}{$instexpid}{$band} = $ecf;
      }
    }
  }

  my @mean_E_list = ();
  my %fluxDensitiesToFluxes = ();
  foreach my $band (@used_bands) {
    my $i = $band_to_i{$band};
    my @band_ranges = @{$ecf_info[$i]{'edges'}};
    my $idbandlo = $band_ranges[0            ]{'lo'};
    my $idbandhi = $band_ranges[$#band_ranges]{'hi'};

    push @mean_E_list, ($idbandlo+$idbandhi)/2.0;
    $fluxDensitiesToFluxes{$band} = $ecf_info[$i]{'flux'};
  }
  my $list_mean_energies = join(' ', @mean_E_list);

  #......................................................................
  # Decide where to go:

  if ($first_stage eq 'makesimlist') {
    goto MAKESIMLIST;
  } elsif($first_stage eq 'imsample') {
    goto IMSAMPLE;
  } elsif($first_stage eq 'makerateimg') {
    goto MAKERATEIMG;
  } elsif($first_stage eq 'makectsimg') {
    goto MAKECTSIMG;
  } elsif($first_stage eq 'poissonize') {
    goto POISSONIZE;
  } elsif ($first_stage eq 'detect') {
    goto DETECT;
#  } elsif($first_stage eq 'eddington') {
#    goto EDDINGTON;
#  } elsif($first_stage eq 'correct') {
#    goto CORRECT;
  } elsif($first_stage eq 'fluxtorand') {
    goto FLUXTORAND;
  } elsif($first_stage eq 'addbits') {
    goto ADDBITS;
  } elsif($first_stage eq 'compare') {
    goto COMPARE;
#  } elsif($first_stage eq 'addsimrates') {
#    goto ADDSIMRATES;
#  } elsif($first_stage eq 'filter') {
#    goto FILTER;
#  } elsif($first_stage eq 'sensmaps') {
#    goto SENSMAPS;
  } elsif($first_stage eq 'cleanup') {
    goto CLEANUP;
  } else {
SAS::error('badEntryStage', "Unrecognized entry stage $first_stage.");
  }

  #......................................................................
  # Start main routine:

  MAKESIMLIST:
#  print "************** start MAKESIMLIST *************\n\n";
  SAS::message($SAS::AppMsg, $SAS::VerboseMsg,
    "************** start MAKESIMLIST *************\n");

  if ($makeBlankFields) {
SAS::warning('noActionForBlankField', "Parameter --withsimsources is unset: thus no action this section.");
  } else {
SAS::error('noTemplate', "Couldn't find $template_set.") if (!-e "$template_set");

    $command = "srclistsim "
    ."srcspecset=$template_set "
    ."srclistset=$simsrclistset "
    ;

SAS::error('makeSimListFailed', "Couldn't make sim source list.")
    if (&run("$command"));

    $command = "newcolgen "
    ."tab=$simsrclistset".":SRCLIST "
    ."newcolumnlist='STREAM_N FIELD_N' "
    ."newcolvaluelist='$stream_num $id_number' "
    ;

SAS::error('addColsFailed', "Couldn't add stream & field numbers to "
."sim source list.")
    if (&run("$command"));
  }

  goto ENDD if ($last_stage eq 'makesimlist');


  IMSAMPLE:
#  print "*************** start IMSAMPLE ***************\n\n";
  SAS::message($SAS::AppMsg, $SAS::VerboseMsg,
    "*************** start IMSAMPLE ***************\n");

  if ($makeBlankFields) {
SAS::warning('noActionForBlankField', "Parameter --withsimsources is unset: thus no action this section.");
  } else {
SAS::error('noSimSrcListSet', "Couldn't find $simsrclistset.")
    if (!$testFlag && !-e "$simsrclistset");
SAS::error('noInverseSensitivitySet', "Couldn't find $inv_sensy_set.")
    if (!$testFlag && !-e "$inv_sensy_set");

    $command = "imsample "
    ."imageset=$inv_sensy_set "
    ."srclisttab=$simsrclistset:SRCLIST "
#    ."xcol=***** "
#    ."ycol=***** "
."colstyle=radec "
."racol=RA "
."deccol=DEC "
#*********
    ."outcol=INV_SENSY "
    ;

SAS::error('flagSimFailed', "Couldn't sample sensitivity for the simulated sources.")
    if (&run("$command"));
  }

  goto ENDD if ($last_stage eq 'imsample');


  MAKERATEIMG: # call srcmap for faint sources and esrcmap for bright.
#  print "************* start MAKERATEIMG **************\n\n";
  SAS::message($SAS::AppMsg, $SAS::VerboseMsg,
    "************* start MAKERATEIMG **************\n");

  if ($makeBlankFields) {
SAS::warning('noActionForBlankField', "Parameter --withsimsources is unset: thus no action this section.");
  } else {
SAS::error('noSimSrcListSet', "Couldn't find $simsrclistset.")
    if (!$testFlag && !-e "$simsrclistset");

    foreach my $obsid_root (@obsid_roots) {
      my $obsid = $obs_ids{$obsid_root};

      my $cif = $cifs{$obsid};
SAS::error('noCif', "Couldn't find CIF $cif.") if (!-e "$cif");
      $ENV{'SAS_CCF'} = "$cif";

      foreach my $instexpid (@{$instexpids{$obsid}}) {
#        my $inst_uc = substr($instexpid, 0, 2);
#        my $filter = $filters{$obsid}{$instexpid};
        my $padmaskset = $padmasksets{$obsid}{$instexpid};
SAS::error('noPadMask', "Couldn't find $padmaskset.")
        if (!$testFlag && !-e "$padmaskset");

#        foreach my $band (@used_bands) {
#          my $expmapset  = $expmaps{$obsid}{$instexpid}{$band};
#SAS::error('noExpMap', "Couldn't find $expmapset.") if (!-e "$expmapset");
#        }

        my $expmap = $expmap_refs{$obsid}{$instexpid};
SAS::error('noExpMap', "Couldn't find $expmap.") if (!-e "$expmap");

        # Both esrcmap and srcmap in the present instance create images which display nett flux per image pixel from the overlaid PSFs of all sim sources which satisfy the respective selection expressions. The fluxes are calculated for the nominal sim source spectrum, over the energy band designated by the E_MIN and E_MAX keywords of the FLUX_SCALES table of the sim source specification dataset

###########******** THESE KWDS SHOULD BE IN THE SRCSPECS HEADER!!!!

        # Do bright sources:
        #
        $command = "esrcmap -w 1 "
        ."srclisttab=$simsrclistset:SRCLIST "
        ."maskset=$padmaskset "
        ."templateset=$expmap "
        ."outsets='$list_bright_flux_img{$obsid}{$instexpid}' "
        ."expression='FLUX>=$cutoff_flux' "
        ."withidcol=no "
        ."idbands='".join(' ', @used_bands)."' "
        ."estyle=user "
        ."psfenergies='$list_mean_energies' "
        ."energyfraction=$energy_fraction "
        ."posstyle=radec "
        ."racol=RA "
        ."deccol=DEC "
        ."ratecol=FLUX "
        ."tempimageset=$temp_image_set "
        ."tempsrclistset=$temp_srclist_set "
        ;

SAS::error('makeBrightFluxImagesFailed', "Couldn't make bright flux images.")
        if (&run("$command"));

        # Do faint sources:
        #
        $command = "srcmap "
        ."srclisttab=$simsrclistset:SRCLIST "
        ."maskset=$padmaskset "
        ."templateset=$expmap "
        ."outset=$flux_images_faint{$obsid}{$instexpid} "
#        ."withfluxcut=yes "
#        ."fluxcut=$cutoff_flux "
        ."expression='FLUX<$cutoff_flux' "
        ."psfstyle=uniform "
#        ."gausswidth=$faint_src_width "
        ."withapprox=yes "
        ."approxstyle=subpixels "
        ."nsubpixels=$num_sub_pixels "
        ."racol=RA "
        ."deccol=DEC "
        ."ratecol=FLUX "
        ."tempimageset=$temp_image_set "
        ;

        if ($withFluxOffset){
          $command .= "fluxoffset=$fluxOffset ";
        }

SAS::error('makeFaintFluxImageFailed', "Couldn't make faint flux image.")
        if (&run("$command"));

        foreach my $band (@used_bands) {
          my $bright_src_image = $flux_images_bright{$obsid}{$instexpid}{$band};
          my $faint_src_image = $flux_images_faint{$obsid}{$instexpid};
SAS::error('noFaintImage', "Couldn't find $faint_src_image.")
          if (!$testFlag && !-e "$faint_src_image");

SAS::error('noBrightImage', "Couldn't find $bright_src_image.")
          if (!$testFlag && !-e "$bright_src_image");

          my $src_rate_image = $src_rate_images{$obsid}{$instexpid}{$band};
          my $ecf = $ecfs{$obsid}{$instexpid}{$band};

          # Prepare multiplication factor to transform the sim-source-band flux images first to flux-densities at 1keV; then to fluxes for the present band; then to count rates per pixel.
          #
          my $src_weight = $fluxDensitiesToFluxes{$band} * $ecf
            * 1.0e11 / $sim_fluxDensityToFlux;

          $command = "imweightadd "
          ."imagesets='$faint_src_image $bright_src_image' "
          ."withweights=yes "
          ."weightstyle=user "
          ."weights='$src_weight $src_weight' "
          ."outimageset=$src_rate_image "
          ."tempset=$temp_image_set "
          ;

SAS::error('combineRateImageFailed', "Couldn't make rate image.")
          if (&run("$command"));
        } # next $band
      } # next $instexpid
    } # next $obsid_root
  } # end if $makeBlankFields

  goto ENDD if ($last_stage eq 'makerateimg');


  MAKECTSIMG:
#  print "************** start MAKECTSIMG **************\n\n";
  SAS::message($SAS::AppMsg, $SAS::VerboseMsg,
    "************** start MAKECTSIMG **************\n");

  foreach my $obsid_root (@obsid_roots) {
    my $obsid = $obs_ids{$obsid_root};
    foreach my $instexpid (@{$instexpids{$obsid}}) {
      foreach my $band (@used_bands) {
        my $bkg_cts_image = $bkg_cts_images{$obsid}{$instexpid}{$band};
SAS::error('noBkpCountsImage', "Couldn't find $bkg_cts_image.")
        if (!$testFlag && !-e "$bkg_cts_image");

        my $cts_image = $cts_images{$obsid}{$instexpid}{$band};

        if ($makeBlankFields) {
########## cp $bkg_cts_image to $cts_image
          $command = "cp $bkg_cts_image $cts_image";
SAS::error('cpBkgToCtsImageFailed', "Couldn't cp $bkg_cts_image $cts_image.")
          if (&run("$command"));

        } else {
          my $expmapset = $expmaps{   $obsid}{$instexpid}{$band};
SAS::error('noExpMap', "Couldn't find $expmapset.") if (!-e "$expmapset");
          my $src_rate_image = $src_rate_images{$obsid}{$instexpid}{$band};
SAS::error('noRateImage', "Couldn't find $src_rate_image.")
          if (!$testFlag && !-e "$src_rate_image");

          my $src_cts_image = $src_cts_images{$obsid}{$instexpid}{$band};

          # Multiply src rate image by expmap to make src counts image:
          #
          $command = "farith "
          ."infil1=$expmapset "
          ."infil2=$src_rate_image "
          ."outfil=$src_cts_image "
          ."ops=MUL "
          ."clobber=yes"
          ;

SAS::error('makeCountsImageFailed', "Couldn't multiply source rate image by exposure map.")
          if (&run("$command"));

SAS::error('noSrcCountsImage', "Couldn't find $src_cts_image.")
          if (!$testFlag && !-e "$src_cts_image");

          # Now add the src counts image to the bkg counts image:
          #
          $command = "farith "
          ."infil1=$src_cts_image "
          ."infil2=$bkg_cts_image "
          ."outfil=$cts_image "
          ."ops=ADD "
          ."clobber=yes"
          ;

SAS::error('makeCountsImageFailed', "Couldn't make the expectation counts image.")
          if (&run("$command"));
        } # end if $makeBlankFields

        # Make sure all pixels are >= 0:
        #
        $command = "fimgtrim "
        ."infile=$cts_image "
        ."threshlo='0.0' "
        ."threshup='INDEF' "
        ."const_lo=0.0 "
#        ."const_up=yes"
        ."outfile=$cts_image "
        ."clobber=yes "
        ;

SAS::error('trimmingNegativePixelsFailed', "Couldn't run fimgtrim.")
        if (&run("$command"));
      } # next $band
    } # next $instexpid
  } # next $obsid_root

  goto ENDD if ($last_stage eq 'makectsimg');


  POISSONIZE:
#  print "************** start POISSONIZE **************\n\n";
  SAS::message($SAS::AppMsg, $SAS::VerboseMsg,
    "************** start POISSONIZE **************\n");

  foreach my $obsid_root (@obsid_roots) {
    my $obsid = $obs_ids{$obsid_root};
    foreach my $instexpid (@{$instexpids{$obsid}}) {
      foreach my $band (@used_bands) {
        my $imageset  = $sim_images{$obsid}{$instexpid}{$band};
        my $cts_image = $cts_images{ $obsid}{$instexpid}{$band};
SAS::error('noAvCountsImage', "Couldn't find $cts_image.")
        if (!$testFlag && !-e "$cts_image");

        $command = "impoissonize "
        ."inset=$cts_image "
        ."outset=$imageset "
        ;

SAS::error('poissonizeFailed', "Couldn't poissonize average counts image.")
        if (&run("$command"));

#        $command = "fappend "
#        ."infile=$cts_image'[LOGNLOGS]' "
#        ."outfile=$imageset "
#        ;
# 
#SAS::error('addLogNLogSExtFailed', "Couldn't add LOGNLOGS extension.")
#        if (&run("$command"));

        my $ecf = $ecfs{$obsid}{$instexpid}{$band};

        $command = "addattribute "
        ."attributename='ECF' "
        ."attributetype='real' "
###  ."attributeunit=''deg^2'' "
# Can't yet do this. DJF is going to modify addattribute to accept a unit parameter.
###        ."withattributecomment='yes' "
#."withattributecomment='no' "
# Some comments (with double quotes??) seem to give problems to SAS::message.
###        ."attributecomment='\"[cgs] Count rate = flux * ECF * 10^11.\"' "
        ."set=$imageset "
        ."realvalue='$ecf' "
        ;

SAS::error('addEcfKwdFailed', "Couldn't add ECF keyword.")
        if (&run("$command"));

        # This is necessary for the 2xmm source detection script:
        #
        $command = "addattribute "
        ."attributename='BKGDSCRN' "
        ."attributetype='boolean' "
###  ."attributeunit=''deg^2'' "
# Can't yet do this. DJF is going to modify addattribute to accept a unit parameter.
###        ."withattributecomment='yes' "
#."withattributecomment='no' "
# Some comments (with double quotes??) seem to give problems to SAS::message.
###        ."attributecomment='\"[cgs] Count rate = flux * ECF * 10^11.\"' "
        ."set=$imageset "
        ."booleanvalue='yes' "
        ;

SAS::error('addBkgscrnKwdFailed', "Couldn't add BKGDSCRN keyword.")
        if (&run("$command"));
      }
    }
  }



############# need other band-related kwds be written to file so eimsimdetect can pick them up?


  goto ENDD if ($last_stage eq 'poissonize');


  DETECT:
#  print "**************** start DETECT ****************\n\n";
  SAS::message($SAS::AppMsg, $SAS::VerboseMsg,
    "**************** start DETECT ****************\n");

  my $det_path = `which $det_script`;
  chomp ($det_path);
  if (-e "$det_path") {
SAS::error('noDetTask', "--dettask $det_script is not executable.") if (!-x "$det_path");
  } else {
SAS::error('noDetTask', "--dettask $det_script not found.");
  }

#  my $edetect_cleanup;
#  if ($cleanup) {
#    $edetect_cleanup = 'yes';
#  } else {
#    $edetect_cleanup = 'no';
#  }

  my $edetect_astest;
  if ($testFlag) {
    $edetect_astest = 'yes';
  } else {
    $edetect_astest = 'no';
  }

  $command = "$det_script "
  ."obsidroots='".join(' ', @obsid_roots)."' "
  ."refband=$ref_band "
  ."prdssubdir=$prod_subdir "
  ."simopsubdir=$simop_subdir "
  ."simgensubdir=$simgen_subdir "
#  ."cleanup=$edetect_cleanup "
  ."astest=$edetect_astest "
  ."srcspecset=$template_set "
#  ."tempascii=$temp_ascii "
  ."srclistset=$raw_det_list "
  ."streamnumber=$stream_num "
  ."idnumber=$id_number "
  ;

  if ($with_first) {
    $command .= "entrystage=$det_first_stage ";
  }
  if ($with_last) {
    $command .= "finalstage=$det_last_stage ";
  }

#  print "\ninvoke $command\n\n";
  SAS::message($SAS::AppMsg, $SAS::VerboseMsg, "invoke $command\n");

SAS::error('detectTaskFailed', "Couldn't run $det_script.")
  if (system($command));
  # Not using &run() here because we want the detect script to be run whether
  # $params{'astest'} is set or not. $params{'astest'} is passed to the
  # detect script and so is also effective therein.

  goto ENDD if ($last_stage eq 'detect');


#  EDDINGTON: # correct for Eddington bias.
#  print "************** start EDDINGTON ***************\n\n";
#
#  # Params accessed:
#  # ???
#
#  foreach $obsid_root (@obsid_roots) {
#    $obsid = $obs_ids{$obsid_root};
#    foreach $instexpid (@{$instexpids{$obsid}}) {
#      $mlset = "$mlsets{ $obsid}{$instexpid}";
#
##      if (&boolTranslate($do_eddington)) {
#      if ($do_eddington) {
#        $command = "eimsim "
#        ."function=eddington "
#        ."detsrclistset=$mlset "
#        ."likemin=$likemin "
#        ;
#
#&quit("Couldn't compute Eddington correction.", 21)
#if (&run("$command"));
#      }
#    }
#  }
#
#  goto ENDD if ($last_stage eq 'eddington');

#  CORRECT: # correct rate, position and their respective uncerts for
#  # systematic errors. Normally one would run eimsim_single twice, the
#  # first time to measure the syserrors and the second time (tho only
#  # from 'correct' onward) to correct for them.
###### this needs to be altered to deal with a single source list per obs.
#
#  # Params accessed:
#  # ???
#
#  if ($apply_corr) {
#    foreach $obsid_root (@obsid_roots) {
#      $obsid = $obs_ids{$obsid_root};
#      foreach $instexpid (@{$instexpids{$obsid}}) {
#        $inst_uc = substr($instexpid, 0, 2);
#        $mlset = $mlsets{$obsid}{$instexpid};
#
#SAS::error('noMlSrcListSet', "Couldn't find $mlset.")
#        if (!$testFlag && !-e "$mlset");
#
#        $ximaerrcorrset = $ximaerrcorrsets{$inst_uc};
#SAS::error('noXimaCorrSet', "Couldn't find $ximaerrcorrset.")
#        if (!$testFlag && !-e "$ximaerrcorrset");
#
#        $yimaerrcorrset = $yimaerrcorrsets{$inst_uc};
#SAS::error('noYimaCorrSet', "Couldn't find $yimaerrcorrset.")
#        if (!$testFlag && !-e "$yimaerrcorrset");
#
#        $ratecorrset = $ratecorrsets{$inst_uc};
#SAS::error('noRateCorrSet', "Couldn't find $ratecorrset.")
#        if (!$testFlag && !-e "$ratecorrset");
#
#        $command = "eimsim "
#        ."function=correct "
#        ."detsrclistset=$mlset "
#        ."ximaerrcorrectorset=$ximaerrcorrset "
#        ."yimaerrcorrectorset=$yimaerrcorrset "
#        ."ratecorrectorset=$ratecorrset "
#        ."usecorrected=$do_eddington "
#        ;
#
#SAS::error('correctSysErrorsFailed', "Couldn't correct systematic errors.")
#        if (&run("$command"));
#      }
#    }
#  }
#
#  goto ENDD if ($last_stage eq 'correct');


  FLUXTORAND:
#  print "************** start FLUXTORAND **************\n\n";
  SAS::message($SAS::AppMsg, $SAS::VerboseMsg,
    "************** start FLUXTORAND **************\n");

  if ($makeBlankFields) {
SAS::warning('noActionForBlankField', "Parameter --withsimsources is unset: thus no action this section.");
  } else {
SAS::error('noDetectedSrcListSet', "Couldn't find $raw_det_list.")
    if (!$testFlag && !-e "$raw_det_list");

    $command = "fluxlinearize "
    ."srcspecset=$template_set "
    ."srclisttab=$raw_det_list:SRCLIST "
    ."randcol=LINF "
    ."randerrcol=LINF_ERR "
    ."fluxcol=FLUX "
    ."fluxerrcol=FLUX_ERR "
    ;

SAS::error('fluxlinearizeFailed', "Couldn't unscale fluxes to even randoms.")
    if (&run("$command"));
  }

  goto ENDD if ($last_stage eq 'fluxtorand');


  ADDBITS:
#  print "*************** start ADDBITS ****************\n\n";
  SAS::message($SAS::AppMsg, $SAS::VerboseMsg,
    "*************** start ADDBITS ****************\n");

SAS::error('noDetSrcListSet', "Couldn't find $raw_det_list.")
  if (!$testFlag && !-e "$raw_det_list");
SAS::error('noInverseSensitivitySet', "Couldn't find $inv_sensy_set.")
  if (!$testFlag && !-e "$inv_sensy_set");

  $command = "newcolgen "
  ."tab=$raw_det_list".":SRCLIST "
  ."newcolumnlist='STREAM_N FIELD_N' "
  ."newcolvaluelist='$stream_num $id_number' "
  ;

SAS::error('addColsFailed', "Couldn't add stream & field numbers to "
."list of detected sources.")
  if (&run("$command"));

  my $total_sky_area = &eimsimperlsubs::readFITSKeyword(
    $inv_sensy_set, 'SKY_AREA');

  $command = "fparkey "
  ."value=$total_sky_area "
  ."fitsfile=$raw_det_list+1 "
  ."keyword='SKY_AREA' "
  ."comm='[deg^2] Total area in which sources are detectable.' "
  ."add=yes "
  ;

SAS::error('fparkeyFailed', "Couldn't add SKY_AREA keyword to det source list.")
  if (&run("$command"));

  goto ENDD if ($last_stage eq 'addbits');


  COMPARE:
#  print "*************** start COMPARE ****************\n\n";
  SAS::message($SAS::AppMsg, $SAS::VerboseMsg,
    "*************** start COMPARE ****************\n");

  if ($makeBlankFields) {
SAS::warning('noActionForBlankField', "Parameter --withsimsources is unset: thus no action this section.");
  } else {
SAS::error('noSimSrcListSet', "Couldn't find $simsrclistset.")
    if (!$testFlag && !-e "$simsrclistset");

#  foreach my $obsid_root (@obsid_roots) {
#    my $obsid = $obs_ids{$obsid_root};

#    my $cif = $cifs{$obsid};
#SAS::error('noCif', "Couldn't find CIF $cif.") if (!-e "$cif");
#    $ENV{'SAS_CCF'} = "$cif";

#    my $raw_det_list = $detsets{$obsid};
SAS::error('noDetectedSrcListSet', "Couldn't find $raw_det_list.")
      if (!$testFlag && !-e "$raw_det_list");

      $command = "srccompare "
      ."srcspecset=$template_set "
      ."simsrclistset=$simsrclistset "
      ."detsrclisttab=$raw_det_list:SRCLIST "
#      ."simfluxcol=FLUX "
#      ."simfluxerrcol=FLUX_ERR "
      ."racol=RA "
      ."deccol=DEC "
      ."radecerrcol=RADEC_ERR "
      ."fluxcol=FLUX "
      ."fluxerrcol=FLUX_ERR "
#      ."fluxstyle=simple " # choice simple, root, rand
      ."fluxstyle=rand " # choice simple, root, rand
      ."randcol=LINF "
      ."randerrcol=LINF_ERR "
      ;

SAS::error('matchDetWithSimFailed', "Couldn't compare detected to "
."simulated source lists.")
      if (&run("$command"));
  }

  goto ENDD if ($last_stage eq 'compare');

#  ADDSIMRATES:
#
#  # Params accessed:
#
#  #	- prdsdir
#  #	- interdir
#  #	- obsnumber
#  #	- instexpids
#  #	- streamnumber
#  #	- idnumber
#  #	- entrystage
#  #	- finalstage
#  #	- astest
#
#  foreach $obsid_root (@obsid_roots) {
#    $obsid = $obs_ids{$obsid_root};
#
#    my $detsrclistset = $detsets{$obsid};
#SAS::error('noDetectedSrcListSet', "Couldn't find $detsrclistset.")
#    if (!$testFlag && !-e "$detsrclistset");
#
#    $command = "eimsim "
#    ."function=addsimratecols "
#    ."detsrclistset=$detsrclistset "
#    ."idcol=SRC_NUM "
#    ;
#
#SAS::error('addSimRateColsFailed', "Couldn't add sim_rate columns to det list.")
#    if (&run("$command"));
#  }
#
#  goto ENDD if ($last_stage eq 'addsimrates');

#  FILTER:
#
#  # Params accessed:
#
#  #     - obsnumber
#  #	- instexpids
#  #	- streamnumber
#  #	- idnumber
#  #	- entrystage
#  #	- finalstage
#  #	- astest
#
#  foreach $obsid_root (@obsid_roots) {
#    $obsid = $obs_ids{$obsid_root};
#    foreach $instexpid (@{$instexpids{$obsid}}) {
#      $mlset = $mlsets{$obsid}{$instexpid};
#SAS::error('noMlSrcListSet', "Couldn't find $mlset.") if (!$testFlag && !-e "$mlset");
#      $filtered_mlset = $filtered_mlsets{$obsid}{$instexpid};
#
#      $command = "fselect "
##***** try evselect to avoid cross-talk problems between streams????
#      ."infile=$mlset'[SRCLIST]' "
#      ."outfile=$filtered_mlset "
#      ."expr='(ID_BAND==0)&&(!(isnull(RATE)))&&(RATE_ERR>0.0)' "
#      ."clobber=yes "
#      ;
#
#SAS::error('filterSrcListFailed', "Couldn't filter $mlset")
#      if (&run("$command"));
#    }
#  }
#
#  goto ENDD if ($last_stage eq 'filter');
#
#  SENSMAPS:
#
#  # Params accessed:
##****
#
#  foreach $obsid_root (@obsid_roots) {
#    $obsid = $obs_ids{$obsid_root};
#    foreach $instexpid (@{$instexpids{$obsid}}) {
#      $sens_map = "$sens_maps{$obsid}{$instexpid}";
#SAS::error('noSensMapSet', "Couldn't find $sens_map.") if (!$testFlag && !-e "$sens_map");
#      $filtered_mlset = $filtered_mlsets{$obsid}{$instexpid};
#SAS::error('noFilteredMlSrcListSet', "Couldn't find $filtered_mlset.")
#      if (!$testFlag && !-e "$filtered_mlset");
#
#      $command = "imsample "
#      ."imageset=$sens_map "
#      ."srclisttab=$filtered_mlset:SRCLIST "
#      ."outcol=SENSY "
#      ;
#
#SAS::error('sampleSensMapFailed', "Couldn't add SENSY column to source list.")
#      if (&run("$command"));
#    }
#  }
#
#  goto ENDD if ($last_stage eq 'sensmaps');


  CLEANUP:
#  print "*************** start CLEANUP ****************\n\n";
  SAS::message($SAS::AppMsg, $SAS::VerboseMsg,
    "*************** start CLEANUP ****************\n");

  # Do the detect task first, otherwise it might exit if it can't find some
  # of its necessary precursor files.
  #
  $det_path = `which $det_script`;
  chomp ($det_path);
  if (-e "$det_path") {
SAS::error('noDetTask', "--dettask $det_script is not executable.") if (!-x "$det_path");
  } else {
SAS::error('noDetTask', "--dettask $det_script not found.");
  }

#  my $edetect_cleanup;
#  if ($cleanup) {
#    $edetect_cleanup = 'yes';
#  } else {
#    $edetect_cleanup = 'no';
#  }

#  my $edetect_astest;
  if ($testFlag) {
    $edetect_astest = 'yes';
  } else {
    $edetect_astest = 'no';
  }

  $command = "$det_script "
  ."obsidroots='".join(' ', @obsid_roots)."' "
  ."prdssubdir=$prod_subdir "
  ."simopsubdir=$simop_subdir "
  ."simgensubdir=$simgen_subdir "
#  ."cleanup=$edetect_cleanup "
  ."astest=$edetect_astest "
  ."srcspecset=$template_set "
#  ."tempascii=$temp_ascii "
  ."srclistset=$raw_det_list "
  ."streamnumber=$stream_num "
  ."idnumber=$id_number "
  ."entrystage=cleanup "
  ."finalstage=cleanup "
  ;

#  print "\ninvoke $command\n\n";
  SAS::message($SAS::AppMsg, $SAS::VerboseMsg, "invoke $command\n");

SAS::error('detectTaskFailed', "Couldn't run $det_script cleanup.")
  if (system($command));
  # Not using &run() here because we want the detect script to be run whether
  # $params{'astest'} is set or not. $params{'astest'} is passed to the
  # detect script and so is also effective therein.


#  if ($cleanup) {
    &cleanup($temp_image_set);
    &cleanup($temp_srclist_set);
    &cleanup($temp_ascii);
    foreach my $obsid_root (@obsid_roots) {
      my $obsid = $obs_ids{$obsid_root};
      foreach my $instexpid (@{$instexpids{$obsid}}) {
        &cleanup($flux_images_faint{$obsid}{$instexpid});
        foreach my $band (@used_bands) {
          &cleanup($sim_images{$obsid}{$instexpid}{$band});
          &cleanup($src_cts_images{$obsid}{$instexpid}{$band});
          &cleanup($src_rate_images{$obsid}{$instexpid}{$band});
          &cleanup($cts_images{$obsid}{$instexpid}{$band});
          &cleanup($sim_images{$obsid}{$instexpid}{$band});
#          &cleanup($bkg_cts_images{$obsid}{$instexpid}{$band});
          &cleanup($flux_images_bright{$obsid}{$instexpid}{$band});
        } # end foreach $band (@used_bands)
      } # end foreach $instexpid (@{$instexpids{$obsid}})
    } # end foreach $obsid_root (@obsid_roots)
#  } # end if cleanup


  ENDD:

  print "\nFINISHED CYCLE\n\n";

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

