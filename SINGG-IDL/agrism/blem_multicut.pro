PRO blem_multicut, window, wsz, chan, ic, spgr, spgf, spgf2, spdr, spdf, spdf2, idstr, $
                   nid, sexid, imin, imax, outpng=outpng, wpos=wpos, dxoff=dxoff
   ;
   ; Multiple plots of 1d cut spectra
   ;
   ; window -> window to plot to
   ; wsz    -> size of window (2 element array)
   ; chan   -> channel numbers of extraction.(array units)
   ; ic     -> line position to nearest pixel (array units)
   ; spgr   -> raw grism spec
   ; spgf   -> filtered grism spec
   ; spgf2  -> normalized and widowed filtered grism spec.
   ; spdr   -> raw direct image
   ; spdf   -> filtered direct image
   ; spdf2  -> Normalized & filtered 
   ; idstr  -> identification string.
   ; outpng -> if set the name of the output png file.
   ; dxoff  -> x offset between direct and grism image 
   ;           (xdirect - xgrism) - needed for pears data
   ;
   ; G. Meurer 2002+
   ; G. Meurer 7/2006 add dxoff keyword
   ;
   IF keyword_set(wpos) THEN window,window,xsize=wsz[0],ysize=wsz[1],xpos=wpos[0],ypos=wpos[1] $
                        ELSE window,window,xsize=wsz[0],ysize=wsz[1]
   !P.MULTI = [0,1,3]
   title0   = 'Grism image cuts.  Grism catalog source : '+idstr
   xtitle0  = 'Channel'
   ytitle0  = 'Counts'
   title1   = 'Direct image cuts.  Grism catalog source : '+idstr
   xtitle1  = 'Channel'
   ytitle1  = 'Counts'
   title2   = 'Pre-cross-correlation cuts.  Grism catalog source : '+idstr
   xtitle2  = 'Offset'
   ytitle2  = 'Counts / RMS(clipped)'
   ;
   IF NOT keyword_set(dxoff) THEN dxo = 0 ELSE dxo = dxoff
   ;
   ; convert to display units
   chan1    = chan + 1
   chand1   = chan1 + dxo
   ;
   ; limits
   xr       = [min(chan1), max(chan1)]
   y0       = min([spgr, spgf])
   y1       = max([spgr, spgf])
   dy       = y1 - y0
   yr0      = [y0-0.05*dy,y1+0.05*dy]
   y0       = min([spdr, spdf])
   y1       = max([spdr, spdf])
   dy       = y1 - y0
   yr1      = [y0-0.05*dy,y1+0.2*dy]
   yanot1   = y1 + 0.08*dy
   y0       = min([spdf2, spgf2])
   y1       = max([spdf2, spgf2])
   dy       = y1 - y0
   dx       = chan - ic
   xr2      = xr - ic
   yr2      = [y0-0.05*dy,y1+0.2*dy]
   yanot2   = y1 + 0.08*dy
   cid      = [!lblue, !lcyan, !lgreen, !lyellow, !tan, !lgray]
   ncid     = n_elements(cid)
   ;
   ; Plot 0: grism image cuts
   plot, chan1, spgr, xrange=xr, yrange=yr0, xstyle=1, ystyle=1, psym=10, color=!black, $
    charsize=1.8, xtitle=xtitle0, ytitle=ytitle0, title=title0
   oplot, chan1, spgr, psym=10, color=!black
   oplot, chan1, spgf, psym=10, color=!blue
   ;
   ; Plot 1: direct image cuts
   plot, chand1, spdr, xrange=xr+dxo, yrange=yr1, xstyle=1, ystyle=1, psym=10, color=!black, $
    charsize=1.8, xtitle=xtitle1, ytitle=ytitle1, title=title1
   ;
   ; mark location of sextractor sources
   IF nid GT 0 THEN BEGIN 
      FOR i = 0, nid-1 DO BEGIN 
         col = cid[i MOD ncid] 
         xbx = [chand1[imin[i]], chand1[imin[i]], chand1[imax[i]], chand1[imax[i]]]
         ybx = [yr1[0], yr1[1], yr1[1], yr1[0]]
         polyfill, xbx, ybx, color=col
      ENDFOR 
      FOR i = 0, nid-1 DO BEGIN 
         xanot = 0.5*(chand1[imin[i]] + chand1[imax[i]])
         xyouts, xanot, yanot1, strtrim(sexid[i],2), alignment=0.5, color=!black
      ENDFOR 
   ENDIF 
   ;
   ; replot direct image cuts
   oplot, chand1, spdr, psym=10, color=!black
   oplot, chand1, spdf, psym=10, color=!blue
   ;
   ; Plot 2: pre-crcor cuts
   plot, dx, spgf2, xrange=xr2, yrange=yr2, xstyle=1, ystyle=1, psym=10, color=!black, $
    charsize=1.8, xtitle=xtitle2, ytitle=ytitle2, title=title2
   ;
   ; mark location of sextractor sources
   IF nid GT 0 THEN BEGIN 
      FOR i = 0, nid-1 DO BEGIN 
         col = cid[i MOD ncid] 
         xbx = [dx[imin[i]], dx[imin[i]], dx[imax[i]], dx[imax[i]]]
         ybx = [yr2[0], yr2[1], yr2[1], yr2[0]]
         polyfill, xbx, ybx, color=col
      ENDFOR 
      FOR i = 0, nid-1 DO BEGIN 
         xanot = 0.5*(dx[imin[i]] + dx[imax[i]])
         xyouts, xanot, yanot2, strtrim(sexid[i],2), alignment=0.5, color=!black
      ENDFOR 
   ENDIF 
   ;
   ; replot direct image cuts
   oplot, dx, spgf2, psym=10, color=!dgreen
   oplot, dx, spdf2, psym=10, color=!purple
   ;
   ; output png file
   IF keyword_set(outpng) THEN makepng,outpng,/color
END 

