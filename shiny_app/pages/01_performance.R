# ============================================================================
# pages/01_performance.R - Model performance overview
# Relies on globals from app.R: test_scored, cutoffs, gini_val, ks_val,
# auc_val, overall_default, theme_cr, colours
# ============================================================================

performance_ui <- function(id) {
  ns <- NS(id)
  tagList(
    layout_columns(
      fill = FALSE,
      value_box("Gini", sprintf("%.3f", gini_val),
                showcase = bs_icon("graph-up"), theme = "secondary"),
      value_box("KS Statistic", sprintf("%.3f", ks_val),
                showcase = bs_icon("rulers"), theme = "secondary"),
      value_box("AUC", sprintf("%.3f", auc_val),
                showcase = bs_icon("bullseye"), theme = "secondary"),
      value_box("Default Rate", percent(overall_default, 0.1),
                showcase = bs_icon("exclamation-triangle"), theme = "secondary")
    ),
    layout_columns(
      card(card_header("Score Distribution"),
           plotOutput(ns("dist"), height = 320)),
      card(card_header("Default Rate by Score Band"),
           plotOutput(ns("band"), height = 320))
    ),
    card(
      card_header("Decision Policy on the Test Population"),
      plotOutput(ns("decision"), height = 300),
      DTOutput(ns("decision_tbl"))
    )
  )
}

performance_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    
    output$dist <- renderPlot({
      ggplot(test_scored, aes(score)) +
        geom_histogram(binwidth = 10, fill = gold, colour = "white", alpha = 0.9) +
        geom_vline(xintercept = c(cutoffs$decline, cutoffs$approve),
                   linetype = "dashed", colour = charcoal) +
        labs(x = "Credit Score", y = "Applicants",
             subtitle = "Dashed lines mark the decline / approve cutoffs") +
        theme_cr()
    })
    
    output$band <- renderPlot({
      test_scored %>%
        mutate(b = cut(score, breaks = seq(floor(min(score)/25)*25,
                                           ceiling(max(score)/25)*25, by = 25),
                       include.lowest = TRUE)) %>%
        group_by(b) %>% summarise(n = n(), dr = mean(target), .groups = "drop") %>%
        filter(n >= 30) %>%
        ggplot(aes(b, dr, fill = dr)) +
        geom_col(alpha = 0.9) +
        geom_text(aes(label = percent(dr, 0.1)), vjust = -0.4, size = 3) +
        scale_fill_gradient(low = risk_low, high = risk_high, guide = "none") +
        scale_y_continuous(labels = percent_format(), expand = expansion(c(0, 0.12))) +
        labs(x = "Score Band", y = "Default Rate") +
        theme_cr() + theme(axis.text.x = element_text(angle = 45, hjust = 1))
    })
    
    output$decision <- renderPlot({
      ggplot(test_scored, aes(score, fill = decision)) +
        geom_histogram(binwidth = 10, colour = "white", alpha = 0.9) +
        scale_fill_manual(values = c(DECLINE = red, REVIEW = amber, APPROVE = green)) +
        labs(x = "Credit Score", y = "Applicants", fill = NULL) +
        theme_cr()
    })
    
    output$decision_tbl <- renderDT({
      test_scored %>%
        group_by(Decision = decision) %>%
        summarise(Applicants = n(),
                  `% Population` = percent(n() / nrow(test_scored), 0.1),
                  `Default Rate` = percent(mean(target), 0.01),
                  .groups = "drop")
    }, options = list(dom = "t", ordering = FALSE), rownames = FALSE)
  })
}