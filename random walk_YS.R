maxdate<-as.Date("2022-02-01")

dat_subset<-all_dat %>% 
  filter(date>=mindate) %>% 
  mutate(gcc_90=case_when(date<maxdate~gcc_90),
         gcc_sd=case_when(date<maxdate~gcc_sd),
         evi=case_when(date<maxdate~ evi),
         evi_sd=case_when(date<maxdate~ evi_sd)) 

gcc<- dat_subset%>% 
  dplyr::select(date, gcc_90, site) %>% 
  spread(key="site", value="gcc_90") %>% 
  dplyr::select(-date) %>% 
  as.matrix()
evi<- dat_subset%>% 
  dplyr::select(date, evi, site) %>% 
  spread(key="site", value="evi") %>% 
  dplyr::select(-date) %>% 
  as.matrix()
# site<- all_dat %>% filter(date>=mindate) %>% pull(site) %>% as.factor() %>% as.integer()

# Setting Initial conditions and prior for the model
data <- list(gcc=gcc,
             evi=evi,
             nt=nrow(gcc),
             ns=ncol(gcc),  ## data
             x_ic=0,tau_ic=10, ## initial condition prior
             a_obs_gcc=1,r_obs_gcc=1,           ## obs error prior
             a_obs_evi=1,r_obs_evi=1,           ## obs error prior
             a_add=1,r_add=1            ## process error prior
)


RandomWalk = "
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
     x[1, s] ~ dnorm(x_ic,tau_ic)
  }
  tau_obs_gcc ~ dgamma(a_obs_gcc,r_obs_gcc)
  tau_obs_evi ~ dgamma(a_obs_evi,r_obs_evi)
  tau_add ~ dgamma(a_add,r_add)
}
"

####
# Defining the initial state of each of the chains we are going to run

nchain = 3
init <- list()
for(i in 1:nchain){
  # y.samp = sample(y,length(y),replace=TRUE)
  # init[[i]] <- list(tau_add=1/var(diff(y.samp)),  ## initial guess on process precision
  #                   tau_obs=5/var(y.samp))        ## initial guess on obs precision
  init[[i]] <- list(tau_add=500,  ## initial guess on process precision
                    tau_obs_gcc=500,
                    tau_obs_evi=500)        ## initial guess on obs precision
}

####
# Presenting basic model to JAGS
j.model   <- jags.model (file = textConnection(RandomWalk),
                         data = data,
                         inits = init,
                         n.chains = 3)

# Running first MCMC and assessing convergence
jags.out   <- coda.samples (model = j.model,
                            variable.names = c("tau_add","tau_obs_gcc","tau_obs_evi"),
                            n.iter = 1000)
plot(jags.out)


# Now that the model has converged we'll want to take a much larger sample from the MCMC and include the full vector of X's in the output

jags.out   <- coda.samples (model = j.model,
                            variable.names = c("x","tau_add","tau_obs_gcc","tau_obs_evi"),
                            n.iter = 10000)

# time <- gcc_dat_short$time
# time.rng = c(1,length(time))       ## adjust to zoom in and out
out <- as.matrix(jags.out)         ## convert from coda to matrix  
x.cols <- grep("^x",colnames(out)) ## grab all columns that start with the letter x
ci <- apply(out[,x.cols],2,quantile,c(0.025,0.5,0.975)) ## model was fit on log scale

newdat<-all_dat %>% 
  filter(date>=mindate) %>% 
  cbind(t(ci))
write_rds(newdat, "./data/random walk output.rds")
ggplot(newdat)+
  geom_line(aes(x=date, y=gcc_90), col="dark green")+
  geom_point(aes(x=date, y=evi), col="light green")+
  geom_ribbon(aes(x=date, ymin=`2.5%`, ymax=`97.5%`), fill="blue", alpha=0.5)+
  geom_line(aes(x=date, y=`50%`), col="blue")+
  facet_wrap(.~site)+
  theme_classic()

