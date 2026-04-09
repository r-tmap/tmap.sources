# Get Overture Maps PMTiles URLs

Returns a named list of PMTiles URLs for all Overture themes. When
`release = "latest"` (default), the version is resolved via the Overture
STAC catalog at runtime.

## Usage

``` r
tmap_src_overture(release = "latest")
```

## Arguments

- release:

  Character. `"latest"` or an explicit release string such as
  `"2026-03-18"` or `"2026-03-18.0"`.

## Value

Named list of URLs: `addresses`, `base`, `buildings`, `divisions`,
`places`, `transportation`.
