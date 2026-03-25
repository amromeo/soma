# Send-Out Tracking Workstation

This project is an MVP Shiny application for operational tracking of laboratory send-out testing.

It is designed to help staff answer a few daily questions quickly:

- Which send-out orders are still pending?
- Which results have arrived as inbound PDFs?
- Which orders are overdue?
- Which PDFs have already been reviewed or worked?
- Where is the actual PDF file so it can be opened immediately?

This is intentionally a workstation, not just a dashboard. The app supports operational triage, lightweight work tracking, and future OCR-assisted matching without requiring manual linking in the MVP.

## Current MVP Scope

The app currently includes:

- a `Recently Received` worklist for inbound PDFs
- a `Pending` view for LIS orders without verified results
- an `Overdue` view for orders past expected turnaround
- a `Metrics` view for light operational summaries
- a `Matching` placeholder tab for future OCR-assisted linking
- separate persistence for:
  - LIS orders
  - inbound PDFs
  - OCR text payloads
  - future link suggestions

## Project Structure

```text
app.R
R/
  data_ingest_orders.R
  data_ingest_pdfs.R
  data_ingest_pdf_text.R
  helpers_paths.R
  metrics.R
  pins_io.R
  status_updates.R
  ui_tables.R
data/
  sample_orders.csv
  sample_pdfs.csv
  sample_pdf_text.csv
scripts/
  dev_load.R
www/
  styles.css
```

## Data Model

### 1. Orders

Source of truth for reconciled send-out order status and final turnaround time.

Key fields include:

- `order_id`
- `patient_id`
- `patient_name`
- `test_name`
- `reference_lab`
- `order_datetime`
- `expected_tat_hours`
- `lis_result_verified_datetime`
- `is_verified`
- `is_overdue`
- `tat_verified_hours`
- `aging_hours`

### 2. PDFs

Operational queue for inbound result PDFs.

Key fields include:

- `pdf_id`
- `pdf_received_datetime`
- `pdf_path`
- `pdf_filename`
- `pdf_pages`
- `pdf_status`
- `worked_status`
- `worked_by`
- `worked_datetime`
- `notes`
- `assigned_to`
- `parsed_text_available`

### 3. PDF Text

Separate OCR payload storage keyed by `pdf_id`.

Key fields include:

- `pdf_id`
- `ocr_text`
- `ocr_status`
- `ocr_engine`
- `ocr_processed_datetime`
- `ocr_confidence`
- `text_version`

### 4. Link Suggestions

Placeholder table for future candidate matching.

## Local Persistence

The MVP uses `pins`.

For local development, pins are stored outside the repo in:

`C:\Users\amrom\AppData\Local\sendout-tool\pins_board`

This avoids OneDrive file locking issues when the repo itself is in a synced folder.

## Local Setup

This repo expects R 4.4.x and these packages:

- `shiny`
- `DT`
- `bslib`
- `ggplot2`
- `pins`
- `digest`
- `dplyr`

If needed:

```powershell
$env:R_LIBS_USER='C:\Users\amrom\AppData\Local\R\win-library\4.4'
& 'C:\Program Files\R\R-4.4.2\bin\Rscript.exe' -e "install.packages(c('shiny','DT','bslib','ggplot2','pins','digest','dplyr'), repos='https://cloud.r-project.org')"
```

## Local Testing

Load sample data:

```powershell
$env:R_LIBS_USER='C:\Users\amrom\AppData\Local\R\win-library\4.4'
& 'C:\Program Files\R\R-4.4.2\bin\Rscript.exe' scripts/dev_load.R
```

Run the app:

```powershell
$env:R_LIBS_USER='C:\Users\amrom\AppData\Local\R\win-library\4.4'
& 'C:\Program Files\R\R-4.4.2\bin\Rscript.exe' -e "shiny::runApp('.', launch.browser = TRUE)"
```

## Notes About Sample Data

- sample PDF paths are placeholders and may not exist on your machine
- the `Open` action is wired, but it only opens real files
- OCR text is seeded separately through `data/sample_pdf_text.csv`

## What the App Does Not Do Yet

- automated PDF-to-order matching
- manual linking workflow
- LIS writeback
- interface engine routing
- authentication / authorization
- enterprise-grade multi-user locking

## Future Direction

The current structure is meant to support later addition of:

- parsed metadata extraction from OCR text
- candidate match generation
- suggestion review and acceptance
- interface-engine routing
- migration from pins/dataframes to a database backend

