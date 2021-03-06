#' Average expression within neighbourhoods
#'
#' This function calculates the mean expression of each feature in the
#' Milo object stored in the assays slot. Neighbourhood expression data are
#' stored in a new slot \code{nhoodExpression}.
#'
#' @param x A \code{Milo} object with \code{nhoods} slot populated, alternatively a NxM indicator matrix
#' of N cells and M nhoods.
#' @param assay A character scalar that describes the assay slot to use for calculating neighbourhood expression.
#' @param subset.row A logical, integer or character vector indicating the rows
#' of \code{x} to use for sumamrizing over cells in neighbourhoods.
#' @param exprs If \code{x} is a list of neighbourhoods, \code{exprs} is a matrix of genes X
#' cells to use for calculating neighbourhood expression.
#'
#' @details
#' This function computes the mean expression of each gene, subset by \code{subset.rows}
#' where present, across the cells contained within each neighbourhood.
#'
#' @return A \code{\linkS4class{Milo}} object with the \code{nhoodExpression} slot populated.
#'
#' @author
#' Mike Morgan
#'
#' @examples
#' require(SingleCellExperiment)
#' m <- matrix(rnorm(100000), ncol=100)
#' milo <- Milo(SingleCellExperiment(assays=list(logcounts=m)))
#' milo <- buildGraph(m, k=20, d=30)
#' milo <- makeNhoods(milo)
#' milo <- calcNhoodExpression(milo)
#' dim(nhoodExpression(milo))
#'
#' @name calcNhoodExpression
NULL

#' @export
#' @rdname calcNhoodExpression
#' @import SingleCellExperiment
calcNhoodExpression <- function(x, assay="logcounts", subset.row=NULL, exprs=NULL){

    if(is(x, "Milo")){
        # are neighbourhoods calculated?
        if(ncol(nhoods(x)) == 1 & nrow(nhoods(x)) == 1){
            stop("No neighbourhoods found - run makeNhoods first")
        }

        if(!is.null(assay(x, assay))){
            n.exprs <- .calc_expression(nhoods=nhoods(x),
                                        data.set=assay(x, assay),
                                        subset.row=subset.row)
            nhoodExpression(x) <- n.exprs
            return(x)
        }
    } else if(is(x, "Matrix")){
        if(is.null(exprs)){
            stop("No expression data found. Please specific a gene expression matrix to exprs")
        } else{
            n.exprs <- .calc_expression(nhoods=x,
                                        data.set=exprs,
                                        subset.row=subset.row)
            x.milo <- Milo(SingleCellExperiment(assay=list(logcounts=exprs)))
            nhoodExpression(x.milo) <- n.exprs
            return(x.milo)
        }
    }
}


#' @importFrom Matrix tcrossprod colSums t
.calc_expression <- function(nhoods, data.set, subset.row=NULL){
    # neighbour.model <- matrix(0L, ncol=length(nhoods), nrow=ncol(data.set))
    #
    # for(x in seq_along(1:length(nhoods))){
    #     neighbour.model[nhoods[[x]], x] <- 1
    # }

    if(!is.null(subset.row)){
        if(is(data.set[subset.row,], "Matrix")){
            neigh.exprs <- Matrix::tcrossprod(Matrix::t(nhoods), data.set[subset.row,])
        }else{
            neigh.exprs <- Matrix::tcrossprod(Matrix::t(nhoods), as(data.set[subset.row,], "dgeMatrix"))
        }
    } else{
        neigh.exprs <- Matrix::tcrossprod(Matrix::t(nhoods), data.set)
    }
    neigh.exprs <- t(apply(neigh.exprs, 2, FUN=function(XP) XP/colSums(nhoods)))

    if(is.null(subset.row)){
        rownames(neigh.exprs) <- rownames(data.set)
    } else{
        rownames(neigh.exprs) <- rownames(data.set[subset.row, , drop=FALSE])
    }

    return(neigh.exprs)
}


