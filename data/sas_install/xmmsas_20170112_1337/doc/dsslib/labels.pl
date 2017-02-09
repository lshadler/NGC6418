# LaTeX2HTML 2016 (1.71)
# Associate labels original text with physical files.


$key = q/cite_asc:keywords/;
$external_labels{$key} = "$URL/" . q|node5.html|; 
$noresave{$key} = "$nosave";

$key = q/dsslib:description:description/;
$external_labels{$key} = "$URL/" . q|node1.html|; 
$noresave{$key} = "$nosave";

$key = q/dsslib:description:errorconditions/;
$external_labels{$key} = "$URL/" . q|node4.html|; 
$noresave{$key} = "$nosave";

1;


# LaTeX2HTML 2016 (1.71)
# labels from external_latex_labels array.


$key = q/dsslib:description:description/;
$external_latex_labels{$key} = q|1|; 
$noresave{$key} = "$nosave";

$key = q/dsslib:description:errorconditions/;
$external_latex_labels{$key} = q|2|; 
$noresave{$key} = "$nosave";

1;

