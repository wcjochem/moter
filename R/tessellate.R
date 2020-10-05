#' Create morphological tessellations
#'
#' @param X Spatial polygons of building footprints.
#' @param unique_id String of a column in \code{X} with unique IDs.
#' @param limit Spatial polygon defining the study area.
#' @param shrink Distance for inward buffer on building footprints. Default 0.4.
#' @param segment Distance (in meters) between points created on building
#'   footprint segments. Default 0.5.
#' @param verbose Display progress. Default True.
#'
#' @return Description
#'
#' @details
#'
#' @seealso \url{}
#'
#' @examples
#'
#' @name motess
#' @export
motess <- function(X, unique_id, limit, shrink=0.4, segment=0.5, verbose=True){
  # add data checks

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
