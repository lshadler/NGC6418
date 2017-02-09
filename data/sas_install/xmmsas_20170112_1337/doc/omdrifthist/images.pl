# LaTeX2HTML 2016 (1.71)
# Associate images original text with physical files.


$key = q/y;MSF=1.6;AAT/;
$cached_env_img{$key} = q|<IMG
 WIDTH="12" HEIGHT="30" ALIGN="MIDDLE" BORDER="0"
 SRC="|."$dir".q|img3.png"
 ALT="$y$">|; 

$key = q/1<=pages<=2;MSF=1.6;AAT/;
$cached_env_img{$key} = q|<IMG
 WIDTH="126" HEIGHT="30" ALIGN="MIDDLE" BORDER="0"
 SRC="|."$dir".q|img4.png"
 ALT="$1&lt;=pages&lt;=2$">|; 

$key = q/(x,y);MSF=1.6;AAT/;
$cached_env_img{$key} = q|<IMG
 WIDTH="41" HEIGHT="32" ALIGN="MIDDLE" BORDER="0"
 SRC="|."$dir".q|img1.png"
 ALT="$(x,y)$">|; 

$key = q/x;MSF=1.6;AAT/;
$cached_env_img{$key} = q|<IMG
 WIDTH="13" HEIGHT="13" ALIGN="BOTTOM" BORDER="0"
 SRC="|."$dir".q|img2.png"
 ALT="$x$">|; 

1;

