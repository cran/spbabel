#' Convert from Spatial*DataFrame to table.
#'
#' Decompose a Spatial object to a single table structured as a row for every coordinate in all the sub-geometries, including duplicated coordinates that close polygonal rings, close lines and shared vertices between objects. 
#' 
#' Input can be a \code{\link[sp]{SpatialPolygonsDataFrame}}, \code{\link[sp]{SpatialLinesDataFrame}} or a \code{\link[sp]{SpatialPointsDataFrame}}.
#' @param x \code{\link[sp]{Spatial}} object
#' @param ... ignored
#'
#' For simplicity \code{sptable} and its inverse \code{sp} assume that all geometry can be encoded with object, branch, island, order, x and y. 
#' and that the type of topology is identified by which of these are present. 
#' @return \code{\link[dplyr]{tbl_df}} data_frame with columns
#' \itemize{
#'  \item SpatialPolygonsDataFrame "object_"   "branch_"   "island_"   "order_" "x"    "y_"
#'  \item SpatialLinesDataFrame "object_"   "branch_" "order_"  "x_"      "y_"
#'  \item SpatialPointsDataFrame  "object_" x_"      "y_"
#'  \item SpatialMultiPointsDataFrame "object_" "branch_" "x_" "y_"
#' }
#' @export
#'
sptable <- function(x, ...) {
  UseMethod("sptable")
}

#' @export
#' @rdname sptable
sptable.SpatialPolygonsDataFrame <- function(x, ...) {
  .gobbleGeom(x, ...)
}

#' @export
#' @rdname sptable
sptable.SpatialLinesDataFrame <- function(x, ...) {
  mat2d_f(.gobbleGeom(x, ...))
}

#' @export
#' @rdname sptable
#' @importFrom dplyr bind_cols
sptable.SpatialPointsDataFrame <- function(x, ...) {
  #df <- mat2d_f(.pointsGeom(x, ...))
  df <- .pointsGeom(x, ...)
  df$object_ <- as.integer(df$object_) ## not needed once .pointsGeom uses tbl_df
  df
}

#' @export
#' @rdname sptable
#' @importFrom dplyr bind_cols
sptable.SpatialMultiPointsDataFrame <- function(x, ...) {
   #df <- mat2d_f(.pointsGeom(x))
  df <- .pointsGeom(x, ...)
   df$object_ <- as.integer(df$object_) 
   df$branch_ <- as.integer(df$branch_) 
   df
}
## TODO multipoints
#' @importFrom dplyr data_frame
mat2d_f <- function(x) {
  as_data_frame(as.data.frame((x)))
}


#' @rdname sptable
#' @param object Spatial object
#' @param value modified sptable version of object
#'
#' @return Spatial object
#' @export
"sptable<-" <-
  function(object, value) {
       sp(value, as.data.frame(object), proj4string(object))

  }





.coordsIJ <- function(x, i, j, type) {
  switch(type, 
         line = x@lines[[i]]@Lines[[j]]@coords, 
         poly =  x@polygons[[i]]@Polygons[[j]]@coords)
}

.nsubobs <- function(x, i, type) {
  length(
    switch(type, 
         line = x@lines[[i]]@Lines, 
         poly = x@polygons[[i]]@Polygons)
)
}
.holes <- function(x, i, j, type) {
  switch(type, 
         line = NULL, 
         ## negate here since it will be NULL outside for lines
         poly = !x@polygons[[i]]@Polygons[[j]]@hole
         )
}
## adapted from raster package R/geom.R
## generalized on Polygon and Line
#' @importFrom sp geometry
#' @importFrom dplyr bind_rows
.gobbleGeom <-   function(x,  ...) {
  gx <- geometry(x)
  typ <- switch(class(gx), 
                SpatialPolygons = "poly", 
                SpatialLines = "line")
  nobs <- length(geometry(x))
  objlist <- vector("list", nobs)
  cnt <- 0L
  for (i in seq(nobs)) {
      nsubobs <- .nsubobs(x, i, typ) 
      ps <- lapply(1:nsubobs,
                   function(j) {
                     coords <- .coordsIJ(x, i, j, typ)
                     nr <- nrow(coords)
                     lst <- list(
                                 branch_ = rep(j + cnt, nr), 
                                 island_ = rep(.holes(x, i, j, typ), nr), 
                                 order_ = seq(nr),
                                 x_ = coords[,1], 
                                 y_ = coords[,2])
                     as_data_frame(lst[!sapply(lst, is.null)])
                   }
      )
      psd <- do.call(bind_rows, ps)
      objlist[[i]] <- bind_cols(data_frame(object_ = rep(i, nrow(psd))), psd)
      cnt <- cnt + nsubobs
    }
  obs <- do.call(bind_rows, objlist)
  
  rownames(obs) <- NULL

  attr(obs, "crs") <- proj4string(x)
  return( obs )
}




.pointsGeom <-  function(x, ...) {
  ## this will have to become a tbl
  xy <- as_data_frame(as.data.frame(coordinates(x)))
  cnames <- c('object_', 'x_', 'y_')
  ##xy <- cbind(1:nrow(xy), xy)
  if (is.list(x@coords)) {
    br <- rep(seq_along(x@coords), unlist(lapply(x@coords, nrow)))
    cnames <- c('branch_', 'object_', 'x_', 'y_')
    xy <- bind_cols(data_frame(br), data_frame(br), xy)
  } else {
    br <- seq(nrow(xy))
    xy <- bind_cols(data_frame(br), xy)
  }
  
  colnames(xy) <- cnames
  return(xy)
}
