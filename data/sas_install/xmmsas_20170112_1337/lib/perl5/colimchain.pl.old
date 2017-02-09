#! /usr/bin/perl -w
#
# NAME: colimchain
# VERSION: 1.5
#
# Developer: Ian Stewart		SSC-LUX
#
# TODO:
#	- Replace prints by SAS::message. In all other perl tasks too.
#	- Check that .lyt file works.
#
#########################################################################

my ($testflag, %obs_list);
my ($i, $band_num, $filename, $maskfile, $template_band_num, $command, $infile, $at_least_one_not_flat, @input_filepaths);
my ($colimplot_pgdev, $colimplot_op_file, $x_offset, $y_offset, $line1, $line2, $all_line, $x_size, $y_size, $status, $temp_ppm_file, $taskname, $xi, $yi, $a_redval, $a_bluval, $a_grnval, $b_redval, $b_bluval, $b_grnval, $b_index, $read_index, $last_index, $max_buf_len, @read_vector, $write_index, $buf, @write_vector, $log_name, $write_log);

sub colimchain {

  use SAS;
  no strict 'refs';

  $taskname = "colimchain";

  my $apm = $SAS::AppMsg;
  my $vbs = $SAS::VerboseMsg;
  my $nsy = $SAS::NoisyMsg;

#  my (%params, $ccf_path);
#  my (%obs_list, $band_num, $filename, %filenames, @input_filepaths);
#  my ($infile, $opfile, $command, $i, $maskfile, $status, $colimplot_op_file, $colimplot_pgdev, $clobber, @chunks, $junk, $max);
#  my ($x_offset, $y_offset, $line1, $line2, @lines, $x_size, $y_size);
#
#  my $log_name = 'log';

  # Prints all output to stderr:
  select(STDERR);


  my $frame_gif_file = "frame.gif";
  my $frame_ppm_file = "frame.ppm";
  my $coms_file = "chain_coms.dat";
  my $whole_ppm_file = 'whole.ppm';
  my $image_ppm_file = 'image.ppm';
  my $thumblist_file = 'links.lis';

  # Vars used by &write_byte and &read_byte:
#  my $max_buf_len = 16384;
my $max_buf_len = 16;
  my $read_index = 0;
  my $write_index = 0;
  my $last_index = 0;

#  %params = &getParams;

  my $num_entries = parameterCount('bandlist');
SAS::error('tooFewBands', "Too few images - can't make a colour plot.")
  if ($num_entries <= 1);

  my @band_nums = ();
  foreach $i (0 .. $num_entries-1) {
    $band_nums[$i] = intParameter('bandlist', $i)
  }
  @band_nums = sort(@band_nums);

#  $clobbertemps  = booleanParameter('clobbertemps');
  my $clobberprods  = booleanParameter('clobberprods');
  my $prod_dir      = stringParameter('prodsdir');
  my $output_file   = stringParameter('plotfile');
  my $pgdev         = stringParameter('pgdev');
  my $thumbnail_dir = stringParameter('thumbnaildir');
  my $inst_lc       = stringParameter('instrument');
### instexpid??
  my $idtype        = stringParameter('idtype');
  my $obsindex      = intParameter('obsindex');
  my $expindex      = intParameter('expindex');
  my $obsid         = stringParameter('obsid');
  my $expid         = stringParameter('expid');
  my $do_smooth     = booleanParameter('smooth');
  my $maxwidth      = realParameter('maxwidth');
  my $nconvolvers   = intParameter('nconvolvers');
  my $desiredsnr    = realParameter('desiredsnr');
  my $withthumbnails = booleanParameter('withthumbnails');

  my $expandtomask  = booleanParameter('expandtomask');
  my $rebinimage    = booleanParameter('rebinimage');
  my $newnxbins     = intParameter('newnxbins');
  my $newnybins     = intParameter('newnybins');
  my $cutoff        = realParameter('cutoff');
  my $weirdness     = realParameter('weirdness');
  my $heat          = realParameter('heat');
  my $heatspread    = realParameter('heatspread');
  my $gainstyle     = stringParameter('gainstyle');
  my $gain          = realParameter('gain');
#*** change it to usergain in line with colimplot?
  my $add_to_frame  = booleanParameter('withframe');

  $testflag      = booleanParameter('astest');

  if ($testflag) {SAS::warning('inTestMode',"The --astest parameter is set: "
    ."you will get no real output.");}

my $template_name = 'asmooth_template.ds';
### pass template set name as command-line parameter.


#  my $testflag = &boolTranslate($params{astest});
#  my $clobbertemps = &boolTranslate($params{clobbertemps});
#  my $clobberprods = &boolTranslate($params{clobberprods});
#  my $prod_dir = $params{prodsdir};
#  my $write_log = &boolTranslate($params{writelog});
#  my $add_to_frame = &boolTranslate($params{withframe});
#  my $output_file = $params{plotfile};
#  my $pgdev = $params{pgdev};
#  my $thumbnail_dir = $params{'thumbnaildir'};

#  $ccf_path = $params{ccfpath};
#  if (!defined($ccf_path) || $ccf_path eq '') {
    if (!defined($ENV{'SAS_CCF'})) {
#&quit("You must set SAS_CCF before running $taskname.", 1);
SAS::error('noCifSpecified', "You must set SAS_CCF before running $taskname.");
#    } else {
#      $ccf_path = $ENV{'SAS_CCF'};
    }
#  } else {
#    $ENV{'SAS_CCF'} = $ccf_path;
#  }

  #......................................................................
  # Main processing:

#&quit("Directory $prod_dir not found.", 2) if (!-e "$prod_dir");
SAS::error('noProductSubdirectory', "Directory $prod_dir not found.")
    if (!-d "$prod_dir");

  if (-e "$output_file" && !$clobberprods) {
#&quit("Output file $output_file exists, $taskname not run.", 3);
SAS::error('outputExists', "Output file $output_file exists, $taskname not run.");
  }

#  my $inst_uc = uc($params{instrument});
  my $inst_uc = uc($inst_lc);
  if ($inst_uc eq 'OM') {
#&quit("Sorry, can't do OM yet.", 4);
SAS::error('notYetSupported', "Sorry, can't do OM yet.");
  } elsif ($inst_uc ne 'M1' && $inst_uc ne 'M2' && $inst_uc ne 'PN') {
#&quit("Unrecognised instrument.", 5);
SAS::error('badInstrument', "Unrecognised instrument $inst_uc.");
  }

#  $params{bandlist} =~ s/^\s+//;
#  $params{bandlist} =~ s/\s+$//;
#  my @band_nums = sort(split(/\s+/, $params{bandlist}));
#&quit("Too few images to make a colour plot.", 6) if (@band_nums < 2);

#  if ($params{idtype} eq 'index') {
  if ($idtype eq 'index') {
    &makeHashTreeEpic($prod_dir);

    my @obss = sort(keys(%obs_list));
    if (@obss > 1) {
#      &tell("Products directory contains more than 1 observation.");
      print "Products directory contains more than 1 observation.\n";
      SAS::message($vbs, "Products directory contains more than 1 observation.");
    }
#    if ($#obss < $params{obsindex}) {
    if ($#obss < $obsindex) {
#      &warn("The number of observations is fewer than the required obsindex. "
#      ."Last observation being used.");
      SAS::warning('tooFewObs', "The number of observations is fewer than "
        ."the required --obsindex. Last observation is being used instead "
        ."of --obsindex.");

      $obsid = $obss[$#obss];
    } else {
#      $obsid = $obss[$params{obsindex}];
      $obsid = $obss[$obsindex];
    }

    my $exp_list_name = ${${$obsid}{$inst_uc}};
    my @exps = sort(keys(%{$exp_list_name}));
    if (@exps > 1) {
#      &tell("There is more than 1 exposure for this instrument.");
      print "There is more than 1 exposure for this instrument.\n";
    }
#    if ($#exps < $params{expindex}) {
    if ($#exps < $expindex) {
#      &warn("The number of exposures is fewer than the required expindex. "
#      ."Last exposure being used.");
      SAS::warning('tooFewExposures', "The number of exposures is fewer than "
        ."the required --expindex. Last exposure is being used instead "
        ."of --expindex.");

      $expid = $exps[$#exps];
    } else {
#      $expid = $exps[$params{expindex}];
      $expid = $exps[$expindex];
    }

  } else { # assume idtype = 'full':
#    my $obsid = $params{obsid};
#    my $expid = $params{expid};
  }

  my $not_all_files_found = 0;
  my %filenames = ();
  foreach $band_num (@band_nums) {
    $filename = "P$obsid$inst_uc$expid"."IMAGE_$band_num"."000.FIT";
    if (-e "$prod_dir/$filename") {
#      &tell("File $filename found.");
      print "File $filename found.\n";
    } else {
#      &warn("File $filename not found.");
      SAS::warning('imageNotFound', "File $filename not found.");

      $not_all_files_found = 1;
    }
    $filenames{$band_num} = $filename;
  }
  if ($not_all_files_found) {
#&quit("Not all the files were found - can't proceed.", 7);
SAS::error('someImagesNotFound', "Not all the files were found - can't proceed.");
  }

  my $withmaskset = 'yes';
  # Find an exposure map to use for a mask:
  my @files = `ls -1 $prod_dir`;
  my $no_exp_map_found = 1; # default
  foreach (@files) {
    if (/^P($obsid$inst_uc$expid)EXPMAP\d000.FIT/i) {
      $no_exp_map_found = 0;
      $maskfile = $_;
  last;
    }
  }
  if ($no_exp_map_found) {
#    &warn("No exposure map found for this observation+instrument+exposure.");
    SAS::warning('expMapNotFound', "No exposure map was found for this observation+instrument+exposure.");

    $withmaskset = 'no';
  } else {
    chomp($maskfile);

#&quit("Mask $prod_dir/$maskfile is all zero. Can't do smoothing.", 9)
SAS::error('maskAllZeros', "Mask $prod_dir/$maskfile is all zero. Can't do smoothing.") if (&image_is_zero("$prod_dir/$maskfile"));
  }

  #......................................................................
  # Smoothing:

  my $filelist = '';
#  if (&boolTranslate($params{smooth})) {
  if ($do_smooth) {
    # Make template:

    if ($no_exp_map_found) {
#&quit("Can't usefully run asmooth - no exposure map found to use as a mask.",10);
SAS::error('expMapNotFound', "Can't usefully run asmooth - no exposure map found to use as a mask.");
    }

    $template_band_num = $band_nums[0];

#&quit("Template input image is flat. Can't smooth.", 10.1)
SAS::error('templateImageIsFlat', "Template input image is flat. Can't smooth.")
if (&image_is_flat("$prod_dir/$filenames{$template_band_num}"));

    # Make template from the lowest energy band (this will have strongest
    # sources and weakest background):
    my $opfile = "smoothed_"."$template_band_num".".ds";
### should pass this as a command-line parameter.

    $command = "asmooth "
    ."inset=$prod_dir/$filenames{$template_band_num} "
    ."outset=$opfile "
    ."widthliststyle=log "
    ."maxwidth=$maxwidth "
    ."nconvolvers=$nconvolvers "
    ."desiredsnr=$desiredsnr "
    ."templateset=$template_name "
### pass template set name as command-line parameter.
    ."normalize=yes "
### shouldn't be necessary with full use of param-2.0, because it should be default for adaptive smoothing.
    ."withweightset=yes "
    ."weightset=$prod_dir/$maskfile "
    ."withoutmaskset=yes "
    ."outmaskset=$prod_dir/$maskfile "
    ;

#    if (&run($clobbertemps, $opfile, $command, "asmooth output $opfile "
#    ."already exists. asmooth not run.")) {
#&quit("Couldn't run asmooth.", 11);
#    }
SAS::error('templateAsmoothFailed', "Couldn't do first asmooth.")
    if (&run("$command"));

    @input_filepaths = ();
    $at_least_one_not_flat = 0; # default
    foreach $band_num (@band_nums) {
      $opfile = "smoothed_"."$band_num".".ds";
      push @input_filepaths, $opfile;

    next if ($band_num eq $template_band_num);

      $infile = "$prod_dir/$filenames{$band_num}";
      if (&image_is_flat($infile)) {
#        if (&run($clobbertemps, $opfile, "cp $infile $opfile", "Couldn't cp "
#        ."to $opfile, it already exists.")) {
#&quit("Couldn't cp $infile $opfile.", 11.1);
          $command = "cp $infile $opfile";
SAS::error('cpFailed', "Couldn't $command.") if (&run("$command"));
#        }
#fimgstat
    next;
      }

      $at_least_one_not_flat = 1;

      $command = "asmooth "
      ."inset=$infile "
      ."outset=$opfile "
      ."widthliststyle=log "
      ."maxwidth=$maxwidth "
      ."nconvolvers=$nconvolvers "
      ."desiredsnr=$desiredsnr "
      ."readtemplateset=yes "
      ."writetemplateset=no "
      ."templateset=$template_name "
### pass template set name as command-line parameter.
      ."normalize=yes "
### shouldn't be necessary with full use of param-2.0, because it should be default for adaptive smoothing.
#    ."withweightset=yes "
#    ."weightset=$prod_dir/$maskfile "
      ."withoutmaskset=yes "
      ."outmaskset=$prod_dir/$maskfile "
      ;

      ;

#      if (&run($clobbertemps, $opfile, $command, "asmooth output $opfile "
#      ."already exists. asmooth not run.")) {
#&quit("Couldn't run asmooth.", 12);
#      }
SAS::error('asmoothFailed', "Couldn't run asmooth.") if (&run("$command"));
    } # next $band_num

#&quit("No non-flat asmooth input files.", 12.1) if (!$at_least_one_not_flat);
SAS::error('allImagesFlat', "No non-flat asmooth input files.") if (!$at_least_one_not_flat);

  } else { # don't smooth:
    # Compose filename list $filelist:

    @input_filepaths = ();
    foreach(sort(values(%filenames))) {
      push @input_filepaths, "$prod_dir/$_";
    }
  }

  my $at_least_one_not_zero = 0; # default
  foreach(@input_filepaths) {
    if(!&image_is_zero($_)) {
      $at_least_one_not_zero = 1;
  last;
    }
  }
#&quit("No non-zero colimplot input files.", 12.2) if (!$at_least_one_not_zero);
SAS::error('allImagesZero', "No non-zero input images.") if (!$at_least_one_not_zero);

  $filelist = join(' ', @input_filepaths);
  $filelist = "'$filelist'";

#........................................................................
# Colimplot:

  if ($pgdev eq '/png') {
    $colimplot_pgdev = '/ppm';
    $colimplot_op_file = $image_ppm_file;
#    $clobber = $clobbertemps;
  } else {
    $colimplot_pgdev = $pgdev;
    $colimplot_op_file = $output_file;
#    $clobber = $clobberprods;
  }

  $command = "colimplot "
  .      "insets=$filelist "
  ."expandtomask=$expandtomask "
  .  "rebinimage=$rebinimage "
  .   "newnxbins=$newnxbins "
  .   "newnybins=$newnybins "
  .      "cutoff=$cutoff "
  .   "weirdness=$weirdness "
  .        "heat=$heat "
  .  "heatspread=$heatspread "
  .   "gainstyle=$gainstyle "
  .    "usergain=$gain "
  .       "pgdev=$colimplot_pgdev "
  .    "plotfile=$colimplot_op_file "
  .   "withframe=$add_to_frame "
  ;

  if ($no_exp_map_found) {
    $command .= ''
    ."maskstyle=self "

  } else {
    $command .= ''
    . "withmask=$withmaskset "
    ."maskstyle=user "
    .  "maskset=$prod_dir/$maskfile "
  }

#  if (&run($clobber, $colimplot_op_file, $command, "colimplot output "
#  ."$colimplot_op_file already exists. colimplot not run.")) {
#&quit("Couldn't run colimplot.", 13);
#  }
SAS::error('colimplotFailed', "Couldn't run colimplot.") if (&run("$command"));

  if ($pgdev eq '/png') { # then colimplot has written its image
  # output to a file called $image_ppm_file.
    if ($add_to_frame) { # Convert the frame file to ppm and add it
    # to $image_ppm_file to give $whole_ppm_file:
      $command = "giftoppm $frame_gif_file > $frame_ppm_file";
#      if (&run($clobbertemps, $frame_ppm_file, $command, "giftoppm output "
#      ."$frame_ppm_file already exists. giftoppm not run.")) {
#&quit("Couldn't run pnmtopng.", 14);
#      }
SAS::error('pnmtopngFailed', "Couldn't run pnmtopng.") if (&run("$command"));

      $x_offset = 0;
      $y_offset = 0;
      if (-e "$coms_file") {
        open(COMS, "$coms_file");
          if (defined($line1 = <COMS>)
          &&  defined($line2 = <COMS>)) {
            $all_line = $line1.$line2;
            if ($all_line
            =~ /^\s*(\d+)\s+(\d+)\s+(\d+)\s*\n\s*(\d+)\s+(\d+)\s+(\d+)\s*$/) {
              $x_offset = int(($1 + $2) / 2.0);
              $y_offset = int(($4 + $5) / 2.0);

              my @lines = `cat $image_ppm_file`;
#&quit("Bad $image_ppm_file file", 15) if (!defined($lines[4])); # 4 header lines plus at least 1 pixel.
SAS::error('badPpmFile', "Bad $image_ppm_file file.") if (!defined($lines[4])); # 4 header lines plus at least 1 pixel.
              chomp($lines[0]);
#&quit("Bad $image_ppm_file file", 16) if ($lines[0] ne 'P3');
SAS::error('badPpmFile', "Bad $image_ppm_file file.") if ($lines[0] ne 'P3');
              chomp($lines[1]);
              if ($lines[1] =~ /^\s*(\d+)\s*$/) {
                $x_size = $1;
              } else {
#&quit("Bad $image_ppm_file file", 17) ;
SAS::error('badPpmFile', "Bad $image_ppm_file file.");
              }
              chomp($lines[2]);
              if ($lines[2] =~ /^\s*(\d+)\s*$/) {
                $y_size = $1;
              } else {
#&quit("Bad $image_ppm_file file", 18) ;
SAS::error('badPpmFile', "Bad $image_ppm_file file.");
              }

              $x_offset -= int($x_size / 2.0);
              $y_offset -= int($y_size / 2.0);
            }
          }
        close(COMS);
      }

#      if (! -e "$whole_ppm_file") {# || $clobbertemps) {
        if (!$testflag) {
#          &tell("Adding image to frame file.");
          print "Adding image to frame file.\n";
          if (-e "$whole_ppm_file") {unlink("$whole_ppm_file");}
          $status = &add_ppm($frame_ppm_file, $image_ppm_file, $x_offset
            , $y_offset, $whole_ppm_file);

          if ($status != 0) {
#&quit("Couldn't add $frame_ppm_file to $image_ppm_file: add_ppm status $status", 19);
SAS::error('badAddPpmStatus', "Couldn't add $frame_ppm_file to $image_ppm_file: add_ppm status $status.");
          }
        }
#      } else {
#        &warn("$whole_ppm_file already exists, not overwritten.");
#      }

      $temp_ppm_file = $whole_ppm_file;

    } else { # don't add the frame file to the colour image:
      $temp_ppm_file = $image_ppm_file;
    } # end if $add_to_frame

    $command = "pnmtopng $temp_ppm_file > $output_file";

#    if (&run($clobberprods, $output_file, $command, "pnmtopng output "
#    ."$output_file already exists. pnmtopng not run.")) {
#&quit("Couldn't run pnmtopng.", 20);
#    }
SAS::error('pnmtopngFailed', "Couldn't run pnmtopng.") if (&run("$command"));

#    if (&boolTranslate($params{'withthumbnails'})) {
    if ($withthumbnails) {
      my $thumbnail_file = $output_file.".small";

      $command = "pnmsmooth $temp_ppm_file | pnmscale 0.1 "
      ."| ppmquant 256 | pnmtopng > $thumbnail_file";

#      if (&run($clobberprods, $thumbnail_file, $command, "Thumbnail file "
#      ."$thumbnail_file already exists. Not overwritten.")) {
#&quit("Couldn't make thumbnail.", 21);
#      }
SAS::error('makeThumbnailFailed', "Couldn't make thumbnail.") if (&run("$command"));

      $command = "mv $thumbnail_file $thumbnail_dir/";

#      if (&run($clobberprods, "$thumbnail_dir/$thumbnail_file", $command
#      ,"Thumbnail file $thumbnail_dir/$thumbnail_file already exists. "
#      ."Not overwritten.")) {
#&quit("Couldn't mv thumbnail.", 22);
#      }
SAS::error('moveThumbnailFailed', "Couldn't mv thumbnail.") if (&run("$command"));

      if (-e "$thumblist_file") {
        open(LLIS, ">>$thumblist_file");
      } else {
        open(LLIS, ">$thumblist_file");
      }
      print LLIS "$output_file\t$thumbnail_dir/$thumbnail_file\n";
      close(LLIS);
    }
  } # end if ($params{'pgdev'} eq '/png').

exit 0;

}

  #---------------------------------------------------------------------
  sub getParams {
  #---------------------------------------------------------------------
  # This routine is shared with all chains. Should therefore be in a
  # separate module.

    my ($possible_key, $actual_key, $value, $no_match_found
    , $unmatched_pars_found);

    my %params = &getParamDefaults;

    # Look for '-v':
    foreach (@ARGV) {
      if ($_ eq '-v') {
&getVersionThenQuit();
      }
    }

    # Look for '-h(elp)':
    foreach (@ARGV) {
      if (/^-h(|elp)/) {
&printParamsThenQuit();
      }
    }

    $unmatched_pars_found = 0;
    foreach (@ARGV) {
      if ($_ =~ /^(\w+)(=+)/) {
        $actual_key = $1;
        $value = $';
        $no_match_found = 1;
        foreach $possible_key (keys(%params)) {
          if ($possible_key eq $actual_key) {
            $params{$possible_key} = $value;
            $no_match_found = 0;
        last;
          }
        }
        if ($no_match_found) {
          $unmatched_pars_found = 1;
          &warn("Unrecognised parameter: $actual_key");
        }
      }
    }
&quit("Unmatched parameters found.", -1) if ($unmatched_pars_found);

  return %params;
  }

  #---------------------------------------------------------------------
  sub getParamDefaults {
  #---------------------------------------------------------------------
  # Loading default parameter values:

    my %params = (
      ccfpath        => '',
      prodsdir       => '.',
      clobbertemps   => 'no',
      clobberprods   => 'no',
      writelog       => 'no',
      astest         => 'no',
      withthumbnails => 'no',
      thumbnaildir   => './thumbnails',

      instrument   => 'm1',
      idtype       => 'index',
      obsindex     => 0,
      expindex     => 0,
      obsid        => '',
      expid        => '',

      bandlist     => "2 3 4",
      smooth       => 'yes',

      maxsigma     => 20.0,
      desiredsnr   => 7.0,
      ngauss       => 30,

      rebinimage   => 'no',
      newnxbins    => 250,
      newnybins    => 250,
      weirdness    => -0.7,
      heat         => 0.0,
      heatspread   => 0.3,
      cutoff       => 0.05,
      gainstyle    => 'auto',
      gain         => 8.0,
      pgdev        => '/png',
      expandtomask => 'yes',
      plotfile     => 'temp.png',
      withframe    => 'no',
    );

  return %params;
  }

  #---------------------------------------------------------------------
  sub getVersionThenQuit {
  #---------------------------------------------------------------------
  # Adapted from &getVersion in emchain.

    my $ccom = '';
    print "\n" ;
    chomp(my $sasdir = `which $taskname`) ; ##### $ENV{'SAS_DIR'} better???
    my $ii = index($sasdir,"/bin/$taskname");
    if ($ii == -1) { print "Sorry, directory structure of $taskname $sasdir " . 
                     "could not be recognised.\n" ; }
    else {
      $sasdir = substr($sasdir,0,$ii) ;
      $ccom = `find $sasdir -name VERSION | grep $taskname` ;
      if ( length($ccom) == 0 ) { print "Sorry, version number of $taskname " .
                                  "could not be found in $sasdir \n" }
      else {
        chomp(my $version = `cat $ccom`) ;
        $ccom = $sasdir . "/RELEASE" ;
        my $release = "" ;
        if ( -e $ccom ) { chomp($release = `cat $ccom`) }
        print "$taskname $version [$release] \n" ;
      }
    }

    # Write the version of the constituent tasks
    print "\n" ;
    print "You are using the following task versions : \n" ;
    my $task = '';
    foreach $task ("asmooth", "colimplot") {
      $ccom = $task . " -v \n" ;
      print `$ccom` ;
    }
    print "\n" ;

exit 0;
  }

  #---------------------------------------------------------------------
  sub printParamsThenQuit {
  #---------------------------------------------------------------------

    my %params = &getParamDefaults;
    foreach (keys(%params)) {
      print "$_,\tdefault = $params{$_}\n";
    }

exit 0;
  }

  #---------------------------------------------------------------------
  sub boolTranslate {
  #---------------------------------------------------------------------
    my ($inStr) = @_;
    my $out;

    if ($inStr =~ /^\w+$/) {
      $inStr = lc($inStr);
      if ($inStr eq 'y' || $inStr eq 'yes' || $inStr eq 't'
      || $inStr eq 'true') {
        $out = 1;
      } elsif ($inStr eq 'n' || $inStr eq 'no' || $inStr eq 'f'
      || $inStr eq 'false') {
        $out = 0;
      } else {
&quit("Non-boolean variable $inStr treated as boolean.", -2);
      }
    } elsif ($inStr ne '0' && $inStr ne '1') {
&quit("Non-boolean variable $inStr treated as boolean.", -3);
    }

  return($out);
  }

  #---------------------------------------------------------------------
  sub makeHashTreeEpic {
  #---------------------------------------------------------------------
  # Construct a hash tree of revolution, observation, exposure, instrument,
  # ccd, in which each hash value is a name of the next hash down. The easiest
  # way to compose unambiguous hash names is to use the rev, obs etc numbers
  # themselves.

    no strict 'refs';

    my ($filename, $obs, $ins, $typ, $exp, $img);
    my ($prod_dir) = @_;

    my @filenames = `ls -1 $prod_dir`;

    my $total_matching_files = 0;
    foreach $filename (@filenames) {
      chomp($filename);
      if ($filename =~ /^P(\d{10})(\w\w)(S|U)(\d{3})IMAGE_(\d)000.FIT/i) {

        ++$total_matching_files;

        $obs = $1;
        $ins = $2;
        $typ = $3;
        $exp = $4;
        $img = $5;
        chomp($filename);

        # Observation list:
        $obs_list{$obs} = "$obs";

        # Instrument list for each observation:
        ${${$obs}{$ins}} = "$obs$ins";

        # Exposure list for each instrument:
        ${${"$obs$ins"}{"$typ$exp"}} = "$obs$ins$typ$exp";

        # No more hash levels below this, so it is convenient to store the
        # filename in the hash value instead:
        ${${"$obs$ins$typ$exp"}{"$img"}} = "$filename";
      }
    }

    if ($total_matching_files == 0) {
#&quit("No matching files in $prod_dir.", -4);
SAS::error('noProdFiles', "No matching files in $prod_dir.");
    }
  }

  #----------------------------------------------------------------------
  sub image_is_flat {
  #----------------------------------------------------------------------

    my ($junk, $stddev);

    my ($image) = @_;

    my $command = "fimgstat $image outfile=STDOUT "
      ."threshlo=INDEF threshup=INDEF | grep deviation";

    print "\ninvoke $command\n\n";

    my @chunks = `$command`;
SAS::error('badFimgstat', "Couldn't get sensible result from fimgstat to get stddev of $image.") if (!defined($chunks[0]));

    my $bad_fimgstat_call = 1; # default
    foreach(@chunks) {
      if (/deviation/) {
        $bad_fimgstat_call = 0;
        ($junk, $stddev) = split('=');
        chomp($stddev);
      }
#&quit("Couldn't get sensible result from fimgstat to get dev of $image.", -4.1)
SAS::error('badFimgstat', "Couldn't get sensible result from fimgstat to get stddev of $image.")
if ($bad_fimgstat_call);
    }

    if ($stddev <= 0) {
  return 1;
    } else {
  return 0;
    }
  }

  #----------------------------------------------------------------------
  sub image_is_zero {
  #----------------------------------------------------------------------

    my ($junk, $max);

    my ($image) = @_;

    my $command = "fimgstat $image outfile=STDOUT "
      ."threshlo=INDEF threshup=INDEF | grep 'The maximum'";

    print "\ninvoke $command\n\n";

    my @chunks = `$command`;
SAS::error('badFimgstat', "Couldn't get sensible result from fimgstat to get max of $image.") if (!defined($chunks[0]));

    my $bad_fimgstat_call = 1; # default
    foreach(@chunks) {
      if (/^The maximum of selected image/) {
        $bad_fimgstat_call = 0;
        ($junk, $max) = split('=');
        chomp($max);
      }
#&quit("Couldn't get sensible result from fimgstat to get max of $image.", -4.2)
SAS::error('badFimgstat', "Couldn't get sensible result from fimgstat to get max of $image.")
if ($bad_fimgstat_call);
    }

    if ($max <= 0) {
  return 1;
    } else {
  return 0;
    }
  }

  #----------------------------------------------------------------------
  sub add_ppm {
  #----------------------------------------------------------------------
  # Adds ppm files $a_file to $b_file, leaving the result in $c_file. $b_file
  # is assumed to be an ordinary ppm with 1 pixel per row, $a_file a byte-
  # -stored ppm. The result, $c_file, is a byte-stored ppm.

    my ($a_x_size, $a_y_size, $a_hue_resoln, $b_x_size, $b_y_size, $b_hue_resoln, $line);

#    my $x_offset = 0;
#    my $y_offset = 0;
    
    my $status = 0;

    my ($a_file, $b_file, $x_offset, $y_offset, $c_file) = @_;

    my @b_lines = `cat $b_file`;
  return -1 if (!defined($b_lines[4])); # 4 header lines plus at least 1 pixel.
    chomp($b_lines[0]);
  return -2 if ($b_lines[0] ne 'P3');
    chomp($b_lines[1]);
    if ($b_lines[1] =~ /^\s*(\d+)\s*$/) {
      $b_x_size = $1;
    } else {
  return -3;
    }
    chomp($b_lines[2]);
    if ($b_lines[2] =~ /^\s*(\d+)\s*$/) {
      $b_y_size = $1;
    } else {
  return -4;
    }
    chomp($b_lines[3]);
    if ($b_lines[3] =~ /^\s*(\d+)\s*$/) {
      $b_hue_resoln = $1;
    } else {
  return -5;
    }
  return -6 if (@b_lines != $b_x_size * $b_y_size + 4);

#    &tell("Loaded colour image into memory.");
    print "Loaded colour image into memory.\n";

    open(A, "$a_file");
  return -7 if (!defined($line = <A>));
    chomp($line);
  return -8 if ($line ne 'P6');
  return -9 if (!defined($line = <A>));
    chomp($line);
    if ($line =~ /^\s*(\d+)\s+(\d+)\s*$/) {
      $a_x_size = $1;
      $a_y_size = $2;
    } else {
  return -10;
    }
  return -13 if (!defined($line = <A>));
    chomp($line);
    if ($line =~ /^\s*(\d+)\s*$/) {
      $a_hue_resoln = $1;
  return -14 if ($a_hue_resoln != 255);
    } else {
  return -15;
    }

    open(C, ">$c_file");
    print C "P6\n";
    print C "$a_x_size $a_y_size\n";
    print C "$a_hue_resoln\n";

    foreach $yi (1 .. $a_y_size) {
      foreach $xi (1 .. $a_x_size) {
        ($status, $a_redval) = &read_byte(\*A);
return -16 if ($status < 0);
        ($status, $a_grnval) = &read_byte(\*A);
return -16 if ($status < 0);
        ($status, $a_bluval) = &read_byte(\*A);
return -16 if ($status < 0);

        if ($xi - $x_offset >= 1 && $xi - $x_offset <= $b_x_size
        && $yi - $y_offset >= 1 && $yi - $y_offset <= $b_y_size) { # add the
        # relevant pixel value from $b_file:
          $b_index = 3 + ($yi - $y_offset - 1) * $b_x_size + $xi - $x_offset;
          chomp($b_lines[$b_index]);
          if ($b_lines[$b_index] =~ /^\s*(\d+)\s+(\d+)\s+(\d+)\s*$/) {
            $b_redval = int(256 * ($1 / $b_hue_resoln));
            $b_grnval = int(256 * ($2 / $b_hue_resoln));
            $b_bluval = int(256 * ($3 / $b_hue_resoln));
          } else {
return -17;
          }

          $a_redval = $a_redval + $b_redval;
          if ($a_redval > 255) {$a_redval = 255}
          $a_grnval = $a_grnval + $b_grnval;
          if ($a_grnval > 255) {$a_grnval = 255}
          $a_bluval = $a_bluval + $b_bluval;
          if ($a_bluval > 255) {$a_bluval = 255}
        } else {
#print "                                    ";
        }

return -18 if (&write_byte(\*C, $a_redval, 0));
return -18 if (&write_byte(\*C, $a_grnval, 0));
return -18 if (&write_byte(\*C, $a_bluval, 0));
      }
    }
return -19 if (&write_byte(\*C, 0, 1));
    close(C);
    close(A);
  
  return $status;
  }

  #----------------------------------------------------------------------
  sub read_byte {
  #----------------------------------------------------------------------
  # $read_index and $last_index should both be initialised to 0 in the calling
  # routine, and not altered between calls to read_byte. $max_buf_len should
  # also be assigned a value.

    my ($buf, $byte_val);

    my ($filehandle) = @_;

    if (!defined($read_index) || (defined($read_index) && $read_index
    >= $last_index)) {
      if (defined($last_index = read $filehandle, $buf, $max_buf_len)) {
        @read_vector = unpack "C*", $buf;
        if (!defined($read_vector[0])) {
  return (-1, 0);
        }
        $read_index = 0;
      } else {
  return (-2, 0);
      }
    }

    $byte_val = $read_vector[$read_index];
    ++$read_index;

  return (0, $byte_val);
  }

  #----------------------------------------------------------------------
  sub write_byte {
  #----------------------------------------------------------------------
  # $write_index should be initialised 0 in the calling routine, and
  # not altered between calls to write_byte. After write_byte has been called
  # with the last byte to write, it should be called again with $end = 1
  # to actually write the last buffer to file.

    my ($filehandle, $byte_val, $end) = @_;

    if ($end || (defined($write_index) && $write_index >= $max_buf_len)) {
      $buf = pack "C*", @write_vector;
  return -1 if(!print $filehandle $buf);
      $write_index = 0;
      @write_vector = ();
    } elsif (!defined($write_index)) {
      $write_index = 0;
      @write_vector = ();
    }
    $write_vector[$write_index] = $byte_val;
    ++$write_index;

  return 0;
  }

#  #---------------------------------------------------------------------
#  sub run {
#  #---------------------------------------------------------------------
#
#    my ($clobber, $output, $command, $warning) = @_;
#
#    my $status = 0;
#    if (! -e "$output" || $clobber) {
#      &tell("invoke $command");
#      if (!$testflag) {
#        if (-e "$output") {unlink("$output");}
#        $status = system($command);
#      }
#    } else {
#      &warn($warning);
#    }
#
#  return $status;
#  }

  #---------------------------------------------------------------------
  sub run {
  #---------------------------------------------------------------------
  # $testflag should be defined globally.

    my ($command) = @_;
    my $status = 0;

    print "\ninvoke $command\n\n";
    if (!$testflag) {
      $status = system($command);
    }

  return $status;
  }


#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

sub tell {
  open(LOG, ">> $log_name") if ($write_log);
  foreach (@_) {
    print "$taskname:- $_\n\n";
    print LOG "$taskname:- $_\n\n" if ($write_log);
  }
  close(LOG) if ($write_log);
}

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

sub warn {
  open(LOG, ">> $log_name") if ($write_log);
  foreach (@_) {
    print "** $taskname: warning, $_\n\n";
    print LOG "** $taskname: warning, $_\n\n" if ($write_log);
  }
  close(LOG) if ($write_log);
}

  #----------------------------------------------------------------------
  sub quit {
  #----------------------------------------------------------------------
  # Expects $taskname, $log_name and $write_log to be defined, but doesn't
  # complain if they are not.

    my ($message, $status) = @_;

    my $whole_message = "** ";
    if (defined($taskname)) {
      $whole_message .= "$taskname: ";
    }
    $whole_message .= "ERROR! $message\n\n";
    print $whole_message;
    if (defined($log_name) && defined($write_log) && $write_log) {
      open(LOG, ">> $log_name");
      print LOG $whole_message;
      close(LOG);
    }

exit $status;
  }
