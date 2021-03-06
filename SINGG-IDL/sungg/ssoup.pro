pro ssoup, procedure, makeinput=makeinput
  ;
  ; SSOUP launch pad. Defines the possible bands and dumps them in a COMMON 
  ; block named band and takes care of all prerequisites.
  ; 
  ; procedure -> A SSOUP IDL command line (see ?execute). Optional, will run ssoup_main if
  ;              not specified.
  ; makeinput -> If set, makes an input file using make_ssoupin and nothing else.
  ;
  ; S. Andrews (ICRAR/UWA) 01/2013

    COMMON bands, band, nband, bandnam, bandavail, nbandavail, combo, ncombo
    ; these are the possible bands (I hate you, IDL, for being case-insensitive)
    ; think of this as an enumeration
    band      = { $
      mir_w4 : "W4", $
      mir_w3 : "W3", $
      mir_w2 : "W2", $
      mir_w1 : "W1", $
      halpha : 'HALPHA', $
      r      : 'R', $
      nuv    : 'NUV', $
      fuv    : 'FUV' $
      ;ps_g   : "g", $
      ;ps_r   : "r", $
      ;ps_i   : "i", $
      ;ps_z   : "z", $
      ;ps_y   : "y", $
      ; fir    : "FIR" $
    } 
    nband     = n_tags(band)
    ; HTML friendly
    bandnam   = ["W4", "W3", "W2", "W1", 'H&alpha;', 'R', 'NUV', 'FUV']; $
      ; "g", "r", "i", "z", "y", "FIR"]
    ; the rest of this stuff is defined in ssoup_inputs.pro
    
    ; load prerequisites
    astrolib
    resetplot
  
    ; launch stuff
    if keyword_set(makeinput) then make_ssoupin else $
    if not keyword_set(procedure) then ssoup_main else a = execute(procedure)
end