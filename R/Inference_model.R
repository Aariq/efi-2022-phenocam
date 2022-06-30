##Jussi 6-30
##Inference for phenology

#Steps:
#1. inference model
#2. model validation
#3. forecast

library(rjags)
library(coda)
#for x add the environmental covariates, for y add the response variable
#y:s in validation/forecasting points should be NAs

train_data_all <- list(x = , y = y, n = n)
train_data_valid <- list(x = , y = y, n = n)

## Linear model
#set the model
linear_model = function(train_data_all, train_data_valid, test_data, forecast_data) {
  
  univariate_regression <- "
  model{

  beta ~ dmnorm(b0,Vb)  	## multivariate Normal prior on vector of regression params
  sigma ~ dgamma(s0,Vs)

  for(i in 1:n){
	  mu[i] <- beta[1] + beta[2]*x[i,1] #+ beta[3]*x[i,2]  	## process model
	  y[i]  ~ dnorm(mu[i], sigma)		        ## data model
  }
}
"

## initial conditions
nchain = 3
inits <- list()
for(i in 1:nchain){
  inits[[i]] <- list(beta = rnorm(2,0,5), sigma = rgamma(1, .1))
}

## specify priors
data = train_data_valid
data$b0 <- as.vector(c(0,0,0))      ## regression beta means
data$Vb <- solve(diag(10000,2))   ## regression beta precisions
data$s0 <- .1      ## sigma
data$Vs <- .1   ## sigma

#Validation
j.model <- jags.model(file = textConnection(univariate_regression),
                      data = data, 
                      inits = inits, 
                      n.chains = nchain,
                      n.adapt = 1000)

n.iter.temp = 2000
var.out <- coda.samples(model = j.model, variable.names = c("mu", "y"),
                        n.iter = n.iter.temp)

#x_pred = test_data$x
#y_true = test_data$y
#y_pred_samp = t(as.matrix(var.mat[,c(2,3)])%*%t(as.matrix(x_pred))) +
#matrix(rep(var.mat[,1], length(x_pred)), ncol = length(var.mat[,1]), byrow = F)
#y_pred = apply(exp(y_pred_samp), 1, mean)
#y_pred_low = apply(exp(y_pred_samp), 1, function(x) quantile(x,.025))
#y_pred_high = apply(exp(y_pred_samp), 1, function(x) quantile(x,.975))

RMSE = sqrt(mean((y_true - y_pred)^2))
Type1 = sum(y_true<y_pred_high & y_true>y_pred_low)/length(y_true)

#Forecast
data = train_data_all
data$b0 <- as.vector(c(0,0,0))      ## regression beta means
data$Vb <- solve(diag(10000,3))   ## regression beta precisions
data$s0 <- .1      ## sigma
data$Vs <- .1   ## sigma

j.model <- jags.model(file = textConnection(univariate_regression),
                      data = data, 
                      inits = inits, 
                      n.chains = nchain,
                      n.adapt = 1000)

n.iter.temp = 2000
var.out <- coda.samples(model = j.model, variable.names = c("beta", "sigma"),
                        n.iter = n.iter.temp)

x_pred = forecast_data$x
y_true = forecast_data$y
y_pred_samp = t(as.matrix(var.mat[,c(2,3)])%*%t(as.matrix(x_pred))) +
  matrix(rep(var.mat[,1], length(x_pred)), ncol = length(var.mat[,1]), byrow = F)
y_pred = apply(exp(y_pred_samp), 1, mean)
y_pred_low = apply(exp(y_pred_samp), 1, function(x) quantile(x,.025))
y_pred_high = apply(exp(y_pred_samp), 1, function(x) quantile(x,.975))

model_output = list('RMSE' = RMSE, 'Type1' = Type1, 'Forecast_mean' = y_pred,
                    'Forecast_low' = y_pred_low, 'Forecast_high' = y_pred_high)
}


## Linear dynamic model
#set the model
linear_dynamic_model = function(train_data_all, train_data_valid, test_data, forecast_data) {
  
  univariate_regression <- "
  model{

  beta ~ dmnorm(b0,Vb)  	## multivariate Normal prior on vector of regression params
  sigma_proc ~ dgamma(s0,Vs)
  sigma ~ dgamma(s0,Vs)
  mu[1] ~ dnorm(mu_ic,tau_ic)

  #### Process Model
  for(t in 2:n){
    mu[t]~dnorm(mu[t-1]  + beta[1] + beta[2]*x[i,1] + beta[3]*x[i,2], sigma_proc)
  }

  for(i in 1:n){
	  y[i]  ~ dnorm(mu[i], sigma)		        ## data model
  }
}
"

## initial conditions
nchain = 3
inits <- list()
for(i in 1:nchain){
  inits[[i]] <- list(beta = rnorm(2,0,5), sigma = rgamma(1, .1), sigma_proc = rgamma(1, .1))
}

#Validation
## specify priors
data = train_data_valid
data$b0 <- as.vector(c(0,0,0))      ## regression beta means
data$Vb <- solve(diag(10000,3))   ## regression beta precisions
data$s0 <- .1      ## sigma and sigma_proc
data$Vs <- .1   ## sigma and sigma_proc
data$x_ic=log(1)
data$tau_ic=100

j.model <- jags.model(file = textConnection(univariate_regression),
                      data = data, 
                      inits = inits, 
                      n.chains = nchain,
                      n.adapt = 1000)

n.iter.temp = 2000
var.out <- coda.samples(model = j.model, variable.names = c("beta", "sigma", "sigma_proc"),
                        n.iter = n.iter.temp)

x_pred = test_data$x
y_true = test_data$y
y_pred_samp = t(as.matrix(var.mat[,c(2,3)])%*%t(as.matrix(x_pred))) +
  matrix(rep(var.mat[,1], length(x_pred)), ncol = length(var.mat[,1]), byrow = F)
y_pred = apply(exp(y_pred_samp), 1, mean)
y_pred_low = apply(exp(y_pred_samp), 1, function(x) quantile(x,.025))
y_pred_high = apply(exp(y_pred_samp), 1, function(x) quantile(x,.975))

#y_pred = exp(mean(var.mat[,1]) + mean(var.mat[,2])*x_pred[,2] + mean(var.mat[,3])*x_pred[,3])
#y_pred_low = exp(quantile(var.mat[,1], .025) + quantile(var.mat[,2],.025)*x_pred[,2] + quantile(var.mat[,3],.025)*x_pred[,3])
#y_pred_high = exp(quantile(var.mat[,1], .975) + quantile(var.mat[,2],.975)*x_pred[,2] + quantile(var.mat[,3],.975)*x_pred[,3])

RMSE = sqrt(mean((y_true - y_pred)^2))
Type1 = sum(y_true<y_pred_high & y_true>y_pred_low)/length(y_true)

#Forecast
data = train_data_all
data$b0 <- as.vector(c(0,0,0))      ## regression beta means
data$Vb <- solve(diag(10000,3))   ## regression beta precisions
data$s0 <- .1      ## sigma and sigma_proc
data$Vs <- .1   ## sigma and sigma_proc
data$x_ic=log(1)
data$tau_ic=100

j.model <- jags.model(file = textConnection(univariate_regression),
                      data = data, 
                      inits = inits, 
                      n.chains = nchain,
                      n.adapt = 1000)

n.iter.temp = 2000
var.out <- coda.samples(model = j.model, variable.names = c("beta", "sigma"),
                        n.iter = n.iter.temp)

x_pred = forecast_data$x
y_true = forecast_data$y
y_pred_samp = t(as.matrix(var.mat[,c(2,3)])%*%t(as.matrix(x_pred))) +
  matrix(rep(var.mat[,1], length(x_pred)), ncol = length(var.mat[,1]), byrow = F)
y_pred = apply(exp(y_pred_samp), 1, mean)
y_pred_low = apply(exp(y_pred_samp), 1, function(x) quantile(x,.025))
y_pred_high = apply(exp(y_pred_samp), 1, function(x) quantile(x,.975))

model_output = list('RMSE' = RMSE, 'Type1' = Type1, 'Forecast_mean' = y_pred,
                    'Forecast_low' = y_pred_low, 'Forecast_high' = y_pred_high)
}
