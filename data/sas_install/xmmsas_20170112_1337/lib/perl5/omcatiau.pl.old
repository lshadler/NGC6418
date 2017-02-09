#! /usr/bin/perl -w
#
#
# main for SAS perl tasks.
# 2012-12-08 vny
# Task omcatiau implements the final formatting of the OM source catalogue
# which was produced by the task omcatchain (e.g., it adds the IAD source IDs)
# 
# 2013-02-22 adding the source-number prefix (for multiple catalogue files)
# 2013-02-23 changed the name for the parameter idprefix to prefix
#

require 5;
use strict;
use Getopt::Long;
Getopt::Long::Configure ("pass_through");
use SAS::error;


#use Thread qw'async yield';

my $inp_directory = "";  # The input directory
my $out_directory = "";  # The output directory
my $log_directory = "";
my $oldMasterCatalogue = "old_mastercatalogue.fit";
my $newMasterCatalogue = "new_mastercatalogue.fit";
my $finalCatalogueName = "mastercatalogue.fit";

my $homeDirectory="";
my $nThreads = 2;
my $deleteOldCatalogue="no";
my $prefix =-1; # prefix for the catalogue source number


#***********************************
# Subroutine GetCurrentDirectory
#**********************************
sub GetCurrentDirectory
{
    my $command = "pwd";
    my $curdir = `$command`;

    my $leng = length($curdir);
    substr($curdir, $leng - 1) = "";    
    return $curdir;
}


#****************************************************************
# The main program
#
#***************************************************************
sub omcatiau
{

    my $startTime = time();
    my $SASVERBOSITY = " ";
    if (exists($ENV{SAS_VERBOSITY}))
    {
	$SASVERBOSITY = $ENV{SAS_VERBOSITY};
    }
    else
    {
	$SASVERBOSITY = "5";
	$ENV{SAS_VERBOSITY} = "5";
    }
    if ($SASVERBOSITY > 7) 
    {
	$ENV{SAS_VERBOSITY} = "5";
    }
    
    $inp_directory = stringParameter("inpdirectory");
    $out_directory = stringParameter("outdirectory");
    $log_directory = stringParameter("logdirectory");
    #$odfListFileName=stringParameter("odflist");
    $oldMasterCatalogue=stringParameter("oldmastercatalogue");
    $newMasterCatalogue=stringParameter("newmastercatalogue");
    $finalCatalogueName=stringParameter("finalcatalogue");
    $deleteOldCatalogue = booleanParameter("deleteoldcatalogue");
    $prefix = intParameter("prefix");

    print("L376 inp_directory=$inp_directory \n");
    print("L377 out_directory=$out_directory \n");
    print("L378 log_directory=$log_directory \n");
    print("L379 oldMasterCatalogue=$oldMasterCatalogue \n");
    print("L380 newMasterCatalogue=$newMasterCatalogue \n");
    print("L383 finalCatalogueName=$finalCatalogueName \n");
    print("L382 deleteOldCatalogue=$deleteOldCatalogue \n");
    print("L88 prefix=$prefix \n");

    $homeDirectory=&GetCurrentDirectory;
    print("L188 homeDirectory=$homeDirectory \n");

    my $len = length($out_directory);

    if ($len < 2){
	# using the home directory for the input and output 
	$out_directory=$homeDirectory;
    }

    my $useDirectoryInside=0;
    my $auxFileName;
    my $sasodf_safe="";
    my $sasodfStored=0;
    if (exists($ENV{SAS_ODF})){
	$sasodf_safe=$ENV{SAS_ODF};
	$sasodfStored=1;
    }

    my $masterCataloguePathModified=0;
    my $oldMasterCatalogueFound=0;

    #*******************************************
    # Check for the existence of the ODF list
    #*******************************************
    if (not -e $oldMasterCatalogue) {
	printf("L412 Could not find the old master catalogue specified by the parameter \n");
	# Try to find the file in the output directory
	if (not -e $out_directory) {
	    print("L415 Cannot find the directory $out_directory   \n");
	    # Check the system variable SAS_ODF
	    if (exists($ENV{SAS_ODF})){
		print("L418 The environmental variable SAS_ODF does exist: OK \n ");
		
		$len = length($ENV{SAS_ODF});
		$out_directory = $ENV{SAS_ODF};
	
		if ($len < 3)
		{
		    print("L425 Checking the current directory \n");
		    my $currentDirectory = &GetCurrentDirectory;
		    $ENV{SAS_ODF} =  $currentDirectory;
		    $out_directory=$currentDirectory;
		    #$useDirectoryInside=1;
		    $masterCataloguePathModified=1;		    
		}

	    }
	    else {
		print("L435 The environmental variable SAS_ODF does not exist (using current directory)\n");
		# Try to get the catalogue file name from the current directory
		my $currentDirectory = &GetCurrentDirectory;
		
		$out_directory=$currentDirectory;
		$masterCataloguePathModified=1;	
		#$useDirectoryInside=1;
		
	    }
	}
	else {
	    
	    # try to get  the catalogue file from the out_directory
	   
	    my $oldMasterCataloguePath=$out_directory . "/" . $oldMasterCatalogue;
	    
	    if (not -e $oldMasterCataloguePath) { # file was not found in the output directory
		# Try to find it in the current directory
		my $currentDirectory = &GetCurrentDirectory;
		$out_directory=$currentDirectory;
		#$useDirectoryInside=1;
		print("L452 Using the current directory  \n");
		$oldMasterCataloguePath=$out_directory . "/" . $oldMasterCatalogue;
		if (not -e $oldMasterCataloguePath) {
		    # file not found (the flag oldMasterCatalogueFound will be zero) 
		    $masterCataloguePathModified=0;
		    $oldMasterCatalogueFound=0;	
		} else { # found the file
		    $masterCataloguePathModified=1;
		    $oldMasterCatalogueFound=1;	
		} 
				
	    } else {
		# the file with the list of ODFs was eventually found
		print("L456 found the old master catalogue : $oldMasterCataloguePath OK \n");
		$masterCataloguePathModified=1;	
		$oldMasterCatalogueFound=1;
	    }
	}

    }
    else {
	$oldMasterCatalogueFound=1;
	print("L251 The file $oldMasterCatalogue is in the specified directory: OK \n"); 
    }

    print("L484 oldMasterCatalogueFound=$oldMasterCatalogueFound \n");

    my $oldMasterCataloguePath=$out_directory . "/" . $oldMasterCatalogue;
    my $newMasterCataloguePath=$out_directory . "/" . $newMasterCatalogue;
    my $finalCataloguePath=$out_directory . "/" . $finalCatalogueName;

    if ($oldMasterCatalogueFound){
	print("L491 Found the old master catalogue in the path $out_directory \n");
	$oldMasterCatalogue=$oldMasterCataloguePath;
	$newMasterCatalogue=$newMasterCataloguePath;
	$finalCatalogueName=$finalCataloguePath;
    }
    print("L496 oldMasterCatalogue=$oldMasterCatalogue \n");
    print("L497 newMasterCatalogue=$newMasterCatalogue \n"); 
    print("L498 finalCatalogueName=$finalCatalogueName \n");

    my $logFile=$log_directory . "/final_catalogue.log";
    my $arg = "ommastercatalogue oldmastercatalogue=$oldMasterCatalogue " . 
	"newmastercatalogue=$newMasterCatalogue " . 
	"finalcatalogue=$finalCatalogueName  finish=yes prefix=$prefix -V 5 >& $logFile";

    if ($oldMasterCatalogueFound){
	print("L506 Processing the old master catalogue to finalise it \n");
	print("L508 command=$arg \n");
	#****************************************
	# Calling the task ommastercatalogue with the parameter finish=yes
	system($arg);
	#****************************************
    } else {
	print("L509 The old master catalogue was not found: stopping \n");
    }

    my $finishTime = time();
    my $diff = $finishTime - $startTime;
    #print("------------------------------\n");
    print("L517 Total time taken: $diff s \n");

    if ($sasodfStored){
	$ENV{SAS_ODF} =  $sasodf_safe;
    }


}






