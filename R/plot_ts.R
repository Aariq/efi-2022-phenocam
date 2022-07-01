plot_ts <- function(all_dat, mindate) {
  ggplot(all_dat %>% filter(date >= mindate)) +
    geom_point(aes(x = date, y = evi), col = "light green") +
    geom_point(aes(x = date, y = gcc_90), col = "dark green") +
    geom_errorbar(aes(x = date, y = gcc_90, ymin = gcc_90 - 1.95 * gcc_sd, ymax = gcc_90 + 1.95 * gcc_sd), col = "dark green", alpha = 0.5) +
    geom_point(aes(x = date, y = temp), col = "purple") +
    facet_wrap(. ~ site) +
    theme_classic()
}