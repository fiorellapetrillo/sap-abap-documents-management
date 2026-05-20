---------------------------------------------------------- Español ----------------------------------------------------------
# Gestión de Documentos Contables en ABAP

## Descripción
- Proyecto ABAP end-to-end que simula un proceso de gestión de documentos contables sobre un entorno SAP de práctica. El desarrollo cubre la creación, persistencia, consulta, impresión y automatización masiva de documentos, integrando múltiples componentes ABAP en un único flujo funcional.

## Flujo funcional
- El sistema está diseñado como un ciclo completo de vida del documento:

  - Desarrollo custom para creación de documentos (`ZFIP_FB01`) → Persistencia en tablas Z → Reporte para consulta (`ZFIR_BUSCAR_DOC`) y emisión mediante `SMARTFORMS` → Automatización de carga masiva mediante archivos (`ZFIP_FB01_AUTOM`)
 
## Componentes del proyecto

- **ZFIP_FB01 (Module Pool)**  
  - Transacción para la creación manual de documentos contables utilizando pantallas Dynpro (PBO/PAI). Incluye validaciones, lógica de negocio y persistencia en tablas Z.  
  - Código fuente y capturas:  
    - [/1_src/ZFIP_FB01](./1_src/ZFIP_FB01)  
    - [/2_docs/ZFIP_FB01](./2_docs/ZFIP_FB01)
  <img width="400" alt="zfip_fb01_screen_0100" src="https://github.com/user-attachments/assets/ce316540-e921-4311-8983-d543ad54a0eb" />
  <img width="400" alt="zfip_fb01_screen_0200" src="https://github.com/user-attachments/assets/11199017-d427-43c8-90c6-3f27f55a41e9" />
  <img width="400" alt="zfip_fb01_screen_0300" src="https://github.com/user-attachments/assets/a14f9fd2-71d0-411d-9b52-c07aa6a96f88" />

   
- **ZFIR_BUSCAR_DOC (ALV Report)**  
  - Reporte con pantalla de selección y salida ALV para consulta de documentos procesados. Incluye consolidación de datos de cabecera y posiciones, y dispara SmartForms para emisión documental.  
  - Código fuente y capturas:  
    - [/1_src/ZFIR_BUSCAR_DOC](./1_src/ZFIR_BUSCAR_DOC)  
    - [/2_docs/ZFIR_BUSCAR_DOC](./2_docs/ZFIR_BUSCAR_DOC)  
  <img width="500" alt="zfir_buscar_doc_selection_screen" src="https://github.com/user-attachments/assets/2cb281f1-795b-4971-8328-ace8fb9ec7f2" />
<img width="1000" alt="zfir_buscar_doc_alv" src="https://github.com/user-attachments/assets/1dc879fb-5428-4baa-85b8-d47ba1f1b6a6" />


- **SmartForms**  
  - Formularios para la emisión de documentos desde el ALV.  
  - Capturas:  
    - [/2_docs/ZFISF_DOC_KR](2_docs/SMARTFORMS/ZFISF_DOC_KR_KZ(KR).png)  
    - [/2_docs/ZFISF_DOC_KZ](2_docs/SMARTFORMS/ZFISF_DOC_KR_KZ(KZ).png)  
    - [/2_docs/ZFISF_DOC_SA](2_docs/SMARTFORMS/ZFISF_DOC_SA.png)
  <img width="400" alt="ZFISF_DOC_KR_KZ(2)" src="https://github.com/user-attachments/assets/14e434f1-1cde-44a8-b0e5-af95d5391666" />
     
- **ZFIP_FB01_AUTOM (Batch Input)**  
  - Programa de automatización de carga masiva mediante lectura de archivo TXT desde frontend / application server (AL11) y procesamiento mediante BDC / Batch Input con CALL TRANSACTION
  - Código fuente y capturas:  
    - [/1_src/ZFIP_FB01_AUTOM](./1_src/ZFIP_FB01_AUTOM)  
    - [/2_docs/ZFIP_FB01_AUTOM](./2_docs/ZFIP_FB01_AUTOM)  
  <img width="400" alt="zfip_fb01_autom_selection_screen_1" src="https://github.com/user-attachments/assets/07ee64e8-4960-4405-b7b9-cf6f157354c8" />
  <img width="400"  alt="zfip_fb01_autom_results" src="https://github.com/user-attachments/assets/bcf9b700-114f-45b0-a875-d80ee1369be9" />

## Tecnologías
- ABAP 
- Module Pool (Dynpro, PBO/PAI)  
- ALV (ABAP List Viewer)  
- SmartForms  
- Batch Input (BDC)  
- Open SQL  
- Diccionario de Datos (tablas, elementos de datos, dominios)  
- Módulos de Función (SE37)
- Vistas de Mantenimiento (SM30)
- Clases de Mensajes (SE91)
- Objetos de Rango Numérico (SNRO)

## Modelo de datos
- Para sustentar la lógica de la aplicación en el entorno SAP de práctica NetWeaver 7.02, se modelaron tablas propias basadas en el estándar de SAP:

### 1. Tablas de Datos Maestros y Configuración
* `ZHKONT`: Maestro de cuentas contables (catálogo de cuentas)
* `ZT001`: Configuración de sociedades contables
* `ZT003`: Configuración de tipos de documento
* `ZPARAM`: Parametrizaciones

### 2. Tablas de Procesos
* `ZFB01_FILE_PROC`: Log de control de archivos procesados para validación de duplicados

### 3. Tablas de Persistencia
* `ZBKPF`: Cabeceras de documentos contables
* `ZBSEG`: Posiciones de documentos contables

## Controles de calidad de código
- Todo el desarrollo fue validado utilizando herramientas estándar de SAP para asegurar calidad, consistencia y cumplimiento de buenas prácticas:
- SAP Code Inspector (SCI)
- Extended Program Check (SLIN)

## Autor
- Fiorella Petrillo

---------------------------------------------------------- English ----------------------------------------------------------
# Accounting Document Management in ABAP

## Description
- End-to-end ABAP project that simulates an accounting document management process on a SAP practice environment. The development covers document creation, persistence, query, printing, and mass automation, integrating multiple ABAP components into a single functional workflow.

## Functional Workflow
- The system is designed as a complete document lifecycle:

  - Custom development for document creation (ZFIP_FB01) → Persistence in Z tables → Query report (ZFIR_BUSCAR_DOC) and document issuance via SMARTFORMS → Mass upload automation through files (ZFIP_FB01_AUTOM)
 
## Project Components

- **ZFIP_FB01 (Module Pool)**  
  - Transaction for manual creation of accounting documents using Dynpro screens (PBO/PAI). Includes validations, business logic, and persistence in Z tables.  
  - Source code and screenshots:  
    - [/1_src/ZFIP_FB01](./1_src/ZFIP_FB01)  
    - [/2_docs/ZFIP_FB01](./2_docs/ZFIP_FB01)
  <img width="400" alt="zfip_fb01_screen_0100" src="https://github.com/user-attachments/assets/ce316540-e921-4311-8983-d543ad54a0eb" />
  <img width="400" alt="zfip_fb01_screen_0200" src="https://github.com/user-attachments/assets/11199017-d427-43c8-90c6-3f27f55a41e9" />
  <img width="400" alt="zfip_fb01_screen_0300" src="https://github.com/user-attachments/assets/a14f9fd2-71d0-411d-9b52-c07aa6a96f88" />
   
- **ZFIR_BUSCAR_DOC (ALV Report)**  
  - Report with selection screen and ALV grid output for querying process documents. Includes consolidation of header and line item data, and triggers SmartForms for document printing.  
  - Source code and screenshots:  
    - [/1_src/ZFIR_BUSCAR_DOC](./1_src/ZFIR_BUSCAR_DOC)  
    - [/2_docs/ZFIR_BUSCAR_DOC](./2_docs/ZFIR_BUSCAR_DOC)  
  <img width="500" alt="zfir_buscar_doc_selection_screen" src="https://github.com/user-attachments/assets/2cb281f1-795b-4971-8328-ace8fb9ec7f2" />
<img width="900" alt="zfir_buscar_doc_alv" src="https://github.com/user-attachments/assets/1dc879fb-5428-4baa-85b8-d47ba1f1b6a6" />

- **SmartForms**  
  - Print forms for documents triggered from the ALV output.  
  - Screenshots:  
    - [/2_docs/ZFISF_DOC_KR](2_docs/SMARTFORMS/ZFISF_DOC_KR_KZ(KR).png)  
    - [/2_docs/ZFISF_DOC_KZ](2_docs/SMARTFORMS/ZFISF_DOC_KR_KZ(KZ).png)  
    - [/2_docs/ZFISF_DOC_SA](2_docs/SMARTFORMS/ZFISF_DOC_SA.png)
  <img width="400" alt="ZFISF_DOC_KR_KZ(2)" src="https://github.com/user-attachments/assets/14e434f1-1cde-44a8-b0e5-af95d5391666" />
     
- **ZFIP_FB01_AUTOM (Batch Input)**  
  - Mass data load automation program via TXT file reading from frontend / application server (AL11) and processing via BDC / Batch Input with CALL TRANSACTION.  
  - Source code and screenshots:  
    - [/1_src/ZFIP_FB01_AUTOM](./1_src/ZFIP_FB01_AUTOM)  
    - [/2_docs/ZFIP_FB01_AUTOM](./2_docs/ZFIP_FB01_AUTOM)  
  <img width="400" alt="zfip_fb01_autom_selection_screen_1" src="https://github.com/user-attachments/assets/07ee64e8-4960-4405-b7b9-cf6f157354c8" />
  <img width="400"  alt="zfip_fb01_autom_results" src="https://github.com/user-attachments/assets/bcf9b700-114f-45b0-a875-d80ee1369be9" />

## Technologies
- ABAP 
- Module Pool (Dynpro, PBO/PAI)  
- ALV (ABAP List Viewer)  
- SmartForms  
- Batch Input (BDC)  
- Open SQL  
- Data Dictionary (Tables, Data Elements, Domains)  
- Function Modules (SE37)
- Maintenance views (SM30)
- Message classes (SE91)
- Number range objects (SNRO)

## Data Model
- To support the application logic in the SAP NetWeaver 7.02 practice environment, custom tables were modeled based on the SAP standard:

### 1. Master Data and Configuration Tables
* `ZHKONT`: G/L Account Master (Chart of Accounts)
* `ZT001`: Company Code Configuration
* `ZT003`: Document Type Configuration
* `ZPARAM`: Parameter Settings

### 2. Process Tables
* `ZFB01_FILE_PROC`: Control log of processed files for duplicate validation

### 3. Persistence Tables
* `ZBKPF`: Accounting Document Headers
* `ZBSEG`: Accounting Document Line Items

## Code Quality Controls
- The entire development was validated using standard SAP tools to ensure quality, consistency, and compliance with best practices:
- SAP Code Inspector (SCI)
- Extended Program Check (SLIN)

## Author
- Fiorella Petrillo
