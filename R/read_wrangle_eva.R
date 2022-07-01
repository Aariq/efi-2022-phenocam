read_wrangle_eva <- function(filepath) {
  read_csv(filepath) %>% 
    mutate(across(c(year, doy), as.integer)) %>%
    rowwise() %>%
    mutate(
      aerosol = (intToBits(Fmask)[1:8] %>% as.integer())[7:8] %>% str_flatten() %>% as.integer(),
      water = (intToBits(Fmask)[1:8] %>% as.integer())[6] %>% as.integer(),
      snowice = (intToBits(Fmask)[1:8] %>% as.integer())[5] %>% as.integer(),
      cloudshadow = (intToBits(Fmask)[1:8] %>% as.integer())[3:4] %>% str_flatten() %>% as.integer(),
      cloud = (intToBits(Fmask)[1:8] %>% as.integer())[2] %>% as.integer()
    ) %>%
    ungroup() %>%
    # mutate(qa=case_when(Fmask==0|Fmask==64 ~2,
    #                     TRUE~1)) %>%
    # filter(qa==2|is.na(qa)) %>%
    filter(
      aerosol < 11,
      water == 0,
      snowice == 0,
      cloudshadow == 0,
      cloud == 0
    ) %>%
    dplyr::select(-Fmask, -aerosol, -water, -snowice, -cloudshadow, -cloud) %>%
    group_by(site, date, year, doy) %>%
    summarize(
      blue = mean(blue),
      green = mean(green),
      red = mean(red),
      nir = mean(nir)
    ) %>%
    ungroup() %>%
    mutate(evi = 2.5 * (nir - red) / (nir + 6 * red - 7.5 * blue + 1)) %>%
    filter(evi > 0, evi <= 1) %>%
    filter(red > 0, green > 0, blue > 0)
  
}