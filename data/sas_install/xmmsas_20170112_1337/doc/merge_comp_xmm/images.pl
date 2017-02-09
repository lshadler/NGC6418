# LaTeX2HTML 2016 (1.71)
# Associate images original text with physical files.


$key = q/2000times2000;MSF=1.6;AAT/;
$cached_env_img{$key} = q|<IMG
 WIDTH="87" HEIGHT="30" ALIGN="MIDDLE" BORDER="0"
 SRC="|."$dir".q|img1.png"
 ALT="$2000\times2000$">|; 

$key = q/N_{H}=2{times}10^{20};MSF=1.6;AAT/;
$cached_env_img{$key} = q|<IMG
 WIDTH="100" HEIGHT="34" ALIGN="MIDDLE" BORDER="0"
 SRC="|."$dir".q|img2.png"
 ALT="$N_{H}=2{\times}10^{20}$">|; 

$key = q/^{-2};MSF=1.6;AAT/;
$cached_env_img{$key} = q|<IMG
 WIDTH="21" HEIGHT="18" ALIGN="BOTTOM" BORDER="0"
 SRC="|."$dir".q|img3.png"
 ALT="$^{-2}$">|; 

1;

