# Setting up the Random Walk model for the phenology data
library(tidyverse)
library(skimr)
library(visdat)
library(lubridate)
library(rjags)
#library(rnoaa)
library(daymetr)
library(ecoforecastR)
# loading in the phenology data

gcc_dat <- readRDS("processed_data/gcc_use_ross.RDS")
summary(dat)

# calculating anomaly
gcc_dat <- gcc_dat %>%
  mutate(doy = yday(time)) %>% 
  #within each site and for each day of year...
  group_by(doy, siteID) %>% 
  #...calculate mean GCC for the whole time series...
  mutate(mean_gcc_doy = mean(gcc_90, na.rm = TRUE)) %>% 
  ungroup() %>% 
  # ... then calculate GCC anomaly
  mutate(gcc_anom  = gcc_90 - mean_gcc_doy) 
# %>% 
#   #and plot!
#   ggplot() +
#   geom_histogram(aes(gcc_anom)) +
#   facet_wrap(~siteID)

summary(gcc_dat)

y <- gcc_dat$gcc_anom

# Setting Initial conditions and prior for the model
data <- list(y=y,n=length(y),      ## data
             x_ic=1000,tau_ic=100, ## initial condition prior
             a_obs=1,r_obs=1,           ## obs error prior
             a_add=1,r_add=1            ## process error prior
)


# Establishing the model form for the random walk

RandomWalk = "
model{
  
  #### Data Model
  for(t in 1:n){
    y[t] ~ dnorm(x[t],tau_obs)
  }
  
  #### Process Model
  for(t in 2:n){
    x[t]~dnorm(x[t-1],tau_add)
  }
  
  #### Priors
  x[1] ~ dnorm(x_ic,tau_ic)
  tau_obs ~ dgamma(a_obs,r_obs)
  tau_add ~ dgamma(a_add,r_add)
}
"

####
# Defining the initial state of each of the chains we are going to run

nchain = 3
init <- list()
for(i in 1:nchain){
  y.samp = sample(y,length(y),replace=TRUE)
  init[[i]] <- list(tau_add=1/var(diff(y.samp)),  ## initial guess on process precision
                    tau_obs=5/var(y.samp))        ## initial guess on obs precision
}

####
# Presenting basic model to JAGS
j.model   <- jags.model (file = textConnection(RandomWalk),
                         data = data,
                         inits = init,
                         n.chains = 3)

# Running first MCMC and assessing convergence
jags.out   <- coda.samples (model = j.model,
                            variable.names = c("tau_add","tau_obs"),
                            n.iter = 1000)
plot(jags.out)

