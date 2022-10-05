# Pulling Met data for specific sites

# need to run 'noaa_met_data.R' to pull in the functions to call in these data
library(tidyverse)
library(neon4cast)
library(lubridate)
library(rMR)

#library(EFIstandards)

Sys.setenv("AWS_DEFAULT_REGION" = "data",
           "AWS_S3_ENDPOINT" = "ecoforecast.org")

dir.create("drivers", showWarnings = FALSE)


site_data <- 
  readr::read_csv(
    "https://raw.githubusercontent.com/eco4cast/neon4cast-phenology/master/Phenology_NEON_Field_Site_Metadata_20210928.csv"
  )

unique(site_data$field_site_id)

forecast_date <- lubridate::as_date("2022-02-15") 
sites.get <- c(unique(site_data$field_site_id))


# Download NOAA past data and Future Forecast

# Past Data
for(i in 1:length(sites.get)){
  neon4cast::get_stacked_noaa_s3(".",site = sites.get[i], averaged = FALSE)
}

# Forecast Data
pb <- txtProgressBar(min=0, max=length(sites.get), style=3)
pb.ind=1

for(i in 1:length(sites.get)){
  neon4cast::get_noaa_forecast_s3(".",model = "NOAAGEFS_1hr", site = sites.get[i], date = forecast_date, cycle = "00")
  setTxtProgressBar(pb, pb.ind); pb.ind=pb.ind+1
}

# Create Dataframe from drivers
noaa_past <- neon4cast::stack_noaa(dir = "drivers", model = "NOAAGEFS_1hr_stacked")

# Forecast date set to 2022-02-15 for demonstration purposes
noaa_future <- neon4cast::stack_noaa(dir = "drivers", model = "NOAAGEFS_1hr", forecast_date = forecast_date)

# Aggregate to day and convert units of drivers
noaa_past_mean <- noaa_past %>% 
  mutate(date = as_date(time)) %>% 
  group_by(date, siteID) %>% 
  summarize(air_temperature = mean(air_temperature, na.rm = TRUE),.groups = "drop") %>% 
  rename(time = date) %>% 
  mutate(air_temperature = air_temperature - 273.15)

noaa_future_mean <- noaa_future %>% 
  mutate(date = as_date(time)) %>% 
  group_by(date, ensemble, siteID) %>% 
  summarize(air_temperature = mean(air_temperature, na.rm = TRUE), .groups = "drop") %>% 
  rename(time = date) %>% 
  mutate(ensemble = as.numeric(stringr::str_sub(ensemble, start = 4, end = 6)),
         air_temperature = air_temperature - 273.15)




saveRDS(noaa_past_mean, "data/noaa_past_climate_data.RDS")
saveRDS(noaa_future_mean, "data/noaa_future_climate_data.RDS")
