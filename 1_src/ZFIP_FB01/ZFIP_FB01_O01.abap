*&---------------------------------------------------------------------*
*&  Include           ZFIP_FB01_O01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  STATUS_0100  OUTPUT
*&---------------------------------------------------------------------*
*      CONFIGURACIÓN DE STATUS Y TÍTULO PARA LA PANTALLA 0100
*----------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET PF-STATUS 'ZSTATUS_0100'.
  SET TITLEBAR '100'.

ENDMODULE.                 " STATUS_0100  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  STATUS_0200  OUTPUT
*&---------------------------------------------------------------------*
*     CONFIGURACIÓN DE STATUS Y TÍTULO PARA LA PANTALLA 0200
*----------------------------------------------------------------------*
MODULE status_0200 OUTPUT.
  SET PF-STATUS 'ZSTATUS_0200'.
  SET TITLEBAR '200'.

ENDMODULE.                 " STATUS_0200  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  STATUS_0300  OUTPUT
*&---------------------------------------------------------------------*
*        CONFIGURACIÓN DE STATUS Y TÍTULO PARA LA PANTALLA 0300
*----------------------------------------------------------------------*
MODULE status_0300 OUTPUT.
  SET PF-STATUS 'ZSTATUS_0300'.
  SET TITLEBAR '300'.

ENDMODULE.                 " STATUS_0300  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  LOGICA_PBO_0100  OUTPUT
*&---------------------------------------------------------------------*
*     LÓGICA DE INICIALIZACIÓN DE DATOS AL INGRESAR A LA PANTALLA 0100
*----------------------------------------------------------------------*
MODULE logica_pbo_0100 OUTPUT.

  "Fecha Posteo: si no se ingresó, se asigna fecha del día por defecto
  IF zbkpf-budat IS INITIAL.
    zbkpf-budat = sy-datum.
  ENDIF.

  "Inicialización de la primera posición del documento
  v_posicion = 10.

ENDMODULE.                 " LOGICA_PBO_0100  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  LOGICA_PBO_0200  OUTPUT
*&---------------------------------------------------------------------*
*  CONFIGURACIÓN DE VISUALIZACIÓN DE CAMPOS DE LA PANTALLA 0200
*----------------------------------------------------------------------*
MODULE logica_pbo_0200 OUTPUT.

  LOOP AT SCREEN.
    CASE screen-name.

        "Botón COMP
      WHEN 'COMPLETAR_ZFIP_FB01'.
        "Si es la pos de ret de imp: No se muestra
        IF v_flag_retencion = 'X'.
          screen-active = 0.
          MODIFY SCREEN.
        ENDIF.

        "Visualización si se trata de tipo KR o KZ
      WHEN 'ZBSEG-ZFBDT'. "Fecha de vencimiento
        IF ( wa_zbkpf-blart = 'KR' OR wa_zbkpf-blart = 'KZ' ) AND v_flag_retencion IS INITIAL.
          screen-invisible = 0.
          screen-active    = 1.
        ELSE.
          screen-invisible = 1.
          screen-active    = 0.
          MODIFY SCREEN.
        ENDIF.

      WHEN 'ZT003-ZUSCH'. "Ind. de Imp.
        IF ( wa_zbkpf-blart = 'KR' OR wa_zbkpf-blart = 'KZ' ) AND v_flag_retencion IS INITIAL.
          screen-invisible = 0.
          screen-active    = 1.
        ELSE.
          screen-invisible = 1.
          screen-active    = 0.
          MODIFY SCREEN.
        ENDIF.

        "Monto, Cuenta, Signo y Texto Pos
      WHEN 'ZBSEG-DMBTR' OR
           'ZBSEG-HKONT' OR
           'ZBSEG-SHKZG' OR
           'ZBSEG-SGTXT'.

        "Si es la pos de ret de imp: Grisados
        IF v_flag_retencion = 'X'.
          screen-input = 0.
          MODIFY SCREEN.
        ENDIF.

    ENDCASE.
  ENDLOOP.

*-------------------------------------------------------------------
*Si se presiona ENTER en 0200

  "No repetir toda la logica del PBO
  IF v_flag_enter_0200 IS INITIAL.

*--------------------------------------------------------------------
*Si se presiona BACK en 0200

    "Cargar los datos de la pos anterior
    IF v_flag_back_0200 IS NOT INITIAL.

      "Revertir la ret de imp si corresponde
      IF wa_zbkpf-blart = 'KZ' AND v_retencion_revertida IS INITIAL.
        v_retencion_revertida = 'X'.
        PERFORM f_recuperar_montos_originales.
      ENDIF.

      "Retroceder una posición
      v_posicion = v_posicion - 10.

      "Cargar los datos de la pos anterior en la pantalla
      SORT i_zbseg BY posnr.
      READ TABLE i_zbseg INTO wa_zbseg WITH KEY posnr = v_posicion
      BINARY SEARCH.

      IF sy-subrc EQ 0.
        zbseg-shkzg     = wa_zbseg-shkzg.
        zbseg_hkont_cab = wa_zbseg-hkont.
        zbseg-zusch     = wa_zbseg-zusch.
        zbseg-wrbtr     = wa_zbseg-wrbtr.
        zbseg-dmbtr     = wa_zbseg-dmbtr.
        zbseg-zfbdt     = wa_zbseg-zfbdt.
        zbseg-sgtxt     = wa_zbseg-sgtxt.

        CLEAR v_flag_back_0200.
      ENDIF.

    ENDIF. "IF v_flag_back_0200 IS NOT INITIAL.

*--------------------------------------------------------------------
*Si se presiona BACK desde 0300

    IF v_flag_back_0300 IS NOT INITIAL.

      "Revertir la retención si corresponde
      IF wa_zbkpf-blart = 'KZ' AND v_retencion_revertida IS INITIAL.
        v_retencion_revertida = 'X'.
        PERFORM f_recuperar_montos_originales.
      ENDIF.

      "Obtener la última posición
      SORT i_zbseg BY posnr DESCENDING.
      LOOP AT i_zbseg INTO wa_zbseg.
        IF wa_zbseg-sgtxt = v_texto_pos_imp.
          CONTINUE. "Saltear la posición si es la de ret de imp
        ENDIF.
        v_posicion = wa_zbseg-posnr.
        EXIT.
      ENDLOOP.

      "Cargar los datos de la posición obtenida en pantalla
      IF v_posicion IS NOT INITIAL.
        zbseg-shkzg      = wa_zbseg-shkzg.
        zbseg_hkont_cab  = wa_zbseg-hkont.
        zbseg-zusch      = wa_zbseg-zusch.
        zbseg-zfbdt      = wa_zbseg-zfbdt.
        zbseg-sgtxt      = wa_zbseg-sgtxt.
        zbseg-wrbtr      = wa_zbseg-wrbtr.
        zbseg-dmbtr      = wa_zbseg-dmbtr.

        CLEAR v_flag_back_0300.
      ENDIF.

    ENDIF. "IF v_flag_back_0300 IS NOT INITIAL.

*--------------------------------------------------------------------

    "Si es la posición de retención de imp
    IF v_flag_retencion = 'X'.

      "Asignar los valores de MONTO y TEXTO POSICION obtenidos en f_retencion_imp
      zbseg-dmbtr  = wa_zbseg-dmbtr.
      zbseg-sgtxt  = wa_zbseg-sgtxt.
      PERFORM f_calculo_dinamico_monto_local.

    ELSE.

      "Mostrar el valor del ind de imp (checkbox) obtenido en f_validaciones_campos_0100
      zt003-zusch = v_zusch.

    ENDIF. "IF v_flag_retencion = 'X'.

*-------------------------------------------------------------------

    "Limpieza de campos de posición para evitar arrastre de datos
    CLEAR: zbseg-shkzg, zbseg-hkont.

    "Asignar el valor a mostrar en CUENTA de la cabecera
    zbseg_hkont_cab = wa_zbseg-hkont.

*-----------------------------------------------------------------------
*Datos dinámicos de la cuenta financiera

    DATA: lv_cuenta_txt50 TYPE zhkont-txt50,
          lv_cuenta_waers TYPE zhkont-waers.

    "Obtener la descripción y la moneda de la cuenta
    SELECT SINGLE txt50 waers
      FROM zhkont
      INTO (lv_cuenta_txt50, lv_cuenta_waers)
      WHERE skonto = wa_zbseg-hkont.

    IF lv_cuenta_txt50 IS INITIAL.
      MESSAGE a010(zfip_fb01_msg). "ERROR, CUENTA MAL CONFIGURADA, FALTA DESCRIPCION
    ENDIF.

    IF lv_cuenta_waers IS INITIAL.
      MESSAGE a024(zfip_fb01_msg). "ERROR, CUENTA MAL CONFIGURADA, FALTA MONEDA
    ELSE.
      "Guardar en la estructura
      wa_zbseg-waers = lv_cuenta_waers.
    ENDIF.

*------------------------------------------------------------------
*Título dinámico según el signo de la posición

    DATA: lv_signo    TYPE string,
          lv_titulo   TYPE string.

    "Para una pos S: signo 'Debe'
    IF wa_zbseg-shkzg = 'S'.
      lv_signo = text-001. "Debe
      "Para una pos H: signo 'Haber'
    ELSEIF wa_zbseg-shkzg = 'H'.
      lv_signo = text-002. "Haber
    ELSE.
      MESSAGE a019(zfip_fb01_msg). "ERROR AL CONSTRUIR EL TITULO
    ENDIF.

    "Construcción del título: n° pos / signo
    CONCATENATE v_posicion '/' lv_signo INTO lv_titulo SEPARATED BY space.

  ENDIF. "IF v_flag_enter_0200 IS INITIAL.

*------------------------------------------------------------------

  "Reseteo del flag para el siguiente ciclo de pantalla
  CLEAR v_flag_enter_0200.

ENDMODULE.                 " LOGICA_PBO_0200  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  LOGICA_PBO_0300  OUTPUT
*&---------------------------------------------------------------------*
*   CARGA DE DATOS PARA VISUALIZACIÓN FINAL DEL DOCUMENTO
*----------------------------------------------------------------------*
MODULE logica_pbo_0300 OUTPUT.

  "Cargar en pantalla datos de cabecera
  zbkpf-bldat = wa_zbkpf-bldat.
  zbkpf-budat = wa_zbkpf-budat.
  zbkpf-xblnr = wa_zbkpf-xblnr.
  zbkpf-bktxt = wa_zbkpf-bktxt.
  zbkpf-monat = wa_zbkpf-monat.
  zbkpf-blart = wa_zbkpf-blart.
  zbkpf-bukrs = wa_zbkpf-bukrs.
  zbkpf-waers = wa_zbkpf-waers.

*---------------------------------------------------------------------
*Mostrar en pantalla las posiciones guardadas en la tabla interna

  DATA lv_moneda_cuenta TYPE zhkont-waers.

  "Buscar la pos que se está solicitando con los botones ANT y SIG
  SORT i_zbseg BY posnr.
  READ TABLE i_zbseg INTO wa_zbseg WITH KEY posnr = v_posicion
  BINARY SEARCH.

  IF sy-subrc EQ 0.
    "Cargar en pantalla datos de la posición
    zbseg-posnr      = wa_zbseg-posnr.
    zbseg-shkzg      = wa_zbseg-shkzg.
    zbseg-hkont      = wa_zbseg-hkont.
    zbseg-zusch      = wa_zbseg-zusch.
    zbseg-wrbtr      = wa_zbseg-wrbtr.
    zbseg-dmbtr      = wa_zbseg-dmbtr.
    lv_moneda_cuenta = wa_zbseg-waers.

    "Si no hay más posiciones a mostrar
  ELSE.
    MESSAGE w035(zfip_fb01_msg). "No hay más posiciones para mostrar

    "Se retrocede la posición sumada
    v_posicion = v_posicion - 10.
  ENDIF. "READ TABLE i_zbseg INTO wa_zbseg

ENDMODULE.                 " LOGICA_PBO_0300  OUTPUT