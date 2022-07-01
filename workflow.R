gcc_dat <-
  readr::read_csv(
    "https://data.ecoforecast.org/targets/phenology/phenology-targets.csv.gz",
    guess_max = 1e6
  )

hls_df <- read_rds("./data/evi ts.rds")
hls_df_proc <- hls_df %>%
  rowwise() %>%
  mutate(
    aerosol = (intToBits(Fmask)[1:8] %>% as.integer())[7:8] %>% str_flatten() %>% as.integer(),
    water = (intToBits(Fmask)[1:8] %>% as.integer())[6] %>% as.integer(),
    snowice = (intToBits(Fmask)[1:8] %>% as.integer())[5] %>% as.integer(),
    cloudshadow = (intToBits(Fmask)[1:8] %>% as.integer())[3:4] %>% str_flatten() %>% as.integer(),
    cloud = (intToBits(Fmask)[1:8] %>% as.integer())[2] %>% as.integer()
  ) %>%
  ungroup() %>%
  # mutate(qa=case_when(Fmask==0|Fmask==64 ~2,
  #                     TRUE~1)) %>%
  # filter(qa==2|is.na(qa)) %>%
  filter(
    aerosol < 11,
    water == 0,
    snowice == 0,
    cloudshadow == 0,
    cloud == 0
  ) %>%
  dplyr::select(-Fmask, -aerosol, -water, -snowice, -cloudshadow, -cloud) %>%
  group_by(site, date, year, doy) %>%
  summarize(
    blue = mean(blue),
    green = mean(green),
    red = mean(red),
    nir = mean(nir)
  ) %>%
  ungroup() %>%
  mutate(evi = 2.5 * (nir - red) / (nir + 6 * red - 7.5 * blue + 1)) %>%
  filter(evi > 0, evi <= 1) %>%
  filter(red > 0, green > 0, blue > 0)

noaa_dat <- read_rds("./data/noaa_past_climate_data.RDS")
mindate <- min(noaa_dat$time)

all_dat <- gcc_dat %>%
  dplyr::select(-rcc_90, -rcc_sd) %>%
  rename(site = siteID, date = time) %>%
  left_join(hls_df_proc %>% dplyr::select(site, date, evi), by = c("site", "date")) %>%
  left_join(noaa_dat %>% rename(date = time, temp = air_temperature, site = siteID), by = c("site", "date")) %>%
  mutate(temp = (temp - quantile(temp, 0.025, na.rm = T)) / (quantile(temp, 0.975, na.rm = T) - quantile(temp, 0.025, na.rm = T))) %>%
  group_by(site) %>%
  mutate(gcc_90 = (gcc_90 - quantile(gcc_90, 0.025, na.rm = T)) / (quantile(gcc_90, 0.975, na.rm = T) - quantile(gcc_90, 0.025, na.rm = T))) %>%
  mutate(gcc_sd = (gcc_sd) / (quantile(gcc_90, 0.975, na.rm = T) - quantile(gcc_90, 0.025, na.rm = T))^2) %>%
  mutate(evi = (evi - quantile(evi, 0.025, na.rm = T)) / (quantile(evi, 0.975, na.rm = T) - quantile(evi, 0.025, na.rm = T))) %>%
  ungroup() %>%
  mutate(
    evi_sd = 0.01,
    temp_sd = 0
  ) %>%
  mutate(doy = format(date, "%j") %>% as.integer())

ggplot(all_dat %>% filter(date >= mindate)) +
  geom_point(aes(x = date, y = evi), col = "light green") +
  geom_point(aes(x = date, y = gcc_90), col = "dark green") +
  geom_errorbar(aes(x = date, y = gcc_90, ymin = gcc_90 - 1.95 * gcc_sd, ymax = gcc_90 + 1.95 * gcc_sd), col = "dark green", alpha = 0.5) +
  geom_point(aes(x = date, y = temp), col = "purple") +
  facet_wrap(. ~ site) +
  theme_classic()

all_dat_clim_site <- all_dat %>%
  filter(date < mindate) %>%
  group_by(site, doy) %>%
  summarise(
    gcc_clim = mean(gcc_90, na.rm = T),
    evi_clim = mean(evi, na.rm = T)
  ) %>%
  ungroup()

# all_dat_clim_all<-all_dat %>%
#   filter(date<mindate) %>%
#   group_by(doy) %>%
#   summarise(temp_clim=mean(temp, na.rm=T)
#   ) %>%
#   ungroup()


all_dat_ano <- all_dat %>%
  left_join(all_dat_clim_site, by = c("site", "doy")) %>%
  # left_join(all_dat_clim_all, by=c("doy")) %>%
  mutate(
    gcc_ano = gcc_90 - gcc_clim,
    evi_ano = evi - evi_clim # ,
    # temp_ano=temp-temp_clim
  )

ggplot(all_dat_ano %>% filter(date >= mindate)) +
  geom_point(aes(x = date, y = evi_ano), col = "light green") +
  geom_point(aes(x = date, y = gcc_ano), col = "dark green") +
  geom_errorbar(aes(x = date, y = gcc_ano, ymin = gcc_ano - 1.95 * gcc_sd, ymax = gcc_ano + 1.95 * gcc_sd), col = "dark green", alpha = 0.5) +
  geom_point(aes(x = date, y = temp), col = "purple") +
  facet_wrap(. ~ site) +
  theme_classic()

ggplot(all_dat_ano %>% filter(date >= mindate)) +
  geom_point(aes(x = temp, y = gcc_ano, col = site)) +
  facet_wrap(. ~ site) +
  theme_classic()

date_list <- seq(mindate + 30, as.Date("2022-06-23") - 30, by = "30 day")
for (d in 1:length(date_list)) {
  today <- date_list[d]
  dir.create(paste0("./data/archive/", today), recursive = T)
  # subset data
  dat_new <- all_dat %>%
    filter(date >= today - 30) %>%
    mutate(
      gcc_90 = case_when(date < today ~ gcc_90),
      gcc_sd = case_when(date < today ~ gcc_sd),
      evi = case_when(date < today ~ evi),
      evi_sd = case_when(date < today ~ evi_sd)
    )
  
  gcc <- dat_new %>%
    dplyr::select(date, gcc_90, site) %>%
    spread(key = "site", value = "gcc_90") %>%
    dplyr::select(-date) %>%
    as.matrix()
  evi <- dat_new %>%
    dplyr::select(date, evi, site) %>%
    spread(key = "site", value = "evi") %>%
    dplyr::select(-date) %>%
    as.matrix()
  # site<- all_dat %>% filter(date>=mindate) %>% pull(site) %>% as.factor() %>% as.integer()
  
  
  # load prior model
  if (d == 1) {
    # initialize
    priors <- list(
      x_ic = rep(0, ncol(gcc)), tau_ic = rep(10, ncol(gcc)), ## initial condition prior
      a_obs_gcc = 1, r_obs_gcc = 1, ## obs error prior
      a_obs_evi = 1, r_obs_evi = 1, ## obs error prior
      a_add = 1, r_add = 1 ## process error prior
    )
  } else {
    # load previous model
    prev_day <- date_list[d - 1]
    priors <- read_rds(paste0("./data/archive/", prev_day, "_posterior.rds"))
  }
  
  
  # Setting Initial conditions and prior for the model
  data <- c(
    list(
      gcc = gcc,
      evi = evi,
      nt = nrow(gcc),
      ns = ncol(gcc) ## data
    ),
    priors
  )
  
  RandomWalk <- "
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
"

####
# Defining the initial state of each of the chains we are going to run

nchain <- 3
init <- list()
for (i in 1:nchain) {
  # y.samp = sample(y,length(y),replace=TRUE)
  # init[[i]] <- list(tau_add=1/var(diff(y.samp)),  ## initial guess on process precision
  #                   tau_obs=5/var(y.samp))        ## initial guess on obs precision
  init[[i]] <- list(
    tau_add = 500, ## initial guess on process precision
    tau_obs_gcc = 500,
    tau_obs_evi = 500
  ) ## initial guess on obs precision
}

####
# Presenting basic model to JAGS
j.model <- jags.model(
  file = textConnection(RandomWalk),
  data = data,
  inits = init,
  n.chains = 3
)
jags.out <- coda.samples(
  model = j.model,
  variable.names = c("x", "tau_add", "tau_obs_gcc", "tau_obs_evi"),
  n.iter = 1000
)
out <- as.matrix(jags.out) ## convert from coda to matrix

# save posteriors
x_ic <- tau_ic <- rep(NA, ncol(gcc))
for (s in 1:ncol(gcc)) {
  x.col <- paste0("x[", 30 * d + 1, ",", s, "]")
  x_ic[s] <- mean(out[, x.col])
  tau_ic[s] <- 1 / sd(out[, x.col])^2
}
posteriors <- list(
  x_ic = x_ic, tau_ic = tau_ic, ## initial condition prior
  a_obs_gcc = mean(out[, "tau_obs_gcc"]),
  r_obs_gcc = 1 / sd(out[, "tau_obs_gcc"])^2, ## obs error prior
  a_obs_evi = mean(out[, "tau_obs_evi"]),
  r_obs_evi = 1 / sd(out[, "tau_obs_evi"])^2, ## obs error prior
  a_add = mean(out[, "tau_add"]),
  r_add = 1 / sd(out[, "tau_add"])^2
)
write_rds(posteriors, paste0("./data/archive/", today, "_posterior.rds"))

# plot
x.cols <- grep("^x", colnames(out)) ## grab all columns that start with the letter x
ci <- apply(out[, x.cols], 2, quantile, c(0.025, 0.5, 0.975)) ## model was fit on log scale

dat_fitted <- dat_new %>%
  cbind(t(ci))
write_rds(dat_fitted, paste0("./data/archive/", today, "_data.rds"))

p <- ggplot(dat_fitted) +
  geom_line(aes(x = date, y = gcc_90), col = "dark green") +
  geom_point(aes(x = date, y = evi), col = "light green") +
  geom_ribbon(aes(x = date, ymin = `2.5%`, ymax = `97.5%`), fill = "blue", alpha = 0.5) +
  geom_line(aes(x = date, y = `50%`), col = "blue") +
  facet_wrap(. ~ site) +
  theme_classic()

cairo_pdf(paste0("./data/archive/", today, "_plot.rds"))
print(p)
dev.off()
}
