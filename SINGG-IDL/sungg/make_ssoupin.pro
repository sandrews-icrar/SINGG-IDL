PRO make_ssoupin, status, ll=ll, wd=wd, hname=hname, file=file
  ;
  ; make an input file for ssoup
  ;
  ;   ll    -> logical unit for reporting progress.  If not set then 
  ;            ll = -1 (output to terminal)
  ;   wd    -> if set, the name of the directory containing 
  ;            the files to be processed by ssoup.  If not set the
  ;            default is the current directory.
  ;   hname -> name of HIPASS target to be processed.
  ;   file  -> name of the ssoup input file to be created.  If not set
  ;            a file ssoup.in will be created.
  ;  
  ; G. Meurer (ICRAR/UWA) 6/2010
  ; G. Meurer (ICRAR/UWA) 1/2012
  ;    + improved default for Rsub image name, to handle case of
  ;      J0008-59 (NB filter included in im name)
  ;    + improved default for R mask name also for case of 
  ;      J0008-59; now tries either hname+'_mask.fits' and
  ;      hname+'_R_mask.fits'
  ;
  rulen      = '*'+['-nd-int.fits', '_nuv.fits']
  rulef      = '*'+['-fd-int.fits', '_fuv.fits']
  ; some arrays we will need later
  bandavail = ['']
  fili  = ['']
  film  = ['']
  skyord = [0]
  COMMON bands, band, nband, bandnam, aaaa1, aaaa2, aaaa3, aaaa4 ; sigh
  ssoup_initvars
  ;
  ; set logical unit for log file
  IF NOT keyword_set(ll) THEN ll = -1
  prog      = 'MAKE_SSOUPIN: '
  plog,ll,prog,'------------------------ starting '+prog+'-------------------------'
  ;
  ; go to initial directory if needed
  IF keyword_set(wd) THEN BEGIN 
     plog,ll,prog,'going to working directory : '+wd
     cd,wd,current=cwd
  ENDIF 
  ;
  ; determine HIPASS target name
  IF NOT keyword_set(hname) THEN BEGIN 
     sstr  = '*_ss.fits'
     flist = file_search(sstr)
     jj    = strpos(flist[0],'_')
     IF jj GT 0 THEN BEGIN 
        hname = strmid(flist[0],0,jj)
     Endif ELSE BEGIN 
        plog,ll,prog,'could not guess HIPASS target name using file search string: "'+sstr+'", exiting.'
        status = 0b
        return
     ENDELSE 
     plog,ll,prog,'will use derived HIPASS target name: '+hname
  ENDIF ELSE BEGIN 
     plog,ll,prog,'will use passed HIPASS target name: '+hname
  ENDELSE 
  ;
  ; find Halpha image
  sstr     = '*_?sub_ss.fits'
  fili_ha  = file_search(hname+sstr,count=count)
  IF count EQ 0 THEN BEGIN 
     plog,ll,prog,'could not find Halpha image using search string: "'+sstr+'", exiting'
     status = 0b
     return
  ENDIF ELSE BEGIN 
     fili  = [fili,  fili_ha[0]]
     bandavail = [bandavail, band.HALPHA]
     skyord = [skyord, 2]
  ENDELSE 
  ;
  ; find R image
  sstr     = hname+'_?_ss.fits'
  fili_r   = file_search(sstr,count=count)
  IF count EQ 0 THEN BEGIN 
     plog,ll,prog,'could not find R band image using search string: "'+sstr+'", exiting'
     status = 0b
     return
  ENDIF ELSE BEGIN 
     fili  = [fili,  fili_r[0]]
     bandavail = [bandavail, band.R]
     skyord = [skyord, 2]
  ENDELSE 
  ;
  ; find NUV image
  nr       = n_elements(rulen)
  ii       = 0
  repeat begin 
     sstr     = rulen[ii]
     fili_nuv = file_search(sstr,count=count)
     IF count EQ 0 THEN BEGIN 
        plog,ll,prog,'could not find NUV band image using search string: "'+sstr+'" ...'
     ENDIF ELSE BEGIN 
        fili  = [fili,  fili_nuv[0]]
        bandavail = [bandavail, band.NUV]
        skyord = [skyord, 1]
     ENDELSE
     ii    = ii + 1
  endrep until ((ii eq nr) or (count gt 0))
  if count eq 0 then begin
     plog,ll,prog,'could not find NUV band image using any rule, exiting'
     status = 0b
  endif
  ;
  ; find FUV image
  nr       = n_elements(rulef)
  ii       = 0
  repeat begin 
     sstr     = rulef[ii]
     fili_fuv = file_search(sstr,count=count)
     IF count EQ 0 THEN BEGIN 
        plog,ll,prog,'could not find FUV band image using search string: "'+sstr+'" ...'
     ENDIF ELSE BEGIN 
        fili  = [fili,  fili_fuv[0]]
        bandavail = [bandavail, band.FUV]
        skyord = [skyord, 1]
     ENDELSE
     ii    = ii + 1
  endrep until ((ii eq nr) or (count gt 0))
  if count eq 0 then begin
     plog,ll,prog,'could not find FUV band image using any rule, exiting'
     status = 0b
  endif 
  ; find Wise images
  for i=1,4 do begin
      ; raw filenames coming out of http://irsa.ipac.caltech.edu/applications/wise are really stupid
      ; please rename your images first
      si = strtrim(string(i),1) ; WTH, IDL?
      sstr = hname+'-wisssssse-w'+si+'.fits' 
      fili_wise = file_search(sstr, count=count)
      if count eq 0 then begin
          plog,ll,prog,'could not find Wise W'+si+' band image using search string: "'+sstr+'" ...'
      endif else begin ; these aren't essential
          fili = [fili, fili_wise]
          bandavail = [bandavail, 'W'+si]
          skyord = [skyord, 1]
          film = [film, ''] ; we don't have masks yet
      endelse
  endfor
  ;
  ; find Halpha mask image
  sstr    = hname+'*_*sub_mask.fits'
  film_ha = file_search(sstr,count=count)
  IF count EQ 0 THEN BEGIN 
     plog,ll,prog,'**** warning Halpha mask could not be found using search string: "'+sstr+'"'
     film_ha  = hname+'_Rsub_mask.fits'
     plog,ll,prog,'continuing using default name: '+film_ha
  ENDIF ELSE BEGIN 
     film  = [film, film_ha[0]]
  ENDELSE
  ;
  ; find R mask image
  film_r   = hname+'_mask.fits'
  inf      = file_info(film_r)
  IF NOT inf.exists THEN BEGIN 
     try1  = film_r
     try2  = hname+'_R_mask.fits'
     inf   = file_info(try2)
     IF inf.exists THEN BEGIN 
        film = [film, try2]
     ENDIF ELSE BEGIN 
        plog,ll,prog,'**** warning could not find either guesses for R mask: '+try1+' , '+try2
        plog,ll,prog,'continuing, anyway (but you will want to fix this)...'
        film = [film, try1]
     ENDELSE 
  ENDIF else begin
      film = [film, film_r]
  endelse
  ;
  ; find UV mask image
  sstr     = '*_uv_mask.fits'
  filmuv   = file_search(sstr,count=count)
  IF count eq 0 THEN BEGIN 
     ;
     ; that didn't work try another guess
     plog,ll,prog,'could not find file containing: '+sstr+'  will try another guess.'
     sstr  = '*mask.fuv.fits'
     filmuv = file_search(sstr,count=count)
     if count gt 0 then begin 
        film = [film, filmuv[0], filmuv[0]]
     endif else begin 
        plog,ll,prog,'**** warning could not find a UV mask file using search string : '+sstr+'  continuing, anyway ...'
     endelse 
  ENDIF else begin 
     film = [film, filmuv[0], filmuv[0]]
  endelse 
  ; trim arrays
  bandavail = bandavail[1:*]
  fili = fili[1:*]
  film = film[1:*]
  skyord = skyord[1:*]
  nbandavail = n_elements(bandavail)
  ;
  ; derive other names
  filo = strarr(nbandavail)
  filp = strarr(nbandavail)
  fbox = strarr(nbandavail)
  fbplot_jpg = strarr(nbandavail)
  fbplot_eps = strarr(nbandavail)
  ; silly little hack
  ih = where(bandavail eq band.HALPHA, nih)
  if nih gt 0 then bandavail[ih[0]] = 'Halpha'
  for i=0,nbandavail-1 do begin
      filo[i] = hname+'_aligned_' + bandavail[i] + '.fits'
      filp[i] = hname+'_aligned_' + bandavail[i] + '.profile'
      fbox[i] = hname+'_aligned_box_' + bandavail[i] + '.dat'
      fbplot_jpg[i] = hname+'_aligned_skyplot_' + bandavail[i] + '.jpg'
      fbplot_eps[i] = hname+'_aligned_skyplot_' + bandavail[i] + '.eps'
  endfor
  if nih gt 0 then bandavail[ih[0]] = band.HALPHA ; unhack
  film_out        = hname+'_aligned_mask.fits'
  film_sout       = hname+'_aligned_skymask.fits'
  fcompare        = hname+'_compare.dat'
  scalprof        = hname+'_aligned_sprof.dat'
  fcalprof        = hname+'_aligned_fprof.dat'
  scalprof0       = hname+'_aligned_sprof0.dat'
  fcalprof0       = hname+'_aligned_fprof0.dat'
  profjpg         = hname+'_aligned_sprof.jpg'
  profps          = hname+'_aligned_sprof.ps'
  hafuvjpg        = hname+'_aligned_hafuv.jpg'
  hafuvps         = hname+'_aligned_hafuv.ps'
  hafuvjpg0       = hname+'_aligned_hafuv0.jpg'
  hafuvps0        = hname+'_aligned_hafuv0.ps'
  
  ; combos
  ncombo = factorial(nbandavail)/(6*factorial(nbandavail-3)) ; number of 3 color combos
  combo = transpose(combigen(nbandavail, 3))
  combostr = strlowcase(string(strmid(bandavail[combo], 0, 1), format='(3A)')) ; generates hrn, hrf, etc.
  fjpgl = strarr(ncombo)
  fjpgh = strarr(ncombo)
  fjpgl_msk1 = strarr(ncombo)
  fjpgh_msk1 = strarr(ncombo)
  fjpgl_msk2 = strarr(ncombo)
  fjpgh_msk2 = strarr(ncombo)
  fjpgl_msk3 = strarr(ncombo)
  fjpgh_msk3 = strarr(ncombo)
  fjpgl_imsk1 = strarr(ncombo)
  fjpgh_imsk1 = strarr(ncombo)
  fjpgl_imsk2 = strarr(ncombo)
  fjpgh_imsk2 = strarr(ncombo)
  fjpgl_imsk3 = strarr(ncombo)
  fjpgh_imsk3 = strarr(ncombo)
  for i=0,ncombo-1 do begin
      fjpgl[i]       = hname + '_aligned_'       + combostr[i] + '1.jpg'
      fjpgh[i]       = hname + '_aligned_'       + combostr[i] + '2.jpg'
      fjpgl_msk1[i]  = hname + '_aligned_msk1_'  + combostr[i] + '1.jpg'
      fjpgh_msk1[i]  = hname + '_aligned_msk1_'  + combostr[i] + '2.jpg'
      fjpgl_msk2[i]  = hname + '_aligned_msk2_'  + combostr[i] + '1.jpg'
      fjpgh_msk2[i]  = hname + '_aligned_msk2_'  + combostr[i] + '2.jpg'
      fjpgl_msk3[i]  = hname + '_aligned_msk3_'  + combostr[i] + '1.jpg'
      fjpgh_msk3[i]  = hname + '_aligned_msk3_'  + combostr[i] + '2.jpg'
      fjpgl_imsk1[i] = hname + '_aligned_imsk1_' + combostr[i] + '1.jpg'
      fjpgh_imsk1[i] = hname + '_aligned_imsk1_' + combostr[i] + '2.jpg'
      fjpgl_imsk2[i] = hname + '_aligned_imsk2_' + combostr[i] + '1.jpg'
      fjpgh_imsk2[i] = hname + '_aligned_imsk2_' + combostr[i] + '2.jpg'
      fjpgl_imsk3[i] = hname + '_aligned_imsk3_' + combostr[i] + '1.jpg'
      fjpgh_imsk3[i] = hname + '_aligned_imsk3_' + combostr[i] + '2.jpg'
  endfor
  ;
  ; open output file
  IF NOT keyword_set(file) THEN file = 'ssoup.in'
  plog,ll,prog,'creating input file for SSOUP : '+file
  openw,lu,file,/get_lun
  ; 
  ; write output file, copy to log file
  printf,lu, 'HNAME           = '+hname
  plog,ll,'','HNAME           = '+hname
  for i=0,nbandavail-1 do begin
      printf,lu, 'FILI_'       + bandavail[i] + ' = ' + fili[i]
      plog,ll,'','FILI_'       + bandavail[i] + ' = ' + fili[i]
      printf,lu, 'FILM_'       + bandavail[i] + ' = ' + film[i]
      plog,ll,'','FILM_'       + bandavail[i] + ' = ' + film[i]
      printf,lu, 'FILO_'       + bandavail[i] + ' = ' + filo[i]
      plog,ll,'','FILO_'       + bandavail[i] + ' = ' + filo[i]
      printf,lu, 'SKYORD_'     + bandavail[i] + ' = ' + strtrim(string(skyord[i]),2)
      plog,ll,'','SKYORD_'     + bandavail[i] + ' = ' + strtrim(string(skyord[i]),2)
      printf,lu, 'FILP_'       + bandavail[i] + ' = ' +filp[i]
      plog,ll,'','FILP_'       + bandavail[i] + ' = ' +filp[i]
      printf,lu, 'FBOX_'       + bandavail[i] + ' = ' +fbox[i]
      plog,ll,'','FBOX_'       + bandavail[i] + ' = ' +fbox[i]
      printf,lu, 'FBPLOT_JPG_' + bandavail[i] + ' = ' +fbplot_jpg[i]
      plog,ll,'','FBPLOT_JPG_' + bandavail[i] + ' = ' +fbplot_jpg[i]
      printf,lu, 'FBPLOT_EPS_' + bandavail[i] + ' = ' +fbplot_eps[i]
      plog,ll,'','FBPLOT_EPS_' + bandavail[i] + ' = ' +fbplot_eps[i]
  endfor
  printf,lu, 'FILM_OUT        = '+film_out
  plog,ll,'','FILM_OUT        = '+film_out
  printf,lu, 'FILM_SOUT       = '+film_sout
  plog,ll,'','FILM_SOUT       = '+film_sout
  combostr = strupcase(combostr)
  for i=0,ncombo-1 do begin
      printf,lu, 'FJPGL_'       + combostr[i] + ' = ' + fjpgl[i]
      plog,ll,'','FJPGL_'       + combostr[i] + ' = ' + fjpgl[i]
      printf,lu, 'FJPGH_'       + combostr[i] + ' = ' + fjpgh[i]
      plog,ll,'','FJPGH_'       + combostr[i] + ' = ' + fjpgh[i]
      printf,lu, 'FJPGL_MSK1_'  + combostr[i] + ' = ' + fjpgl_msk1[i]
      plog,ll,'','FJPGL_MSK1_'  + combostr[i] + ' = ' + fjpgl_msk1[i]
      printf,lu, 'FJPGH_MSK1_'  + combostr[i] + ' = ' + fjpgh_msk1[i]
      plog,ll,'','FJPGH_MSK1_'  + combostr[i] + ' = ' + fjpgh_msk1[i]
      printf,lu, 'FJPGL_MSK2_'  + combostr[i] + ' = ' + fjpgl_msk2[i]
      plog,ll,'','FJPGL_MSK2_'  + combostr[i] + ' = ' + fjpgl_msk2[i]
      printf,lu, 'FJPGH_MSK2_'  + combostr[i] + ' = ' + fjpgh_msk2[i]
      plog,ll,'','FJPGH_MSK2_'  + combostr[i] + ' = ' + fjpgh_msk2[i]      
      printf,lu, 'FJPGL_MSK3_'  + combostr[i] + ' = ' + fjpgl_msk3[i]
      plog,ll,'','FJPGL_MSK3_'  + combostr[i] + ' = ' + fjpgl_msk3[i]
      printf,lu, 'FJPGH_MSK3_'  + combostr[i] + ' = ' + fjpgh_msk3[i]
      plog,ll,'','FJPGH_MSK3_'  + combostr[i] + ' = ' + fjpgh_msk3[i]
      printf,lu, 'FJPGL_IMSK1_' + combostr[i] + ' = ' + fjpgl_imsk1[i]
      plog,ll,'','FJPGL_IMSK1_' + combostr[i] + ' = ' + fjpgl_imsk1[i]
      printf,lu, 'FJPGH_IMSK1_' + combostr[i] + ' = ' + fjpgh_imsk1[i]
      plog,ll,'','FJPGH_IMSK1_' + combostr[i] + ' = ' + fjpgh_imsk1[i]
      printf,lu, 'FJPGL_IMSK2_' + combostr[i] + ' = ' + fjpgl_imsk2[i]
      plog,ll,'','FJPGL_IMSK2_' + combostr[i] + ' = ' + fjpgl_imsk2[i]
      printf,lu, 'FJPGH_IMSK2_' + combostr[i] + ' = ' + fjpgh_imsk2[i]
      plog,ll,'','FJPGH_IMSK2_' + combostr[i] + ' = ' + fjpgh_imsk2[i]      
      printf,lu, 'FJPGL_IMSK3_' + combostr[i] + ' = ' + fjpgl_imsk3[i]
      plog,ll,'','FJPGL_IMSK3_' + combostr[i] + ' = ' + fjpgl_imsk3[i]
      printf,lu, 'FJPGH_IMSK3_' + combostr[i] + ' = ' + fjpgh_imsk3[i]
      plog,ll,'','FJPGH_IMSK3_' + combostr[i] + ' = ' + fjpgh_imsk3[i]
  endfor
  printf,lu, 'FCOMPARE        = '+fcompare
  plog,ll,'','FCOMPARE        = '+fcompare
  printf,lu, 'SCALPROF        = '+scalprof
  plog,ll,'','SCALPROF        = '+scalprof
  printf,lu, 'FCALPROF        = '+fcalprof
  plog,ll,'','FCALPROF        = '+fcalprof
  printf,lu, 'SCALPROF0       = '+scalprof0
  plog,ll,'','SCALPROF0       = '+scalprof0
  printf,lu, 'FCALPROF0       = '+fcalprof0
  plog,ll,'','FCALPROF0       = '+fcalprof0
  printf,lu, 'PROFJPG         = '+profjpg
  plog,ll,'','PROFJPG         = '+profjpg
  printf,lu, 'PROFPS          = '+profps
  plog,ll,'','PROFPS          = '+profps
  printf,lu, 'HAFUVJPG        = '+hafuvjpg
  plog,ll,'','HAFUVJPG        = '+hafuvjpg
  printf,lu, 'HAFUVPS         = '+hafuvps
  plog,ll,'','HAFUVPS         = '+hafuvps
  printf,lu, 'HAFUVJPG0       = '+hafuvjpg0
  plog,ll,'','HAFUVJPG0       = '+hafuvjpg0
  printf,lu, 'HAFUVPS0        = '+hafuvps0
  plog,ll,'','HAFUVPS0        = '+hafuvps0
  ;
  ; close output file
  free_lun,lu
  plog,ll,prog,'closed file: '+file
  ;
  ; return to original directory if needed.
  IF keyword_set(wd) THEN BEGIN 
     plog,ll,prog,'returning to starting directory : '+cwd
     cd,cwd
  ENDIF 
  ;
  status = 1b
  plog,ll,prog,'returning with status = '+numstr(fix(status))
END 
