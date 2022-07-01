
<!-- README.md is generated from README.Rmd. Please edit that file -->

# Phenocam Forecast for NEFI summer course 2022

<!-- badges: start -->
<!-- badges: end -->

Team:

-   [Eric Scott](https://github.com/Aariq)
-   [Yiluan Song](https://github.com/yiluansong)
-   [Ross Alexander](https://github.com/alexanderm10)
-   [Jussi Mäkinen](https://github.com/jusmak)

# Literature

-   <https://www.sciencedirect.com/science/article/abs/pii/S0034425720303266>

# Data exploration

[Data exploration](docs/EDA.md)

## Timeseries

``` r
tar_read(ts_plot)
#> Warning: Removed 11245 rows containing missing values (geom_point).
#> Warning: Removed 342 rows containing missing values (geom_point).
#> Warning: Removed 2 row(s) containing missing values (geom_path).
```

![](README_files/figure-gfm/unnamed-chunk-2-1.png)<!-- -->

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

### JAGS code:


    model{
      
      for (s in 1:ns) {
        #### Data Model
        for(t in 1:nt){
          gcc[t, s] ~ dnorm(x[t, s],tau_obs_gcc)
          evi[t, s] ~ dnorm(x[t, s],tau_obs_evi)
        }
        
        #### Process Model
        for(t in 2:nt){
          x[t, s]~dnorm(x[t-1, s],tau_add)
        }
      }
      
      
      #### Priors
      for (s in 1:ns) {
         x[1, s] ~ dnorm(x_ic[s],tau_ic[s])
      }
      tau_obs_gcc ~ dgamma(a_obs_gcc,r_obs_gcc)
      tau_obs_evi ~ dgamma(a_obs_evi,r_obs_evi)
      tau_add ~ dgamma(a_add,r_add)
    }

# Forecasts

1)  Prepare new data for assimilation
2)  Load posterior as prior/ initialize uninformative prior
3)  Set initial conditions
4)  Configure model
5)  Fit model (and forecast)
6)  Model assessment
7)  Summarize posteriors with hyperparameters (save hyperparameters)
8)  Combine previous data with forecast (save data)
9)  Visualize (save plots)

Some examples

-   [2020-11-24](https://github.com/Aariq/efi-2022-phenocam/blob/main/forecasts/2020-11-24/plot.pdf)
-   [2021-07-22](https://github.com/Aariq/efi-2022-phenocam/blob/main/forecasts/2021-07-22/plot.pdf)
-   [2022-05-18](https://github.com/Aariq/efi-2022-phenocam/blob/main/forecasts/2022-05-18/plot.pdf)

### Workflow:

``` mermaid
graph LR
  subgraph legend
    x7420bd9270f8d27d([""Up to date""]):::uptodate --- x5b3426b4c7fa7dbc([""Started""]):::started
    x5b3426b4c7fa7dbc([""Started""]):::started --- xbf4603d6c2c2ad6b([""Stem""]):::none
  end
  subgraph Graph
    x9d9338876342a883(["all_dat"]):::uptodate --> x16fdb873ff498824(["all_dat_ano"]):::uptodate
    x68dd683e0472743b(["mindate"]):::uptodate --> x16fdb873ff498824(["all_dat_ano"]):::uptodate
    xb8d8de52ba56a7bb(["gcc_dat_file"]):::uptodate --> x250fae475e168023(["gcc_dat"]):::uptodate
    x37a4b6e78faf3120(["noaa_dat_file"]):::uptodate --> xb9d1c1bbc12ef44d(["noaa_dat"]):::uptodate
    x8fa3f0bfe3afe1bc(["RandomWalk"]):::uptodate --> x793b57f9be3e25d5(["README"]):::started
    x32cef2290a81c584(["ts_plot"]):::uptodate --> x793b57f9be3e25d5(["README"]):::started
    x9d9338876342a883(["all_dat"]):::uptodate --> xab6329fc3aa0e7b8(["forecasts"]):::uptodate
    x74653413816894b0(["batch"]):::uptodate --> xab6329fc3aa0e7b8(["forecasts"]):::uptodate
    x8448797b328e6352(["date_list"]):::uptodate --> xab6329fc3aa0e7b8(["forecasts"]):::uptodate
    x68dd683e0472743b(["mindate"]):::uptodate --> xab6329fc3aa0e7b8(["forecasts"]):::uptodate
    x8fa3f0bfe3afe1bc(["RandomWalk"]):::uptodate --> xab6329fc3aa0e7b8(["forecasts"]):::uptodate
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
  classDef started stroke:#000000,color:#000000,fill:#DC863B;
  classDef none stroke:#000000,color:#000000,fill:#94a4ac;
  linkStyle 0 stroke-width:0px;
  linkStyle 1 stroke-width:0px;
  linkStyle 25 stroke-width:0px;
```

# Resources for Challenge

-   [challenge
    docs](https://projects.ecoforecast.org/neon4cast-docs/theme-phenology.html)
-   [phenocam](https://phenocam.sr.unh.edu/webcam/)

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

# Repo structure

-   `data/` put raw data here
-   `R/` put R functions to be `source()`ed here
-   `docs/` put .Rmd files to be rendered here
