# This perl task is designed to be called from eimsimprep. You should not run it from the command line, but instead submit its name to eimsimprep via the --detpreptask parameter.

my ($testFlag);
my ($command);

sub eimsimdetprep1xmm {

  use SAS;
  use eimsimperlsubs;

  my $taskname = "eimsimdetprep1xmm";

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
  my $ref_band         = intParameter('refband');
  my $template_set     = stringParameter('srcspecset');
#  my $temp_ascii       = stringParameter('tempascii');
#  my $stream_num       = intParameter('streamnumber');

  my %versions = ('emask'      => '2.7',
                  'eboxdetect' => '4.13.1',
                  'emldetect'  => '4.32.1',
                  'esplinemap' => '4.0.3',
                  'srcmatch'   => '3.15.1');
  foreach my $taskname (keys(%versions)){
#print "$taskname\n";
    my $prescribed_version = $versions{$taskname};
#print "$prescribed_version\n";
    my $version = &eimsimperlsubs::getVersion($taskname);
#print "$version\n";
    if ($version ne $prescribed_version){
    SAS::warning('badTaskVersion', "Found version $version of task "
      ."$taskname although version $prescribed_version is required. "
      ."The simulations may not proceed correctly.");
    }
  }
#exit 0;

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

  #......................................................................
  # Set up all file names and other variables:

#  $stream_num =~ s/^0+//; # chop off any leading zeros
#  $id_number  =~ s/^0+//; # chop off any leading zeros
#  my $stream_num_str = '0'x(2-length($stream_num))."$stream_num";
#  my $id_number_str  = '0'x(4-length($id_number)) ."$id_number";
#  my $id_str = "S$stream_num_str"."F$id_number_str";

  my %expmap_refs = ();
  my %detmasksets = ();
  foreach my $obsid_root (@obsid_roots) {
#print "obsid_root $obsid_root\n";
    my $prod_dir  = "$obsid_root/$prod_subdir";
    my $simop_dir = "$obsid_root/$simop_subdir";

    my $obsid = $obs_ids{$obsid_root};

    foreach my $instexpid (@{$instexpids{$obsid}}) {
#print "  instexpid $instexpid\n";
      $expmap_refs{"$obsid$instexpid"} = "$prod_dir/P$obsid$instexpid"
        ."EXPMAP$ref_band"."000.FIT";

      $detmasksets{$obsid}{$instexpid} = "$simop_dir/Sim_$instexpid"
        ."_edetectMask.fits";
    } # end foreach $instexpid (@{$instexpids{$obsid}})
  } # end foreach $obsid_root (@obsid_roots)


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
    foreach my $instexpid (@{$instexpids{$obsid}}) {
      my $expmapset = $expmap_refs{"$obsid$instexpid"};
SAS::error('noExpMap', "Can't find ref-band $expmapset.") if (!-e "$expmapset");
      my $detmaskset = $detmasksets{$obsid}{$instexpid};

      $command = "emask "
      ."expimageset=$expmapset "
      ."detmaskset=$detmaskset "
      ."threshold1=0.05 "
      ;

SAS::error('emaskFailed', "Couldn't run emask.") if (&run("$command"));
    }
  }

  goto ENDD if ($last_stage eq 'main');


  CLEANUP:

  foreach my $obsid_root (@obsid_roots) {
    my $obsid = $obs_ids{$obsid_root};
    foreach my $instexpid (@{$instexpids{$obsid}}) {
      &cleanup($detmasksets{$obsid}{$instexpid});
    } # end foreach $instexpid (@{$instexpids{$obsid}})
  } # end foreach $obsid_root (@obsid_roots)

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

