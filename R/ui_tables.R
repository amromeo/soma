library(DT)

status_badge <- function(value, type = c("pdf", "order")) {
  type <- match.arg(type)
  badge_class <- if (type == "pdf") {
    switch(
      value,
      new = "badge-new",
      reviewed = "badge-reviewed",
      worked = "badge-worked",
      worked_outside_system = "badge-external",
      archived = "badge-archived",
      "badge-neutral"
    )
  } else {
    if (identical(value, "overdue")) "badge-overdue" else "badge-neutral"
  }
  as.character(tags$span(class = paste("status-badge", badge_class), value))
}

pdf_action_buttons <- function(pdf_id) {
  actions <- list(
    list("open", "Open"),
    list("reviewed", "Reviewed"),
    list("worked", "Worked"),
    list("external", "Worked outside"),
    list("assign", "Assign"),
    list("notes", "Notes")
  )

  html <- vapply(actions, function(action) {
    sprintf(
      "<button type='button' class='btn btn-sm btn-outline-secondary pdf-action' data-action='%s' data-pdf-id='%s'>%s</button>",
      action[[1]], pdf_id, action[[2]]
    )
  }, character(1))

  paste(html, collapse = " ")
}

table_recent_pdfs <- function(df) {
  if (!nrow(df)) {
    df <- empty_pdfs_df()
  }

  display <- data.frame(
    received_datetime = format_datetime(df$pdf_received_datetime),
    filename = df$pdf_filename,
    pdf_path = df$pdf_path,
    pages = df$pdf_pages,
    worked_status = vapply(df$worked_status, status_badge, character(1), type = "pdf"),
    assigned_to = ifelse(is.na(df$assigned_to), "", df$assigned_to),
    notes = df$notes,
    actions = vapply(df$pdf_id, pdf_action_buttons, character(1)),
    stringsAsFactors = FALSE
  )

  datatable(
    display,
    escape = FALSE,
    rownames = FALSE,
    filter = "top",
    options = list(pageLength = 10, scrollX = TRUE, order = list(list(0, "desc"))),
    colnames = c("Received", "Filename", "Path", "Pages", "Status", "Assigned To", "Notes", "Actions")
  )
}

table_pending_orders <- function(df) {
  display <- data.frame(
    order_id = df$order_id,
    patient = ifelse(df$patient_name == "" | is.na(df$patient_name), df$patient_id, df$patient_name),
    test_name = df$test_name,
    reference_lab = df$reference_lab,
    order_datetime = format_datetime(df$order_datetime),
    expected_tat_hours = round(df$expected_tat_hours, 1),
    aging_hours = round(df$aging_hours, 1),
    overdue = ifelse(df$is_overdue, status_badge("overdue", "order"), status_badge("on_time", "order")),
    stringsAsFactors = FALSE
  )

  datatable(
    display,
    escape = FALSE,
    rownames = FALSE,
    filter = "top",
    options = list(pageLength = 12, scrollX = TRUE, order = list(list(6, "desc"))),
    colnames = c("Order ID", "Patient", "Test", "Reference Lab", "Ordered", "Expected TAT (hrs)", "Aging (hrs)", "Flag")
  )
}

table_overdue_orders <- function(df) {
  display <- data.frame(
    order_id = df$order_id,
    patient = ifelse(df$patient_name == "" | is.na(df$patient_name), df$patient_id, df$patient_name),
    test_name = df$test_name,
    reference_lab = df$reference_lab,
    order_datetime = format_datetime(df$order_datetime),
    expected_tat_hours = round(df$expected_tat_hours, 1),
    aging_hours = round(df$aging_hours, 1),
    overdue_by_hours = round(df$aging_hours - df$expected_tat_hours, 1),
    stringsAsFactors = FALSE
  )

  datatable(
    display,
    rownames = FALSE,
    filter = "top",
    options = list(pageLength = 12, scrollX = TRUE, order = list(list(7, "desc"))),
    colnames = c("Order ID", "Patient", "Test", "Reference Lab", "Ordered", "Expected TAT (hrs)", "Aging (hrs)", "Overdue By (hrs)")
  )
}

table_metrics_group <- function(df, group_label) {
  if (!nrow(df)) {
    df <- data.frame(value = character(), median_tat_hours = numeric(), verified_orders = numeric())
    names(df)[1] <- group_label
  }

  datatable(
    df,
    rownames = FALSE,
    options = list(pageLength = 8, dom = "tip", scrollX = TRUE),
    colnames = c(gsub("_", " ", group_label), "Median TAT (hrs)", "Verified Orders")
  )
}
