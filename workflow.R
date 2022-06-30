gcc_dat <- 
  readr::read_csv(
    "https://data.ecoforecast.org/targets/phenology/phenology-targets.csv.gz",
    guess_max = 1e6
  )

hls_df<-read_rds("./data/evi ts.rds")
hls_df_proc<-hls_df %>% 
  rowwise() %>% 
  mutate(aerosol=(intToBits(Fmask) [1:8] %>% as.integer()) [7:8] %>% str_flatten() %>% as.integer(),
         water=(intToBits(Fmask) [1:8] %>% as.integer()) [6] %>% as.integer(),
         snowice=(intToBits(Fmask) [1:8] %>% as.integer()) [5] %>% as.integer(),
         cloudshadow=(intToBits(Fmask) [1:8]  %>% as.integer()) [3:4] %>% str_flatten() %>% as.integer(),
         cloud=(intToBits(Fmask) [1:8]  %>% as.integer()) [2] %>% as.integer()) %>%  
  ungroup() %>% 
  # mutate(qa=case_when(Fmask==0|Fmask==64 ~2,
  #                     TRUE~1)) %>%
  # filter(qa==2|is.na(qa)) %>%
  filter(aerosol<11,
         water==0,
         snowice==0,
         cloudshadow==0,
         cloud==0) %>%
  dplyr::select(-Fmask, -aerosol, -water, -snowice, -cloudshadow, -cloud) %>%
  group_by(site,  date, year, doy ) %>% 
  summarize(blue=mean(blue),
            green=mean(green),
            red=mean(red),
            nir=mean(nir)) %>% 
  ungroup() %>% 
  mutate(evi=2.5* (nir-red) / (nir + 6*red - 7.5*blue + 1)) %>% 
  filter(evi>0, evi<=1) %>% 
  filter(red>0, green>0, blue>0) 

noaa_dat<-read_rds("./data/noaa_past_climate_data.RDS")
mindate<-min(noaa_dat$time)

all_dat<-gcc_dat %>% 
  dplyr::select(-rcc_90, -rcc_sd) %>% 
  rename(site=siteID,date=time) %>% 
  left_join(hls_df_proc %>% dplyr::select(site, date, evi), by=c("site", "date")) %>% 
  left_join(noaa_dat %>% rename(date=time, temp=air_temperature, site=siteID), by=c("site", "date")) %>% 
  mutate(temp=(temp-quantile(temp, 0.025, na.rm=T))/(quantile(temp, 0.975, na.rm=T)-quantile(temp, 0.025, na.rm=T))) %>%
  group_by(site) %>% 
  mutate(gcc_90=(gcc_90-quantile(gcc_90, 0.025, na.rm=T))/(quantile(gcc_90, 0.975, na.rm=T)-quantile(gcc_90, 0.025, na.rm=T))) %>%
  mutate(gcc_sd=(gcc_sd)/(quantile(gcc_90, 0.975, na.rm=T)-quantile(gcc_90, 0.025, na.rm=T))^2) %>%
  mutate(evi=(evi-quantile(evi, 0.025, na.rm=T))/(quantile(evi, 0.975, na.rm=T)-quantile(evi, 0.025, na.rm=T))) %>%
  ungroup() %>% 
  mutate(evi_sd=0.01,
         temp_sd=0) %>% 
  mutate(doy=format(date, "%j") %>% as.integer()) 

ggplot(all_dat %>% filter(date>=mindate))+
  geom_point(aes(x=date, y=evi), col="light green") +
  geom_point(aes(x=date, y=gcc_90), col="dark green") +
  geom_errorbar(aes(x=date, y=gcc_90, ymin=gcc_90-1.95*gcc_sd, ymax=gcc_90+1.95*gcc_sd), col="dark green", alpha=0.5) +
  geom_point(aes(x=date, y=temp), col="purple") +
  facet_wrap(.~site)+
  theme_classic()

all_dat_clim_site<-all_dat %>%
  filter(date<mindate) %>% 
  group_by(site, doy) %>% 
  summarise(gcc_clim=mean(gcc_90, na.rm=T),
         evi_clim=mean(evi, na.rm=T)
         ) %>% 
  ungroup() 

# all_dat_clim_all<-all_dat %>% 
#   filter(date<mindate) %>% 
#   group_by(doy) %>% 
#   summarise(temp_clim=mean(temp, na.rm=T)
#   ) %>% 
#   ungroup() 
  

all_dat_ano<-all_dat %>% 
  left_join(all_dat_clim_site, by=c("site", "doy")) %>% 
  # left_join(all_dat_clim_all, by=c("doy")) %>% 
  mutate(gcc_ano=gcc_90-gcc_clim,
         evi_ano=evi-evi_clim#,
         # temp_ano=temp-temp_clim
         )

ggplot(all_dat_ano %>% filter(date>=mindate))+
  geom_point(aes(x=date, y=evi_ano), col="light green") +
  geom_point(aes(x=date, y=gcc_ano), col="dark green") +
  geom_errorbar(aes(x=date, y=gcc_ano, ymin=gcc_ano-1.95*gcc_sd, ymax=gcc_ano+1.95*gcc_sd), col="dark green", alpha=0.5) +
  geom_point(aes(x=date, y=temp), col="purple") +
  facet_wrap(.~site)+
  theme_classic()

ggplot(all_dat_ano %>% filter(date>=mindate))+
  geom_point(aes(x=temp, y=gcc_ano, col=site))+
  facet_wrap(.~site)+
  theme_classic()

date_list<-seq(mindate, as.Date("2022-06-23")-35, by="day")
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