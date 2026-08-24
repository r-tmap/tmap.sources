urls <- tmap_src_overture()
meta <- tmap_src_meta(urls$buildings)
if (!is.null(meta)) {
  tmap_src_layers(meta)
  tmap_src_vars(meta, layer = "building")
  tmap_src_cats(meta, layer = "building", var = "subtype")
}
