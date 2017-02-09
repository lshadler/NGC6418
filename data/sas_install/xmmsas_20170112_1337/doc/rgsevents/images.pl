# LaTeX2HTML 2016 (1.71)
# Associate images original text with physical files.


$key = q/^{nomath_inline{ddagnomath_inline{};MSF=1.6;AAT/;
$cached_env_img{$key} = q|<IMG
 WIDTH="11" HEIGHT="20" ALIGN="BOTTOM" BORDER="0"
 SRC="|."$dir".q|img4.png"
 ALT="$^{\ddag }$">|; 

$key = q/^{nomath_inline{dagnomath_inline{};MSF=1.6;AAT/;
$cached_env_img{$key} = q|<IMG
 WIDTH="11" HEIGHT="20" ALIGN="BOTTOM" BORDER="0"
 SRC="|."$dir".q|img3.png"
 ALT="$^{\dag }$">|; 

$key = q/nomath_inline}ddagnomath_inline};MSF=1.6;AAT/;
$cached_env_img{$key} = q|<IMG
 WIDTH="8" HEIGHT="27" ALIGN="MIDDLE" BORDER="0"
 SRC="|."$dir".q|img2.png"
 ALT="\ddag">|; 

$key = q/nomath_inline}dagnomath_inline};MSF=1.6;AAT/;
$cached_env_img{$key} = q|<IMG
 WIDTH="8" HEIGHT="27" ALIGN="MIDDLE" BORDER="0"
 SRC="|."$dir".q|img1.png"
 ALT="\dag">|; 

1;

