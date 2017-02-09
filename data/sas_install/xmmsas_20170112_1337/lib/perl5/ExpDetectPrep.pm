package ExpDetectPrep;
use strict;
use English;
use Carp;
use vars
  qw(@ISA $VERSION $name $author $date $version @instList $numberOfStreams);
###@ISA = qw(Module);
# Commented out - IMS 2006-09-27.
use ModuleResources;
use ModuleUtil;

use SSCLib;	# for isoptdefined()
# our $Testflag;	# for run() 
# our $Taskname;	# for sscwarn(), sscnote(), quit()
# our @Tmpfiles2kill;	# for quit()
# our %Flagglobal;	# $Flagglobal{'cleanup'} for quit() 

# Declare identity, version, author, date, etc.
$name    = __PACKAGE__;
$VERSION = '0.17';
$version = $VERSION;
$author  = 'Richard West,Dean Hinshaw,Duncan John Fyfe,Richard Saxton,Ian Stewart';
$date    = '2006-05-18';

#
# ChangeLog
# =========
#
# version 0.17 - 2006-07-12
# ------------
#
# + Merged image ONTIME correction changed to use addattribute.  This will ensure
#   correction is applied by executable logs.
# + XID merged exposure map was made as weighted addition of N bands.  This 
#   leaves the exposure map values too big.  Use farith to divide weighted map by N to 
#   get a better value.
#
# version 0.16 - 2006-05-18
# ------------
#
# + When more than one exposure is selected for source detection 
# gtimerge the selected images and write the new ONTIME into the
# merged image.  This is so the proper ONTIME can be propogated to
# the sources.
#
# version 0.15 - 2006-03-22
# ------------
#
# + Corrected keepSafe parameters
#
# version 0.14 - 2006-02-21
# ------------
#
# + Images  supplied to the band 8 imweightadd merges are
#   written to a file to be used with emosaic in ImageMerge module.
#   Using the imweightadd output looses the indidual image keywords.
#
# version 0.13 - 2006-02-07 DJF
# ------------
#
# + Added test to make sure files exist before passing to imweightadd
# + Fixed bad use of info() and foo().  This depends on info returning true. This is not guarenteed.
#
# version 0.12 - 2005-11-14 IMS
# ------------
#
# + Incorporated DJF's shortening of some intermediate file names.
#
# version 0.11 - 2005-11-04 IMS
# ------------
#
# + Slightly modified it to fix a bug which prevented band 9 images/exp maps from being made.
#
# version 0.10 - 2005-11-04 IMS
# ------------
#
# + Exposures for which flare screening was not performed are no longer considered for merging.
#
# version 0.09 - 2005-11-02 IMS
# ------------
#
# + Non-vig exposure maps (both those read and the newly created merged version) now have shorter content strings (thus shorter names).
# + Merged exposure map now also made for band 8 (necessary for ImageMerge).
# + Merged band 8 image is now made in the same way as the (new) merged band 8 exp map.
#
# version 0.08 - 2005-10-31 IMS
# ------------
#
# + XID images and exposure maps are now also being made (by adding merged images and exp maps for bands 2, 3 and 4).
#
# version 0.07 - 2005-10-28 IMS
# ------------
#
# + Altered things so that the band-8 imweightadd is not called if there are no input images. (I hope.)
#
# version 0.06 - 2005-10-21 RGW
# ------------
#
# + Make sure we look for FITS product images not intermediate files when creating the band 8 merged image
#
# version 0.05 - 2005-10-14 IMS
# ------------
#
# + Merged image (as intermediate file) now made for band 8 as requested by ACS.
# + Added copyFile to the list of used ModuleResources subs.
#
# version 0.04 - 2005-09-21 IMS
# ------------
#
# + Slight bug fixing, so it will run.
#
# version 0.03 - 2005-09-20 IMS
# ------------
#
# + Restored imweightadd parameters to 0.01 format. There's method in my madness.
# + Constituent exposure ids are now written as kwds to merged datasets. 
#
# version 0.02 - 2005-08-15 RGW
# ------------
#
# + hacked argument to imweightadd (withweights -> calculateweights)
# + changed circumstances under which the module is ignored (only ignored if
#    all image creation modules are ignored)
#
# version 0.01 - 2005-06-12 IMS
# ------------
#
# + First draft.

# Declare list of instruments this module is interested in
@instList = qw(emos1 emos2 epn);

#my $energyBands = [qw(1 2 3 4 5)];
my $xidBands = {'epn' => [qw(2 3 4)], 'emos1' => [qw(2 3 4)], 'emos2' => [qw(2 3 4)] };
### This list of xid bands ought to be obtained from a subroutine call because it is also needed in ExpDetect. IMS 2005-10-31.

# Number of streams
sub numberOfStreams
{
    1;
}

#
sub evaluateRules
{
    my $inst = thisInstrument;
    if ( $inst eq 'epn' )
    {

        # PN Ignore condition
        return ignore()
          if (
	      allIgnored(
                module => 'MakePNImage'
                , instrument => thisInstrument
            )
          );

        # PN Start conditions
        start()
          if (
            allComplete(
                module => 'MakePNImage'
                , instrument => thisInstrument
            )
          );
    }
    else
    {

        # MOS Ignore condition
        return ignore()
          if (
            allIgnored(
                module => 'MakeMOSImage'
                , instrument => thisInstrument
            )
          );

        # MOS Start conditions
        start()
          if (
            allComplete(
                module => 'MakeMOSImage'
                , instrument => thisInstrument
            )
          );
    }
}

#
sub performAction
{
    info("Module version number: $version");

    my @expids = listExposures(
        instrument => thisInstrument
    );

    my $existsargwithattributecomment = SSCLib::isoptdefined('addattribute', 'withattributecomment');	# 1 (true) if yes, namely old version (perhaps the versions prior to 2.0).

    # Set which bands to use for source searching
    my @bandList = ( 1, 2, 3, 4, 5, 8 );

    # If more than 1 exposure, possibly with different filters,
    # find which filter has the longest total exposure:

    my %exposureLengths;
    my (%filters, %modes);
    foreach my $exp_id (@expids)
    {
        my $mode = getExposureProperty(
            instrument => thisInstrument
            , exp_id => $exp_id
            , name => 'datamode'
        );
        if ( thisInstrument eq 'epn' && $mode =~ /Small/ )
        {
            info("Will not perform source detection for PN mode $mode");
			next;
        }
#### filter out other modes?

        my $rawim = findFile(
            class => 'product'
            , instrument => thisInstrument
            , exp_id => $exp_id
            , band => 1
            , content => 'EPIC image'
            , 'format' => 'FITS'
        );
        if ( !$rawim )
        {
            info("Can't find a band 1 image for this exposure - won't perform source detection on it");
	    next;
        }
        my $flareScreened;
        if (
            hasFITSKeyword(
                file => $rawim
                , extension => 'PRIMARY'
                , keyword => 'BKGDSCRN'
            )
          )
        {
            $flareScreened = readFITSKeyword(
                file => $rawim
                , extension => 'PRIMARY'
                , keyword => 'BKGDSCRN'
            );
            undef $flareScreened if $flareScreened eq 'F';
        }
        if ( !$flareScreened )
        {
            info("Images were not flare screened - source detection not performed");
	    next;
        }

        my $filter = getExposureProperty(
            instrument => thisInstrument
	    , exp_id => $exp_id
            , name => 'filter'
        );
        unless ( $filter =~ /(Thin|Medium|Thick|Open)/ )
        {
            info("Could not match filter for energy conversion factor ($filter)");
	    next;
#            return exception();
        }
        $filter = $1;
        $filters{$exp_id} = $filter;
        $modes{$exp_id} = $mode;

        my $exposureLength = getExposureProperty(
            instrument => thisInstrument
            , exp_id => $exp_id
            , name => 'exp_duration'
        );

		$exposureLengths{$filter}{$mode} += $exposureLength;
    } # end loop over exposure ids

    return success() if (keys(%exposureLengths)<=0);

    my $maxExposureLength = 0;
    my ($chosenFilter, $chosenMode);
    foreach my $filter (keys(%exposureLengths))
    {
        foreach my $mode (keys(%{$exposureLengths{$filter}}))
        {
            if ($exposureLengths{$filter}{$mode} > $maxExposureLength)
            {
                $maxExposureLength = $exposureLengths{$filter}{$mode};
                $chosenFilter = $filter;
                $chosenMode = $mode;
            }
        }
    }
    info("Chosen filter $chosenFilter");
    info("Chosen mode $chosenMode");

    my $totalExposure = $exposureLengths{$chosenFilter}{$chosenMode};

    my $tempset = newFile(
        class => 'intermediate'
        , content => 'Generic temporary dataset'
    );

    foreach my $band (@bandList)
    {
        my (@rawImList, @expImList,@expidList);

        foreach my $exp_id (@expids)
        {
			next unless (($filters{$exp_id} eq $chosenFilter)
			 && ( $modes{$exp_id} eq $chosenMode ) );

            my $rawim = findFile(
                class => 'product'
                , instrument => thisInstrument
                , exp_id => $exp_id
                , band => $band
                , content => 'EPIC image'
				, 'format' => 'FITS'
            );
            my $expim = findFile(
                class => 'product'
                , instrument => thisInstrument
                , exp_id => $exp_id
                , band => $band
                , content => 'EPIC exposure map'
				, 'format' => 'FITS'
            );

			next unless ( $rawim && fileExists( file => $rawim ) 
				&& $expim && fileExists( file => $expim ) 
			);

            push( @rawImList, $rawim );
            push( @expImList, $expim );
            push( @expidList, $exp_id );

        } # end loop over $exp_id

		unless ( @rawImList )
		{
			info("No images found");
			next;
		}

        my $mergedRawim = newFile(
            class => 'intermediate'
            , instrument => thisInstrument
            , band => $band
            , content => 'merged image'
        );
        doCommand(
            'imweightadd'
            , imagesets => [@rawImList]
            , withweights => 'no'
            , outimageset => $mergedRawim
            , tempset => $tempset
          )
          or return exception();

	# When merging more than one exposure calculate new ONTIME and EXPOSURE values 
	# and write this into the merged image.
	if (@rawImList > 1)
	{
		info("Calculating corrected ONTIME for merged images");
		info("ModuleUtil::ontimeFix(",$mergedRawim , @rawImList,'"');	#" (Comment just for Emacs)
		my %ontime = ModuleUtil::ontimeFix( $mergedRawim , @rawImList );
		Msg->mark();
		Msg->debug( Data::Dumper::Dumper( \%ontime ) );
		if (my @ontime = sort( grep /ONTIME/,(keys %ontime)) )
		{
			my $num = scalar(@ontime);
			my $numnum = $num+1;
			my @attcomment = ('Sum of GTIs for a particular CCD') x $num;
			push @attcomment , 'max of ONTIMEnn values' ;
			my @wattcomment = ('Y') x $numnum;
			my @atttype = ('real') x $numnum;
			my @attname = (@ontime , 'EXPOSURE');

			my @realval = (@ontime{@ontime} , $ontime{EXPOSURE});
			use Data::Dumper qw();

			if ($existsargwithattributecomment) {
			doCommand('addattribute'
				, set => $mergedRawim
				,attributename => \@attname
				,attributetype => \@atttype
				,withattributecomment => \@wattcomment
				,attributecomment => \@attcomment
				,realvalue => \@realval
			) or return exception();
			} else {
			doCommand('addattribute'
				, set => $mergedRawim
				,attributename => \@attname
				,attributetype => \@atttype
				,attributecomment => \@attcomment
				,realvalue => \@realval
			) or return exception();
		        }
		}

	}
		# Write the filenames merged to a file so we can use them
		# again with emosaic.
		my @rawlistdtl = ( class => 'intermediate'
			, content => 'raw image list'
			, instrument => thisInstrument
			, band => $band
			, format => 'ASCII'
		);

		unless ( ModuleUtil::keepSafe ( file_identifier => \@rawlistdtl , text => \@rawImList )  )
		{
			info("Unable to store raw image list for later use.");
			return exception();
		}

        doCommand(
            'addattribute', set => $mergedRawim.":PRIMARY"
            , attributename => 'EXPOSURE'
            , attributetype => 'real'
            , realvalue => $totalExposure
          )
          or return exception();

        foreach my $i (0 .. $#expidList)
        {
            my $exp_id = $expidList[$i];
            my $kwd_str = 'EXPID'.sprintf("%2.2d", $i+1);
            doCommand(
                'addattribute', set => $mergedRawim.":PRIMARY"
                , attributename => $kwd_str
                , attributetype => 'string'
                , stringvalue => $exp_id
              )
              or return exception();
        }

        my $mergedExpim = newFile(
            class => 'intermediate'
            , instrument => thisInstrument
            , band => $band
            , content => 'merged exposure map'
        );
        doCommand(
            'imweightadd'
            , imagesets => [@expImList]
            , withweights => 'no'
            , outimageset => $mergedExpim
            , tempset => $tempset
        ) or return exception();


		# Write the filenames merged to a file so we can use them
		# again with emosaic.
		my @explistdtl = ( class => 'intermediate'
			, content => 'exposure map list'
			, instrument => thisInstrument
			, band => $band
			, format => 'ASCII'
		);

		unless ( ModuleUtil::keepSafe ( file_identifier => \@explistdtl , text => \@expImList ) )
		{
			info("Unable to store exposure map list for later use.");
			return exception();
		}

        doCommand(
            'addattribute', set => $mergedExpim.":PRIMARY"
            , attributename => 'EXPOSURE'
            , attributetype => 'real'
            , realvalue => $totalExposure
          )
          or return exception();

        foreach my $i (0 .. $#expidList)
        {
            my $exp_id = $expidList[$i];
            my $kwd_str = 'EXPID'.sprintf("%2.2d", $i+1);
            doCommand(
                'addattribute', set => $mergedExpim.":PRIMARY"
                , attributename => $kwd_str
                , attributetype => 'string'
                , stringvalue => $exp_id
              )
              or return exception();
        }

        next if ($band eq '8'); # band 8 is just for rawimage and expmap.

        my (@flatExpImList, @imEventList);
        foreach my $exp_id (@expids)
        {
	    next unless ($filters{$exp_id} eq $chosenFilter
			 && $modes{$exp_id} eq $chosenMode);

            my $flatExpIm = findFile(
                class => 'intermediate'
                , instrument => thisInstrument
                , exp_id => $exp_id
                , band => $band
                , content => 'non-vig exposure map'
            );
            my $filteredList = findFile(
                class => 'intermediate'
                , instrument => thisInstrument
                , exp_id => $exp_id
                , band => $band
                , content => 'image event list'
            );

	    next unless $flatExpIm && $filteredList;

            push( @flatExpImList, $flatExpIm );
            push( @imEventList, $filteredList );
        } # end loop over $exp_id

		unless (@flatExpImList)
		{
			info("No flat expmaps found");
			next;
		}

        my $mergedFlatExpim = newFile(
            class => 'intermediate'
            , instrument => thisInstrument
            , band => $band
            , content => 'merged non-vig exp map'
        );
        doCommand(
            'imweightadd'
            , imagesets => [@flatExpImList]
            , withweights => 'no'
            , outimageset => $mergedFlatExpim
            , tempset => $tempset
          )
          or return exception();

		# Write the filenames merged to a file so we can use them
		# again with emosaic.

        doCommand(
            'addattribute', set => $mergedFlatExpim.":PRIMARY"
            , attributename => 'EXPOSURE'
            , attributetype => 'real'
            , realvalue => $totalExposure
          )
          or return exception();

        foreach my $i (0 .. $#expidList)
        {
            my $exp_id = $expidList[$i];
            my $kwd_str = 'EXPID'.sprintf("%2.2d", $i+1);
            doCommand(
                'addattribute', set => $mergedFlatExpim.":PRIMARY"
                , attributename => $kwd_str
                , attributetype => 'string'
                , stringvalue => $exp_id
              )
              or return exception();
        }

        my $mergedFilteredList = newFile(
            class => 'intermediate'
            , instrument => thisInstrument
            , band => $band
            , content => 'image merged event list'
        );
        if (@imEventList==1)
        {
            copyFile(
                source => $imEventList[0]
                , destination => $mergedFilteredList
            );
        }
        elsif(@imEventList==2) 
        {
            doCommand(
                'merge'
                , set1 => $imEventList[0]
                , set2 => $imEventList[1]
                , outset => $mergedFilteredList
              )
              or return exception();
	} else {
	    my $prevFile=shift(@imEventList);
	    my $idx=0;

            foreach my $file (splice(@imEventList, 2))
            {
		my $nextFile=newFile(class => 'intermediate',
				     content => 'Intermediate merged event list',
				     src_num => $idx
				     );
		$idx++;

                doCommand('merge',
			  set1 => $prevFile,
			  set2 => $file,
			  outset => $nextFile
                  )
                  or return exception();

		$prevFile=$nextFile;
            }
	    
	    copyFile(source => $prevFile,
		     destination => $mergedFilteredList);
        }

        foreach my $i (0 .. $#expidList)
        {
            my $exp_id = $expidList[$i];
            my $kwd_str = 'EXPID'.sprintf("%2.2d", $i+1);
            doCommand(
                'addattribute', set => $mergedFilteredList
                , attributename => $kwd_str
                , attributetype => 'string'
                , stringvalue => $exp_id
              )
              or return exception();
        }
    } # end loop over $band

    # Merged image and exposure map for band 9 (xid band). These images should be used in the second call to emldetect in ExpDetect.
    my @rawImList=();
    my @expImList=();
    my $inst = thisInstrument;
    my @xidBandsThisInst = @{$xidBands->{$inst}};

    foreach my $band (@xidBandsThisInst)
    {
        my $rawim = findFile(
            class => 'intermediate'
            , instrument => thisInstrument
            , band => $band
            , content => 'merged image'
        );
        my $expim = findFile(
            class => 'intermediate'
            , instrument => thisInstrument
            , band => $band
            , content => 'merged exposure map'
        );

		unless ( $rawim && fileExists( file => $rawim ) 
			&& $expim && fileExists( file => $expim ) 
		) {
			info("Band $band image not found");
			next;
		}
        push( @rawImList, $rawim );
        push( @expImList, $expim );
    } # end loop over $band

	unless (@rawImList == @xidBandsThisInst)
	{
    	info("\nNo or missing XID-band constituent images.");
		return success();
	}

    $tempset = newFile(
        class => 'intermediate'
        , content => 'Generic temporary dataset'
    );
    my $mergedRawim = newFile(
        class => 'intermediate'
        , instrument => thisInstrument
        , band => 9
        , content => 'merged image'
    );
    doCommand(
        'imweightadd'
        , imagesets => [@rawImList]
        , withweights => 'no'
        , outimageset => $mergedRawim
        , tempset => $tempset
      )
      or return exception();

    my $addedExpim = newFile(
        class => 'intermediate'
        , instrument => thisInstrument
        , band => 9
        , content => 'added exposure map'
    );
    my $mergedExpim = newFile(
        class => 'intermediate'
        , instrument => thisInstrument
        , band => 9
        , content => 'merged exposure map'
    );


    doCommand(
        'imweightadd'
        , imagesets => [@expImList]
        , withweights => 'no'
        , outimageset => $addedExpim
        , tempset => $tempset
    ) or return exception();

	my $div = @expImList;
	doCommand('farith'
		,infil1 => $addedExpim
		,infil2 => $div
		,outfil => $mergedExpim
		,ops => 'DIV'
    ) or return exception();

    # Raise success flag
    return success();
}
1;
