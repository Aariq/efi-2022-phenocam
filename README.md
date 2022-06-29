
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

site metadata is here:

```r
site_data <- 
  readr::read_csv(
    "https://raw.githubusercontent.com/eco4cast/neon4cast-phenology/master/Phenology_NEON_Field_Site_Metadata_20210928.csv"
    )

```

[Data exploration](docs/EDA.md)

# Links

- [challenge docs](https://projects.ecoforecast.org/neon4cast-docs/theme-phenology.html)
- [phenocam](https://phenocam.sr.unh.edu/webcam/)

# Repo structure

- `data/` put raw data here
- `R/` put R functions to be `source()`ed here
- `docs/` put .Rmd files to be rendered here
