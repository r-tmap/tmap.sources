# Derived accessors for tmap source metadata

Convenience functions to extract specific parts of the metadata object
returned by
[`tmap_src_meta`](https://r-tmap.github.io/tmap.sources/reference/tmap_src_meta.md).

## Usage

``` r
tmap_src_layers(meta)

tmap_src_vars(meta, layer = NULL)

tmap_src_cats(meta, layer = NULL, var)
```

## Arguments

- meta:

  List. Output of
  [`tmap_src_meta`](https://r-tmap.github.io/tmap.sources/reference/tmap_src_meta.md).

- layer:

  Character. Layer name. May be omitted when the source has exactly one
  layer; required otherwise.

- var:

  Character. Variable name within the layer.

## Value

- `tmap_src_layers`:

  Character vector of layer names.

- `tmap_src_vars`:

  Data frame with columns `variable`, `class`, `categories`
  (list-column), and `palette` (list-column) for all variables in the
  layer.

- `tmap_src_cats`:

  A list with elements `categories` (character vector of known category
  values) and `palette` (named character vector of hex colours), both
  `NULL` when no catalogue entry exists for `layer.var`.

## Examples

``` r
if (FALSE) { # \dontrun{
urls <- tmap_src_overture()
meta <- tmap_src_meta(urls$buildings)

tmap_src_layers(meta)
#> [1] "building" "building_part"

tmap_src_vars(meta, layer = "building")

tmap_src_cats(meta, layer = "building", var = "subtype")
#> $categories
#>  [1] "residential" "commercial" ...
#> $palette
#>  residential  commercial ...
#>  "#f4a460"    "#4169e1"  ...
} # }
```
