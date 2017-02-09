# LaTeX2HTML 2016 (1.71)
# Associate labels original text with physical files.


$key = q/binned_att:description:sampleBinnedAttitude/;
$external_labels{$key} = "$URL/" . q|node3.html|; 
$noresave{$key} = "$nosave";

$key = q/binned_att:description:writeBinnedAttitude/;
$external_labels{$key} = "$URL/" . q|node4.html|; 
$noresave{$key} = "$nosave";

$key = q/binned_att:description:gtiWeightBinnedAttitude/;
$external_labels{$key} = "$URL/" . q|node6.html|; 
$noresave{$key} = "$nosave";

$key = q/binned_att:description:readBinnedAttitude/;
$external_labels{$key} = "$URL/" . q|node5.html|; 
$noresave{$key} = "$nosave";

$key = q/binned_att:description:binUpAttitudeFromOdf/;
$external_labels{$key} = "$URL/" . q|node2.html|; 
$noresave{$key} = "$nosave";

$key = q/binned_att:description:description/;
$external_labels{$key} = "$URL/" . q|node1.html|; 
$noresave{$key} = "$nosave";

1;


# LaTeX2HTML 2016 (1.71)
# labels from external_latex_labels array.


$key = q/binned_att:description:binUpAttitudeFromOdf/;
$external_latex_labels{$key} = q|1.1|; 
$noresave{$key} = "$nosave";

$key = q/binned_att:description:readBinnedAttitude/;
$external_latex_labels{$key} = q|1.4|; 
$noresave{$key} = "$nosave";

$key = q/binned_att:description:gtiWeightBinnedAttitude/;
$external_latex_labels{$key} = q|1.5|; 
$noresave{$key} = "$nosave";

$key = q/binned_att:description:writeBinnedAttitude/;
$external_latex_labels{$key} = q|1.3|; 
$noresave{$key} = "$nosave";

$key = q/binned_att:description:sampleBinnedAttitude/;
$external_latex_labels{$key} = q|1.2|; 
$noresave{$key} = "$nosave";

$key = q/binned_att:description:description/;
$external_latex_labels{$key} = q|1|; 
$noresave{$key} = "$nosave";

1;

