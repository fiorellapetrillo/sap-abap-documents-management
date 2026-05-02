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

