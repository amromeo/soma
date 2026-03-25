library(dplyr)

persist_pdf_update <- function(mutator) {
  df <- load_pdfs()
  updated <- mutator(df)
  updated$last_updated <- Sys.time()
  write_pdfs(updated)
  updated
}

mark_pdf_worked <- function(pdf_id, user = NA_character_) {
  persist_pdf_update(function(df) {
    df %>%
      mutate(
        worked_status = if_else(.data$pdf_id == pdf_id, "worked", .data$worked_status),
        worked_by = if_else(.data$pdf_id == pdf_id, user, .data$worked_by),
        worked_datetime = if_else(.data$pdf_id == pdf_id, Sys.time(), .data$worked_datetime),
        pdf_status = if_else(.data$pdf_id == pdf_id, "worked", .data$pdf_status)
      )
  })
}

mark_pdf_reviewed <- function(pdf_id, user = NA_character_) {
  persist_pdf_update(function(df) {
    df %>%
      mutate(
        worked_status = if_else(.data$pdf_id == pdf_id, "reviewed", .data$worked_status),
        worked_by = if_else(.data$pdf_id == pdf_id, user, .data$worked_by),
        pdf_status = if_else(.data$pdf_id == pdf_id, "reviewed", .data$pdf_status)
      )
  })
}

mark_pdf_external <- function(pdf_id, user = NA_character_) {
  persist_pdf_update(function(df) {
    df %>%
      mutate(
        worked_status = if_else(.data$pdf_id == pdf_id, "worked_outside_system", .data$worked_status),
        worked_by = if_else(.data$pdf_id == pdf_id, user, .data$worked_by),
        worked_datetime = if_else(.data$pdf_id == pdf_id, Sys.time(), .data$worked_datetime),
        pdf_status = if_else(.data$pdf_id == pdf_id, "worked_outside_system", .data$pdf_status)
      )
  })
}

update_pdf_notes <- function(pdf_id, text) {
  persist_pdf_update(function(df) {
    df %>%
      mutate(notes = if_else(.data$pdf_id == pdf_id, text, .data$notes))
  })
}

assign_pdf <- function(pdf_id, user) {
  persist_pdf_update(function(df) {
    df %>%
      mutate(assigned_to = if_else(.data$pdf_id == pdf_id, user, .data$assigned_to))
  })
}
