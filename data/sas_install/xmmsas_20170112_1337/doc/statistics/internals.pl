# LaTeX2HTML 2016 (1.71)
# Associate internals original text with physical files.


$key = q/statistics:description:comments/;
$ref_files{$key} = "$dir".q|node3.html|; 
$noresave{$key} = "$nosave";

$key = q/statistics:description:use/;
$ref_files{$key} = "$dir".q|node1.html|; 
$noresave{$key} = "$nosave";

$key = q/statistics:description:description/;
$ref_files{$key} = "$dir".q|node2.html|; 
$noresave{$key} = "$nosave";

1;

