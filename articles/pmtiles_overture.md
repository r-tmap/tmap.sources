# PMTiles - overture

## Introduction

\<to be added, some introduction about PMTiles format\>

``` r
library(tmap)
library(tmap.mapgl)
library(tmap.sources)
tmap_mode("maplibre")
#> ℹ tmap modes "plot" -> "view" -> "mapbox" -> "maplibre"
#> ℹ rotate with `tmap::rtm()`switch to "plot" with `tmap::ttm()`
```

## Remote PMTiles file

OvertureMaps contain a few very large PMTiles. The following is one with
the [buildings](https://docs.overturemaps.org/guides/buildings/), across
the World.

``` r
library(tmap)
library(tmap.mapgl)
library(tmap.sources)
tmap_mode("maplibre")
#> ℹ tmap modes "plot" -> "view" ->
#> "mapbox" -> "maplibre"

urls = tmap_src_overture()

tm_shape(
  urls$building, 
  bbox = "Amsterdam") +
tm_polygons(fill = "#ee7700") +
tm_maplibre(zoom = 14)
```

We can also use a categorical color palette:

``` r
urls = tmap_src_overture()
meta = tmap_src_meta(urls$buildings)
vars = tmap_src_vars(meta, layer = "building")
cats = tmap_src_cats(meta, layer = "building", var = "subtype")

tm_shape(
  urls$buildings,
  layer = "building",
  bbox = "Amsterdam") +
tm_polygons(
  fill = "subtype",
  fill.scale = tm_scale_categorical(
    levels    = cats$categories,
    values    = cats$palette,
    value.na  = "#ffffff",
    label.na  = "Unknown"
  ),
  fill.legend = tm_legend("Building type")
) +
tm_maplibre(zoom = 14)
#> Input to asJSON(keep_vec_names=TRUE) is a named vector. In a future version of jsonlite, this option will not be supported, and named vectors will be translated into arrays instead of objects. If you want JSON object output, please use a named list instead. See ?toJSON.
```
