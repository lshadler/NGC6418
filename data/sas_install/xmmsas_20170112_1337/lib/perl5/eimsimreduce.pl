# This perl task should be run after eimsimbatch. You should run eimsimreduce once only, and in only one 'stream'.

my ($testFlag);
my ($command, $makeBlankFields, $kwd);

sub eimsimreduce {

  use SAS;
  use eimsimperlsubs;

  my $taskname = "eimsimreduce";

  # Prints all output to stderr:
  select(STDERR);

  #......................................................................
  # Read and check parameters:

  $testFlag            = booleanParameter('astest');
  my $testFlagStr = &boolToStr($testFlag);

  my $first_stage      = stringParameter('entrystage');
  my $last_stage       = stringParameter('finalstage');
  my $simgen_subdir    = stringParameter('simgensubdir');
  my $template_set     = stringParameter('srcspecset');
  my $errors_histo_bin_size = realParameter('biashistobinsize');
  my $comp_histo_bin_size   = realParameter('comphistobinsize');
  my $prob_cutoff           = realParameter('probcutoff');
  my $rel_histo_bin_size    = realParameter('relhistobinsize');

  #......................................................................
  # Setup file names:

  my $det_list_command = "ls -1 $simgen_subdir/Sim_rawDetList_S??F????.fits";
  my @det_lists = `$det_list_command`;
  foreach my $det_list_path (@det_lists){
    chomp($det_list_path);
    my @chunks = split('\/', $det_list_path);
    my $det_list = $chunks[$#chunks];
    my $stream = substr($det_list, 16, 2);
    my $field = substr($det_list, 19, 4);
#print "@chunks\n";
#    my $sim_list_path = join('\/', @chunks[0..$#chunks-1])
#    my $sim_list_path = join('/', @chunks[0..$#chunks-1])
#      ."/Sim_srcList_S$stream"."F$field.fits";
#SAS::error('mismatchedSimAndDetLists', "There is a list of detected "
#  ."sources $det_list_path but no matching list of sim sources "
#  ."$sim_list_path.")
#    if (!-e $sim_list_path);
  }

  my $sim_list_command = "ls -1 $simgen_subdir/Sim_srcList_S??F????.fits";

  my $num_fields = @det_lists;
  my $list_of_detlist_sets = "$simgen_subdir/ListOfDetLists.asc";
  my $list_of_simlist_sets = "$simgen_subdir/ListOfSimLists.asc";
  my $merged_set = "$simgen_subdir/MergedDetList.fits";
  my $errors_histo_set       = "$simgen_subdir/BiasHisto.fits";
  my $completeness_histo_set = "$simgen_subdir/CompletenessHisto.fits";
  my $reliability_histo_set  = "$simgen_subdir/ReliabilityHisto.fits";

  my $biasXplot1         = "$simgen_subdir/bias_tanx_1.ps";
  my $biasXplot2         = "$simgen_subdir/bias_tanx_2.ps";
  my $biasXplot3         = "$simgen_subdir/bias_tanx_3.ps";
  my $biasYplot1         = "$simgen_subdir/bias_tany_1.ps";
  my $biasYplot2         = "$simgen_subdir/bias_tany_2.ps";
  my $biasYplot3         = "$simgen_subdir/bias_tany_3.ps";
  my $biasSplot1         = "$simgen_subdir/bias_flux_1.ps";
  my $biasSplot2         = "$simgen_subdir/bias_flux_2.ps";
  my $biasSplot3         = "$simgen_subdir/bias_flux_3.ps";
  my $completeness_plot1 = "$simgen_subdir/Completeness1.ps";
  my $completeness_plot2 = "$simgen_subdir/Completeness2.ps";
  my $completeness_plot3 = "$simgen_subdir/Completeness3.ps";
  my $completeness_plot4 = "$simgen_subdir/Completeness4.ps";
  my $completeness_plot5 = "$simgen_subdir/Completeness5.ps";
  my $reliability_plot1  = "$simgen_subdir/Reliability1.ps";
  my $reliability_plot2  = "$simgen_subdir/Reliability2.ps";
  my $reliability_plot3  = "$simgen_subdir/Reliability3.ps";
  my $reliability_plot4  = "$simgen_subdir/Reliability4.ps";

  #......................................................................
  # Decide where to go:

  if ($first_stage eq 'merge') {
    goto MERGE;

  } elsif ($first_stage eq 'bias') {
    goto ERRORS;

  } elsif ($first_stage eq 'completeness') {
    goto COMPLETENESS;

  } elsif ($first_stage eq 'reliability') {
    goto RELIABILITY;

  } else {
SAS::error('badEntryStage', "Unrecognized entry stage $first_stage.");
  }

  #......................................................................
  # Start main routine:

  MERGE:

SAS::error('detLsFailed', "Couldn't ls the detlist sets.")
  if (&run("$det_list_command > $list_of_detlist_sets"));

  $command = "fmerge "
  .'@'."$list_of_detlist_sets "
  ."outfile=$merged_set "
  ."columns=- "
  ."clobber=yes "
  ;

SAS::error('fmergeFailed', "Couldn't merge source lists.") if (&run("$command"));

  $command = "fparkey "
  ."value=$num_fields "
  ."fitsfile=$merged_set+1 "
  ."keyword='N_FIELDS' "
  ."add=yes "
  ;

SAS::error('fparkeyFailed', "Couldn't add N_FIELDS keyword to merged source list.")
  if (&run("$command"));

  goto ENDD if ($last_stage eq 'merge');


  ERRORS:

SAS::error('noMergedSet', "Couldn't find $merged_set.")
  if (!$testFlag && !-e "$merged_set");

  $makeBlankFields = 0;
  if (!$testFlag){
    $kwd = &eimsimperlsubs::readFITSKeyword($merged_set, 'SRCLIST', 'COMPARED');
    if ($kwd eq '' || $kwd eq 'F') {$makeBlankFields = 1;}
  }

  if ($makeBlankFields) {
    SAS::warning('noActionForUncompared', "Keyword COMPARED in the list of detections is unset: thus no action this section.");
  } else {
    $command = "eimsimbias "
    ."histoset=$errors_histo_set "
    ."append=no " # makes a new histo dataset
    ."detsrclistset=$merged_set "
    ."xcolumn=FLUX "
    ."pstr=X "
    ."xbinwidth=$errors_histo_bin_size "
    ."withplots=yes "
    ."plot1file=$biasXplot1 "
    ."plot2file=$biasXplot2 "
    ."plot3file=$biasXplot3 "
    ;

SAS::error('eimsimbiasFailed', "Couldn't run 1st eimsimbias.") if (&run("$command"));

    $command = "eimsimbias "
    ."histoset=$errors_histo_set "
    ."append=yes "
    ."detsrclistset=$merged_set "
    ."xcolumn=FLUX "
    ."pstr=Y "
    ."xbinwidth=$errors_histo_bin_size "
    ."withplots=yes "
    ."plot1file=$biasYplot1 "
    ."plot2file=$biasYplot2 "
    ."plot3file=$biasYplot3 "
    ;

SAS::error('eimsimbiasFailed', "Couldn't run 2nd eimsimbias.") if (&run("$command"));

    $command = "eimsimbias "
    ."histoset=$errors_histo_set "
    ."append=yes "
    ."detsrclistset=$merged_set "
    ."xcolumn=SIM_FLUX "
    ."pstr=FLUX "
    ."xbinwidth=$errors_histo_bin_size "
    ."withplots=yes "
    ."plot1file=$biasSplot1 "
    ."plot2file=$biasSplot2 "
    ."plot3file=$biasSplot3 "
    ;

SAS::error('eimsimbiasFailed', "Couldn't run 3rd eimsimbias.") if (&run("$command"));
  }

  goto ENDD if ($last_stage eq 'bias');


  COMPLETENESS:

SAS::error('noMergedSet', "Couldn't find $merged_set.")
  if (!$testFlag && !-e "$merged_set");

  $makeBlankFields = 0;
  if (!$testFlag){
    $kwd = &eimsimperlsubs::readFITSKeyword($merged_set, 'SRCLIST', 'COMPARED');
    if ($kwd eq '' || $kwd eq 'F') {$makeBlankFields = 1;}
  }

  if ($makeBlankFields) {
    SAS::warning('noActionForUncompared', "Keyword COMPARED in the list of detections is unset: thus no action this section.");
  } else {
SAS::error('simLsFailed', "Couldn't ls the simlist sets.")
    if (&run("$sim_list_command > $list_of_simlist_sets"));

    $command = "eimsimcompleteness "
    ."srcspecset=$template_set "
    ."histobinsize=$comp_histo_bin_size "
    ."histoset=$completeness_histo_set "
    ."filelist=$list_of_simlist_sets "
    ."detsrclistset=$merged_set "
    ."probcutoff=$prob_cutoff "
    ."withplots=yes "
    ."plot1file=$completeness_plot1 "
    ."plot2file=$completeness_plot2 "
    ."plot3file=$completeness_plot3 "
    ."plot4file=$completeness_plot4 "
    ."plot5file=$completeness_plot5 "
    ;

SAS::error('eimsimcompletenessFailed', "Couldn't run eimsimcompleteness.")
    if (&run("$command"));
  }

  goto ENDD if ($last_stage eq 'completeness');


  RELIABILITY:

SAS::error('noMergedSet', "Couldn't find $merged_set.")
  if (!$testFlag && !-e "$merged_set");

#  $makeBlankFields = 0;
#  if (!$testFlag){
#    $kwd = &eimsimperlsubs::readFITSKeyword($merged_set, 'SRCLIST', 'COMPARED');
#    if ($kwd eq '' || $kwd eq 'F') {$makeBlankFields = 1;}
################### check that fkeyprint does return this string for boolean kwds.
#  }

#  if ($makeBlankFields) {
#    SAS::warning('noActionForUncompared', "Keyword COMPARED in the list of detections is unset: thus no action this section.");
#  } else {
    $command = "eimsimreliability "
    ."histobinsize=$rel_histo_bin_size "
    ."histoset=$reliability_histo_set "
    ."detsrclistset=$merged_set "
    ."probcutoff=$prob_cutoff "
    ."withplots=yes "
    ."plot1file=$reliability_plot1 "
    ."plot2file=$reliability_plot2 "
    ."plot3file=$reliability_plot3 "
    ."plot4file=$reliability_plot4 "
    ;

SAS::error('eimsimreliabilityFailed', "Couldn't run eimsimreliability.")
    if (&run("$command"));
#  }

  goto ENDD if ($last_stage eq 'reliability');

  ENDD:

}

  #---------------------------------------------------------------------
  sub run {
  #---------------------------------------------------------------------
  # $testFlag should be defined globally.

    my ($command) = @_;
    my $status = 0;

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

