# LaTeX2HTML 2016 (1.71)
# Associate images original text with physical files.


$key = q/t_{FMTS}<t_{track};MSF=1.6;AAT/;
$cached_env_img{$key} = q|<IMG
 WIDTH="110" HEIGHT="30" ALIGN="MIDDLE" BORDER="0"
 SRC="|."$dir".q|img2.png"
 ALT="$t_{FMTS}
&lt; t_{track}$">|; 

$key = q/t_{track}sim;MSF=1.6;AAT/;
$cached_env_img{$key} = q|<IMG
 WIDTH="58" HEIGHT="30" ALIGN="MIDDLE" BORDER="0"
 SRC="|."$dir".q|img1.png"
 ALT="$t_{track} \sim$">|; 

$key = q/sim;MSF=1.6;AAT/;
$cached_env_img{$key} = q|<IMG
 WIDTH="16" HEIGHT="15" ALIGN="BOTTOM" BORDER="0"
 SRC="|."$dir".q|img3.png"
 ALT="$\sim$">|; 

1;

