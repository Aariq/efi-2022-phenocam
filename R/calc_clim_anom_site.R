#calculate climate anomaly by site
calc_clim_anom_site <- function(all_dat) {
  all_dat %>%
    left_join(all_dat_clim_site, by = c("site", "doy")) %>%
    # left_join(all_dat_clim_all, by=c("doy")) %>%
    mutate(
      gcc_ano = gcc_90 - gcc_clim,
      evi_ano = evi - evi_clim # ,
      # temp_ano=temp-temp_clim
    )
}