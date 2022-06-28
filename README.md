
# efi-2022-phenocam

<!-- badges: start -->
<!-- badges: end -->

# Target data

gcc data is here:

```r
gcc_dat <- 
  readr::read_csv(
    "https://data.ecoforecast.org/targets/phenology/phenology-targets.csv.gz",
    guess_max = 1e6
  )

```