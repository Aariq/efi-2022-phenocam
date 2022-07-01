
<!-- README.md is generated from README.Rmd. Please edit that file -->

# efi-2022-phenocam

<!-- badges: start -->
<!-- badges: end -->

### Workflow:

── Attaching packages ─────────────────────────────────────── tidyverse
1.3.1 ── ✔ ggplot2 3.3.6 ✔ purrr 0.3.4 ✔ tibble 3.1.7 ✔ dplyr 1.0.9 ✔
tidyr 1.2.0 ✔ stringr 1.4.0 ✔ readr 2.1.2 ✔ forcats 0.5.1 ── Conflicts
────────────────────────────────────────── tidyverse_conflicts() ── ✖
dplyr::filter() masks stats::filter() ✖ dplyr::lag() masks stats::lag()
Loading required package: coda Linked to JAGS 4.3.1 Loaded modules:
basemod,bugs

``` mermaid
graph LR
  subgraph legend
    x7420bd9270f8d27d([""Up to date""]):::uptodate --- x0a52b03877696646([""Outdated""]):::outdated
    x0a52b03877696646([""Outdated""]):::outdated --- xbf4603d6c2c2ad6b([""Stem""]):::none
  end
  subgraph Graph
    x9d9338876342a883(["all_dat"]):::uptodate --> x16fdb873ff498824(["all_dat_ano"]):::uptodate
    x68dd683e0472743b(["mindate"]):::uptodate --> x16fdb873ff498824(["all_dat_ano"]):::uptodate
    xb8d8de52ba56a7bb(["gcc_dat_file"]):::uptodate --> x250fae475e168023(["gcc_dat"]):::uptodate
    x37a4b6e78faf3120(["noaa_dat_file"]):::uptodate --> xb9d1c1bbc12ef44d(["noaa_dat"]):::uptodate
    x32cef2290a81c584(["ts_plot"]):::uptodate --> x793b57f9be3e25d5(["README"]):::outdated
    x9d9338876342a883(["all_dat"]):::uptodate --> xd7adfc39060f91a9(["out"]):::uptodate
    x74653413816894b0(["batch"]):::uptodate --> xd7adfc39060f91a9(["out"]):::uptodate
    x8448797b328e6352(["date_list"]):::uptodate --> xd7adfc39060f91a9(["out"]):::uptodate
    x68dd683e0472743b(["mindate"]):::uptodate --> xd7adfc39060f91a9(["out"]):::uptodate
    x8fa3f0bfe3afe1bc(["RandomWalk"]):::uptodate --> xd7adfc39060f91a9(["out"]):::uptodate
    x18f6cc99ecb95617(["hls_df_file"]):::uptodate --> x64431175705194ee(["hls_df_proc"]):::uptodate
    x74653413816894b0(["batch"]):::uptodate --> x8448797b328e6352(["date_list"]):::uptodate
    x250fae475e168023(["gcc_dat"]):::uptodate --> x8448797b328e6352(["date_list"]):::uptodate
    x68dd683e0472743b(["mindate"]):::uptodate --> x8448797b328e6352(["date_list"]):::uptodate
    xb9d1c1bbc12ef44d(["noaa_dat"]):::uptodate --> x68dd683e0472743b(["mindate"]):::uptodate
    x9d9338876342a883(["all_dat"]):::uptodate --> x32cef2290a81c584(["ts_plot"]):::uptodate
    x68dd683e0472743b(["mindate"]):::uptodate --> x32cef2290a81c584(["ts_plot"]):::uptodate
    x16fdb873ff498824(["all_dat_ano"]):::uptodate --> xdae95d0f164d35b8(["anom_plot"]):::uptodate
    x68dd683e0472743b(["mindate"]):::uptodate --> xdae95d0f164d35b8(["anom_plot"]):::uptodate
    x250fae475e168023(["gcc_dat"]):::uptodate --> x9d9338876342a883(["all_dat"]):::uptodate
    x64431175705194ee(["hls_df_proc"]):::uptodate --> x9d9338876342a883(["all_dat"]):::uptodate
    xb9d1c1bbc12ef44d(["noaa_dat"]):::uptodate --> x9d9338876342a883(["all_dat"]):::uptodate
    xcd447f216a0c85c5(["EDA"]):::uptodate --> xcd447f216a0c85c5(["EDA"]):::uptodate
  end
  classDef uptodate stroke:#000000,color:#ffffff,fill:#354823;
  classDef outdated stroke:#000000,color:#000000,fill:#78B7C5;
  classDef none stroke:#000000,color:#000000,fill:#94a4ac;
  linkStyle 0 stroke-width:0px;
  linkStyle 1 stroke-width:0px;
  linkStyle 24 stroke-width:0px;
```

# Target data

gcc data is here:

``` r
gcc_dat <- 
  readr::read_csv(
    "https://data.ecoforecast.org/targets/phenology/phenology-targets.csv.gz",
    guess_max = 1e6
  )
```

site metadata is here:

``` r
site_data <- 
  readr::read_csv(
    "https://raw.githubusercontent.com/eco4cast/neon4cast-phenology/master/Phenology_NEON_Field_Site_Metadata_20210928.csv"
    )
```

[Data exploration](docs/EDA.md)

# Timeseries

``` r
tar_read(ts_plot)
#> Warning: Removed 11245 rows containing missing values (geom_point).
#> Warning: Removed 342 rows containing missing values (geom_point).
#> Warning: Removed 2 row(s) containing missing values (geom_path).
```

![](README_files/figure-gfm/unnamed-chunk-3-1.png)<!-- -->

# Model structure

Data model

![GCC\_{t, s} \sim N (X\_{t, s}, \tau\_{o, GCC})](https://latex.codecogs.com/png.image?%5Cdpi%7B110%7D&space;%5Cbg_white&space;GCC_%7Bt%2C%20s%7D%20%5Csim%20N%20%28X_%7Bt%2C%20s%7D%2C%20%5Ctau_%7Bo%2C%20GCC%7D%29 "GCC_{t, s} \sim N (X_{t, s}, \tau_{o, GCC})")

![EVI\_{t, s} \sim N (X\_{t, s}, \tau\_{o, EVI})](https://latex.codecogs.com/png.image?%5Cdpi%7B110%7D&space;%5Cbg_white&space;EVI_%7Bt%2C%20s%7D%20%5Csim%20N%20%28X_%7Bt%2C%20s%7D%2C%20%5Ctau_%7Bo%2C%20EVI%7D%29 "EVI_{t, s} \sim N (X_{t, s}, \tau_{o, EVI})")

Process model

![X\_{t, s} \sim N(X\_{t-1, s}+ \beta\_{s} T\_{t, s} + \mu\_{s},\tau\_{a})](https://latex.codecogs.com/png.image?%5Cdpi%7B110%7D&space;%5Cbg_white&space;X_%7Bt%2C%20s%7D%20%5Csim%20N%28X_%7Bt-1%2C%20s%7D%2B%20%5Cbeta_%7Bs%7D%20T_%7Bt%2C%20s%7D%20%2B%20%5Cmu_%7Bs%7D%2C%5Ctau_%7Ba%7D%29 "X_{t, s} \sim N(X_{t-1, s}+ \beta_{s} T_{t, s} + \mu_{s},\tau_{a})")

![X\_{t, s} \sim N(X\_{t-1, s}+ \beta T\_{t, s},\tau\_{a})](https://latex.codecogs.com/png.image?%5Cdpi%7B110%7D&space;%5Cbg_white&space;X_%7Bt%2C%20s%7D%20%5Csim%20N%28X_%7Bt-1%2C%20s%7D%2B%20%5Cbeta%20T_%7Bt%2C%20s%7D%2C%5Ctau_%7Ba%7D%29 "X_{t, s} \sim N(X_{t-1, s}+ \beta T_{t, s},\tau_{a})")

![X\_{t, s} \sim N(X\_{t-1, s},\tau\_{a})](https://latex.codecogs.com/png.image?%5Cdpi%7B110%7D&space;%5Cbg_white&space;X_%7Bt%2C%20s%7D%20%5Csim%20N%28X_%7Bt-1%2C%20s%7D%2C%5Ctau_%7Ba%7D%29 "X_{t, s} \sim N(X_{t-1, s},\tau_{a})")

Priors

![X\_{1, s} \sim N (mu\_{IC, s}, \tau\_{IC, s})](https://latex.codecogs.com/png.image?%5Cdpi%7B110%7D&space;%5Cbg_white&space;X_%7B1%2C%20s%7D%20%5Csim%20N%20%28mu_%7BIC%2C%20s%7D%2C%20%5Ctau_%7BIC%2C%20s%7D%29 "X_{1, s} \sim N (mu_{IC, s}, \tau_{IC, s})")

![\tau\_{o, GCC} \sim Gamma(a\_{o, GCC},r\_{o, GCC})](https://latex.codecogs.com/png.image?%5Cdpi%7B110%7D&space;%5Cbg_white&space;%5Ctau_%7Bo%2C%20GCC%7D%20%5Csim%20Gamma%28a_%7Bo%2C%20GCC%7D%2Cr_%7Bo%2C%20GCC%7D%29 "\tau_{o, GCC} \sim Gamma(a_{o, GCC},r_{o, GCC})")

![\tau\_{o, EVI} \sim Gamma(a\_{o, EVI},r\_{o, EVI})](https://latex.codecogs.com/png.image?%5Cdpi%7B110%7D&space;%5Cbg_white&space;%5Ctau_%7Bo%2C%20EVI%7D%20%5Csim%20Gamma%28a_%7Bo%2C%20EVI%7D%2Cr_%7Bo%2C%20EVI%7D%29 "\tau_{o, EVI} \sim Gamma(a_{o, EVI},r_{o, EVI})")

![\tau\_{a} \sim Gamma(a_a,r_a)](https://latex.codecogs.com/png.image?%5Cdpi%7B110%7D&space;%5Cbg_white&space;%5Ctau_%7Ba%7D%20%5Csim%20Gamma%28a_a%2Cr_a%29 "\tau_{a} \sim Gamma(a_a,r_a)")

# Forecasts

Some examples

-   [2020-11-24](forecasts/2020-11-24/plot.pdf)

# Links

-   [challenge
    docs](https://projects.ecoforecast.org/neon4cast-docs/theme-phenology.html)
-   [phenocam](https://phenocam.sr.unh.edu/webcam/)

# Repo structure

-   `data/` put raw data here
-   `R/` put R functions to be `source()`ed here
-   `docs/` put .Rmd files to be rendered here
