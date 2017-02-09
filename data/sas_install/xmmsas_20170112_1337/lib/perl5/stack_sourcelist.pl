# read emldetect source list with "raw rows" and combine them to the final
# stacked source list with summary rows per observation and instrument

sub stack_sourcelist() {

    # expecting at least two arguments:
    @_>=3 or SAS::message($SAS::AppMsg, $SAS::SilentMsg, 
                         "Internal code error: function stack_sourcelist() ".
                         "called with wrong number of arguments. ");

    # 1. mandatory: file name of input emldetect source list
    my $inlist = $_[0];

    # 2. mandatory: file name of stacked output source list
    my $outlist = $_[1];
    my $outlistsum;

    # 3. mandatory: minimum likelihood per pointing
    my $mindetml = $_[2];

    # 4. not mandatory: hrpndef, hrm1def, hrm2def, comment
    my @addpar = @_[3..$#_];

   ########################################
    # INTERNAL PARAMETERS OF SAS TASKS
    # - NEED TO BE UPDATED IN CASE THE TASKS ARE UPDATED
    my $maskthr = 0.15;                      # psfthreshold in emldetect; FIXED
    ########################################

    # other values
    my $mynull = 0**(-1);

    ########################################
    ## variables:
    my $fits;         ## holds the fits file
    my $nbands;       ## number of energy bands used during source detection
    my $frstrow;      ## index of first row of currently addressed detection
    my $thisrow;      ## index of currently addressed row in the source list
    my @newvals;      ## array of new values in a column and a row slice
    my %instrows;     ## hash of arrays holding the row numbers per instrument
    my %hrdef;        ## energy bands used to calculate HRs
    my @pointings;    ## pointings per source
    ## declared later-on:
    # - modified columns of the source list
    # - $srcid:          ML_SRC_ID of the currently addressed detection
    # - @srcinds:        indexes of all rows of $srcid
    # - $instslice:      pointer to instrument IDs of these rows
    # - $instidpnt:      ID_INST of currently addressed pointing
    # - @pntinds:        row indexes of this pointing; subset of @srcinds
    # - @instinds:       row indexes of the instrument; subset of @srcinds
    # - @pntrows:        row indexes of all pointings with same ID_BAND
    ## variables to store intermediate results
    my %seenids;      ## used when determining the unique detection IDs
    my $tmpexpmap;    ## temporary EXP_MAP  values; used for checks
    my $tmpmaskfrac;  ## temporary MASKFRAC values; used for checks
    my $tmpdetml;     ## detection likelihood per pointing
    my $tmpmaxdetml;  ## used to calculate maximum of pointing likelihoods
    my $tmpflux;      ## flux values; used to calculate the total flux
    my $tmpfluxerr;   ## flux errors; used to calculate the total flux error
    my @tmphrval=($mynull,$mynull,$mynull,$mynull); ## hardness ratios
    my @tmphrerr=($mynull,$mynull,$mynull,$mynull); ## their errors
    ## declared later-on:
    # - %seenpnts:       used when determining the instrument IDs per detection
    # - @instmaskfracs:  maxima of all pointing MASKFRACs
    # - @instfluxvals:   total flux per instrument and energy band
    # - @instfluxerrs:   flux error per instrument and energy band
    my $startcol=6;   ## number of first column which will get new values
    my $nnewrows = 4; ## number of new summary rows per pointing       ### FIXED
    my $headercomment=$addpar[3];

    ########################################
    # summary source list
    my ($suffix) =  ($outlist =~ /.*(\..*)/) 
	            ? $outlist =~ /.*(\..*)/ : "";
    if ($suffix eq ".gz" || $suffix eq ".GZ") {
	($suffix) = ($outlist =~ /.*(\..*)\.(.*)/)
	            ? $outlist =~ /.*(\..*)\.(.*)/ : "";
    }
    # determine file base
    ($outlistsum) = ($outlist =~ /(.*)$suffix/);
    $outlistsum   = $outlistsum."_sum".$suffix;
    ########################################

    # copy input file to output file name and work on output file from now on
    copy($inlist, $outlist)
        or die SAS::error("FileNotCopied", "Could not copy $inlist to ".
                          "$outlist. Please make sure that you have read ".
                          "and write access.");

    # open first extension (read-only) and get HR??DEF keywords
    # If not defined: parameter value or default
    # If a keyword is undefined, SimpleFits stops reading the header, so we
    # have to re-open it ...
    $fits = SimpleFITS->open($outlist, access=>"readonly");
    $fits->readkey("HRPNDEF", my $hrpndef);
    $fits->close;
    if (! defined($hrpndef)) {
	$hrpndef = $addpar[0];
	if (! defined($hrpndef)) {
	    $hrpndef = "1 2 2 3 3 4 4 5";
	}
	SAS::warning("KeywordMissing", 
		     "Keyword HRPNDEF not found - using default value.");
    }
    $fits = SimpleFITS->open($outlist, access=>"readonly");
    $fits->readkey("HRM1DEF", my $hrm1def);
    $fits->close;
    if (! defined($hrm1def)) {
	$hrm1def = $addpar[1];
	if (! defined($hrm1def)) {
	    $hrm1def = "1 2 2 3 3 4 4 5";
	}
	SAS::warning("KeywordMissing", 
		     "Keyword HRM1DEF not found - using default value.");
    }
    $fits = SimpleFITS->open($outlist, access=>"readonly");
    $fits->readkey("HRM2DEF", my $hrm2def);
    $fits->close;
    if (! defined($hrm2def)) {
	$hrm2def = $addpar[2];
	if (! defined($hrm2def)) {
	    $hrm2def = "1 2 2 3 3 4 4 5";
	}
	SAS::warning("KeywordMissing", 
		     "Keyword HRM2DEF not found - using default value.");
    }
    # hrdef structure (cf. emldetect/eml_io.f90:
    @{$hrdef{1}} = split(/ /,$hrpndef);
    @{$hrdef{2}} = split(/ /,$hrm1def);
    @{$hrdef{3}} = split(/ /,$hrm2def);

    # open fits file (read-write)
    $fits = SimpleFITS->open($outlist, access=>"readwrite", type=>"table");
    ($fits->status() == 0) 
        or SAS::error("FileNotFound", "Could not open $outlist. ".
                      "File not found or unreadable.");

    ## MODIFY COLUMN BY COLUMN
    # relevant columns: IDs, those to be re-defined, those affected by
    # MASKFRAC, and those used to derive other values.
    # set pointers
    $fits
        ->readcol("ML_ID_SRC",  {}, my $mlidsrc   )
        ->readcol("ID_INST",    {}, my $idinst    )
        ->readcol("ID_BAND",    {}, my $idband    )
        ->readcol("SCTS",       {}, my $scts      )
        ->readcol("SCTS_ERR",   {}, my $sctserr   )
        ->readcol("EXT",        {}, my $ext       )
        ->readcol("DET_ML",     {}, my $detml     )
        ->readcol("EXT_ML",     {}, my $extml     )
        ->readcol("BG_MAP",     {}, my $bgmap     )
        ->readcol("EXP_MAP",    {}, my $expmap    )
        ->readcol("FLUX",       {}, my $flux      )
        ->readcol("FLUX_ERR",   {}, my $fluxerr   )
        ->readcol("RATE",       {}, my $rate      )
        ->readcol("RATE_ERR",   {}, my $rateerr   )
        ->readcol("RAWX",       {}, my $rawx      )
        ->readcol("RAWY",       {}, my $rawy      )
        ->readcol("OFFAX",      {}, my $offax     )
        ->readcol("CCDNR",      {}, my $ccdnr     )
        ->readcol("HR1",        {}, my $hr1       )
        ->readcol("HR1_ERR",    {}, my $hr1err    )
        ->readcol("HR2",        {}, my $hr2       )
        ->readcol("HR2_ERR",    {}, my $hr2err    )
        ->readcol("HR3",        {}, my $hr3       )
        ->readcol("HR3_ERR",    {}, my $hr3err    )
        ->readcol("HR4",        {}, my $hr4       )
        ->readcol("HR4_ERR",    {}, my $hr4err    )
        ->readcol("MASKFRAC",   {}, my $maskfrac  )
        ->readcol("VIGNETTING", {}, my $vignetting)
	->ncols(my $ncol);

## Long integers are not supported by the DAL, which also means: The source
## list cannot be read by Fortran tasks, if ID_INST is converted into long
## integer. Stick to the workaround: floating point with double precision and
## display format TDISP F11.0.
##    # convert ID_INST column into long integer (not possible in emldetect,
##    # because int64 seems not to be supported)
##    my $tmpcolnum = $fits->colnum("ID_INST");
##    @newvals = @$idinst;
##    $fits
##	->delcol("ID_INST")
##	->insertcol({TTYPE => ["ID_INST", ""], TFORM => "K"}, $tmpcolnum)
##	->writecol("ID_INST", {}, \@newvals);

    # determine number of energy bands:
    $nbands = List::Util::max @$idband;

    ## UPDATE SOURCE LIST
    # loop over unique source IDs
    # Both loops (over sources and over pointings) are run in reverse order,
    # so we won't mess up the row indices by inserting the new summary rows.
    %seenids = ();
    SOURCE: for my $srcid                        ### (reverse) loop over sources
	(reverse(grep { ! $seenids{ $_ }++ } @$mlidsrc)) {  ### labeled "SOURCE"

	# indices of the rows which have ML_ID_SRC $srcid
#	my @srcinds = (List::MoreUtils::indexes { $_ eq $srcid } @$mlidsrc);
        my ( @srcinds ) = grep { $$mlidsrc[$_] eq $srcid } 0..$#{$mlidsrc};
	my $instslice = [@$idinst[@srcinds]];
	# initialize (empty) arrays of pointing summary values, which will be
	# used for the total summary later-on
	@{$instrows{1}} = ();
	@{$instrows{2}} = ();
	@{$instrows{3}} = ();
	# initialize maximum of pointing DET_MLs with the all-EPIC DET_ML
	$tmpmaxdetml = $$detml[$srcinds[0]];

        ## DEFINE ROWS PER POINTING
	# loop over unique pointings per source ID
	# - modify summary rows last
	my %seenpts = ();
	# get pointing IDs:
	# - use a (reference on the) ML_ID_SRC slice of ID_INST
	# - ignore last digit of ID_INST
	@pointings = 
	    reverse(grep { ! $seenpts{ (substr $_,0,(length($_)-1)) }++ }  
		    @$idinst[@srcinds]);
	foreach my $instidpnt (@pointings) {   ### (reverse) loop over pointings

	    $instidpnt = (substr $instidpnt,0,(length($instidpnt)-1));

	    # row numbers of this pointing (indices starting with 0)
	    my @pntinds = 
		@srcinds[(grep
			  { (substr $$instslice[$_], 0,
			     (length($$instslice[$_])-1))
				eq "$instidpnt" } 
			  0..$#{$instslice})];
            ## insert summary rows per pointing: one total, one per instrument
	    if ($instidpnt ne "") {                 ### begin: rows per pointing

		# new rows
		$fits->insertrows($nnewrows, $pntinds[0]);

		# initialize columns 1-5 of the summary rows with values from
		# the next row
		# (writecol: array reference or scalar)
		$frstrow = $pntinds[0]+$nnewrows+1;
		my $srtrow = $pntinds[0]+1;
		my $endrow = $pntinds[0]+$nnewrows;
		foreach (1..$startcol-1) {
		    $fits->readcol( $_, {rows=>[$frstrow]}, my $tmpvar);
		    @newvals = ($$tmpvar[0])x$nnewrows;
		    $fits->writecol($_, {rows=>[$srtrow,$endrow]}, \@newvals);
		}

		# set ID_BAND to zero
		@newvals = (0)x$nnewrows;
		$fits->writecol("ID_BAND",{rows=>[$srtrow,$endrow]}, \@newvals);

		################################################################
		## set final column values per pointing per instrument
		for my $nr (1..$nnewrows-1) {     ### loop over new summary rows

		    $thisrow = $pntinds[0]+$nr+1;

		# ID_INST: abbreviated OBS_ID + INST_ID
		    $fits->writecol("ID_INST", {rows=>$thisrow}, 
				    "$instidpnt"."$nr");

		    # rows corresponding to this instrument
		    my @instinds =
			@srcinds[(grep
				  { $$instslice[$_] eq "$instidpnt"."$nr" } 
				  0..$#{$instslice})];
		    if (@instinds) {               ### begin: instrument defined

			# PREPARATORY WORK

			# add the instrument row numbers to the index array
			push @{$instrows{$nr}}, @instinds;

			# initialize other columns with values from first
			# instrument row
			$frstrow = $instinds[0]+$nnewrows+1;

			foreach ($startcol..$ncol) {
			    $fits->readcol( $_, {rows=>[$frstrow]}, my $tmpvar);
			    $fits->writecol($_, {rows=>$thisrow}, $tmpvar);
			}

			# temporary values of EXP_MAP, MASKFRAC, used for checks
			$tmpexpmap = List::Util::sum @$expmap[@instinds];
			$tmpmaskfrac = List::Util::min @$maskfrac[@instinds];
			# up to four hardness ratios
			for my $ie (0..$nbands-1) {
                                    # loop over energy bands (max. $nband-1 HRs)
			    $tmphrval[$ie] = $mynull;
			    $tmphrerr[$ie] = $mynull;
			    # calculate hardness ratio, if @hrdef is set 
			    if (defined(${$hrdef{$nr}}[2*$ie])
				&& defined(${$hrdef{$nr}}[2*$ie+1])
				&& "0"."${$hrdef{$nr}}[2*$ie]"   > 0
				&& "0"."${$hrdef{$nr}}[2*$ie+1]" > 0) {
				# ... and if corresponding rows are found
				if( $$idband[$instinds[0]-1+${$hrdef{$nr}}[2*$ie]]
				    == ${$hrdef{$nr}}[2*$ie]
				    && $$idband[$instinds[0]-1+${$hrdef{$nr}}[2*$ie+1]]
				    == ${$hrdef{$nr}}[2*$ie+1] )
				{
				# indices: rows are sorted by band number
				# -> first row of the instrument block
				#    plus band indices minus one (start with 0)
				my $lowind = 
				    $instinds[0]-1 + ${$hrdef{$nr}}[2*$ie];
				my $higind = 
				    $instinds[0]-1 + ${$hrdef{$nr}}[2*$ie+1];
				# max(0.,rate):
				my $ratelowval = 
				    ($$rate[$lowind]>=0) ? $$rate[$lowind] : 0;
				my $ratehigval = 
				    ($$rate[$higind]>=0) ? $$rate[$higind] : 0;
				# HR
				my $tmpsum = $ratelowval+$ratehigval;
				if ($tmpsum != 0) {
				    $tmphrval[$ie] =
					($ratehigval-$ratelowval) / $tmpsum ;
				# HR error
				    $tmphrerr[$ie] = 
					2.0*sqrt($$rate[$lowind]
						 *$$rate[$lowind]
						 *$$rateerr[$lowind]
						 *$$rateerr[$lowind]
						 +
						 $$rate[$higind]
						 *$$rate[$higind]
						 *$$rateerr[$higind]
						 *$$rateerr[$higind]
					) / $tmpsum/$tmpsum ;
				}		
			    }}                                  # end if defined
			}                           # end loop over energy bands


			# COLUMNS ##############################################
			$fits
		# SCTS: sum; null if exp_map<=0 or maskfrac<threshold
			    ->writecol("SCTS", {rows=>$thisrow},
				       (defined($tmpmaskfrac) &&
					$tmpmaskfrac>=$maskthr &&
					defined($tmpexpmap) &&
					$tmpexpmap>0)
				       ?
				       (List::Util::sum @$scts[@instinds])
				       :
				       $mynull)
                # SCTS_ERR: square root of quadratic sum or null
			    ->writecol("SCTS_ERR", {rows=>$thisrow},
				       (defined($tmpmaskfrac) &&
					$tmpmaskfrac>=$maskthr &&
					defined($tmpexpmap) &&
					$tmpexpmap>0)
				       ?
				       (sqrt(List::Util::sum 
					     ( map {(defined($_)) ? $_*$_ : 0.0}
					       (@$sctserr[@instinds])
					    ) ))
				       :
				       $mynull )
                # DET_ML: equivalent likelihood via gamma function or NULL
			    ->writecol("DET_ML", {rows=>$thisrow},
				       (defined($tmpmaskfrac) &&
					$tmpmaskfrac>=$maskthr &&
					defined($tmpexpmap) &&
					$tmpexpmap>0)
				       ?
				       likelihood(   # dofs/2, sum(likelihoods)
					   (2+($$extml[$instinds[0]]>0)
					    +(scalar @instinds))/2.0,
					   List::Util::sum @$detml[@instinds]
				       ) 
				       :
				       $mynull )
                # BG_MAP: sum; null if exp_map<=0
			    ->writecol("BG_MAP", {rows=>$thisrow},
				       (defined($tmpexpmap) && $tmpexpmap>0)
				       ?
				       (List::Util::sum @$bgmap[@instinds])
				       :
				       $mynull)
		# EXP_MAP: sum; null if negative
			    ->writecol("EXP_MAP", {rows=>$thisrow},
				       (defined($tmpexpmap) && $tmpexpmap>0)
				       ?
				       $tmpexpmap
				       :
				       $mynull)
                # FLUX: sum; null if exp_map<=0 or maskfrac<threshold
			    ->writecol("FLUX", {rows=>$thisrow},
				       (defined($tmpmaskfrac) &&
					$tmpmaskfrac>=$maskthr &&
					defined($tmpexpmap) &&
					$tmpexpmap>0)
				       ?
				       (List::Util::sum @$flux[@instinds])
				       :
				       $mynull)
                # FLUX_ERR: square root of quadratic sum or null
			    ->writecol("FLUX_ERR", {rows=>$thisrow},
				       (defined($tmpmaskfrac) &&
					$tmpmaskfrac>=$maskthr &&
					defined($tmpexpmap) &&
					$tmpexpmap>0)
				       ?
				       (sqrt(List::Util::sum 
					     ( map {(defined($_)) ? $_*$_ : 0.0}
						    (@$fluxerr[@instinds])
					    ) ))
				       :
				       $mynull )
                # RATE: sum; null if exp_map<=0 or maskfrac<threshold
			    ->writecol("RATE", {rows=>$thisrow},
				       (defined($tmpmaskfrac) &&
					$tmpmaskfrac>=$maskthr &&
					defined($tmpexpmap) &&
					$tmpexpmap>0)
				       ?
				       (List::Util::sum @$rate[@instinds])
				       :
				       $mynull)
                # RATE_ERR: square root of quadratic sum or null
			    ->writecol("RATE_ERR", {rows=>$thisrow},
				       (defined($tmpmaskfrac) &&
					$tmpmaskfrac>=$maskthr &&
					defined($tmpexpmap) &&
					$tmpexpmap>0)
				       ?
				       (sqrt(List::Util::sum 
					     ( map {(defined($_)) ? $_*$_ : 0.0}
					       (@$rateerr[@instinds])
					    ) ))
				       :
				       $mynull )
                # HR1: calculated above, set to null if lower than -10
			    ->writecol("HR1", {rows=>$thisrow},
				       ($tmphrval[0] >= -10.0)
				       ?
				       $tmphrval[0]
				       :
				       $mynull)
                # HR1_ERR
			    ->writecol("HR1_ERR", {rows=>$thisrow},
				       ($tmphrerr[0] >= -10.0)
				       ?
				       $tmphrerr[0]
				       :
				       $mynull)
                # HR2
			    ->writecol("HR2", {rows=>$thisrow},
				       ($tmphrval[1] >= -10.0)
				       ?
				       $tmphrval[1]
				       :
				       $mynull)
                # HR2_ERR
			    ->writecol("HR2_ERR", {rows=>$thisrow},
				       ($tmphrerr[1] >= -10.0)
				       ?
				       $tmphrerr[1]
				       :
				       $mynull)
                # HR3
			    ->writecol("HR3", {rows=>$thisrow},
				       ($tmphrval[2] >= -10.0)
				       ?
				       $tmphrval[2]
				       :
				       $mynull)
                # HR3_ERR
			    ->writecol("HR3_ERR", {rows=>$thisrow},
				       ($tmphrerr[2] >= -10.0)
				       ?
				       $tmphrerr[2]
				       :
				       $mynull)
                # HR4
			    ->writecol("HR4", {rows=>$thisrow},
				       ($tmphrval[3] >= -10.0)
				       ?
				       $tmphrval[3]
				       :
				       $mynull)
                # HR4_ERR
			    ->writecol("HR4_ERR", {rows=>$thisrow},
				       ($tmphrerr[3] >= -10.0)
				       ?
				       $tmphrerr[3]
				       :
				       $mynull)
		# RAWX, RAWY, OFFAX, CCDNR: unchanged
			    #
		# MASKFRAC per pointing: minimum
			    ->writecol("MASKFRAC", {rows=>$thisrow},
				       $tmpmaskfrac)
                # EEF & VIGNETTING: null for instrument summaries
			    ->writecol("EEF",        {rows=>$thisrow}, $mynull)
			    ->writecol("VIGNETTING", {rows=>$thisrow}, $mynull)
                # ONTIME: unchanged

			    # done.
			    ;

		    } else {                     ### begin: instrument undefined
			# set all columns from SCTS on to NULL if instrument has
			# not been used (without FLAG column)
			for my $nc ($startcol..$ncol-1) {
			    $fits->writecol($nc, {rows=>$thisrow}, $mynull);
			}
		    }                    ### end: instrument defined / undefined

		}                             ### end loop over new summary rows



		################################################################
		## set final column values in summary row per pointing
		$thisrow = $pntinds[0]+1;

		# PREPARATORY WORK

		# initialize with values from the next row
		$frstrow = $pntinds[0]+$nnewrows+1;
		foreach ($startcol..$ncol) {
		    $fits->readcol( $_, {rows=>[$frstrow]}, my $tmpvar);
		    $fits->writecol($_, {rows=>$thisrow}, $tmpvar);
		}

		# temporary value of EXP_MAP, used for checks
		my $tmpexpmap = List::Util::sum @$expmap[@pntinds];

		# calculate total fluxes and flux errors:
		# sum of summary values per instrument weighted by errors
		my $tmpsqerr;
		$tmpflux = 0.;
		$tmpfluxerr = 0.;
		for my $ii (1..$nnewrows-1) {
		    # read newly calculated summary values per instrument
		    $fits
			->readcol("FLUX",    {rows=>[$thisrow+$ii]}, my $tmpfl)
			->readcol("FLUX_ERR",{rows=>[$thisrow+$ii]}, my $tmpfe);
		    if (defined($$tmpfl[0]) && $$tmpfe[0] !=0 ) {
			$tmpsqerr = 1.0/$$tmpfe[0]/$$tmpfe[0];
			$tmpflux += $$tmpfl[0]*$tmpsqerr;
			$tmpfluxerr += $tmpsqerr;
		    }
		}
		if ($tmpflux > 0) {
		    $tmpflux /= $tmpfluxerr;
		    $tmpfluxerr = 1.0/sqrt($tmpfluxerr);
		} else {
		    $tmpflux = $mynull;
		    $tmpfluxerr = $mynull;
		}

		# calculate detection likelihood
		$tmpdetml = likelihood(   # dofs/2, sum(likelihoods)
					  (2+($$extml[$pntinds[0]]>0)
					   +(scalar @pntinds))/2.0,
					  List::Util::sum @$detml[@pntinds] );
		# maximum likelihood of pointings
		$tmpmaxdetml = $tmpdetml if ($tmpdetml > $tmpmaxdetml);

		# COLUMNS ######################################################
		$fits
		# ID_INST: abbreviated OBS_ID + 0
		    ->writecol("ID_INST", {rows=>$thisrow}, 
			       "$instidpnt"."0")
	        # SCTS: sum
		    ->writecol("SCTS", {rows=>$thisrow},
			       (List::Util::sum @$scts[@pntinds]))
		# SCTS_ERR: square root of quadratic sum
		    ->writecol("SCTS_ERR", {rows=>$thisrow},
			       (sqrt(List::Util::sum 
				     ( map {$_*$_} (@$sctserr[@pntinds])
				     ) )) )
		# DET_ML: equivalent likelihood via gamma function or null
		    ->writecol("DET_ML", {rows=>$thisrow},
			       $tmpdetml)
                # BG_MAP: sum; null if exp_map<=0
		    ->writecol("BG_MAP", {rows=>$thisrow},
			       (defined($tmpexpmap) && $tmpexpmap>0)
			       ?
			       (List::Util::sum @$bgmap[@pntinds])
			       :
			       $mynull)
  	        # EXP_MAP: null in summary rows with ID_INST [and/or ID_BAND]==0
		    ->writecol("EXP_MAP", {rows=>$thisrow}, 
			       $mynull)
    	        # FLUX: error-weighted mean of per-instrument fluxes
		    ->writecol("FLUX", {rows=>$thisrow},
			       $tmpflux)
  	        # FLUX_ERR: error of error-weighted mean flux (see above)
		    ->writecol("FLUX_ERR", {rows=>$thisrow},
			       $tmpfluxerr)
		# RATE: sum
		    ->writecol("RATE", {rows=>$thisrow},
			       (List::Util::sum @$rate[@pntinds]))
		# RATE_ERR: square root of quadratic sum
		    ->writecol("RATE_ERR", {rows=>$thisrow},
			       (sqrt(List::Util::sum 
				     ( map {$_*$_} (@$rateerr[@pntinds])
				     ) )) )
		# following columns are null in INST_ID==0 summary rows:
		    ->writecol("RAWX",       {rows=>$thisrow}, $mynull)
		    ->writecol("RAWY",       {rows=>$thisrow}, $mynull)
		    ->writecol("OFFAX",      {rows=>$thisrow}, $mynull)
		    ->writecol("CCDNR",      {rows=>$thisrow}, $mynull)
		    ->writecol("HR1",        {rows=>$thisrow}, $mynull)
		    ->writecol("HR1_ERR",    {rows=>$thisrow}, $mynull)
		    ->writecol("HR2",        {rows=>$thisrow}, $mynull)
		    ->writecol("HR2_ERR",    {rows=>$thisrow}, $mynull)
		    ->writecol("HR3",        {rows=>$thisrow}, $mynull)
		    ->writecol("HR3_ERR",    {rows=>$thisrow}, $mynull)
		    ->writecol("HR4",        {rows=>$thisrow}, $mynull)
		    ->writecol("HR4_ERR",    {rows=>$thisrow}, $mynull)
		    ->writecol("MASKFRAC",   {rows=>$thisrow}, $mynull)
		    ->writecol("EEF",        {rows=>$thisrow}, $mynull)
		    ->writecol("VIGNETTING", {rows=>$thisrow}, $mynull)
		    ->writecol("ONTIME",     {rows=>$thisrow}, $mynull)
		    # done.
		    ;


	    }                                         ### end: rows per pointing

        }                                            ### end loop over pointings

	### CHECK DETECTION LIKELIHOOD PER POINTING
	# Total likelihood or at least one pointing likelihood have to be
	# larger than $mindetml.
	# n.b.: Surely it would make sense to check the likelihoods /before/ we
	# update all the entries of a source. Actually, we would need another
	# loop over the pointings, determine exposure and mask fraction, set the
	# individual detection likelihoods to null if necessary, and calculate
	# equivalent likelihoods per pointing and all-EPIC; then check them and
	# proceed only if we want to keep the source.
        # The difference in runtime between the two approaches is not relevant,
	# so we test it here.
	if ($tmpmaxdetml < $mindetml) {
	    # delete source from list:
	    # source rows plus new summary rows per pointing
	    for my $delrow
		(0..$#srcinds+$#pointings*$nnewrows) {
		    $fits->delrows([$srcinds[0]+1]);
	    }
	    # proceed to next source
	    next SOURCE;
	}
	    

	########################################################################
        ## MODIFY MAJOR ROWS (total summary last)

        # indexes of rows with ID_INST > 3
	@rowinds = @srcinds[(grep { "0"."$$idinst[$srcinds[$_]]" > 3 } 
			     0..$#srcinds)];

	## number of instruments: FIXED
	for my $nr (1..3) {                            ### loop over instruments
	    # indices of pointing rows corresponding to this instrument number:
	    # @{$instrows{$nr}}

	    # initialize (empty) arrays of mask fractions, fluxes and errors
	    my @instmaskfracs = ();
	    my @instfluxvals = ();
	    my @instfluxerrs = ();

	    # all rows of this detections which have ID_INST == $nr
	    if ($#{$instrows{$nr}} >= 0) {              # if instrows{$nr} found
		for my $ir               ### (reverse) loop over instrument rows
		    (reverse( @srcinds[(grep
					{ "0"."$$idinst[$srcinds[$_]]" == $nr }
					0..$#srcinds)] ))
		{

		    $thisrow = $ir+1;

		    ############################################################
		    ## I. PER INSTRUMENT PER ENERGY BAND
		    if ("0"."$$idband[$ir]" != 0) {         # begin ID_BAND !=0

			# indices of pointing rows with same ID_BAND
			my @pntrows = 
			    @{$instrows{$nr}}[(grep
				       { $$idband[${$instrows{$nr}}[$_]]
					     == $$idband[$ir] }
					       0..$#{$instrows{$nr}})];
			# temporary value of EXP_MAP, used for checks
			$tmpexpmap = List::Util::sum @$expmap[@pntrows];
			# temporary value of MASKFRAC: maximum of pointings
			$tmpmaskfrac = List::Util::max @$maskfrac[@pntrows];
			push @instmaskfracs, $tmpmaskfrac;
			# temporary values of flux, flux error:
			# needed for summary row
			$tmpflux = 
			    (defined($tmpexpmap) && $tmpexpmap != 0)
			    ? 
			    (List::Util::sum 
			     ( map { $$flux[$_]*$$expmap[$_] } @pntrows ))
			    / $tmpexpmap
			    : 
			    $mynull;
			push @instfluxvals, $tmpflux;
			$tmpfluxerr = 
			    (defined($tmpexpmap) && $tmpexpmap != 0)
			    ?
			    sqrt(List::Util::sum 
				 ( map { $$fluxerr[$_]*$$fluxerr[$_]
					     *$$expmap[$_]*$$expmap[$_] }
				   @pntrows )) / $tmpexpmap
				       : 
				       $mynull;
			push @instfluxerrs, $tmpfluxerr;

			# COLUMNS ##############################################
			$fits
			    # SCTS: sum; null if exp_map<=0 or maskfrac<thresh.
			    ->writecol("SCTS", {rows=>$thisrow},
				       (defined($tmpmaskfrac) &&
					$tmpmaskfrac>=$maskthr &&
					defined($tmpexpmap) &&
					$tmpexpmap>0)
				       ?
				       (List::Util::sum @$scts[@pntrows])
				       :
				       $mynull)
			    # SCTS_ERR: square root of quadratic sum or null
			    ->writecol("SCTS_ERR", {rows=>$thisrow},
				       (defined($tmpmaskfrac) &&
					$tmpmaskfrac>=$maskthr &&
					defined($tmpexpmap) &&
					$tmpexpmap>0)
				       ?
				       (sqrt(List::Util::sum 
					     ( map {(defined($_)) ? $_*$_ : 0.0}
					       (@$sctserr[@pntrows])
					     ) ))
				       :
				       $mynull )
			    # DET_ML: equivalent likelihood via gamma function 
			    #         or NULL
			    ->writecol("DET_ML", {rows=>$thisrow},
				       (defined($tmpmaskfrac) &&
					$tmpmaskfrac>=$maskthr &&
					defined($tmpexpmap) &&
					$tmpexpmap>0)
				       ?
				       likelihood(   # dofs/2, sum(likelihoods)
					  (2+($$extml[$pntrows[0]]>0)
					   +(scalar @pntrows))/2.0,
					  List::Util::sum @$detml[@pntrows] )
				       :
				       $mynull )
			    # BG_MAP: sum; null if exp_map<=0
			    ->writecol("BG_MAP", {rows=>$thisrow},
				       (defined($tmpexpmap) && $tmpexpmap>0)
				       ?
				       (List::Util::sum @$bgmap[@pntrows])
				       :
				       $mynull)
			    # EXP_MAP: sum; null if negative
			    ->writecol("EXP_MAP", {rows=>$thisrow},
				       (defined($tmpexpmap) && $tmpexpmap>0)
				       ?
				       $tmpexpmap
				       :
				       $mynull)
			    # FLUX: exposure-weighted sum;
			    #       null if exp_map<=0 or m.frac<thr.
			    ->writecol("FLUX", {rows=>$thisrow},
				       (defined($tmpmaskfrac) &&
					$tmpmaskfrac>=$maskthr &&
					defined($tmpexpmap) &&
					$tmpexpmap>0)
				       ?
				       $tmpflux
				       :
				       $mynull)
			    # FLUX_ERR: exposure-weighted square root of
			    #           quadratic sum or null
			    ->writecol("FLUX_ERR", {rows=>$thisrow},
				       (defined($tmpmaskfrac) &&
					$tmpmaskfrac>=$maskthr &&
					defined($tmpexpmap) &&
					$tmpexpmap>0)
				       ?
				       $tmpfluxerr
				       :
				       $mynull )
			    # RATE: sum; null if exp_map<=0 or maskfrac<thresh.
			    ->writecol("RATE", {rows=>$thisrow},
				       (defined($tmpmaskfrac) &&
					$tmpmaskfrac>=$maskthr &&
					defined($tmpexpmap) &&
					$tmpexpmap>0)
				       ?
				       (List::Util::sum @$rate[@pntrows])
				       :
				       $mynull)
			    # RATE_ERR: square root of quadratic sum or null
			    ->writecol("RATE_ERR", {rows=>$thisrow},
				       (defined($tmpmaskfrac) &&
					$tmpmaskfrac>=$maskthr &&
					defined($tmpexpmap) &&
					$tmpexpmap>0)
				       ?
				       (sqrt(List::Util::sum 
					 ( map { $_*$_ } (@$rateerr[@pntrows]) )
					))
				       :
				       $mynull )
			    # RAWX, RAWY, OFFAX, CCDNR: null (pointing-depend.)
			    ->writecol("RAWX",       {rows=>$thisrow}, $mynull)
			    ->writecol("RAWY",       {rows=>$thisrow}, $mynull)
			    ->writecol("OFFAX",      {rows=>$thisrow}, $mynull)
			    ->writecol("CCDNR",      {rows=>$thisrow}, $mynull)
			    # HR?, HR?_ERR: unchanged (null)
			    #
			    # MASKFRAC: maximum of pointings
			    ->writecol("MASKFRAC", {rows=>$thisrow},
				       $tmpmaskfrac)
			    # EEF: unchanged
			    #
			    # VIGNETTING: NULL
			    ->writecol("VIGNETTING", {rows=>$thisrow}, $mynull )
			    # ONTIME: unchanged
			    ;

		    ############################################################
		    ## II. SUMMARY ROW PER INSTRUMENT
		    } else {                                        # ID_BAND==0

			# temporary value of MASKFRAC: minimum of maxima
			$tmpmaskfrac = List::Util::min @instmaskfracs;

			# COLUMNS ##############################################
			$fits
			    # SCTS: sum; null if exp_map<=0 or maskfrac<thresh.
			    ->writecol("SCTS", {rows=>$thisrow},
				       (defined($tmpmaskfrac) &&
					$tmpmaskfrac>=$maskthr &&
					defined($tmpexpmap) &&
					$tmpexpmap>0)
				       ?
				       (List::Util::sum 
					@$scts[@{$instrows{$nr}}])
				       :
				       $mynull)
			    # SCTS_ERR: square root of quadratic sum or null
			    ->writecol("SCTS_ERR", {rows=>$thisrow},
				       (defined($tmpmaskfrac) &&
					$tmpmaskfrac>=$maskthr &&
					defined($tmpexpmap) &&
					$tmpexpmap>0)
				       ?
				       (sqrt(List::Util::sum 
					     ( map {(defined($_)) ? $_*$_ : 0.0}
					       (@$sctserr[@{$instrows{$nr}}])
					     ) ))
				       :
				       $mynull )
			    # DET_ML: equivalent likelihood via gamma function
			    ->writecol("DET_ML", {rows=>$thisrow},
				       (defined($tmpmaskfrac) &&
					$tmpmaskfrac>=$maskthr &&
					defined($tmpexpmap) &&
					$tmpexpmap>0)
				       ?
				       likelihood(   # dofs/2, sum(likelihoods)
				 (2+($$extml[${$instrows{$nr}}[0]]>0)
 					       +(scalar @{$instrows{$nr}}))/2.0,
						    List::Util::sum 
						    @$detml[@{$instrows{$nr}}] )
				       :
				       $mynull )
			    # BG_MAP: sum; null if exp_map<=0
			    ->writecol("BG_MAP", {rows=>$thisrow},
				       (defined($tmpexpmap) && $tmpexpmap>0)
				       ?
				       (List::Util::sum
					@$bgmap[@{$instrows{$nr}}])
				       :
				       $mynull)
			    # EXP_MAP: unchanged (null)
			    #
			    # FLUX: exposure-weighted sum; null if exp_map<=0 
			    #       or maskfrac<threshold
			    ->writecol("FLUX", {rows=>$thisrow},
				       (defined($tmpmaskfrac) &&
					$tmpmaskfrac>=$maskthr &&
					defined($tmpexpmap) &&
					$tmpexpmap>0)
				       ?
				       (List::Util::sum @instfluxvals)
				       :
				       $mynull)
			    # FLUX_ERR: exposure-weighted square root of 
			    #           quadratic sum or null
			    ->writecol("FLUX_ERR", {rows=>$thisrow},
				       (defined($tmpmaskfrac) &&
					$tmpmaskfrac>=$maskthr &&
					defined($tmpexpmap) &&
					$tmpexpmap>0)
				       ?
				       (sqrt(List::Util::sum 
					     ( map {(defined($_)) ? $_*$_ : 0.0}
					       (@instfluxerrs)              ) ))
				       :
				       $mynull )
			    # RATE: sum; null if exp_map<=0 or maskfrac<thresh.
			    ->writecol("RATE", {rows=>$thisrow},
				       (defined($tmpmaskfrac) &&
					$tmpmaskfrac>=$maskthr &&
					defined($tmpexpmap) &&
					$tmpexpmap>0)
				       ?
				       (List::Util::sum 
					@$rate[@{$instrows{$nr}}])
				       :
				       $mynull)
			    # RATE_ERR: square root of quadratic sum or null
			    ->writecol("RATE_ERR", {rows=>$thisrow},
				       (defined($tmpmaskfrac) &&
					$tmpmaskfrac>=$maskthr &&
					defined($tmpexpmap) &&
					$tmpexpmap>0)
				       ?
				       (sqrt(List::Util::sum 
					     ( map {(defined($_)) ? $_*$_ : 0.0}
					       (@$rateerr[@{$instrows{$nr}}])
					     ) ))
				       :
				       $mynull )
			    # RAWX, RAWY, OFFAX, CCDNR: null in summary rows
			    ->writecol("RAWX",       {rows=>$thisrow}, $mynull)
			    ->writecol("RAWY",       {rows=>$thisrow}, $mynull)
			    ->writecol("OFFAX",      {rows=>$thisrow}, $mynull)
			    ->writecol("CCDNR",      {rows=>$thisrow}, $mynull)
			    # HR?, HR?_ERR: unchanged
			    #
			    # MASKFRAC: minimum of maxima (or vice versa ;-) )
			    ->writecol("MASKFRAC", {rows=>$thisrow},
				       $tmpmaskfrac)
			    # EEF, VIGNETTING, ONTIME: unchanged
			    ;

		    }                                              # end ID_BAND

		}                              ### end loop over instrument rows

	    } else {                               # end  if instrows{$nr} found
		## instrument rows without detections:
		# set RAWX, RAWY, OFFAX, CCDNR to null
		@newvals = ($mynull)x($nbands+1);
		$srtrow = @srcinds[(grep
				    { "0"."$$idinst[$srcinds[$_]]" == $nr }
				    0..$#srcinds) + 1];
		$fits->writecol("RAWX",
				{rows=>[$srtrow,$srtrow+$nbands]},
				\@newvals);
	    }
		    
	}                                          ### end loop over instruments


	###################################################################
	## III. TOTAL SUMMARY ROW - unchanged at the moment
#	$thisrow = $srcinds[0]+1;



        ## DELETE ADDITIONAL ROWS

        # renew index list of rows with ID_INST > 3
	$fits
	    ->readcol("ML_ID_SRC",  {}, my $newmlidsrc)
	    ->readcol("ID_INST",    {}, my $newidinst )
	    ->readcol("ID_BAND",    {}, my $newidband )
	    ;
	# delete rows one by one - which might be inefficient ...
	for my $delrow
	    (reverse(grep { $$newmlidsrc[$_] eq $srcid 
				&& "0"."$$newidinst[$_] " > 3 
				&& "0"."$$newidband[$_] " > 0 }
		     (0..$#{$newmlidsrc})))
	{
	    $fits->delrows([$delrow+1]);
	}

    }                                                  ### end loop over sources

    # add number of detections and update history keyword of primary header
    $fits
	->readcol("ID_INST",    {}, my $newidinst )
	->readcol("ID_BAND",    {}, my $newidband )
	    ;
    ( @instinds ) = grep { $$newidinst[$_] ne 0 || $$newidband[$_] ne 0 }
                           0..$#{$newidinst};
    ($sec,$min,$hour,$day,$mon,$year) = localtime();
    $fits
	->move(-1)
	->writekey("NDETECT",   $#{$newidinst}-$#instinds,
		   "Total number of detections")
	->writekey("LIKEMIN",   $mindetml,
		   "Minimum detection likelihood to include a source");
    if (defined $headercomment) {
	$fits->writekey("COMMENT", $headercomment); 
    }
    $fits->writekey("HISTORY","Updated by ".qx/edetect_stack -v/."at ".
                    sprintf("%04i-%02i-%02iT%02i:%02i:%02i",
                            $year+1900,$mon+1,$day,$hour,${min},${sec}));

    # close the file
    $fits->close();

    # copy output file to output summary file name
    copy($outlist, $outlistsum)
        or die SAS::error("FileNotCopied", "Could not copy $inlist to ".
                          "$outlist. Please make sure that you have read ".
                          "and write access.");

    ## summary file
    # open fits file
    $fits = SimpleFITS->open($outlistsum, access=>"write", type=>"table");
    ($fits->status() == 0) 
        or SAS::error("FileNotFound", "Could not open $outlist. ".
                      "File not found or unreadable.");

    # delete rows one by one - which might be inefficient ...
    $fits->delrows([$_+1]) for (reverse(@instinds));

    # close the file
    $fits->close();

    # information
    SAS::message($SAS::AppMsg, $SAS::VerboseMsg, 
	     "Final source list comprises ".($#{$newidinst}-$#instinds)
		 ." detections.");


################################################################################
### LIKELIHOOD
# return the negative natural logarithm of the complement of the incomplete
# gamma function: -ln(1-gammainc(arg1,arg2))
# WARNING: no sanity checks on input are performed
# Code follows emldetect/edetect_gen.f90/gammq

sub likelihood {

    # first argument: 0.5 * number of the degrees of freedom
    my $hdof = $_[0];
    # second argument: sum of individual likelihoods
    my $like = $_[1];
    # result: likelihood corresponding to two degrees of freedom
    my $ltwo;

    # no negative arguments
    if ($hdof <= 0. || $like <= 0.) {
	$ltwo = 0.;
    } else {

	# iteration / convergence criteria
	my $nmaxit = 1000;
	my $convrg = 3e-7;
	my $lowval = 1e-30;
	my $itres;

	# coefficients for approximation:
	my @coeff = (76.18009173,  -86.50532033,  24.01409822,
                     -1.231739516, 1.20858003e-3, -5.36382e-6);
	my $increm = 1.0;

	## ln(gamma)
	$ltwo = ($hdof < 1.0) ? $hdof : $hdof-1.0;

	# integration 
	$increm += $coeff[$_]/($ltwo+$_+1.0) for (0..5);

	# intermediate value of $ltwo
	$ltwo = ($ltwo+0.5)*log($ltwo+5.5) - $ltwo-5.5 
	    + log(2.50662827465*$increm);
	$ltwo -= log($hdof) if $hdof<1.0;

	## iteration
	$like = $convrg if $like < $convrg;

	# branch 1:
	if ($like < $hdof+1.0) {
	    $itres = 1/$hdof;
	    my $del = $itres;
	    my $niter = 0;
	    do {
		$niter += 1;
		$del = $del * $like / ($hdof+$niter);
		$itres += $del;
	    } until (abs($del)<$convrg*abs($itres) || $niter==$nmaxit);
	# result:
	$ltwo = -log( 1.0 - $itres * exp( $hdof*log($like) - $like - $ltwo ) );

	# branch 2:
	} else {
	    $itres = 1.0;   # temporary start value, overwritten later-on
	    my $itold = 0.0;
	    my $a0 = 1.0;
	    my $a1 = $like;
	    my $b0 = 0.0;
	    my $b1 = 1.0;
	    my $fac = 1.0;

	    my $niter = 0;
	    do {
		$itold = $itres if ($a1 != 0);
		$niter += 1;
		$a0 = ($a1 + $a0*($niter-$hdof)) * $fac;
		$b0 = ($b1 + $b0*($niter-$hdof)) * $fac;
		$a1 = $like*$a0 + $niter*$fac*$a1;
		$b1 = $like*$b0 + $niter*$fac*$b1;
		if ($a1 != 0.0) {
		    $fac = 1.0/$a1;
		    $itres = $b1*$fac;
		}
	    } until (abs(($itres-$itold)/$itres)<$convrg || $niter==$nmaxit);
	# result:
	$ltwo = $like - $hdof*log($like) + $ltwo - log($itres);

	}

    }

    return $ltwo;

}                                                             ### END LIKELIHOOD

################################################################################

}

1;                                                      ### END STACK_SOURCELIST
