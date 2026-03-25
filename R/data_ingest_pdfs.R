library(dplyr)

init_pdf_columns <- function(df) {
  defaults <- empty_pdfs_df()
  for (col in names(defaults)) {
    if (!col %in% names(df)) {
      df[[col]] <- defaults[[col]]
    }
  }
  df[, names(defaults), drop = FALSE]
}

ingest_pdfs <- function(df_raw, existing = load_pdfs()) {
  if (missing(df_raw) || is.null(df_raw) || !nrow(df_raw)) {
    return(init_pdf_columns(existing))
  }

  path_values <- as.character(coalesce_col(df_raw, c("pdf_path", "path", "full_path", "file_path")))
  normalized <- data.frame(
    pdf_id = if ("pdf_id" %in% names(df_raw)) as.character(df_raw$pdf_id) else vapply(path_values, derive_pdf_id, character(1)),
    pdf_received_datetime = parse_datetime_col(coalesce_col(df_raw, c("pdf_received_datetime", "received_timestamp", "received_at", "timestamp"))),
    pdf_path = path_values,
    pdf_filename = as.character(coalesce_col(df_raw, c("pdf_filename", "filename", "file_name"))),
    pdf_pages = as.numeric(coalesce_col(df_raw, c("pdf_pages", "pages", "page_count"), default = NA_character_)),
    pdf_source_folder = as.character(coalesce_col(df_raw, c("pdf_source_folder", "source_folder", "folder"))),
    pdf_status = as.character(coalesce_col(df_raw, c("pdf_status", "status"), default = "received")),
    worked_status = "new",
    worked_by = NA_character_,
    worked_datetime = as.POSIXct(NA, origin = "1970-01-01", tz = "UTC"),
    notes = "",
    assigned_to = NA_character_,
    last_updated = Sys.time(),
    parsed_text_available = FALSE,
    parsed_patient_name = NA_character_,
    parsed_patient_id = NA_character_,
    parsed_test_name = NA_character_,
    parsed_accession = NA_character_,
    parsed_dates = NA_character_,
    candidate_match_count = NA_real_,
    stringsAsFactors = FALSE
  )

  normalized$pdf_filename[normalized$pdf_filename == "" | is.na(normalized$pdf_filename)] <- basename(normalized$pdf_path)
  normalized$pdf_source_folder[normalized$pdf_source_folder == "" | is.na(normalized$pdf_source_folder)] <- dirname(normalized$pdf_path)
  normalized <- normalized[normalized$pdf_path != "" & !is.na(normalized$pdf_path), , drop = FALSE]
  normalized <- normalized[!duplicated(normalized$pdf_id, fromLast = TRUE), , drop = FALSE]

  existing <- init_pdf_columns(existing)
  if (nrow(existing)) {
    preserved_cols <- c("worked_status", "worked_by", "worked_datetime", "notes", "assigned_to")
    preserved <- existing[, c("pdf_id", preserved_cols), drop = FALSE]
    normalized <- normalized %>%
      left_join(preserved, by = "pdf_id", suffix = c("", ".preserved")) %>%
      mutate(
        worked_status = coalesce(worked_status.preserved, worked_status),
        worked_by = coalesce(worked_by.preserved, worked_by),
        worked_datetime = coalesce(worked_datetime.preserved, worked_datetime),
        notes = coalesce(notes.preserved, notes),
        assigned_to = coalesce(assigned_to.preserved, assigned_to)
      ) %>%
      select(-ends_with(".preserved"))

    existing_keep <- existing[!existing$pdf_id %in% normalized$pdf_id, , drop = FALSE]
    combined <- bind_rows(existing_keep, normalized)
  } else {
    combined <- normalized
  }

  combined <- init_pdf_columns(combined)
  combined <- combined[order(combined$pdf_received_datetime, decreasing = TRUE), , drop = FALSE]
  rownames(combined) <- NULL
  combined
}
