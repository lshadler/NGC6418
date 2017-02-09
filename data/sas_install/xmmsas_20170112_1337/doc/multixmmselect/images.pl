# LaTeX2HTML 2016 (1.71)
# Associate images original text with physical files.


$key = q/1<={{tt{centerpaneheight}<=10;MSF=1.6;AAT/;
$cached_env_img{$key} = q|<IMG
 WIDTH="229" HEIGHT="30" ALIGN="MIDDLE" BORDER="0"
 SRC="|."$dir".q|img2.png"
 ALT="$1&lt;={\tt centerpaneheight}&lt;=10$">|; 

$key = q/epsfig{file=multixmmselectGUI.epsi,height=18cm};AAT/;
$cached_env_img{$key} = q|<IMG
 WIDTH="587" HEIGHT="815" ALIGN="BOTTOM" BORDER="0"
 SRC="|."$dir".q|img1.png"
 ALT="\epsfig{file=multixmmselectGUI.epsi,height=18cm}">|; 

1;

