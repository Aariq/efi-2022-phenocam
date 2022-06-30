#Jussi 6-29
#Get weather forecast data for phenology sites

library(neon4cast)
library(lubridate)
library(rMR)

Sys.setenv("AWS_DEFAULT_REGION" = "data",
           "AWS_S3_ENDPOINT" = "ecoforecast.org")

dir.create("drivers", showWarnings = FALSE)

#set the day for starting forecast
forecast_date <- lubridate::as_date("2022-02-15")  

#set team
team_name <- "pheno_NEFI"

team_list <- list(list(individualName = list(givenName = "Jussi", 
                                             surName = "Makinen"),
                       organizationName = "Yale Uni",
                       electronicMailAddress = "jussi.makinen@yale.edu"))

site_data <- readr::read_csv("https://raw.githubusercontent.com/eco4cast/neon4cast-phenology/master/Phenology_NEON_Field_Site_Metadata_20210928.csv")
#target <- readr::read_csv("https://data.ecoforecast.org/targets/aquatics/aquatics-targets.csv.gz", guess_max = 1e6)

sites <- unique(target$siteID)
for(i in 1:length(sites)){
  neon4cast::get_stacked_noaa_s3(".",site = sites[i], averaged = FALSE)
}

noaa_past <- neon4cast::stack_noaa(dir = "drivers", model = "NOAAGEFS_1hr_stacked")
noaa_future <- neon4cast::stack_noaa(dir = "drivers", model = "NOAAGEFS_1hr", forecast_date = forecast_date)

noaa_past_mean <- noaa_past %>% 
  mutate(date = as_date(time)) %>% 
  group_by(date) %>% 
  summarize(air_temperature = mean(air_temperature, na.rm = TRUE), .groups = "drop") %>% 
  rename(time = date) %>% 
  mutate(air_temperature = air_temperature - 273.15)

