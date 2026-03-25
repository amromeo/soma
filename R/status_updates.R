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
    row_idx <- which(df$pdf_id == pdf_id)
    if (!length(row_idx)) {
      return(df)
    }
    df$worked_status[row_idx] <- "worked"
    df$worked_by[row_idx] <- user
    df$worked_datetime[row_idx] <- Sys.time()
    df$pdf_status[row_idx] <- "worked"
    df
  })
}

mark_pdf_reviewed <- function(pdf_id, user = NA_character_) {
  persist_pdf_update(function(df) {
    row_idx <- which(df$pdf_id == pdf_id)
    if (!length(row_idx)) {
      return(df)
    }
    df$worked_status[row_idx] <- "reviewed"
    df$worked_by[row_idx] <- user
    df$pdf_status[row_idx] <- "reviewed"
    df
  })
}

mark_pdf_external <- function(pdf_id, user = NA_character_) {
  persist_pdf_update(function(df) {
    row_idx <- which(df$pdf_id == pdf_id)
    if (!length(row_idx)) {
      return(df)
    }
    df$worked_status[row_idx] <- "worked_outside_system"
    df$worked_by[row_idx] <- user
    df$worked_datetime[row_idx] <- Sys.time()
    df$pdf_status[row_idx] <- "worked_outside_system"
    df
  })
}

update_pdf_notes <- function(pdf_id, text) {
  persist_pdf_update(function(df) {
    row_idx <- which(df$pdf_id == pdf_id)
    if (!length(row_idx)) {
      return(df)
    }
    df$notes[row_idx] <- text
    df
  })
}

assign_pdf <- function(pdf_id, user) {
  persist_pdf_update(function(df) {
    row_idx <- which(df$pdf_id == pdf_id)
    if (!length(row_idx)) {
      return(df)
    }
    df$assigned_to[row_idx] <- user
    df
  })
}
