## @file
# Parse XML config file

#========================================================================
use XML::LibXML;
use IO::Handle;

use GVEPICExposure;
use GVTask;
use GVProduct;
use GVODF;



@exposures = ();

# @method void   parseXMLConfFile(@ARGV)
# parse input command line and parse the parameter file.
sub parseXMLConfFile
{

	my $filename = $_[0];
	# open a filehandle and parse
	
	my $parser = XML::LibXML->new();
	$doc    = $parser->parse_file($filename);

	my %dist;
	
	&proc_node( $doc->getDocumentElement, \%dist );

#	$doc->toString;
#	return @exposures;
}

# process an XML tree node: if it's an element, update the
# distribution list and process all its children
#

sub proc_node {
    my( $node, $dist ) = @_;
    return unless( $node->nodeType eq &XML_ELEMENT_NODE );
    $dist->{ $node->nodeName } ++;
    

    foreach my $child ( $node->getChildnodes ) {
   		if($child -> nodeType ne &XML_TEXT_NODE)
    	{
#    		$elname = $child -> getName();
#        	@atts = $child -> getAttributes();
			          
        	foreach my $obs ($child->findnodes('OBSERVATION')) {
        		foreach my $param ($obs->findnodes('PARAM')) {
	            	$id = $param->getAttribute('id');
	            	$value = $param->getAttribute('default');	            	
	            	if ($id eq "analysisoption") {
	            		$odf_object->setAnalysisOption($value);
	            	} elsif ($id eq "epicsrc") {
	            		$odf_object->setEPICsrc($value)
	            	}  elsif ($id eq "ra") {
	            		$odf_object->setRA($value)
	            	}  elsif ($id eq "dec") {
	            		$odf_object->setDEC($value)
	            	}  elsif ($id eq "sourcename") {
	            		$odf_object->setSourceName($value)
	            	}  elsif ($id eq "obsid") {
	            		$odf_object->setObsId($value)
	            	}	elsif ($id eq "EPN") {
	            		$odf_object->setEPN($value)
	            	}	elsif ($id eq "EMOS1") {
	            		$odf_object->setEMOS1($value)
	            	}	elsif ($id eq "EMOS2") {
	            		$odf_object->setEMOS2($value)
	            	}	elsif ($id eq "RGS1") {
	            		$odf_object->setRGS1($value)
	            	}	elsif ($id eq "RGS2") {
	            		$odf_object->setRGS2($value)
	            	}	elsif ($id eq "OM") {
	            		$odf_object->setOM($value)	            		            		                 		            		            	
	            	}	elsif ($id eq "OM_sourcematch") {
	            		$odf_object->setOM_sourcematch($value)
	            	}	            		                 		            		            	

        		}
        	} 
        	        		
        	foreach my $inst ($child->findnodes('INSTRUMENT')) {
            	my $instName = $inst->getAttribute('value');                	
        	  
   
	        	foreach my $expo ($inst->findnodes('EXPOSURE')) {
	        		my $object = new GVEPICExposure();
	
					$object->setInstName($instName);

		        	$object->setMode($expo->getAttribute('mode'));		        	
		  	       	$object->setExpId($expo->getAttribute('expid'));
		           	$object->setDuration($expo->getAttribute('duration'));
		           	$object->setProcess($expo->getAttribute('process'));
					my @products = ();

		 			foreach my $product ($expo->findnodes('PRODUCT'))
		 			{
		 				$productObj = new GVProduct();
		 				$productObj->setProduct($product->getAttribute('value'));
		 				$productObj->setProcess($product->getAttribute('process'));
		 				
		 				my @tasks = ();	
						foreach my $task ($product->findnodes("TASK")) {				
			        		my $taskObj = new GVTask();
			        		my $params = {};
			        	
			        		$taskObj->setTask($task->getAttribute('name'));
							$taskObj->setInfo($task->getAttribute('purpose'));
			        		foreach my $param ($task->findnodes('PARAM')) {        		 
			          			if ($param->hasAttribute('default') ) {
			          				$attr = $param->getAttributeNode('default');
				          			$params->{$param->getAttribute('id')} = $attr;
			         			}         			         		
			        		}	
			        		
			        		$taskObj->setParam($params);			        	
			        		push(@tasks,$taskObj);  
						} 					       
						$productObj->setTasks(\@tasks);
			           	push(@products,$productObj);
			           	
			        }
		       		  
			        $object->setProducts(\@products);
			        push(@exposures,$object);				     
	        	}
    		}
    
    	 
        &proc_node( $child, $dist );
    }

    }
}


1;
