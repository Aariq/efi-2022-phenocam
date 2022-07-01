join_data <- function(gcc_dat, hls_df_proc, noaa_dat) {
  gcc_dat %>%
    dplyr::select(-rcc_90, -rcc_sd) %>%
    rename(site = siteID, date = time) %>%
    left_join(hls_df_proc %>% dplyr::select(site, date, evi), by = c("site", "date")) %>%
    left_join(noaa_dat %>% rename(date = time, temp = air_temperature, site = siteID), by = c("site", "date")) %>%
    mutate(temp = (temp - quantile(temp, 0.025, na.rm = T)) / (quantile(temp, 0.975, na.rm = T) - quantile(temp, 0.025, na.rm = T))) %>%
    group_by(site) %>%
    mutate(gcc_90 = (gcc_90 - quantile(gcc_90, 0.025, na.rm = T)) / (quantile(gcc_90, 0.975, na.rm = T) - quantile(gcc_90, 0.025, na.rm = T))) %>%
    mutate(gcc_sd = (gcc_sd) / (quantile(gcc_90, 0.975, na.rm = T) - quantile(gcc_90, 0.025, na.rm = T))^2) %>%
    mutate(evi = (evi - quantile(evi, 0.025, na.rm = T)) / (quantile(evi, 0.975, na.rm = T) - quantile(evi, 0.025, na.rm = T))) %>%
    ungroup() %>%
    mutate(
      evi_sd = 0.01,
      temp_sd = 0
    ) %>%
    mutate(doy = format(date, "%j") %>% as.integer())
}