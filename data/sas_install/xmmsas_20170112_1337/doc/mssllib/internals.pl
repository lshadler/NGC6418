# LaTeX2HTML 2016 (1.71)
# Associate internals original text with physical files.


$key = q/omfchain:description:instruments/;
$ref_files{$key} = "$dir".q|node1.html|; 
$noresave{$key} = "$nosave";

$key = q/mssllib:description:description/;
$ref_files{$key} = "$dir".q|node2.html|; 
$noresave{$key} = "$nosave";

1;

