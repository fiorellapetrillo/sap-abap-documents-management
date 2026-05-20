*&---------------------------------------------------------------------*
*&      Form  F_VALIDACIONES_CAMPOS_0100
*&---------------------------------------------------------------------*
*    VALIDACIONES DE DATOS INGRESADOS EN PANTALLA 0100
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM f_validaciones_campos_0100 .

*Fecha Doc.
  IF zbkpf-bldat IS INITIAL.
    MESSAGE e000(zfip_fb01_msg). "Completar la fecha del documento
  ELSE.
    IF zbkpf-bldat > sy-datum.
      MESSAGE e001(zfip_fb01_msg). "Fecha inválida: no puede ser una fecha futura
    ENDIF.
  ENDIF. "IF zbkpf-bldat IS INITIAL.

*--------------------------------------------------------------------------
*Fecha Posteo
  IF zbkpf-budat IS INITIAL.
    MESSAGE e002(zfip_fb01_msg). "Debe ingresar la fecha de posteo
  ELSE.
    IF zbkpf-budat LT sy-datum.
      MESSAGE e021(zfip_fb01_msg). "Fecha de posteo inválida: no ingresar una fecha del pasado
    ENDIF.
  ENDIF. "IF zbkpf-budat IS INITIAL.

*--------------------------------------------------------------------------
*Periodo
  IF zbkpf-monat IS INITIAL.
    MESSAGE e006(zfip_fb01_msg). "Debe ingresar el período fiscal
  ELSE.
    IF zbkpf-monat LT 01 OR zbkpf-monat GT 12.
      MESSAGE e007(zfip_fb01_msg). "Período inválido: debe estar entre 01 y 12
    ENDIF.
  ENDIF. "IF bkpf-monat IS INITIAL.

*----------------------------------------------------------------
*Sociedad
  DATA lv_sociedad TYPE zbkpf-bukrs.

  IF zbkpf-bukrs IS INITIAL.
    MESSAGE e003(zfip_fb01_msg). "Completar Sociedad
  ELSE.

    "Obtener datos adicionales de la sociedad
    SELECT SINGLE bukrs butxt
    FROM zt001
    INTO (lv_sociedad, v_sociedad_butxt)
    WHERE bukrs EQ zbkpf-bukrs.

    IF sy-subrc EQ 0.
      "Obtener parametrizaciones de la sociedad
      PERFORM f_select_zparam.
    ELSE.
      MESSAGE e005(zfip_fb01_msg). "La sociedad ingresada no existe
    ENDIF.

    IF v_sociedad_butxt IS INITIAL.
      MESSAGE a015(zfip_fb01_msg). "ERROR, SOCIEDAD MAL CONFIGURADA, FALTA DESCRIPCION
    ENDIF.

  ENDIF. "IF zbkpf-bukrs IS INITIAL.

*-----------------------------------------------------------------------
*Moneda
  "Si no se ingresa una moneda
  IF zbkpf-waers IS INITIAL.

    "Obtener la moneda correspondiente a la sociedad ingresada
    SELECT SINGLE waers
    FROM zt001
    INTO v_sociedad_waers
    WHERE bukrs = zbkpf-bukrs.

    IF sy-subrc EQ 0.
      "Utilizar esa moneda
      zbkpf-waers = v_sociedad_waers.
    ELSE.
      MESSAGE a009(zfip_fb01_msg). "ERROR, SOCIEDAD MAL CONFIGURADA, FALTA MONEDA
    ENDIF.

  ELSE.

    "Validar que la moneda ingresada exista
    SELECT SINGLE waers
    FROM tcurc
    INTO v_sociedad_waers
    WHERE waers = zbkpf-waers.

    IF sy-subrc NE 0.
      MESSAGE e009(zfip_fb01_msg). "Moneda inexistente
    ENDIF.
  ENDIF. "IF zbkpf-waers IS INITIAL.

*-----------------------------------------------------------------
*Tipo
  DATA lv_blart TYPE zbkpf-blart.

  IF zbkpf-blart IS INITIAL.
    MESSAGE e011(zfip_fb01_msg). "Ingrese el Tipo de documento
  ELSE.

    "Obtener datos adicionales del tipo de documento
    SELECT SINGLE blart bktxt zusch
      FROM zt003
      INTO (lv_blart, v_bktxt, v_zusch)
      WHERE blart = zbkpf-blart.

    IF sy-subrc NE 0.
      MESSAGE e012(zfip_fb01_msg). "Tipo de documento inexistente
    ENDIF.

    IF v_bktxt IS INITIAL.
      MESSAGE a027(zfip_fb01_msg). "ERROR, TIPO DE DOCUMENTO MAL CONFIGURADO, FALTA DESCRIPCION
    ENDIF.

  ENDIF. "IF zbkpf-blart IS INITIAL.

*---------------------------------------------------------------
*Referencia obligatoria para docs KR y KZ
  IF zbkpf-blart EQ 'KZ' OR zbkpf-blart EQ 'KR'.

    IF zbkpf-xblnr IS INITIAL.
      MESSAGE e013(zfip_fb01_msg). "Debe ingresar una referencia
    ENDIF.

  ENDIF. "IF zbkpf-blart EQ 'KZ' OR zbkpf-blart EQ 'KR'.

*-----------------------------------------------------------------
*Signo y cuenta
  PERFORM f_validaciones_signo_cuenta.

*-----------------------------------------------------------------
*Guardar los valores ingresados en las estructuras

  "Cabecera
  wa_zbkpf-bldat  = zbkpf-bldat.
  wa_zbkpf-budat  = zbkpf-budat.
  wa_zbkpf-monat  = zbkpf-monat.
  wa_zbkpf-bukrs  = zbkpf-bukrs.
  wa_zbkpf-waers  = zbkpf-waers.
  wa_zbkpf-blart  = zbkpf-blart.
  wa_zbkpf-xblnr  = zbkpf-xblnr.
  wa_zbkpf-bktxt  = zbkpf-bktxt.

  "Posición
  wa_zbseg-bukrs  = zbkpf-bukrs.
  wa_zbseg-waer2  = zbkpf-waers.
  wa_zbseg-shkzg  = zbseg-shkzg.
  wa_zbseg-hkont  = zbseg-hkont.

ENDFORM.                    " F_VALIDACIONES_CAMPOS_0100
*&---------------------------------------------------------------------*
*&      Form  F_CALCULO_DINAMICO_MONTO_LOCAL
*&---------------------------------------------------------------------*
*          CÁLCULO DEL MONTO EN MONEDA LOCAL
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM f_calculo_dinamico_monto_local .

  DATA lv_param TYPE zparam-param.

  "Si las monedas del documento y de la cuenta son la misma
  IF wa_zbseg-waers = wa_zbkpf-waers.

    "Mostrar en MONTO LOCAL el mismo valor que se ingresó en MONTO
    zbseg-wrbtr = zbseg-dmbtr.

  ELSE. "Si no son la misma

    "Obtener el tipo de cambio entre ambas monedas, desde tabla de parametrización
    CONCATENATE 'TIPO_CAMBIO_' wa_zbseg-waers '_' wa_zbkpf-waers INTO lv_param.

    READ TABLE i_zparam INTO wa_zparam WITH KEY bukrs         = wa_zbkpf-bukrs
                                                id            = 'ZFB01'
                                                param         = lv_param
                                                valor_entrada = sy-datum.

    IF sy-subrc EQ 0.
      "Cálculo del monto local según el tipo de cambio obtenido
      zbseg-wrbtr = zbseg-dmbtr * wa_zparam-valor_salida.
    ELSE.
      MESSAGE a028(zfip_fb01_msg). "NO SE ENCONTRO EL TIPO DE CAMBIO, VER TABLA ZPARAM
    ENDIF.

  ENDIF. "IF wa_zbseg-waers = wa_zbkpf-waers.

  "Guardar el monto local en la estructura
  wa_zbseg-wrbtr  = zbseg-wrbtr.

ENDFORM.                    " F_CALCULO_DINAMICO_MONTO_LOCAL
*&---------------------------------------------------------------------*
*&      Form  F_VALIDACIONES_CAMPOS_0200
*&---------------------------------------------------------------------*
*   VALIDACIONES DE DATOS DE POSICIÓN
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM f_validaciones_campos_0200 .

*Monto
  IF zbseg-dmbtr IS INITIAL.
    MESSAGE e022(zfip_fb01_msg). "Debe ingresar el monto
  ELSE.
    IF zbseg-dmbtr LE 0.
      MESSAGE e023(zfip_fb01_msg). "Monto ingresado inválido
    ENDIF. "IF zbseg-dmbtr LE 0.
  ENDIF. "IF zbseg-dmbtr is INITIAL.

*---------------------------------------------------------------------------
*Fecha Venc. obligatoria para documentos KR y KZ
  IF ( wa_zbkpf-blart = 'KR' OR wa_zbkpf-blart = 'KZ' ) AND v_flag_retencion IS INITIAL.

    IF zbseg-zfbdt IS INITIAL.
      MESSAGE e025(zfip_fb01_msg). "Debe ingresar la fecha de vencimiento
    ELSE.

      IF zbseg-zfbdt LT sy-datum.
        MESSAGE e026(zfip_fb01_msg). "Fecha de vencimiento inválida: no puede estar en el pasado
      ENDIF.
    ENDIF. "IF zbseg-zfbdt IS INITIAL.
  ENDIF. "IF ( wa_zbkpf-blart = 'KR' OR wa_zbkpf-blart = 'KZ' ) AND v_flag_retencion IS INITIAL.

*-------------------------------------------------------------------------------
*Guardar los valores ingresados en la estructura
  wa_zbseg-dmbtr = zbseg-dmbtr.
  wa_zbseg-zfbdt = zbseg-zfbdt.
  wa_zbseg-sgtxt = zbseg-sgtxt.
  wa_zbseg-zusch = zt003-zusch.
  wa_zbseg-posnr = v_posicion.

*--------------------------------------------------------------------------------
*Agregar los datos de la estructura a la tabla de posiciones
  SORT i_zbseg BY posnr.

  "Verificar si es una posición nueva o una modificación
  READ TABLE i_zbseg WITH KEY posnr = v_posicion
  BINARY SEARCH
  TRANSPORTING NO FIELDS.

  IF sy-subrc EQ 0.
    "Si se presionó BACK y se cambiaron datos, modificar el registro correspondiente
    MODIFY i_zbseg FROM wa_zbseg INDEX sy-tabix.
  ELSE.
    "Si es una posicion nueva, se agrega el registro nuevo
    APPEND wa_zbseg TO i_zbseg.
  ENDIF.

ENDFORM.                    " F_VALIDACIONES_CAMPOS_0200
*&---------------------------------------------------------------------*
*&      Form  F_VALIDACIONES_0300
*&---------------------------------------------------------------------*
*   VALIDACIONES FINALES Y CREACIÓN DEL DOCUMENTO
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM f_validaciones_0300 .

*Comprobación del balance

  DATA: lv_suma_montos_debe  TYPE zbseg-wrbtr,
        lv_suma_montos_haber TYPE zbseg-wrbtr.

  "Recorrer la tabla de posiciones
  LOOP AT i_zbseg INTO wa_zbseg.
    "Sumar los montos de todas las posiciones DEBE
    IF wa_zbseg-shkzg = 'S'.
      lv_suma_montos_debe = lv_suma_montos_debe + wa_zbseg-wrbtr.
      "Sumar los montos de todas las posiciones HABER
    ELSEIF wa_zbseg-shkzg = 'H'.
      lv_suma_montos_haber = lv_suma_montos_haber + wa_zbseg-wrbtr.
    ENDIF.
  ENDLOOP.

  "Validar que los resultados sean iguales
  IF lv_suma_montos_debe NE lv_suma_montos_haber.
    MESSAGE e029(zfip_fb01_msg). "Documento no compensado. Diferencia mayor a cero
  ENDIF.

*--------------------------------------------------------------------------------
*Generación del número de documento a través de un objeto numerador

  "Obtener el año fiscal desde la fecha del doc
  zbkpf-gjhar = zbkpf-bldat+0(4).

  DATA: lv_belnr_num  TYPE nrnr,         "Número de rango fijo definido en SNRO
        lv_belnr      TYPE zbkpf-belnr,  "Resultado del numerador
        lv_subobject  TYPE subobject,
        lv_gjhar      TYPE inri-toyear.

  lv_gjhar = zbkpf-gjhar.     "Año fiscal
  lv_belnr_num = '01'.
  lv_subobject = zbkpf-bukrs. "Subobjeto según la sociedad

  CALL FUNCTION 'NUMBER_GET_NEXT'
    EXPORTING
      toyear                  = lv_gjhar
      nr_range_nr             = lv_belnr_num
      object                  = 'ZN_FIP_F01'
      subobject               = lv_subobject
      quantity                = '1'
      ignore_buffer           = 'X'
    IMPORTING
      number                  = lv_belnr
    EXCEPTIONS
      interval_not_found      = 1
      number_range_not_intern = 2
      object_not_found        = 3
      quantity_is_0           = 4
      quantity_is_not_1       = 5
      interval_overflow       = 6
      buffer_overflow         = 7
      OTHERS                  = 8.

  IF sy-subrc NE 0.
    MESSAGE a030(zfip_fb01_msg). "ERROR AL GENERAR NUMERO DE DOCUMENTO
  ELSE.
    "Guardar el número
    zbkpf-belnr = lv_belnr.
  ENDIF.

*-------------------------------------------------------------------------
*Completar las tablas y crear el documento

  DATA lwa_doc_kr TYPE zbkpf.

  "Completar NUM DOC y AÑO FISCAL en la cabecera y las posiciones
  wa_zbkpf-belnr = zbkpf-belnr.
  wa_zbkpf-gjhar = zbkpf-gjhar.

  LOOP AT i_zbseg INTO wa_zbseg.
    wa_zbseg-belnr = zbkpf-belnr.
    wa_zbseg-gjhar = zbkpf-gjhar.
    MODIFY i_zbseg FROM wa_zbseg.
  ENDLOOP.

  "Modificar los KR usando la tabla de f_concatenar_pagado_0100
  IF wa_zbkpf-blart = 'KZ'.
    LOOP AT i_doc_kr INTO lwa_doc_kr.
      MODIFY zbkpf FROM lwa_doc_kr.
    ENDLOOP.
  ENDIF.

  "Completar la tabla de cabeceras
  INSERT zbkpf FROM wa_zbkpf.

  IF sy-subrc NE 0.
    MESSAGE a031(zfip_fb01_msg). "Error al guardar la cabecera del documento
    ROLLBACK WORK.
  ENDIF.

  "Completar la tabla de posiciones
  INSERT zbseg FROM TABLE i_zbseg.

  IF sy-subrc NE 0.
    MESSAGE a032(zfip_fb01_msg). "Error al guardar las posiciones del doc
    ROLLBACK WORK.
  ENDIF.

  MESSAGE i004(zfip_fb01_msg) WITH wa_zbkpf-belnr. "Documento N° & creado con éxito!
  COMMIT WORK.

  CLEAR: okcode, wa_zbkpf, wa_zbseg, zbkpf, zbseg.
  REFRESH: i_zbseg.

ENDFORM.                    " F_VALIDACIONES_0300
*&---------------------------------------------------------------------*
*&      Form  F_VALIDACIONES_SIGNO_CUENTA
*&---------------------------------------------------------------------*
*     VALIDAR SIGNO Y NUMERO DE CUENTA DE LA POSICIÓN
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM f_validaciones_signo_cuenta .

*Signo
  IF zbseg-shkzg IS INITIAL.
    MESSAGE e014(zfip_fb01_msg). "Ingresar un signo (S o H)
  ENDIF.

*-----------------------------------------------------------------------
*Cuenta
  DATA: lv_skonto TYPE zhkont-skonto,
        lv_bukrs  TYPE zhkont-bukrs,
        lv_datbi  TYPE zhkont-datbi.

  IF zbseg-hkont IS INITIAL.
    MESSAGE e016(zfip_fb01_msg). "Ingresar número de cuenta
  ENDIF.

  "Completar el número ingresado con ceros a la izquierda
  CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
    EXPORTING
      input  = zbseg-hkont
    IMPORTING
      output = zbseg-hkont.

  "Obtener datos adicionales de la cuenta ingresada
  SELECT SINGLE skonto bukrs datbi
    FROM zhkont
    INTO (lv_skonto, lv_bukrs, lv_datbi)
    WHERE skonto = zbseg-hkont.

  IF sy-subrc NE 0.
    MESSAGE e017(zfip_fb01_msg). "Número de cuenta inexistente
  ENDIF.

  IF lv_bukrs NE zbkpf-bukrs.
    MESSAGE e018(zfip_fb01_msg). "La cuenta no corresponde a la sociedad ingresada
  ENDIF.

  "Controlar la fecha de vencimiento de la cuenta
  IF lv_datbi IS NOT INITIAL AND lv_datbi LT zbkpf-bldat.
    MESSAGE e020(zfip_fb01_msg). "La cuenta ingresada no se encuentra utilizable
  ENDIF.

ENDFORM.                    " F_VALIDACIONES_SIGNO_CUENTA
*&---------------------------------------------------------------------*
*&      Form  F_RETENCION_IMP_0200
*&---------------------------------------------------------------------*
*     CALCULAR LA RETENCIÓN DE IMPUESTOS PARA DOCUMENTOS KZ
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM f_retencion_imp_0200 .

  DATA: lv_retencion       TYPE zbseg-dmbtr,
        lv_total_retencion TYPE zbseg-dmbtr,
        lv_cuenta_ret      TYPE zhkont-skonto,
        li_ret_imp         TYPE STANDARD TABLE OF zbseg.

  FIELD-SYMBOLS: <lfs_ret_imp> LIKE LINE OF li_ret_imp,
                 <lfs_zbseg>   LIKE LINE OF i_zbseg.

  CLEAR li_ret_imp.

  "Buscar posiciones que aplican para la retención
  LOOP AT i_zbseg ASSIGNING <lfs_ret_imp>.

    "Signo H con Ind de Imp verdadero
    IF <lfs_ret_imp>-shkzg = 'H' AND <lfs_ret_imp>-zusch = 'X'.
      APPEND <lfs_ret_imp> TO li_ret_imp.
    ENDIF.

  ENDLOOP.

  IF li_ret_imp IS NOT INITIAL.

    "Obtener la cuenta financiera de retención correspondiente a la sociedad
    SELECT SINGLE skonto
      FROM zhkont
      INTO lv_cuenta_ret
      WHERE bukrs = wa_zbkpf-bukrs
      AND txt50 = 'CUENTA DE RETENCIÓN AFIP'.

    IF sy-subrc EQ 0.
      "Obtener el porcentaje de imp desde la tabla de parametrización
      READ TABLE i_zparam INTO wa_zparam WITH KEY bukrs         = wa_zbkpf-bukrs
                                                  id            = 'ZFB01'
                                                  param         = 'PORCENTAJE_IMP'
                                                  valor_entrada = lv_cuenta_ret.

      IF sy-subrc EQ 0.
        v_porcent_ret = wa_zparam-valor_salida.

        "Obtener el valor para TEXTO POSICION desde la tabla de parametrización
        READ TABLE i_zparam INTO wa_zparam WITH KEY bukrs         = wa_zbkpf-bukrs
                                                    id            = 'ZFB01'
                                                    param         = 'TEXTO_POS_IMP'.

        IF sy-subrc EQ 0.
          v_texto_pos_imp = wa_zparam-valor_salida.
          CLEAR lv_total_retencion.

          "Recorrer las posiciones que requieren retención
          LOOP AT li_ret_imp ASSIGNING <lfs_ret_imp>.

            "Cálculo del % de cada monto
            lv_retencion = <lfs_ret_imp>-dmbtr * v_porcent_ret / 100.

            <lfs_ret_imp>-dmbtr = <lfs_ret_imp>-dmbtr - lv_retencion.

            "Suma del total de las retenciones, será el monto de la nueva posición
            lv_total_retencion = lv_total_retencion + lv_retencion.

            CLEAR lv_retencion.

            "Cálculo del % de cada monto local
            lv_retencion = <lfs_ret_imp>-wrbtr * v_porcent_ret / 100.
            "Restarlo a cada monto local
            <lfs_ret_imp>-wrbtr = <lfs_ret_imp>-wrbtr - lv_retencion.

            "Buscar esas posiciones en la tabla
            READ TABLE i_zbseg ASSIGNING <lfs_zbseg> WITH KEY posnr = <lfs_ret_imp>-posnr.

            IF sy-subrc EQ 0.
              "Asignar los nuevos montos modificados
              <lfs_zbseg>-dmbtr = <lfs_ret_imp>-dmbtr.
              <lfs_zbseg>-wrbtr = <lfs_ret_imp>-wrbtr.
            ENDIF.

          ENDLOOP.

          "Sumar una posición
          v_posicion = v_posicion + 10.

          "Guardar los datos de la nueva posición (de ret de imp)
          wa_zbseg-hkont = lv_cuenta_ret.
          wa_zbseg-shkzg = 'H'.
          wa_zbseg-dmbtr = lv_total_retencion.
          wa_zbseg-zfbdt = ''.
          wa_zbseg-sgtxt = v_texto_pos_imp.
          wa_zbseg-zusch = ''.

          CALL SCREEN 0200.

        ELSE. "READ TABLE i_zparam INTO wa_zparam
          MESSAGE a034(zfip_fb01_msg). "NO SE ENCONTRO EL VALOR DE SALIDA DE TEXTO_POS_IMP, VER TABLA ZPARAM
        ENDIF. "READ TABLE i_zparam INTO wa_zparam

      ELSE. "READ TABLE i_zparam INTO wa_zparam
        MESSAGE a038(zfip_fb01_msg). "NO SE ENCONTRO EL PORCENTAJE DE IMPUESTO, VER TABLA ZPARAM
      ENDIF. "READ TABLE i_zparam INTO wa_zparam

    ELSE. "SELECT SINGLE skonto INTO lv_cuenta_ret
      MESSAGE a037(zfip_fb01_msg). "NO SE ENCONTRO LA CUENTA DE RETENCION DE IMPUESTOS
    ENDIF. "SELECT SINGLE skonto INTO lv_cuenta_ret

  ENDIF. "IF li_ret_imp IS NOT INITIAL.

ENDFORM.                    " F_RETENCION_IMP_0200
*&---------------------------------------------------------------------*
*&      Form  F_CONCATENAR_PAGADO_0100
*&---------------------------------------------------------------------*
*   MARCAR COMO PAGADO LOS DOC KR CON LA MISMA REFERENCIA
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM f_concatenar_pagado_0100 .

  FIELD-SYMBOLS <lfs_doc_kr> LIKE LINE OF i_doc_kr.

  "Buscar los doc existentes que tengan la misma referencia
  SELECT *
    FROM zbkpf
    INTO TABLE i_doc_kr
    WHERE xblnr = wa_zbkpf-xblnr.

  "Eliminar los que NO sean KR
  DELETE i_doc_kr WHERE blart NE 'KR'.

  IF i_doc_kr IS NOT INITIAL.

    "Agregar 'PAGADO' al texto de cabecera de los KR
    LOOP AT i_doc_kr ASSIGNING <lfs_doc_kr>.
      CONCATENATE <lfs_doc_kr>-bktxt '- PAGADO' INTO <lfs_doc_kr>-bktxt SEPARATED BY space.
    ENDLOOP.

  ELSE.
    MESSAGE a033(zfip_fb01_msg). "ERROR, NO SE ENCUENTRA DOCUMENTO KR CON ESA REFERENCIA
  ENDIF. "IF i_doc_kr IS NOT INITIAL.

ENDFORM.                    " F_CONCATENAR_PAGADO_0100
*&---------------------------------------------------------------------*
*&      Form  F_RECUPERAR_MONTOS_ORIGINALES
*&---------------------------------------------------------------------*
*      REVERTIR LA RETENCIÓN DE IMPUESTOS
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM f_recuperar_montos_originales .

  DATA lv_ret_back TYPE zbseg-dmbtr.

  "Recorrer las posiciones (salteando la de retención)
  LOOP AT i_zbseg INTO wa_zbseg.
    IF wa_zbseg-sgtxt = v_texto_pos_imp.
      CONTINUE.
    ENDIF.

    "Si cumple las condiciones para haberse aplicado la retención
    IF   wa_zbkpf-blart = 'KZ'
     AND wa_zbseg-shkzg = 'H'
     AND wa_zbseg-zusch = 'X'.

      "Cálculo para obtener los montos originales
      lv_ret_back = 1 - ( v_porcent_ret / 100 ).

      "Modificar los montos en la posicion
      wa_zbseg-wrbtr = wa_zbseg-wrbtr / lv_ret_back.
      wa_zbseg-dmbtr = wa_zbseg-dmbtr / lv_ret_back.

      MODIFY i_zbseg FROM wa_zbseg.
    ENDIF.
  ENDLOOP.

ENDFORM.                    " F_RECUPERAR_MONTOS_ORIGINALES
*&---------------------------------------------------------------------*
*&      Form  F_SELECT_ZPARAM
*&---------------------------------------------------------------------*
*    OBTENER INFORMACIÓN ADICIONAL DE LA SOCIEDAD INGRESADA
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM f_select_zparam .

  REFRESH i_zparam.

  "Obtener parametrizaciones de la sociedad ingresada
  SELECT *
    FROM zparam
    INTO TABLE i_zparam
    WHERE bukrs = zbkpf-bukrs
      AND id    = 'ZFB01'.

  IF i_zparam IS INITIAL.
    MESSAGE a039(zfip_fb01_msg). "NO EXISTE PARAMETRIZACION PARA LA SOCIEDAD INGRESADA, VER TABLA ZPARAM
  ENDIF.

ENDFORM.                    " F_SELECT_ZPARAM
