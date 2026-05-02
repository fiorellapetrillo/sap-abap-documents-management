*&---------------------------------------------------------------------*
*& Include ZFIP_FB01_TOP                     Module Pool      ZFIP_FB01
*&
*&---------------------------------------------------------------------*

PROGRAM  zfip_fb01.

*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
*TABLAS
*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
TABLES: zbkpf, zbseg, zt003.

*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
*DECLARACIONES
*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
DATA: wa_zbkpf  TYPE zbkpf,
      i_zbseg   TYPE TABLE OF zbseg,
      wa_zbseg  TYPE zbseg,
      i_doc_kr  TYPE TABLE OF zbkpf,
      i_zparam  TYPE TABLE OF zparam,
      wa_zparam TYPE zparam.

DATA: okcode           TYPE sy-ucomm,
      v_posicion       TYPE zbseg-posnr,
      v_zusch          TYPE zt003-zusch,
      v_bktxt          TYPE zt003-bktxt,
      v_sociedad_waers TYPE zt001-waers,
      v_texto_pos_imp  TYPE zparam-valor_salida,
      v_porcent_ret    TYPE zparam-valor_salida,
      v_sociedad_butxt TYPE zt001-butxt,
      zbseg_hkont_cab  TYPE zhkont-skonto.

DATA: v_flag_enter_0200     TYPE flag,
      v_flag_retencion      TYPE flag,
      v_flag_back_0200      TYPE flag,
      v_flag_back_0300      TYPE flag,
      v_retencion_revertida TYPE flag.