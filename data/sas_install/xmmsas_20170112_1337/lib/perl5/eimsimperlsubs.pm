  package eimsimperlsubs;

  # readFITSKeyword
  # getExposureProperty
  # setUpObsIdHash
  # readEcfs
  # dumpEcfs
  # getInstExpHash
  # checkProds
  # dumpProds
  # checkBandInstFilt
  # run
  # quit

  use SAS;

  use vars qw($testFlag);
  my $testFlag=0;

  #---------------------------------------------------------------------
  sub readFITSKeyword {
  #---------------------------------------------------------------------
  # $testFlag should be defined globally.

  # Slightly modified from 2xmm/scripts/ims_perlsubs_5.pm IMS 18 Jul 2006

    my ($rump, $next_quote);
    my ($file, $ext, $kwd_name, $command);
    if (@_ == 3) {
      ($file, $ext, $kwd_name) = @_;
&quit('undefArg1',"1st argument to readFITSKeyword is undefined.") if (!defined($file));
&quit('undefArg2',"2nd argument to readFITSKeyword is undefined.") if (!defined($ext));
&quit('undefArg3',"3rd argument to readFITSKeyword is undefined.") if (!defined($kwd_name));
      $command = "fkeyprint '$file"."[$ext]' $kwd_name";
    } elsif (@_ == 2) {
      ($file, $kwd_name) = @_;
&quit('undefArg1',"1st argument to readFITSKeyword is undefined.") if (!defined($file));
&quit('undefArg2',"2nd argument to readFITSKeyword is undefined.") if (!defined($kwd_name));
      $command = "fkeyprint $file"."+0 $kwd_name";
    } else {
&quit('badNumArgs',"Need 2 or 3 arguments to readFITSKeyword.");
    }
#print "command is $command\n\n";

&quit('fileNotFound',"Couldn't find file $file.") if (!$testFlag && !-e "$file");

    my $value = '';
#    print "invoke $command\n\n";
#    SAS::message($SAS::VerboseMsg, "invoke $command\n");
    SAS::message($SAS::AppMsg, $SAS::VerboseMsg, "invoke $command\n");

  return '999' if ($testFlag);

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

  #----------------------------------------------------------------------
  sub getExposureProperty {
  #----------------------------------------------------------------------

    my ($file, $kwd) = @_;
    my (@fields);

    my $command = "fkeyprint $file"."+0 $kwd | grep =";
    my @lines = `$command`;
    if (defined($lines[0])) {
      @fields = split('\'', $lines[0]);
      if (defined($fields[1]) && $fields[0] =~ /=/) {
  return $fields[1];
      } else {
  return 0;
      }
    } else {
  return 0;
    }
  }

  #---------------------------------------------------------------------
  sub setUpObsIdHash {
  #---------------------------------------------------------------------

    my ($prod_subdir, @obsid_roots) = @_;
    my ($obsid);

    my %obs_ids = ();
    foreach my $obsid_root (@obsid_roots) {
      my $prod_dir  = "$obsid_root/$prod_subdir";
SAS::error('noProductSubdirectory', "Directory $prod_dir not found.")
      if (!-d "$prod_dir");

      my @prod_files = `ls -1 $prod_dir`;

SAS::error('noProducts', "No product files in $prod_dir.")
      if (@prod_files <= 0);

      my $already_found_obsid = 0;
      foreach my $file (@prod_files) {
        chomp($file);

        if ($file =~ /^P(\d{10})/) {
          if ($already_found_obsid) {
            if ($1 != $obsid) {
SAS::error('tooManyPathsThisObsid', "Only 1 --obsidroots entry "
."allowed per obsid.");
            }
          } else {
            $obsid = $1;
            $already_found_obsid = 1;
          }

        } # end if $file =~ /^P(\d{10})/
      } # end foreach $file (@prod_files)

SAS::error('noProducts', "No product files in $prod_dir.")
      if (!$already_found_obsid);

      $obs_ids{$obsid_root} = "$obsid"; # quotes to force it to be a string
    } # end foreach $obsid_root (@obsid_roots)

  return %obs_ids;
  }

  #---------------------------------------------------------------------
  sub readEcfs {
  #---------------------------------------------------------------------

    my ($srcSpecSetName, $temp_ascii, $tf) = @_;
$testFlag=$tf;
#print "tf=$testFlag\n";

SAS::error('templateSetNotFound', "Couldn't find $srcSpecSetName.")
    if (!-e $srcSpecSetName);

    my $energy_unit;
    if ($testFlag){
      $energy_unit = 'eV';
    } else {
      $energy_unit
        = &readFITSKeyword($srcSpecSetName, 'FLUX_SCALES', 'EUNIT');
      $energy_unit =~ s/\s*$//;
    }

    my $conversion_to_eV = 1; # default
    if (!$testFlag){
      if ($energy_unit eq 'keV'){
        $conversion_to_eV = 1000.0;
      } elsif($energy_unit ne 'eV'){
SAS::error('badEUnit', "The energy unit $energy_unit is unrecognized.")
      }
    }

    if (!$testFlag && -e $temp_ascii) {unlink($temp_ascii);}

    my $command = "fdump $srcSpecSetName'[FLUX_SCALES]' outfile=$temp_ascii "
      ."columns=- rows=- "
      ."pagewidth=250 prhead=no showcol=yes showrow=no showunit=no";

SAS::error('readEcfsFailed', "Couldn't read ECFs from $srcSpecSetName"."[FLUX_SCALES].")
    if (&run("$command"));

SAS::error('fdumpOutputNotFound', "Couldn't find $temp_ascii.")
    if (!$testFlag && !-e $temp_ascii);

    my @ecf_info = ();
    if ($testFlag) { # store some meaningless values in @ecf_info:
      @ecf_info = (
        {'bandid'   => '1',
         'flux'     => 999,
         'edges'    => [({'lo'=>200,  'hi'=>500})],
         'instrums' => {
           'PN' => {
             'OPEN'   => {'ECF'=>999, 'BG'=>999},
             'THIN'   => {'ECF'=>999, 'BG'=>999},
             'MEDIUM' => {'ECF'=>999, 'BG'=>999},
             'THICK'  => {'ECF'=>999, 'BG'=>999}
                   },
           'M1' => {
             'OPEN'   => {'ECF'=>999, 'BG'=>999},
             'THIN'   => {'ECF'=>999, 'BG'=>999},
             'MEDIUM' => {'ECF'=>999, 'BG'=>999},
             'THICK'  => {'ECF'=>999, 'BG'=>999}
           },
           'M2' => {
             'OPEN'   => {'ECF'=>999, 'BG'=>999},
             'THIN'   => {'ECF'=>999, 'BG'=>999},
             'MEDIUM' => {'ECF'=>999, 'BG'=>999},
             'THICK'  => {'ECF'=>999, 'BG'=>999}
           }}},
        {'bandid'   => '2',
         'flux'     => 999,
         'edges'    => [({'lo'=>500,  'hi'=>1000})],
         'instrums' => {
           'PN' => {
             'OPEN'   => {'ECF'=>999, 'BG'=>999},
             'THIN'   => {'ECF'=>999, 'BG'=>999},
             'MEDIUM' => {'ECF'=>999, 'BG'=>999},
             'THICK'  => {'ECF'=>999, 'BG'=>999}
           },
           'M1' => {
             'OPEN'   => {'ECF'=>999, 'BG'=>999},
             'THIN'   => {'ECF'=>999, 'BG'=>999},
             'MEDIUM' => {'ECF'=>999, 'BG'=>999},
             'THICK'  => {'ECF'=>999, 'BG'=>999}
           },
           'M2' => {
             'OPEN'   => {'ECF'=>999, 'BG'=>999},
             'THIN'   => {'ECF'=>999, 'BG'=>999},
             'MEDIUM' => {'ECF'=>999, 'BG'=>999},
             'THICK'  => {'ECF'=>999, 'BG'=>999}
           }}},
        {'bandid'   => '3',
         'flux'     => 999,
         'edges'    => [({'lo'=>1000,  'hi'=>2000})],
         'instrums' => {
           'PN' => {
             'OPEN'   => {'ECF'=>999, 'BG'=>999},
             'THIN'   => {'ECF'=>999, 'BG'=>999},
             'MEDIUM' => {'ECF'=>999, 'BG'=>999},
             'THICK'  => {'ECF'=>999, 'BG'=>999}
           },
           'M1' => {
             'OPEN'   => {'ECF'=>999, 'BG'=>999},
             'THIN'   => {'ECF'=>999, 'BG'=>999},
             'MEDIUM' => {'ECF'=>999, 'BG'=>999},
             'THICK'  => {'ECF'=>999, 'BG'=>999}
           },
           'M2' => {
             'OPEN'   => {'ECF'=>999, 'BG'=>999},
             'THIN'   => {'ECF'=>999, 'BG'=>999},
             'MEDIUM' => {'ECF'=>999, 'BG'=>999},
             'THICK'  => {'ECF'=>999, 'BG'=>999}
           }}},
        {'bandid'   => '4',
         'flux'     => 999,
         'edges'    => [({'lo'=>2000,  'hi'=>4500})],
         'instrums' => {
           'PN' => {
             'OPEN'   => {'ECF'=>999, 'BG'=>999},
             'THIN'   => {'ECF'=>999, 'BG'=>999},
             'MEDIUM' => {'ECF'=>999, 'BG'=>999},
             'THICK'  => {'ECF'=>999, 'BG'=>999}
           },
           'M1' => {
             'OPEN'   => {'ECF'=>999, 'BG'=>999},
             'THIN'   => {'ECF'=>999, 'BG'=>999},
             'MEDIUM' => {'ECF'=>999, 'BG'=>999},
             'THICK'  => {'ECF'=>999, 'BG'=>999}
           },
           'M2' => {
             'OPEN'   => {'ECF'=>999, 'BG'=>999},
             'THIN'   => {'ECF'=>999, 'BG'=>999},
             'MEDIUM' => {'ECF'=>999, 'BG'=>999},
             'THICK'  => {'ECF'=>999, 'BG'=>999}
           }}},
        {'bandid'   => '5',
         'flux'     => 999,
         'edges'    => [({'lo'=>4500,  'hi'=>12000})],
         'instrums' => {
           'PN' => {
             'OPEN'   => {'ECF'=>999, 'BG'=>999},
             'THIN'   => {'ECF'=>999, 'BG'=>999},
             'MEDIUM' => {'ECF'=>999, 'BG'=>999},
             'THICK'  => {'ECF'=>999, 'BG'=>999}
           },
           'M1' => {
             'OPEN'   => {'ECF'=>999, 'BG'=>999},
             'THIN'   => {'ECF'=>999, 'BG'=>999},
             'MEDIUM' => {'ECF'=>999, 'BG'=>999},
             'THICK'  => {'ECF'=>999, 'BG'=>999}
           },
           'M2' => {
             'OPEN'   => {'ECF'=>999, 'BG'=>999},
             'THIN'   => {'ECF'=>999, 'BG'=>999},
             'MEDIUM' => {'ECF'=>999, 'BG'=>999},
             'THICK'  => {'ECF'=>999, 'BG'=>999}
           }}},
        {'bandid'   => '9',
         'flux'     => 999,
         'edges'    => [({'lo'=>500,  'hi'=>4500})],
         'instrums' => {
           'PN' => {
             'OPEN'   => {'ECF'=>999, 'BG'=>999},
             'THIN'   => {'ECF'=>999, 'BG'=>999},
             'MEDIUM' => {'ECF'=>999, 'BG'=>999},
             'THICK'  => {'ECF'=>999, 'BG'=>999}
           },
           'M1' => {
             'OPEN'   => {'ECF'=>999, 'BG'=>999},
             'THIN'   => {'ECF'=>999, 'BG'=>999},
             'MEDIUM' => {'ECF'=>999, 'BG'=>999},
             'THICK'  => {'ECF'=>999, 'BG'=>999}
           },
           'M2' => {
             'OPEN'   => {'ECF'=>999, 'BG'=>999},
             'THIN'   => {'ECF'=>999, 'BG'=>999},
             'MEDIUM' => {'ECF'=>999, 'BG'=>999},
             'THICK'  => {'ECF'=>999, 'BG'=>999}
           }}}
      );

    } else { # !$testFlag
      # The job of extracting the column values from the ascii file is not easy. Partly this is because the fdump page size limit of 256 is too small to allow all the column values to be printed in 1 set of rows: it usually split into 2 or more 'chunks'. Each chunk must begin with a line which lists all the columns in that chunk, and must be followed by N lines of numerical values for those columns, where N is the total number or rows in the table (which obviously must be the same for each chunk). The first job is to find out how many chunks there are.
      #
      my $num_chunks = 0;
      my $num_rows = 0;
      open(ECF, "$temp_ascii");
      while(my $line=<ECF>){
        chomp $line;
      next if ($line=~/^\s*#/ || $line=~/^\s*$/); # pure comment or blank lines

#        if (###############first non-space is a letter){
        if ($line =~ /^\s*[A-Z]/){
          ++$num_chunks;
        } elsif ($num_chunks<1) {
          ++$num_rows;
        }
      }
      close ECF;

#print "num_chunks=$num_chunks\n";

      # Now we read in the column names into one list, and the values into N lists, 1 per row:
      #
      # Set up a list of N empty lists:
      #
      my @rows = ();
      foreach my $i (0 .. $num_rows-1){
        push @rows, [()];
      }

      my @col_names = ();
#      my @col_values = ();
      my $row_num = 0;
      my $chunk_num = 0;
      open(ECF, "$temp_ascii");
      while(my $line=<ECF>){
        chomp $line;
      next if ($line=~/^\s*#/ || $line=~/^\s*$/); # pure comment or blank lines
        $line =~ s/^\s+//;

#        if (###############first non-space is a letter){
        if ($line =~ /^\s*[A-Z]/){
#print "line starts with char: $line\n";
          push @col_names, split(/\s+/, $line);
          $row_num = 0;
          ++$chunk_num;
        } else {
#print "line starts with num: $line\n";
          my @col_values = ();
          if ($chunk_num > 1) {@col_values = @{$rows[$row_num]};}
          push @col_values, split(/\s+/, $line);
          $rows[$row_num] = \@col_values;
          ++$row_num;
        }
      }
      close ECF;

      # Check for presence of vital column names:
      #
      my @vital_cols = qw(ID_BAND E_LO E_HI FLUX);
      my $num_vital_cols = @vital_cols;
      my $num_cols = @col_names;
SAS::error('tooFewColumnsInSrcSpecFile', "Only found $num_cols column names in $srcSpecSetName"."[FLUX_SCALES]. There should be at least ".2+$num_vital_cols.".") # ie, the vital columns, plus at least 1 ECF and 1 BG column.
      if ($num_cols < 2+$num_vital_cols);

      foreach my $vital_col (@vital_cols){
        my $vital_col_not_found = 1; # default
        foreach my $col_name (@col_names){
          if ($col_name eq $vital_col) {
            $vital_col_not_found = 0;
        last;
          }
        }
SAS::error('vitalColumnNotFound', "Essential column name $vital_col was not found in $srcSpecSetName"."[FLUX_SCALES].")
        if ($vital_col_not_found);
      }

      # Now load all the values.
      #
      my ($bandid, $elo, $ehi, $flux);
      foreach my $row (@rows){
        my @col_values = @{$row};
        my %filter_lists = ();
        foreach my $i (0 .. $#col_names){
          my $col_name = $col_names[$i];
#print "row $row, col $i: col name = $col_name\n";
          if ($col_name =~ /^(ECF|BG)_(\w\w)_(\w+)/){
            my $field = $1;
            my $inst = $2;
            my $filt = $3;
#print "  Col name starts with ECF or BG. Field=$field, inst=$inst, filt=$filt, value=$col_values[$i]\n";
            $filter_lists{$inst}{$filt}{$field} = $col_values[$i];
          } elsif ($col_name eq 'ID_BAND') {
            $bandid = $col_values[$i];
          } elsif ($col_name eq 'E_LO') {
            $elo = $col_values[$i];
          } elsif ($col_name eq 'E_HI') {
            $ehi = $col_values[$i];
          } elsif ($col_name eq 'FLUX') {
            $flux = $col_values[$i];
          }
        } # next col

        my @band_ranges = ();
        push @band_ranges, {'lo'=>$elo*$conversion_to_eV, 'hi'=>$ehi*$conversion_to_eV};

        push @ecf_info, {'bandid'   => "$bandid", # quotes to force it to be a string.
                         'flux'     => $flux,
                         'edges'    => [@band_ranges],
                         'instrums' => {%filter_lists}};
      } # next row
    } # end if ($testFlag)

    my $sim_fluxDensityToFlux;
    if ($testFlag){
      $sim_fluxDensityToFlux = 999;
    } else {
      $sim_fluxDensityToFlux
      = &readFITSKeyword($srcSpecSetName, 'FLUX_SCALES', 'FLUX');
    }

#&dumpEcfs(\@ecf_info);
#die "test - stopping here";

#  return (@ecf_info, $sim_fluxDensityToFlux);
#  return [(@ecf_info, $sim_fluxDensityToFlux)];
  return (\@ecf_info, $sim_fluxDensityToFlux);

  } # readEcfs

  #---------------------------------------------------------------------
  sub readEcfs_20070828 {
  #---------------------------------------------------------------------

    my ($srcSpecSetName, $temp_ascii, $tf) = @_;
$testFlag=$tf;
#print "tf=$testFlag\n";

SAS::error('templateSetNotFound', "Couldn't find $srcSpecSetName.")
    if (!-e $srcSpecSetName);

    my $energy_unit;
    if ($testFlag){
      $energy_unit = 'eV';
    } else {
      $energy_unit
        = &readFITSKeyword($srcSpecSetName, 'FLUX_SCALES', 'EUNIT');
      $energy_unit =~ s/\s*$//;
    }

    my $conversion_to_eV = 1; # default
    if (!$testFlag){
      if ($energy_unit eq 'keV'){
        $conversion_to_eV = 1000.0;
      } elsif($energy_unit ne 'eV'){
SAS::error('badEUnit', "The energy unit $energy_unit is unrecognized.")
      }
    }

    if (!$testFlag && -e $temp_ascii) {unlink($temp_ascii);}

    my $command = "fdump $srcSpecSetName'[FLUX_SCALES]' outfile=$temp_ascii "
      ."columns=- rows=- "
      ."pagewidth=250 prhead=no showcol=no showrow=no showunit=no";

SAS::error('readEcfsFailed', "Couldn't read ECFs from $srcSpecSetName.")
    if (&run("$command"));

SAS::error('fdumpOutputNotFound', "Couldn't find $temp_ascii.")
    if (!$testFlag && !-e $temp_ascii);

    my @ecf_info = ();
    if ($testFlag) { # store some meaningless values in @ecf_info:
      @ecf_info = (
        {'bandid'   => '1',
         'flux'     => 999,
         'edges'    => [({'lo'=>200,  'hi'=>500})],
         'instrums' => {
           'PN' => {
             'OPEN'   => 999,
             'THIN'   => 999,
             'MEDIUM' => 999,
             'THICK'  => 999
                   },
           'M1' => {
             'OPEN'   => 999,
             'THIN'   => 999,
             'MEDIUM' => 999,
             'THICK'  => 999
           },
           'M2' => {
             'OPEN'   => 999,
             'THIN'   => 999,
             'MEDIUM' => 999,
             'THICK'  => 999
           }}},
        {'bandid'   => '2',
         'flux'     => 999,
         'edges'    => [({'lo'=>500,  'hi'=>1000})],
         'instrums' => {
           'PN' => {
             'OPEN'   => 999,
             'THIN'   => 999,
             'MEDIUM' => 999,
             'THICK'  => 999
           },
           'M1' => {
             'OPEN'   => 999,
             'THIN'   => 999,
             'MEDIUM' => 999,
             'THICK'  => 999
           },
           'M2' => {
             'OPEN'   => 999,
             'THIN'   => 999,
             'MEDIUM' => 999,
             'THICK'  => 999
           }}},
        {'bandid'   => '3',
         'flux'     => 999,
         'edges'    => [({'lo'=>1000,  'hi'=>2000})],
         'instrums' => {
           'PN' => {
             'OPEN'   => 999,
             'THIN'   => 999,
             'MEDIUM' => 999,
             'THICK'  => 999
           },
           'M1' => {
             'OPEN'   => 999,
             'THIN'   => 999,
             'MEDIUM' => 999,
             'THICK'  => 999
           },
           'M2' => {
             'OPEN'   => 999,
             'THIN'   => 999,
             'MEDIUM' => 999,
             'THICK'  => 999
           }}},
        {'bandid'   => '4',
         'flux'     => 999,
         'edges'    => [({'lo'=>2000,  'hi'=>4500})],
         'instrums' => {
           'PN' => {
             'OPEN'   => 999,
             'THIN'   => 999,
             'MEDIUM' => 999,
             'THICK'  => 999
           },
           'M1' => {
             'OPEN'   => 999,
             'THIN'   => 999,
             'MEDIUM' => 999,
             'THICK'  => 999
           },
           'M2' => {
             'OPEN'   => 999,
             'THIN'   => 999,
             'MEDIUM' => 999,
             'THICK'  => 999
           }}},
        {'bandid'   => '5',
         'flux'     => 999,
         'edges'    => [({'lo'=>4500,  'hi'=>12000})],
         'instrums' => {
           'PN' => {
             'OPEN'   => 999,
             'THIN'   => 999,
             'MEDIUM' => 999,
             'THICK'  => 999
           },
           'M1' => {
             'OPEN'   => 999,
             'THIN'   => 999,
             'MEDIUM' => 999,
             'THICK'  => 999
           },
           'M2' => {
             'OPEN'   => 999,
             'THIN'   => 999,
             'MEDIUM' => 999,
             'THICK'  => 999
           }}},
        {'bandid'   => '9',
         'flux'     => 999,
         'edges'    => [({'lo'=>500,  'hi'=>4500})],
         'instrums' => {
           'PN' => {
             'OPEN'   => 999,
             'THIN'   => 999,
             'MEDIUM' => 999,
             'THICK'  => 999
           },
           'M1' => {
             'OPEN'   => 999,
             'THIN'   => 999,
             'MEDIUM' => 999,
             'THICK'  => 999
           },
           'M2' => {
             'OPEN'   => 999,
             'THIN'   => 999,
             'MEDIUM' => 999,
             'THICK'  => 999
           }}}
      );

    } else {
      open(ECF, "$temp_ascii");
      while(my $line=<ECF>){
        chomp $line;
        next if ($line=~/^\s*#/ || $line=~/^\s*$/);
        $line =~ s/^\s+//;
        my ($bandid, $elo, $ehi, $flux
          , $ecf_pn_open, $ecf_pn_thin, $ecf_pn_medium, $ecf_pn_thick
          , $ecf_m1_open, $ecf_m1_thin, $ecf_m1_medium, $ecf_m1_thick
          , $ecf_m2_open, $ecf_m2_thin, $ecf_m2_medium, $ecf_m2_thick) = split('\s+', $line);

        my @band_ranges = ();
        push @band_ranges, {'lo'=>$elo*$conversion_to_eV, 'hi'=>$ehi*$conversion_to_eV};

        my %filter_lists;
        $filter_lists{"PN"} = {
          'OPEN'  =>$ecf_pn_open,
          'THIN'  =>$ecf_pn_thin,
          'MEDIUM'=>$ecf_pn_medium,
          'THICK' =>$ecf_pn_thick
        };
        $filter_lists{"M1"} = {
          'OPEN'  =>$ecf_m1_open,
          'THIN'  =>$ecf_m1_thin,
          'MEDIUM'=>$ecf_m1_medium,
          'THICK' =>$ecf_m1_thick
        };
        $filter_lists{"M2"} = {
          'OPEN'  =>$ecf_m2_open,
          'THIN'  =>$ecf_m2_thin,
          'MEDIUM'=>$ecf_m2_medium,
          'THICK' =>$ecf_m2_thick
        };

#foreach my $inst (keys(%filter_lists)){
#  print "$inst".": ";
#  foreach my $filter (qw(OPEN THIN MEDIUM THICK)){
#    my $val = $filter_lists{$inst}{$filter};
#    print "$val ";
#  }
#  print "\n";
#}

        push @ecf_info, {'bandid'   => "$bandid", # quotes to force it to be a string.
                         'flux'     => $flux,
                         'edges'    => [@band_ranges],
                         'instrums' => {%filter_lists}};
      }
      close ECF;
    }

    my $sim_fluxDensityToFlux;
    if ($testFlag){
      $sim_fluxDensityToFlux = 999;
    } else {
      $sim_fluxDensityToFlux
      = &readFITSKeyword($srcSpecSetName, 'FLUX_SCALES', 'FLUX');
    }

#  return (@ecf_info, $sim_fluxDensityToFlux);
#  return [(@ecf_info, $sim_fluxDensityToFlux)];
  return (\@ecf_info, $sim_fluxDensityToFlux);

  } # readEcfs_20070828

  #---------------------------------------------------------------------
  sub dumpEcfs {
  #---------------------------------------------------------------------
    my ($ecf_ref) = @_;
    my @ecf_info = @{$ecf_ref};

    foreach my $i (0 .. $#ecf_info){
      my $band = $ecf_info[$i]{'bandid'};
      my $flux = $ecf_info[$i]{'flux'};
      my @band_ranges = @{$ecf_info[$i]{'edges'}};
      my $idbandlo = $band_ranges[0            ]{'lo'};
      my $idbandhi = $band_ranges[$#band_ranges]{'hi'};
      print "Band $band".": from $idbandlo to $idbandhi keV.\n";

      my %filter_lists = %{$ecf_info[$i]{'instrums'}};
      my @used_insts_uc = keys(%filter_lists);
      foreach my $inst (@used_insts_uc){
        print "  Inst $inst\n";
        my @filters = keys(%{$filter_lists{$inst}});
        foreach my $filter (@filters){
          print "    Filter $filter\n";
          my @fields = keys(%{$filter_lists{$inst}{$filter}});
          foreach my $field (@fields){
            my $val = $filter_lists{$inst}{$filter}{$field};
            print "      $field $val\n";
          }
        }
#        print "\n";
      }
    }
  } # dumpEcfs

  #---------------------------------------------------------------------
  sub dumpEcfs_20070828 {
  #---------------------------------------------------------------------
    my ($ecf_ref) = @_;
    my @ecf_info = @{$ecf_ref};

    foreach my $i (0 .. $#ecf_info){
      my $band = $ecf_info[$i]{'bandid'};
      my $flux = $ecf_info[$i]{'flux'};
      my @band_ranges = @{$ecf_info[$i]{'edges'}};
      my $idbandlo = $band_ranges[0            ]{'lo'};
      my $idbandhi = $band_ranges[$#band_ranges]{'hi'};
      print "Band $band".": from $idbandlo to $idbandhi keV.\n";

      my %filter_lists = %{$ecf_info[$i]{'instrums'}};
      my @used_insts_uc = keys(%filter_lists);
      foreach my $inst (@used_insts_uc){
        my @filters = keys(%{$filter_lists{$inst}});
        print "   $inst".": ";
        foreach my $filter (@filters){
          my $val = $filter_lists{$inst}{$filter};
          print "$val ";
        }
        print "\n";
      }
    }
  } # dumpEcfs_20070828

  #---------------------------------------------------------------------
  sub getInstExpHash {
  #---------------------------------------------------------------------

    my ($obs_id_root, $prod_subdir, $obs_id, $insts_uc_ref) = @_;
    my @insts_uc = @{$insts_uc_ref};

    my %instExpHash = ();
    my $prod_dir  = "$obs_id_root/$prod_subdir";
    foreach my $inst_uc (@insts_uc) {
      my %inst_hash = ();
      my @files = `ls -1 $prod_dir/P$obs_id$inst_uc*`;
      foreach my $file (@files) {
        my @chunks = split('\/', $file);
        if ($chunks[$#chunks] =~ /^P${obs_id}${inst_uc}((S|U)\d{3})/) {
          $inst_hash{"$1"} = 1;
        }
      }
      $instExpHash{$inst_uc} = \%inst_hash;
    }

  return \%instExpHash;
  }

  #---------------------------------------------------------------------
  sub checkProds {
  #---------------------------------------------------------------------
  # This peforms the following functions:
  #	(i) Checks that there is only 1 obsid per product subdirectory.
  #	(ii) Checks that there is a CALIND and a ATTTSR file.
  #	(iii) Checks that there is at least 1 epic event list.
  #	(iv) For each epic event list, counts the bands as specified by
  # exposure maps. These lists of bands have to obey the following criteria:
  #		(a) All obs/insts/exps must have the same number of bands.
  #		(b) There must be at least 1 band.
  #
  # Returned is a hash which records the 10-digit obsid string, plus the
  # epic instruments and exposures present in each observation; also
  # returned is a list of bands compiled from the incidence of exposure maps.
  #---------------------------------------------------------------------

    my ($prod_subdir, @obsid_roots) = @_;

    my $obsid;
    my %obs_ids = ();
    my %bandhash = ();
    my %filters = ();
    my $is_first_obsinstexp = 1;
    foreach my $obsid_root (@obsid_roots) {
      my $prod_dir  = "$obsid_root/$prod_subdir";
SAS::error('noProductSubdirectory', "Directory $prod_dir not found.")
      if (!-d "$prod_dir");

      my @prod_files = `ls -1 $prod_dir`;

SAS::error('noProducts', "No product files in $prod_dir.")
      if (@prod_files <= 0);

      my $already_found_obsid = 0;
      foreach my $file (@prod_files) {
        chomp($file);

        if ($file =~ /^P(\d{10})/) {
          if ($already_found_obsid) {
            if ($1 != $obsid) {
SAS::error('tooManyPathsThisObsid', "Only 1 --obsidroots entry "
."allowed per obsid.");
            }
          } else {
            $obsid = $1;
            $already_found_obsid = 1;
          }

        } # end if $file =~ /^P(\d{10})/
      } # end foreach $file (@prod_files)

SAS::error('noProducts', "No product files in $prod_dir.")
      if (!$already_found_obsid);

      # Now start checking the file types:
      #
      my $calind_found = 0;
      my $atttsr_found = 0;
      my %insts_hash = ();
      foreach my $file (@prod_files) {
        chomp($file);
        my $evlist = '';
        if      ($file =~ /^P\d{10}OBX000CALIND/) {
          $calind_found = 1;
        } elsif ($file =~ /^P\d{10}OBX000ATTTSR/) {
          $atttsr_found = 1;
        } elsif ($file =~ /^P\d{10}(PN)((S|U)\d{3})PIEVLI/) {
          $evlist = $file;
        } elsif ($file =~ /^P\d{10}(M1)((S|U)\d{3})MIEVLI/) {
          $evlist = $file;
        } elsif ($file =~ /^P\d{10}(M2)((S|U)\d{3})MIEVLI/) {
          $evlist = $file;
        }
        my $inst_uc = $1;
        my $expid = $2;

        if ($evlist){
          my $filter=&getExposureProperty("$prod_dir/$evlist", 'FILTER');

          unless(uc($filter) =~ /^(THIN|MEDIUM|THICK|OPEN)/ ){
SAS::error('badFilter', "Don't recognize filter $filter.");
          }
          $filters{$obsid}{"$inst_uc$expid"} = $1;
          $insts_hash{$inst_uc} = 'dummy';
        }
      }

SAS::error('noCalind', "No CALIND file in $prod_dir.")
      if (!$calind_found);
SAS::error('noAtttsr', "No ATTTSR file in $prod_dir.")
      if (!$atttsr_found);
SAS::error('noInstruments', "No epic event lists in $prod_dir.")
      if (!(defined($insts_hash{'PN'}) || defined($insts_hash{'M1'}) || defined($insts_hash{'M2'})));

#      my @insts_uc = keys(%insts_hash);
#      foreach my $inst_uc (@insts_uc){
#        my @expids = keys(%{$insts_hash{$inst_uc}});
#        foreach my $expid (@expids){
      my @instexpids = keys(%{$filters{$obsid}});
      foreach my $instexpid (@instexpids){
          if ($is_first_obsinstexp) {
            foreach my $file (@prod_files) {
              chomp($file);
#              if ($file =~ /^P\d{10}${inst_uc}${expid}EXPMAP(\w)/) {
              if ($file =~ /^P\d{10}${instexpid}EXPMAP(\w)/) {
                $bandhash{$1} = 'dummy';
              }
            }
            $is_first_obsinstexp = 0;
#SAS::error('noBands', "No bands found for instexpid $inst_uc$expid in directory $prod_dir.")
SAS::error('noBands', "No bands found for instexpid $instexpid in directory $prod_dir.")
            if (!keys(%bandhash));

          } else { # !$is_first_obsinstexp
            my %temp_bandhash = ();
            foreach my $file (@prod_files) {
              chomp($file);
#              if ($file =~ /^P\d{10}${inst_uc}${expid}EXPMAP(\w)/) {
#SAS::error('tooManyBands', "Too many bands for instexpid $inst_uc$expid in directory $prod_dir.")
              if ($file =~ /^P\d{10}${instexpid}EXPMAP(\w)/) {
SAS::error('tooManyBands', "Too many bands for instexpid $instexpid in directory $prod_dir.")
                if (!defined($bandhash{$1}));

                $temp_bandhash{$1} = 'dummy';
              }
            }

            foreach my $band (keys(%bandhash)){
#SAS::error('tooFewBands', "Too few bands for instexpid $inst_uc$expid in directory $prod_dir.")
SAS::error('tooFewBands', "Too few bands for instexpid $instexpid in directory $prod_dir.")
                if (!defined($temp_bandhash{$band}));
            }
          }
#        }
      }

      $obs_ids{$obsid_root} = "$obsid"; # quotes to force it to be a string.
    } # end foreach $obsid_root (@obsid_roots)

    my @used_bands = sort(keys(%bandhash));

  return \%obs_ids, \@used_bands, \%filters;
  } # checkProds

  #---------------------------------------------------------------------
  sub checkProds_old {
  #---------------------------------------------------------------------
  # This peforms the following functions:
  #	(i) Checks that there is only 1 obsid per product subdirectory.
  #	(ii) Checks that there is a CALIND and a ATTTSR file.
  #	(iii) Checks that there is at least 1 epic event list.
  #	(iv) For each epic event list, counts the bands as specified by
  # exposure maps. These lists of bands have to obey the following criteria:
  #		(a) All obs/insts/exps must have the same number of bands.
  #		(b) There must be at least 1 band.
  #
  # Returned is a hash which records the 10-digit obsid string, plus the
  # epic instruments and exposures present in each observation; also
  # returned is a list of bands compiled from the incidence of exposure maps.
  #---------------------------------------------------------------------

    my ($prod_subdir, @obsid_roots) = @_;

    my $obsid;
    my %obs_ids = ();
    my %bandhash = ();
    my $is_first_obsinstexp = 1;
    foreach my $obsid_root (@obsid_roots) {
      my $prod_dir  = "$obsid_root/$prod_subdir";
SAS::error('noProductSubdirectory', "Directory $prod_dir not found.")
      if (!-d "$prod_dir");

      my @prod_files = `ls -1 $prod_dir`;

SAS::error('noProducts', "No product files in $prod_dir.")
      if (@prod_files <= 0);

      my $already_found_obsid = 0;
      foreach my $file (@prod_files) {
        chomp($file);

        if ($file =~ /^P(\d{10})/) {
          if ($already_found_obsid) {
            if ($1 != $obsid) {
SAS::error('tooManyPathsThisObsid', "Only 1 --obsidroots entry "
."allowed per obsid.");
            }
          } else {
            $obsid = $1;
            $already_found_obsid = 1;
          }

        } # end if $file =~ /^P(\d{10})/
      } # end foreach $file (@prod_files)

SAS::error('noProducts', "No product files in $prod_dir.")
      if (!$already_found_obsid);

      # Now start checking the file types:
      #
      my $calind_found = 0;
      my $atttsr_found = 0;
      my %insts_hash = ();
      foreach my $file (@prod_files) {
        chomp($file);
        my $evlist = '';
        if      ($file =~ /^P\d{10}OBX000CALIND/) {
          $calind_found = 1;
        } elsif ($file =~ /^P\d{10}OBX000ATTTSR/) {
          $atttsr_found = 1;
        } elsif ($file =~ /^P\d{10}(PN)((S|U)\d{3})PIEVLI/) {
#          $insts_expids{'PN'}{$1} = 'dummy';
          $evlist = $file;
        } elsif ($file =~ /^P\d{10}(M1)((S|U)\d{3})MIEVLI/) {
#          $insts_expids{'M1'}{$1} = 'dummy';
          $evlist = $file;
        } elsif ($file =~ /^P\d{10}(M2)((S|U)\d{3})MIEVLI/) {
#          $insts_expids{'M2'}{$1} = 'dummy';
          $evlist = $file;
        }
        my $inst_uc = $1;
        my $expid = $2;

        if ($evlist){
          my $filter=&getExposureProperty("$prod_dir/$evlist", 'FILTER');

          unless(uc($filter) =~ /^(THIN|MEDIUM|THICK|OPEN)/ ){
SAS::error('badFilter', "Don't recognize filter $filter.");
          }
#          $filters{$obsid}{$instexpid} = $1;
          $insts_hash{$inst_uc}{$expid} = $1;
        }
      }

SAS::error('noCalind', "No CALIND file in $prod_dir.")
      if (!$calind_found);
SAS::error('noAtttsr', "No ATTTSR file in $prod_dir.")
      if (!$atttsr_found);
SAS::error('noInstruments', "No epic event lists in $prod_dir.")
      if (!(defined($insts_hash{'PN'}) || defined($insts_hash{'M1'}) || defined($insts_hash{'M2'})));

#      my @insts_uc = keys(%insts_expids);
      my @insts_uc = keys(%insts_hash);
      foreach $inst_uc (@insts_uc){
        my @expids = keys(%{$insts_hash{$inst_uc}});
        foreach $expid (@expids){
          if ($is_first_obsinstexp) {
            foreach my $file (@prod_files) {
              chomp($file);
              if ($file =~ /^P\d{10}${inst_uc}${expid}EXPMAP(\w)/) {
                $bandhash{$1} = 'dummy';
              }
            }
            $is_first_obsinstexp = 0;
SAS::error('noBands', "No bands found for instexpid $inst_uc$expid in directory $prod_dir.")
            if (!keys(%bandhash));

          } else { # !$is_first_obsinstexp
            my %temp_bandhash = ();
            foreach my $file (@prod_files) {
              chomp($file);
              if ($file =~ /^P\d{10}${inst_uc}${expid}EXPMAP(\w)/) {
SAS::error('tooManyBands', "Too many bands for instexpid $inst_uc$expid in directory $prod_dir.")
                if (!defined($bandhash{$1}));

                $temp_bandhash{$1} = 'dummy';
              }
            }

            foreach my $band (keys(%bandhash)){
SAS::error('tooFewBands', "Too few bands for instexpid $inst_uc$expid in directory $prod_dir.")
                if (!defined($temp_bandhash{$band}));
            }
          }
        }
      }

      $obs_ids{$obsid_root} = {'obsid'    => "$obsid", # quotes to force it to be a string.
                               'instrums' => {%insts_hash}};
    } # end foreach $obsid_root (@obsid_roots)

    my @used_bands = sort(keys(%bandhash));

  return \%obs_ids, \@used_bands;
  } # checkProds_old

  #---------------------------------------------------------------------
  sub dumpProds {
  #---------------------------------------------------------------------

    my ($obsid_ref, $used_bands_ref, $filters_ref) = @_;

    my %obs_ids = %{$obsid_ref};
    my %filters = %{$filters_ref};
    my @obsid_roots = keys(%obs_ids);
    foreach my $obsid_root (@obsid_roots) {
      my $obsid = $obs_ids{$obsid_root};
      print "obsid $obsid:\n";
#      my %insts_hash = %{$obs_ids{$obsid_root}{'instrums'}};
#      foreach my $inst_uc (keys(%insts_hash)){
#      print "  $inst_uc:\n";
#        my %expid_hash = %{$insts_hash{$inst_uc}};
#        foreach my $expid (keys(%expid_hash)){
      my @instexpids = keys(%{$filters{$obsid}});
      foreach my $instexpid (@instexpids){
#         my $filter = $insts_hash{$inst_uc}{$expid};
#          print "    $expid $filter\n";
        my $filter = $filters{$obsid}{$instexpid};
        print "    $instexpid $filter\n";
#        }
      }
    }
    print "\n";

    my @used_bands = @{$used_bands_ref};
    foreach my $band (@used_bands) {
      print "band $band\n";
    }
  } # dumpProds

  #---------------------------------------------------------------------
  sub dumpProds_old {
  #---------------------------------------------------------------------

    my ($obsid_ref, $used_bands_ref) = @_;

    my %obs_ids = %{$obsid_ref};
    my @obsid_roots = keys(%obs_ids);
    foreach my $obsid_root (@obsid_roots) {
      my $obsid = $obs_ids{$obsid_root}{'obsid'};
      print "obsid $obsid:\n";
      my %insts_hash = %{$obs_ids{$obsid_root}{'instrums'}};
      foreach my $inst_uc (keys(%insts_hash)){
      print "  $inst_uc:\n";
        my %expid_hash = %{$insts_hash{$inst_uc}};
        foreach my $expid (keys(%expid_hash)){
          my $filter = $insts_hash{$inst_uc}{$expid};
          print "    $expid $filter\n";
        }
      }
    }
    print "\n";

    my @used_bands = @{$used_bands_ref};
    foreach my $band (@used_bands) {
      print "band $band\n";
    }

  } # dumpProds_old

  #---------------------------------------------------------------------
  sub checkBandInstFilt {
  #---------------------------------------------------------------------
  # This checks that all bands, and all combos of instrument/filter, are
  # present in the ecf hash. It also calculates a hash which is useful
  # to translate between the band hash and the ecf list.

    my ($used_bands_ref, $filters_ref, $ecf_ref) = @_;

    my @used_bands = @{$used_bands_ref};
    my %filters = %{$filters_ref};
#    my %obs_ids = keys(%{$filters_ref});
    my @ecf_info = @{$ecf_ref};

    my %band_to_i = ();
    foreach my $band (@used_bands){
      my $band_was_found = 0;
      foreach my $i (0 .. $#ecf_info) {
        my $ecf_band = $ecf_info[$i]{'bandid'};
        if ($ecf_info[$i]{'bandid'} eq $band){
          $band_was_found = 1;
          $band_to_i{$band} = $i;
      last;
        }
      } # next $i
SAS::error('bandNotInTemplateFile', "Couldn't find band $band in the template file.")
      if (!$band_was_found);
    } # next $band

    my @obsids = keys(%filters);
    foreach my $band (@used_bands){
      my $i = $band_to_i{$band};
SAS::error('bandNotInTemplateFile', "Couldn't find band $band in the template file.")
      if (!defined($ecf_info[$i]));

      foreach my $obsid (@obsids) {
#        my $obsid = $obs_ids{$obsid_root}{'obsid'};
#        my %insts_hash = %{$obs_ids{$obsid_root}{'instrums'}};
        my %ecf_insts_hash = %{$ecf_info[$i]{'instrums'}};
        my @instexpids = keys(%{$filters{$obsid}});
        foreach my $instexpid (@instexpids){
          my $inst_uc = substr($instexpid, 0, 2);
#        foreach my $inst_uc (keys(%insts_hash)){
SAS::error('instNotInTemplateFile', "Couldn't find inst $inst_uc in the template file.")
          if (!defined($ecf_insts_hash{$inst_uc}));

#          my %expid_hash = %{$insts_hash{$inst_uc}};
#          foreach my $expid (keys(%expid_hash)){
#            my $filter = $insts_hash{$inst_uc}{$expid};
          my $filter = $filters{$obsid}{$instexpid};
#print "ggg filter=$filter\n";
SAS::error('filterNotInTemplateFile', "Couldn't find filter $filter for inst $inst_uc in the template file.")
          if (!defined($ecf_insts_hash{$inst_uc}{$filter}));
#          }
        } # $instexpid
      } # $obsid
    } # $band


    my %instexpids = ();
#    foreach my $obsid_root (@obsid_roots) {
#      my $obsid = $obs_ids{$obsid_root}{'obsid'};
    foreach my $obsid (keys(%filters)) {
#print "hhh obsid=$obsid\n";
#print "$filters{$obsid}\n";
      my @blah = sort(keys(%{$filters{$obsid}}));
#print "@blah\n";
#      $instexpids{$obsid} = [sort(keys(%{$filters{$obsid}}))];
      $instexpids{$obsid} = [@blah];
#      my %insts_hash = %{$obs_ids{$obsid_root}{'instrums'}};
#      foreach my $inst_uc (keys(%insts_hash)) {
#        my %expids = %{$insts_hash{$inst_uc}};
#        foreach my $expid (keys(%expids)) {
#          push @{$instexpids{$obsid}}, "$inst_uc$expid";
#        }
#      }
    }

  return \%instexpids, \%band_to_i;
  } # checkBandInstFilt

  #---------------------------------------------------------------------
  sub checkBandInstFilt_20070828 {
  #---------------------------------------------------------------------
  # This checks that all bands, and all combos of instrument/filter, are
  # present in the ecf hash. It also calculates a hash which is useful
  # to translate between the band hash and the ecf list.

    my ($used_bands_ref, $filters_ref, $ecf_ref) = @_;

    my @used_bands = @{$used_bands_ref};
    my %filters = %{$filters_ref};
#    my %obs_ids = keys(%{$filters_ref});
    my @ecf_info = @{$ecf_ref};

    my %band_to_i = ();
    foreach my $band (@used_bands){
      my $band_was_found = 0;
      foreach my $i (0 .. $#ecf_info) {
        my $ecf_band = $ecf_info[$i]{'bandid'};
        if ($ecf_info[$i]{'bandid'} eq $band){
          $band_was_found = 1;
          $band_to_i{$band} = $i;
      last;
        }
      } # next $i
SAS::error('bandNotInTemplateFile', "Couldn't find band $band in the template file.")
      if (!$band_was_found);
    } # next $band

    my @obsids = keys(%filters);
    foreach my $band (@used_bands){
      my $i = $band_to_i{$band};
SAS::error('bandNotInTemplateFile', "Couldn't find band $band in the template file.")
      if (!defined($ecf_info[$i]));

      foreach my $obsid (@obsids) {
#        my $obsid = $obs_ids{$obsid_root}{'obsid'};
#        my %insts_hash = %{$obs_ids{$obsid_root}{'instrums'}};
        my %ecf_insts_hash = %{$ecf_info[$i]{'instrums'}};
        my @instexpids = keys(%{$filters{$obsid}});
        foreach my $instexpid (@instexpids){
          my $inst_uc = substr($instexpid, 0, 2);
#        foreach my $inst_uc (keys(%insts_hash)){
SAS::error('instNotInTemplateFile', "Couldn't find inst $inst_uc in the template file.")
          if (!defined($ecf_insts_hash{$inst_uc}));

#          my %expid_hash = %{$insts_hash{$inst_uc}};
#          foreach my $expid (keys(%expid_hash)){
#            my $filter = $insts_hash{$inst_uc}{$expid};
          my $filter = $filters{$obsid}{$instexpid};
#print "ggg filter=$filter\n";
SAS::error('filterNotInTemplateFile', "Couldn't find filter $filter for inst $inst_uc in the template file.")
          if (!defined($ecf_insts_hash{$inst_uc}{$filter}));
#          }
        } # $instexpid
      } # $obsid
    } # $band


    my %instexpids = ();
#    foreach my $obsid_root (@obsid_roots) {
#      my $obsid = $obs_ids{$obsid_root}{'obsid'};
    foreach my $obsid (keys(%filters)) {
#print "hhh obsid=$obsid\n";
#print "$filters{$obsid}\n";
      my @blah = sort(keys(%{$filters{$obsid}}));
#print "@blah\n";
#      $instexpids{$obsid} = [sort(keys(%{$filters{$obsid}}))];
      $instexpids{$obsid} = [@blah];
#      my %insts_hash = %{$obs_ids{$obsid_root}{'instrums'}};
#      foreach my $inst_uc (keys(%insts_hash)) {
#        my %expids = %{$insts_hash{$inst_uc}};
#        foreach my $expid (keys(%expids)) {
#          push @{$instexpids{$obsid}}, "$inst_uc$expid";
#        }
#      }
    }

  return \%instexpids, \%band_to_i;
  } # checkBandInstFilt_20070828

  #---------------------------------------------------------------------
  sub checkBandInstFilt_old {
  #---------------------------------------------------------------------
  # This checks that all bands, and all combos of instrument/filter, are
  # present in the ecf hash. It also calculates a couple of useful hashes.

    my ($used_bands_ref, $obsid_ref, $ecf_ref) = @_;

    my @used_bands = @{$used_bands_ref};
    my %obs_ids = %{$obsid_ref};
    my @ecf_info = @{$ecf_ref};

    my %band_to_i = ();
    foreach my $band (@used_bands){
#print "$band\n";
      my $band_was_found = 0;
      foreach my $i (0 .. $#ecf_info) {
        my $ecf_band = $ecf_info[$i]{'bandid'};
#print "  $i $ecf_band\n";
        if ($ecf_info[$i]{'bandid'} eq $band){
          $band_was_found = 1;
          $band_to_i{$band} = $i;
      last;
        }
      } # next $i
SAS::error('bandNotInTemplateFile', "Couldn't find band $band in the template file.")
      if (!$band_was_found);
    } # next $band

    my @obsid_roots = keys(%obs_ids);
    foreach my $band (@used_bands){
      my $i = $band_to_i{$band};
SAS::error('bandNotInTemplateFile', "Couldn't find band $band in the template file.")
      if (!defined($ecf_info[$i]));

      foreach my $obsid_root (@obsid_roots) {
        my $obsid = $obs_ids{$obsid_root}{'obsid'};
        my %insts_hash = %{$obs_ids{$obsid_root}{'instrums'}};
        my %ecf_insts_hash = %{$ecf_info[$i]{'instrums'}};
        foreach my $inst_uc (keys(%insts_hash)){
SAS::error('instNotInTemplateFile', "Couldn't find inst $inst_uc in the template file.")
          if (!defined($ecf_insts_hash{$inst_uc}));

          my %expid_hash = %{$insts_hash{$inst_uc}};
          foreach my $expid (keys(%expid_hash)){
            my $filter = $insts_hash{$inst_uc}{$expid};
SAS::error('filterNotInTemplateFile', "Couldn't find filter $filter for inst $inst_uc in the template file.")
            if (!defined($ecf_insts_hash{$inst_uc}{$filter}));
          }
        }
      }
    }

#    my @obsid_roots = keys(%obs_ids);
    my %instexpids = ();
    foreach my $obsid_root (@obsid_roots) {
      my $obsid = $obs_ids{$obsid_root}{'obsid'};
      my %insts_hash = %{$obs_ids{$obsid_root}{'instrums'}};
#      my %temp_hash = ();
      foreach my $inst_uc (keys(%insts_hash)) {
#SAS::error('instNotInTemplateFile', "Couldn't find inst $inst_uc in the template file.")
#        if (!defined($ecf_filter_lists{$inst_uc}));

        my %expids = %{$insts_hash{$inst_uc}};
        foreach my $expid (keys(%expids)) {
#          my $filter = $insts_hash{$inst_uc}{$expid};
#SAS::error('filterNotInTemplateFile', "Couldn't find filter $filter for inst $inst_uc in the template file.")
#          if (!defined($ecf_filter_lists{$inst_uc}{$filter}));

 #         $temp_hash{"$inst_uc$expid"} = 1;
          push @{$instexpids{$obsid}}, "$inst_uc$expid";
        }
      }

#      push @{$instexpids{$obsid}}, keys(%temp_hash)
    }

  return \%instexpids, \%band_to_i;
  } # checkBandInstFilt_old

  #---------------------------------------------------------------------
  sub getVersion {
  #---------------------------------------------------------------------
  # Obtain the version string for a sas task.

    my ($taskname) = @_;
    my $version = ''; # default

    my ($str) = `$taskname -v`;
    if ($str =~ /^${taskname}\s+\(${taskname}-(\d+\.\d+(|\.\d+))\)/){
      $version = $1;
    }

  return $version;
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
  sub quit {
  #---------------------------------------------------------------------
    my ($code, $message) = @_;
SAS::error($code, $message)
  }

  #---------------------------------------------------------------------
  sub template {
  #---------------------------------------------------------------------

  }


1;

