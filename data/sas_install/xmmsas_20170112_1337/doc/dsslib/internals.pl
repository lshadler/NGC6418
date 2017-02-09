# LaTeX2HTML 2016 (1.71)
# Associate internals original text with physical files.


$key = q/dsslib:description:description/;
$ref_files{$key} = "$dir".q|node1.html|; 
$noresave{$key} = "$nosave";

$key = q/cite_asc:keywords/;
$ref_files{$key} = "$dir".q|node5.html|; 
$noresave{$key} = "$nosave";

$key = q/dsslib:description:errorconditions/;
$ref_files{$key} = "$dir".q|node4.html|; 
$noresave{$key} = "$nosave";

1;

