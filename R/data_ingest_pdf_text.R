library(dplyr)

init_pdf_text_columns <- function(df) {
  defaults <- empty_pdf_text_df()
  for (col in names(defaults)) {
    if (!col %in% names(df)) {
      df[[col]] <- defaults[[col]]
    }
  }
  df[, names(defaults), drop = FALSE]
}

ingest_pdf_text <- function(df_raw, existing = load_pdf_text()) {
  if (missing(df_raw) || is.null(df_raw) || !nrow(df_raw)) {
    return(init_pdf_text_columns(existing))
  }

  pdf_ids <- as.character(coalesce_col(df_raw, c("pdf_id")))
  path_values <- as.character(coalesce_col(df_raw, c("pdf_path", "path", "full_path", "file_path")))
  derived_ids <- vapply(path_values, derive_pdf_id, character(1))
  resolved_ids <- ifelse(is.na(pdf_ids) | pdf_ids == "", derived_ids, pdf_ids)

  normalized <- data.frame(
    pdf_id = resolved_ids,
    ocr_text = as.character(coalesce_col(df_raw, c("ocr_text", "pdf_text", "text"))),
    ocr_status = as.character(coalesce_col(df_raw, c("ocr_status", "status"), default = "completed")),
    ocr_engine = as.character(coalesce_col(df_raw, c("ocr_engine", "engine"), default = NA_character_)),
    ocr_processed_datetime = parse_datetime_col(coalesce_col(df_raw, c("ocr_processed_datetime", "processed_at", "timestamp"))),
    ocr_confidence = as.numeric(coalesce_col(df_raw, c("ocr_confidence", "confidence"), default = NA_character_)),
    text_version = as.character(coalesce_col(df_raw, c("text_version", "pipeline_version", "version"), default = NA_character_)),
    last_updated = Sys.time(),
    stringsAsFactors = FALSE
  )

  normalized <- normalized[normalized$pdf_id != "" & !is.na(normalized$pdf_id), , drop = FALSE]
  normalized <- normalized[!duplicated(normalized$pdf_id, fromLast = TRUE), , drop = FALSE]

  existing <- init_pdf_text_columns(existing)
  if (nrow(existing)) {
    existing_keep <- existing[!existing$pdf_id %in% normalized$pdf_id, , drop = FALSE]
    combined <- bind_rows(existing_keep, normalized)
  } else {
    combined <- normalized
  }

  combined <- init_pdf_text_columns(combined)
  combined <- combined[order(combined$ocr_processed_datetime, decreasing = TRUE), , drop = FALSE]
  rownames(combined) <- NULL
  combined
}

sync_pdf_text_flags <- function(df_pdfs, df_pdf_text) {
  if (!nrow(df_pdfs)) {
    return(df_pdfs)
  }

  df_pdfs$parsed_text_available <- df_pdfs$pdf_id %in% df_pdf_text$pdf_id
  df_pdfs$last_updated <- Sys.time()
  df_pdfs
}
