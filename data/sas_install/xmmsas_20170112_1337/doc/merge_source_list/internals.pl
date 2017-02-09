# LaTeX2HTML 2016 (1.71)
# Associate internals original text with physical files.


$key = q/merge_source_list:description:use/;
$ref_files{$key} = "$dir".q|node2.html|; 
$noresave{$key} = "$nosave";

$key = q/merge_source_list:description:instruments/;
$ref_files{$key} = "$dir".q|node1.html|; 
$noresave{$key} = "$nosave";

$key = q/merge_source_list:description:outputfiles/;
$ref_files{$key} = "$dir".q|node6.html|; 
$noresave{$key} = "$nosave";

$key = q/merge_source_list:description:comments/;
$ref_files{$key} = "$dir".q|node8.html|; 
$noresave{$key} = "$nosave";

$key = q/merge_source_list:description:inputfiles/;
$ref_files{$key} = "$dir".q|node5.html|; 
$noresave{$key} = "$nosave";

$key = q/merge_source_list:description:parameters/;
$ref_files{$key} = "$dir".q|node4.html|; 
$noresave{$key} = "$nosave";

$key = q/merge_source_list:description:algorithm/;
$ref_files{$key} = "$dir".q|node7.html|; 
$noresave{$key} = "$nosave";

$key = q/merge_source_list:description:description/;
$ref_files{$key} = "$dir".q|node3.html|; 
$noresave{$key} = "$nosave";

1;

