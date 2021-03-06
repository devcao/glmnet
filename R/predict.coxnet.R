#' @method predict coxnet
#' @export
predict.coxnet=function(object,newx,s=NULL,type=c("link","response","coefficients","nonzero"),exact=FALSE,newoffset,...){
  type=match.arg(type)
  ###coxnet has no intercept, so we treat it separately
  if(missing(newx)){
    if(!match(type,c("coefficients","nonzero"),FALSE))stop("You need to supply a value for 'newx'")
  }
  if(exact&&(!is.null(s))){
    lambda=object$lambda
    which=match(s,lambda,FALSE)
    if(!all(which>0)){
      lambda=unique(rev(sort(c(s,lambda))))
        check_dots(object,...)# This fails if you don't supply the crucial arguments
        object=update(object,lambda=lambda,...)
    }
  }

  nbeta=object$beta
   if(!is.null(s)){
    vnames=dimnames(nbeta)[[1]]
    dimnames(nbeta)=list(NULL,NULL)
    lambda=object$lambda
    lamlist=lambda.interp(lambda,s)
    nbeta=nbeta[,lamlist$left,drop=FALSE]%*%Diagonal(x=lamlist$frac) +nbeta[,lamlist$right,drop=FALSE]%*%Diagonal(x=1-lamlist$frac)
    dimnames(nbeta)=list(vnames,paste(seq(along=s)))
  }
  if(type=="coefficients")return(nbeta)
  if(type=="nonzero")return(nonzeroCoef(nbeta,bystep=TRUE))
  nfit=as.matrix(newx%*%nbeta)
  if(object$offset){
    if(missing(newoffset))stop("No newoffset provided for prediction, yet offset used in fit of glmnet",call.=FALSE)
    nfit=nfit+array(newoffset,dim=dim(nfit))
  }
  switch(type,
         response=exp(nfit),
         link=nfit
         )
}
