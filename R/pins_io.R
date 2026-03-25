library(pins)

default_pins_root <- Sys.getenv("LOCALAPPDATA", unset = "")
pins_data_dir <- if (nzchar(default_pins_root)) {
  file.path(default_pins_root, "sendout-tool", "pins_board")
} else {
  file.path(getwd(), "data", "pins_board")
}
orders_pin_name <- "sendout_orders"
pdfs_pin_name <- "sendout_pdfs"
suggestions_pin_name <- "sendout_suggestions"
pdf_text_pin_name <- "sendout_pdf_text"

empty_orders_df <- function() {
  data.frame(
    order_id = character(),
    patient_id = character(),
    patient_name = character(),
    test_name = character(),
    reference_lab = character(),
    order_datetime = as.POSIXct(character(), tz = "UTC"),
    specimen_datetime = as.POSIXct(character(), tz = "UTC"),
    expected_tat_hours = numeric(),
    lis_result_verified_datetime = as.POSIXct(character(), tz = "UTC"),
    order_status = character(),
    last_updated = as.POSIXct(character(), tz = "UTC"),
    is_verified = logical(),
    is_overdue = logical(),
    tat_verified_hours = numeric(),
    aging_hours = numeric(),
    stringsAsFactors = FALSE
  )
}

empty_pdfs_df <- function() {
  data.frame(
    pdf_id = character(),
    pdf_received_datetime = as.POSIXct(character(), tz = "UTC"),
    pdf_path = character(),
    pdf_filename = character(),
    pdf_pages = numeric(),
    pdf_source_folder = character(),
    pdf_status = character(),
    worked_status = character(),
    worked_by = character(),
    worked_datetime = as.POSIXct(character(), tz = "UTC"),
    notes = character(),
    assigned_to = character(),
    last_updated = as.POSIXct(character(), tz = "UTC"),
    parsed_text_available = logical(),
    parsed_patient_name = character(),
    parsed_patient_id = character(),
    parsed_test_name = character(),
    parsed_accession = character(),
    parsed_dates = character(),
    candidate_match_count = numeric(),
    stringsAsFactors = FALSE
  )
}

empty_suggestions_df <- function() {
  data.frame(
    suggestion_id = character(),
    pdf_id = character(),
    order_id = character(),
    suggestion_rank = numeric(),
    suggestion_score = numeric(),
    suggestion_reason = character(),
    suggestion_status = character(),
    stringsAsFactors = FALSE
  )
}

empty_pdf_text_df <- function() {
  data.frame(
    pdf_id = character(),
    ocr_text = character(),
    ocr_status = character(),
    ocr_engine = character(),
    ocr_processed_datetime = as.POSIXct(character(), tz = "UTC"),
    ocr_confidence = numeric(),
    text_version = character(),
    last_updated = as.POSIXct(character(), tz = "UTC"),
    stringsAsFactors = FALSE
  )
}

get_board <- function() {
  dir.create(pins_data_dir, recursive = TRUE, showWarnings = FALSE)
  board_folder(pins_data_dir, versioned = FALSE)
}

pin_exists_safe <- function(board, name) {
  tryCatch(!is.null(pin_meta(board, name)), error = function(...) FALSE)
}

load_or_initialize_pin <- function(name, empty_fn) {
  board <- get_board()
  if (!pin_exists_safe(board, name)) {
    df <- empty_fn()
    pin_write(board, df, name = name, type = "rds")
    return(df)
  }
  tryCatch(
    pin_read(board, name),
    error = function(...) {
      df <- empty_fn()
      pin_write(board, df, name = name, type = "rds")
      df
    }
  )
}

load_orders <- function() {
  load_or_initialize_pin(orders_pin_name, empty_orders_df)
}

load_pdfs <- function() {
  load_or_initialize_pin(pdfs_pin_name, empty_pdfs_df)
}

load_suggestions <- function() {
  load_or_initialize_pin(suggestions_pin_name, empty_suggestions_df)
}

load_pdf_text <- function() {
  load_or_initialize_pin(pdf_text_pin_name, empty_pdf_text_df)
}

write_orders <- function(df) {
  pin_write(get_board(), df, name = orders_pin_name, type = "rds")
  invisible(df)
}

write_pdfs <- function(df) {
  pin_write(get_board(), df, name = pdfs_pin_name, type = "rds")
  invisible(df)
}

write_suggestions <- function(df) {
  pin_write(get_board(), df, name = suggestions_pin_name, type = "rds")
  invisible(df)
}

write_pdf_text <- function(df) {
  pin_write(get_board(), df, name = pdf_text_pin_name, type = "rds")
  invisible(df)
}
