run_model <- function(date_list, RandomWalk, all_dat, batch, mindate, outdir = "./forecasts/") {
  for (d in 1:length(date_list)) {
    today <- date_list[d]
    
    # create dir
    dir.create(paste0(outdir, today), recursive = T)
    
    # subset data
    dat_new <- all_dat %>%
      filter(date >= today - batch) %>%
      mutate( # set data after today to NA
        gcc_90 = case_when(date < today ~ gcc_90),
        gcc_sd = case_when(date < today ~ gcc_sd),
        evi = case_when(date < today ~ evi),
        evi_sd = case_when(date < today ~ evi_sd)
      )
    
    # make matrices for observations
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
    
    # load previous data
    if (d ==1) {
      
      dat_old <- all_dat %>%
        filter(date>=mindate) %>% 
        head(0)
    } else {
      prev_day <- date_list[d - 1]
      dat_old<-read_rds(paste0(outdir, prev_day, "/data.rds")) %>% 
        filter(date<prev_day)
    }
    
    # load priors
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
      priors <- read_rds(paste0(outdir, prev_day, "/posterior.rds"))
    }
    
    
    # Setting data and prior for the model
    data <- c(
      list(
        gcc = gcc,
        evi = evi,
        nt = nrow(gcc),
        ns = ncol(gcc) ## data
      ),
      priors
    )
    
  
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
  
  # run MCMC
  jags.out <- coda.samples(
    model = j.model,
    variable.names = c("x", "tau_add", "tau_obs_gcc", "tau_obs_evi"),
    n.iter = 1000
  )
  out <- as.matrix(jags.out) ## convert from coda to matrix
  
  # Save posteriors
  x_ic <- tau_ic <- rep(NA, ncol(gcc))
  for (s in 1:ncol(gcc)) {
    x.col <- paste0("x[", batch+1, ",", s, "]")
    x_ic[s] <- mean(out[, x.col])
    tau_ic[s] <- 1 / sd(out[, x.col])^2
  }
  mu_obs_gcc<-mean(out[, "tau_obs_gcc"])
  sd_obs_gcc<-sd(out[, "tau_obs_gcc"])
  mu_obs_evi<-mean(out[, "tau_obs_evi"])
  sd_obs_evi<-sd(out[, "tau_obs_evi"])
  mu_add<-mean(out[, "tau_add"])
  sd_add<-sd(out[, "tau_add"])
  
  posteriors <- list(
    x_ic = x_ic, tau_ic = tau_ic, ## initial condition prior
    a_obs_gcc = (mu_obs_gcc/sd_obs_gcc)^2,
    r_obs_gcc =mu_obs_gcc/sd_obs_gcc^2, ## obs error prior
    a_obs_evi = (mu_obs_evi/sd_obs_evi)^2,
    r_obs_evi = mu_obs_evi/sd_obs_evi^2, ## obs error prior
    a_add = (mu_add/sd_add)^2,
    r_add = mu_add/sd_add^2
  )
  write_rds(posteriors, paste0(outdir, today, "/posterior.rds"))
  
  # plot
  x.cols <- grep("^x", colnames(out)) ## grab all columns that start with the letter x
  ci <- apply(out[, x.cols], 2, quantile, c(0.025, 0.5, 0.975)) ## model was fit on log scale
  
  dat_fitted <- bind_rows(dat_old,
                          dat_new %>%
                            cbind(t(ci))
  )
  write_rds(dat_fitted, paste0(outdir, today, "/data.rds"))
  
  p <- ggplot(dat_fitted) +
    geom_line(aes(x = date, y = gcc_90), col = "dark green") +
    geom_point(aes(x = date, y = evi), col = "light green") +
    geom_ribbon(aes(x = date, ymin = `2.5%`, ymax = `97.5%`), fill = "blue", alpha = 0.5) +
    geom_line(aes(x = date, y = `50%`), col = "blue") +
    facet_wrap(. ~ site) +
    theme_classic()
  
  cairo_pdf(paste0(outdir, today, "/plot.pdf"))
  print(p)
  dev.off()
  
  print (paste0(today, " completed."))
  }
}