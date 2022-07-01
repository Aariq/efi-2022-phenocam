plot_anom <- function(all_dat_ano, mindate) {
  ggplot(all_dat_ano %>% filter(date >= mindate)) +
    geom_point(aes(x = date, y = evi_ano), col = "light green") +
    geom_point(aes(x = date, y = gcc_ano), col = "dark green") +
    geom_errorbar(aes(x = date, y = gcc_ano, ymin = gcc_ano - 1.95 * gcc_sd, ymax = gcc_ano + 1.95 * gcc_sd), col = "dark green", alpha = 0.5) +
    geom_point(aes(x = date, y = temp), col = "purple") +
    facet_wrap(. ~ site) +
    theme_classic()
}