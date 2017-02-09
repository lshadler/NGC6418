# This perl task is designed to be called from eimsimprep. You should not run it from the command line, but instead submit its name to eimsimprep via the --detpreptask parameter.

my ($testFlag);
my ($command);

sub eimsimdetprep2xmm {

  use SAS;
  use eimsimperlsubs;

  my $taskname = "eimsimdetprep2xmm";

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
  }

  $testFlag            = booleanParameter('astest');

  my $first_stage      = stringParameter('entrystage');
  my $last_stage       = stringParameter('finalstage');
  my $prod_subdir      = stringParameter('prdssubdir');
  my $simop_subdir     = stringParameter('simopsubdir');
  my $simgen_subdir    = stringParameter('simgensubdir');
#  my $ref_band         = intParameter('refband');
  my $template_set     = stringParameter('srcspecset');
#  my $temp_ascii       = stringParameter('tempascii');
#  my $stream_num       = intParameter('streamnumber');

  my %versions = ('emask'      => '2.9',
                  'eboxdetect' => '4.15.2',
                  'emldetect'  => '4.44.25',
                  'esplinemap' => '4.4');
  foreach my $taskname (keys(%versions)){
    my $prescribed_version = $versions{$taskname};
    my $version = &eimsimperlsubs::getVersion($taskname);
    if ($version ne $prescribed_version){
    SAS::warning('badTaskVersion', "Found version $version of task "
      ."$taskname although version $prescribed_version is required. "
      ."The simulations may not proceed correctly.");
    }
  }

  #......................................................................
  # Read ECF data from template file. In the present script this is just
  # needed for the list of instruments.
  #
  if (!-d "$simgen_subdir") {
    SAS::warning('noGenericSimOutputSubdir', "Directory $simgen_subdir not found; I'll try to mkdir it.");
SAS::error('mkdirFailed', "Couldn't mkdir $simgen_subdir.")
    if (system("mkdir -p $simgen_subdir"));
SAS::error('noSimOutputSubdir', "Directory $simgen_subdir not found.")
    if (!-d "$simgen_subdir");
  }

  my $temp_ascii = "$simgen_subdir/Sim_temp.txt";

  my ($ecf_ref, $sim_fluxDensityToFlux)
    = &eimsimperlsubs::readEcfs($template_set, $temp_ascii, $testFlag);
  my @ecf_info = @{$ecf_ref};
SAS::error('noEcfsFound', "No ECF entries were returned by readEcfs.")
  if (@ecf_info <= 0);

SAS::error('badEcfStructure', "No instrument data returned in the ECF hash.")
  if (!defined($ecf_info[0]{'instrums'}));

#  my %filter_lists = %{$ecf_info[0]{'instrums'}};
#  my @used_insts_uc = keys(%filter_lists);

#  my @used_bands = ();
#  my %Elos = ();
#  my %Ehis = ();
#  foreach my $i (0 .. $#ecf_info) {
#    my $band = $ecf_info[$i]{'bandid'};
#  next if ($band eq '9');
#    $used_bands[$i] = $band;
#    my @band_ranges = @{$ecf_info[$i]{'edges'}};
#    $Elos{$band} = $band_ranges[0            ]{'lo'};
#    $Ehis{$band} = $band_ranges[$#band_ranges]{'hi'};
#  }
#
#  #......................................................................
#  # Set up obsid hash:
#
#  my %obs_ids = &eimsimperlsubs::setUpObsIdHash_new($prod_subdir, @obsid_roots);
#  # in eimsimperlsubs.
#
#  #......................................................................
#  # Setup instexpid arrays from existence of any files for that obsid and
#  # instrument:
#
#  my %temp_hash = ();
#  my %instexpids = ();
#  foreach my $obsid_root (@obsid_roots) {
#    my $prod_dir  = "$obsid_root/$prod_subdir";
#    my $obsid = $obs_ids{$obsid_root};
#
#    my %temp_hash = ();
#    foreach my $inst_uc (@used_insts_uc) {
#      my @files = `ls -1 $prod_dir/P$obsid$inst_uc*`;
#      foreach my $file (@files) {
#        my @chunks = split('\/', $file);
#        if ($chunks[$#chunks] =~ /^P${obsid}${inst_uc}((S|U)\d{3})\S{6}(\d)/) {
#          my $instexpid = "$inst_uc$1";
#          $temp_hash{$instexpid} = 1;
#        }
#      }
#    }
#    push @{$instexpids{$obsid}}, keys(%temp_hash)
#  }

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

  my %Elos = ();
  my %Ehis = ();
  foreach my $band (@used_bands) {
    my $i = $band_to_i{$band};
    my @band_ranges = @{$ecf_info[$i]{'edges'}};
    $Elos{$band} = $band_ranges[0            ]{'lo'};
    $Ehis{$band} = $band_ranges[$#band_ranges]{'hi'};
  }

  my %inst_uc2lc = (
    'M1'=>'emos1',
    'M2'=>'emos2',
    'PN'=>'epn',
    'R1'=>'rgs1',
    'R2'=>'rgs2',
    'OM'=>'om',
    'EP'=>'epic'
  );

  #......................................................................
  # Set up all file names and other variables:

  my %evlists = ();
  my %image_evlists = ();
  my %attsets = ();
  my %attGTIFiles = ();
  foreach my $obsid_root (@obsid_roots) {
    my $prod_dir  = "$obsid_root/$prod_subdir";
    my $simop_dir = "$obsid_root/$simop_subdir";

    my $obsid = $obs_ids{$obsid_root};

###    $cifs{$obsid}         = "$prod_dir/P$obsid".  "OBX000CALIND0000.FIT";
    $attsets{$obsid} = "$prod_dir/P$obsid"."OBX000ATTTSR0000.FIT";
    $attGTIFiles{$obsid} = "$simop_dir/Sim_attitudeGtis.fits";

    foreach my $instexpid (@{$instexpids{$obsid}}) {
      my $inst_uc = substr($instexpid, 0, 2);

      if ($inst_uc eq 'PN') {
        $evlists{$obsid}{$instexpid} = "$prod_dir/P$obsid$instexpid"
          ."PIEVLI0000.FIT";
      } else {
        $evlists{$obsid}{$instexpid} = "$prod_dir/P$obsid$instexpid"
          ."MIEVLI0000.FIT";
      }

      foreach my $band (@used_bands) {
        $image_evlists{$obsid}{$instexpid}{$band}
          = "$simop_dir/Sim_$instexpid"."_imageEventList_$band.fits";
#        if ($inst_uc eq 'PN') {
#          $image_evlists{$obsid}{$instexpid}{$band}
#            = "$simop_dir/P$id_str$instexpid"."PIEVLI$band"."000.FIT";
#        } else {
#          $image_evlists{$obsid}{$instexpid}{$band}
#            = "$simop_dir/P$id_str$instexpid"."MIEVLI$band"."000.FIT";
#        }
      }
    }
  }

  # Event selection expressions follow. Mos expressions were copied from version 2.09 of the MakeMOSImage pipeline module; pn expressions were copied from version 2.14 of the MakePNImage module. NOTE! Haven't broken up band 5 for PN to avoid copper line. IMS 2006-10-09.
  #
  my %Flags = (
    'emos1' => {
        'default' => '(FLAG & 0x766ba000)==0'
        , '8'     => '(FLAG & 0x766aa000)==0'
        , '8fov'  => '(FLAG & 0x766ba000)==0'
      }
    , 'emos2' => {
        'default' => '(FLAG & 0x766ba000)==0'
        , '8'     => '(FLAG & 0x766aa000)==0'
        , '8fov'  => '(FLAG & 0x766ba000)==0'
    }
    , 'epn' => {
          '1' => '(FLAG & 0x2fb002c)==0'
        , '2' => '(FLAG & 0x2fb002c)==0'
        , '3' => '(FLAG & 0x2fb0024)==0'
        , '4' => '(FLAG & 0x2fb0024)==0'
        , '5' => '(FLAG & 0x2fb0024)==0'
    }
  );

  my %expressions = ();
  foreach my $obsid_root (@obsid_roots) {
    my $obsid = $obs_ids{$obsid_root};
    my $attGTIFile = $attGTIFiles{$obsid};
    foreach my $instexpid (@{$instexpids{$obsid}}) {
      my $inst_uc = substr($instexpid, 0, 2);
      my $inst_lc = $inst_uc2lc{$inst_uc};
      foreach my $band (@used_bands) {
        my (@expr);
        my $pilo = $Elos{$band};
        my $pihi = $Ehis{$band};
        push @expr, "(PI in ($pilo:$pihi])";
        push @expr, "GTI($attGTIFile, TIME)";

        if ($inst_lc eq 'epn'){
          push @expr, "(RAWY>12)";
          if ($band eq '1'){
            push @expr, '(PATTERN==0)';
          } else {
            push @expr, '(PATTERN<=4)';
          }
          push @expr, $Flags{$inst_lc}{$band};

        } else { # must be mos
          push @expr, "(PATTERN<=12)";
          push @expr, $Flags{$inst_lc}{'default'};
        } # end choice of inst

        $expressions{$obsid}{$instexpid}{$band} = join(' && ', @expr);
      } # end loop over band
    } # end loop over instexpid
  } # end loop over obsids

  #......................................................................
  # Decide where to go:

  if ($first_stage eq 'main') {
    goto MAINN;

  } elsif ($first_stage eq 'cleanup') {
    goto CLEANUP;

  } else {
SAS::error('badEntryStage', "Unrecognized entry stage $first_stage.");
  }

  #......................................................................
  # Start main routine:

  MAINN:

  foreach my $obsid_root (@obsid_roots) {
    my $obsid = $obs_ids{$obsid_root};

    my $attset = $attsets{$obsid};
SAS::error('noAtthkgenOutput', "Couldn't find $attset.") if (!-e "$attset");

    # Make the attitude GTI set:
    #
    my $attGTIFile = $attGTIFiles{$obsid};

    $command = "tabgtigen "
    ."expression='!isNull(DAHFPNT) && (DAHFPNT < 3.0/60.0)' "
    ."gtiset=$attGTIFile "
    ."table=$attset:ATTHK "
    ."postfraction=0 "
    ."prefraction=0 "
    ;

SAS::error('evselectFailed', "Couldn't run tabgtigen to make attitude GTIs.")
    if (&run("$command"));

SAS::error('noAttitudeGtis', "Couldn't find $attGTIFile.")
    if (!$testFlag && !-e "$attGTIFile");

    foreach my $instexpid (@{$instexpids{$obsid}}) {
      my $inst_uc = substr($instexpid, 0, 2);

      # Now make all the band-filtered event lists:
      #
      my $evlist = $evlists{$obsid}{$instexpid};
SAS::error('noEventList', "Couldn't find $evlist.") if (!-e "$evlist");

      foreach my $band (@used_bands) {
        my $image_evlist = $image_evlists{$obsid}{$instexpid}{$band};
        my $expression = $expressions{$obsid}{$instexpid}{$band};

        # The evselect parameters were copied from version 2.09 of the MakeMOSImage pipeline module and version 2.14 of the MakePNImage module (the set of parameters appears to be the identical in both modules). I have commented out those parameters which are used in the modules just to make images, because here the point is to make the filtered, band-specific event lists only. IMS 2006-10-09.

        $command = "evselect "
        ."table=$evlist:EVENTS "
        ."keepfilteroutput=yes "
        ."withfilteredset=yes "
        ."filteredset=$image_evlist "
        ."writedss=yes "
        ."updateexposure=yes "
        ."expression='$expression' "
#        ."withimageset='Y' "
#        ."imageset= $imgFile "
#        ."xcolumn='X' "
#        ."ycolumn='Y' "
#        ."imagebinning='binSize' "
#        ."ximagebinsize=80 "
#        ."yimagebinsize=80 "
#        ."withimagedatatype='true' "
#        ."imagedatatype='Int32' "
        ;

SAS::error('evselectFailed', "Couldn't filter event list for inst $inst_uc band $band.")
        if (&run("$command"));
      }
    }
  }

  goto ENDD if ($last_stage eq 'main');


  CLEANUP:

  foreach my $obsid_root (@obsid_roots) {
    my $obsid = $obs_ids{$obsid_root};
    &cleanup($attGTIFiles{$obsid});
    foreach my $instexpid (@{$instexpids{$obsid}}) {
      foreach my $band (@used_bands) {
        &cleanup($image_evlists{$obsid}{$instexpid}{$band});
      }
    }
  }

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

