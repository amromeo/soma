source_files <- list.files("R", pattern = "\\.[Rr]$", full.names = TRUE)
invisible(lapply(source_files, source))

orders_raw <- read.csv("data/sample_orders.csv", stringsAsFactors = FALSE)
pdfs_raw <- read.csv("data/sample_pdfs.csv", stringsAsFactors = FALSE)
pdf_text_raw <- read.csv("data/sample_pdf_text.csv", stringsAsFactors = FALSE)

orders <- ingest_orders(orders_raw, existing = load_orders())
pdfs <- ingest_pdfs(pdfs_raw, existing = load_pdfs())
pdf_text <- ingest_pdf_text(pdf_text_raw, existing = load_pdf_text())
pdfs <- sync_pdf_text_flags(pdfs, pdf_text)

write_orders(orders)
write_pdfs(pdfs)
write_suggestions(empty_suggestions_df())
write_pdf_text(pdf_text)

cat("Sample data loaded into local pins board.\n")
