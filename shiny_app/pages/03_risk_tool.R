# ============================================================================
# pages/03_risk_tool.R - Interactive applicant scoring
# Relies on globals: test_woe, test_scored, model_feats, top_drivers,
# feat_stats, median_woe_vec, coefs, scaling, cutoffs, score_from_woe,
# prob_from_woe, decide, pretty_name, theme_cr, colours
# ============================================================================

risk_tool_ui <- function(id) {
  ns <- NS(id)
  layout_sidebar(
    sidebar = sidebar(
      width = 360,
      title = "Score an applicant",
      div(
        actionButton(ns("load_random"), "Load random applicant",
                     class = "btn-secondary btn-sm", width = "100%"),
        br(), br(),
        layout_columns(
          actionButton(ns("load_low"), "Low-risk sample", class = "btn-sm"),
          actionButton(ns("load_high"), "High-risk sample", class = "btn-sm")
        )
      ),
      hr(),
      helpText("Adjust the top risk drivers (in WOE units). Other features",
               "stay at the loaded applicant's values, or the population median."),
      uiOutput(ns("sliders"))
    ),
    layout_columns(
      col_widths = c(5, 7),
      card(
        card_header("Decision"),
        div(class = "decision-box",
            uiOutput(ns("score_big")),
            uiOutput(ns("decision_badge")),
            uiOutput(ns("prob")))
      ),
      card(
        card_header("Points Breakdown"),
        plotOutput(ns("breakdown"), height = 360)
      )
    )
  )
}

risk_tool_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    rv <- reactiveValues(woe = median_woe_vec, actual = NULL)
    
    output$sliders <- renderUI({
      lapply(top_drivers, function(f) {
        rng <- feat_stats[feat_stats$feature == f, ]
        # round endpoints outward to clean 0.1 boundaries so the auto-generated
        # tick labels sit on round numbers and don't crowd at the edges
        lo <- floor(rng$min_woe * 10) / 10
        hi <- ceiling(rng$max_woe * 10) / 10
        sliderInput(ns(paste0("sl_", f)), pretty_name(f),
                    min = lo, max = hi,
                    value = round(rv$woe[[f]], 2), step = 0.05)
      })
    })
    
    # collect the six slider values into one reactive, debounced so the score
    # and chart recompute only after the user stops dragging (not on every pixel)
    slider_vals <- reactive({
      sapply(top_drivers, function(f) input[[paste0("sl_", f)]])
    })
    slider_vals_d <- debounce(slider_vals, 250)
    
    observeEvent(slider_vals_d(), {
      vals <- slider_vals_d()
      for (f in top_drivers) {
        v <- vals[[f]]
        if (!is.null(v) && !is.na(v)) rv$woe[[f]] <- v
      }
    }, ignoreNULL = TRUE)
    
    load_sample <- function(rows) {
      idx <- sample(rows, 1)
      row <- test_woe[idx, ]
      v <- median_woe_vec
      for (f in model_feats) v[[f]] <- as.numeric(row[[f]])
      rv$woe <- v
      rv$actual <- test_scored$target[idx]
      for (f in top_drivers) {
        updateSliderInput(session, paste0("sl_", f),
                          value = round(v[[f]] / 0.05) * 0.05)
      }
    }
    
    observeEvent(input$load_random, load_sample(seq_len(nrow(test_woe))))
    observeEvent(input$load_low,
                 load_sample(which(test_scored$score >= quantile(test_scored$score, 0.85))))
    observeEvent(input$load_high,
                 load_sample(which(test_scored$score <= quantile(test_scored$score, 0.15))))
    
    current_score <- reactive(score_from_woe(rv$woe, coefs, scaling))
    current_prob  <- reactive(prob_from_woe(rv$woe, coefs))
    current_dec   <- reactive(decide(current_score(), cutoffs))
    
    output$score_big <- renderUI({
      div(class = "score-big", current_score())
    })
    
    output$decision_badge <- renderUI({
      d <- current_dec()
      col <- c(DECLINE = red, REVIEW = amber, APPROVE = green)[d]
      div(class = "decision-badge",
          style = paste0("background:", col, ";"), d)
    })
    
    output$prob <- renderUI({
      actual_txt <- if (!is.null(rv$actual))
        sprintf(" · actual outcome: %s",
                ifelse(rv$actual == 1, "defaulted", "repaid")) else ""
      div(class = "prob-line",
          sprintf("Predicted default probability: %s%s",
                  percent(current_prob(), 0.01), actual_txt))
    })
    
    output$breakdown <- renderPlot({
      w <- rv$woe
      betas <- coefs[names(coefs) != "(Intercept)"]
      betas <- betas[!is.na(betas)]
      feats <- intersect(names(betas), model_feats)
      base_per_feat <- (scaling$offset - scaling$factor * coefs[["(Intercept)"]]) / length(feats)
      tibble(
        feature = pretty_name(feats),
        points = round(base_per_feat - scaling$factor * betas[feats] * as.numeric(w[feats]))
      ) %>%
        arrange(desc(points)) %>%
        mutate(feature = factor(feature, levels = feature)) %>%
        ggplot(aes(feature, points, fill = points)) +
        geom_col(alpha = 0.9) +
        scale_fill_gradient(low = risk_high, high = risk_low, guide = "none") +
        coord_flip() +
        labs(x = NULL, y = "Points contributed") +
        theme_cr()
    })
  })
}