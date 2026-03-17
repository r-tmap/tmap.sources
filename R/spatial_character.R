#' @export
tmapReproject.character = function(shp, tmapID, bbox = NULL, ..., crs) {
	shapeTM(shp, tmapID, bbox, ...)
}

#' @export
#' @import freestiler
#' @import servr
tmapShape.character = function(shp, is.main, crs, bbox, unit, filter, layer, shp_name, smeta, o, tmf) {
	dt = data.table(dummy__ = TRUE, tmapID__ = NA_integer_, sel__ = TRUE)
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
	is_pmtiles <- function(x) {
		is.character(x) && length(x) == 1 && grepl("\\.pmtiles($|\\?)", x, ignore.case = TRUE)
	}
	is_remote <- function(x) {
		is.character(x) && length(x) == 1 &&
			grepl("^(https?|ftp)://", x, ignore.case = TRUE)
	}
	is_local <- function(x) {
		is.character(x) && length(x) == 1 && !is_remote(x)
	}

	if (!is_pmtiles(shp)) cli::cli_abort("{.field data source} this data source is not implemented yet; only pmtiles are implemented")

	if (is_local(shp)) {
		shp = normalizePath(shp, mustWork = TRUE)
		dir = dirname(shp)
		port = servr::random_port()
		# srv = servr::httr(dir = dir) # not sure why this doesn't work
		srv = freestiler::serve_tiles(shp, port = port)
		url = paste0(srv$url, "/", basename(shp))
		meta = freestiler:::.pmtiles_metadata(shp)
		layers = vapply(meta$metadata$vector_layers, "[[", "id", FUN.VALUE = character(1))
		if (!is.null(layer)) {
			if (!layer %in% layers) cli::cli_abort("{.field PMTiles} layer {.code {layer} not found. Available layers: {.code {layers}}")
		} else {
			layer = layers[1L]
		}
		lid = which(layer == layers)
		li = meta$metadata$vector_layers[[lid]]
		bbox = get_bbox_meta(meta)
		vars = names(li$fields)
	} else {

		if (is.null(layer)) cli::cli_abort("{.field PMTiles} layer is required for remote PMTiles. Please specify it via {.fun tm_shape}")
		url = shp
		bbox = sf::st_bbox()
		vars = character(0)
	}
	type = "pmtiles"
	dims = character(0)
	dims_vals = list()

	list(bbox = bbox,
		 layer = layer,
		 url = url,
		 vars = vars,
		 dims = dims,
		 dims_vals = dims_vals,
		 type = type)
}


get_bbox_meta = function(meta) {
	sf::st_bbox(c(xmin = meta$min_longitude, xmax = meta$max_longitude, ymin = meta$min_latitude, ymax = meta$max_latitude), crs = sf::st_crs("OGC:CRS84"))
}

