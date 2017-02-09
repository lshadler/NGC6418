## @file
# subroutine to calculate the best Signal to Noise ratio

## @method void calculate_Signal2Noise()
# Allows the user interactivetily to calculate the best S/N
# @param fits_file Fits File Name
# @return Void

#======================================================================== 

sub calculate_Signal2Noise(){ 
	
	$logger->info("\n----> Running calculate_Signal2Noise ..... "); 
	
	$event_list = $_[0];
	my $instrument = $_[1];	
	my $exposure = $_[2];
	my $mode = $_[3];
	my $expo = $_[4];

	if ( ($mode eq "TimingEvts") && ( ($instrument eq "m1") || ($instrument eq "m2") ) )
	{
	    $logger->error("PG filtering not available for MOS in Timing mode") ;
	}
	else
	{
	    &show_ds9($event_list,$instrument,$exposure,$mode,"PG",$expo);
	}
	
	$logger->info("Continue...");

}

## @method void show_ds9($fits_file, $instrument)
# Display an image file (call to ds9)
# @param fits_file Fits File Name
# @param instrument
# @return Void

#========================================================================
sub show_ds9(){
 	use vars qw($PG_flagCall
	 );
	 
	$fits_file    = $_[0];
	my $instrument   = $_[1];
	my $exposure = $_[2];
	my $mode = $_[3];
	my $type = $_[4];
	my $expoObj = $_[5];
	
	my $src_expression = '';
	my $bkg_expression = '';
	my $bkg_flag = 0;
	my $src_exclude_flag = 0;
	my $bkg_exclude_flag = 0;
	
	
	#.. Get Variable object
	my $msg;
	my $product;
	if ($type eq "PG") {
		$product  = "GTIFiltering";
		$msg = "high background filtering using PG optimization";
	}
	if ($type eq "LC") {
		$product = "lightcurve";
		$msg = "Light curve creation";
	}
	if ($type eq "SPC") {
		$product = "spectra";
		$msg = "spectra creation";
	}

	my $src_region_flag = 0;
	%Switch = (
		'circle'    => sub { $logger->info("Parsing a Circle");
							$_[3] =~ s/"//;
							$shape = uc($_[0]);												
							if ($bkg_flag eq 0)	{								
								if ($src_region_flag != 0 && $src_exclude_flag == 0)
								{
									$logger->error("More than one source region detected.\n");
								}	
								if ($src_expression =~ /IN/) {$src_expression = $src_expression." && "; }
								if ($src_exclude_flag eq 1) {$src_expression = $src_expression."!";}
								if ($src_exclude_flag == 0)
								{
									$expoObj->set_src_region($shape);
									$expoObj->set_src_X($_[1]);								
									$expoObj->set_src_Y($_[2]);
								 	$expoObj->set_src_inner_roptimg($_[3]);					
								}
								$src_region_flag = 1;
								$src_expression = $src_expression." ((X,Y) IN $shape($_[1],$_[2],$_[3])) ";}													
							else {								
								if ($bkg_expression =~ /IN/) {$bkg_expression = $bkg_expression." && "; }
								if ($bkg_exclude_flag eq 1)  {$bkg_expression = $bkg_expression."!";}
								$expoObj->set_bkg_region($shape);
								$expoObj->set_bkg_X($_[1]);
								$expoObj->set_bkg_Y($_[2]);
							 	$expoObj->set_bkg_innerrimg($_[3]);
							 	
								$bkg_expression = $bkg_expression." ((X,Y) IN $shape($_[1],$_[2],$_[3])) ";
								$bkg_flag = 0;}		
							
							$logger->info("SOURCE: $src_expression");
       						$logger->info("BACKGROUND:$bkg_expression");
       						
						   },
    	'annulus'   => sub { $logger->info("Parsing a Annulus");
    						$_[3] =~ s/"//;
    						$_[4] =~ s/"//;	
							$shape = uc($_[0]);												
							if ($bkg_flag eq 0)	{								
								if ($src_expression =~ /IN/) {$src_expression = $src_expression." && "; }
								if ($src_exclude_flag eq 1) {$src_expression = $src_expression."!";}
								$expoObj->set_src_region($shape);
								$expoObj->set_src_X($_[1]);
								$expoObj->set_src_Y($_[2]);
							 	$expoObj->set_src_inner_roptimg($_[3]);
							 	$expoObj->set_src_roptimg($_[4]);

								$src_expression = $src_expression." ((X,Y) IN $shape($_[1],$_[2],$_[3],$_[4])) ";
							
							}													
							else {								
								if ($bkg_expression =~ /IN/) {$bkg_expression = $bkg_expression." && "; }
								if ($bkg_exclude_flag eq 1)  {$bkg_expression = $bkg_expression."!";}
								$expoObj->set_bkg_region($shape);
								$expoObj->set_bkg_X($_[1]);
								$expoObj->set_bkg_Y($_[2]);
							 	$expoObj->set_bkg_innerrimg($_[3]);
							 	$expoObj->set_bkg_outerrimg($_[4]);
								
								$bkg_expression = $bkg_expression." ((X,Y) IN $shape($_[1],$_[2],$_[3],$_[4])) ";
								$bkg_flag = 0;}	

								
							$logger->info("SOURCE: $src_expression");
       						$logger->info("BACKGROUND: $bkg_expression");    	
    						},
    	'ellipse'   => sub { $logger->info( "Parsing a Ellipse");
    						$_[3] =~ s/"//;
    						$_[4] =~ s/"//;	
							$shape = uc($_[0]);												
							if ($bkg_flag eq 0)	{								
								if ($src_expression =~ /IN/) {$src_expression = $src_expression." && "; }
								if ($src_exclude_flag eq 1) {$src_expression = $src_expression."!";}
								$expoObj->set_src_region($shape);
								$expoObj->set_src_X($_[1]);
								$expoObj->set_src_Y($_[2]);
							 	$expoObj->set_src_inner_roptimg($_[3]);
							 	$expoObj->set_src_roptimg($_[4]);
							 	
								$src_expression = $src_expression." ((X,Y) IN $shape($_[1],$_[2],$_[3],$_[4],$_[5])) ";}													
							else {								
								if ($bkg_expression =~ /IN/) {$bkg_expression = $bkg_expression." && "; }
								if ($bkg_exclude_flag eq 1)  {$bkg_expression = $bkg_expression."!";}
								$bkg_expression = $bkg_expression." ((X,Y) IN $shape($_[1],$_[2],$_[3],$_[4],$_[5])) ";
								$bkg_flag = 0;
								$expoObj->set_bkg_region($shape);
								$expoObj->set_bkg_X($_[1]);
								$expoObj->set_bkg_Y($_[2]);
							 	$expoObj->set_bkg_innerrimg($_[3]);
							 	$expoObj->set_bkg_outerrimg($_[4]);								
							}		

							$logger->info( "SOURCE: $src_expression");
       						$logger->info( "BACKGROUND: $bkg_expression");			
					    	},
    	'box' => sub { $logger->info( "Parsing a Box");
    						$_[3] =~ s/"//;
    						$_[4] =~ s/"//;	
							$shape = uc($_[0]);												
							if ($bkg_flag eq 0)	{								
								if ($src_expression =~ /IN/) {$src_expression = $src_expression." && "; }
								if ($src_exclude_flag eq 1) {$src_expression = $src_expression."!";}
								$expoObj->set_src_region($shape);
								$expoObj->set_src_X($_[1]);
								$expoObj->set_src_Y($_[2]);
							 	$expoObj->set_src_XLength($_[3]);
							 	$expoObj->set_src_YLength($_[4]);
							 	
								$src_expression = $src_expression." ((X,Y)) IN $shape($_[1],$_[2],$_[3],$_[4],$_[5])) ";}													
							else {								
								if ($bkg_expression =~ /IN/) {$bkg_expression = $bkg_expression." && "; }
								if ($bkg_exclude_flag eq 1)  {$bkg_expression = $bkg_expression."!";}
								$expoObj->set_bkg_region($shape);
								$expoObj->set_bkg_X($_[1]);
								$expoObj->set_bkg_Y($_[2]);
							 	$expoObj->set_bkg_XLength($_[3]);
							 	$expoObj->set_bkg_YLength($_[4]);		
								
								$bkg_expression = $bkg_expression." ((X,Y) IN $shape($_[1],$_[2],$_[3],$_[4],$_[5])) ";
								$bkg_flag = 0;}		


							$logger->info( "SOURCE: $src_expression");
       						$logger->info( "BACKGROUND: $bkg_expression");
    						},
    );


       	#.. Columns to be shown
       	my $X = "X";
       	my $Y = "Y";
       	if (($mode eq "TimingEvts") )
      	{
          if ($instrument eq "pn")
	  {
		    $X = "RAWX";
		    $Y = "RAWY";
       	  }
	  elsif ( ($instrument eq "m1") || ($instrument eq "m2") ) 
	  {
	      $logger->error("PG filtering not available for MOS in Timing mode") ;
	  }
      	} 

	my $tmp_image = "tmp_image_".$instrument.".ds";
	&produce_image($fits_file,$tmp_image,$instrument);

       if (($pid = fork) == 0)
       { 
# Run ds9
	if (&isRunning() == 1) {
	    exec ("ds9 -title xmmextractor_ds9  -cmap invert yes -cmap heat -scale log $tmp_image"); }
	    ##exec ("ds9 -title xmmextractor_ds9 -cmap invert yes -cmap heat -scale log  -fits $fits_file -bin cols $X $Y -zoom to fit -bin about center -bin factor 40"); }
	exit (1);
       }
       elsif ($pid > 0)
       {
 		
# Show the current Source and Background regions
		$expoObj->set_src_region("");		
		$expoObj->set_src_X(0);		
		$expoObj->set_src_Y(0);
		$expoObj->set_src_roptimg(0);
		$expoObj->set_src_XLength(0);
		$expoObj->set_src_YLength(0);
		$expoObj->set_bkg_XLength(0);
		$expoObj->set_bkg_YLength(0);
 
		$src_reg = $expoObj->get_src_region();		
		$src_x = $expoObj->get_src_X();		
		$src_y = $expoObj->get_src_Y();
		$src_rad = $expoObj->get_src_roptimg();
		$src_XL = $expoObj->get_src_XLength();
		$src_YL = $expoObj->get_src_YLength();
		$bkg_XL = $expoObj->get_bkg_XLength();
		$bkg_YL = $expoObj->get_bkg_YLength();
		my $xmmSrcExpr="";
				
		if ( ($src_x != 0) && ($src_y != 0))
		{ 	
			$expre="";
			if ($mode eq "TimingEvts")
			{
				$xmmSrcExpr = "\"$src_reg($src_x,$src_y,$src_XL,$src_YL,0)\"";
				$expre = "$src_reg($src_x,$src_y,$src_XL,$src_YL,0) # color=white";
			}
			else				
			{
				$xmmSrcExpr = "\"$src_reg($src_x,$src_y,$src_rad)\"";
				$expre = "$src_reg($src_x,$src_y,$src_rad) # color=white";
			}

			$command = "physical; $expre"; 
			print "COMMAND $command/n";
        	&send($command);
		}

		$expoObj->set_bkg_region("");
		$expoObj->set_bkg_X(0);
		$expoObj->set_bkg_Y(0);
		$expoObj->set_bkg_innerrimg(0);
		$expoObj->set_bkg_outerrimg(0);

		$bkg_reg = $expoObj->get_bkg_region();
		$bkg_x = $expoObj->get_bkg_X();
		$bkg_y = $expoObj->get_bkg_Y();
		$bkg_rad1 = $expoObj->get_bkg_innerrimg();
		$bkg_rad2 = $expoObj->get_bkg_outerrimg();
		
		my $xmmBkgExpr="";
		if (($bkg_x != 0) && ($bkg_y != 0))
		{
			$bkgExpre="";
			if ($mode eq "TimingEvts")
			{
				$xmmBkgExpr = "\"$bkg_reg($bkg_x,$bkg_y,$bkg_YL,$bkg_YL,0)\"";
				$bkgExpre = "$bkg_reg($bkg_x,$bkg_y,$bkg_XL,$bkg_YL,0) # color=white background";
			}
			else
			{
				$xmmBkgExpr = "\"$bkg_reg($bkg_x,$bkg_y,$bkg_rad1,$bkg_rad2)\"";
				$bkgExpre = "$bkg_reg($bkg_x,$bkg_y,$bkg_rad1,$bkg_rad2) # color=white background";	
			}
			$command = "physical; $bkgExpre";        
			print "COMMAND $command/n";    	  
			&send($command);
		}
		
		#Store the current src and bkg regions.

		if ($type eq "PG") {
		    $expoObj->getProduct($product)->getTask("xmmextractor","SN_optimization")->getParam("srcexpr")->setValue($xmmSrcExpr);
		    $expoObj->getProduct($product)->getTask("xmmextractor","SN_optimization")->getParam("bkgexpr")->setValue($xmmBkgExpr);
		}
			
		if ($type eq "LC") {
		    $expoObj->getProduct($product)->getTask("evselect","src_filtering")->getParam("expression")->setValue($xmmSrcExpr);
		    $expoObj->getProduct($product)->getTask("evselect","bkg_filtering")->getParam("expression")->setValue($xmmBkgExpr);
		}
			
		if ($type eq "SPC") {			
		    $expoObj->getProduct($product)->getTask("especget","sp_creation")->getParam("srcexp")->setValue($xmmSrcExpr);
		    $expoObj->getProduct($product)->getTask("especget","sp_creation")->getParam("backexp")->setValue($xmmBkgExpr);
		}
         	
       	print "Create source and background region for $msg\n";
       	print "\"Y\"-> New regions. \"N\"-> Use default region  \n";
       	print "Press Y/N...: \n";
       	chomp( $key = <STDIN> );
		while ( ($key eq 'y' ) ||($key eq 'Y' ) )  
		{				
			$src_expression = '';
			$bkg_expression = '';
			
			@output = &receive();
		
			$logger->info("DS9 command received: @output");
			#parse the xpaget output  
    		
			foreach my $line (@output) 
			{
			    @words = split(' ',$line);
# Skip comments
			    if ( ( $words[0] eq "#") || (lc($words[0]) eq "global") )
			    {
    				$logger->info( "GLOBAL: $line");
			    }	
			    elsif ( (lc($words[0]) eq "fk5") || (lc($words[0]) eq "physical") ) 
			    {
    				$logger->info( "UNITS: $line");    				
			    }
			    else
			    {    			
	    			
	    			$line =~ s/\(|\)|,/  /g;
	    			$logger->info( "LINE: $line");	    			
# Background region	and check if it is a excluded region   			
	    			if ( $line =~ /background/) {
				    $line =~ s/background/ /g; 
				    $bkg_flag = 1;
				    $logger->info( "Background region");	    		
				    if ($line =~ /^[\-]/) {
					$line =~ s/^[\-]//g;
					$bkg_exclude_flag = 1;
					$logger->info( "Background excluded region");						
				    }	    				    				
	    			}
# Source Exclude region
				if ($line =~ /^[\-]/) {
				    $line =~ s/^[\-]//g;
				    $src_exclude_flag = 1;
				    $logger->info( "Source excluded region");
				}
				
	    			@expr = split(' ',$line); 	    			
# Only one source region file can be taken into account
				$Switch{lc($expr[0])}->(@expr);
				
			    }    			
			    
			    if ($type eq "PG") {
				$expoObj->getProduct($product)->getTask("xmmextractor","SN_optimization")->getParam("srcexpr")->setValue($src_expression);
				$expoObj->getProduct($product)->getTask("xmmextractor","SN_optimization")->getParam("bkgexpr")->setValue($bkg_expression);
			    }
			    
			    if ($type eq "LC") {
				$expoObj->getProduct($product)->getTask("evselect","src_filtering")->getParam("expression")->setValue($src_expression);
				$expoObj->getProduct($product)->getTask("evselect","bkg_filtering")->getParam("expression")->setValue($bkg_expression);
			    }
			    
			    if ($type eq "SPC") {
				$expoObj->getProduct($product)->getTask("especget","sp_creation")->getParam("srcexp")->setValue($src_expression);
				$expoObj->getProduct($product)->getTask("especget","sp_creation")->getParam("backexp")->setValue($bkg_expression);
			    }
			}	
			
			if ($type eq "PG")
			{			
			    if ( $expoObj->getProduct($product)->getTask("xmmextractor","SN_optimization")->getParam("PG_optimize_SN")->getValue() eq "yes")
			    {    			
				#.. Before Running PG optimization we have to check if we have already created the GTI needed 
				#.. for PG to run regions to create a bkg light curve to calculate the S/N
				@epicGTI=&test_epic_gtifile($instrument,$exposure,$mode);
			    	if (! $epicGTI[0]){	
				    $PG_flagCall = 1;				
				    &compute_gti;
			    	}    	
		    		&PG_gti_filter($instrument,$exposure,$mode,$expoObj,$fits_file);
			    }
			}
			
			my $newMsg;	   	
			if ($type eq "PG") {			
			    $newMsg = "\"Y\"-> Repeat PG optimization with new regions. \"N\"-> Use the count rate obtained \n"
			}
			else {		
			    $newMsg = "\"Y\"-> Define new regions. \"N\"-> Use already defined regions \n";
			}
			print $newMsg;       	
			print "Press Y/N...: \n";
			chomp( $key = <STDIN> );			
			
		}
		
#close ds9 instance     
		kill 9 => $pid;
		
       }
	else
	{
	    $logger->error("ds9 display error: $!\n");
	}
	#my @args = ("ds9 -title xmmextractor_ds9 -cmap invert yes -cmap b -cmap value 1.15 .13 -fits $fits_file -zoom to fit &");
	#system(@args);                   # == 0 or &error_code(5); NOTE: If I put this bit it wont run on the grid    
	
	system("rm $tmp_image");
	return(1);

}

sub send()
{
	&waitForRunning();	
	`echo "$_[0]" | xpaset xmmextractor_ds9 regions `;
	
}

sub receive()
{
	@output = `xpaget xmmextractor_ds9 regions -format ds9 `;
	return (@output);
}

sub waitForRunning()
{		
	$output = `xpaget xmmextractor_ds9 2>&1`;
	@error = split(' ',$output);

	while ($error[0] eq "XPA\$ERROR"  )
	{			
		$output = `xpaget xmmextractor_ds9 2>&1`;
		@error = split(' ',$output);}				
}

sub isRunning()
{		
	$output = `xpaget xmmextractor_ds9 2>&1`;
	@error = split(' ',$output);
	
	if ($error[0] eq "XPA\$ERROR"  ) { $flag = 1;	}
	else { $flag = 0;}
	
	return($flag);			
}



1;
