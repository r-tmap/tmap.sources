#' @export
#' @importFrom tmap tmapReproject
tmapReproject.character = function(shp, tmapID, bbox = NULL, ..., crs) {
	shapeTM(shp, tmapID, bbox, ...)
}

#' @export
#' @import freestiler
#' @import servr
#' @import data.table
tmapShape.character = function(shp, is.main, crs, bbox, unit, filter, layer, shp_name, smeta, o, tmf) {
	dt = data.table::data.table(dummy__ = TRUE, tmapID__ = NA_integer_, sel__ = TRUE)
	dtcols = "dummy__"
	if (is.null(bbox$x)) bbox$x = smeta$bbox
	shpTM = shapeTM(shp = shp, tmapID = integer(0), bbox = bbox, smeta = smeta)
	structure(list(shpTM = shpTM, dt = dt, is.main = is.main, dtcols = dtcols, shpclass = "character", bbox = bbox, unit = unit, shp_name = shp_name, smeta = smeta, type_ids = NULL, type_vars = NULL), class = "tmapShape")
}

#' @export
tmapSubsetShp.character = function(shp, vars) {
	shp
}


#' @export
tmapGetShapeMeta2.character = function(shp, smeta, o) {
	vars = character(0)
	smeta$vars_levs = list()
	smeta
}


#' @export
tmapGetShapeMeta1.character = function(shp, layer, o) {
	meta = get_source_info(shp)

	if (!is.null(layer)) {
		if (!layer %in% meta$layers) cli::cli_abort("{.field PMTiles} layer {.code {layer}} not found. Available layers: {.code {layers}}")
	} else {
		layer = meta$layers[1L]
	}

	vars = meta$layer_vars[[layer]]$variable

	dims = character(0)
	dims_vals = list()

	list(bbox = meta$bbox,
		 layer = layer,
		 url = meta$url,
		 vars = vars,
		 dims = dims,
		 dims_vals = dims_vals,
		 type = meta$type,
		 tile_type = meta$tile_type)
}




