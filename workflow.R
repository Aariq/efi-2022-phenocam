gcc_dat <- 
  readr::read_csv(
    "https://data.ecoforecast.org/targets/phenology/phenology-targets.csv.gz",
    guess_max = 1e6
  )

noaa_dat<-read_rds("./data/noaa_past_climate_data.RDS")


all_dat<-gcc_dat %>% 
  dplyr::select(-rcc_90, -rcc_sd) %>% 
  rename(site=siteID,date=time) %>% 
  left_join(hls_df_proc %>% dplyr::select(site, date, evi), by=c("site", "date")) %>% 
  # left_join(noaa_dat %>% rename(date=time, temp=air_tempe), )
  # mutate(temp=(temp-quantile(temp, 0.025, na.rm=T))/(quantile(temp, 0.975, na.rm=T)-quantile(temp, 0.025, na.rm=T))) %>%
  group_by(site) %>% 
  mutate(gcc_90=(gcc_90-quantile(gcc_90, 0.025, na.rm=T))/(quantile(gcc_90, 0.975, na.rm=T)-quantile(gcc_90, 0.025, na.rm=T))) %>%
  mutate(gcc_sd=(gcc_sd)/(quantile(gcc_90, 0.975, na.rm=T)-quantile(gcc_90, 0.025, na.rm=T))^2) %>%
  mutate(evi=(evi-quantile(evi, 0.025, na.rm=T))/(quantile(evi, 0.975, na.rm=T)-quantile(evi, 0.025, na.rm=T))) %>%
  ungroup() %>% 
  mutate(evi_sd=0.01,
         temp_sd=0) %>% 
  mutate(doy=format(date, "%j") %>% as.integer()) 

all_dat_clim<-all_dat %>% 
  group_by(site, doy) %>% 
  summarise(gcc_clim=mean(gcc_90, na.rm=T),
         evi_clim=mean(evi, na.rm=T)
         )

all_dat_ano<-all_dat %>% 
  left_join(all_dat_clim, by=c("site", "doy")) %>% 
  mutate(gcc_ano=gcc_90-gcc_clim,
         evi_ano=evi-evi_clim)

ggplot(all_dat)+
  geom_point(aes(x=date, y=evi), col="light green") +
  geom_point(aes(x=date, y=gcc_90), col="dark green") +
  geom_errorbar(aes(x=date, y=gcc_90, ymin=gcc_90-1.95*gcc_sd, ymax=gcc_90+1.95*gcc_sd), col="dark green", alpha=0.5) +
  # geom_point(aes(x=date, y=temp), col="dark purple") +
  facet_wrap(.~site)+
  theme_classic()

ggplot(all_dat_ano)+
  geom_point(aes(x=date, y=evi_ano), col="light green") +
  geom_point(aes(x=date, y=gcc_ano), col="dark green") +
  geom_errorbar(aes(x=date, y=gcc_ano, ymin=gcc_ano-1.95*gcc_sd, ymax=gcc_ano+1.95*gcc_sd), col="dark green", alpha=0.5) +
  # geom_point(aes(x=date, y=temp), col="dark purple") +
  facet_wrap(.~site)+
  theme_classic()

date_list<-seq(as.Date("2018-01-01"), as.Date("2022-06-23")-35, by="day")
for (d in date_list)  {
  # subset data
  dat_subset<-all_dat %>% 
    filter(date<d)
  
  dat_new<-all_dat %>% 
    filter(date==d) %>% 
    drop_na(gcc_90)
  
  # load prior model
  if (d==1) {
    # initialize
    model_p<-
  } else {
    # load previous model
    model_p<-
  }
  
  if (nrow(dat_new)==0) {
    # no data then keep existing model
    model_a<-model_p
  } else {
    # build and configure model
    
    # fit model (infer parameters)
    
    
  }
  
  # make forecasts (35 days)
  
  # plot
  
  # evaluate accuracy
  
  # save model parameters
  
}