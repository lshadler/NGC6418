# LaTeX2HTML 2016 (1.71)
# Associate labels original text with physical files.


$key = q/cal:user/;
$external_labels{$key} = "$URL/" . q|node1.html|; 
$noresave{$key} = "$nosave";

$key = q/cal:user:env/;
$external_labels{$key} = "$URL/" . q|node4.html|; 
$noresave{$key} = "$nosave";

$key = q/cite_ct:SOCCCFICD/;
$external_labels{$key} = "$URL/" . q|node5.html|; 
$noresave{$key} = "$nosave";

1;


# LaTeX2HTML 2016 (1.71)
# labels from external_latex_labels array.


$key = q/cal:user:env/;
$external_latex_labels{$key} = q|3.1|; 
$noresave{$key} = "$nosave";

$key = q/cal:user/;
$external_latex_labels{$key} = q|1|; 
$noresave{$key} = "$nosave";

1;

