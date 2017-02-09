# LaTeX2HTML 2016 (1.71)
# Associate images original text with physical files.


$key = q/>=;MSF=1.6;AAT/;
$cached_env_img{$key} = q|<IMG
 WIDTH="29" HEIGHT="30" ALIGN="MIDDLE" BORDER="0"
 SRC="|."$dir".q|img4.png"
 ALT="$&gt;=$">|; 

$key = q/<=;MSF=1.6;AAT/;
$cached_env_img{$key} = q|<IMG
 WIDTH="29" HEIGHT="30" ALIGN="MIDDLE" BORDER="0"
 SRC="|."$dir".q|img2.png"
 ALT="$&lt;=$">|; 

$key = q/^*;MSF=1.6;AAT/;
$cached_env_img{$key} = q|<IMG
 WIDTH="11" HEIGHT="16" ALIGN="BOTTOM" BORDER="0"
 SRC="|."$dir".q|img1.png"
 ALT="$^*$">|; 

$key = q/ge;MSF=1.6;AAT/;
$cached_env_img{$key} = q|<IMG
 WIDTH="16" HEIGHT="30" ALIGN="MIDDLE" BORDER="0"
 SRC="|."$dir".q|img3.png"
 ALT="$\ge$">|; 

1;

