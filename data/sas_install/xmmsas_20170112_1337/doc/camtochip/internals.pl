# LaTeX2HTML 2016 (1.71)
# Associate internals original text with physical files.


$key = q/camtochip:description:inputfiles/;
$ref_files{$key} = "$dir".q|node5.html|; 
$noresave{$key} = "$nosave";

$key = q/camtochip:description:use/;
$ref_files{$key} = "$dir".q|node2.html|; 
$noresave{$key} = "$nosave";

$key = q/camtochip:description:instruments/;
$ref_files{$key} = "$dir".q|node1.html|; 
$noresave{$key} = "$nosave";

$key = q/camtochip:description:description/;
$ref_files{$key} = "$dir".q|node3.html|; 
$noresave{$key} = "$nosave";

$key = q/camtochip:description:parameters/;
$ref_files{$key} = "$dir".q|node4.html|; 
$noresave{$key} = "$nosave";

$key = q/camtochip:description:outputfiles/;
$ref_files{$key} = "$dir".q|node6.html|; 
$noresave{$key} = "$nosave";

1;

