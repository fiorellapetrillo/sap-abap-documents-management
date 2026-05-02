*&---------------------------------------------------------------------*
*& Report  ZFIP_FB01_AUTOM
*&
*&---------------------------------------------------------------------*
* DR No.    :       CRQ0003                                            *
* Program   :       ZFIP_FB01_AUTOM                                    *
* Title     :       Carga masiva de ZFIP_FB01                          *
* Type      :       Executable Program                                 *
* Created by:       Fiorella Petrillo                                  *
* Transport Number: Local Object                                       *
* Description:      Carga automática de datos en transacción ZFIT_FB01 *
************************************************************************
*----------------------------------------------------------------------*
* MODIFICATION LOGS                                                    *
*----------------------------------------------------------------------*
* Date     Modified by  Description  Transport Request  Change request *
* ====    ===========  ===========   ================  ================*
*----------------------------------------------------------------------*

REPORT  zfip_fb01_autom.

*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
*INCLUDES
*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
INCLUDE zfip_fb01_autom_top.
INCLUDE zfip_fb01_autom_f01.

*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
*INITIALIZATION
*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
INITIALIZATION.
  "Limpieza de variables y tablas globales
  PERFORM f_clear.

*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
*AT SELECTION-SCREEN
*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_path1.
  "Config de la ayuda de búsqueda en el parámetro 'Ruta origen'
  PERFORM f_f4_help USING 'L' CHANGING p_path1.


AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_path2.
  "Config de la ayuda de búsqueda en el parámetro 'Ruta de archivos a procesar'
  PERFORM f_f4_help USING 'S' CHANGING p_path2.

AT SELECTION-SCREEN.
  "Chequear ingreso de información en parámetros
  PERFORM f_check_parameters.

AT SELECTION-SCREEN OUTPUT.
  "Criterios de visualización de campos de la pantalla de selección
  PERFORM f_hide_screen_fields.

*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
*START-OF-SELECTION
*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
START-OF-SELECTION.
  "Leer información del archivo en tablas internas
  PERFORM f_upload.

  "Validación de la información recopilada
  IF i_cab IS NOT INITIAL AND i_pos IS NOT INITIAL.
    PERFORM f_process_data.
  ENDIF.

  "Batch input tcode ZFIT_FB01
  IF i_cab_bi IS NOT INITIAL AND i_pos_bi IS NOT INITIAL.
    PERFORM f_bi_zfip_fb01.
  ENDIF.

  IF i_alv IS  NOT INITIAL.
    "Creación del log de errores para archivos del servidor
    IF rb_al11 IS NOT INITIAL.
      PERFORM f_create_error_log.
    ENDIF.

    "Salida de ALV
    PERFORM f_config_alv.
  ENDIF.