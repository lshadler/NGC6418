# LaTeX2HTML 2016 (1.71)
# Associate internals original text with physical files.


$key = q/responselib:description:description/;
$ref_files{$key} = "$dir".q|node3.html|; 
$noresave{$key} = "$nosave";

$key = q/responselib:description:use/;
$ref_files{$key} = "$dir".q|node2.html|; 
$noresave{$key} = "$nosave";

$key = q/responselib:description:comments/;
$ref_files{$key} = "$dir".q|node4.html|; 
$noresave{$key} = "$nosave";

$key = q/responselib:description:instruments/;
$ref_files{$key} = "$dir".q|node1.html|; 
$noresave{$key} = "$nosave";

1;

