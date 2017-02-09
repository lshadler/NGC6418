# LaTeX2HTML 2016 (1.71)
# Associate images original text with physical files.


$key = q/I_{x,y};MSF=1.6;AAT/;
$cached_env_img{$key} = q|<IMG
 WIDTH="30" HEIGHT="30" ALIGN="MIDDLE" BORDER="0"
 SRC="|."$dir".q|img2.png"
 ALT="$I_{x,y}$">|; 

$key = q/pi;MSF=1.6;AAT/;
$cached_env_img{$key} = q|<IMG
 WIDTH="14" HEIGHT="13" ALIGN="BOTTOM" BORDER="0"
 SRC="|."$dir".q|img5.png"
 ALT="$\pi$">|; 

$key = q/arctan(nabla_yslashnabla_x);MSF=1.6;AAT/;
$cached_env_img{$key} = q|<IMG
 WIDTH="111" HEIGHT="32" ALIGN="MIDDLE" BORDER="0"
 SRC="|."$dir".q|img4.png"
 ALT="$\arctan(\nabla_y/\nabla_x)$">|; 

$key = q/{displaymath}(nablaI)_{x,y}=frac{1}{6}left(array{{c}sum_{j=y-1}^{y+1}I_{x+1,j}-s^{x+1}I_{i,y+1}-sum_{i=x-1}^{x+1}I_{i,y-1}array{right).{displaymath};MSF=1.6;AAT/;
$cached_env_img{$key} = q|<IMG
 WIDTH="355" HEIGHT="69" BORDER="0"
 SRC="|."$dir".q|img1.png"
 ALT="\begin{displaymath}
(\nabla I)_{x,y} = \frac{1}{6} \left( \begin{array}{c}
\sum_...
...i,y+1} - \sum_{i=x-1}^{x+1} I_{i,y-1} \\\\
\end{array} \right).
\end{displaymath}">|; 

$key = q/x,y;MSF=1.6;AAT/;
$cached_env_img{$key} = q|<IMG
 WIDTH="28" HEIGHT="30" ALIGN="MIDDLE" BORDER="0"
 SRC="|."$dir".q|img3.png"
 ALT="$x,y$">|; 

1;

