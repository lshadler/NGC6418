# LaTeX2HTML 2016 (1.71)
# Associate images original text with physical files.


$key = q/{code}efluxerspectrumset=my_src.dsarfset=my_src.arfrespset=my_src.rmffluxedset=my_src_fluxed.ds{code};AAT/;
$cached_env_img{$key} = q|<IMG
 WIDTH="674" HEIGHT="14" ALIGN="BOTTOM" BORDER="0"
 SRC="|."$dir".q|img2.png"
 ALT="\begin{code}
efluxer spectrumset=my\_src.ds arfset=my\_src.arf respset=my\_src.rmf fluxedset=my\_src\_fluxed.ds
\end{code}">|; 

$key = q/^{2};MSF=1.6;AAT/;
$cached_env_img{$key} = q|<IMG
 WIDTH="11" HEIGHT="18" ALIGN="BOTTOM" BORDER="0"
 SRC="|."$dir".q|img1.png"
 ALT="$^{2}$">|; 

$key = q/{code}efluxerspectrumset=my_src.dsarfset=my_src.arfrespset=my_src.rmfbackgndset=my_bgd.dsfluxedset=my_srcbgd_fluxed.ds{code};AAT/;
$cached_env_img{$key} = q|<IMG
 WIDTH="717" HEIGHT="33" ALIGN="BOTTOM" BORDER="0"
 SRC="|."$dir".q|img3.png"
 ALT="\begin{code}
efluxer spectrumset=my\_src.ds arfset=my\_src.arf respset=my\_src.rmf backgndset=my\_bgd.ds fluxedset=my\_srcbgd\_fluxed.ds
\end{code}">|; 

1;

