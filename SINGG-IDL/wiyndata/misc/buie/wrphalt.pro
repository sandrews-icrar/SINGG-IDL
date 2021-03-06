;+
; NAME:
;  wrphalt
; PURPOSE: (one line)
;  Write a photometry log file.
; DESCRIPTION:
;
; CATEGORY:
;  File I/O
; CALLING SEQUENCE:
;  wrphalt,logname,filename,obj,fil,jd,exptime,gain,rad,sky1,sky2,serial, $
;           xpos,ypos,fwhm,maxcnt,sky,skyerr,mag,err,bad
; INPUTS:
;  logname  - string containing the photometry log file to write to.
;  filename - Original image file name for each point.
;  obj      - String array containing all object names.
;  fil      - String array with filter codes.
;  jd       - Julian date of mid-time of observation.
;  exptime  - Exposure time in seconds.
;  gain     - Gain of system in photons per count.
;  rad      - Radius of object aperture in pixels.
;  sky1     - Inner radius of sky annulus in pixels.
;  sky2     - Outer radius of sky annulus in pixels.
;  serial   - Serial number for observation.
;  xpos     - vector containing the x position for each point.
;  ypos     - vector containing the y position for each point.
;  fwhm     - Full-width at half maximum in arcseconds.
;  maxcnt   - Original DN of maximum in image.
;  sky      - Sky signal in counts/pixel.
;  skyerr   - Uncertainty of the sky signal.
;  mag      - Instrumental magnitude.
;  err      - Uncertainties of the magnitudes.
; OPTIONAL INPUT PARAMETERS:
;  bad      - flag that marks data as bad.  1 is bad, 0 or missing is good.
;               The vector is optional, default is that all are good.
; KEYWORD INPUT PARAMETERS:
;  APPEND - if set appends data to the named file.
; OUTPUTS:
; KEYWORD OUTPUT PARAMETERS:
; COMMON BLOCKS:
; SIDE EFFECTS:
; RESTRICTIONS:
; PROCEDURE:
; MODIFICATION HISTORY:
;  Written by Marc W. Buie, Lowell Observatory, 2000/08/30
;-
pro wrphalt,logname,filename,obj,fil,jd,exptime,gain,rad,sky1,sky2,serial, $
           xpos,ypos,fwhm,maxcnt,sky,skyerr,mag,err,bad,APPEND=append

   if badpar(logname, 7,[0,1],caller='WRPHALT (logname) ') then return

   if badpar(filename,7,[0,1],caller='WRPHALT (filename) ',npts=nfilename) then return
   if badpar(obj,     7,[0,1],caller='WRPHALT (obj) '     ,npts=nobj     ) then return
   if badpar(fil,     7,[0,1],caller='WRPHALT (fil) '     ,npts=nfil     ) then return
   if badpar(jd,      5,[0,1],caller='WRPHALT (jd) '      ,npts=njd      ) then return
   if badpar(exptime,[2,3,4,5],[0,1],caller='WRPHALT (exptime) ',npts=nexptime) then return
   if badpar(gain   ,[2,3,4,5],[0,1],caller='WRPHALT (gain) '   ,npts=ngain   ) then return
   if badpar(rad    ,[2,3,4,5],[0,1],caller='WRPHALT (rad) '    ,npts=nrad    ) then return
   if badpar(sky1   ,[2,3,4,5],[0,1],caller='WRPHALT (sky1) '   ,npts=nsky1   ) then return
   if badpar(sky2   ,[2,3,4,5],[0,1],caller='WRPHALT (sky2) '   ,npts=nsky2   ) then return
   if badpar(serial ,[2,3],[0,1],caller='WRPHALT (serial) ' ,npts=nserial ) then return
   if badpar(xpos   ,[2,3,4,5],[0,1],caller='WRPHALT (xpos) '   ,npts=nxpos   ) then return
   if badpar(ypos   ,[2,3,4,5],[0,1],caller='WRPHALT (ypos) '   ,npts=nypos   ) then return
   if badpar(fwhm   ,[2,3,4,5],[0,1],caller='WRPHALT (fwhm) '   ,npts=nfwhm   ) then return
   if badpar(maxcnt ,[2,3,4,5],[0,1],caller='WRPHALT (maxcnt) ' ,npts=nmaxcnt ) then return
   if badpar(sky    ,[2,3,4,5],[0,1],caller='WRPHALT (sky) '    ,npts=nsky    ) then return
   if badpar(skyerr ,[2,3,4,5],[0,1],caller='WRPHALT (skyerr) ' ,npts=nskyerr ) then return
   if badpar(mag,[4,5],[0,1],caller='WRPHALT (mag) ',npts=nmag) then return
   if badpar(err,[4,5],[0,1],caller='WRPHALT (err) ',npts=nerr) then return
   if badpar(bad,[0,1,2,3],[0,1],caller='WRPHALT (BAD) ', $
             npts=nbad,default=bytarr(njd)) then return

   lens = [ nfilename, nobj, nfil, njd, nexptime, ngain, nrad, nsky1, nsky2, $
            nserial, nxpos, nypos, nfwhm, nmaxcnt,  nsky, nskyerr, nmag, nerr, nbad ]

   z=where(lens ne max(lens),count)
   if count ne 0 then begin
      print,'WRPHALT: All inputs must have the same length.  Aborting.'
      return
   endif

   if keyword_set(append) then begin
      newfile = not exists(logname)
      openw, lun, logname, append=append, /get_lun
      if newfile then printf,lun,'PHOTFILE v1.0'
   endif else begin
      openw, lun, logname, /get_lun
      printf,lun,'PHOTFILE v1.0'
   endelse

   fmt1 = '(a,1x,"''",a,"''",1x,a,1x,f13.5,1x,f8.3,1x,f6.2,1x,f7.3,1x,f7.3,' + $
            '1x,f7.3,1x,i4.4,1x,f8.3,1x,f8.3,1x,f5.2,1x,f7.1,1x,f8.2,1x,f6.2,' + $
            '1x,f8.4,1x,f7.4,1x,i1)'

   for i=0,njd-1 do begin
      printf,lun,FORMAT=fmt1, $
         filename[i], obj[i], fil[i], jd[i], exptime[i], gain[i], rad[i], $
         sky1[i], sky2[i], serial[i], xpos[i], ypos[i], fwhm[i], $
         maxcnt[i], sky[i], skyerr[i], mag[i], err[i], bad[i]
   endfor

   free_lun,lun

end
