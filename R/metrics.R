library(dplyr)

calc_order_metrics <- function(df_orders) {
  df_orders <- compute_order_metrics(df_orders)

  tat_by_lab <- df_orders %>%
    filter(is_verified, !is.na(tat_verified_hours)) %>%
    group_by(reference_lab) %>%
    summarise(median_tat_hours = median(tat_verified_hours, na.rm = TRUE), verified_orders = n(), .groups = "drop") %>%
    arrange(desc(verified_orders))

  tat_by_test <- df_orders %>%
    filter(is_verified, !is.na(tat_verified_hours)) %>%
    group_by(test_name) %>%
    summarise(median_tat_hours = median(tat_verified_hours, na.rm = TRUE), verified_orders = n(), .groups = "drop") %>%
    arrange(desc(verified_orders))

  daily_orders <- df_orders %>%
    filter(!is.na(order_datetime)) %>%
    mutate(order_date = as.Date(order_datetime)) %>%
    count(order_date, name = "orders") %>%
    arrange(order_date)

  list(
    pending_count = sum(!df_orders$is_verified, na.rm = TRUE),
    overdue_count = sum(df_orders$is_overdue, na.rm = TRUE),
    median_tat_overall = median(df_orders$tat_verified_hours[df_orders$is_verified], na.rm = TRUE),
    tat_by_lab = tat_by_lab,
    tat_by_test = tat_by_test,
    daily_orders = daily_orders
  )
}

calc_pdf_metrics <- function(df_pdfs, recent_window_hours = 72) {
  if (!nrow(df_pdfs)) {
    return(list(
      recent_pdf_count = 0,
      worked_pdf_count = 0,
      pdf_count = 0,
      worked_percent = NA_real_,
      median_work_lag_hours = NA_real_,
      daily_pdfs = data.frame(pdf_date = as.Date(character()), pdfs = numeric())
    ))
  }

  recent_cutoff <- Sys.time() - as.difftime(recent_window_hours, units = "hours")
  work_lag_hours <- as.numeric(difftime(df_pdfs$worked_datetime, df_pdfs$pdf_received_datetime, units = "hours"))
  worked_mask <- df_pdfs$worked_status %in% c("worked", "worked_outside_system")

  daily_pdfs <- df_pdfs %>%
    filter(!is.na(pdf_received_datetime)) %>%
    mutate(pdf_date = as.Date(pdf_received_datetime)) %>%
    count(pdf_date, name = "pdfs") %>%
    arrange(pdf_date)

  list(
    recent_pdf_count = sum(df_pdfs$pdf_received_datetime >= recent_cutoff, na.rm = TRUE),
    worked_pdf_count = sum(worked_mask, na.rm = TRUE),
    pdf_count = nrow(df_pdfs),
    worked_percent = mean(worked_mask, na.rm = TRUE),
    median_work_lag_hours = median(work_lag_hours[worked_mask], na.rm = TRUE),
    daily_pdfs = daily_pdfs
  )
}

calc_summary <- function(df_orders, df_pdfs, recent_window_hours = 72) {
  order_metrics <- calc_order_metrics(df_orders)
  pdf_metrics <- calc_pdf_metrics(df_pdfs, recent_window_hours = recent_window_hours)

  list(
    summary = c(
      order_metrics[c("pending_count", "overdue_count", "median_tat_overall")],
      pdf_metrics[c("recent_pdf_count", "worked_pdf_count", "pdf_count", "worked_percent", "median_work_lag_hours")]
    ),
    tat_by_lab = order_metrics$tat_by_lab,
    tat_by_test = order_metrics$tat_by_test,
    daily_orders = order_metrics$daily_orders,
    daily_pdfs = pdf_metrics$daily_pdfs
  )
}
