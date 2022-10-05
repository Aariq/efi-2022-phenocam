model_RandomWalk <- function() {
  "
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
}