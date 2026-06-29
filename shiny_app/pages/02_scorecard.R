# ============================================================================
# pages/02_scorecard.R - Browse the bin-level points card
# Relies on globals: card, model_feats, top_drivers, pretty_name, theme_cr,
# colours
# ============================================================================

scorecard_ui <- function(id) {
  ns <- NS(id)
  layout_sidebar(
    sidebar = sidebar(
      title = "Browse the card",
      selectInput(ns("feat"), "Feature",
                  choices = setNames(model_feats, pretty_name(model_feats)),
                  selected = top_drivers[1]),
      helpText("Each WOE bin of a feature is worth a fixed number of points.",
               "Higher points = lower risk contribution.")
    ),
    card(card_header(textOutput(ns("title"))),
         plotOutput(ns("plot"), height = 320)),
    card(card_header("Full Points Card"),
         DTOutput(ns("tbl")))
  )
}

scorecard_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    
    output$title <- renderText(paste("Points by bin -", pretty_name(input$feat)))
    
    output$plot <- renderPlot({
      card %>% filter(coef_name == input$feat) %>%
        mutate(bin = factor(bin, levels = bin[order(woe)])) %>%
        ggplot(aes(bin, points, fill = points)) +
        geom_col(alpha = 0.9) +
        geom_text(aes(label = points),
                  vjust = ifelse(card$points[card$coef_name == input$feat] >= 0, -0.4, 1.2),
                  size = 3.2) +
        scale_fill_gradient(low = risk_high, high = risk_low, guide = "none") +
        labs(x = "WOE Bin", y = "Points") +
        theme_cr() + theme(axis.text.x = element_text(angle = 30, hjust = 1))
    })
    
    output$tbl <- renderDT({
      card %>%
        transmute(Feature = pretty_name(coef_name), Bin = bin,
                  WOE = round(woe, 3), Beta = round(beta, 3), Points = points)
    }, options = list(pageLength = 12), rownames = FALSE, filter = "top")
  })
}