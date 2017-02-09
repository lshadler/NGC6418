# LaTeX2HTML 2016 (1.71)
# Associate internals original text with physical files.


$key = q/sasperl:description:instruments/;
$ref_files{$key} = "$dir".q|node1.html|; 
$noresave{$key} = "$nosave";

$key = q/sasperl:description:description/;
$ref_files{$key} = "$dir".q|node3.html|; 
$noresave{$key} = "$nosave";

$key = q/sasperl:description:use/;
$ref_files{$key} = "$dir".q|node2.html|; 
$noresave{$key} = "$nosave";

1;

