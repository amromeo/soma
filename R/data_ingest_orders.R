library(dplyr)

normalize_expected_tat_hours <- function(df) {
  if ("expected_tat_hours" %in% names(df)) {
    return(as.numeric(df$expected_tat_hours))
  }
  if ("expected_tat_days" %in% names(df)) {
    return(as.numeric(df$expected_tat_days) * 24)
  }
  rep(NA_real_, nrow(df))
}

coalesce_col <- function(df, candidates, default = NA_character_) {
  for (candidate in candidates) {
    if (candidate %in% names(df)) {
      return(df[[candidate]])
    }
  }
  rep(default, nrow(df))
}

parse_datetime_col <- function(x) {
  if (inherits(x, "POSIXt")) {
    return(as.POSIXct(x, tz = "UTC"))
  }
  if (is.factor(x)) {
    x <- as.character(x)
  }
  if (is.character(x)) {
    x <- trimws(x)
    x[x == ""] <- NA_character_
  }
  parsed <- suppressWarnings(as.POSIXct(x, tz = "UTC"))
  if (all(is.na(parsed)) && inherits(x, "Date")) {
    return(as.POSIXct(x, tz = "UTC"))
  }
  parsed
}

compute_order_metrics <- function(df) {
  if (!nrow(df)) {
    return(df)
  }

  now_time <- Sys.time()
  df %>%
    mutate(
      is_verified = !is.na(lis_result_verified_datetime),
      aging_hours = dplyr::if_else(
        is_verified,
        as.numeric(difftime(lis_result_verified_datetime, order_datetime, units = "hours")),
        as.numeric(difftime(now_time, order_datetime, units = "hours"))
      ),
      tat_verified_hours = as.numeric(difftime(lis_result_verified_datetime, order_datetime, units = "hours")),
      is_overdue = !is_verified & !is.na(expected_tat_hours) & aging_hours > expected_tat_hours,
      last_updated = as.POSIXct(last_updated, tz = "UTC")
    )
}

ingest_orders <- function(df_raw, existing = load_orders()) {
  if (missing(df_raw) || is.null(df_raw) || !nrow(df_raw)) {
    return(compute_order_metrics(existing))
  }

  normalized <- data.frame(
    order_id = as.character(coalesce_col(df_raw, c("order_id", "orderid", "accession_number"))),
    patient_id = as.character(coalesce_col(df_raw, c("patient_id", "mrn", "patient_mrn"))),
    patient_name = as.character(coalesce_col(df_raw, c("patient_name", "patient"))),
    test_name = as.character(coalesce_col(df_raw, c("test_name", "test", "procedure_name"))),
    reference_lab = as.character(coalesce_col(df_raw, c("reference_lab", "performing_lab", "lab"))),
    order_datetime = parse_datetime_col(coalesce_col(df_raw, c("order_datetime", "ordered_at", "order_date"))),
    specimen_datetime = parse_datetime_col(coalesce_col(df_raw, c("specimen_datetime", "collected_at", "specimen_date"))),
    expected_tat_hours = normalize_expected_tat_hours(df_raw),
    lis_result_verified_datetime = parse_datetime_col(coalesce_col(df_raw, c("lis_result_verified_datetime", "verified_datetime", "result_verified_at"))),
    order_status = as.character(coalesce_col(df_raw, c("order_status", "status"), default = "pending")),
    last_updated = Sys.time(),
    stringsAsFactors = FALSE
  )

  normalized <- normalized[normalized$order_id != "" & !is.na(normalized$order_id), , drop = FALSE]
  normalized <- normalized[!duplicated(normalized$order_id, fromLast = TRUE), , drop = FALSE]

  if (!nrow(existing)) {
    merged <- normalized
  } else {
    existing_base <- existing[, intersect(names(existing), names(normalized)), drop = FALSE]
    if (!"last_updated" %in% names(existing_base)) {
      existing_base$last_updated <- Sys.time()
    }
    existing_keep <- existing_base[!existing_base$order_id %in% normalized$order_id, , drop = FALSE]
    merged <- bind_rows(existing_keep[, names(normalized), drop = FALSE], normalized)
  }

  merged <- compute_order_metrics(merged)
  merged <- merged[order(merged$order_datetime, decreasing = TRUE), , drop = FALSE]
  rownames(merged) <- NULL
  merged
}
