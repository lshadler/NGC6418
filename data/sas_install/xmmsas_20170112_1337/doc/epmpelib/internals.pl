# LaTeX2HTML 2016 (1.71)
# Associate internals original text with physical files.


$key = q/epmpelib:description:instruments/;
$ref_files{$key} = "$dir".q|node1.html|; 
$noresave{$key} = "$nosave";

$key = q/epmpelib:description:use/;
$ref_files{$key} = "$dir".q|node2.html|; 
$noresave{$key} = "$nosave";

$key = q/epmpelib:description:comments/;
$ref_files{$key} = "$dir".q|node5.html|; 
$noresave{$key} = "$nosave";

$key = q/epmpelib:description:algorithm/;
$ref_files{$key} = "$dir".q|node4.html|; 
$noresave{$key} = "$nosave";

$key = q/epmpelib:description:description/;
$ref_files{$key} = "$dir".q|node3.html|; 
$noresave{$key} = "$nosave";

1;

