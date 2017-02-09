# LaTeX2HTML 2016 (1.71)
# Associate labels original text with physical files.


$key = q/responselib:description:comments/;
$external_labels{$key} = "$URL/" . q|node4.html|; 
$noresave{$key} = "$nosave";

$key = q/responselib:description:use/;
$external_labels{$key} = "$URL/" . q|node2.html|; 
$noresave{$key} = "$nosave";

$key = q/responselib:description:instruments/;
$external_labels{$key} = "$URL/" . q|node1.html|; 
$noresave{$key} = "$nosave";

$key = q/responselib:description:description/;
$external_labels{$key} = "$URL/" . q|node3.html|; 
$noresave{$key} = "$nosave";

1;


# LaTeX2HTML 2016 (1.71)
# labels from external_latex_labels array.


1;

