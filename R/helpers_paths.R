`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0 || (length(x) == 1 && is.na(x))) y else x
}

safe_null <- function(x) {
  if (is.null(x) || length(x) == 0) NA else x
}

format_datetime <- function(x, tz = Sys.timezone()) {
  if (inherits(x, "POSIXt")) {
    return(format(x, "%Y-%m-%d %H:%M", tz = tz))
  }
  x
}

derive_pdf_id <- function(path) {
  normalized <- normalizePath(path, winslash = "/", mustWork = FALSE)
  digest::digest(normalized, algo = "xxhash64")
}

open_pdf <- function(path) {
  normalized <- normalizePath(path, winslash = "/", mustWork = FALSE)
  exists <- file.exists(normalized)

  if (!exists) {
    return(list(success = FALSE, path = normalized, message = "File does not exist"))
  }

  success <- FALSE
  os_name <- Sys.info()[["sysname"]]

  if (identical(os_name, "Windows")) {
    success <- isTRUE(tryCatch(shell.exec(normalized), error = function(...) FALSE))
  } else if (identical(os_name, "Darwin")) {
    success <- identical(system2("open", shQuote(normalized), wait = FALSE), 0L)
  } else {
    success <- identical(system2("xdg-open", shQuote(normalized), wait = FALSE), 0L)
  }

  list(success = success, path = normalized, message = if (success) "Opened" else "Unable to open automatically")
}

metric_value_box <- function(title, value, tone = c("primary", "warning", "danger", "success")) {
  tone <- match.arg(tone)
  div(
    class = paste("metric-box", paste0("metric-", tone)),
    div(class = "metric-label", title),
    div(class = "metric-value", value)
  )
}
