# LaTeX2HTML 2016 (1.71)
# Associate images original text with physical files.


$key = q/{figure}center{{epsfig{file=calview_view_menu.ps,height=5cm}{{{center{{figure};FSF=1.6;AAT/;
$cached_env_img{$key} = q|<IMG
 WIDTH="151" HEIGHT="226" BORDER="0"
 SRC="|."$dir".q|img3.png"
 ALT="\begin{figure}\begin{center}
\epsfig{file=calview_view_menu.ps,height=5cm}
\end{center}\end{figure}">|; 

$key = q/{figure}center{{epsfig{file=calview_gui.ps,width=10cm}{{{center{{figure};FSF=1.6;AAT/;
$cached_env_img{$key} = q|<IMG
 WIDTH="452" HEIGHT="665" BORDER="0"
 SRC="|."$dir".q|img2.png"
 ALT="\begin{figure}\begin{center}
\epsfig{file=calview_gui.ps,width=10cm}
\end{center}\end{figure}">|; 

$key = q/approx100;MSF=1.6;AAT/;
$cached_env_img{$key} = q|<IMG
 WIDTH="45" HEIGHT="13" ALIGN="BOTTOM" BORDER="0"
 SRC="|."$dir".q|img1.png"
 ALT="$\approx 100$">|; 

1;

