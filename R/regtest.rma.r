regtest.rma <- function(x, model="rma", predictor="sei", ret.fit=FALSE, digits, ...) {

   #########################################################################

   mstyle <- .get.mstyle("crayon" %in% .packages())

   if (!inherits(x, "rma"))
      stop(mstyle$stop("Argument 'x' must be an object of class \"rma\"."))

   if (inherits(x, "robust.rma"))
      stop(mstyle$stop("Method not available for objects of class \"robust.rma\"."))

   if (inherits(x, "rma.glmm"))
      stop(mstyle$stop("Method not available for objects of class \"rma.glmm\"."))

   if (inherits(x, "rma.mv"))
      stop(mstyle$stop("Method not available for objects of class \"rma.mv\"."))

   if (inherits(x, "rma.ls"))
      stop(mstyle$stop("Method not available for objects of class \"rma.ls\"."))

   model <- match.arg(model, c("lm", "rma"))
   predictor <- match.arg(predictor, c("sei", "vi", "ni", "ninv", "sqrtni", "sqrtninv"))

   if (missing(digits)) {
      digits <- .get.digits(xdigits=x$digits, dmiss=TRUE)
   } else {
      digits <- .get.digits(digits=digits, xdigits=x$digits, dmiss=FALSE)
   }

   #########################################################################

   yi <- x$yi
   vi <- x$vi
   weights <- x$weights
   ni <- x$ni ### may be NULL
   X  <- x$X
   p  <- x$p

   if (predictor == "sei")
      X <- cbind(X, sei=sqrt(vi))

   if (predictor == "vi")
      X <- cbind(X, vi=vi)

   if (is.element(predictor, c("ni", "ninv", "sqrtni", "sqrtninv"))) {

      if (is.null(ni)) {
         stop(mstyle$stop("No sample size information stored in model object."))

      } else {

         if (predictor == "ni")
            X <- cbind(X, ni=ni)
         if (predictor == "ninv")
            X <- cbind(X, ninv=1/ni)
         if (predictor == "sqrtni")
            X <- cbind(X, ni=sqrt(ni))
         if (predictor == "sqrtninv")
            X <- cbind(X, ni=1/sqrt(ni))

      }

   }

   ### check if X of full rank (if not, cannot carry out the test)

   tmp <- lm(yi ~ X - 1)
   coef.na <- is.na(coef(tmp))
   if (any(coef.na))
      stop(mstyle$stop("Model matrix no longer of full rank after addition of predictor. Cannot fit model."))

   if (model == "rma") {

      fit  <- rma.uni(yi, vi, weights=weights, mods=X, intercept=FALSE, method=x$method, weighted=x$weighted, test=x$test, tau2=ifelse(x$tau2.fix, x$tau2, NA), control=x$control, ...)
      zval <- fit$zval[p+1]
      pval <- fit$pval[p+1]
      dfs  <- fit$dfs

   } else {

      yi   <- c(yi) ### to remove attributes
      fit  <- lm(yi ~ X - 1, weights=1/vi)
      fit  <- summary(fit)
      zval <- coef(fit)[p+1,3]
      pval <- coef(fit)[p+1,4]
      dfs  <- x$k - x$p - 1

   }

   res <- list(model=model, predictor=predictor, zval=zval, pval=pval, dfs=dfs, method=x$method, digits=digits, ret.fit=ret.fit, fit=fit)

   class(res) <- "regtest.rma"
   return(res)

}
