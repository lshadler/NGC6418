# LaTeX2HTML 2016 (1.71)
# Associate images original text with physical files.


$key = q/sim;MSF=1.6;AAT/;
$cached_env_img{$key} = q|<IMG
 WIDTH="16" HEIGHT="15" ALIGN="BOTTOM" BORDER="0"
 SRC="|."$dir".q|img1.png"
 ALT="$\sim$">|; 

$key = q/>;MSF=1.6;AAT/;
$cached_env_img{$key} = q|<IMG
 WIDTH="16" HEIGHT="30" ALIGN="MIDDLE" BORDER="0"
 SRC="|."$dir".q|img3.png"
 ALT="$&gt;$">|; 

$key = q/times;MSF=1.6;AAT/;
$cached_env_img{$key} = q|<IMG
 WIDTH="16" HEIGHT="30" ALIGN="MIDDLE" BORDER="0"
 SRC="|."$dir".q|img4.png"
 ALT="$\times$">|; 

$key = q/<;MSF=1.6;AAT/;
$cached_env_img{$key} = q|<IMG
 WIDTH="16" HEIGHT="30" ALIGN="MIDDLE" BORDER="0"
 SRC="|."$dir".q|img2.png"
 ALT="$&lt;$">|; 

1;

