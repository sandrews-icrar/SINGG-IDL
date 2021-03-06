PRO ssoup_compresults, ll, sname, photplam, ebv, fprofs, fcomp
  ;
  ; Compare magnitudes and radii from SSOUP and what's in
  ; various databases
  ;
  ; sname  -> SINGG/HIPASS name
  ; fprofs -> profile file names
  ; fcomp  -> name of output comparison
  ;
  ; G. Meurer 6/2010
  odb     = 'singg_derived'
  udb1    = 'sungg_derived_2010'
  udb2    = 'sungg_derived_zz'
  prog    = 'SSOUP_COMPRESULTS: '
  hline1  = '#                         <---- Database ----> <------ SSOUP ------>'
  hline2  = '#SName         Band        R_50   mag    err      R_50   mag    err '
  wlv     = 5500.0
  COMMON bands, band, nband, bandnam, bandavail, nbandavail, combo, ncombo 
  plog,ll,prog,'------------------- starting '+prog+'-------------------------'
  ;
  ; need pivot wavelength of NUV & FUV.  Should
  ; be passed, but have defaults, just in case
  pn    = where(bandavail EQ band.NUV,npn)
  pf    = where(bandavail EQ band.FUV,npf)
  IF npn EQ 1 THEN wlnuv = photplam[pn] ELSE wlnuv = 2300.8
  IF npf EQ 1 THEN wlfuv = photplam[pf] ELSE wlfuv = 1535.1
  ;
  ; get data from UV data from sungg database
  udb     = udb1
  dbopen, udb
  entn    = dbfind('filter = nuv')
  entn    = dbmatch('sname', sname,entn)
  IF entn[0] LE 0 THEN BEGIN
     udb  = udb2
     dbclose
     dbopen,udb
     entn = dbfind('filter = nuv')
     entn = dbmatch('sname', sname,entn)
  ENDIF 
  nuu     = n_elements(entn)
  IF entn[0] LE 0 THEN BEGIN 
     plog,ll,prog,'**** warning object does not match either UV databases'
     udb    = '-'
     entn   = [-1.0]
     entf   = [-1.0]
     mnuv   = [99.99]
     mfuv   = [99.99]
     mnuv0  = [99.99]
     mfuv0  = [99.99]
     emnuv  = [9.99]
     emfuv  = [9.99]
     r50n   = [999.99]
     r50f   = [999.99]
     nuu    = 0
  ENDIF ELSE BEGIN
     dbext,entn,'flux_brt,flux_corr,mag_rms,r50_brt,entry_othfilt', $
                 fnuv,fnuv0,emnuv,r50n,entf
     dbext,entf,'flux_brt,flux_corr,mag_rms,r50_brt', $
                 ffuv,ffuv0,emfuv,r50f
     mfuv  = -2.5*alog10(ffuv) - 21.1 + 5.0*alog10(wlv/wlfuv)
     mfuv0 = -2.5*alog10(ffuv0) - 21.1 + 5.0*alog10(wlv/wlfuv)
     mnuv  = -2.5*alog10(fnuv) - 21.1 + 5.0*alog10(wlv/wlnuv)
     mnuv0 = -2.5*alog10(fnuv0) - 21.1 + 5.0*alog10(wlv/wlnuv)
  ENDELSE 
  dbclose
  ;
  plog,ll,prog,'number of matching entries in UV databases: '+numstr(nuu)
  plog,ll,prog,'UV matches from database: '+udb
  ;
  ; get optical results from Halpha database
  dbopen, odb
  list      = good_derived3()
  ento      = dbmatch('name', sname)
  IF ento[0] GT 0 THEN BEGIN 
     dbext, ento, 'mapp_r_t,err_mag_r_t,re_r_t,err_re_r_t', mr,emr,rer,erer
     dbext, ento, 'logf_ha_t,logf_ha0_t,err_logf_ha_t,re_ha_t,err_re_ha_t', $
            lfha,lfha0,elfha,reha,ereha
     noo    = n_elements(ento)
  ENDIF ELSE BEGIN
     noo    = 0
     mr     = [99.99]
     emr    = [9.99]
     rer    = [999.99]
     erer   = [9.99]
     lfha   = [99.99]
     lfha0  = [99.99]
     elfha  = [9.99]
     reha   = [999.99]
     ereha  = [9.99]
  ENDELSE
  dbclose
  plog,ll,prog,'number of matching entries in optical database: '+numstr(noo)
  ; TODO: these are hardcoded number of wavelengths. We can ignore these until we get MIR results...
  ; Need to also fix pp below.
  flx       = [lfha, mr, mnuv, mfuv]
  ;flx       = [lfha, mr, mnuv0, mfuv0]
  eflx      = [elfha, emr, emnuv, emfuv]
  r50       = [reha, rer, r50n, r50f]
  er50      = [ereha, erer, 0.0, 0.0]
  ;
  ; get deredden parameters
  dredf   = make_array(nbandavail, /float, value=1.0)
  IF ebv GT 0 THEN ccm_unred, photplam, dredf, ebv[0]
  plog,ll,prog,'will de-redden fluxes using the following band | wl | factor sets'
  FOR ii = 0, nbandavail-1 DO plog,ll,prog,'   '+ljust(bandavail[ii],6)+' | '+numstr(photplam[ii])+' | '+numstr(dredf[ii])
  ;
  ; loop through bands
  plog,ll,prog,'opening output comparison file: '+fcomp
  openw, lu, fcomp, /get_lun
  printf,lu,hline1
  printf,lu,hline2
  plog,ll,' ',hline1
  plog,ll,' ',hline2
  ;
  FOR ii = 0,nbandavail-1 DO BEGIN 
     if bandavail[ii] eq band.mir_W1 or bandavail[ii] eq band.mir_W2 or bandavail[ii] eq band.mir_W3 $
          or bandavail[ii] eq band.mir_W4 then continue ; TODO: get database results for comparison
     ;
     ; pointer to position in db arrays. No count because this will never be less than 0.
     pp     = where(tag_names(band) EQ bandavail[ii], /null)-4
     ;
     ; read header of file, that's where the info is...
     pixsize = 0.0
     pfplt_rdhdr, fprofs[ii], pixsize, filename, funits, fscale, fluxcal, $
                  proftype, numgals, galindex, xcenter, ycenter, $
                  axerat, posang, posangwc, skylev, skysigpx, skysigbx, $
                  rads, radf, radc, fluxs, fluxf, fluxt, flsigskys, flsigskyf, flsigskyt, $
                  flsigcnts, flsigcntf, flsigcntt, ref, ret, $
                  resigskyf, resigskyt, resigcntf, resigcntt, sef, set, $
                  lstart, lend, isoflag, netflag, /silent
     IF bandavail[ii] NE band.HALPHA THEN BEGIN 
        fits_read, filename, im, hd, /header_only
        m0      = sxpar(hd, 'magzpt1')
        flx_p   = m0 - 2.5*alog10(dredf[ii]*fluxf/fscale)
        eflx_p  = 2.5*alog10(1.0+flsigskyf/fluxf)
     ENDIF ELSE BEGIN
        flx_p   = alog10(fluxf*dredf[ii])
        eflx_p  = alog10(1.0+(flsigskyf^2 + flsigcntf^2)/fluxf)
     ENDELSE 
     r50_p   = ref
     ;
     ; print results for this band to log and output file
     str = ljust(sname,15)+ljust(bandavail[ii],8)+'  '+$
           string(r50[pp],format='(f6.2)')+' '+string(flx[pp],format='(f7.3)')+' '+string(eflx[pp],format='(f5.3)')+' | '+$
           string(r50_p,format='(f6.2)')+' '+string(flx_p,format='(f7.3)')+' '+string(eflx_p,format='(f5.3)')
     plog,ll,' ',str
     printf,lu,str
  ENDFOR 
  ;
  ; close output file
  plog, ll, prog, 'closing comparison file '+fcomp
  free_lun, lu
END 


