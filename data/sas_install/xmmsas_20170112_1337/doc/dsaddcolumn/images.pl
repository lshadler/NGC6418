# LaTeX2HTML 2016 (1.71)
# Associate images original text with physical files.


$key = q/{code}dsaddcolumntable=myfile.ds:MYEXTname=col1type=int8units=kmlabel="Distance"{code};AAT/;
$cached_env_img{$key} = q|<IMG
 WIDTH="624" HEIGHT="14" ALIGN="BOTTOM" BORDER="0"
 SRC="|."$dir".q|img1.png"
 ALT="\begin{code}
dsaddcolumn table=myfile.ds:MYEXT name=col1 type=int8 units=km label=''Distance''
\end{code}">|; 

1;

