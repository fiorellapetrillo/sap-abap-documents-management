---------------------------------------------------------- Español ----------------------------------------------------------
# Gestión de Documentos Contables en ABAP

## Descripción
- Proyecto ABAP end-to-end que simula un proceso de gestión de documentos contables sobre un entorno de práctica. El desarrollo cubre la creación, persistencia, consulta, impresión y automatización masiva de documentos, integrando múltiples componentes ABAP en un único flujo funcional.

## Flujo funcional
- El sistema está diseñado como un ciclo completo de vida del documento:

  - Desarrollo custom para creación de documentos (ZFIP_FB01) → Persistencia en tablas Z → Reporte para consulta (ZFIR_BUSCAR_DOC) y emisión mediante SMARTFORMS → Automatización de carga masiva mediante archivos (ZFIP_FB01_AUTOM)
 
## Componentes del proyecto

- **ZFIP_FB01 (Module Pool)**  
  - Transacción para la creación manual de documentos contables utilizando pantallas Dynpro (PBO/PAI). Incluye validaciones, lógica de negocio y persistencia en tablas Z.  
  - Código fuente y capturas:  
    - [/1_src/ZFIP_FB01](./1_src/ZFIP_FB01)  
    - [/2_docs/ZFIP_FB01](./2_docs/ZFIP_FB01)
<img width="500" alt="zfip_fb01_screen_0100" src="https://github.com/user-attachments/assets/ce316540-e921-4311-8983-d543ad54a0eb" />
<img width="500" alt="zfip_fb01_screen_0200" src="https://github.com/user-attachments/assets/11199017-d427-43c8-90c6-3f27f55a41e9" />
<img width="500" alt="zfip_fb01_screen_0300" src="https://github.com/user-attachments/assets/a14f9fd2-71d0-411d-9b52-c07aa6a96f88" />
   
- **ZFIR_BUSCAR_DOC (ALV Report)**  
  - Reporte con pantalla de selección y salida ALV para consulta de documentos almacenados. Incluye consolidación de datos de cabecera y posiciones, y dispara SmartForms para emisión documental.  
  - Código fuente y capturas:  
    - [/1_src/ZFIR_BUSCAR_DOC](./1_src/ZFIR_BUSCAR_DOC)  
    - [/2_docs/ZFIR_BUSCAR_DOC](./2_docs/ZFIR_BUSCAR_DOC)  
<img width="500" alt="zfir_buscar_doc_selection_screen" src="https://github.com/user-attachments/assets/2cb281f1-795b-4971-8328-ace8fb9ec7f2" />
<img width="2314" height="355" alt="zfir_buscar_doc_alv_output" src="https://github.com/user-attachments/assets/d4061c05-9288-4bf2-9c7b-148d49e338a2" />

- **SmartForms**  
  - Formularios para la impresión de documentos desde el ALV.  
  - Capturas:  
    - [/2_docs/ZFISF_DOC_KR](./2_docs/ZFISF_DOC_KR)  
    - [/2_docs/ZFISF_DOC_KZ](./2_docs/ZFISF_DOC_KZ)  
    - [/2_docs/ZFISF_DOC_SA](./2_docs/ZFISF_DOC_SA)
   <img width="500" alt="ZFISF_DOC_KR_KZ(2)" src="https://github.com/user-attachments/assets/63fdc735-8c19-461a-b156-e1be760902de" />
     
- **ZFIP_FB01_AUTOM (Batch Input)**  
  - Programa de automatización que simula la carga masiva de documentos utilizando BDCDATA y CALL TRANSACTION, incluyendo manejo de mensajes vía BDCMSGCOLL.  
  - Código fuente y capturas:  
    - [/1_src/ZFIP_FB01_AUTOM](./1_src/ZFIP_FB01_AUTOM)  
    - [/2_docs/ZFIP_FB01_AUTOM](./2_docs/ZFIP_FB01_AUTOM)  
<img width="500" alt="zfip_fb01_autom_selection_screen_1" src="https://github.com/user-attachments/assets/3574595b-83d6-4c63-81e4-8bec33a00026" />
<img width="500" alt="zfip_fb01_autom_success" src="https://github.com/user-attachments/assets/638364bf-3d01-438b-af69-0481e94dfb3f" />

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
- Para sustentar la lógica de la aplicación en el entorno de práctica NetWeaver 7.02, se modelaron tablas propias basadas en el estándar de SAP:

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

## Escenario funcional
- Creación manual de documentos 
- Almacenamiento en tablas
- Consulta de documentos mediante reporte ALV  
- Impresión de documentos mediante SmartForms  
- Creación masiva mediante Batch Input  

## Autor
- Fiorella Petrillo

---------------------------------------------------------- English ----------------------------------------------------------
# Accounting Document Management in ABAP

## Description
- End-to-end ABAP project that simulates an accounting document management process on a practice environment. The development covers document creation, persistence, query, printing, and mass automation, integrating multiple ABAP components into a single functional workflow.

## Functional Workflow
- The system is designed as a complete document lifecycle:

  - Custom development for document creation (ZFIP_FB01) → Persistence in Z tables → Query report (ZFIR_BUSCAR_DOC) and document issuance via SMARTFORMS → Mass upload automation through files (ZFIP_FB01_AUTOM)
 
## Project Components

- **ZFIP_FB01 (Module Pool)**  
  - Transaction for manual creation of accounting documents using Dynpro screens (PBO/PAI). Includes validations, business logic, and persistence in Z tables.  
  - Source code and screenshots:  
    - [/1_src/ZFIP_FB01](./1_src/ZFIP_FB01)  
    - [/2_docs/ZFIP_FB01](./2_docs/ZFIP_FB01)
<img width="500" alt="zfip_fb01_screen_0100" src="https://github.com/user-attachments/assets/ce316540-e921-4311-8983-d543ad54a0eb" />
<img width="500" alt="zfip_fb01_screen_0200" src="https://github.com/user-attachments/assets/11199017-d427-43c8-90c6-3f27f55a41e9" />
<img width="500" alt="zfip_fb01_screen_0300" src="https://github.com/user-attachments/assets/a14f9fd2-71d0-411d-9b52-c07aa6a96f88" />
   
- **ZFIR_BUSCAR_DOC (ALV Report)**  
  - Report with selection screen and ALV grid output for querying stored documents. Includes consolidation of header and line item data, and triggers SmartForms for document printing.  
  - Source code and screenshots:  
    - [/1_src/ZFIR_BUSCAR_DOC](./1_src/ZFIR_BUSCAR_DOC)  
    - [/2_docs/ZFIR_BUSCAR_DOC](./2_docs/ZFIR_BUSCAR_DOC)  
<img width="500" alt="zfir_buscar_doc_selection_screen" src="https://github.com/user-attachments/assets/2cb281f1-795b-4971-8328-ace8fb9ec7f2" />
<img width="2314" height="355" alt="zfir_buscar_doc_alv_output" src="https://github.com/user-attachments/assets/d4061c05-9288-4bf2-9c7b-148d49e338a2" />

- **SmartForms**  
  - Print forms for documents triggered from the ALV output.  
  - Screenshots:  
    - [/2_docs/ZFISF_DOC_KR](./2_docs/ZFISF_DOC_KR)  
    - [/2_docs/ZFISF_DOC_KZ](./2_docs/ZFISF_DOC_KZ)  
    - [/2_docs/ZFISF_DOC_SA](./2_docs/ZFISF_DOC_SA)
   <img width="500" alt="ZFISF_DOC_KR_KZ(2)" src="https://github.com/user-attachments/assets/63fdc735-8c19-461a-b156-e1be760902de" />
     
- **ZFIP_FB01_AUTOM (Batch Input)**  
  - Automation program that simulates mass document upload using BDCDATA and CALL TRANSACTION, including message handling via BDCMSGCOLL.  
  - Source code and screenshots:  
    - [/1_src/ZFIP_FB01_AUTOM](./1_src/ZFIP_FB01_AUTOM)  
    - [/2_docs/ZFIP_FB01_AUTOM](./2_docs/ZFIP_FB01_AUTOM)  
<img width="500" alt="zfip_fb01_autom_selection_screen_1" src="https://github.com/user-attachments/assets/3574595b-83d6-4c63-81e4-8bec33a00026" />
<img width="500" alt="zfip_fb01_autom_success" src="https://github.com/user-attachments/assets/638364bf-3d01-438b-af69-0481e94dfb3f" />

## Technologies
- ABAP (SAP NetWeaver 7.02)  
- Module Pool (Dynpro, PBO/PAI)  
- ALV (ABAP List Viewer)  
- SmartForms  
- Batch Input (BDC)  
- Open SQL  
- Data Dictionary (Tables, Data Elements, Domains)  
- Function Modules  

## Data Model
- To support the application logic in the NetWeaver 7.02 practice environment, custom tables were modeled based on the SAP standard:

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

## Functional Scenario
- Manual document creation 
- Data persistence in custom tables
- Document query via ALV report  
- Document printing via SmartForms  
- Mass document creation via Batch Input  

## Author
- Fiorella Petrillo
