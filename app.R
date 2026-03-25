library(shiny)
library(bslib)
library(DT)
library(ggplot2)

source_files <- list.files("R", pattern = "\\.[Rr]$", full.names = TRUE)
invisible(lapply(source_files, source))

recent_window_hours_default <- 72

ui <- page_fluid(
  theme = bs_theme(version = 5, bootswatch = "flatly"),
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "styles.css"),
    tags$script(HTML("
      $(document).on('click', '.pdf-action', function() {
        const payload = {
          action: $(this).data('action'),
          pdf_id: $(this).data('pdf-id'),
          nonce: Date.now()
        };
        Shiny.setInputValue('pdf_row_action', payload, {priority: 'event'});
      });
    "))
  ),
  titlePanel("Send-Out Tracking Workstation"),
  fluidRow(
    column(
      width = 9,
      div(
        class = "app-intro",
        h4("Operational view for pending send-outs and inbound PDFs"),
        p("Use this workstation to triage recently received results, monitor overdue orders, and capture work that happened inside or outside the app.")
      )
    ),
    column(
      width = 3,
      div(
        class = "toolbar-card",
        textInput("current_user", "Working as", value = Sys.getenv("USERNAME", unset = "Lab User")),
        numericInput("recent_window_hours", "Recent PDF window (hours)", value = recent_window_hours_default, min = 1, max = 720, step = 1),
        actionButton("refresh_data", "Reload from pins", class = "btn-primary btn-sm")
      )
    )
  ),
  navset_tab(
    id = "main_tabs",
    nav_panel("Recently Received", fluidRow(column(width = 12, div(class = "panel-card", DTOutput("recent_pdfs_table"))))),
    nav_panel("Pending", fluidRow(column(width = 12, div(class = "panel-card", DTOutput("pending_orders_table"))))),
    nav_panel(
      "Overdue",
      fluidRow(
        column(width = 3, div(class = "panel-card", selectInput("overdue_lab_filter", "Reference lab", choices = "All", selected = "All"), uiOutput("overdue_summary"))),
        column(width = 9, div(class = "panel-card", DTOutput("overdue_orders_table")))
      )
    ),
    nav_panel(
      "Metrics",
      fluidRow(
        column(width = 3, uiOutput("value_box_pending")),
        column(width = 3, uiOutput("value_box_recent")),
        column(width = 3, uiOutput("value_box_overdue")),
        column(width = 3, uiOutput("value_box_worked"))
      ),
      fluidRow(
        column(width = 6, div(class = "panel-card", plotOutput("orders_trend_plot", height = 260))),
        column(width = 6, div(class = "panel-card", plotOutput("pdf_trend_plot", height = 260)))
      ),
      fluidRow(
        column(width = 6, div(class = "panel-card", DTOutput("metrics_lab_table"))),
        column(width = 6, div(class = "panel-card", DTOutput("metrics_test_table")))
      )
    ),
    nav_panel(
      "Matching",
      div(
        class = "panel-card placeholder-card",
        h4("Candidate matching placeholder"),
        p("Candidate matching will appear here once PDF parsing can propose likely order links.")
      )
    )
  )
)

server <- function(input, output, session) {
  values <- reactiveValues(
    orders = load_orders(),
    pdfs = load_pdfs(),
    suggestions = load_suggestions(),
    pdf_text = load_pdf_text()
  )

  refresh_all <- function() {
    values$orders <- load_orders()
    values$pdfs <- load_pdfs()
    values$suggestions <- load_suggestions()
    values$pdf_text <- load_pdf_text()
  }

  observeEvent(input$refresh_data, {
    refresh_all()
    showNotification("Data reloaded from pins.", type = "message")
  })

  observe({
    labs <- sort(unique(stats::na.omit(values$orders$reference_lab)))
    updateSelectInput(session, "overdue_lab_filter", choices = c("All", labs), selected = "All")
  })

  recent_pdfs <- reactive({
    cutoff <- Sys.time() - as.difftime(input$recent_window_hours %||% recent_window_hours_default, units = "hours")
    df <- values$pdfs
    df[df$pdf_received_datetime >= cutoff, , drop = FALSE]
  })

  pending_orders <- reactive({
    df <- values$orders
    df[!df$is_verified, , drop = FALSE]
  })

  overdue_orders <- reactive({
    df <- values$orders
    df <- df[df$is_overdue, , drop = FALSE]
    if (!identical(input$overdue_lab_filter, "All")) {
      df <- df[df$reference_lab == input$overdue_lab_filter, , drop = FALSE]
    }
    df[order(df$aging_hours, decreasing = TRUE), , drop = FALSE]
  })

  metrics_bundle <- reactive({
    calc_summary(values$orders, values$pdfs, recent_window_hours = input$recent_window_hours %||% recent_window_hours_default)
  })

  output$recent_pdfs_table <- renderDT({
    table_recent_pdfs(recent_pdfs())
  })

  output$pending_orders_table <- renderDT({
    table_pending_orders(pending_orders())
  })

  output$overdue_orders_table <- renderDT({
    table_overdue_orders(overdue_orders())
  })

  output$metrics_lab_table <- renderDT({
    table_metrics_group(metrics_bundle()$tat_by_lab, group_label = "reference_lab")
  })

  output$metrics_test_table <- renderDT({
    table_metrics_group(metrics_bundle()$tat_by_test, group_label = "test_name")
  })

  output$overdue_summary <- renderUI({
    df <- overdue_orders()
    tagList(
      div(class = "summary-stat", span("Overdue orders"), strong(nrow(df))),
      div(class = "summary-stat", span("Oldest aging (hrs)"), strong(if (nrow(df)) round(max(df$aging_hours, na.rm = TRUE), 1) else 0))
    )
  })

  output$value_box_pending <- renderUI({
    metric_value_box("Pending send-outs", metrics_bundle()$summary$pending_count, "warning")
  })

  output$value_box_recent <- renderUI({
    metric_value_box("Recent PDFs", metrics_bundle()$summary$recent_pdf_count, "primary")
  })

  output$value_box_overdue <- renderUI({
    metric_value_box("Overdue orders", metrics_bundle()$summary$overdue_count, "danger")
  })

  output$value_box_worked <- renderUI({
    worked_label <- paste0(metrics_bundle()$summary$worked_pdf_count, " / ", metrics_bundle()$summary$pdf_count)
    metric_value_box("Worked PDFs", worked_label, "success")
  })

  output$orders_trend_plot <- renderPlot({
    df <- metrics_bundle()$daily_orders
    validate(need(nrow(df) > 0, "No order activity available yet."))
    ggplot(df, aes(x = order_date, y = orders)) +
      geom_col(fill = "#1f6f8b") +
      labs(x = NULL, y = "Orders", title = "Order volume by day") +
      theme_minimal(base_size = 12)
  })

  output$pdf_trend_plot <- renderPlot({
    df <- metrics_bundle()$daily_pdfs
    validate(need(nrow(df) > 0, "No PDF activity available yet."))
    ggplot(df, aes(x = pdf_date, y = pdfs)) +
      geom_col(fill = "#3d8b37") +
      labs(x = NULL, y = "PDFs", title = "PDF receipts by day") +
      theme_minimal(base_size = 12)
  })

  observeEvent(input$pdf_row_action, {
    action <- input$pdf_row_action$action
    pdf_id <- input$pdf_row_action$pdf_id
    user <- input$current_user %||% "Unknown"

    if (identical(action, "open")) {
      path <- values$pdfs$pdf_path[match(pdf_id, values$pdfs$pdf_id)]
      result <- open_pdf(path)
      if (!isTRUE(result$success)) {
        showNotification(paste("Unable to open automatically. Path:", result$path), type = "warning", duration = 8)
      }
      return(invisible(NULL))
    }

    if (identical(action, "reviewed")) {
      values$pdfs <- mark_pdf_reviewed(pdf_id, user = user)
      showNotification("PDF marked reviewed.", type = "message")
      return(invisible(NULL))
    }

    if (identical(action, "worked")) {
      values$pdfs <- mark_pdf_worked(pdf_id, user = user)
      showNotification("PDF marked worked.", type = "message")
      return(invisible(NULL))
    }

    if (identical(action, "external")) {
      values$pdfs <- mark_pdf_external(pdf_id, user = user)
      showNotification("PDF marked worked outside system.", type = "message")
      return(invisible(NULL))
    }

    if (identical(action, "assign")) {
      showModal(modalDialog(
        title = "Assign PDF",
        textInput("assign_user_modal", "Assign to", value = values$pdfs$assigned_to[match(pdf_id, values$pdfs$pdf_id)] %||% user),
        footer = tagList(modalButton("Cancel"), actionButton("save_assign_modal", "Save assignment", class = "btn-primary"))
      ))

      observeEvent(input$save_assign_modal, {
        removeModal()
        values$pdfs <- assign_pdf(pdf_id, input$assign_user_modal)
        showNotification("Assignment updated.", type = "message")
      }, once = TRUE)
      return(invisible(NULL))
    }

    if (identical(action, "notes")) {
      current_note <- values$pdfs$notes[match(pdf_id, values$pdfs$pdf_id)] %||% ""
      showModal(modalDialog(
        title = "Edit notes",
        textAreaInput("notes_modal", "Notes", value = current_note, rows = 6, width = "100%"),
        footer = tagList(modalButton("Cancel"), actionButton("save_notes_modal", "Save notes", class = "btn-primary")),
        size = "m"
      ))

      observeEvent(input$save_notes_modal, {
        removeModal()
        values$pdfs <- update_pdf_notes(pdf_id, input$notes_modal)
        showNotification("Notes saved.", type = "message")
      }, once = TRUE)
    }
  })
}

shinyApp(ui, server)
