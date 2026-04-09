# Get tmap source metadata

Returns all known metadata for a PMTiles source. For Overture Maps URLs,
the `layer_vars` data frames are automatically annotated with
`categories` and `palette` list-columns for variables that have a known
closed value set.

## Usage

``` r
tmap_src_meta(x)
```

## Arguments

- x:

  URL or local file path to a PMTiles source.

## Value

A list with elements: `input`, `type`, `tile_type`, `url`, `layers`,
`layer_vars`, `bbox`, `zoom`. Each element of `layer_vars` is a data
frame with columns `variable`, `class`, `categories` (list), `palette`
(list).
