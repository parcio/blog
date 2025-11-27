library(ggplot2)

data("midwest", package = "ggplot2")
is_rstudio <- Sys.getenv("RSTUDIO") == "1"
if (interactive() && ! is_rstudio) {
  library(httpgd)
  hgd()
}

# Scatterplot
gg <- ggplot(midwest, aes(x = area, y = poptotal)) +
  geom_point(aes(col = state, size = popdensity)) +
  geom_smooth(method = "loess", se = FALSE) +
  xlim(c(0, 0.1)) +
  ylim(c(0, 500000)) +
  labs(subtitle = "Area Vs Population",
       y = "Population",
       x = "Area",
       title = "Scatterplot",
       caption = "Source: midwest")

if (interactive()) {
  plot(gg)
} else {
  ggsave("plot.pdf", plot = gg)
}
