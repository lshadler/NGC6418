# LaTeX2HTML 2016 (1.71)
# Associate images original text with physical files.


$key = q/N;MSF=1.6;AAT/;
$cached_env_img{$key} = q|<IMG
 WIDTH="18" HEIGHT="14" ALIGN="BOTTOM" BORDER="0"
 SRC="|."$dir".q|img1.png"
 ALT="$N$">|; 

$key = q/^2;MSF=1.6;AAT/;
$cached_env_img{$key} = q|<IMG
 WIDTH="11" HEIGHT="18" ALIGN="BOTTOM" BORDER="0"
 SRC="|."$dir".q|img2.png"
 ALT="$^2$">|; 

$key = q/^{-1};MSF=1.6;AAT/;
$cached_env_img{$key} = q|<IMG
 WIDTH="21" HEIGHT="18" ALIGN="BOTTOM" BORDER="0"
 SRC="|."$dir".q|img4.png"
 ALT="$^{-1}$">|; 

$key = q/^{-2};MSF=1.6;AAT/;
$cached_env_img{$key} = q|<IMG
 WIDTH="21" HEIGHT="18" ALIGN="BOTTOM" BORDER="0"
 SRC="|."$dir".q|img3.png"
 ALT="$^{-2}$">|; 

1;

