# calulate climatology and anomaly
calc_clim_anom <- function(all_dat, mindate) {
  all_dat_clim_site <- all_dat %>%
    filter(date < mindate) %>%
    group_by(site, doy) %>%
    summarise(
      gcc_clim = mean(gcc_90, na.rm = T),
      evi_clim = mean(evi, na.rm = T)
    ) %>%
    ungroup()
  
  # all_dat_clim_all<-all_dat %>%
  #   filter(date<mindate) %>%
  #   group_by(doy) %>%
  #   summarise(temp_clim=mean(temp, na.rm=T)
  #   ) %>%
  #   ungroup()
  
  all_dat %>%
    left_join(all_dat_clim_site, by = c("site", "doy")) %>%
    # left_join(all_dat_clim_all, by=c("doy")) %>%
    mutate(
      gcc_ano = gcc_90 - gcc_clim,
      evi_ano = evi - evi_clim # ,
      # temp_ano=temp-temp_clim
    )
}
 