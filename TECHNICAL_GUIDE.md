# Technical Guide

This guide is for developers or analysts who need to support, extend, or troubleshoot the Send-Out Tracking Workstation.

## Overview

The app is a Shiny-based operational workstation backed by local `pins`.

The design intent is:

- keep the UI understandable for operational staff
- keep persistence abstracted behind helper functions
- separate operational PDF metadata from large OCR text payloads
- preserve a path toward future matching and eventual database migration

## Core Architecture

### Application entry point

- [app.R](/C:/Users/amrom/OneDrive/Documents/sendout-tool/app.R)

Responsibilities:

- load all files in `R/`
- initialize reactive state from persisted pins
- render tabbed UI
- connect row-level UI actions to mutation helpers
- compute metrics for display

### Persistence

- [R/pins_io.R](/C:/Users/amrom/OneDrive/Documents/sendout-tool/R/pins_io.R)

Current persisted tables:

- orders
- PDFs
- PDF OCR text
- suggestions

Important detail:

- local pins are written to `%LOCALAPPDATA%\\sendout-tool\\pins_board`
- this avoids overwrite failures caused by OneDrive locking repo-local folders

If persistence is later migrated to a database, this is the main seam to replace.

### Ingestion

- [R/data_ingest_orders.R](/C:/Users/amrom/OneDrive/Documents/sendout-tool/R/data_ingest_orders.R)
- [R/data_ingest_pdfs.R](/C:/Users/amrom/OneDrive/Documents/sendout-tool/R/data_ingest_pdfs.R)
- [R/data_ingest_pdf_text.R](/C:/Users/amrom/OneDrive/Documents/sendout-tool/R/data_ingest_pdf_text.R)

Design choices:

- orders are normalized and recomputed from LIS-export inputs
- PDFs preserve app-managed work-tracking columns across refreshes
- OCR text is stored separately and linked by `pdf_id`
- PDF metadata carries `parsed_text_available` as a lightweight flag

### Metrics

- [R/metrics.R](/C:/Users/amrom/OneDrive/Documents/sendout-tool/R/metrics.R)

Definitions:

- final TAT = `lis_result_verified_datetime - order_datetime`
- pending = missing LIS verified timestamp
- overdue = pending and beyond expected TAT
- recent PDF receipt = within configurable recent window
- PDF work lag = `worked_datetime - pdf_received_datetime`

### PDF path behavior

- [R/helpers_paths.R](/C:/Users/amrom/OneDrive/Documents/sendout-tool/R/helpers_paths.R)

`open_pdf()` abstracts OS-specific open behavior.

Expected behavior:

- open the file if the runtime environment can access it
- otherwise surface the path so the user can still act

### Status mutations

- [R/status_updates.R](/C:/Users/amrom/OneDrive/Documents/sendout-tool/R/status_updates.R)

These functions are intended to be the server-side mutation layer for:

- reviewed
- worked
- worked outside system
- notes
- assignment

## Current Data Schemas

### Orders table

Required operational columns:

- `order_id`
- `patient_id`
- `patient_name`
- `test_name`
- `reference_lab`
- `order_datetime`
- `specimen_datetime`
- `expected_tat_hours`
- `lis_result_verified_datetime`
- `order_status`
- `last_updated`
- `is_verified`
- `is_overdue`
- `tat_verified_hours`
- `aging_hours`

### PDFs table

Required operational columns:

- `pdf_id`
- `pdf_received_datetime`
- `pdf_path`
- `pdf_filename`
- `pdf_pages`
- `pdf_source_folder`
- `pdf_status`
- `worked_status`
- `worked_by`
- `worked_datetime`
- `notes`
- `assigned_to`
- `last_updated`
- `parsed_text_available`

### PDF text table

Current OCR payload columns:

- `pdf_id`
- `ocr_text`
- `ocr_status`
- `ocr_engine`
- `ocr_processed_datetime`
- `ocr_confidence`
- `text_version`
- `last_updated`

### Suggestions table

Placeholder only for now:

- `suggestion_id`
- `pdf_id`
- `order_id`
- `suggestion_rank`
- `suggestion_score`
- `suggestion_reason`
- `suggestion_status`

## Local Development Workflow

Install packages if needed:

```powershell
$env:R_LIBS_USER='C:\Users\amrom\AppData\Local\R\win-library\4.4'
& 'C:\Program Files\R\R-4.4.2\bin\Rscript.exe' -e "install.packages(c('shiny','DT','bslib','ggplot2','pins','digest','dplyr'), repos='https://cloud.r-project.org')"
```

Load sample data:

```powershell
$env:R_LIBS_USER='C:\Users\amrom\AppData\Local\R\win-library\4.4'
& 'C:\Program Files\R\R-4.4.2\bin\Rscript.exe' scripts/dev_load.R
```

Run app:

```powershell
$env:R_LIBS_USER='C:\Users\amrom\AppData\Local\R\win-library\4.4'
& 'C:\Program Files\R\R-4.4.2\bin\Rscript.exe' -e "shiny::runApp('.', launch.browser = TRUE)"
```

## Common Support Tasks

### Reset local data

Delete the local pins folder:

`C:\Users\amrom\AppData\Local\sendout-tool\pins_board`

Then rerun `scripts/dev_load.R` or your real ingestion flow.

### Replace sample data with real data

Typical approach:

1. Load real LIS export into a dataframe.
2. Call `ingest_orders()`.
3. Write via `write_orders()`.
4. Load real PDF event feed.
5. Call `ingest_pdfs()`.
6. Write via `write_pdfs()`.
7. Load OCR output.
8. Call `ingest_pdf_text()`.
9. Optionally call `sync_pdf_text_flags()`.
10. Write via `write_pdf_text()` and `write_pdfs()`.

### Troubleshoot missing PDFs

Check:

- whether `pdf_path` is correct
- whether the app host can access that path
- whether the file still exists
- whether the path is local, mapped, or UNC-based

### Troubleshoot empty tables

Check:

- whether the pin board exists
- whether data was written to the expected local pins path
- whether source data had the expected columns
- whether `order_id` or `pdf_id` values were missing

## Extension Points

### Next logical enhancements

- surface OCR availability and text preview in the UI
- parse patient/test/accession metadata from OCR text
- generate candidate order links
- add suggestion review workflow
- expose per-lab operational queues

### Database migration path

The easiest migration path is:

1. preserve dataframe-shaped contracts
2. replace pin load/write helpers with database read/write helpers
3. leave UI and metrics interfaces mostly unchanged

### Multi-user considerations

Current MVP assumptions:

- local or light shared usage
- no formal record locking
- no authentication layer

If usage broadens, the first place to harden is persistence and write concurrency.

