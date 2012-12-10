PRO calc_widths
   fhipass    = '../hipass_widths.dat'
   fout       = '../halpha_widths.dat'
   folders    = ['Run0410_n','Run0503_n','Run0603_n']
   xsize      = 1500
   ysize      = 600
   lamzero    = 6562.8169
   cvel       = 299792.458
   ;
   ; read filename list
   readcol, fhipass, filename, hipassid, hw50max, hw50min, hw20max, $
     hw20min, format='(a,a,f,f,f,f)'
   nfiles     = n_elements(filename)
   ;
   ; match filenames to folders
   fileno     = strmid(filename, 3)
   runno      = fix(strmid(fileno, 1, 1))
   nightno    = strmid(fileno, 3, 1)
   ;
   ; create filename strings
   fintspec   = '../'+folders(runno-1)+nightno+'/intspec'+fileno+'.cr.ms.fits'
   ;
   ; initialise window for plots
   window, 0, xsize=xsize, ysize=ysize
   ;
   ; make output arrays
   w50max     = make_array(nfiles)
   w50min     = make_array(nfiles)
   w20max     = make_array(nfiles)
   w20min     = make_array(nfiles)
   ;
   ; make output file
   openw, 1, fout
   printf, 1, '# File generated by calc_widths.pro at ' + systime()
   printf, 1, '#       filename   hipass id          w50max          w50min'+$
     '          w20max          w20min'
   ;
   ; loop over files
   FOR ii=0, nfiles-1 DO BEGIN
       ;
       ; open fits file
       spectra  = readfits(fintspec(ii), fitsheader)
       specdim  = size(spectra, /dimensions)
       ;
       ; read information from header
       delt1loc = where(strmid(fitsheader, 0, 6) EQ 'CDELT1')
       disper   = float(strmid(fitsheader(delt1loc), $
                             strpos(fitsheader(delt1loc), '=')+1))
       disper   = disper(0)
       crvalloc = where(strmid(fitsheader, 0, 6) EQ 'CRVAL1')
       crval    = float(strmid(fitsheader(crvalloc), $
                             strpos(fitsheader(crvalloc), '=')+1))
       crval    = crval(0)
       crpixloc = where(strmid(fitsheader, 0, 6) EQ 'CRPIX1')
       crpix    = float(strmid(fitsheader(crpixloc), $
                             strpos(fitsheader(crpixloc), '=')+1))
       crpix    = crpix(0)
       ;
       ; set wavelengths
       lamda1   = ((findgen(specdim(0)) - (crpix - 1)) * $
                     disper) + crval
       ;
       ; plot spectrum
       xx       = findgen(specdim(0))
       spectrum = spectra(*,1)
       plot, xx, spectrum
       ;
       ; ask for input on Halpha position
       print, 'Number of pixels = ', specdim(0)
       read, 'Lower limit: ', lower
       read, 'Upper limit: ', upper
       ;
       ; replot selected range
       xx       = findgen(upper - lower + 1)
       spectrum = spectrum(lower:upper)
       xlamda   = lamda1(lower:upper)
       plot, xx, spectrum
       ;
       ; ask for input on background ranges
       print, 'Max = ', upper - lower
       read, 'Left continuum low:   ', c0
       read, 'Left continuum high:  ', c1
       read, 'Right continuum low:  ', c2
       read, 'Right continuum high: ', c3
       ;
       ; calculate and remove background level
       cont     = mean([spectrum(c0:c1),spectrum(c2:c3)])
       spectrum = spectrum(c0:c3) - cont
       xlamda   = xlamda(c0:c3)
       peak     = max(spectrum, peakloc)
       p50      = 0.5*peak
       p20      = 0.2*peak
       ;
       ; find widths
       over50     = where(spectrum GE p50, no50, complement=under50, ncomplement=nu50)
       over20     = where(spectrum GE p20, no20, complement=under20, ncomplement=nu20)
       highpos    = over50(no50-1)
       lamhigh    = xlamda(highpos) + disper * (spectrum(highpos) - p50) / $
                          (spectrum(highpos) - spectrum(highpos + 1))
       lowpos     = over50(0)
       lamlow     = xlamda(lowpos) - disper * (spectrum(lowpos) - p50) / $
                          (spectrum(lowpos) - spectrum(lowpos - 1))
       w50max(ii) = lamhigh - lamlow
       highpos    = over20(no20-1)
       lamhigh    = xlamda(highpos) + disper * (spectrum(highpos) - p20) / $
                          (spectrum(highpos) - spectrum(highpos + 1))
       lowpos     = over20(0)
       lamlow     = xlamda(lowpos) - disper * (spectrum(lowpos) - p20) / $
                          (spectrum(lowpos) - spectrum(lowpos - 1))
       w20max(ii) = lamhigh - lamlow
       under50op  = where(under50 GT peakloc, nu50op, complement=under50up, $
                          ncomplement=nu50up)
       under20op  = where(under20 GT peakloc, nu20op, complement=under20up, $
                          ncomplement=nu20up)
       highpos    = under50(under50op(0)) - 1
       lamhigh    = xlamda(highpos) + disper * (spectrum(highpos) - p50) / $
                          (spectrum(highpos) - spectrum(highpos + 1))
       lowpos     = under50(under50up(nu50up-1)) + 1
       lamlow     = xlamda(lowpos) - disper * (spectrum(lowpos) - p50) / $
                          (spectrum(lowpos) - spectrum(lowpos - 1))
       w50min(ii) = lamhigh - lamlow
       highpos    = under20(under20op(0)) - 1
       lamhigh    = xlamda(highpos) + disper * (spectrum(highpos) - p20) / $
                          (spectrum(highpos) - spectrum(highpos + 1))
       lowpos     = under20(under20up(nu20up-1)) + 1
       lamlow     = xlamda(lowpos) - disper * (spectrum(lowpos) - p20) / $
                          (spectrum(lowpos) - spectrum(lowpos - 1))
       w20min(ii) = lamhigh - lamlow
       ;
       ; convert wavelengths to velocities
       w50max(ii)  = w50max(ii) * cvel / lamzero
       w50min(ii)  = w50min(ii) * cvel / lamzero
       w20max(ii)  = w20max(ii) * cvel / lamzero
       w20min(ii)  = w20min(ii) * cvel / lamzero
       ;
       ; print to output file
       printf, 1, filename(ii), hipassid(ii), w50max(ii), $
         w50min(ii), w20max(ii), w20min(ii), format='(a16,a12,4f16)'
   ENDFOR
   close, 1
END