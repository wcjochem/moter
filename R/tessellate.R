#' Create morphological tessellations
#'
#' @param X Spatial polygons of building footprints.
#' @param unique_id String of a column name in \code{X} with unique IDs.
#' @param limit Spatial polygon defining the study area.
#' @param shrink Distance for inward buffer on building footprints. Default 0.4.
#' @param segment Distance (in meters) between points created on building
#'   footprint segments. Default 0.5.
#' @param verbose Display progress. Default True.
#'
#' @return A spatial dataset in \code{sf} format of the tessellation polygons.
#'
#' @details The algorithm is described by Fleischmann et al. (2020). If the
#'   building footprints are unprojected (i.e using WGS 84 coordinates reference
#'   system), note that \code{moter} makes a quick approximation for distances
#'   for the shrink and segment parameters.
#'
#' @seealso \url{https://docs.momepy.org}
#' @references Fleischmann, M., A. Feliciotti, O. Romice, S. Porta (2020).
#'   "Morphological tessellation as a way of partitioning space: Improving
#'   consistency in urban morphology at the plot scale." \emph{Computers,
#'   Environment, & Urban Systems}, 80,
#'   101441.\url{https://doi.org/10.1016/j.compenvurbsys.2019.101441}
#'
#' @examples
#'
#' @name motess
#' @export
motess <- function(X, unique_id, limit, shrink=0.4, segment=0.5, verbose=TRUE){
  # add data checks
  if(!inherits(X, "sf")){
    stop("Building footprints should be `sf` format")
  }

  if(missing(unique_id)){
    stop("Please provide a column name of unique IDs.")
  } else {
    if(!inherits(unique_id, "character")){
      stop("Please provide a valid column name of unique IDs.")
    }
    if(length(unique_id) > 1) unique_id <- unique_id[1]

    if(!unique_id %in% names(X)){
      stop("Please provide a valid column name of unique IDs.")
    }
  }

  if(any(sf::st_geometry_type(X) %in% "MULTIPOLYGON")){
    X <- sf::st_cast(X, "POLYGON")

    uID <- strsplit(row.names(X), split=".", fixed=T)
    uID <- sapply(uID, "[", 2)
    uID <- ifelse(is.na(uID), "", paste0(".", uID))

    X[[unique_id]] <- paste0(X[[unique_id]], uID)
  }

  if(any(duplicated(X[[unique_id]]))){
    stop("Building footprints must have a unique ID.")
  }

  if(missing(limit)){
    limit <- sf::st_as_sfc(sf::st_bbox(X))
  } else{
    if(!inherits(X, c("sf","sfc"))){
      stop("Study limit should be 'sf' or 'sfc' type.")
    }
  }

  if(sf::st_is_longlat(X)){
    # quick and dirty approximation
    # add st_transform
    shrink <- shrink / 111111
  }

  if (verbose) cat("Inward offset...\n")
  X <- sf::st_buffer(X, dist=(-1*shrink))

  if(verbose) cat("Discretization...\n")
  segs <- sf::st_segmentize(X, segment)
  # check for NULL geoms (caused by small footprints)
  geodim <- sf::st_dimension(segs)
  if(any(is.na(geodim))){
    segs <- segs[-which(is.na(geodim)), ]
  }

  # check for inhomogenous geometry types
  if(class(sf::st_geometry(segs)) == "sfc_GEOMETRY"){
    segs <- sf::st_cast(segs, "MULTIPOLYGON")
    segs <- sf::st_cast(segs, "POLYGON")

    uID <- strsplit(row.names(segs), split=".", fixed=T)
    uID <- sapply(uID, "[", 2)
    uID <- ifelse(is.na(uID), "", paste0(".", uID))

    segs[[unique_id]] <- paste0(segs[[unique_id]], uID)
  }

  bpts <- sf::st_cast(segs, "POINT")
  # remove duplicates (rings)
  bpts <- unique(bpts)

  if(verbose) cat("Generating Voroni diagram...\n")
  v <- sf::st_voronoi(sf::st_union(bpts), envelope=limit)
  v <- sf::st_collection_extract(v)

  if(verbose) cat("Dissolving Voroni polygons...\n")
  v <- v[unlist(sf::st_intersects(bpts, v))]
  v <- sf::st_join(st_sf(v), bpts)
  v <- aggregate(v[,names(v) != unique_id],
                 by=list(UID = v[[unique_id]]), FUN=sum)
  colnames(v)[colnames(v) == "UID"] <- unique_id

  if(verbose) cat("Clipping morphological tessellation...\n")
  v <- sf::st_intersection(v, limit)
  vg <- sf::st_multipolygon(lapply(sf::st_geometry(v), function(x) x[1]))
  sf::st_geometry(v) <- sf::st_cast(sf::st_sfc(vg, crs=sf::st_crs(v)), 'POLYGON')

  if(verbose) cat("Finished morphological tesselation: ", strftime(Sys.time()), "\n")
  return(v)
}

