# LaTeX2HTML 2016 (1.71)
# Associate labels original text with physical files.


$key = q/odfbrowser:procs/;
$external_labels{$key} = "$URL/" . q|node10.html|; 
$noresave{$key} = "$nosave";

$key = q/odfbrowser:description:description/;
$external_labels{$key} = "$URL/" . q|node2.html|; 
$noresave{$key} = "$nosave";

$key = q/odfbrowser:description:use/;
$external_labels{$key} = "$URL/" . q|node1.html|; 
$noresave{$key} = "$nosave";

$key = q/odfbrowser:description:inputfiles/;
$external_labels{$key} = "$URL/" . q|node11.html|; 
$noresave{$key} = "$nosave";

$key = q/odfbrowser:description:outputfiles/;
$external_labels{$key} = "$URL/" . q|node12.html|; 
$noresave{$key} = "$nosave";

1;


# LaTeX2HTML 2016 (1.71)
# labels from external_latex_labels array.


$key = q/odfbrowser:description:inputfiles/;
$external_latex_labels{$key} = q|3|; 
$noresave{$key} = "$nosave";

$key = q/odfbrowser:description:outputfiles/;
$external_latex_labels{$key} = q|4|; 
$noresave{$key} = "$nosave";

$key = q/odfbrowser:procs/;
$external_latex_labels{$key} = q|2.2|; 
$noresave{$key} = "$nosave";

$key = q/odfbrowser:description:description/;
$external_latex_labels{$key} = q|2|; 
$noresave{$key} = "$nosave";

$key = q/odfbrowser:description:use/;
$external_latex_labels{$key} = q|1|; 
$noresave{$key} = "$nosave";

1;

