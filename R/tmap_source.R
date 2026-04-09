get_bbox_meta = function(meta) {
	sf::st_bbox(structure(meta$header$bounds, names = c("xmin", "ymin", "xmax", "ymax")), crs = sf::st_crs("OGC:CRS84"))
}

get_source_info = function(shp, start_local_host = TRUE) {
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

	# todo: update when more source types are supported

	if (!is_pmtiles(shp)) cli::cli_abort("{.field data source} this data source is not implemented yet; only pmtiles are implemented")
	type = "pmtiles"

	if (is_local(shp)) {
		shp = normalizePath(shp, mustWork = TRUE)

		if (start_local_host) {
			port = servr::random_port()
			srv = freestiler::serve_tiles(shp, port = port)
			url = paste0(srv$url, "/", basename(shp))
		} else {
			url = NULL
		}
		meta = read_pmtiles_info(shp)
	} else {
		meta = read_pmtiles_info(shp)
		url = shp
	}

	tile_type = tolower(meta$header$tile_type)
	if (is.na(tile_type) && "vector_layers" %in% names(meta$metadata)) tile_type = "mvt"

	if (tile_type == "mvt") {
		layers = vapply(meta$metadata$vector_layers, "[[", "id", FUN.VALUE = character(1))

		if (length(layers)) {
			layer_vars = lapply(seq_along(layers), function(id) {
				y = meta$metadata$vector_layers[[id]]
				vars = names(y$fields)
				typs = tolower(unname(y$fields))
				typs = ifelse(typs == "number", "numeric", ifelse(typs == "boolean", "logical", "character"))
				data.frame(variable = vars, class = typs)
			})
			names(layer_vars) = layers
		}
	} else if (tile_type == "png") {
		layers = meta$metadata$name
		tile_type = meta$metadata$type #overlay or baselayer
		layer_vars = list(data.frame(variable = layers, class = "color"))
		names(layer_vars) = layers
	} else {
		cli::cli_abort("tile_type {tile_type} unsupported")
	}


	bbox = get_bbox_meta(meta)
	zoom = c(min = meta$header$minzoom, max = meta$header$maxzoom)

	list(input = shp,
		 type = type,
		 tile_type = tile_type,
		 url = url,
		 layers = layers,
		 layer_vars = layer_vars,
		 bbox = bbox,
		 zoom = zoom)

}
