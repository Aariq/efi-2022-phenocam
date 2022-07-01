
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

# Model structure

Data model
$$GCC_{t, s} \sim N (X_{t, s}, \tau_{o, GCC})$$
$$EVI_{t, s} \sim N (X_{t, s}, \tau_{o, EVI})$$

Process model
$$
X_{t, s} \sim N(X_{t-1, s}+ \beta_{s} T_{t, s} + \mu_{s},\tau_{a})\\
X_{t, s} \sim N(X_{t-1, s}+ \beta T_{t, s},\tau_{a})\\
X_{t, s} \sim N(X_{t-1, s},\tau_{a})
$$

Priors
$$
X_{1, s} \sim N (mu_{IC, s}, \tau_{IC, s})\\
\tau_{o, GCC} \sim Gamma(a_{o, GCC},r_{o, GCC})\\
\tau_{o, EVI} \sim Gamma(a_{o, EVI},r_{o, EVI})\\
\tau_{a} \sim Gamma(a_a,r_a)
$$


# Links

- [challenge docs](https://projects.ecoforecast.org/neon4cast-docs/theme-phenology.html)
- [phenocam](https://phenocam.sr.unh.edu/webcam/)

# Repo structure

- `data/` put raw data here
- `R/` put R functions to be `source()`ed here
- `docs/` put .Rmd files to be rendered here
