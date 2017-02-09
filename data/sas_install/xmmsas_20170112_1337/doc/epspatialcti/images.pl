# LaTeX2HTML 2016 (1.71)
# Associate images original text with physical files.


$key = q/epsfig{file=Vela_before.ps,width=10cm};AAT/;
$cached_env_img{$key} = q|<IMG
 WIDTH="453" HEIGHT="465" ALIGN="BOTTOM" BORDER="0"
 SRC="|."$dir".q|img1.png"
 ALT="\epsfig{file=Vela_before.ps,width=10cm}">|; 

$key = q/epsfig{file=Vela_after.ps,width=10cm};AAT/;
$cached_env_img{$key} = q|<IMG
 WIDTH="453" HEIGHT="465" ALIGN="BOTTOM" BORDER="0"
 SRC="|."$dir".q|img2.png"
 ALT="\epsfig{file=Vela_after.ps,width=10cm}">|; 

1;

