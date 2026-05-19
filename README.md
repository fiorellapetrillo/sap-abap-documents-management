---------------------------------------------------------- Español ----------------------------------------------------------
## Gestión de Documentos Contables en ABAP

## Descripción
- Proyecto ABAP end-to-end que simula un proceso de gestión de documentos contables sobre un entorno de práctica. El desarrollo cubre la creación, persistencia, consulta, impresión y automatización masiva de documentos, integrando múltiples componentes ABAP en un único flujo funcional.

## Flujo funcional
- El sistema está diseñado como un ciclo completo de vida del documento:

  - Desarrollo custom para creación de documentos (ZFIP_FB01) → Persistencia en tablas Z → Reporte para consulta (ZFIR_BUSCAR_DOC) y emisión mediante SmartForms → Automatización de carga masiva mediante archivos (ZFIP_FB01_AUTOM)
 
## Componentes del proyecto

- **ZFIP_FB01 (Module Pool)**  
  - Transacción para la creación manual de documentos contables utilizando pantallas Dynpro (PBO/PAI). Incluye validaciones, lógica de negocio y persistencia en tablas Z.  
  - Código fuente y capturas:  
    - [/1_src/ZFIP_FB01](./1_src/ZFIP_FB01)  
    - [/2_docs/ZFIP_FB01](./2_docs/ZFIP_FB01)
   <img width="600" alt="zfip_fb01_screen_0100" src="https://github.com/user-attachments/assets/ce316540-e921-4311-8983-d543ad54a0eb" />


      

- **ZFIR_BUSCAR_DOC (ALV Report)**  
  - Reporte con pantalla de selección y salida ALV para consulta de documentos almacenados. Incluye consolidación de datos de cabecera y posiciones, y dispara SmartForms para emisión documental.  
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
- Diccionario de Datos (tablas, elementos de datos, dominios)  
- Módulos de Función  

## Modelo de datos
- Para sustentar la lógica de la aplicación en el entorno de práctica NetWeaver 7.02, se modelaron tablas propias basadas en el estándar de SAP FI:

  - ZBKPF (cabecera de documento)  
  - ZBSEG (posiciones del documento)  
  - ZHKONT (cuentas)  
  - ZT001, ZT003 (configuración de sociedades y tipos)  
  - ZPARAM (parametrización)
  - ZFB01_FILE_PROC (log de arhivos procesados para evitar duplicación)

- También incluye:
  - Módulos de función para lógica reutilizable  
  - Elementos de datos y dominios para definición técnica  

## Controles de calidad de código
- Todo el desarrollo fue validado utilizando herramientas estándar de SAP para asegurar calidad, consistencia y cumplimiento de buenas prácticas:
- SAP Code Inspector (SCI)
- Extended Program Check (SLIN)

## Escenario funcional
- Creación manual de documentos 
- Almacenamiento en tablas
- Consulta de documentos mediante reporte ALV  
- Impresión de documentos mediante SmartForms  
- Creación masiva mediante Batch Input  

## Autor
- Fiorella Petrillo

---------------------------------------------------------- English ----------------------------------------------------------
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

## Code Quality Controls
- All development was validated using SAP standard tools to ensure code quality, consistency, and compliance with best practices:
- SAP Code Inspector (SCI)
- Extended Program Check (SLIN)

## Functional Scenario
- Manual document creation (Module Pool)
- Storage in custom FI-like tables
- Document retrieval via ALV report
- Document printing via SmartForms
- Mass document creation via Batch Input

## Author
Fiorella Petrillo
