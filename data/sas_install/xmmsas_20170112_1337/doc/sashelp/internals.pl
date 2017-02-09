# LaTeX2HTML 2016 (1.71)
# Associate internals original text with physical files.


$key = q/sashelp:description:parameters/;
$ref_files{$key} = "$dir".q|node4.html|; 
$noresave{$key} = "$nosave";

$key = q/sashelp:description:instruments/;
$ref_files{$key} = "$dir".q|node1.html|; 
$noresave{$key} = "$nosave";

$key = q/sashelp:description:use/;
$ref_files{$key} = "$dir".q|node2.html|; 
$noresave{$key} = "$nosave";

$key = q/sashelp:description:errorconditions/;
$ref_files{$key} = "$dir".q|node5.html|; 
$noresave{$key} = "$nosave";

$key = q/sashelp:description:description/;
$ref_files{$key} = "$dir".q|node3.html|; 
$noresave{$key} = "$nosave";

1;

