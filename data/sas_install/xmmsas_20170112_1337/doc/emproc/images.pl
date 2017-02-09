# LaTeX2HTML 2016 (1.71)
# Associate images original text with physical files.


$key = q/|;MSF=1.6;AAT/;
$cached_env_img{$key} = q|<IMG
 WIDTH="8" HEIGHT="32" ALIGN="MIDDLE" BORDER="0"
 SRC="|."$dir".q|img2.png"
 ALT="$\vert$">|; 

$key = q/ge;MSF=1.6;AAT/;
$cached_env_img{$key} = q|<IMG
 WIDTH="16" HEIGHT="30" ALIGN="MIDDLE" BORDER="0"
 SRC="|."$dir".q|img3.png"
 ALT="$\ge$">|; 

$key = q/epsfig{file=emproc.epsi,width=.8textwidth};AAT/;
$cached_env_img{$key} = q|<IMG
 WIDTH="572" HEIGHT="745" ALIGN="BOTTOM" BORDER="0"
 SRC="|."$dir".q|img1.png"
 ALT="\epsfig{file=emproc.epsi,width=.8\textwidth}">|; 

$key = q/le;MSF=1.6;AAT/;
$cached_env_img{$key} = q|<IMG
 WIDTH="16" HEIGHT="30" ALIGN="MIDDLE" BORDER="0"
 SRC="|."$dir".q|img4.png"
 ALT="$\le$">|; 

1;

