# SAP ABAP FI Document Management

## Description
End-to-end ABAP solution simulating a financial document management process in SAP NetWeaver 7.02. The project covers creation, persistence, consultation, printing, and mass automation of accounting documents, integrating multiple ABAP components into a single functional flow.

## Architecture Overview

The system is designed as a complete document lifecycle:

- Data Entry (Module Pool)
- Data Persistence (Custom FI-like tables)
- Data Consultation (ALV Report)
- Document Output (SmartForms)
- Mass Processing (Batch Input Automation)

## Project Components

- **ZFIP_FB01 (Module Pool)**  
  Transaction for manual creation of financial documents using Dynpro screens (PBO/PAI). Includes validations, business logic, and persistence into custom FI-like tables.

  Path:
  `/1_src/ZFIP_FB01`
  `/2_docs/ZFIP_FB01`

- **ZFIR_BUSCAR_DOC (ALV Report)**  
  Report with selection screen and ALV output for querying stored documents. Includes data consolidation from header and item tables and triggers SmartForms for printing.

  Path:
  `/1_src/ZFIR_BUSCAR_DOC`
  `/2_docs/ZFIR_BUSCAR_DOC`

- **SmartForms**  
  Forms for printing documents from the ALV.
  
  Path:  
  `/2_docs/ZFISF_DOC_KR`
  `/2_docs/ZFISF_DOC_KZ`  
  `/2_docs/ZFISF_DOC_SA`

- **ZFIP_FB01_AUTOM (Batch Input)**  
  Automation program that simulates mass document creation using BDCDATA and CALL TRANSACTION, including message handling via BDCMSGCOLL.

  Path:
  `/1_src/ZFIP_FB01_AUTOM`
  `/2_docs/ZFIP_FB01_AUTOM`

## Technologies
- ABAP (SAP NetWeaver 7.02)
- Module Pool (Dynpro, PBO/PAI)
- ALV (ABAP List Viewer)
- SmartForms
- Batch Input (BDC)
- Open SQL
- Data Dictionary (tables, data elements, domains)
- Function Modules

## Data Model
Custom tables were created to simulate SAP FI structures and support the application logic.
Examples:
- ZBKPF (document header)
- ZBSEG (document items)
- ZHKONT (accounts)
- ZT001, ZT003 (configuration)
- ZPARAM (parameterization)

Also included:
- Function modules for reusable logic
- Data elements and domains for data definition

## Functional Scenario
- Manual document creation (Module Pool)
- Storage in custom FI-like tables
- Document retrieval via ALV report
- Document printing via SmartForms
- Mass document creation via Batch Input

## Author
Fiorella Petrillo

------------------------------
## Gestión de Documentos Financieros en ABAP

## Descripción
- Solución ABAP end-to-end que simula un proceso de gestión de documentos financieros en SAP NetWeaver 7.02. El proyecto cubre la creación, persistencia, consulta, impresión y automatización masiva de documentos contables, integrando múltiples componentes ABAP en un único flujo funcional.

## Arquitectura general
- El sistema está diseñado como un ciclo completo de vida del documento:

- Entrada de datos (Module Pool)  
- Persistencia de datos (tablas tipo FI)  
- Consulta de datos (reporte ALV)  
- Salida de documentos (SmartForms)  
- Procesamiento masivo (Batch Input Automation)  

## Componentes del proyecto

- **ZFIP_FB01 (Module Pool)**  
  - Transacción para la creación manual de documentos financieros utilizando pantallas Dynpro (PBO/PAI). Incluye validaciones, lógica de negocio y persistencia en tablas propias tipo FI.  
  - Carpetas:  
    - `/1_src/ZFIP_FB01`  
    - `/2_docs/ZFIP_FB01`  

- **ZFIR_BUSCAR_DOC (ALV Report)**  
  - Reporte con pantalla de selección y salida ALV para consultar documentos almacenados. Incluye consolidación de datos de cabecera y posiciones y dispara SmartForms para impresión.  
  - Carpetas:  
    - `/1_src/ZFIR_BUSCAR_DOC`  
    - `/2_docs/ZFIR_BUSCAR_DOC`  

- **SmartForms**  
  - Formularios para la impresión de documentos desde el ALV.  
  - Carpetas:  
    - `/2_docs/ZFISF_DOC_KR`  
    - `/2_docs/ZFISF_DOC_KZ`  
    - `/2_docs/ZFISF_DOC_SA`  

- **ZFIP_FB01_AUTOM (Batch Input)**  
  - Programa de automatización que simula la carga masiva de documentos utilizando BDCDATA y CALL TRANSACTION, incluyendo manejo de mensajes vía BDCMSGCOLL.  
  - Carpetas:  
    - `/1_src/ZFIP_FB01_AUTOM`  
    - `/2_docs/ZFIP_FB01_AUTOM`  

## Tecnologías
- ABAP (SAP NetWeaver 7.02)  
- Module Pool (Dynpro, PBO/PAI)  
- ALV (ABAP List Viewer)  
- SmartForms  
- Batch Input (BDC)  
- Open SQL  
- Data Dictionary (tablas, elementos de datos, dominios)  
- Function Modules  

## Modelo de datos
- Se crearon tablas propias para simular estructuras de SAP FI y soportar la lógica de la aplicación.

- Ejemplos:
  - ZBKPF (cabecera de documento)  
  - ZBSEG (posiciones del documento)  
  - ZHKONT (cuentas)  
  - ZT001, ZT003 (configuración)  
  - ZPARAM (parametrización)  

- También incluye:
  - Módulos de función para lógica reutilizable  
  - Elementos de datos y dominios para definición técnica  

## Escenario funcional
- Creación manual de documentos 
- Almacenamiento en tablas
- Consulta de documentos mediante reporte ALV  
- Impresión de documentos mediante SmartForms  
- Creación masiva mediante Batch Input  

## Autor
- Fiorella Petrillo
