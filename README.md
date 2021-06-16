


<!-- README.md is generated from README.Rmd. Please edit that file -->

# moter: Generating **MO**rphological **TE**ssellations in **R**

Chris Jochem
*[WorldPop Research Group, University of Southampton](https://www.worldpop.org/)*

The `moter` package is currently a proof-of-concept and experimental package.
Use at your own risk. The code is implementing an algorithm to create
tessellated polygons around building footprints. The generated polygons
efficiently partition a study area space and can be used for as zones for
calculating urban morphometrics from building shapes. The morphological
tessellation (MT) was described by [Fleischmann et al.
(2020)](https://doi.org/10.1016/j.compenvurbsys.2019.101441) and the algorithm
was implemented in [`momepy`](https://docs.momepy.org).

## Installation

The code can be installed from GitHub. It also requires the `sf` package.

```r
devtools::install_github("wcjochem/moter@main")
```



## Basic usage


```r
library(moter)
```

There is currently one primary function, `motess` that takes a set of building
polygons and generates the morphological tessellation as a set of spatial
polygons in `sf` format. In addition, this function requires the footprints to
have a column with a unique identifier and (optionally) takes a bounding box to
limit the extent of the study area.

There are two key parameters affecting the morphological tessellation. The
first, `shrink` is the distance set (in meters) for an inward buffer which
separates adjacent buildings. The second, `limit` is the distance (in meters) to
create points along the edges of the building footprints. Default values have
been provided in the function. Users are directed to Fleischmann et al. (2020)
for further discussion about the sensitivity of these parameters.

This processing may take some time for large collections of building footprints.


```r
# create morphological tessellation
MT <- motess(X, unique_id = "UID", verbose = TRUE)
#> Inward offset...
#> Discretization...
#> Generating Voroni diagram...
#> Dissolving Voroni polygons...
#> Clipping morphological tessellation...
#> Finished morphological tesselation:  2021-06-16 14:58:26
```
The resulting morphological cells are provided as `sf` type spatial polygons
which can be viewed and plotted.


```r
head(MT)
#> Simple feature collection with 6 features and 1 field
#> Geometry type: POLYGON
#> Dimension:     XY
#> Bounding box:  xmin: 32.61528 ymin: 0.3289504 xmax: 32.62128 ymax: 0.334044
#> Geodetic CRS:  WGS 84
#>   UID                       geometry
#> 1   1 POLYGON ((32.61604 0.331013...
#> 2   2 POLYGON ((32.6211 0.3303195...
#> 3   3 POLYGON ((32.61699 0.329241...
#> 4   4 POLYGON ((32.61536 0.331925...
#> 5   5 POLYGON ((32.61831 0.332910...
#> 6   6 POLYGON ((32.61777 0.329079...
```

<img src="man/figures/REAsDME-plotting-1.png" title="Example morphological tessellation" alt="Example morphological tessellation" width="50%" />


## References
Fleischmann, M., A. Feliciotti, O. Romice, S. Porta (2020). "Morphological
tessellation as a way of partitioning space: Improving consistency in urban
morphology at the plot scale."  *Computers, Environment, & Urban Systems**, 80,
101441.[https://doi.org/10.1016/j.compenvurbsys.2019.101441](https://doi.org/10.1016/j.compenvurbsys.2019.101441).
