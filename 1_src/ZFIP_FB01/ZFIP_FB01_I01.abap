*&---------------------------------------------------------------------*
*&  Include           ZFIP_FB01_I01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*    MANEJO DE ACCIONES DEL USUARIO EN LA PANTALLA INICIAL
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.

  CASE okcode.

      "Si se presiona BACK (verde)
    WHEN 'BACK'.
      CLEAR: wa_zbkpf, wa_zbseg, okcode.
      REFRESH i_zbseg.
      "Salida del programa
      LEAVE PROGRAM.
*---------------------------------------------------------------------------------
      "Si se presiona AVANZAR
    WHEN 'GO'.
      CLEAR okcode.
      "Validación de datos ingresados
      PERFORM f_validaciones_campos_0100.

      "Tratamiento especial para documentos de tipo KZ
      IF wa_zbkpf-blart = 'KZ'.
        PERFORM f_concatenar_pagado_0100.
      ENDIF.
      "Avanzar a la siguiente pantalla
      CALL SCREEN 0200.
*---------------------------------------------------------------------------------
    WHEN OTHERS.

  ENDCASE.

ENDMODULE.                 " USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0200  INPUT
*&---------------------------------------------------------------------*
*  MANEJO DE ACCIONES DEL USUARIO EN LA PANTALLA DE CARGA DE POSICIONES                                                                                                                        MANEJO DE ACCIONES DEL USUARIO EN LA PANTALLA DE CARGA DE
*----------------------------------------------------------------------*
MODULE user_command_0200 INPUT.

  CASE okcode.

      "Si se presiona BACK (verde)
    WHEN 'BACK'.
      "Si es la primera posición: regresar a la pantalla inicial
      IF  v_posicion = 10.
        CLEAR: okcode, wa_zbkpf, wa_zbseg, v_flag_retencion.
        REFRESH i_zbseg.
        CALL SCREEN 0100.
        "Si no es la primera posición: retroceder una
      ELSE.
        CLEAR: okcode, v_flag_retencion.
        v_flag_back_0200 = 'X'.
        CALL SCREEN 0200.
      ENDIF.
*---------------------------------------------------------------------------------
      "Si se presiona EXIT: Salir del programa
    WHEN 'EXIT'.
      CLEAR: okcode, wa_zbkpf, wa_zbseg.
      REFRESH i_zbseg.
      LEAVE PROGRAM.
*---------------------------------------------------------------------------------
      "Si se presiona COMP
    WHEN 'COMP'.
      CLEAR okcode.

      "Calcular monto local
      PERFORM f_calculo_dinamico_monto_local.
      "Validación de datos
      PERFORM f_validaciones_campos_0200.
      PERFORM f_validaciones_signo_cuenta.

      "Limpieza de la estructura para cargar una nueva posición
      CLEAR: wa_zbseg-posnr,
             wa_zbseg-waers,
             wa_zbseg-dmbtr,
             wa_zbseg-wrbtr,
             wa_zbseg-zfbdt,
             wa_zbseg-sgtxt,
             wa_zbseg-zusch.

      "Sumar una posición
      v_posicion = v_posicion + 10.

      "Guardar el nuevo valor de SIGNO y CUENTA
      wa_zbseg-shkzg  = zbseg-shkzg.
      wa_zbseg-hkont  = zbseg-hkont.

      "Volver a llamar esta misma screen
      CLEAR zbseg.
      SET SCREEN 0200.
*---------------------------------------------------------------------------------
      "Si se presiona POSTEAR
    WHEN 'POST'.
      CLEAR: okcode, v_retencion_revertida.

      "Validación de datos
      PERFORM f_calculo_dinamico_monto_local.
      PERFORM f_validaciones_campos_0200.

      "Para los doc KZ que no se le aplicó la ret de imp
      IF wa_zbkpf-blart = 'KZ' AND v_flag_retencion IS INITIAL.
        v_flag_retencion = 'X'.
        "Aplicación de ret de imp
        PERFORM f_retencion_imp_0200.
      ENDIF.

      "Llamar a la siguiente screen
      v_posicion = 10.
      CALL SCREEN 0300.
*---------------------------------------------------------------------------------
      "Si se presiona ENTER
    WHEN space.
      CLEAR okcode.
      v_flag_enter_0200 = 'X'.
      "Calcular el monto local
      PERFORM f_calculo_dinamico_monto_local.
*---------------------------------------------------------------------------------
    WHEN OTHERS.
  ENDCASE.

ENDMODULE.                 " USER_COMMAND_0200  INPUT
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0300  INPUT
*&---------------------------------------------------------------------*
*   MANEJO DE ACCIONES DEL USUARIO EN LA PANTALLA FINAL
*----------------------------------------------------------------------*
MODULE user_command_0300 INPUT.

  CASE okcode.

      "Si se presiona BACK (verde)
    WHEN 'BACK'.
      "Retornar a la pantalla de posiciones
      CLEAR: okcode, v_flag_retencion.
      v_flag_back_0300 = 'X'.
      SET SCREEN 0200.
*---------------------------------------------------------------------------
      "Si se presiona EXIT
    WHEN 'EXIT'.
      "Salir del programa
      CLEAR: wa_zbkpf, wa_zbseg, okcode.
      REFRESH i_zbseg.
      LEAVE PROGRAM.
*---------------------------------------------------------------------------
      "Si se presiona ANTERIOR
    WHEN 'ANT'.
      "Mostrar los datos de la posición anterior a la actual
      IF v_posicion GT 10.
        v_posicion = v_posicion - 10.
        "Si ya no hay más posiciones
      ELSE.
        MESSAGE w036(zfip_fb01_msg). "No hay posiciones anteriores para mostrar
      ENDIF.
      CLEAR okcode.
      SET SCREEN 0300.
*---------------------------------------------------------------------------
      "Si se presiona SIGUIENTE
    WHEN 'SIG'.
      "Mostrar los datos de la posición siguiente
      v_posicion = v_posicion + 10.
      CLEAR okcode.
      SET SCREEN 0300.
*---------------------------------------------------------------------------
      "Si se presiona GUARDAR
    WHEN 'SAVE'.
      "Validación final y regreso a la pantalla inicial
      CLEAR okcode.
      PERFORM f_validaciones_0300.
      SET SCREEN 0100.
*---------------------------------------------------------------------------
    WHEN OTHERS.
  ENDCASE.
ENDMODULE.                 " USER_COMMAND_0300  INPUT