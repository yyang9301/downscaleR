##############################################################################################################
#                     Generalized Linear Models (GLM)                                                        #
##############################################################################################################
#' @title Donwscaling with generalized linear models (GLM).
#' @description Donwscaling with generalized linear models (GLM) with the base function \code{\link[stats]{glm}}.
#' @param x The grid data. Class: matrix.
#' @param y The observations data. Class: matrix.
#' @param fitting A string indicating the types of objective functions and how to fit the linear model.
#' @param simulate A string indicating wether we want a stochastic or a deterministic GLM. Stochastic GLMs only accept gamma 
#' or binomial families.
#' @param ... Optional parameters. See the parameter fitting for more information.
#' \itemize{
#' \item \code{fitting = NULL} In this case the generalized linear model uses the \code{\link[stats]{glm}} function to fit the linear model. 
#' This is the default option.
#' The optional parameters when fitting = NULL are:
  #' \itemize{
  #' \item \code{family} A string indicating a description of the error distribution. Options are 
  #' family = c("gaussian","binomial","Gamma","inverse.gaussian","poisson","quasi","quasibinomial","quasipoisson"). 
  #' The links can be also specified and can be found in \code{\link[stats]{family}}.
  #' \item \code{na.action} A function which indicates what should happen when the data contain NAs. 
  #' The default is set by the na.action setting of options, and is na.fail if that is unset. 
  #' The ‘factory-fresh’ default is na.omit. Another possible value is NULL, no action. Value na.exclude can be useful.
  #' }
#' \item \code{fitting = "stepwise"} Indicates a stepwise regression via \code{\link[stats]{glm}} and \code{\link[stats]{step}}.
#' The optional parameters are the same than for fitting = NULL. The stepwise performs always a forward selection search stopping
#' based on the AIC criterion.
#' \item \code{fitting = c("L1","L2","L1L2","gLASSO")}. These four options refer to ridge regression (L1 penalty), lasso regression (L2 penalty),
#' elastic-net regression (L1L2 penalty) and group Lasso regression (group L2 penalty). The model is fitted via 
#' \code{\link[glmnet]{glmnet}} and the corresponding penalties are found via \code{\link[glmnet]{cv.glmnet}}. This function \code{\link[glmnet]{glmnet}}
#' forces by default to standardize predictors, however we have changed it to standardize = FALSE, and standardization should be done prior to 
#' the downscaling process. 
#' The optional parameters when fitting = c("L1","L2","L1L2","gLASSO") are:
  #' \itemize{
  #' \item \code{family} A string indicating a description of the error distribution. Options are 
  #' family = c("gaussian","binomial","Gamma","inverse.gaussian","poisson","quasi","quasibinomial","quasipoisson"). 
  #' The links CAN NOT be specified as the \code{\link[glmnet]{glmnet}} has not been programmed to handle links.
  #' However, the default ones can be found in \code{\link[stats]{family}}. If fitting = "gLASSO" then family must be "mgaussian".
  #' \item \code{offset} A vector of length nobs that is included in the linear predictor (a nobs x nc matrix for the "multinomial" family). 
  #' Useful for the "poisson" family (e.g. log of exposure time), or for refining a model by starting at a current fit. 
  #' Default is NULL. If supplied, then values must also be supplied to the predict function.
  #' }
#' \item \code{MP} Solves the ordinary least squares (OLS) by a Moore-Penrose (MP) inverse. No more optional parameters
#' are permitted when fitting = "MP". Multisite can be performed in this way of fitting the model.
#' }
#' There are two things to consider. 
#' 1) If family = "binomial" then type = "response" when predicting values.
#' 2) Except for fitting = "MP", for the rest of the fitting options, the parameter singlesite must be TRUE, unless 
#' we want a gLASSO which in this case singlesite must be FALSE.
#' @return The GLM model as returned from \code{\link[stats]{glm}} plus a list with information concerning the experiment.
#' @details This function is internal and should not be used by the user. The user should use \code{\link[downscaleR]{downscale.train}} or \code{\link[downscaleR]{downscale.cv}}.
#' @author J. Bano-Medina
#' @importFrom stats step formula
#' @import glmnet
#' @export
glm.train <- function(x, y, fitting = NULL, simulate = "no", ...) {
  if (is.null(fitting)) {
    df <- data.frame(cbind(y,x)); colnames(df) <- paste0('X',1:(dim(x)[2] + 1))
    weights <- glm(X1~.,data = df, ...)
  }
  else if (fitting == "MP") {
    x <- cbind(x,array(data = 1,dim = c(nrow(x), 1)))
    weights <- ginv(data.matrix(x)) %*% data.matrix(y)
  }
  else if (fitting == "stepwise") {
    df <- data.frame(cbind(y,x)); colnames(df) <- paste0('X',1:(dim(x)[2] + 1))
    fullmod <- glm(X1~.,data = df,...)
    nothing <- glm(X1~1.,data = df,...)
    weights <- step(nothing, scope = list(lower = formula(nothing),upper = formula(fullmod)),
                    direction = "forward")
  }
  else if (fitting == "L1") {
    cv <- cv.glmnet(x,y,alpha = 1, ...)
    weights <- glmnet(x,y,alpha = 1, standardize = FALSE, lambda = cv$lambda.1se, ...)
  }
  else if (fitting == "L2") {
    cv <- cv.glmnet(x,y,alpha = 0, ...)
    weights <- glmnet(x,y,alpha = 0, standardize = FALSE, lambda = cv$lambda.1se, ...)
  }
  else if (fitting == "L1L2") {
    alphalist <- seq(0,1,by = 0.1)
    cv <- lapply(alphalist, function(z){
      c <- cv.glmnet(x, y, alpha = z, ...)
      return(list("alpha" = z, "lambda" = c$lambda.1se, "validation" = min(c$cvm)))})
    alpha <- lambda <- val <- vector(mode = "numeric", length = length(alphalist))
    for (i in 1:length(alphalist)) {
      alpha[i] <- cv[[i]]$alpha
      lambda[i] <- cv[[i]]$lambda
      val[i] <- cv[[i]]$validation}
    alpha_winner  <- alpha[which(val == min(val))]
    lambda_winner <- lambda[which(val == min(val))]
    weights <- glmnet(x,y,alpha = alpha_winner, standardize = FALSE, lambda = lambda_winner, ...)
  }
  else if (fitting == "gLASSO") {
    cv <- cv.glmnet(x,y,alpha = 0, family = "mgaussian", ...)
    weights <- glmnet(x,y,alpha = 0, family = "mgaussian", type.multinomial = "grouped", ...)
  }
  
  arglist <- list(...) 
  if (is.null(arglist$family)) {family = "gaussian"}
  else {family <- arglist$family}
  return(list("weights" = weights, "info" = list("fitting" = fitting, "simulate" = simulate, "family" = family)))}

#' @title Donwscaling with a given generalized linear model (GLM).
#' @description Donwscaling with a given generalized linear models (GLM) calculated in \code{\link[downscaleR]{downscale.predict}} via \code{\link[downscaleR]{glm.train}}.
#' @param x The grid data. Class: matrix.
#' @param weights Object as returned from \code{\link[downscaleR]{glm.train}}
#' @param info A list containing information of the experiment: the fitting, the family of the generalized linear model and 
#' if it is deterministic or stochastic.
#' @return The predicted matrix.
#' @details Predicts by using the base function \code{\link[stats]{predict}}. This function is internal and should not be used by the user.
#' The user should use \code{\link[downscaleR]{downscale.predict}}.
#' @author J. Bano-Medina
#' @export
glm.predict <- function(x, weights, info) {
  if (is.null(info$fitting) || info$fitting == "stepwise") {
    df <- data.frame(x); colnames(df) <- paste0('X',2:(dim(x)[2] + 1))
    pred <- predict(weights, newdata = df, type = 'response')
  }
  else if (info$fitting == "MP") {
    x <- cbind(x,array(data = 1,dim = c(nrow(x), 1)))
    pred <- data.matrix(x) %*% weights
  }
  else if (info$fitting == "L1" || info$fitting == "L2" || info$fitting == "L1L2" || info$fitting == "gLASSO") {
    pred <- drop(predict(weights,x,type = "response"))
  }
  if (info$simulate == "yes") {
    if (info$family == "binomial") {
      rnd <- runif(length(pred), min = 0, max = 1)
      ind01 <- which(pred > rnd)
      pred[ind01] <- 1
      pred[-ind01] <- 0
    }
    else if (info$family == "Gamma") {
      pred <- rgamma(n = length(pred), shape = 1/summary(weights)$dispersion, scale = summary(weights)$dispersion * pred)
    }
  }
  return(pred)}