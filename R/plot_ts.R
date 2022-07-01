plot_ts <- function(all_dat, mindate) {
  ggplot(all_dat %>% filter(date >= mindate)) +
    geom_point(aes(x = date, y = evi), col = "light green", size = 0.3) +
    geom_point(aes(x = date, y = gcc_90), col = "dark green", size = 0.3) +
    geom_errorbar(aes(x = date, y = gcc_90, ymin = gcc_90 - 1.95 * gcc_sd, ymax = gcc_90 + 1.95 * gcc_sd), col = "dark green", alpha = 0.5) +
    geom_line(aes(x = date, y = temp), col = "purple", size = 0.3) +
    facet_wrap(. ~ site) +
    scale_x_date(date_breaks = "6 months", date_labels = "%Y-%m") +
    theme_classic() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
}