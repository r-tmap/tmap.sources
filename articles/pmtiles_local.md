# PMTiles - self created

## Introduction

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

In order to create PMTiles locally, the package `freestiler` is
required. The created `PMTiles` files can be viewed from a local server,
or be uploaded to a remote server.

``` r
library(freestiler)
```

## Creation of PMTiles

If we have a `sf` object for which we would like to create a PMTiles
file, we have to think in advance what we would like to visualize. To
replicate the choropleth in the introduction vignette, we have two
options:

1.  We generate a color column, and use the as-is scale
    (`tm_scale_asis`)
2.  We generate a categorical (factor) column and use the categorical
    scale (`tm_scale_categorical`)

Let’s do both:

``` r
# add categorical variable
NLD_dist$edu_cat = cut(NLD_dist$edu_appl_sci, breaks = c(0, 21.5, 29.5, 39.8, 51.5, 90))

# get used colors
library(cols4all)
pal = c4a("plasma", 5)
colorNA = c4a_na("plasma")

# add color variable
NLD_dist$edu_fill = pal[cut(NLD_dist$edu_appl_sci, breaks = c(0, 21.5, 29.5, 39.8, 51.5, 90), include.lowest = TRUE)]
NLD_dist$edu_fill[is.na(NLD_dist$edu_fill)] = colorNA
```

Now we can create the PMTiles file:

``` r
freestile(
    NLD_dist,
    "NLD_dist.pmtiles",
    layer_name = "edu",
    min_zoom = 4,
    max_zoom = 15
)
#> Creating MLT tiles (zoom 4-15) for 3340 features across 1 layer...
#>   Transforming layer 'edu' to WGS84...
#>   Parsed 3340 features across 1 layer in 0.0s
#>   Zoom  4/15:      1 tiles ...
#>                 1 encoded (0.1s)
#>   Zoom  5/15:      1 tiles ...
#>                 1 encoded (0.1s)
#>   Zoom  6/15:      4 tiles ...
#>                 4 encoded (0.1s)
#>   Zoom  7/15:      6 tiles ...
#>                 6 encoded (0.0s)
#>   Zoom  8/15:     15 tiles ...
#>                15 encoded (0.0s)
#>   Zoom  9/15:     36 tiles ...
#>                34 encoded (0.0s)
#>   Zoom 10/15:    105 tiles ...
#>               100 encoded (0.0s)
#>   Zoom 11/15:    354 tiles ...
#>               348 encoded (0.1s)
#>   Zoom 12/15:   1270 tiles ...
#>              1217 encoded (0.1s)
#>   Zoom 13/15:   4749 tiles ...
#>              4485 encoded (0.1s)
#>   Zoom 14/15:  18235 tiles ...
#>             16934 encoded (0.3s)
#>   Zoom 15/15:  71155 tiles ...
#>             65366 encoded (1.0s)
#>   Total: 88511 tiles in 1.9s
#>   Writing PMTiles archive (88511 tiles) ...
#>   PMTiles write: 1.0s
#> Created NLD_dist.pmtiles (38.9 MB)
#> View with: view_tiles("NLD_dist.pmtiles")
```

### Option 1: color column

``` r
tm_shape("NLD_dist.pmtiles") +
  tm_polygons(fill = "edu_fill") +
  tm_add_legend(fill = pal, labels = levels(NLD_dist$edu_cat), type = "polygons", title = "Education")
#> Serving tiles at http://localhost:4321
#>   Directory: /home/runner/work/tmap.sources/tmap.sources/vignettes
#> Use stop_server() to stop
#> No legends available in mode "maplibre" for map variables
```

### Option 2: categorical variable

``` r
tm_shape("NLD_dist.pmtiles") +
  tm_polygons(
    fill = "edu_cat",
    fill.scale = tm_scale_categorical(values = pal, levels = levels(NLD_dist$edu_cat)),
    fill.legend = tm_legend(title = "Education")
  )
#> Serving tiles at http://localhost:6621
#>   Directory: /home/runner/work/tmap.sources/tmap.sources/vignettes
#> Use stop_server() to stop
```
