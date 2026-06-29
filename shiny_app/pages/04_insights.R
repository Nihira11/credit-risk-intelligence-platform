# ============================================================================
# pages/04_insights.R - Feature influence, lift, validation, business read-out
# Relies on globals: card, model_feats, test_scored, validation,
# overall_default, pretty_name, theme_cr, colours
# ============================================================================

insights_ui <- function(id) {
  ns <- NS(id)
  tagList(
    layout_columns(
      card(card_header("Score Influence by Feature"),
           plotOutput(ns("swing"), height = 380)),
      card(card_header("Lift by Decile"),
           plotOutput(ns("lift"), height = 380))
    ),
    layout_columns(
      card(
        card_header("Model vs. Scorecard - Ranking Power"),
        DTOutput(ns("validation")),
        div(class = "note-green",
            "A scorecard is a monotonic rescaling of the model, so its",
            "Gini/KS/AUC match the model - confirming the points conversion",
            "is faithful.")
      ),
      card(
        card_header("Business Read-out"),
        uiOutput(ns("business"))
      )
    )
  )
}

insights_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    
    output$swing <- renderPlot({
      card %>% group_by(coef_name) %>%
        summarise(swing = max(points) - min(points), .groups = "drop") %>%
        semi_join(tibble(coef_name = model_feats), by = "coef_name") %>%
        arrange(desc(swing)) %>% slice_head(n = 12) %>%
        ggplot(aes(reorder(pretty_name(coef_name), swing), swing, fill = swing)) +
        geom_col(alpha = 0.9) +
        geom_text(aes(label = swing), hjust = -0.2, size = 3) +
        scale_fill_gradient(low = charcoal, high = gold, guide = "none") +
        scale_y_continuous(expand = expansion(c(0, 0.12))) +
        coord_flip() + labs(x = NULL, y = "Points swing") + theme_cr()
    })
    
    output$lift <- renderPlot({
      test_scored %>%
        mutate(decile = ntile(desc(score), 10)) %>%
        group_by(decile) %>%
        summarise(dr = mean(target), .groups = "drop") %>%
        mutate(lift = dr / overall_default) %>%
        ggplot(aes(factor(decile), lift)) +
        geom_col(fill = gold, alpha = 0.9) +
        geom_hline(yintercept = 1, linetype = "dashed", colour = charcoal) +
        geom_text(aes(label = sprintf("%.1fx", lift)), vjust = -0.4, size = 3) +
        scale_y_continuous(expand = expansion(c(0, 0.12))) +
        labs(x = "Risk Decile (1 = highest risk)", y = "Lift vs. average") +
        theme_cr()
    })
    
    output$validation <- renderDT({
      validation
    }, options = list(dom = "t", ordering = FALSE), rownames = FALSE)
    
    output$business <- renderUI({
      appr <- test_scored %>% filter(decision == "APPROVE")
      decl <- test_scored %>% filter(decision == "DECLINE")
      appr_rate <- if (nrow(appr) > 0) percent(nrow(appr)/nrow(test_scored), 0.1) else "0%"
      appr_dr   <- if (nrow(appr) > 0) percent(mean(appr$target), 0.01) else "-"
      decl_catch <- if (nrow(decl) > 0)
        percent(sum(decl$target)/sum(test_scored$target), 0.1) else "0%"
      tags$ul(
        tags$li(sprintf("Auto-approve rate: %s of applicants", appr_rate)),
        tags$li(sprintf("Approved-band default rate: %s (vs %s overall)",
                        appr_dr, percent(overall_default, 0.01))),
        tags$li(sprintf("Decline band captures %s of all defaults", decl_catch)),
        tags$li("Cutoffs are tuned to this model's score range; adjust to trade",
                "approval volume against expected loss.")
      )
    })
  })
}