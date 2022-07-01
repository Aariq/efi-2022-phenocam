# Created by use_targets().
# Follow the comments below to fill in this target script.
# Then follow the manual to check and run the pipeline:
#   https://books.ropensci.org/targets/walkthrough.html#inspect-the-pipeline # nolint

# Load packages required to define the pipeline:
library(targets)
library(tarchetypes)

#load packages used in the pipeline
source("packages.R")


# Set target options:
tar_option_set(
  format = "rds" # default storage format
)

# tar_make_clustermq() configuration (okay to leave alone):
options(clustermq.scheduler = "multicore")


# Load the R scripts with your custom functions:
lapply(list.files("R", full.names = TRUE, recursive = TRUE), source)
# source("other_functions.R") # Source other scripts as needed. # nolint

tar_plan(
  tar_target(gcc_dat_file, "https://data.ecoforecast.org/targets/phenology/phenology-targets.csv.gz", format = "url"),
  gcc_dat = read_csv(gcc_dat_file, guess_max = 1e6),
  tar_file(hls_df_file, "data/eva_ts.csv"),
  hls_df_proc = read_wrangle_evi(hls_df_file),
  tar_file(noaa_dat_file, "./data/noaa_past_climate_data.RDS"),
  noaa_dat = read_rds(noaa_dat_file),
  
  # starting point
  mindate = min(noaa_dat$time),
  
  all_dat = join_data(gcc_dat, hls_df_proc, noaa_dat),
  ts_plot = plot_ts(all_dat, mindate),
  all_dat_ano = calc_clim_anom(all_dat, mindate),
  anom_plot = plot_anom(all_dat_ano, mindate),
  batch = 60,
  date_list = seq(mindate + batch, max(gcc_dat$time), by = paste0(batch, " day")),
  RandomWalk = model_RandomWalk(),
  out = run_model(date_list, RandomWalk, all_dat, batch, mindate),
  tar_render(EDA, "docs/EDA.Rmd", output_format = "all"),
  tar_render(README, "README.Rmd", output_format = "all")
)
