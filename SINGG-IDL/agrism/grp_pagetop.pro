PRO grp_pagetop, unit, title
   printf,unit,'<HTML>'
   printf,unit,'<HEAD>'
   printf,unit,'<TITLE>'+title+'</TITLE>'
   printf,unit,'</HEAD>'
   printf,unit,'<BODY bgcolor="#c0c0c0" text="#000000" link="#400080" vlink="#C40000" alink="#00A000">'
   printf,unit,'<H1>'
   printf,unit,title
   printf,unit,'</H1>'
END 

