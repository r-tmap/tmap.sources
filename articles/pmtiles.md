# PMTiles

## Introduction

Until version 4.3, it was only possible to visualize spatial data stored
in memory with `tmap`, e.g. objects from the class packages `sf`,
`terra`, or `stars`. This package, `tmap.sources` makes it possible to
visualize remote spatial data. Currently only `PMTiles`, a remote
tile-based data sources are supported, but support for other remote data
sources will be added later.

To run `tmap.sources`, besides `tmap`, another package is required,
namely
[`tmap.mapgl`](https://r-tmap.github.io/tmap.mapgl/articles/mapgl),
because we require the tmap mode `"maplibre"`:

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
tm_shape(
  "https://overturemaps-tiles-us-west-2-beta.s3.amazonaws.com/2026-01-21/buildings.pmtiles", 
  bbox = "Amsterdam") +
tm_polygons(fill = "#ee7700") +
tm_maplibre(zoom = 14)
```

We can also use a categorical color palette:

``` r
library(tmap)
library(tmap.sources)

# Define the mapping
building_subtypes <- data.frame(
  level = c("residential", "commercial", "industrial", "educational",
            "civic", "religious", "medical", "transportation",
            "entertainment", "agricultural", "military", "outbuilding",
            "service"),
  color = c("#f4a460", "#4169e1", "#708090", "#ffd700",
            "#dc143c", "#9370db", "#ff6347", "#20b2aa",
            "#ff69b4", "#6b8e23", "#556b2f", "#d2b48c",
            "#87ceeb"),
  label = c("Residential", "Commercial", "Industrial", "Educational",
            "Civic", "Religious", "Medical", "Transportation",
            "Entertainment", "Agricultural", "Military", "Outbuilding",
            "Service")
)

tm_shape(
  "https://overturemaps-tiles-us-west-2-beta.s3.amazonaws.com/2026-01-21/buildings.pmtiles",
  bbox = "Amsterdam") +
tm_polygons(
  fill = "subtype",
  fill.scale = tm_scale_categorical(
    levels    = building_subtypes$level,
    values    = building_subtypes$color,
    labels    = building_subtypes$label,
    value.na  = "#cccccc",
    label.na  = "Unknown"
  ),
  fill.legend = tm_legend("Building type")
) +
tm_maplibre(zoom = 14)
```
