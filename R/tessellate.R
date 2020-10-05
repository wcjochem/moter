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
#' @details The algorithm is described by Fleischmann et al. (2020).
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
motess <- function(X, unique_id, limit, shrink=0.4, segment=0.5, verbose=True){
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

  if(any(sf::st_geometry_type(X)) %in% "MULTIPOLYGON"){
    X <- sf::st_cast(X, "POLYGON")

    uID <- strsplit(row.names(X), split=".", fixed=T)
    uID <- sapply(uID, "[", 2)
    uID <- ifelse(is.na(uID), "", paste0(".", uID))

    X[[unique_id]] <- paste0(X[[unique_id]], uID)
  }

  if(any(duplicated(X[[unique_id]]))){
    stop("Building footprints must have a unique ID")
  }

  if(missing(limit)){
    limit <- sf::st_as_sfc(sf::st_bbox(X))
  }

  if(sf::st_is_longlat(X)){
    shrink <- shrink / 111111
  }

  if (verbose) print("Inward offset...")
  X <- sf::st_buffer(X, dist=shrink)

  if(verbose) print("Discretization...")
  bpts <- sf::st_cast(sf::st_segmentize(X, segment), "POINT")
  # remove duplicates (rings)
  bpts <- unique(bpts)

  if(verbose) print("Generating Voroni diagram...")
  v <- sf::st_voronoi(sf::st_union(bpts), envelope=limit)
  v <- sf::st_collection_extract(v)

  if(verbose) print("Dissolving Voroni polygons...")
  v <- v[unlist(sf::st_intersects(bpts, v))]
  v <- sf::st_join(st_sf(v), bpts)
  v <- aggregate(v[,names(v) != unique_id],
                 by=list(UID = v[[unique_id]]), FUN=sum)
  colnames(v)[colnames(v) == "UID"] <- unique_id

  return(v)
}

