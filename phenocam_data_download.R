# downloading phenocam data


gcc_dat <- 
  readr::read_csv(
    "https://data.ecoforecast.org/targets/phenology/phenology-targets.csv.gz",
    guess_max = 1e6
  )

head(gcc_dat)

# just going to pull in two sites: HARV & GRSM

gcc_use <- gcc_dat[gcc_dat$siteID %in% c("HARV", "GRSM"),]


saveRDS(gcc_use, "processed_data/gcc_use_ross.RDS")
