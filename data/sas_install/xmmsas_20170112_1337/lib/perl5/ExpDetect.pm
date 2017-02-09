package ExpDetect;
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
$VERSION = '2.18';
$version = $VERSION;
$author  = 'Richard West,Dean Hinshaw,Duncan John Fyfe,Richard Saxton,Ian Stewart';
$date    = '2006-07-13';

#
# ChangeLog
# =========
#
# version 2.18 - 2006-07-13 DJF
# ------------
#
# + Saving image information for later emosaic use was using epic instrument
#   rather than individual instrument name in filename 
#
# version 2.17 - 2006-07-11 DJF
# ------------
#
# + Detection mask promoted to a full product.  Without the detection mask there is no
#   obvious means of determining why no sources were detected with a non-zero exposure.
#
# version 2.16 - 2006-03-22 DJF
# ------------
#
# + Corrected parameters to keepSafe function
#
# version 2.15 - 2006-03-08 DJF
# ------------
#
# + Changed eboxdetect likemin to 5.
# + esensemap likemin set to that of X as advised by Y
#
# version 2.14 - 2006-02-21 DJF
# ------------
#
# + Exposure maps which are supplied to the band 8 imweightadd image are
#   written to a file to be used with emosaic in ImageMerge module.
#   Using the imweightadd output looses the indidual image keywords.
#
# version 2.13 - 2005-11-29 IMS
# ------------
# + Value of emask parameter --threshold1 changed from 0.05 to 0.5
#
# version 2.12 - 2005-11-04 DJF
# ------------
# + Changed 'merged bkg' to 'merged background' for band 8 images to make it consistent with ImageMerge module.
#
# version 2.11 - 2005-11-03 IMS
# ------------
#
# + Fixed a bug in the sub isInList.
# + The second call to emldetect now proceeds only if there are the same number of image files as ecfs.
#
# version 2.10 - 2005-11-02 IMS
# ------------
#
# + Non-vig exposure map now has a shorter content string (thus shorter name).
# + No longer make PNG products for bkg maps in bands 1-5.
# + Band 8 fits bkg map changed from product to intermediate.
# + Band 8 bkg map PNG product abolished.
#
# version 2.09 - 2005-10-31 IMS
# ------------
#
# + Updated task parameter values according to scripts sent by GL on 23 Oct 05.
# + XID (merged-exposure) bkg maps now being made.
# + Final emldetect call now uses XID images, exposure maps etc made in the ExpDetectPrep module.
# + 'Observation' changed to 'merged' in the content string for bkg maps.
# + Sensitivity maps now being made.
#
# version 2.08 - 2005-10-20 IMS
# ------------
#
# + Keywords listing the constituent exposure ids are now written to box and mldetect source list headers.
# + Same now also written to background maps.
# + Added GIFtoPNG to list of used ModuleResources subroutines.
# + The non-vignetted rather than the vignetted exp map is now sent to emask.
#
# version 2.07 - 2005-10-19 RGW
# ------------
#
# + shortened name of intermediate EPIC observation background map files (80-character filename limits nibbles the privates yet again).
#
# version 2.06 - 2005-09-23 RGW
# ------------
#
# + deal gracefully with cases where merged maps don't exist for an instrument
#
# version 2.05 - 2005-09-21 IMS
# ------------
#
# + Some debugging done, so it will run.
#
# version 2.04 - 2005-09-20 IMS
# ------------
#
# + FITS background map products are now also being made for band 8.
# + PNG background maps now made for bands 1-5, 8.
# + Slight relocation of the generation of the band 1-5 background map names.
#
# version 2.03 - 2005-09-14 IMS
# ------------
#
# + The first emldetect output (contains info for bands 1-5) is now made the product, rather than the second (which just contains band 9 info).
#
# version 2.02 - 2005-08-16 RGW
# ------------
#
# + handling of lists of mask images corrected
# + changed spline map to a product rather than intermediate
#
# version 2.01 - 2005-07-12 IMS
# ------------
#
# + All instrument-specific parts made non-instrument-specific, since we are now doing a single EPIC source detection.
# + $numberOfStreams=1 instead of =numberOfExposures().
# + evaluateRules changed to reflect new prior module ExpDetectPrep.
# + $exp_id and $mode are no longer necessary (this processing is now done in ExpDetectPrep).
# + Images, exp maps and filtered source lists which have been merged in ExpDetectPrep are now read as inputs rather than single-exposure ones. (If there's only 1 exposure per inst+filter combination, ExpDetectPrep copies the single-exposure image/expmap/list to the 'merged' name.)
# + Non-empty $filteredList is now necessary for push of $rawim, $expim etc into lists.
# + Filter is now read from the band-0 merged source list for each instrument.
# + Det mask made for each instrument and added to list @maskImList.
# + Parameter settings are those recommended by GL on 15 Jun 2005.
# + XID now added in a separate, final call to emldetect.
# + Non-vignetted, merged exposure map is now also used (supplied to esplinemap).
#
# + ***>>> NOTE! <<<*** esensmap invocation temporarily commented out. What to do? Alternatives: (i) put in a loop over insts; (ii) single call to esensitivity to make single epic sens map.
#
# version 2.00 - 2005-05-09 DJF
# ------------
#
# + Add explicit perl module headers.  Previously these were supplied
#   at compile time.  This will make debugging and extending the modules
#   through additional perl libraries easier.
# + Code layout made more uniform with perltidy
# + Standardized date format (ccyy-mm-dd)
# + Standardized author list to use comma separator
# + Make use of perl $VERSION magic.  Now $Version = version = ''
#
# Version 1.38 - 2004-03-03
# ------------
#
# + Moved energy conversion factors into ModuleResources.
# + Moved hardness bands to ModuleResources.
# + Changed energyBands() match changes in ModuleResources.
#
# Version 1.37 - 2004-02-19
# ------------
#
# +  Fixed evaluateRules cross-instrument dependance
#
# Version 1.36 - 2004-01-14
# ------------
#
# + Changed dependance on MakeImage to MakeMOSImage and MakePNImage
#
# Version 1.35 - 2003-12-09
# ------------
#
# + Adapted doCommand to use anonymous lists for list parameters
#
# Version 1.34 - 2003-06-13 (RDS)
# ------------
#
# + New ECFs for latest QE files
#
# Version 1.33 - 2002-09-16 (DJF)
# ------------
#
# + Remove code for testing spline node variations
#
# Version 1.32 - 2002-08-27 (DJF)
# ------------
#
# + Fix background image list for testing of esplinemap
#
# Version 1.31 - 2002-08-23 (DJF)
# ------------
#
# + Try different node values in esplinemap
#
# Version 1.30 - 2002-08-16 (DJF)
# ------------
#
# + Change to esplinemap parameters.  Use scut = 0.001 rather than default
# + Added call to esplinemap and eboxdetect for different number of nodes.
#
# Version 1.29 - 2002-06-10 (DJF)
# ------------
#
# + Incorporating catalogue pipeline improvements into the production pipeline
#
#   (See patch versions below for further details)
#
# Version 1.28.12 - 2002-05-08 (DH)
# ---------------
#
# + Remove eposcorr call for ml exposure source lists.
#
# Version 1.28.11 - 2002-05-02 (DH)
# ---------------
#
# + Add pimin and pimax parameters to the esplinemap call.
#
# Version 1.28.10 - 2002-04-30 (DH)
# ---------------
#
# + Fix typo.
#
# Version 1.28.9 - 2002-04-26 (DH)
# --------------
#
# + Make sure implot only tries to plot FITS files.
#
# Version 1.28.8 - 2002-04-26 (DH)
# --------------
#
# + Put oot options back in esplinemap.
#
# Version 1.28.7 - 2002-04-26 (DH)
# --------------
#
# + For now remove oot options from esplinempap, unitl bug
#   is fixed.
#
# Version 1.28.6 - 2002-04-25 (DH)
# --------------
#
# + Bug fix.
#
# Version 1.28.5 - 2002-04-24 (DH)
# --------------
#
# + Shorten name of intermediate image event lists to
#   accomodate a bug in esplinemap.
#
# Version 1.28.4 - 2002-04-19 (DH)
# --------------
#
# + Add ml list and exp map graphics products.
# + Add new feature in esplinemap for handling oot events.
#
# Version 1.28.3 - 2002-03-29 (DH)
# --------------
#
# + Correct spelling of eposcorr.
#
# Version 1.28.2 - 2002-03-29 (DH)
# --------------
#
# + Bug fixes for 1.28.2.
# + For extended source detection, need to do a call to eboxdetect
#   as well as emldetect.
# + Add in call to eposscorr to correct source positions
#
# Version 1.28.1 - 2002-03-28 (DH)
# --------------
#
# + Call to esky2det and extended source detection on xid band.
#
# Version 1.28 - 2002-03-28 (DH)
# ------------
#
# + BKGDSCRN keyword now always written (either T or F).  Comment
#   fixed.
#
# Version 1.27 - 2002-02-25 (DH)
# ------------
#
# + Put pn band 1 image back into source detection.
#
# Version 1.26 - 2002-02-08 (DH)
# ------------
#
# + Fix bug in esplinemap call.  The parameter idband should be the band
#   reference number, rather than the actual band number itself.
#
# Version 1.25 - 2002-02-08 (DH)
# ------------
#
# + Bug fixes for 1.24.
#
# Version 1.24 - 2002-02-08 (DH)
# ------------
#
# + Add keyword BKGDSCRN to products if flare GTI was applied to images.
#
# Version 1.23 - 2002-01-07 (DH)
# ------------
#
# + Don't run emldetect if the box map source list is empty.
#
# Version 1.22 - 2001-10-30 (DH)
# ------------
#
# + Put in new ECF parameters, as per SSC-LUX-TN-0059, issue 2.0.  Includes
#   values for the Open filter position.
#
# Version 1.21 - 2001-10-09 (DH)
# ------------
#
# + Fix mistake in changing parameter name hrdef in eboxdetect.
#
# Version 1.20 - 2001-10-08 (DH)
# ------------
#
# + Replace hrdef and xiddef with new parmeters which specify
#   the instrument (hrm1def, hrm2def, ...);
# + Change value of likemin parameter from 10 to 8.  Change mlmin
#   parameter to 10, whereas is was 16 or 18 depending on the number
#   of bands.
#
# Version 1.19 - 2001-10-04 (DH)
# ------------
#
# + Revert back to old ECFs of version 1.17 .
#
# Version 1.18 - 2001-10-01 (DH)
# ------------
#
# + Correct MOS think filter ECFs.  Closes SSC-SPR-2573.
#
# Version 1.17 - 2001-08-30 (DFJ)
# ------------
#
# + corrected ecf instrument name, pn -> epn
#
# Version 1.16 - 2001-08-21 (DFJ)
# ------------
#
# + Correct some miss typed energy conversion factors
#
# Version 1.15 - 2001-08-15 (DFJ)
# ------------
#
# + Apply correction to use of new xidecf parameter.
#
# Version 1.14 - 2001-08-14 (DFJ)
# ------------
#
# + Corrected energy conversion factors (see SSC-LUX-TM-0059).
# + Added XID band conversion factors (withecf) to emldetect
#
# Version 1.13 - 2001-06-04 (DH)
# ------------
#
# + Change nsplinenode of esplinemap from 10 to 16.
#
# Version 1.12 - 2001-05-30 (DH)
# ------------
#
# + Change mlmin value for emldetect task from 10 to 16 for 4 bands
#   and 18 for 5 bands.
#
# Version 1.11 - 2001-05-21 (DH)
# ------------
#
# + Change esplinemap parameter withexpimage to false, and remove
#   expimageset paramter.
#
# Version 1.10 - 2001-05-02 (DH)
# ------------
#
# + Add values for hrdef and efc parameters to eboxdetect.  Use
#   same values as for emldetect.
# + Remove pointresponse from emldetect, which has been removed
#   from the latest version.
# + Add pimin and pimax parameters to emldetect and eboxdetect.
#   Use the new energyBands function to obtain the needed values.
# + Add new xiddef parameter to emldetect, which gives which input
#   images correspond to the xidbands.
# + Fix SSC-SPR-2361.  The code was not using the proper xid bands
#   for making the sensitivity maps.
#
# Version 1.09 - 2001-03-20 (DH)
# ------------
#
# + New version of esplinemap, which no longer has an idinst
#   parameter.  So take it out.
#
# Version 1.08 - 2001-03-19 (DH)
# ------------
#
# + Do not perform source detection for PN small window modes.
#
# Version 1.07 - 2001-03-16 (DH)
# ------------
#
# + Fix bug which was introduced in 1.05/1.06 which
#   caused hrdef and idinst parameters not to set
#   in esplinemap.
# + Print out version number in performAction() for
#   tracking purposes.
#
# Version 1.06 - 2001-03-08 (DH)
# ------------
#
# + Set withxidband=true in emldetect.
# + Put energy conversion factors into emldetect.
# + Add in new 'hrdef' parameter to emldetect.
#
# Version 1.05 - 2001-03-06 (DH)
# ------------
#
# + Fix bug introduced in 1.04 which caused wrong energy
#   bands to be used to make pn sensitivity maps.
#
# + Change calling sequence for new version of esplinemap:
#	Set the idband and idinst parameters.
#	Take the default setting for scut, whose value has been
#	redefined.
#
# Version 1.04 - 2001-01-29 (DH)
# ------------
#
# + Remove energy band 1 from list of images used for source
#   detection in the pn.
#
# Version 1.01 - 2000-12-11 (DH)
# ------------
#
# + First production version.

# Declare list of instruments this module is interested in
@instList = qw(epic);

#my $energyBands = [qw(1 2 3 4 5)];
my $xidBands = {'epn' => [qw(2 3 4)], 'emos1' => [qw(2 3 4)], 'emos2' => [qw(2 3 4)] };
### This list of xid bands ought to be obtained from a subroutine call because it is also needed in ExpDetectPrep. IMS 2005-10-31.

# Number of streams
sub numberOfStreams
{
    1;
}

#
sub evaluateRules
{
    return ignore()
      if (
        allIgnored( module => 'ExpDetectPrep' )
      );

    start()
      if (
        allComplete( module => 'ExpDetectPrep' )
      );
}

#
sub performAction
{
    info("Module version number: $version");

    #
    my (
        @rawImList, @expImList, @flatExpImList, @bkgImList
        , @ebandlo, @ebandhi, @imEventList, @maskImList
        , @instList, @maskImLongList
        , @bandLongList, @hardnessLongList, @ecfList
        , @xidEbandlo, @xidEbandhi, @xidEcfList
        , %band8constituents, %band9constituents, %expidKwds
    );

    my $existsargwithattributecomment = SSCLib::isoptdefined('addattribute', 'withattributecomment');	# 1 (true) if yes, namely old version (perhaps the versions prior to 2.0).

    # Set which bands to use for source searching
    my @bandList = ( 1, 2, 3, 4, 5 );
    my @hardnessList = qw(1 2 2 3 3 4);

    # Find raw images, exposure maps for this exposure, in band order
    foreach my $inst (qw(epn emos1 emos2))
    {
        my @xidBandsThisInst = @{$xidBands->{$inst}};
        my ($filter, $maskIm);
        foreach my $band (@bandList)
        {
            my $rawim = findFile(
                class => 'intermediate'
                , instrument => $inst
                , band => $band
                , content => 'merged image'
            );
            my $expim = findFile(
                class => 'intermediate'
                , instrument => $inst
                , band => $band
                , content => 'merged exposure map'
            );
            my $flatExpIm = findFile(
                class => 'intermediate'
                , instrument => $inst
                , band => $band
                , content => 'merged non-vig exp map'
            );
            my $filteredList = findFile(
                class => 'intermediate'
                , instrument => $inst
                , band => $band
                , content => 'image merged event list'
            );
            if ( $rawim && $expim && $flatExpIm && $filteredList )
            {
                if ( !$filter ) # ie, if this is the first band
                {
                    $filter = readFITSKeyword(
                        file => $filteredList
                        , extension => 'PRIMARY'
                        , keyword => 'FILTER'
                    );

                    unless ( $filter =~ /(Thin|Medium|Thick|Open)/ )
                    {
                        info("Could not match filter for energy conversion factor");
                        return exception();
                    }
                    $filter = $1;

                    # Create detection mask for this exposure
                    $maskIm = newFile(
						class => 'product'
                        , instrument => $inst
                        , content => 'EPIC DETECTION MASK'
                    );
#goto SKIP010;
                    doCommand(
                        'emask'
                        , expimageset => $flatExpIm
                        , threshold1 => 0.5
                        , threshold2 => 1.0
                        , detmaskset => $maskIm
                      )
                      or return exception();
#SKIP010:

                    push( @maskImList, $maskIm );

                    push(
                        @xidEcfList
                        , energyConversionFactor(
                            $inst, $filter, 9
                        )
                    );
                    push( @xidEbandlo, energyBand( 9, 0 ) );
                    push( @xidEbandhi, energyBand( 9, 1 ) );

                    # Read the constituent exposure IDs of the band 1 merged image:
                    my @expidKwdValues = ();
                    my $exited_normally = 0;
                    foreach my $i (1 .. 99) # why the arbitrary 99? Because I don't like infinite loops.
                    {
                        my $kwd_str = 'EXPID'.sprintf("%2.2d", $i);
                        my $kwd_value = readFITSKeyword(
                            'file' => $rawim
                            , 'extension' => 'PRIMARY'
                            , 'keyword' => $kwd_str
                        );
                        if ($kwd_value)
                        {
                            push( @expidKwdValues, $kwd_value);
                        }
                        else
                        {
                            $exited_normally = 1;
                            last;
                        }
                    }
                    if ($exited_normally)
                    {
                        $expidKwds{$inst} = [@expidKwdValues];
                    }
                    else
                    {
                        info("Bug when reading expid keywords.");
                    }
                } # end if !$filter (ie, if $band==0)

                my $bkgFile = newFile(
                    class => 'product'
                    , instrument => $inst
                    , band => $band
                    , content => 'EPIC merged background map'
                );
                push( @bkgImList, $bkgFile );
                push( @{$band8constituents{$inst}}, $bkgFile);
                push( @{$band9constituents{$inst}}, $bkgFile) if (&isInList($band, @xidBandsThisInst));
				push( @maskImLongList, $maskIm );
                push( @rawImList, $rawim );
                push( @expImList, $expim );
                push( @flatExpImList, $flatExpIm );
                push(
                    @ecfList
                    , energyConversionFactor(
                        $inst, $filter, $band
                    )
                );
                push( @ebandlo, energyBand( $band, 0 ) );
                push( @ebandhi, energyBand( $band, 1 ) );
                push( @imEventList, $filteredList );

                push( @instList, $inst );
                push( @bandLongList, $band );
            }
            else
            {
                info(
"Cannot find all required images for instrument $inst, energy band $band. This combination will be ignored."
                );
            }
        } # end loop over bands
    } # end loop over insts
    return success() unless @rawImList;

#SKIP01:
    my $flareScreened;
    if (
        hasFITSKeyword(
            file => $rawImList[0]
            , extension => 'PRIMARY'
            , keyword => 'BKGDSCRN'
        )
      )
    {
        $flareScreened = readFITSKeyword(
            file => $rawImList[0]
            , extension => 'PRIMARY'
            , keyword => 'BKGDSCRN'
        );
        undef $flareScreened if $flareScreened eq 'F';
    }

    # Do box detection stage
    my $boxList = newFile(
        class => 'product'
        , instrument => thisInstrument
        , content => 'EPIC OBSERVATION box-local source list'
    );
#goto SKIP02;
    doCommand(
        'eboxdetect'
        , imagesets => [@rawImList]
        , expimagesets => [@expImList]
        , detmasksets => [@maskImList]
        , boxlistset => $boxList
        , usemap => 'false'
        , likemin => 5
        , boxsize => 5
        , withdetmask => 'true'
        , withexpimage => 'true'
        , nruns => 1
        , ecf => [@ecfList]
        , pimin => [@ebandlo]
        , pimax => [@ebandhi]
      )
      or return exception();

#SKIP02:
    if ($existsargwithattributecomment) {
    doCommand(
        'addattribute', set => $boxList
        , attributename => 'BKGDSCRN'
        , attributetype => 'boolean'
        , booleanvalue => $flareScreened ? 'T' : 'F'
        , withattributecomment => 'Y'
        , attributecomment =>
          "Was background screening of the eventlist applied?"
      )
      or return exception();
    } else {
    doCommand(
        'addattribute', set => $boxList
        , attributename => 'BKGDSCRN'
        , attributetype => 'boolean'
        , booleanvalue => $flareScreened ? 'T' : 'F'
        , attributecomment =>
          #"Was background screening of the eventlist applied?"
          '"Was background screening of the eventlist applied?"'
      )
      or return exception();
    }

    &addAllExpIdKwds($boxList, \%expidKwds) or return exception();

    # Create spline background map for each image
    foreach my $i (0 .. $#rawImList)
    {
        my $bkgFile = $bkgImList[$i];
        doCommand(
            'esplinemap'
            , boxlistset => $boxList
            , idband => $bandLongList[$i]
            , imageset => $rawImList[$i]
            , detmaskset => $maskImLongList[$i]
            , withexpimage => 'true'
            , expimageset => $flatExpImList[$i]
            , withdetmask => 'true'
            , withexpimage2 => 'false'
            , fitmethod => 'spline'
#            , nsplinenodes => 12
            , nsplinenodes => 13
#            , excesssigma => 2.5
            , excesssigma => 3.0
            , nfitrun => 4
#            , withootset => 'true'
            , withootset => ($instList[$i] eq 'epn') ? 'true' : 'false'
#            , mlmin => 1.0
            , scut => 0.002
            , ooteventset => $imEventList[$i]
            , bkgimageset => $bkgFile
            , pimin => $ebandlo[$i]
            , pimax => $ebandhi[$i]
#### last 2 aren't needed if $imEventList[$i] is filtered on the energy band.
          )
          or return exception();

        if ($existsargwithattributecomment) {
        doCommand(
            'addattribute', set => $bkgFile
            , attributename => 'BKGDSCRN'
            , attributetype => 'boolean'
            , booleanvalue => $flareScreened ? 'T' : 'F'
            , withattributecomment => 'Y'
            , attributecomment =>
              "Was background screening of the eventlist applied?"
          )
          or return exception();
        } else {
        doCommand(
            'addattribute', set => $bkgFile
            , attributename => 'BKGDSCRN'
            , attributetype => 'boolean'
            , booleanvalue => $flareScreened ? 'T' : 'F'
            , attributecomment =>
              #"Was background screening of the eventlist applied?"
              '"Was background screening of the eventlist applied?"'
          )
          or return exception();
        }

        &addExpIdKwds($bkgFile, \%expidKwds, $instList[$i]) or return exception();

} # end loop over found merged images

    # Now make band 8 background maps. These are made by summing, for each instrument, the background maps for bands 1 to 5. NOTE that, formally speaking, there is a possibility that not all the 5 constituents may be summed, in which case the background map cannot truly be said to be for band 8. There's also nothing but convention to say that the bands don't overlap. So from a software engineering point of view this is not a very watertight bit of code. But we have to leave something to future generations!
    #
    # Band 9 (xid) bkg maps now also made here, and the lists of xid images, exp maps and bkg maps loaded.

    my ( @xidRawImList, @xidExpImList, @xidBkgImList, $bkgFile );
    my $tempImage = newFile(
        class => 'intermediate'
        , instrument => 'epic'
        , content => 'temporaryImage'
    );
    foreach my $inst (qw(epn emos1 emos2))
    {
		next unless exists $band8constituents{$inst};
        if (@{$band8constituents{$inst}} != 5)
        {
            info("There are not (as there should be) 5 constituents to the 'band 8' background map for instrument $inst.");
        }
        next unless(@{$band8constituents{$inst}});

        $bkgFile = newFile(
            class => 'intermediate'
            , instrument => $inst
            , band => 8
            , content => 'merged background map'
            , format => 'FITS'
        );
        doCommand(
            'imweightadd', imagesets => $band8constituents{$inst}
            , withweights => 'no'
            , outimageset => $bkgFile
            , tempset => $tempImage
          )
          or return exception();
	
		my @bkgmaplistdtl = ( class => 'intermediate'
			, content => 'background map list'
			, instrument => $inst
			, band => 8
			, format => 'ASCII'
		);

		unless ( &ModuleUtil::keepSafe ( file_identifier => \@bkgmaplistdtl , text => $band8constituents{$inst} ) )
		{
			info('Unable to store band 8 image list for later use.');
			return exception();
		}
		

        # Now for band 9 (xid):
        my @xidBandsThisInst = @{$xidBands->{$inst}};
	next unless exists $band9constituents{$inst};
        if (@{$band9constituents{$inst}} != @xidBandsThisInst)
        {
            info("Incorrect number of constituents found for the XID background map for instrument $inst.");
        }
        next unless(@{$band9constituents{$inst}});

        $bkgFile = newFile(
            class => 'intermediate'
            , instrument => $inst
            , band => 9
            , content => 'merged background map'
        );
        doCommand(
            'imweightadd', imagesets => $band9constituents{$inst}
            , withweights => 'no'
            , outimageset => $bkgFile
            , tempset => $tempImage
          )
          or return exception();
        push( @xidBkgImList, $bkgFile );

        my $rawim = findFile(
            class => 'intermediate'
            , instrument => $inst
            , band => 9
            , content => 'merged image'
        );
        my $expim = findFile(
            class => 'intermediate'
            , instrument => $inst
            , band => 9
            , content => 'merged exposure map'
        );
        if ( $rawim && $expim )
        {
            push( @xidRawImList, $rawim );
            push( @xidExpImList, $expim );
        }
        else
        {
            info("Cannot find all required images for instrument $inst, XID energy band.");
            return exception();
        }
    } # end loop over instruments

    # Re-run eboxdetect with a background map
    my $mboxList = newFile(
        class => 'product'
        , instrument => thisInstrument
        , content => 'EPIC observation box-map source list'
    );
    doCommand(
        'eboxdetect'
        , boxsize => 5
        , imagesets => [@rawImList]
        , expimagesets => [@expImList]
        , bkgimagesets => [@bkgImList]
        , detmasksets => [@maskImList]
        , boxlistset => $mboxList
        , likemin => 5
        , usemap => 'true'
        , withdetmask => 'true'
        , withexpimage => 'true'
        , nruns => 1
        , ecf => [@ecfList]
        , pimin => [@ebandlo]
        , pimax => [@ebandhi]
      )
      or return exception();

    if ($existsargwithattributecomment) {
    doCommand(
        'addattribute', set => $mboxList
        , attributename => 'BKGDSCRN'
        , attributetype => 'boolean'
        , booleanvalue => $flareScreened ? 'T' : 'F'
        , withattributecomment => 'Y'
        , attributecomment =>
          "Was background screening of the eventlist applied"
      )
      or return exception();
    } else {
    doCommand(
        'addattribute', set => $mboxList
        , attributename => 'BKGDSCRN'
        , attributetype => 'boolean'
        , booleanvalue => $flareScreened ? 'T' : 'F'
        , attributecomment =>
          #"Was background screening of the eventlist applied?"
          '"Was background screening of the eventlist applied?"'
      )
      or return exception();
    }

    &addAllExpIdKwds($mboxList, \%expidKwds) or return exception();

    if (   fileExists( file => $mboxList )
        && numberFITSRows( file => $mboxList, extension => 'SRCLIST' )
        > 0 )
    {
        my (@commandLine, %hrmatch);

        # Run maximum likelihood detection
        my $mlList = newFile(
            class => 'product'
            , instrument => thisInstrument
            , content => 'EPIC observation ml source list'
        );
        @commandLine = (
            imagesets => [@rawImList]
            , expimagesets => [@expImList]
            , bkgimagesets => [@bkgImList]
            , boxlistset => $mboxList
            , ecut => 15.0
            , nmulsou => 2
            , ecf => [@ecfList]
            , determineerrors => 'true'
            , mlmin => 6
            , pimin => [@ebandlo]
            , pimax => [@ebandhi]
            , mllistset => $mlList
            , dmlextmin => 4
            , fitextent => 'true'
            , withsourcemap => 'false'
### GL has true, but this has no effect on source detection.
            , withdetmask => 'true'
            , detmasksets => [@maskImList]
            , extentmodel => 'beta'
            , withthreshold => 'true'
            , threshcolumn => 'LIKE'
            , threshold => 10.0
            , withtwostage => 'true'
        );

        # Add hardness details to commandLine based on available instruments
        %hrmatch = (
            'emos1' => 'hrm1def'
            , 'emos2' => 'hrm2def'
            , 'epn' => 'hrpndef'
        );
        foreach my $inst (qw(epn emos1 emos2))
        {
            push( @commandLine
                , ( $hrmatch{"$inst"}, [ @{ hardnessBands($inst) } ] )
            );
        }
        doCommand( 'emldetect', @commandLine ) or return exception();

        &addAllExpIdKwds($mlList, \%expidKwds) or return exception();

        # Now run emldetect on xid images:
        if (@xidRawImList != @xidEcfList)
        {
            info("Wrong number of input files for XID run of emldetect");
        }
        else
        {
            my $mlListXid = newFile(
                class => 'intermediate'
                , instrument => thisInstrument
                , content => 'ml XID source list'
            );
            @commandLine = (
                imagesets => [@xidRawImList]
                , expimagesets => [@xidExpImList]
                , bkgimagesets => [@xidBkgImList]
                , boxlistset => $mlList
                , ecut => 15.0
                , nmulsou => 1
                , ecf => [@xidEcfList]
## GL says is obsolete parameter
                , determineerrors => 'true'
                , mlmin => 0.0
                , pimin => [@xidEbandlo]
                , pimax => [@xidEbandhi]
                , mllistset => $mlListXid
                , fitextent => 'no'
                , fitposition => 'no'
                , withsourcemap => 'false'
                , withdetmask => 'true'
                , detmasksets => [@maskImList]
                , extentmodel => 'beta'
                , xidfixed => 'yes'
            );

            # Add hardness and xid band details to commandLine based on available instruments
            %hrmatch = (
                'emos1' => 'hrm1def'
                , 'emos2' => 'hrm2def'
                , 'epn' => 'hrpndef'
            );
            my %xidmatch = (
                'emos1' => 'xidm1def'
                , 'emos2' => 'xidm2def'
                , 'epn' => 'xidpndef'
            );
            foreach my $inst (qw(epn emos1 emos2))
            {
                push( @commandLine
                    , ( $hrmatch{"$inst"}, [ @{ hardnessBands($inst) } ] )
                );
                push( @commandLine
                    , ( $xidmatch{"$inst"}, [ @{ $xidBands->{$inst} } ] ) );
            }
            doCommand( 'emldetect', @commandLine ) or return exception();

	    if ($existsargwithattributecomment) {
            doCommand(
                'addattribute', set => $mlList
                , attributename => 'BKGDSCRN'
                , attributetype => 'boolean'
                , booleanvalue => $flareScreened ? 'T' : 'F'
                , withattributecomment => 'Y'
                , attributecomment =>
                  "Was background screening of the eventlist applied?"
              )
              or return exception();
	    } else {
            doCommand(
                'addattribute', set => $mlList
                , attributename => 'BKGDSCRN'
                , attributetype => 'boolean'
                , booleanvalue => $flareScreened ? 'T' : 'F'
                , attributecomment =>
		  #"Was background screening of the eventlist applied?"
		  '"Was background screening of the eventlist applied?"'
              )
              or return exception();
	    }
        }
    }

    # Create sensitivity map for band 8.
    my $senseFile = newFile(
        class => 'product'
        , instrument => 'epic'
        , band => 8
        , content => 'EPIC OBSERVATION SENSITIVITY MAP'
    );
    doCommand(
        'esensmap'
        , expimagesets => [@expImList]
        , bkgimagesets => [@bkgImList]
        , detmasksets => [@maskImList]
        , sensimageset => $senseFile
        , mlmin => 6
###### Should be the same as for emldetect?? Or eboxdetect --likemin????
      )
      or return exception();

    if ($existsargwithattributecomment) {
    doCommand(
        'addattribute', set => $senseFile
        , attributename => 'BKGDSCRN'
        , attributetype => 'boolean'
        , booleanvalue => $flareScreened ? 'T' : 'F'
        , withattributecomment => 'Y'
        , attributecomment =>
          "Was background screening of the eventlist applied?"
      )
      or return exception();
    } else {
    doCommand(
        'addattribute', set => $senseFile
        , attributename => 'BKGDSCRN'
        , attributetype => 'boolean'
        , booleanvalue => $flareScreened ? 'T' : 'F'
        , attributecomment =>
          #"Was background screening of the eventlist applied?"
          '"Was background screening of the eventlist applied?"'
      )
      or return exception();
    }

    # Raise success flag
    return success();
}

sub addAllExpIdKwds
{
    my $status = 1;
    my ($fileName, $expidKwdsRef) = @_;

    foreach my $inst (qw(epn emos1 emos2))
    {
        $status = &addExpIdKwds($fileName, $expidKwdsRef, $inst);
        return $status if (!$status);
    }
    return $status;
}

sub addExpIdKwds
{
    my $status = 1;
    my ($fileName, $expidKwdsRef, $inst) = @_;
    my %expidKwds = %{$expidKwdsRef};

    my $prefix = 'PN'; # default
    if ($inst eq 'emos1')
    {
        $prefix = 'M1';
    }
    elsif ($inst eq 'emos2')
    {
        $prefix = 'M2';
    }

    if (defined($expidKwds{$inst}))
    {
        my @kwd_list = @{$expidKwds{$inst}};
        foreach my $i (0 .. $#kwd_list)
        {
            my $exp_id = $kwd_list[$i];
            my $kwd_str = $prefix.'EXID'.sprintf("%2.2d", $i+1);
            doCommand(
                'addattribute', set => $fileName
                , attributename => $kwd_str
                , attributetype => 'string'
                , stringvalue => $exp_id
              )
              or return exception();
        }
    }
    return $status;
}

sub isInList
{
    my ($element, @list) = @_;
    my $status = 0;
    return $status if (!defined($list[0]) || !defined($element));
    foreach my $trial (@list)
    {
        if ($trial eq $element)
        {
            $status = 1;
            last;
        }
    }
    return $status;
}
1;
