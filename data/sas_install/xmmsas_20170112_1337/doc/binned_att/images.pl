# LaTeX2HTML 2016 (1.71)
# Associate images original text with physical files.


$key = q/i;MSF=1.6;AAT/;
$cached_env_img{$key} = q|<IMG
 WIDTH="9" HEIGHT="17" ALIGN="BOTTOM" BORDER="0"
 SRC="|."$dir".q|img2.png"
 ALT="$i$">|; 

$key = q/N-1;MSF=1.6;AAT/;
$cached_env_img{$key} = q|<IMG
 WIDTH="46" HEIGHT="30" ALIGN="MIDDLE" BORDER="0"
 SRC="|."$dir".q|img4.png"
 ALT="$N-1$">|; 

$key = q/N;MSF=1.6;AAT/;
$cached_env_img{$key} = q|<IMG
 WIDTH="18" HEIGHT="14" ALIGN="BOTTOM" BORDER="0"
 SRC="|."$dir".q|img1.png"
 ALT="$N$">|; 

$key = q/i+1;MSF=1.6;AAT/;
$cached_env_img{$key} = q|<IMG
 WIDTH="37" HEIGHT="29" ALIGN="MIDDLE" BORDER="0"
 SRC="|."$dir".q|img3.png"
 ALT="$i+1$">|; 

1;

