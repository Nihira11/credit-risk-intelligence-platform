# ============================================================================
# pages/theme.R - Brand palette & theme  (Slate & Teal)
# Central place for the dashboard's colours and ggplot/bslib theme
# green/red stay semantic: green = approve, red = decline
# ============================================================================

# Palette
charcoal   <- "#1E293B"   # navbar / secondary (slate)
gold       <- "#0D9488"   # accent / primary   (teal)
ink        <- "#1A1A1A"   # body text
paper      <- "#F1F5F9"   # page background
green      <- "#0D9488"   # APPROVE (teal)
red        <- "#B91C1C"   # DECLINE
amber      <- "#CA8A04"   # REVIEW

# chart gradients (low -> high)
chart_low  <- "#0D9488"   # default-rate gradient: safe end
chart_high <- "#5EEAD4"
risk_low   <- "#0D9488"   # points/risk gradient: low risk
risk_high  <- "#B91C1C"   # high risk

# ggplot theme
theme_cr <- function(base_size = 13) {
  ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      plot.title    = ggplot2::element_text(face = "bold", colour = ink),
      plot.subtitle = ggplot2::element_text(colour = "#555555"),
      panel.grid.minor = ggplot2::element_blank(),
      axis.title    = ggplot2::element_text(colour = "#444444")
    )
}

# bslib app theme
app_theme <- bslib::bs_theme(
  version = 5, bg = paper, fg = ink,
  primary = gold, secondary = charcoal,
  base_font = bslib::font_google("Inter"),
  heading_font = bslib::font_google("Spectral"),
  "navbar-bg" = charcoal
)