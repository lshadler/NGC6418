# LaTeX2HTML 2016 (1.71)
# Associate internals original text with physical files.


$key = q/odfbrowser:description:use/;
$ref_files{$key} = "$dir".q|node1.html|; 
$noresave{$key} = "$nosave";

$key = q/odfbrowser:description:description/;
$ref_files{$key} = "$dir".q|node2.html|; 
$noresave{$key} = "$nosave";

$key = q/odfbrowser:procs/;
$ref_files{$key} = "$dir".q|node10.html|; 
$noresave{$key} = "$nosave";

$key = q/odfbrowser:description:outputfiles/;
$ref_files{$key} = "$dir".q|node12.html|; 
$noresave{$key} = "$nosave";

$key = q/odfbrowser:description:inputfiles/;
$ref_files{$key} = "$dir".q|node11.html|; 
$noresave{$key} = "$nosave";

1;

