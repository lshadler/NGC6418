# LaTeX2HTML 2016 (1.71)
# Associate labels original text with physical files.


$key = q/emproc:description:instruments/;
$external_labels{$key} = "$URL/" . q|node1.html|; 
$noresave{$key} = "$nosave";

$key = q/emproc:description:errorconditions/;
$external_labels{$key} = "$URL/" . q|node12.html|; 
$noresave{$key} = "$nosave";

$key = q/emproc:description:parameters/;
$external_labels{$key} = "$URL/" . q|node11.html|; 
$noresave{$key} = "$nosave";

$key = q/emproc:description:description/;
$external_labels{$key} = "$URL/" . q|node3.html|; 
$noresave{$key} = "$nosave";

$key = q/emproc:description:use/;
$external_labels{$key} = "$URL/" . q|node2.html|; 
$noresave{$key} = "$nosave";

$key = q/emproc:emproc:figure/;
$external_labels{$key} = "$URL/" . q|node4.html|; 
$noresave{$key} = "$nosave";

1;


# LaTeX2HTML 2016 (1.71)
# labels from external_latex_labels array.


$key = q/emproc:emproc:figure/;
$external_latex_labels{$key} = q|3.1|; 
$noresave{$key} = "$nosave";

$key = q/emproc:description:use/;
$external_latex_labels{$key} = q|2|; 
$noresave{$key} = "$nosave";

$key = q/emproc:description:errorconditions/;
$external_latex_labels{$key} = q|5|; 
$noresave{$key} = "$nosave";

$key = q/emproc:description:description/;
$external_latex_labels{$key} = q|3|; 
$noresave{$key} = "$nosave";

$key = q/emproc:description:parameters/;
$external_latex_labels{$key} = q|4|; 
$noresave{$key} = "$nosave";

$key = q/emproc:description:instruments/;
$external_latex_labels{$key} = q|1|; 
$noresave{$key} = "$nosave";

1;

