*&---------------------------------------------------------------------*
*&  Include           ZFIP_FB01_AUTOM_TOP
*&---------------------------------------------------------------------*

*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
*ESTRUCTURAS Y TIPOS
*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
TYPES:
BEGIN OF ty_cab,     "Estructura para los datos de cabeceras leídos del archivo
         tipo_linea(1)   TYPE c,         "Cabecera
         belnr_ext(8)    TYPE c,         "Número de documento externo
         bldat(10)       TYPE c,         "Fecha del documento
         bukrs_ext(5)    TYPE c,         "Código de sociedad externo
         waers(3)        TYPE c,         "Moneda
         blart_ext(3)    TYPE c,         "Tipo de Documento externo
         xblnr(16)       TYPE c,         "Referencia
         nombre_arch(50) TYPE c,         "Nombre del archivo
         linea           TYPE sy-tabix,  "Número de línea del archivo
END OF ty_cab,

tt_cab TYPE STANDARD TABLE OF ty_cab,

BEGIN OF ty_pos,     "Estructura para los datos de posiciones leídos del archivo
         tipo_linea(1)   TYPE c,         "Posición
         belnr_ext(8)    TYPE c,         "Número de documento Externo
         dmbtr(16)       TYPE c,         "Monto
         zfbdt(10)       TYPE c,         "Fecha de vencimiento
         zusch_ext(2)    TYPE c,         "Indicador de impuesto externo
         skonto_ext(10)  TYPE c,         "Número de cuenta externo
         nombre_arch(50) TYPE c,         "Nombre del archivo
         linea           TYPE sy-tabix,  "Número de línea del archivo
END OF ty_pos,

tt_pos TYPE STANDARD TABLE OF ty_pos,

BEGIN OF ty_soc_ext, "Estructura para los datos de las sociedades externas
         bukrs_ext(5) TYPE c,            "Código de sociedad externo
         bukrs        TYPE zbkpf-bukrs,  "Código de sociedad SAP
END OF ty_soc_ext,

  tt_soc_ext TYPE STANDARD TABLE OF ty_soc_ext,

BEGIN OF ty_soc_int,  "Estructura para los datos de las sociedades SAP
         bukrs TYPE zbkpf-bukrs,  "Código de sociedad SAP
END OF ty_soc_int,

tt_soc_int TYPE STANDARD TABLE OF ty_soc_int,

BEGIN OF ty_ctas_ext, "Estructura para los datos de las cuentas externas
         skonto_ext(10) TYPE c,            "Número de cuenta externo
         skonto         TYPE zbseg-hkont,  "Número de cuenta SAP
         bukrs_ext(5)   TYPE c,            "Código sociedad externo
         bukrs          TYPE zbkpf-bukrs,  "Código sociedad SAP
END OF ty_ctas_ext,

tt_ctas_ext TYPE STANDARD TABLE OF ty_ctas_ext,

BEGIN OF ty_ctas_int,  "Estructura para los datos de las cuentas SAP
         skonto TYPE zbseg-hkont,  "Número de cuenta SAP
         bukrs  TYPE zbkpf-bukrs,  "Código de sociedad SAP
END OF ty_ctas_int,

tt_ctas_int TYPE STANDARD TABLE OF ty_ctas_int,

BEGIN OF ty_zparam_aux, "Estructura para los datos de parametrización
         bukrs         TYPE zparam-bukrs,         "Código de sociedad SAP
         param         TYPE zparam-param,         "Parámetro
         valor_entrada TYPE zparam-valor_entrada, "Valor de entrada
         valor_salida  TYPE zparam-valor_salida,  "Valor de salida
END OF ty_zparam_aux,

tt_zparam_aux TYPE STANDARD TABLE OF ty_zparam_aux,

BEGIN OF ty_cab_bi,     "Estructura para los datos de cabeceras listos para el BI
         tipo_linea(1)   TYPE c,            "Cabecera
         belnr_ext(8)    TYPE c,            "Número de documento externo
         bldat(10)       TYPE c,            "Fecha del documento
         gjhar           TYPE zbkpf-gjhar,  "Año Fiscal
         bktxt           TYPE zbkpf-bktxt,  "Texto cabecera
         monat           TYPE zbkpf-monat,  "Período
         bukrs           TYPE zbkpf-bukrs,  "Código sociedad
         waers           TYPE zbkpf-waers,  "Moneda
         blart           TYPE zbkpf-blart,  "Tipo de Documento
         xblnr           TYPE zbkpf-xblnr,  "Referencia
         nombre_arch(50) TYPE c,            "Nombre del archivo
         linea           TYPE sy-tabix,     "Número de línea del archivo
END OF ty_cab_bi,

tt_cab_bi TYPE STANDARD TABLE OF ty_cab_bi,

BEGIN OF ty_pos_bi,     "Estructura para los datos de posiciones listos para el BI
         tipo_linea(1)   TYPE c,            "Posición
         belnr_ext(8)    TYPE c,            "Número de documento externo
         shkzg           TYPE zbseg-shkzg,  "Signo posición
         skonto          TYPE zbseg-hkont,  "Número de cuenta
         dmbtr           TYPE zbseg-dmbtr,  "Monto
         sgtxt           TYPE zbseg-sgtxt,  "Texo posición
         zfbdt           TYPE zbseg-zfbdt,  "Fecha de vencimiento
         zusch           TYPE zbseg-zusch,  "Indicador de impuesto
         nombre_arch(50) TYPE c,            "Nombre del archivo
         linea           TYPE sy-tabix,     "Número de linea del archivo
END OF ty_pos_bi,

tt_pos_bi TYPE STANDARD TABLE OF ty_pos_bi,

BEGIN OF ty_tabla_alv,      "Estructura de la tabla final para el ALV
       nombre_arch(50) TYPE c,           "Nombre del archivo
       belnr_ext(8)    TYPE c,           "Número de Documento Externo
       linea_cab(2)    TYPE c,           "Número de línea de cabecera
       bukrs           TYPE zbkpf-bukrs, "Sociedad SAP
       gjhar           TYPE zbkpf-gjhar, "Año Fiscal
       blart           TYPE zbkpf-blart, "Tipo de documento SAP
       semaforo(4)     TYPE c,           "Verde o Rojo según Exito o Error
       belnr(10)       TYPE c,           "Número de Documento SAP creado
       mensaje         TYPE string,      "Descripción del resultado
       gt_colores      TYPE slis_t_specialcol_alv, "Tabla interna de colores del ALV
END OF ty_tabla_alv,

tt_tabla_alv TYPE STANDARD TABLE OF ty_tabla_alv.

*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
*DECLARACIONES
*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
DATA: i_cab    TYPE tt_cab,
      i_pos    TYPE tt_pos,
      i_cab_bi TYPE tt_cab_bi,
      i_pos_bi TYPE tt_pos_bi.

DATA: i_bdcdata  TYPE STANDARD TABLE OF bdcdata,
      wa_bdcdata TYPE bdcdata.

DATA: i_alv  TYPE tt_tabla_alv,
      wa_alv TYPE ty_tabla_alv.

DATA v_file_name TYPE char255.

*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
*CONSTANTES
*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
CONSTANTS: c_pyc(1)    TYPE c VALUE ';',
           c_tipo_c(1) TYPE c VALUE 'C',
           c_tipo_p(1) TYPE c VALUE 'P'.


*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
*PANTALLA DE SELECCIÓN
*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
SELECTION-SCREEN BEGIN OF BLOCK a1 WITH FRAME TITLE text-001.
PARAMETERS: rb_loc  RADIOBUTTON GROUP a1 DEFAULT 'X' USER-COMMAND chc,  "Archivo del sistema local
            rb_al11 RADIOBUTTON GROUP a1,                               "Archivo del servidor
            p_path1  TYPE string LOWER CASE MODIF ID z01,               "Ruta de origen del archivo
            p_pathd1 TYPE string LOWER CASE MODIF ID z01,               "Ruta de destino del archivo
            p_path2  TYPE string LOWER CASE MODIF ID z02,               "Ruta de archivos a procesar
            p_pathd2 TYPE string LOWER CASE MODIF ID z02,               "Ruta de archivos procesados
            p_log    TYPE string LOWER CASE MODIF ID z02.               "Ruta log
SELECTION-SCREEN END OF BLOCK a1.

SELECTION-SCREEN SKIP 1.
PARAMETERS: p_modo(1) TYPE c OBLIGATORY DEFAULT 'N'.                    "Modo de ejecución del Batch Input