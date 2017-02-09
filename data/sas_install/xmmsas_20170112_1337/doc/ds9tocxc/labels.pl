# LaTeX2HTML 2016 (1.71)
# Associate labels original text with physical files.


$key = q/dsninetocxc:description:parameters/;
$external_labels{$key} = "$URL/" . q|node4.html|; 
$noresave{$key} = "$nosave";

$key = q/dsninetocxc:description:description/;
$external_labels{$key} = "$URL/" . q|node3.html|; 
$noresave{$key} = "$nosave";

$key = q/xmmselect:description:instruments/;
$external_labels{$key} = "$URL/" . q|node1.html|; 
$noresave{$key} = "$nosave";

$key = q/cite_ct:ASCregion/;
$external_labels{$key} = "$URL/" . q|node6.html|; 
$noresave{$key} = "$nosave";

1;


# LaTeX2HTML 2016 (1.71)
# labels from external_latex_labels array.


$key = q/dsninetocxc:description:parameters/;
$external_latex_labels{$key} = q|4|; 
$noresave{$key} = "$nosave";

$key = q/xmmselect:description:instruments/;
$external_latex_labels{$key} = q|1|; 
$noresave{$key} = "$nosave";

$key = q/dsninetocxc:description:description/;
$external_latex_labels{$key} = q|3|; 
$noresave{$key} = "$nosave";

1;

