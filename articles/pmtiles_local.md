# Self-created PMTiles

## Introduction

PMTiles is an efficient format for serving vector and raster map tiles
directly from a single file, without a tile server. This vignette shows
how to create PMTiles from `sf` objects using the `freestiler` package,
and how to visualize them with `tmap.mapgl`.

``` r
library(tmap)
library(tmap.mapgl)
library(tmap.sources)
library(freestiler)
library(cols4all)
tmap_mode("maplibre")
#> ℹ tmap modes "plot" -> "view" -> "mapbox" -> "maplibre"
#> ℹ rotate with `tmap::rtm()`switch to "plot" with `tmap::ttm()`
```

Two things to decide before writing a PMTiles file:

- **Which columns to include.** Only columns present in the file can be
  used for styling. Add any variables you intend to map before calling
  [`freestile()`](https://walker-data.com/freestiler/reference/freestile.html).
- **How to encode the aesthetic.** For categorical styling, either
  pre-compute a color column (`tm_scale_asis`) or include a factor
  column and use `tm_scale_categorical`. Both approaches are shown below
  for polygons.

## Polygons

### Preparing the data

``` r
data("NLD_dist", package = "tmap")

breaks  <- c(0, 21.5, 29.5, 39.8, 51.5, 90)
pal     <- c4a("plasma", 5)
colorNA <- c4a_na("plasma")

NLD_dist$edu_cat  <- cut(NLD_dist$edu_appl_sci, breaks = breaks)
NLD_dist$edu_fill <- pal[cut(NLD_dist$edu_appl_sci, breaks = breaks,
                             include.lowest = TRUE)]
NLD_dist$edu_fill[is.na(NLD_dist$edu_fill)] <- colorNA
```

### Creation of PMTiles

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

### Visualization

**Option 1:** use the pre-computed color column directly with
`tm_scale_asis`. The legend must be added manually since tmap cannot
infer it from raw color values.

``` r
tm_shape("NLD_dist.pmtiles") +
  tm_polygons(fill = "edu_fill") +
  tm_add_legend(fill = pal, labels = levels(NLD_dist$edu_cat),
                type = "polygons", title = "Education")
```

**Option 2:** use the factor column with `tm_scale_categorical`. tmap
handles the color mapping and legend automatically.

``` r
tm_shape("NLD_dist.pmtiles") +
  tm_polygons(
    fill        = "edu_cat",
    fill.scale  = tm_scale_categorical(values = pal,
                                       levels = levels(NLD_dist$edu_cat)),
    fill.legend = tm_legend(title = "Education")
  )
```

## Lines

### Preparing the data

`World_rivers` contains a `scalerank` variable (1 = largest rivers). We
keep the six most prominent ranks and convert to a factor for
categorical styling.

``` r
data("World_rivers", package = "tmap")
World_rivers <- World_rivers[World_rivers$scalerank <= 6, ]
World_rivers$rank_cat <- factor(paste0("rank ", World_rivers$scalerank),
                                levels = paste0("rank ", 1:6))
river_pal <- c4a("-seaborn.crest", 6)
```

### Creation of PMTiles

``` r
freestile(World_rivers, "World_rivers.pmtiles",
          layer_name = "rivers", min_zoom = 0, max_zoom = 10)
#> Creating MLT tiles (zoom 0-10) for 1619 features across 1 layer...
#>   Parsed 1619 features across 1 layer in 0.0s
#>   Zoom  0/10:      1 tiles ...
#>                 1 encoded (0.0s)
#>   Zoom  1/10:      4 tiles ...
#>                 4 encoded (0.0s)
#>   Zoom  2/10:     11 tiles ...
#>                10 encoded (0.0s)
#>   Zoom  3/10:     29 tiles ...
#>                29 encoded (0.0s)
#>   Zoom  4/10:     76 tiles ...
#>                74 encoded (0.0s)
#>   Zoom  5/10:    216 tiles ...
#>               212 encoded (0.0s)
#>   Zoom  6/10:    591 tiles ...
#>               567 encoded (0.0s)
#>   Zoom  7/10:   1591 tiles ...
#>              1367 encoded (0.0s)
#>   Zoom  8/10:   4278 tiles ...
#>              2982 encoded (0.0s)
#>   Zoom  9/10:  12243 tiles ...
#>              6353 encoded (0.0s)
#>   Zoom 10/10:  38689 tiles ...
#>             13135 encoded (0.0s)
#>   Total: 24734 tiles in 0.2s
#>   Writing PMTiles archive (24734 tiles) ...
#>   PMTiles write: 0.3s
#> Created World_rivers.pmtiles (5.3 MB)
#> View with: view_tiles("World_rivers.pmtiles")
```

### Visualization

``` r
tm_shape("World_rivers.pmtiles") +
  tm_lines(
    lwd        = 6,
    col        = "rank_cat",
    col.scale  = tm_scale_categorical(values = river_pal,
                                      levels = levels(World_rivers$rank_cat)),
    col.legend = tm_legend(title = "River rank")
  )
```

## Points

When creating point PMTiles from polygon data, centroids must be
computed first. Passing polygon geometry to
[`freestile()`](https://walker-data.com/freestiler/reference/freestile.html)
for use with
[`tm_dots()`](https://r-tmap.github.io/tmap/reference/tm_symbols.html)
or
[`tm_symbols()`](https://r-tmap.github.io/tmap/reference/tm_symbols.html)
will result in circles rendered at every vertex rather than at the
feature centroid.

### Preparing the data

``` r
NLD_dist$edu_cat <- cut(NLD_dist$edu_appl_sci, breaks = breaks)

# centroid step required before freestile() when source is polygon sf
NLD_pts <- sf::st_centroid(NLD_dist)
#> Warning: st_centroid assumes attributes are constant over geometries
```

### Creation of PMTiles

``` r
freestile(NLD_pts, "NLD_dist_pts.pmtiles",
          layer_name = "districts", min_zoom = 5, max_zoom = 15)
#> Creating MLT tiles (zoom 5-15) for 3340 features across 1 layer...
#>   Transforming layer 'districts' to WGS84...
#>   Parsed 3340 features across 1 layer in 0.0s
#>   Zoom  5/15:      1 tiles ...
#>                 1 encoded (0.0s)
#>   Zoom  6/15:      4 tiles ...
#>                 4 encoded (0.0s)
#>   Zoom  7/15:      6 tiles ...
#>                 6 encoded (0.0s)
#>   Zoom  8/15:     14 tiles ...
#>                14 encoded (0.0s)
#>   Zoom  9/15:     33 tiles ...
#>                31 encoded (0.0s)
#>   Zoom 10/15:     95 tiles ...
#>                95 encoded (0.0s)
#>   Zoom 11/15:    309 tiles ...
#>               308 encoded (0.0s)
#>   Zoom 12/15:   1024 tiles ...
#>              1016 encoded (0.0s)
#>   Zoom 13/15:   2501 tiles ...
#>              2417 encoded (0.0s)
#>   Zoom 14/15:   3603 tiles ...
#>              3465 encoded (0.0s)
#>   Zoom 15/15:   4157 tiles ...
#>              3970 encoded (0.0s)
#>   Total: 11327 tiles in 0.1s
#>   Writing PMTiles archive (11327 tiles) ...
#>   PMTiles write: 0.1s
#> Created NLD_dist_pts.pmtiles (6.3 MB)
#> View with: view_tiles("NLD_dist_pts.pmtiles")
```

### Visualization

``` r
tm_shape("NLD_dist_pts.pmtiles") +
  tm_dots(
    fill        = "edu_cat",
    fill.scale  = tm_scale_categorical(values = pal,
                                       levels = levels(NLD_dist$edu_cat)),
    fill.legend = tm_legend(title = "Education")
  )
```

## 3D Polygons

Extruded polygons require a numeric height variable. Because the raw
data range is not available from the remote tile, it must be declared
explicitly via `tm_scale_continuous(limits = ...)`. Use
[`range()`](https://rdrr.io/r/base/range.html) on your data beforehand
to find the appropriate values.

### Preparing the data

``` r
NLD_dist$edu_fill <- pal[as.integer(
  cut(NLD_dist$edu_appl_sci, breaks = breaks, include.lowest = TRUE)
)]
NLD_dist$edu_fill[is.na(NLD_dist$edu_fill)] <- colorNA
NLD_dist$pop_density <- NLD_dist$population / as.numeric(NLD_dist$area)
pop_density_range    <- range(NLD_dist$pop_density, na.rm = TRUE)
```

### Creation of PMTiles

The same `NLD_dist.pmtiles` written above already contains
`pop_density`, so no new file is needed here — provided
[`freestile()`](https://walker-data.com/freestiler/reference/freestile.html)
was called after adding the column.

``` r
# only needed if NLD_dist.pmtiles was created before pop_density was added
freestile(NLD_dist, "NLD_dist.pmtiles",
          layer_name = "edu", min_zoom = 4, max_zoom = 15)
```

### Visualization

``` r
tm_shape("NLD_dist.pmtiles") +
  tm_polygons_3d(
    fill         = "edu_fill",
    height       = "pop_density",
    height.scale = tm_scale_continuous(limits = pop_density_range),
    fill.legend  = tm_legend(title = "Education (% applied sci.)"),
    options      = opt_tm_polygons_3d(height.min = 2000)
  ) +
  tm_maplibre(pitch = 45)
```

    #> Warning: Fill-extrusion layers may have rendering artifacts in globe
    #> projection. Consider using projection = "mercator" in maplibre() for better
    #> performance. See https://github.com/maplibre/maplibre-gl-js/issues/5025
