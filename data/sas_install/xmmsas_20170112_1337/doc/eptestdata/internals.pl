# LaTeX2HTML 2016 (1.71)
# Associate internals original text with physical files.


$key = q/eptestdata:description:use/;
$ref_files{$key} = "$dir".q|node2.html|; 
$noresave{$key} = "$nosave";

$key = q/eptestdata:description:instruments/;
$ref_files{$key} = "$dir".q|node1.html|; 
$noresave{$key} = "$nosave";

$key = q/eptestdata:description:comments/;
$ref_files{$key} = "$dir".q|node14.html|; 
$noresave{$key} = "$nosave";

$key = q/eptestdata:description:description/;
$ref_files{$key} = "$dir".q|node3.html|; 
$noresave{$key} = "$nosave";

1;

