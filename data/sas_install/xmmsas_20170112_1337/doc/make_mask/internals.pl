# LaTeX2HTML 2016 (1.71)
# Associate internals original text with physical files.


$key = q/make_mask:description:comments/;
$ref_files{$key} = "$dir".q|node8.html|; 
$noresave{$key} = "$nosave";

$key = q/make_mask:description:use/;
$ref_files{$key} = "$dir".q|node2.html|; 
$noresave{$key} = "$nosave";

$key = q/make_mask:description:parameters/;
$ref_files{$key} = "$dir".q|node4.html|; 
$noresave{$key} = "$nosave";

$key = q/make_mask:description:outputfiles/;
$ref_files{$key} = "$dir".q|node6.html|; 
$noresave{$key} = "$nosave";

$key = q/make_mask:description:algorithm/;
$ref_files{$key} = "$dir".q|node7.html|; 
$noresave{$key} = "$nosave";

$key = q/make_mask:description:instruments/;
$ref_files{$key} = "$dir".q|node1.html|; 
$noresave{$key} = "$nosave";

$key = q/make_mask:description:description/;
$ref_files{$key} = "$dir".q|node3.html|; 
$noresave{$key} = "$nosave";

$key = q/make_mask:description:inputfiles/;
$ref_files{$key} = "$dir".q|node5.html|; 
$noresave{$key} = "$nosave";

1;

