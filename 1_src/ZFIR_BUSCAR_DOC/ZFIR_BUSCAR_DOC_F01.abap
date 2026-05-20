*----------------------------------------------------------------------*
*  INCLUDE ZFIR_BUSCAR_DOC_F01 .
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  F_REFRESH
*&---------------------------------------------------------------------*
*   LIMPIEZA DE VARIABLES Y TABLAS GLOBALES
*----------------------------------------------------------------------*
FORM f_refresh .

  REFRESH: i_zbkpf,
           i_zbseg,
           i_zhkont,
           i_zt001,
           i_zt003,
           i_alv.

ENDFORM.                    " F_REFRESH
*&---------------------------------------------------------------------*
*&      Form  F_CHECK_SELECTION
*&---------------------------------------------------------------------*
*   VERIFICAR INGRESO DE DATOS PARA SOCIEDAD Y AÑO FISCAL
*----------------------------------------------------------------------*
FORM f_check_selection .

  IF s_bukrs[] IS INITIAL.
    "Debe ingresar una Sociedad
    MESSAGE e006(zfir_bus_doc_msg).
  ENDIF.

  IF s_gjhar[] IS INITIAL.
    "Debe ingresar el Año Fiscal
    MESSAGE e007(zfir_bus_doc_msg).
  ENDIF.

ENDFORM.                    " F_CHECK_SELECTION
*&---------------------------------------------------------------------*
*&      Form  F_SELECT_DATA
*&---------------------------------------------------------------------*
*  SELECCIÓN DE INFORMACIÓN DESDE TABLAS DE BASE DE DATOS
*----------------------------------------------------------------------*
FORM f_select_data .

  DATA: li_zbkpf_aux TYPE tt_zbkpf,
        li_zbseg_aux TYPE tt_zbseg.

  "Obtener cabeceras de documentos
  SELECT bukrs belnr gjhar bldat budat monat blart xblnr bktxt
    FROM zbkpf
    INTO TABLE i_zbkpf
    WHERE  bukrs IN s_bukrs
      AND  gjhar IN s_gjhar
      AND  belnr IN s_belnr
      AND  xblnr IN s_xblnr
      AND  waers IN s_waers
      AND  blart IN s_blart
      AND  bldat IN s_bldat
      AND  budat IN s_budat.

  IF sy-subrc EQ 0.

    "Obtener información adicional de las sociedades
    li_zbkpf_aux[] = i_zbkpf[].
    SORT li_zbkpf_aux BY bukrs.
    DELETE ADJACENT DUPLICATES FROM li_zbkpf_aux COMPARING bukrs.

    SELECT bukrs butxt land1
     FROM zt001
     INTO TABLE i_zt001
     FOR ALL ENTRIES IN li_zbkpf_aux
     WHERE bukrs = li_zbkpf_aux-bukrs.

    IF sy-subrc EQ 0.
      SORT i_zt001 BY bukrs.
    ENDIF.

    "Obtener información adicional de los tipos de documentos
    li_zbkpf_aux[] = i_zbkpf[].
    SORT li_zbkpf_aux BY blart.
    DELETE ADJACENT DUPLICATES FROM li_zbkpf_aux COMPARING blart.

    SELECT blart bktxt
      FROM zt003
      INTO TABLE i_zt003
      FOR ALL ENTRIES IN li_zbkpf_aux
      WHERE blart = li_zbkpf_aux-blart.

    IF sy-subrc EQ 0.
      SORT i_zt003 BY blart.
    ENDIF.

    "Obtener las posiciones de cada cabecera
    SELECT bukrs belnr gjhar posnr hkont shkzg waers dmbtr waer2 wrbtr zfbdt sgtxt zusch
      FROM zbseg
      INTO TABLE i_zbseg
      FOR ALL ENTRIES IN i_zbkpf
      WHERE bukrs = i_zbkpf-bukrs
        AND belnr = i_zbkpf-belnr
        AND gjhar = i_zbkpf-gjhar.

    IF sy-subrc EQ 0.
      SORT i_zbseg BY bukrs belnr gjhar posnr.

      "Obtener información adicional sobre las cuentas financieras
      li_zbseg_aux[] = i_zbseg[].
      SORT li_zbseg_aux BY hkont.
      DELETE ADJACENT DUPLICATES FROM li_zbseg_aux COMPARING hkont.

      SELECT skonto txt50 datbi
        FROM zhkont
        INTO TABLE i_zhkont
        FOR ALL ENTRIES IN li_zbseg_aux
        WHERE skonto = li_zbseg_aux-hkont.

      IF sy-subrc EQ 0.
        SORT i_zhkont BY skonto.
      ENDIF.

    ENDIF. "SELECT FROM zbseg

  ELSE.
    "No se encontraron documentos
    MESSAGE s000(zfir_bus_doc_msg) DISPLAY LIKE 'E'.
  ENDIF. "SELECT FROM zbkpf


ENDFORM.                    " F_SELECT_DATA
*&---------------------------------------------------------------------*
*&      Form  F_PROCESS_DATA
*&---------------------------------------------------------------------*
*       CONSTRUCCIÓN DE LA TABLA ALV
*----------------------------------------------------------------------*
FORM f_process_data .

  DATA: lwa_alv           TYPE ty_tabla_alv,
        lv_tabix          TYPE sy-tabix,
        lwa_colores       TYPE slis_specialcol_alv,
        lv_msg            TYPE ty_tabla_alv-msg,
        lv_celda_amarilla TYPE flag,
        lv_celda_roja     TYPE flag.

  FIELD-SYMBOLS: <lfs_zbkpf>   LIKE LINE OF i_zbkpf,
                 <lfs_zbseg>   LIKE LINE OF i_zbseg,
                 <lfs_zt001>   LIKE LINE OF i_zt001,
                 <lfs_zt003>   LIKE LINE OF i_zt003,
                 <lfs_zhkont>  LIKE LINE OF i_zhkont.

  "Recorrer las cabeceras encontradas para armar la tabla de ALV
  LOOP AT i_zbkpf ASSIGNING <lfs_zbkpf>.
    CLEAR: lwa_alv, lwa_colores, lv_celda_amarilla, lv_celda_roja, lv_msg.
    REFRESH lwa_alv-t_colores.

    "Asignar datos de cabecera a estructura del ALV
    lwa_alv-bukrs     = <lfs_zbkpf>-bukrs.
    lwa_alv-belnr     = <lfs_zbkpf>-belnr.
    lwa_alv-gjhar     = <lfs_zbkpf>-gjhar.
    lwa_alv-bldat     = <lfs_zbkpf>-bldat.
    lwa_alv-budat     = <lfs_zbkpf>-budat.
    lwa_alv-monat     = <lfs_zbkpf>-monat.
    lwa_alv-blart     = <lfs_zbkpf>-blart.
    lwa_alv-xblnr     = <lfs_zbkpf>-xblnr.
    lwa_alv-bktxt_doc = <lfs_zbkpf>-bktxt.

    "Asignar datos de la sociedad a estructura del ALV
    READ TABLE i_zt001 ASSIGNING <lfs_zt001> WITH KEY bukrs = <lfs_zbkpf>-bukrs
    BINARY SEARCH.

    IF sy-subrc EQ 0.
      lwa_alv-butxt = <lfs_zt001>-butxt.
      lwa_alv-land1 = <lfs_zt001>-land1.
    ELSE.
      "No se ha encontrado datos de la sociedad &
      MESSAGE s001(zfir_bus_doc_msg) WITH lwa_alv-bukrs INTO lv_msg.

      "Construcción del mensaje de error en la estructura del ALV
      IF lwa_alv-msg IS INITIAL.
        lwa_alv-msg = lv_msg.
      ELSE.
        CONCATENATE lwa_alv-msg '-' lv_msg INTO lwa_alv-msg SEPARATED BY space.
      ENDIF.
      "Establecer el color de la celda
      lv_celda_amarilla = abap_true.
    ENDIF. "READ TABLE i_zt001 ASSIGNING <lfs_zt001>

    "Asignar datos del tipo de documento a estructura del ALV
    READ TABLE i_zt003 ASSIGNING <lfs_zt003> WITH KEY blart = <lfs_zbkpf>-blart
    BINARY SEARCH.

    IF sy-subrc EQ 0.
      lwa_alv-bktxt_tipo = <lfs_zt003>-bktxt.
    ELSE.
      "No se ha encontrado datos del tipo &
      MESSAGE s002(zfir_bus_doc_msg) WITH lwa_alv-blart INTO lv_msg.

      "Construcción del mensaje de error en la estructura del ALV
      IF lwa_alv-msg IS INITIAL.
        lwa_alv-msg = lv_msg.
      ELSE.
        CONCATENATE lwa_alv-msg '-' lv_msg INTO lwa_alv-msg SEPARATED BY space.
      ENDIF.
      lv_celda_amarilla = abap_true.
    ENDIF. "READ TABLE i_zt003 ASSIGNING <lfs_zt003>

    "Ubicar las posiciones de esa cabecera en la tabla
    CLEAR lv_tabix.
    READ TABLE i_zbseg TRANSPORTING NO FIELDS WITH KEY  bukrs = <lfs_zbkpf>-bukrs
                                                        belnr = <lfs_zbkpf>-belnr
                                                        gjhar = <lfs_zbkpf>-gjhar
                                                        BINARY SEARCH.
    IF sy-subrc EQ 0.
      lv_tabix = sy-tabix.

      "Recorrer esas posiciones y asignar a la estructura del ALV
      LOOP AT i_zbseg ASSIGNING <lfs_zbseg> FROM lv_tabix.

        IF <lfs_zbseg>-bukrs NE <lfs_zbkpf>-bukrs OR
           <lfs_zbseg>-belnr NE <lfs_zbkpf>-belnr OR
           <lfs_zbseg>-gjhar NE <lfs_zbkpf>-gjhar.
          EXIT.
        ENDIF.

        lwa_alv-posnr     = <lfs_zbseg>-posnr.
        lwa_alv-hkont     = <lfs_zbseg>-hkont.
        lwa_alv-waers     = <lfs_zbseg>-waers.
        lwa_alv-waer2     = <lfs_zbseg>-waer2.
        lwa_alv-sgtxt     = <lfs_zbseg>-sgtxt.
        lwa_alv-zfbdt     = <lfs_zbseg>-zfbdt.

        "Indicador de impuesto: Vacío = en el ALV -> 'No'
        IF <lfs_zbseg>-zusch IS INITIAL.
          lwa_alv-zusch = 'No'.
        ELSE.
          "Indicador de impuesto: 'X' = en el ALV -> 'Si'
          lwa_alv-zusch = 'Si'.
        ENDIF.

        "Mostrar el monto en negativo si la posición es DEBE
        IF <lfs_zbseg>-shkzg EQ 'S'.
          lwa_alv-dmbtr     = <lfs_zbseg>-dmbtr * -1.
          lwa_alv-wrbtr     = <lfs_zbseg>-wrbtr * -1.
        ELSE.
          lwa_alv-dmbtr     = <lfs_zbseg>-dmbtr.
          lwa_alv-wrbtr     = <lfs_zbseg>-wrbtr.
        ENDIF.

        "Celda roja si la fecha de vencimiento es inválida
        IF <lfs_zbseg>-zfbdt IS NOT INITIAL AND <lfs_zbseg>-zfbdt LT sy-datum.
          lwa_colores-fieldname = 'ZFBDT'.
          lwa_colores-color-col = 6. "rojo
          lwa_colores-color-int = 1. "celda
          APPEND lwa_colores TO lwa_alv-t_colores.
        ENDIF.

        "Asignar datos de la cuenta a estructura del ALV
        READ TABLE i_zhkont ASSIGNING <lfs_zhkont> WITH KEY skonto = <lfs_zbseg>-hkont
        BINARY SEARCH.

        IF sy-subrc EQ 0.
          lwa_alv-txt50 = <lfs_zhkont>-txt50.
          lwa_alv-datbi = <lfs_zhkont>-datbi.
        ELSE.
          "No se ha encontrado datos de la cuenta &
          MESSAGE s003(zfir_bus_doc_msg) WITH lwa_alv-hkont INTO lv_msg.

          "Construcción del mensaje en la estructura del ALV
          IF lwa_alv-msg IS INITIAL.
            lwa_alv-msg = lv_msg.
          ELSE.
            CONCATENATE lwa_alv-msg '-' lv_msg INTO lwa_alv-msg SEPARATED BY space.
          ENDIF.
          lv_celda_amarilla = abap_true.
        ENDIF. "READ TABLE i_zhkont ASSIGNING <lfs_zhkont>

        "Configuración de color para la columna de ERRORES
        IF lv_celda_amarilla = abap_true.
          lwa_colores-fieldname = 'MSG'.
          lwa_colores-color-col = 3.  "Amarillo
          lwa_colores-color-int = 1.
          APPEND lwa_colores TO lwa_alv-t_colores.
        ENDIF.

        "Guardar registro en tabla de ALV
        APPEND lwa_alv TO i_alv.
      ENDLOOP. "LOOP AT i_zbseg

    ELSE.
      "No se ha encontrado posiciones para este documento
      MESSAGE s004(zfir_bus_doc_msg) INTO lv_msg.

      "Construcción del mensaje en la estructura del ALV
      IF lwa_alv-msg IS INITIAL.
        lwa_alv-msg = lv_msg.
      ELSE.
        CONCATENATE lv_msg '-' lwa_alv-msg INTO lwa_alv-msg SEPARATED BY space.
      ENDIF.
      lv_celda_roja = abap_true.

      "Configuación de color para la columna de ERRORES
      IF lv_celda_roja = abap_true.
        lwa_colores-fieldname = 'MSG'.
        lwa_colores-color-col = 6.  "Rojo
        lwa_colores-color-int = 1.
        APPEND lwa_colores TO lwa_alv-t_colores.
      ENDIF.

      "Guardar registro de cabecera sin posiciones a la tabla del ALV
      APPEND lwa_alv TO i_alv.
    ENDIF. "READ TABLE i_zbseg
  ENDLOOP. "LOOP AT i_zbkpf

ENDFORM.                    " F_PROCESS_DATA
*&---------------------------------------------------------------------*
*&      Form  F_ALV_REPORT
*&---------------------------------------------------------------------*
*          CONSTRUCCIÓN DEL REPORTE ALV
*----------------------------------------------------------------------*
FORM f_alv_report .

  DATA: li_fieldcat  TYPE slis_t_fieldcat_alv,
        li_sort      TYPE slis_t_sortinfo_alv,
        lwa_layout   TYPE slis_layout_alv.

  "Opciones de visualización
  lwa_layout-zebra             = abap_true.
  lwa_layout-colwidth_optimize = abap_true.
  lwa_layout-coltab_fieldname  = 'T_COLORES'.

  "Construcción del catálogo de campos
  PERFORM f_build_fieldcat CHANGING li_fieldcat.

  "Criterios de ordenamiento de salida del ALV
  PERFORM f_build_sort CHANGING li_sort.

  "Salida del ALV
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program       = sy-repid
      i_callback_pf_status_set = 'SET_PF_STATUS'
      i_callback_user_command  = 'USER_COMMAND'
      is_layout                = lwa_layout
      it_fieldcat              = li_fieldcat
      it_sort                  = li_sort
    TABLES
      t_outtab                 = i_alv
    EXCEPTIONS
      program_error            = 1
      OTHERS                   = 2.
  IF sy-subrc NE 0.
    "Error al generar el ALV
    MESSAGE e005(zfir_bus_doc_msg).
  ENDIF.

ENDFORM.                    " F_ALV_REPORT
*&---------------------------------------------------------------------*
*&      Form  uset_pf_status
*&---------------------------------------------------------------------*
*      ESTABLECER EL STATUS CREADO PARA EL ALV
*----------------------------------------------------------------------*
*      -->RT_EXTAB   Tabla de exclusiones de funciones del PF-STATUS
*----------------------------------------------------------------------*
FORM set_pf_status USING rt_extab TYPE slis_t_extab.

  SET PF-STATUS 'ZFIR_DOC_ALVSTATUS' EXCLUDING rt_extab.

ENDFORM.                    "set_pf_status
*&---------------------------------------------------------------------*
*&      Form  user_command
*&---------------------------------------------------------------------*
*     EJECUTAR SMARTFORM ZFISF_DOC_KR_KZ / ZFISF_DOC_SA
*----------------------------------------------------------------------*
*      -->R_UCOMM      Acción del usuario
*      -->RS_SELFIELD  Fila/Campo seleccionado en el ALV
*----------------------------------------------------------------------*
FORM user_command USING r_ucomm     LIKE sy-ucomm
                        rs_selfield TYPE slis_selfield.

  DATA: lv_fm_name     TYPE rs38l_fnam,
        ls_ctrl        TYPE ssfctrlop,
        lwa_alv        TYPE ty_tabla_alv,
        li_doc_sf      TYPE ztt_docsf,
        lwa_linea_sf   TYPE zty_docsf,
        lv_sf          TYPE tdsfname,
        lv_porcent_imp TYPE zparam-valor_salida.

  FIELD-SYMBOLS: <lfs_linea_selec> LIKE LINE OF i_alv,
                 <lfs_cab_sf>      TYPE zty_docsf.

  "Cuando se presione el botón Imprimir SmartForm
  CASE r_ucomm.
    WHEN 'PRINT_SF'.

      "Verificar que se haya seleccionado un registro    
      IF rs_selfield-tabindex IS INITIAL OR rs_selfield-tabindex = 0.
        "Debe seleccionar un registro
        MESSAGE e011(zfir_bus_doc_msg).
        RETURN.
      ENDIF.

      "Tomar la línea seleccionada en el ALV
      READ TABLE i_alv ASSIGNING <lfs_linea_selec> INDEX rs_selfield-tabindex.

      IF sy-subrc NE 0.
        "Error al recuperar la linea seleccionada del ALV
        MESSAGE e009(zfir_bus_doc_msg).
        RETURN.
      ENDIF.

      "Filtrar i_alv por la clave del documento de la línea seleccionada
      REFRESH li_doc_sf.

      LOOP AT i_alv INTO lwa_alv.
        IF lwa_alv-bukrs = <lfs_linea_selec>-bukrs AND
           lwa_alv-belnr = <lfs_linea_selec>-belnr AND
           lwa_alv-gjhar = <lfs_linea_selec>-gjhar.

          "Armar tabla para el SmartForm
          MOVE-CORRESPONDING lwa_alv TO lwa_linea_sf.
          APPEND lwa_linea_sf TO li_doc_sf.
        ENDIF.
      ENDLOOP.

      IF li_doc_sf IS INITIAL.
        "Error al recuperar información para el formulario
        MESSAGE e010(zfir_bus_doc_msg).
        RETURN.
      ELSE.

        "Leer el primer registro de la tabla del SmartForm
        READ TABLE li_doc_sf ASSIGNING <lfs_cab_sf> INDEX 1.
        IF sy-subrc NE 0.
          RETURN.
        ENDIF.

        "Si el tipo de documento es KR o KZ
        IF <lfs_cab_sf>-blart = 'KZ' OR <lfs_cab_sf>-blart = 'KR'.

          "Verificar si alguna posición tiene retención de imp
          CLEAR lv_porcent_imp.

          READ TABLE li_doc_sf TRANSPORTING NO FIELDS WITH KEY zusch = 'Si'.

          "Obtener el % de impuesto aplicado
          IF sy-subrc EQ 0.
            SELECT SINGLE valor_salida
              INTO lv_porcent_imp
              FROM zparam
              WHERE bukrs   = <lfs_cab_sf>-bukrs
                AND id      = 'ZFB01'
                AND param   = 'PORCENTAJE_IMP'
                AND num_sec = '001'.

            IF sy-subrc NE 0.
              CLEAR lv_porcent_imp.
            ENDIF.
          ENDIF. "READ TABLE lt_doc_sf TRANSPORTING NO FIELDS

          "Asignar el nombre del SF correspondiente a estos documentos
          lv_sf = 'ZFISF_DOC_KR_KZ'.

        ELSE.

          "Asignar el nombre del SF correspondiente a docs SA
          lv_sf = 'ZFISF_DOC_SA'.

        ENDIF. "IF <lfs_cab_sf>-blart = 'KZ' OR <lfs_cab_sf>-blart = 'KR'.

        "Recuperar el nombre técnico de la función que ejecuta el formulario
        CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
          EXPORTING
            formname           = lv_sf
          IMPORTING
            fm_name            = lv_fm_name
          EXCEPTIONS
            no_form            = 1
            no_function_module = 2
            OTHERS             = 3.

        IF sy-subrc NE 0.
          "Error al obtener SmartForm
          MESSAGE e008(zfir_bus_doc_msg).
          RETURN.
        ENDIF.

        "Llamar al formulario
        ls_ctrl-no_dialog = 'X'.
        ls_ctrl-preview   = 'X'.

        CALL FUNCTION lv_fm_name
          EXPORTING
            control_parameters = ls_ctrl
            iv_bukrs           = <lfs_cab_sf>-bukrs      "Sociedad
            iv_butxt           = <lfs_cab_sf>-butxt      "Descripcion sociedad
            iv_belnr           = <lfs_cab_sf>-belnr      "Numero de doc
            iv_gjhar           = <lfs_cab_sf>-gjhar      "Año fiscal
            iv_bldat           = <lfs_cab_sf>-bldat      "Fecha Doc
            iv_budat           = <lfs_cab_sf>-budat      "Fecha de posteo
            iv_blart           = <lfs_cab_sf>-blart      "Tipo de doc
            iv_bktxt_tipo      = <lfs_cab_sf>-bktxt_tipo "Descripcion tipo de doc
            iv_xblnr           = <lfs_cab_sf>-xblnr      "Referencia
            iv_bktxt_doc       = <lfs_cab_sf>-bktxt_doc  "Texto Cabecera
            iv_monat           = <lfs_cab_sf>-monat      "Periodo
            iv_porcent_imp     = lv_porcent_imp          "Porcentaje de impuesto
          TABLES
            it_doc_sf          = li_doc_sf.

      ENDIF. "IF lt_doc_sf IS INITIAL.
  ENDCASE. "r_ucomm WHEN 'PRINT_SF'.

ENDFORM.                    "user_command
*&---------------------------------------------------------------------*
*&      Form  F_BUILD_FIELDCAT
*&---------------------------------------------------------------------*
*  CONSTRUCCIÓN DEL CATÁLOGO DE CAMPOS
*----------------------------------------------------------------------*
*      <--P_LI_FIELDCAT  Tabla interna para catálogo de campos
*----------------------------------------------------------------------*
FORM f_build_fieldcat  CHANGING p_li_fieldcat TYPE slis_t_fieldcat_alv.

  DATA lwa_fieldcat TYPE slis_fieldcat_alv.

  lwa_fieldcat-fieldname = 'BUKRS'.
  lwa_fieldcat-seltext_m = text-002. "Sociedad
  lwa_fieldcat-tabname   = 'I_ALV'.
  APPEND lwa_fieldcat TO p_li_fieldcat.

  CLEAR lwa_fieldcat.
  lwa_fieldcat-fieldname = 'BUTXT'.
  lwa_fieldcat-seltext_m = text-003. "Nombre Sociedad
  lwa_fieldcat-tabname   = 'I_ALV'.
  APPEND lwa_fieldcat TO p_li_fieldcat.

  CLEAR lwa_fieldcat.
  lwa_fieldcat-fieldname = 'LAND1'.
  lwa_fieldcat-seltext_m = text-004. "País
  lwa_fieldcat-tabname   = 'I_ALV'.
  APPEND lwa_fieldcat TO p_li_fieldcat.

  CLEAR lwa_fieldcat.
  lwa_fieldcat-fieldname = 'GJHAR'.
  lwa_fieldcat-seltext_m = text-005. "Año Fiscal
  lwa_fieldcat-tabname   = 'I_ALV'.
  APPEND lwa_fieldcat TO p_li_fieldcat.

  CLEAR lwa_fieldcat.
  lwa_fieldcat-fieldname = 'BELNR'.
  lwa_fieldcat-seltext_m = text-006. "Num. de Doc.
  lwa_fieldcat-tabname   = 'I_ALV'.
  APPEND lwa_fieldcat TO p_li_fieldcat.

  CLEAR lwa_fieldcat.
  lwa_fieldcat-fieldname = 'BLDAT'.
  lwa_fieldcat-seltext_l = text-007. "Fecha Doc
  lwa_fieldcat-tabname   = 'I_ALV'.
  APPEND lwa_fieldcat TO p_li_fieldcat.

  CLEAR lwa_fieldcat.
  lwa_fieldcat-fieldname = 'BUDAT'.
  lwa_fieldcat-seltext_m = text-008. "Fecha Post.
  lwa_fieldcat-tabname   = 'I_ALV'.
  APPEND lwa_fieldcat TO p_li_fieldcat.

  CLEAR lwa_fieldcat.
  lwa_fieldcat-fieldname = 'MONAT'.
  lwa_fieldcat-seltext_m = text-009. "P. Cont.
  lwa_fieldcat-tabname   = 'I_ALV'.
  APPEND lwa_fieldcat TO p_li_fieldcat.

  CLEAR lwa_fieldcat.
  lwa_fieldcat-fieldname = 'BLART'.
  lwa_fieldcat-seltext_l = text-010. "Tipo Doc
  lwa_fieldcat-tabname   = 'I_ALV'.
  APPEND lwa_fieldcat TO p_li_fieldcat.

  CLEAR lwa_fieldcat.
  lwa_fieldcat-fieldname = 'BKTXT_TIPO'.
  lwa_fieldcat-seltext_m = text-011. "Descripción del documento
  lwa_fieldcat-tabname   = 'I_ALV'.
  APPEND lwa_fieldcat TO p_li_fieldcat.

  CLEAR lwa_fieldcat.
  lwa_fieldcat-fieldname = 'XBLNR'.
  lwa_fieldcat-seltext_m = text-012. "Referencia
  lwa_fieldcat-tabname   = 'I_ALV'.
  APPEND lwa_fieldcat TO p_li_fieldcat.

  CLEAR lwa_fieldcat.
  lwa_fieldcat-fieldname = 'BKTXT_DOC'.
  lwa_fieldcat-seltext_m = text-013. "Texto Cabecera
  lwa_fieldcat-tabname   = 'I_ALV'.
  APPEND lwa_fieldcat TO p_li_fieldcat.

  CLEAR lwa_fieldcat.
  lwa_fieldcat-fieldname = 'POSNR'.
  lwa_fieldcat-seltext_m = text-014. "Pos
  lwa_fieldcat-tabname   = 'I_ALV'.
  APPEND lwa_fieldcat TO p_li_fieldcat.

  CLEAR lwa_fieldcat.
  lwa_fieldcat-fieldname = 'ZFBDT'.
  lwa_fieldcat-seltext_m = text-015. "Vencimiento
  lwa_fieldcat-tabname   = 'I_ALV'.
  APPEND lwa_fieldcat TO p_li_fieldcat.

  CLEAR lwa_fieldcat.
  lwa_fieldcat-fieldname = 'HKONT'.
  lwa_fieldcat-seltext_m = text-016. "Cuenta
  lwa_fieldcat-tabname   = 'I_ALV'.
  APPEND lwa_fieldcat TO p_li_fieldcat.

  CLEAR lwa_fieldcat.
  lwa_fieldcat-fieldname = 'TXT50'.
  lwa_fieldcat-seltext_l = text-024. "Descripción de la cuenta
  lwa_fieldcat-tabname   = 'I_ALV'.
  APPEND lwa_fieldcat TO p_li_fieldcat.

  CLEAR lwa_fieldcat.
  lwa_fieldcat-fieldname = 'DATBI'.
  lwa_fieldcat-seltext_m = text-017. "Fin de Validez
  lwa_fieldcat-tabname   = 'I_ALV'.
  APPEND lwa_fieldcat TO p_li_fieldcat.

  CLEAR lwa_fieldcat.
  lwa_fieldcat-fieldname = 'WAERS'.
  lwa_fieldcat-seltext_m = text-018. "Moneda del Doc
  lwa_fieldcat-tabname   = 'I_ALV'.
  APPEND lwa_fieldcat TO p_li_fieldcat.

  CLEAR lwa_fieldcat.
  lwa_fieldcat-fieldname = 'DMBTR'.
  lwa_fieldcat-seltext_m = text-019. "Monto
  lwa_fieldcat-tabname   = 'I_ALV'.
  APPEND lwa_fieldcat TO p_li_fieldcat.

  CLEAR lwa_fieldcat.
  lwa_fieldcat-fieldname = 'WAER2'.
  lwa_fieldcat-seltext_l = text-020. "Moneda Local
  lwa_fieldcat-tabname   = 'I_ALV'.
  APPEND lwa_fieldcat TO p_li_fieldcat.

  CLEAR lwa_fieldcat.
  lwa_fieldcat-fieldname = 'WRBTR'.
  lwa_fieldcat-seltext_m = text-019. "Monto
  lwa_fieldcat-tabname   = 'I_ALV'.
  APPEND lwa_fieldcat TO p_li_fieldcat.

  CLEAR lwa_fieldcat.
  lwa_fieldcat-fieldname = 'SGTXT'.
  lwa_fieldcat-seltext_m = text-021. "Texto Posición
  lwa_fieldcat-tabname   = 'I_ALV'.
  APPEND lwa_fieldcat TO p_li_fieldcat.

  CLEAR lwa_fieldcat.
  lwa_fieldcat-fieldname = 'ZUSCH'.
  lwa_fieldcat-seltext_m = text-022. "Imp
  lwa_fieldcat-tabname   = 'I_ALV'.
  APPEND lwa_fieldcat TO p_li_fieldcat.

  CLEAR lwa_fieldcat.
  lwa_fieldcat-fieldname = 'MSG'.
  lwa_fieldcat-seltext_m = text-023. "Errores
  lwa_fieldcat-tabname   = 'I_ALV'.
  APPEND lwa_fieldcat TO p_li_fieldcat.

ENDFORM.                    " F_BUILD_FIELDCAT
*&---------------------------------------------------------------------*
*&      Form  F_BUILD_SORT
*&---------------------------------------------------------------------*
*      CRITERIOS DE ORDENAMIENTO DE SALIDA DEL ALV
*----------------------------------------------------------------------*
*      <--P_LI_SORT  Tabla interna para criterios de ordenamientos
*----------------------------------------------------------------------*
FORM f_build_sort  CHANGING p_li_sort TYPE slis_t_sortinfo_alv.

  DATA lwa_sort TYPE slis_sortinfo_alv.

  CLEAR lwa_sort.
  lwa_sort-fieldname = 'BUKRS'.   "Sociedad
  lwa_sort-up        = abap_true. "Ascendente
  lwa_sort-spos      = 1.
  APPEND lwa_sort TO p_li_sort.

  CLEAR lwa_sort.
  lwa_sort-fieldname = 'GJHAR'.   "Año fiscal
  lwa_sort-up        = abap_true. "Ascendente
  lwa_sort-spos      = 2.
  APPEND lwa_sort TO p_li_sort.

  CLEAR lwa_sort.
  lwa_sort-fieldname = 'BELNR'.   "Num de Doc.
  lwa_sort-up        = abap_true. "Ascendente
  lwa_sort-spos      = 3.
  APPEND lwa_sort TO p_li_sort.

ENDFORM.                    " F_BUILD_SORT
