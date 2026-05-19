*&---------------------------------------------------------------------*
*&  Include           ZFIP_FB01_AUTOM_F01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  F_CLEAR
*&---------------------------------------------------------------------*
*   LIMPIEZA DE VARIABLES Y TABLAS GLOBALES
*----------------------------------------------------------------------*
FORM f_clear .

  REFRESH: i_cab, i_pos, i_cab_bi, i_pos_bi, i_alv.
  CLEAR v_file_name.

ENDFORM.                    " F_CLEAR
*&---------------------------------------------------------------------*
*&      Form  F_F4_HELP
*&---------------------------------------------------------------------*
*    CONFIGURACIÓN DE LA AYUDA DE BÚSQUEDA DE ARCHIVOS SEGÚN ORIGEN:
*                LOCAL ('L') O SERVIDOR ('S')
*----------------------------------------------------------------------*
*      -->P_V_MODE  Indicador del modo ('L' o 'S')
*      <--P_P_PATH  Ruta seleccionada
*----------------------------------------------------------------------*
FORM f_f4_help  USING    p_v_mode TYPE c
                CHANGING p_p_path TYPE string.

  DATA: li_filetable TYPE filetable, "Tabla para almacenar archivos seleccionados
        lv_subrc     TYPE sy-subrc,  "Variable para códigos de retorno
        lv_mask      TYPE string.    "Filtro de archivos (vacío = todos)

  FIELD-SYMBOLS: <lfs_filetable> LIKE LINE OF li_filetable.

*Casos en los que se ejecuta la ayuda de búsqueda
  CASE p_v_mode.

      "Para seleccionar un archivo local
    WHEN 'L'.
      CALL METHOD cl_gui_frontend_services=>file_open_dialog
        CHANGING
          file_table              = li_filetable   "Devuelve el archivo seleccionado
          rc                      = lv_subrc
        EXCEPTIONS
          file_open_dialog_failed = 1
          cntl_error              = 2
          error_no_gui            = 3
          not_supported_by_gui    = 4
          OTHERS                  = 5.

      IF sy-subrc EQ 0.

        READ TABLE li_filetable ASSIGNING <lfs_filetable> INDEX 1.

        IF sy-subrc EQ 0.
          "Guardar en el parámetro
          p_p_path = <lfs_filetable>-filename.
        ENDIF.

      ELSE.
        "Mensaje estándar de error del sistema
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

      "Para seleccionar un archivo del servidor
    WHEN 'S'.
      CALL FUNCTION '/SAPDMC/LSM_F4_SERVER_FILE'
        EXPORTING
          directory        = p_p_path     "Directorio inicial
          filemask         = lv_mask      "Filtro de archivos
        IMPORTING
          serverfile       = p_p_path     "Ruta del archivo seleccionada
        EXCEPTIONS
          canceled_by_user = 1
          OTHERS           = 2.

      IF sy-subrc NE 0.
        "Mensaje estándar de error del sistema
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

    WHEN OTHERS.
      CLEAR p_p_path.

  ENDCASE. "CASE p_v_mode

ENDFORM.                                                    " F_F4_HELP
*&---------------------------------------------------------------------*
*&      Form  F_HIDE_SCREEN_FIELDS
*&---------------------------------------------------------------------*
*   CRITERIOS DE VISUALIZACIÓN DE CAMPOS DE LA PANTALLA DE SELECCIÓN
*----------------------------------------------------------------------*
FORM f_hide_screen_fields .

  "Al seleccionar 'Archivo del servidor'
  IF rb_al11 IS NOT INITIAL.
    LOOP AT SCREEN.
      "Ocultar los parámetros 'Ruta de origen' y 'Ruta destino'
      IF screen-group1 = 'Z01'.
        screen-input     = 0. "Campo no editable
        screen-invisible = 1. "Campo invisible
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.

    "Al seleccionar 'Archivo Local'
  ELSEIF rb_loc IS NOT INITIAL.
    LOOP AT SCREEN.
      "Ocultar 'Ruta de archivos a procesar', 'Ruta de archivos procesados' y 'Ruta Log'
      IF screen-group1 = 'Z02'.
        screen-input     = 0. "Campo no editable
        screen-invisible = 1. "Campo invisible
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ENDIF. "rb_al11 IS NOT INITIAL.

ENDFORM.                    " F_HIDE_SCREEN_FIELDS
*&---------------------------------------------------------------------*
*&      Form  F_UPLOAD
*&---------------------------------------------------------------------*
*   LEVANTAR ARCHIVOS, VALIDAR INFORMACIÓN Y ACOMODAR EN I_CAB Y I_POS
*----------------------------------------------------------------------*
FORM f_upload .

  TYPES: BEGIN OF lty_file,
          linea TYPE char50,
         END OF lty_file.

  DATA: li_file_sinformato TYPE STANDARD TABLE OF lty_file,
        lwa_fileaux        TYPE lty_file,
        lwa_cab            TYPE ty_cab,
        lwa_pos            TYPE ty_pos,
        lv_error           TYPE string,
        li_dirlist         TYPE TABLE OF epsfili,
        lv_dirname         TYPE epsf-epsdirnam,
        lv_linea           TYPE sy-tabix,
        lv_serv_path       TYPE string,
        li_parts           TYPE STANDARD TABLE OF char255,
        lv_lines           TYPE i,
        lv_file_used       TYPE abap_bool,
        lv_line_error      TYPE abap_bool.

  FIELD-SYMBOLS: <lfs_file_sinformato> LIKE LINE OF li_file_sinformato,
                 <lfs_dirlist>         LIKE LINE OF li_dirlist.


**********Archivo Local**************
  IF rb_loc IS NOT INITIAL.

    "Tomar archivo desde ruta p_path1 y cargar los datos en la tabla interna
    CALL FUNCTION 'GUI_UPLOAD'
      EXPORTING
        filename                = p_path1
      TABLES
        data_tab                = li_file_sinformato
      EXCEPTIONS
        file_open_error         = 1
        file_read_error         = 2
        no_batch                = 3
        gui_refuse_filetransfer = 4
        invalid_type            = 5
        no_authority            = 6
        unknown_error           = 7
        bad_data_format         = 8
        header_not_allowed      = 9
        separator_not_allowed   = 10
        header_too_long         = 11
        unknown_dp_error        = 12
        access_denied           = 13
        dp_out_of_memory        = 14
        disk_full               = 15
        dp_timeout              = 16
        OTHERS                  = 17.
    IF sy-subrc EQ 0.

      "Obtener el nombre del archivo desde la ruta completa
      SPLIT p_path1 AT '\' INTO TABLE li_parts.            "Dividir la ruta en cada '\'
      DESCRIBE TABLE li_parts LINES lv_lines.              "Contar cuantas partes tiene
      READ TABLE li_parts INDEX lv_lines INTO v_file_name. "Tomar la última parte (nombre del archivo)


      "Verificar que el archivo no haya sido procesado anteriormente
      PERFORM f_check_file_processed USING v_file_name
                                     CHANGING lv_file_used.

      IF lv_file_used = abap_true.
        PERFORM f_append_error_alv USING v_file_name
                                         space
                                         space
                                         text-000. "Archivo ya procesado anteriormente
        RETURN.
      ENDIF.

      CLEAR lv_line_error.

      "Separar la informacion de la linea en cada ;
      LOOP AT li_file_sinformato ASSIGNING <lfs_file_sinformato>.

        "Segun la primera letra se asigna en la estructura correspondiente
        CASE <lfs_file_sinformato>-linea(1).
          WHEN c_tipo_c. "C = cabecera
            SPLIT <lfs_file_sinformato>-linea AT c_pyc INTO lwa_cab-tipo_linea
                                                            lwa_cab-belnr_ext
                                                            lwa_cab-bldat
                                                            lwa_cab-bukrs_ext
                                                            lwa_cab-waers
                                                            lwa_cab-blart_ext
                                                            lwa_cab-xblnr.

            lwa_cab-linea       = sy-tabix.
            lwa_cab-nombre_arch = v_file_name.
            APPEND lwa_cab TO i_cab.

          WHEN c_tipo_p. "P = posición
            SPLIT <lfs_file_sinformato>-linea AT c_pyc INTO lwa_pos-tipo_linea
                                                            lwa_pos-belnr_ext
                                                            lwa_pos-dmbtr
                                                            lwa_pos-zfbdt
                                                            lwa_pos-zusch_ext
                                                            lwa_pos-skonto_ext.

            lwa_pos-linea       = sy-tabix.
            lwa_pos-nombre_arch = v_file_name.
            APPEND lwa_pos TO i_pos.

          WHEN OTHERS.
            CONCATENATE text-024 <lfs_file_sinformato>-linea+0(1) INTO lv_error SEPARATED BY space.
            "           Tipo de línea inválido: &

            PERFORM f_append_error_alv USING v_file_name
                                             space
                                             space
                                             lv_error.
            lv_line_error = abap_true.
            EXIT.
        ENDCASE.
      ENDLOOP. "AT li_file_sinformato ASSIGNING <lfs_file_sinformato>.

      "Mover el archivo al destino
      PERFORM f_move_local_file.

      "Agregar el nombre del archivo a tabla de procesados
      PERFORM f_save_processed_file.

    ELSE.
      MESSAGE e001(zfb01_bi) WITH p_path1. "Error de acceso a la ruta &
    ENDIF. "CALL FUNCTION 'GUI_UPLOAD'. IF sy-subrc EQ 0.


*********Archivo del Servidor***********
  ELSEIF rb_al11 IS NOT INITIAL.

    REFRESH: li_dirlist.
    lv_dirname = p_path2.

    "Recuperar nombres de archivos de una carpeta del servidor
    CALL FUNCTION 'EPS_GET_DIRECTORY_LISTING'
      EXPORTING
        dir_name               = lv_dirname
      TABLES
        dir_list               = li_dirlist
      EXCEPTIONS
        invalid_eps_subdir     = 1
        sapgparam_failed       = 2
        build_directory_failed = 3
        no_authorization       = 4
        read_directory_failed  = 5
        too_many_read_errors   = 6
        empty_directory_list   = 7
        OTHERS                 = 8.
    IF sy-subrc IS NOT INITIAL.
      MESSAGE e002(zfb01_bi). "No se pudieron recuperar los archivos del directorio AL11
    ENDIF.

    IF li_dirlist IS NOT INITIAL.
      "Recorrer los archivos obtenidos
      LOOP AT li_dirlist ASSIGNING <lfs_dirlist>.

        CLEAR: lv_serv_path, lv_linea, lv_line_error.

        "Copiar el nombre del archivo AL11 a variable compatible
        v_file_name = <lfs_dirlist>-name.

        "Verificar que el archivo no haya sido procesado anteriormente
        PERFORM f_check_file_processed USING v_file_name
                                       CHANGING lv_file_used.

        IF lv_file_used = abap_true.
          PERFORM f_append_error_alv USING v_file_name
                                           space
                                           space
                                           text-000. "Archivo ya procesado anteriormente
          CONTINUE. "Pasar al siguiente archivo
        ENDIF.

        lv_serv_path = p_path2.

        "Concatenar ruta del servidor con el nombre del archivo.
        CONCATENATE lv_serv_path <lfs_dirlist>-name INTO lv_serv_path. "Ruta completa del archivo

        "Abrir archivo desde el servidor
        OPEN DATASET lv_serv_path FOR INPUT IN TEXT MODE ENCODING UTF-8 IGNORING CONVERSION ERRORS.
        IF sy-subrc IS NOT INITIAL.
          MESSAGE e001(zfb01_bi) WITH p_path2. "Error de acceso a ruta
        ELSE.

          DO.
            "Leer cada registro del archivo
            READ DATASET lv_serv_path INTO lwa_fileaux.
            IF sy-subrc NE 0.
              EXIT.
            ENDIF.

            lv_linea = lv_linea + 1.

            "Segun la primera letra se asigna en la estructura correspondiente
            CASE lwa_fileaux-linea+0(1).
              WHEN c_tipo_c. "C = cabecera
                SPLIT lwa_fileaux-linea AT c_pyc INTO lwa_cab-tipo_linea
                                                      lwa_cab-belnr_ext
                                                      lwa_cab-bldat
                                                      lwa_cab-bukrs_ext
                                                      lwa_cab-waers
                                                      lwa_cab-blart_ext
                                                      lwa_cab-xblnr.

                lwa_cab-linea       = lv_linea.
                lwa_cab-nombre_arch = <lfs_dirlist>-name.
                APPEND lwa_cab TO i_cab.

              WHEN c_tipo_p. "P = posición
                SPLIT lwa_fileaux-linea AT c_pyc INTO lwa_pos-tipo_linea
                                                      lwa_pos-belnr_ext
                                                      lwa_pos-dmbtr
                                                      lwa_pos-zfbdt
                                                      lwa_pos-zusch_ext
                                                      lwa_pos-skonto_ext.

                lwa_pos-linea       = lv_linea.
                lwa_pos-nombre_arch = <lfs_dirlist>-name.
                APPEND lwa_pos TO i_pos.

              WHEN OTHERS.
                CONCATENATE text-024 lwa_fileaux-linea+0(1) INTO lv_error SEPARATED BY space.
                "           Tipo de línea inválido: &

                PERFORM f_append_error_alv USING <lfs_dirlist>-name
                                                 space
                                                 space
                                                 lv_error.
                lv_line_error = abap_true.
                EXIT.
            ENDCASE.
          ENDDO.

          "Eliminar registros ya cargados de ese archivo si se detectó una línea inválida
          IF lv_line_error = abap_true.
            DELETE i_cab WHERE nombre_arch = <lfs_dirlist>-name.
            DELETE i_pos WHERE nombre_arch = <lfs_dirlist>-name.
          ENDIF.

          "Cerrar archivo del servidor
          CLOSE DATASET lv_serv_path.
        ENDIF. "OPEN DATASET lv_serv_path

        "Mover a carpeta de procesados
        PERFORM f_move_al11_file USING lv_serv_path.

        "Agregar el nombre del archivo a la tabla de procesados
        PERFORM f_save_processed_file.

      ENDLOOP. "LOOP AT li_dirlist ASSIGNING <lfs_dirlist>.

    ELSE.
      MESSAGE e003(zfb01_bi) WITH lv_dirname. "No se ha encontrado ningún archivo en &
    ENDIF. "IF li_dirlist IS NOT INITIAL.

  ENDIF. "IF rb_loc IS NOT INITIAL. ELSEIF rb_al11 IS NOT INITIAL.

ENDFORM.                    " F_UPLOAD
*&---------------------------------------------------------------------*
*&      Form  F_MOVE_AL11_FILE
*&---------------------------------------------------------------------*
*  MOVER LOS ARCHIVOS A UNA CARPETA DE PROCESADOS
*----------------------------------------------------------------------*
*      -->p_lv_serv_path    Ruta + Nombre del archivo
*----------------------------------------------------------------------*
FORM f_move_al11_file  USING    p_lv_serv_path.

  DATA:   lv_error       TYPE string,
          lv_origen      TYPE string,
          lv_destino     TYPE string,
          lv_oscmd(300)  TYPE c,
          li_return      TYPE STANDARD TABLE OF char80,
          lv_filename    TYPE string,
          lv_path_length TYPE i.

  "Calcular la cantidad de caracteres de p_path2
  lv_path_length = strlen( p_path2 ).

  "Obtener el nombre de archivo desde p_lv_serv_path usando offset
  lv_filename = p_lv_serv_path+lv_path_length. "lv_filename = archivo001.txt


  CONCATENATE '"'  p_lv_serv_path       '"' INTO lv_origen.
  CONCATENATE '"'  p_pathd2 lv_filename '"' INTO lv_destino.
  CONCATENATE 'mv' lv_origen lv_destino     INTO lv_oscmd SEPARATED BY space.

  CALL 'SYSTEM'
  ID 'COMMAND' FIELD lv_oscmd
  ID 'TAB'     FIELD li_return[].

  IF sy-subrc IS NOT INITIAL.
    CONCATENATE text-001 v_file_name INTO lv_error SEPARATED BY space.
    "           No se ha podido mover el archivo &

    PERFORM f_append_error_alv USING lv_filename
                                     space
                                     0
                                     lv_error.
  ENDIF.

ENDFORM.                    " F_MOVE_AL11_FILE
*&---------------------------------------------------------------------*
*&      Form  F_MOVE_LOCAL_FILE
*&---------------------------------------------------------------------*
* CREAR UNA COPIA DEL ARCHIVO EN CARPETA DESTINO Y ELIMINAR EL ORIGINAL
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM f_move_local_file .

  DATA: lv_source   TYPE string,
        lv_destino  TYPE string,
        lv_error    TYPE string,
        lv_rc       TYPE i.

  lv_source = p_path1.

  "Armar destino (carpeta destino + nombre archivo)
  CONCATENATE p_pathd1 '\' v_file_name INTO lv_destino.

  "Copiar archivo (method file_move no esta permitido en MiniSap)
  CALL METHOD cl_gui_frontend_services=>file_copy
    EXPORTING
      source      = lv_source
      destination = lv_destino
      overwrite   = 'X'
    EXCEPTIONS
      OTHERS      = 1.

  IF sy-subrc NE 0.
    CONCATENATE text-001 v_file_name INTO lv_error SEPARATED BY space.
    "           No se ha podido mover el archivo &
  ELSE.
    "Borrar original
    CALL METHOD cl_gui_frontend_services=>file_delete
      EXPORTING
        filename = lv_source
      CHANGING
        rc       = lv_rc   "Resultado del sistema operativo
      EXCEPTIONS
        OTHERS   = 1.

    IF sy-subrc NE 0 OR lv_rc NE 0.
      CONCATENATE text-002 v_file_name INTO lv_error SEPARATED BY space.
      "           No se pudo borrar el archivo original &
    ENDIF.

  ENDIF. "CALL METHOD cl_gui_frontend_services=>file_copy

  IF lv_error IS NOT INITIAL.
    PERFORM f_append_error_alv USING v_file_name
                                     space
                                     space
                                     lv_error.
  ENDIF.

ENDFORM.                    " F_MOVE_LOCAL_FILE
*&---------------------------------------------------------------------*
*&      Form  F_CHECK_FILE_PROCESSED
*&---------------------------------------------------------------------*
*     VERIFICAR SI UN ARCHIVO YA FUE PROCESADO
*----------------------------------------------------------------------*
*      -->p_file_name       Nombre del Archivo
*      <--e_lv_file_used    Indicador Verdadero o Falso
*----------------------------------------------------------------------*
FORM f_check_file_processed  USING    p_file_name TYPE char255
                             CHANGING e_lv_file_used TYPE abap_bool.

  DATA lwa_file_proc TYPE zfb01_file_proc.

  "Chequear si el archivo ya existe en la tabla de procesados
  SELECT SINGLE *
    FROM zfb01_file_proc
    INTO lwa_file_proc
    WHERE zfilename = p_file_name.

  IF sy-subrc EQ 0. "Archivo ya procesado
    e_lv_file_used = abap_true.
  ENDIF.

ENDFORM.                    " F_CHECK_FILE_PROCESSED
*&---------------------------------------------------------------------*
*&      Form  F_PROCESS_DATA
*&---------------------------------------------------------------------*
*     VALIDAR LA INFORMACIÓN RECOPILADA DEL ARCHIVO
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM f_process_data .

  DATA: li_cab_aux        TYPE tt_cab,
        li_soc_ext        TYPE tt_soc_ext,
        lwa_soc_ext       TYPE ty_soc_ext,
        li_soc_int        TYPE tt_soc_int,
        lwa_soc_int       TYPE ty_soc_int,
        li_ctas_ext       TYPE tt_ctas_ext,
        lwa_ctas_ext      TYPE ty_ctas_ext,
        li_ctas_int       TYPE tt_ctas_int,
        lwa_ctas_int      TYPE ty_ctas_int,
        li_zparam_aux     TYPE tt_zparam_aux,
        lwa_zparam_aux    TYPE ty_zparam_aux,
        li_param_textcab  TYPE tt_zparam_aux,
        lwa_param_textcab TYPE ty_zparam_aux,
        li_param_textpos  TYPE tt_zparam_aux,
        lwa_param_textpos TYPE ty_zparam_aux,
        li_param_tipodoc  TYPE tt_zparam_aux,
        lwa_param_tipodoc TYPE ty_zparam_aux,
        li_pos_aux        TYPE tt_pos,
        lwa_cab_bi        TYPE ty_cab_bi,
        li_pos_check      TYPE tt_pos_bi,
        lwa_pos_check     TYPE ty_pos_bi.

  DATA: lv_mes            TYPE zbkpf-monat,
        lv_mes_txt(10)    TYPE c,
        lv_bukrs          TYPE zbkpf-bukrs,
        lv_blart          TYPE zbkpf-blart,
        lv_bktxt          TYPE zbkpf-bktxt,
        lv_gjhar          TYPE zbkpf-gjhar,
        lv_bldat(10)      TYPE c,
 	      lv_count          TYPE i,
        lv_error_select   TYPE abap_bool,
        lv_error_pos      TYPE abap_bool,
        lv_index          TYPE sy-tabix,
        lv_msg_error      TYPE string,
        lv_skonto         TYPE zbseg-hkont,
        lv_shkzg          TYPE zbseg-shkzg,
        lv_dmbtr          TYPE zbseg-dmbtr,
        lv_monto_text     TYPE string,
        lv_zfbdt          TYPE zbseg-zfbdt,
        lv_fecha_text(10) TYPE c,
        lv_zusch          TYPE zbseg-zusch,
        lv_sgtxt          TYPE zbkpf-bktxt.

  FIELD-SYMBOLS: <lfs_i_cab>   LIKE LINE OF i_cab,
                 <lfs_i_pos>   LIKE LINE OF i_pos.


  "Obtener información de las sociedades ext de las cabeceras
  REFRESH li_cab_aux.

  li_cab_aux[] = i_cab[].
  SORT li_cab_aux BY bukrs_ext.
  DELETE ADJACENT DUPLICATES FROM li_cab_aux COMPARING bukrs_ext.

  SELECT bukrs_ext bukrs
    FROM zsoc_ext
    INTO TABLE li_soc_ext
    FOR ALL ENTRIES IN li_cab_aux
    WHERE bukrs_ext = li_cab_aux-bukrs_ext.

  IF li_soc_ext IS INITIAL.
    lv_error_select = abap_true.
    lv_msg_error    = text-014. "Error al recuperar información de las soc. ext. (ZSOC_EXT)
  ELSE.

    "Obtener información de las sociedades SAP correspondientes a las soc ext
    SORT li_soc_ext BY bukrs.

    SELECT bukrs
      FROM zt001
      INTO TABLE li_soc_int
      FOR ALL ENTRIES IN li_soc_ext
      WHERE bukrs = li_soc_ext-bukrs.

    IF li_soc_int IS INITIAL.
      lv_error_select = abap_true.
      lv_msg_error    = text-013. "Error al recuperar información de las soc. SAP (ZT001)
    ELSE.

      "Obtener información para parametrizaciones
      SORT li_soc_int BY bukrs.

      SELECT bukrs param valor_entrada valor_salida
        FROM zparam
        INTO TABLE li_zparam_aux
         FOR ALL ENTRIES IN li_soc_int
           WHERE bukrs = li_soc_int-bukrs
             AND id    = 'ZFB01_AUTOM'.

      IF li_zparam_aux IS INITIAL.
        lv_error_select = abap_true.
        lv_msg_error    = text-012. "Error al recuperar parametrizaciones (ZPARAM)
      ELSE.

        SORT li_zparam_aux BY bukrs param.

        LOOP AT li_zparam_aux INTO lwa_zparam_aux.
          CASE lwa_zparam_aux-param.
            WHEN 'TEXTO_CABECERA'.
              APPEND lwa_zparam_aux TO li_param_textcab.
            WHEN 'TEXTO_POSICION'.
              APPEND lwa_zparam_aux TO li_param_textpos.
            WHEN 'TIPO_DOC'.
              APPEND lwa_zparam_aux TO li_param_tipodoc.
            WHEN OTHERS.
              CLEAR lwa_zparam_aux.
          ENDCASE.
        ENDLOOP. "LOOP AT li_zparam_aux INTO lwa_zparam_aux

      ENDIF. "SELECT FROM zparam
    ENDIF. "SELECT FROM zt001
  ENDIF. "SELECT FROM zsoc_ext


  IF lv_error_select NE abap_true.

    "Obtener información de las cuentas externas
    li_pos_aux[] = i_pos[].
    SORT li_pos_aux BY skonto_ext.
    DELETE ADJACENT DUPLICATES FROM li_pos_aux COMPARING skonto_ext.

    SELECT skonto_ext skonto bukrs_ext bukrs
      FROM zctas_ext
      INTO TABLE li_ctas_ext
      FOR ALL ENTRIES IN li_pos_aux
      WHERE skonto_ext = li_pos_aux-skonto_ext.

    "Obtener informacion de las cuentas SAP correspondientes a las ctas ext.
    IF li_ctas_ext IS NOT INITIAL.

      SORT li_ctas_ext BY skonto.

      SELECT skonto bukrs
        FROM zhkont
        INTO TABLE li_ctas_int
        FOR ALL ENTRIES IN li_ctas_ext
        WHERE skonto = li_ctas_ext-skonto
           AND bukrs = li_ctas_ext-bukrs.

      IF li_ctas_int IS INITIAL.
        lv_error_select = abap_true.
        lv_msg_error    = text-015. "Error al recuperar información de las cuentas SAP (ZHKONT)
      ENDIF. "SELECT FROM zhkont

    ELSE.
      lv_error_select = abap_true.
      lv_msg_error    = text-034. "Error al recuperar información de las cuentas ext. (ZCTAS_EXT)
    ENDIF. "SELECT FROM zctas_ext

  ENDIF. "IF lv_error_select NE abap_true.

  "Gestión de errores
  IF lv_error_select EQ abap_true.
    READ TABLE li_cab_aux ASSIGNING <lfs_i_cab> INDEX 1.

    PERFORM f_append_error_alv USING <lfs_i_cab>-nombre_arch
                                     space
                                     space
                                     lv_msg_error.
    RETURN.
  ENDIF. "IF lv_error_select NE abap_true.

  "Ordenar tablas para los READ
  SORT i_pos            BY belnr_ext.
  SORT li_soc_ext       BY bukrs_ext.
  SORT li_param_textcab BY bukrs valor_entrada.
  SORT li_param_textpos BY bukrs valor_entrada.
  SORT li_param_tipodoc BY bukrs valor_entrada.
  SORT li_ctas_ext      BY skonto_ext.
  SORT li_ctas_int      BY skonto.

******************************************************************************************
*Validaciones de los datos de las cabeceras
  LOOP AT i_cab ASSIGNING <lfs_i_cab>.

    "Número Doc Externo informado
    IF <lfs_i_cab>-belnr_ext IS INITIAL.
      PERFORM f_append_error_alv USING <lfs_i_cab>-nombre_arch
                                       <lfs_i_cab>-belnr_ext
                                       <lfs_i_cab>-linea
                                       text-003. "Número de Documento Externo no informado
      CONTINUE.
    ENDIF.


    "Fecha Documento informada
    IF <lfs_i_cab>-bldat IS INITIAL.
      PERFORM f_append_error_alv USING <lfs_i_cab>-nombre_arch
                                       <lfs_i_cab>-belnr_ext
                                       <lfs_i_cab>-linea
                                       text-004. "Fecha del documento no informada
      CONTINUE.
    ENDIF.

    "Conversión de la fecha:
    lv_fecha_text = <lfs_i_cab>-bldat.

    CONCATENATE lv_fecha_text+0(2) "Dia
                lv_fecha_text+3(2) "Mes
                lv_fecha_text+6(4) "Año
           INTO lv_bldat. "DDMMYYYY

    "Obtener el Año Fiscal
    lv_gjhar = lv_fecha_text+6(4).


    "Obtener Período Contable
    lv_mes = <lfs_i_cab>-bldat+3(2).

    "Validar período contable
    IF lv_mes IS INITIAL OR lv_mes < '01' OR lv_mes > '12'.
      PERFORM f_append_error_alv USING <lfs_i_cab>-nombre_arch
                                       <lfs_i_cab>-belnr_ext
                                       <lfs_i_cab>-linea
                                       text-005. "Periodo contable invalido
      CONTINUE.
    ENDIF.


    "Traducción del código de sociedad externo a código SAP
    READ TABLE li_soc_ext INTO lwa_soc_ext WITH KEY bukrs_ext = <lfs_i_cab>-bukrs_ext
    BINARY SEARCH.

    IF sy-subrc NE 0.
      PERFORM f_append_error_alv USING <lfs_i_cab>-nombre_arch
                                       <lfs_i_cab>-belnr_ext
                                       <lfs_i_cab>-linea
                                       text-006. "Error en código de sociedad externo
      CONTINUE.
    ENDIF.

    "Validación del código de sociedad SAP obtenido
    READ TABLE li_soc_int INTO lwa_soc_int WITH KEY bukrs = lwa_soc_ext-bukrs
    BINARY SEARCH.

    IF sy-subrc EQ 0.
      lv_bukrs = lwa_soc_int-bukrs.
    ELSE.
      PERFORM f_append_error_alv USING <lfs_i_cab>-nombre_arch
                                       <lfs_i_cab>-belnr_ext
                                       <lfs_i_cab>-linea
                                       text-007. "Error en código de sociedad SAP
      CONTINUE.
    ENDIF.


    "Traducción del tipo de documento externo a SAP
    READ TABLE li_param_tipodoc INTO lwa_param_tipodoc WITH KEY bukrs         = lv_bukrs
                                                                valor_entrada = <lfs_i_cab>-blart_ext
    BINARY SEARCH.

    IF sy-subrc NE 0.
      PERFORM f_append_error_alv USING <lfs_i_cab>-nombre_arch
                                       <lfs_i_cab>-belnr_ext
                                       <lfs_i_cab>-linea
                                       text-008. "Tipo de documento inválido (ver ZPARAM)
      CONTINUE.
    ENDIF.

    lv_blart = lwa_param_tipodoc-valor_salida.


    "Referencia informada para tipos KZ y KR
    IF lv_blart = 'KR' OR lv_blart = 'KZ'.

      IF <lfs_i_cab>-xblnr IS INITIAL.
        PERFORM f_append_error_alv USING <lfs_i_cab>-nombre_arch
                                         <lfs_i_cab>-belnr_ext
                                         <lfs_i_cab>-linea
                                         text-009. "Referencia no informada
        CONTINUE.
      ENDIF.

    ENDIF. "IF lv_blart = 'KR' OR lv_blart = 'KZ'.


    "Obtener Texto de Cabecera
    READ TABLE li_param_textcab INTO lwa_param_textcab WITH KEY bukrs         = lv_bukrs
                                                                valor_entrada = lv_blart
    BINARY SEARCH.

    IF sy-subrc NE 0.
      PERFORM f_append_error_alv USING <lfs_i_cab>-nombre_arch
                                       <lfs_i_cab>-belnr_ext
                                       <lfs_i_cab>-linea
                                       text-010. "No es posible obtener Texto de Cab (ver ZPARAM)
      CONTINUE.
    ENDIF.

    lv_bktxt = lwa_param_textcab-valor_salida.

    "Traducción del N° del período contable
    CALL FUNCTION 'ZFM_GET_MONTH_NAME'
      EXPORTING
        iv_mes     = lv_mes
      IMPORTING
        ev_mes_txt = lv_mes_txt.

    "Reemplazar de los & del valor_salida por: período (en letras) y el num de doc ext
    REPLACE FIRST OCCURRENCE OF '&' IN lv_bktxt WITH lv_mes_txt.
    REPLACE FIRST OCCURRENCE OF '&' IN lv_bktxt WITH <lfs_i_cab>-belnr_ext.


********************************************************************************************
*Validaciones de los datos de las posiciones del documento
    REFRESH li_pos_check.
    CLEAR: lv_count, lv_error_pos.


    "Buscar primera posición del documento externo
    READ TABLE i_pos TRANSPORTING NO FIELDS WITH KEY belnr_ext = <lfs_i_cab>-belnr_ext
    BINARY SEARCH.

    IF sy-subrc EQ 0.
      "Obtener el número de fila de esa posición
      lv_index = sy-tabix.

      "Recorrer tabla de posiciones a partir de la línea obtenida
      LOOP AT i_pos ASSIGNING <lfs_i_pos> FROM lv_index.

        "Cuando el n° de doc ext cambie, salir del LOOP
        IF <lfs_i_pos>-belnr_ext NE <lfs_i_cab>-belnr_ext.
          EXIT.
        ENDIF.

        "Contador de posiciones de la cabecera actual
        lv_count = lv_count + 1.


        "Validación del monto
        IF <lfs_i_pos>-dmbtr IS INITIAL.
          lv_error_pos = 'X'.
          lv_msg_error = text-016. "Monto no informado
          EXIT.
        ENDIF.


        "Determinar si la pos es DEBE o HABER según el signo del monto
        lv_monto_text = <lfs_i_pos>-dmbtr.

        IF lv_monto_text+0(1) = '-'.
          lv_shkzg = 'S'.  "Debe
          "Borrar el signo - del monto
          SHIFT lv_monto_text BY 1 PLACES LEFT.
        ELSE.
          lv_shkzg = 'H'.  "Haber
        ENDIF.

        lv_dmbtr = lv_monto_text. "Monto sin signo


        "Fecha de Vencimiento obligatoria para docs KR y KZ
        IF lv_blart = 'KR' OR lv_blart = 'KZ'.

          IF <lfs_i_pos>-zfbdt IS INITIAL.
            lv_error_pos = 'X'.
            lv_msg_error = text-017. "Fecha de vencimiento no informada
            EXIT.
          ELSE.
            "Conversión de la fecha:
            lv_fecha_text = <lfs_i_pos>-zfbdt.

            CONCATENATE lv_fecha_text+6(4) "Año
                        lv_fecha_text+3(2) "Mes
                        lv_fecha_text+0(2) "Dia
                   INTO lv_zfbdt. "YYYYMMDD

            "Validación que sea fecha futura
            IF lv_zfbdt LT sy-datum.
              lv_error_pos = 'X'.
              lv_msg_error = text-018. "Fecha de vencimiento inválida
              EXIT.
            ELSE.
              "Conversión de la fecha:
              CONCATENATE lv_fecha_text+0(2) "Dia
                          lv_fecha_text+3(2) "Mes
                          lv_fecha_text+6(4) "Año
                     INTO lv_zfbdt. "DDMMYYYY
            ENDIF.
          ENDIF. "<lfs_i_pos>-zfbdt IS INITIAL

        ENDIF. "lv_blart = 'KR' OR lv_blart = 'KZ'.


        "Traducción del Indicador de Impuesto
        CASE <lfs_i_pos>-zusch_ext.
          WHEN 'SI'.
            lv_zusch = 'X'.
          WHEN 'NO'.
            lv_zusch = space.
          WHEN OTHERS.
            lv_error_pos = 'X'.
            lv_msg_error = text-019. "Error en indicador de impuesto
            EXIT.
        ENDCASE.


        "Traducción del número de cuenta externo a número de cuenta SAP
        READ TABLE li_ctas_ext INTO lwa_ctas_ext WITH KEY skonto_ext = <lfs_i_pos>-skonto_ext
        BINARY SEARCH.

        IF sy-subrc NE 0.
          lv_error_pos = 'X'.
          lv_msg_error = text-020. "Error en numero de cuenta externo
          EXIT.
        ENDIF.

        "Validación del número de cuenta SAP obtenido
        READ TABLE li_ctas_int INTO lwa_ctas_int WITH KEY skonto = lwa_ctas_ext-skonto
        BINARY SEARCH.

        IF sy-subrc EQ 0.
          lv_skonto = lwa_ctas_int-skonto.
        ELSE.
          lv_error_pos = 'X'.
          lv_msg_error = text-021. "Error en número de cuenta SAP
          EXIT.
        ENDIF.


        "Obtener Texto Posición
        READ TABLE li_param_textpos INTO lwa_param_textpos WITH KEY bukrs         = lv_bukrs
                                                                    valor_entrada = lv_blart
        BINARY SEARCH.

        IF sy-subrc NE 0.
          lv_error_pos = 'X'.
          lv_msg_error = text-022. "No es posible obtener el Texto de Posición (ver ZPARAM)
          EXIT.
        ENDIF.

        lv_sgtxt = lwa_param_textpos-valor_salida.

        "Reemplazar de los & del valor_salida por el período (en letras) y el num de doc ext
        REPLACE FIRST OCCURRENCE OF '&' IN lv_sgtxt WITH lv_mes_txt.
        REPLACE FIRST OCCURRENCE OF '&' IN lv_sgtxt WITH <lfs_i_cab>-belnr_ext.


*******************************************************************************************
        "Asignar datos validados a tabla auxiliar de posiciones
        CLEAR lwa_pos_check.

        lwa_pos_check-tipo_linea  = <lfs_i_pos>-tipo_linea.      "Posición
        lwa_pos_check-belnr_ext   = <lfs_i_pos>-belnr_ext.       "Número de Documento Externo
        lwa_pos_check-shkzg       = lv_shkzg.                    "Signo posición
        lwa_pos_check-skonto      = lv_skonto.                   "Número de cuenta
        lwa_pos_check-dmbtr       = lv_dmbtr.                    "Monto
        lwa_pos_check-sgtxt       = lv_sgtxt.                    "Texto Posición
        lwa_pos_check-zfbdt       = lv_zfbdt.                    "Fecha de Vencimiento
        lwa_pos_check-zusch       = lv_zusch.                    "Indicador de impuesto
        lwa_pos_check-nombre_arch = <lfs_i_pos>-nombre_arch.     "Nombre del archivo
        lwa_pos_check-linea       = <lfs_i_pos>-linea.           "Número de linea del archivo

        APPEND lwa_pos_check TO li_pos_check.

      ENDLOOP. "LOOP AT i_pos ASSIGNING <lfs_i_pos>

    ELSE.
      lv_count = 0.
    ENDIF. "READ TABLE i_pos ASSIGNING <lfs_i_pos>

******************************************************************************************
    "Gestión de errores en posiciones
    IF lv_error_pos IS NOT INITIAL.
      PERFORM f_append_error_alv USING <lfs_i_cab>-nombre_arch
                                       <lfs_i_cab>-belnr_ext
                                       <lfs_i_cab>-linea
                                       lv_msg_error.
      CONTINUE.
    ENDIF.

    "Validar que se encontraron al menos 2 posiciones
    IF lv_count LT 2.
      PERFORM f_append_error_alv USING <lfs_i_cab>-nombre_arch
                                       <lfs_i_cab>-belnr_ext
                                       <lfs_i_cab>-linea
                                       text-011. "El documento debe tener al menos 2 posiciones
      CONTINUE.
    ENDIF.

*******************************************************************************************
    "Asignar datos validados a tabla final de cabeceras
    CLEAR lwa_cab_bi.

    lwa_cab_bi-tipo_linea  = <lfs_i_cab>-tipo_linea.    "Cabecera
    lwa_cab_bi-belnr_ext   = <lfs_i_cab>-belnr_ext.     "Número de documento externo
    lwa_cab_bi-bldat       = lv_bldat.                  "Fecha del documento
    lwa_cab_bi-gjhar       = lv_gjhar.                  "Año Fiscal
    lwa_cab_bi-bktxt       = lv_bktxt.                  "Texto Cabecera
    lwa_cab_bi-monat       = lv_mes.                    "Período
    lwa_cab_bi-bukrs       = lv_bukrs.                  "Código Sociedad
    lwa_cab_bi-waers       = <lfs_i_cab>-waers.         "Moneda
    lwa_cab_bi-blart       = lv_blart.                  "Tipo de Documento
    lwa_cab_bi-xblnr       = <lfs_i_cab>-xblnr.         "Referencia
    lwa_cab_bi-nombre_arch = <lfs_i_cab>-nombre_arch.   "Nombre del archivo
    lwa_cab_bi-linea       = <lfs_i_cab>-linea.         "Número de linea del archivo

    APPEND lwa_cab_bi TO i_cab_bi.


    "Asignar datos validados a tabla final de posiciones
    APPEND LINES OF li_pos_check TO i_pos_bi.

  ENDLOOP. "LOOP AT i_cab ASSIGNING <lfs_i_cab>.

ENDFORM.                    " F_PROCESS_DATA
*&---------------------------------------------------------------------*
*&      Form  F_APPEND_ERROR_ALV
*&---------------------------------------------------------------------*
*  CONFIGURACIÓN DE LOS ERRORES PARA EL ALV FINAL
*----------------------------------------------------------------------*
*      -->p_nombre_arch    Nombre del archivo
*      -->p_belnr_ext      Número de doc ext
*      -->p_linea          Número de linea
*      -->p_mensaje.       Mensaje descriptivo del error
*----------------------------------------------------------------------*
FORM f_append_error_alv  USING    p_nombre_arch
                                  p_belnr_ext
                                  p_linea
                                  p_mensaje.

  FIELD-SYMBOLS <lfs_colores> TYPE slis_specialcol_alv.

  "Asignar información del error a la estructura del ALV
  CLEAR wa_alv.
  wa_alv-nombre_arch = p_nombre_arch.
  wa_alv-belnr_ext   = p_belnr_ext.
  wa_alv-linea_cab   = p_linea.
  wa_alv-semaforo    = '@0A@'.  "Rojo
  wa_alv-mensaje     = p_mensaje.

  "Configurar el color del campo de ALV
  CLEAR wa_alv-gt_colores.
  APPEND INITIAL LINE TO wa_alv-gt_colores ASSIGNING <lfs_colores>.
  <lfs_colores>-fieldname = 'MENSAJE'.
  <lfs_colores>-color-col = 6.   "Campo Rojo
  <lfs_colores>-color-int = 1.

  "Guardar en tabla del ALV
  APPEND wa_alv TO i_alv.

ENDFORM.                    " F_APPEND_ERROR_ALV
*&---------------------------------------------------------------------*
*&      Form  F_BI_ZFIP_FB01
*&---------------------------------------------------------------------*
*    BATCH INPUT A TCODE ZFIT_FB01
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM f_bi_zfip_fb01 .

  DATA: i_messtab    TYPE STANDARD TABLE OF bdcmsgcoll,
        lwa_colores  TYPE slis_specialcol_alv,
        li_pos_aux   TYPE tt_pos_bi,
        lv_index     TYPE sy-tabix,
        lv_dmbtr(20) TYPE c.

  FIELD-SYMBOLS: <lfs_cab_bi>    LIKE LINE OF i_cab_bi,
                 <lfs_pos_first> LIKE LINE OF i_pos_bi,
                 <lfs_pos_curr>  LIKE LINE OF i_pos_bi,
                 <lfs_pos_next>  LIKE LINE OF i_pos_bi,
                 <lfs_messtab>   TYPE bdcmsgcoll.

  "Recorrer las cabeceras
  LOOP AT i_cab_bi ASSIGNING <lfs_cab_bi>.

    REFRESH: i_bdcdata, i_messtab, li_pos_aux.
    CLEAR: wa_alv, wa_alv-gt_colores.


    "Crear tabla auxiliar de posiciones
    li_pos_aux[] = i_pos_bi[].

    "Borrar los registros que no correspondan a la cabecera actual
    DELETE li_pos_aux WHERE belnr_ext NE <lfs_cab_bi>-belnr_ext.


    "Cabecera
    PERFORM bdc_dynpro USING 'ZFIP_FB01' '0100'.
    PERFORM bdc_field  USING 'BDC_OKCODE' '=GO'.

    PERFORM bdc_field USING 'ZBKPF-BLDAT' <lfs_cab_bi>-bldat.
    PERFORM bdc_field USING 'ZBKPF-BKTXT' <lfs_cab_bi>-bktxt.
    PERFORM bdc_field USING 'ZBKPF-MONAT' <lfs_cab_bi>-monat.
    PERFORM bdc_field USING 'ZBKPF-BUKRS' <lfs_cab_bi>-bukrs.
    PERFORM bdc_field USING 'ZBKPF-WAERS' <lfs_cab_bi>-waers.
    PERFORM bdc_field USING 'ZBKPF-BLART' <lfs_cab_bi>-blart.
    PERFORM bdc_field USING 'ZBKPF-XBLNR' <lfs_cab_bi>-xblnr.

    "Signo y cuenta de la primera posición
    READ TABLE li_pos_aux INDEX 1 ASSIGNING <lfs_pos_first>.
    IF sy-subrc EQ 0.
      PERFORM bdc_field USING 'ZBSEG-SHKZG' <lfs_pos_first>-shkzg.
      PERFORM bdc_field USING 'ZBSEG-HKONT' <lfs_pos_first>-skonto.
    ENDIF.


    "Posiciones
    LOOP AT li_pos_aux ASSIGNING <lfs_pos_curr>.

      lv_index = sy-tabix.

      PERFORM bdc_dynpro USING 'ZFIP_FB01' '0200'.

      WRITE <lfs_pos_curr>-dmbtr CURRENCY <lfs_cab_bi>-waers TO lv_dmbtr.
      CONDENSE lv_dmbtr.

      PERFORM bdc_field USING 'ZBSEG-DMBTR' lv_dmbtr.
      PERFORM bdc_field USING 'ZBSEG-SGTXT' <lfs_pos_curr>-sgtxt.

      IF <lfs_cab_bi>-blart = 'KR' OR <lfs_cab_bi>-blart = 'KZ'.
        PERFORM bdc_field USING 'ZBSEG-ZFBDT' <lfs_pos_curr>-zfbdt.
        PERFORM bdc_field USING 'ZT003-ZUSCH' <lfs_pos_curr>-zusch.
      ENDIF.

      lv_index = lv_index + 1.

      READ TABLE li_pos_aux INDEX lv_index ASSIGNING <lfs_pos_next>.

      IF sy-subrc EQ 0.

        PERFORM bdc_field USING 'ZBSEG-SHKZG' <lfs_pos_next>-shkzg.
        PERFORM bdc_field USING 'ZBSEG-HKONT' <lfs_pos_next>-skonto.

        PERFORM bdc_field USING 'BDC_OKCODE' '=COMP'.

      ELSE.
        PERFORM bdc_field USING 'BDC_OKCODE' '=POST'.
      ENDIF.

    ENDLOOP. "LOOP AT li_pos_aux ASSIGNING <lfs_pos_curr>

*********************************************
    "Pantalla final (resumen)
    PERFORM bdc_dynpro USING 'ZFIP_FB01' '0300'.
    PERFORM bdc_field  USING 'BDC_OKCODE' '=SAVE'.


    CALL TRANSACTION 'ZFIT_FB01' USING i_bdcdata
                                 MODE  p_modo     "modo invisible
                                 UPDATE 'S'       "actualización sincrónica
                                 MESSAGES INTO i_messtab.


    "Buscar mensaje de éxito
    READ TABLE i_messtab ASSIGNING <lfs_messtab> WITH KEY msgid  = 'ZFIP_FB01_MSG'
                                                          msgnr  = '004'
                                                          msgtyp = 'I'.
    IF sy-subrc EQ 0.

      "Completar la estructura del ALV
      wa_alv-belnr    = <lfs_messtab>-msgv1. "N° de doc
      wa_alv-mensaje  = text-023. "Documento creado exitosamente!
      wa_alv-semaforo = '@08@'.  "Luz verde

      "Configuración del color de celda
      CLEAR lwa_colores.
      lwa_colores-fieldname = 'MENSAJE'.  "Campo verde
      lwa_colores-color-col = 5.
      lwa_colores-color-int = 1.
      APPEND lwa_colores TO wa_alv-gt_colores.

    ELSE.

      "Buscar primer mensaje de error tipo E o tipo A
      READ TABLE i_messtab ASSIGNING <lfs_messtab> WITH KEY msgtyp = 'E'.

      IF sy-subrc NE 0.
        READ TABLE i_messtab ASSIGNING <lfs_messtab> WITH KEY msgtyp = 'A'.
      ENDIF.

      IF sy-subrc EQ 0.

        "Guardar mensaje en el ALV
        MESSAGE ID <lfs_messtab>-msgid
                TYPE <lfs_messtab>-msgtyp
                NUMBER <lfs_messtab>-msgnr
                WITH <lfs_messtab>-msgv1
                     <lfs_messtab>-msgv2
                     <lfs_messtab>-msgv3
                     <lfs_messtab>-msgv4
                INTO wa_alv-mensaje.

      ENDIF.

      "Asignar color de semáforo
      wa_alv-semaforo = '@0A@'.  "Luz roja

      "Configuración de color de celda
      CLEAR lwa_colores.
      lwa_colores-fieldname = 'MENSAJE'.  "Campo rojo
      lwa_colores-color-col = 6.
      lwa_colores-color-int = 1.
      APPEND lwa_colores TO wa_alv-gt_colores.

    ENDIF. "READ TABLE i_messtab ASSIGNING <lfs_messtab>

    "Completar el registro del ALV
    wa_alv-nombre_arch = <lfs_cab_bi>-nombre_arch.
    wa_alv-belnr_ext   = <lfs_cab_bi>-belnr_ext.
    wa_alv-linea_cab   = <lfs_cab_bi>-linea.
    wa_alv-bukrs       = <lfs_cab_bi>-bukrs.
    wa_alv-gjhar       = <lfs_cab_bi>-gjhar.
    wa_alv-blart       = <lfs_cab_bi>-blart.

    "Guardar en tabla del ALV
    APPEND wa_alv TO i_alv.

  ENDLOOP. "LOOP AT i_cab_bi ASSIGNING <lfs_cab_bi>

ENDFORM.                    " F_BI_ZFIP_FB01
*&---------------------------------------------------------------------*
*&      Form  BDC_DYNPRO
*&---------------------------------------------------------------------*
*     DEFINICIÓN DEL INICIO DE UNA NUEVA PANTALLA
*----------------------------------------------------------------------*
*      -->p_program   Nombre del programa    (1662)
*      -->p_dynpro    Número de screen       (1663)
*----------------------------------------------------------------------*
FORM bdc_dynpro  USING     p_program                        "ZFIP_FB01
                           p_dynpro.                        "0100

  CLEAR wa_bdcdata.
  wa_bdcdata-program  = p_program.
  wa_bdcdata-dynpro   = p_dynpro.
  wa_bdcdata-dynbegin = 'X'.
  APPEND wa_bdcdata TO i_bdcdata.

ENDFORM.                    " BDC_DYNPRO
*&---------------------------------------------------------------------*
*&      Form  BDC_FIELD
*&---------------------------------------------------------------------*
*   ASIGNACIÓN DE VALORES A LOS CAMPOS EN LA PANTALLA ACTIVA
*----------------------------------------------------------------------*
*      -->p_field   Fieldname 'BDC_OKCODE'
*      -->p_value   Acción 'GO' / 'POST' / etc.
*----------------------------------------------------------------------*
FORM bdc_field  USING    p_field
                         p_value.

  CLEAR wa_bdcdata.
  wa_bdcdata-fnam = p_field.
  wa_bdcdata-fval = p_value.
  APPEND wa_bdcdata TO i_bdcdata.

ENDFORM.                    " BDC_FIELD
*&---------------------------------------------------------------------*
*&      Form  F_CONFIG_ALV
*&---------------------------------------------------------------------*
*    CONSTRUCCIÓN DEL REPORTE ALV FINAL
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM f_config_alv .

  DATA: lt_fieldcat TYPE slis_t_fieldcat_alv,
        lt_sort     TYPE slis_t_sortinfo_alv,
        lwa_layout  TYPE slis_layout_alv.

  "Opciones de visualización
  lwa_layout-zebra             = abap_true.
  lwa_layout-colwidth_optimize = abap_true.
  lwa_layout-coltab_fieldname  = 'GT_COLORES'.

  "Catálogo de campos del ALV
  PERFORM f_build_fieldcat CHANGING lt_fieldcat.

  "Criterios de ordenamiento de salida del ALV
  PERFORM f_build_sort CHANGING lt_sort.

  "Salida del ALV
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program      = sy-repid
      i_callback_user_command = 'USER_COMMAND'
      is_layout               = lwa_layout
      it_fieldcat             = lt_fieldcat
    TABLES
      t_outtab                = i_alv
    EXCEPTIONS
      program_error           = 1
      OTHERS                  = 2.

  IF sy-subrc NE 0.
    MESSAGE: e004(zfb01_bi). "Error al generar el ALV
  ENDIF.

ENDFORM.                    " F_CONFIG_ALV
*&---------------------------------------------------------------------*
*&      Form  F_BUILD_FIELDCAT
*&---------------------------------------------------------------------*
*    CONSTRUCCIÓN DEL CATÁLOGO DE CAMPOS
*----------------------------------------------------------------------*
*      <--P_LT_FIELDCAT  Tabla interna para catálogo de campos
*----------------------------------------------------------------------*
FORM f_build_fieldcat  CHANGING p_lt_fieldcat TYPE slis_t_fieldcat_alv.


  DATA lwa_fieldcat TYPE slis_fieldcat_alv.

  lwa_fieldcat-fieldname = 'NOMBRE_ARCH'.
  lwa_fieldcat-tabname   = 'I_ALV'.
  lwa_fieldcat-seltext_m = text-025. "Archivo
  APPEND lwa_fieldcat TO p_lt_fieldcat.

  CLEAR lwa_fieldcat.
  lwa_fieldcat-fieldname = 'BELNR_EXT'.
  lwa_fieldcat-tabname   = 'I_ALV'.
  lwa_fieldcat-seltext_m = text-026. "N° Doc. Externo
  APPEND lwa_fieldcat TO p_lt_fieldcat.

  CLEAR lwa_fieldcat.
  lwa_fieldcat-fieldname = 'LINEA_CAB'.
  lwa_fieldcat-tabname   = 'I_ALV'.
  lwa_fieldcat-seltext_m = text-027. "Cabecera línea
  APPEND lwa_fieldcat TO p_lt_fieldcat.

  CLEAR lwa_fieldcat.
  lwa_fieldcat-fieldname = 'BUKRS'.
  lwa_fieldcat-tabname   = 'I_ALV'.
  lwa_fieldcat-seltext_m = text-028. "Sociedad
  APPEND lwa_fieldcat TO p_lt_fieldcat.

  CLEAR lwa_fieldcat.
  lwa_fieldcat-fieldname = 'GJHAR'.
  lwa_fieldcat-tabname   = 'I_ALV'.
  lwa_fieldcat-seltext_m = text-029. "Año Fiscal
  APPEND lwa_fieldcat TO p_lt_fieldcat.

  CLEAR lwa_fieldcat.
  lwa_fieldcat-fieldname = 'BLART'.
  lwa_fieldcat-tabname   = 'I_ALV'.
  lwa_fieldcat-seltext_m = text-030. "Tipo Doc.
  APPEND lwa_fieldcat TO p_lt_fieldcat.

  CLEAR lwa_fieldcat.
  lwa_fieldcat-fieldname = 'SEMAFORO'.
  lwa_fieldcat-tabname   = 'I_ALV'.
  lwa_fieldcat-seltext_m = text-031. "Status
  lwa_fieldcat-just      = 'C'.
  APPEND lwa_fieldcat TO p_lt_fieldcat.

  CLEAR lwa_fieldcat.
  lwa_fieldcat-fieldname = 'BELNR'.
  lwa_fieldcat-tabname   = 'I_ALV'.
  lwa_fieldcat-seltext_m = text-032. "N° doc. SAP
  lwa_fieldcat-hotspot   = 'X'.
  APPEND lwa_fieldcat TO p_lt_fieldcat.

  CLEAR lwa_fieldcat.
  lwa_fieldcat-fieldname = 'MENSAJE'.
  lwa_fieldcat-tabname   = 'I_ALV'.
  lwa_fieldcat-seltext_m = text-033. "Mensaje
  APPEND lwa_fieldcat TO p_lt_fieldcat.

ENDFORM.                    " F_BUILD_FIELDCAT
*&---------------------------------------------------------------------*
*&      Form  F_SAVE_PROCESSED_FILE
*&---------------------------------------------------------------------*
* ASENTAR LOS NOMBRES DE LOS ARCHIVOS PROCESADOS EN TABLA ZFB01_FILE_PROC
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM f_save_processed_file .

  DATA: lwa_file_proc TYPE zfb01_file_proc,
        lv_error      TYPE string.

  CLEAR lwa_file_proc.

  "Completar el registro
  lwa_file_proc-zfilename = v_file_name. "Nombre del archivo
  lwa_file_proc-erdat     = sy-datum.    "Fecha
  lwa_file_proc-erzet     = sy-uzeit.    "Hora

  "Nombre del usuario
  IF sy-batch = 'X'.
    lwa_file_proc-ernam = 'USER_BATCH'.
  ELSE.
    lwa_file_proc-ernam = sy-uname.
  ENDIF.

  "Agregar el registro a la tabla de procesados
  INSERT zfb01_file_proc FROM lwa_file_proc.

  IF sy-subrc NE 0.
    CONCATENATE text-035 v_file_name INTO lv_error SEPARATED BY space.
    "Error al agregar a la tabla de procesados el archivo &

    PERFORM f_append_error_alv USING v_file_name
                                     space
                                     0
                                     lv_error.
  ENDIF.

ENDFORM.                    " F_SAVE_PROCESSED_FILE
*&---------------------------------------------------------------------*
*&      Form  user_command
*&---------------------------------------------------------------------*
*   EJECUTAR ZFIR_BUSCAR_DOC AL HACER DOBLE CLICK EN BELNR
*----------------------------------------------------------------------*
*      -->R_UCOMM      text
*      -->RS_SELFIELD  text
*----------------------------------------------------------------------*
FORM user_command USING r_ucomm LIKE sy-ucomm
                        rs_selfield TYPE slis_selfield.

  FIELD-SYMBOLS <lfs_alv> LIKE LINE OF i_alv.

  CASE r_ucomm.
    WHEN '&IC1'.  "Doble click

      IF rs_selfield-fieldname = 'BELNR'. "En el campo Núm de doc SAP

        READ TABLE i_alv INDEX rs_selfield-tabindex ASSIGNING <lfs_alv>.

        IF sy-subrc EQ 0.

          "Ejecutar del reporte con filtros aplicados
          SUBMIT zfir_buscar_doc
            WITH s_bukrs EQ <lfs_alv>-bukrs
            WITH s_gjhar EQ <lfs_alv>-gjhar
            WITH s_belnr EQ <lfs_alv>-belnr
            AND RETURN.

        ENDIF. "READ TABLE i_alv INDEX rs_selfield-tabindex
      ENDIF. "rs_selfield-fieldname = 'BELNR'
  ENDCASE.

ENDFORM.                    "user_command
*&---------------------------------------------------------------------*
*&      Form  F_CHECK_PARAMETERS
*&---------------------------------------------------------------------*
*   VALIDAR INGRESO DE RUTAS EN LA PANTALLA DE SELECCIÓN
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM f_check_parameters .

  "Al ejecutar
  IF sy-ucomm NE 'ONLI'.
    RETURN.
  ENDIF.

  "Verificar que se hayan ingresado las rutas
  IF rb_loc IS NOT INITIAL.

    IF p_path1 IS INITIAL.
      "Complete ruta de archivo
      MESSAGE e000(zfb01_bi).
    ENDIF.

    IF p_pathd1 IS INITIAL.
      "Complete ruta de destino
      MESSAGE e005(zfb01_bi).
    ENDIF.

  ELSEIF rb_al11 IS NOT INITIAL.

    IF p_path2 IS INITIAL.
      MESSAGE e000(zfb01_bi).
    ENDIF.

    IF p_pathd2 IS INITIAL.
      MESSAGE e005(zfb01_bi).
    ENDIF.

    IF p_log IS INITIAL.
      "Complete ruta para Log de errores
      MESSAGE e006(zfb01_bi).
    ENDIF.

  ENDIF. "IF rb_loc IS NOT INITIAL.

ENDFORM.                    " F_CHECK_PARAMETERS
*&---------------------------------------------------------------------*
*&      Form  F_CREATE_ERROR_LOG
*&---------------------------------------------------------------------*
*    GENERAR LOG DE ERRORES DEL PROCESAMIENTO EN AL11
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM f_create_error_log .

  DATA: lv_file    TYPE string,
        lv_line    TYPE string,
        li_alv_aux TYPE tt_tabla_alv.

  FIELD-SYMBOLS <lfs_alv_aux> LIKE LINE OF i_alv.

  "Crear una tabla aux
  li_alv_aux[] = i_alv[].

  "Borrar los registros exitosos
  DELETE li_alv_aux WHERE semaforo <> '@0A@'. "Rojo

  IF li_alv_aux IS NOT INITIAL.
    "Ordenar tabla
    SORT li_alv_aux BY nombre_arch.

    "Recorrer los registros
    LOOP AT li_alv_aux ASSIGNING <lfs_alv_aux>.

      "Por cada nombre de archivo
      AT NEW nombre_arch.

        "Construir ruta
        CONCATENATE p_log
                    '/ERRORES_'
                    <lfs_alv_aux>-nombre_arch
               INTO lv_file. "Ruta Log + /ERRORES + nombre del archivo.txt

        "Abrir ruta construida para escritura
        OPEN DATASET lv_file
          FOR OUTPUT
          IN TEXT MODE
          ENCODING DEFAULT.

      ENDAT.

      "Construcción de la línea del log
      CONCATENATE <lfs_alv_aux>-nombre_arch
                  <lfs_alv_aux>-belnr_ext
                  <lfs_alv_aux>-linea_cab
                  <lfs_alv_aux>-bukrs
                  <lfs_alv_aux>-gjhar
                  <lfs_alv_aux>-blart
                  <lfs_alv_aux>-mensaje
             INTO lv_line
             SEPARATED BY ';'.

      "Guardar en ruta
      TRANSFER lv_line TO lv_file.

      "Cerrar ruta al cambiar el nombre del archivo
      AT END OF nombre_arch.
        CLOSE DATASET lv_file.
      ENDAT.

    ENDLOOP. "LOOP AT i_alv ASSIGNING <lfs_alv_aux>.
  ENDIF. "IF li_alv_aux IS NOT INITIAL.

ENDFORM.                    " F_CREATE_ERROR_LOG
*&---------------------------------------------------------------------*
*&      Form  F_BUILD_SORT
*&---------------------------------------------------------------------*
*    CRITERIOS DE ORDENAMIENTO DE SALIDA DEL ALV
*----------------------------------------------------------------------*
*      <--P_LT_SORT  Tabla con los criterios de ordenamiento
*----------------------------------------------------------------------*
FORM f_build_sort  CHANGING p_lt_sort TYPE slis_t_sortinfo_alv.

  DATA lwa_sort TYPE slis_sortinfo_alv.

  CLEAR lwa_sort.
  lwa_sort-fieldname = 'NOMBRE_ARCH'. "Nombre del Archivo
  lwa_sort-up        = abap_true. "Ascendente
  lwa_sort-spos      = 1.
  APPEND lwa_sort TO p_lt_sort.

  CLEAR lwa_sort.
  lwa_sort-fieldname = 'LINEA_CAB'.   "Línea de cabecera
  lwa_sort-up        = abap_true. "Ascendente
  lwa_sort-spos      = 2.
  APPEND lwa_sort TO p_lt_sort.

ENDFORM.                    " F_BUILD_SORT
