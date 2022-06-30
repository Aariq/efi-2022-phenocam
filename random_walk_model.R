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

gcc_dat <- readRDS("data/gcc_use_ross.RDS")
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

# limiting the data to just 2021
gcc_dat_short <- gcc_dat[gcc_dat$time >= as.Date("2021-01-01")& gcc_dat$time < as.Date("2022-01-01"),]
summary(gcc_dat_short)

# y <- gcc_dat_short$gcc_90
y <- gcc_dat$gcc_90

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


# Now that the model has converged we'll want to take a much larger sample from the MCMC and include the full vector of X's in the output

jags.out   <- coda.samples (model = j.model,
                            variable.names = c("x","tau_add","tau_obs"),
                            n.iter = 10000)

time <- gcc_dat_short$time
time.rng = c(1,length(time))       ## adjust to zoom in and out
out <- as.matrix(jags.out)         ## convert from coda to matrix  
x.cols <- grep("^x",colnames(out)) ## grab all columns that start with the letter x
ci <- apply(out[,x.cols],2,quantile,c(0.025,0.5,0.975)) ## model was fit on log scale

plot(time,ci[2,],type='n',ylim=range(y,na.rm=TRUE),ylab="Greenness",xlim=time[time.rng])
## adjust x-axis label to be monthly if zoomed
if(diff(time.rng) < 100){ 
  axis.Date(1, at=seq(time[time.rng[1]],time[time.rng[2]],by='month'), format = "%Y-%m")
}
ecoforecastR::ciEnvelope(time,ci[1,],ci[3,],col=ecoforecastR::col.alpha("red",0.75))
points(time,y,pch="+",cex=0.5)

# Doesn't look too bad, but I'm having issues getting the confidence interval to plot
