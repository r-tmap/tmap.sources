# =============================================================================
# Overture category catalogue
# Hard-coded per-variable category + palette info, keyed as "layer.variable".
# Only variables with a closed, schema-documented value set are included.
# Sources:
#   buildings/subtype  – https://docs.overturemaps.org/schema/concepts/by-theme/buildings/
#                        (verified against actual data; "educational" not "education")
#   segment/subtype    – https://docs.overturemaps.org/guides/transportation/
#   segment/class      – https://docs.overturemaps.org/schema/reference/transportation/segment/
#                        (road classes only; rail/water classes omitted — open-ended)
#   land/subtype       – https://docs.overturemaps.org/schema/concepts/by-theme/base/
#   land_use/subtype   – ibid.
#   water/subtype      – ibid.
# =============================================================================

.overture_cats <- function() {
	list(

		# -------------------------------------------------------------------------
		# buildings : building : subtype
		# -------------------------------------------------------------------------
		`building.subtype` = list(
			categories = c(
				"residential", "commercial", "industrial", "educational",
				"civic", "religious", "medical", "transportation",
				"entertainment", "agricultural", "military", "outbuilding",
				"service"
			),
			palette = c(
				residential    = "#f4a460",
				commercial     = "#4169e1",
				industrial     = "#708090",
				educational    = "#ffd700",
				civic          = "#dc143c",
				religious      = "#9370db",
				medical        = "#ff6347",
				transportation = "#20b2aa",
				entertainment  = "#ff69b4",
				agricultural   = "#6b8e23",
				military       = "#556b2f",
				outbuilding    = "#d2b48c",
				service        = "#87ceeb"
			)
		),

		# -------------------------------------------------------------------------
		# transportation : segment : subtype  (3 values)
		# -------------------------------------------------------------------------
		`segment.subtype` = list(
			categories = c("road", "rail", "water"),
			palette = c(
				road  = "#888888",
				rail  = "#9370db",
				water = "#4169e1"
			)
		),

		# -------------------------------------------------------------------------
		# transportation : segment : class  (road subtype only)
		# Ordered high → low in the road hierarchy; colours follow conventional
		# cartographic practice (motorway = red-orange, fading to light grey for
		# minor roads, with special colours for pedestrian/cycle/service).
		# -------------------------------------------------------------------------
		`segment.class` = list(
			categories = c(
				"motorway", "trunk", "primary", "secondary", "tertiary",
				"residential", "unclassified", "living_street", "service",
				"pedestrian", "footway", "cycleway", "path", "track",
				"steps", "bridleway", "corridor",
				# rail
				"rail", "light_rail", "subway", "tram", "monorail",
				"funicular", "narrow_gauge",
				# water
				"canal", "river", "unknown"
			),
			palette = c(
				motorway      = "#e8452c",
				trunk         = "#e87832",
				primary       = "#f5cf00",
				secondary     = "#c0d000",
				tertiary      = "#c8c8c8",
				residential   = "#e8e8e8",
				unclassified  = "#e0e0e0",
				living_street = "#f0f0d8",
				service       = "#f0f0f0",
				pedestrian    = "#f5deb3",
				footway       = "#f5deb3",
				cycleway      = "#6bc4c4",
				path          = "#d8c8a0",
				track         = "#c8b078",
				steps         = "#e8c8a0",
				bridleway     = "#b8d890",
				corridor      = "#e8e8e8",
				rail          = "#9370db",
				light_rail    = "#b070e0",
				subway        = "#0055cc",
				tram          = "#cc6600",
				monorail      = "#888800",
				funicular     = "#aa4488",
				narrow_gauge  = "#8855bb",
				canal         = "#5588cc",
				river         = "#4477bb",
				unknown       = "#cccccc"
			)
		),

		# -------------------------------------------------------------------------
		# base : land : subtype
		# -------------------------------------------------------------------------
		`land.subtype` = list(
			categories = c(
				"grass", "forest", "wetland", "sand", "rock", "glacier",
				"desert", "crater"
			),
			palette = c(
				grass   = "#c8e6a0",
				forest  = "#6b8e23",
				wetland = "#7fb0a0",
				sand    = "#e8d8a0",
				rock    = "#b8b0a8",
				glacier = "#ddeeff",
				desert  = "#e8c878",
				crater  = "#a89888"
			)
		),

		# -------------------------------------------------------------------------
		# base : land_use : subtype
		# -------------------------------------------------------------------------
		`land_use.subtype` = list(
			categories = c(
				"residential", "commercial", "industrial", "education",
				"recreation", "protected", "agricultural", "military",
				"religious", "transportation", "medical", "landfill"
			),
			palette = c(
				residential    = "#f4d0b8",
				commercial     = "#c0c8f0",
				industrial     = "#c8c0b8",
				education      = "#ffe890",
				recreation     = "#a8d8a0",
				protected      = "#90c890",
				agricultural   = "#d8e8a0",
				military       = "#c8b878",
				religious      = "#e8d0f0",
				transportation = "#d0d0d0",
				medical        = "#f8c0c0",
				landfill       = "#c0b8a8"
			)
		),

		# -------------------------------------------------------------------------
		# base : water : subtype
		# -------------------------------------------------------------------------
		`water.subtype` = list(
			categories = c(
				"ocean", "lake", "river", "pond", "reservoir",
				"stream", "canal", "water", "swimming_pool"
			),
			palette = c(
				ocean        = "#4477aa",
				lake         = "#5588bb",
				river        = "#4488cc",
				pond         = "#66aacc",
				reservoir    = "#5599bb",
				stream       = "#77aacc",
				canal        = "#5577bb",
				water        = "#6688bb",
				swimming_pool = "#88ccee"
			)
		)
	)
}


# =============================================================================
# Mapping: which (url-derived theme) → which layer.variable keys are relevant
# Used by tmap_src_meta() to annotate layer_vars with categories/palette.
# =============================================================================

.overture_theme_cats <- function() {
	list(
		buildings      = list(building     = c("subtype")),
		transportation = list(segment      = c("subtype", "class")),
		base           = list(land         = c("subtype"),
							  land_use     = c("subtype"),
							  water        = c("subtype"))
	)
}


# =============================================================================
# Internal: detect if a URL is an Overture PMTiles URL and return its theme
# =============================================================================

.overture_theme_from_url <- function(url) {
	pattern <- "tiles\\.overturemaps\\.org/[^/]+/([a-z]+)\\.pmtiles"
	m <- regmatches(url, regexpr(pattern, url, perl = TRUE))
	if (length(m) == 0L) return(NULL)
	sub(".*tiles\\.overturemaps\\.org/[^/]+/([a-z]+)\\.pmtiles", "\\1", m)
}


# =============================================================================
# Internal: annotate layer_vars list-of-data-frames with categories + palette
# =============================================================================

.annotate_layer_vars <- function(layer_vars, theme) {
	theme_map <- .overture_theme_cats()
	cat_data  <- .overture_cats()

	if (!theme %in% names(theme_map)) return(layer_vars)

	layer_map <- theme_map[[theme]]

	lapply(names(layer_vars), function(lyr) {
		df   <- layer_vars[[lyr]]
		vars <- if (lyr %in% names(layer_map)) layer_map[[lyr]] else character(0)

		# Add list-columns; default to NULL for all rows, fill known vars
		df$categories <- vector("list", nrow(df))
		df$palette    <- vector("list", nrow(df))

		for (v in vars) {
			key  <- paste0(lyr, ".", v)
			idx  <- which(df$variable == v)
			if (length(idx) == 1L && key %in% names(cat_data)) {
				df$categories[[idx]] <- cat_data[[key]]$categories
				df$palette[[idx]]    <- cat_data[[key]]$palette
			}
		}
		df
	}) |> stats::setNames(names(layer_vars))
}


# =============================================================================
# tmap_src_meta()
# =============================================================================

#' Get tmap source metadata
#'
#' Returns all known metadata for a PMTiles source. For Overture Maps URLs,
#' the \code{layer_vars} data frames are automatically annotated with
#' \code{categories} and \code{palette} list-columns for variables that have
#' a known closed value set.
#'
#' @param x URL or local file path to a PMTiles source.
#' @return A list with elements: \code{input}, \code{type},
#'   \code{tile_type}, \code{url}, \code{layers}, \code{layer_vars},
#'   \code{bbox}, \code{zoom}.  Each element of \code{layer_vars} is a
#'   data frame with columns \code{variable}, \code{class},
#'   \code{categories} (list), \code{palette} (list).
#' @import tmap
#' @import freestiler
#' @export
tmap_src_meta <- function(x) {
	meta  <- get_source_info(x, start_local_host = FALSE)
	theme <- .overture_theme_from_url(x)
	if (!is.null(theme)) {
		meta$layer_vars <- .annotate_layer_vars(meta$layer_vars, theme)
	}
	meta
}


# =============================================================================
# tmap_src_overture()
# =============================================================================

#' Get Overture Maps PMTiles URLs
#'
#' Returns a named list of PMTiles URLs for all Overture themes. When
#' \code{release = "latest"} (default), the version is resolved via the
#' Overture STAC catalog at runtime.
#'
#' @param release Character. \code{"latest"} or an explicit release string
#'   such as \code{"2026-03-18"} or \code{"2026-03-18.0"}.
#' @return Named list of URLs: \code{addresses}, \code{base},
#'   \code{buildings}, \code{divisions}, \code{places},
#'   \code{transportation}.
#' @export
tmap_src_overture <- function(release = "latest") {
	themes <- c("addresses", "base", "buildings", "divisions",
				"places", "transportation")

	if (identical(release, "latest")) {
		release <- .overture_latest_release()        # returns e.g. "2026-03-18.0"
	} else {
		if (!grepl("\\.\\d+$", release)) release <- paste0(release, ".0")
	}

	urls <- paste0("https://tiles.overturemaps.org/", release, "/", themes, ".pmtiles")
	stats::setNames(as.list(urls), themes)
}

.overture_latest_release <- function() {
	resp <- tryCatch(
		jsonlite::fromJSON("https://stac.overturemaps.org/catalog.json"),
		error = function(e) cli::cli_abort(
			"Could not fetch Overture STAC catalog: {conditionMessage(e)}"
		)
	)
	release <- resp[["latest"]]
	if (is.null(release))
		cli::cli_abort("Unexpected STAC catalog format: no 'latest' field found.")
	release
}

#' Derived accessors for tmap source metadata
#'
#' Convenience functions to extract specific parts of the metadata object
#' returned by \code{\link{tmap_src_meta}}.
#'
#' @param meta List. Output of \code{\link{tmap_src_meta}}.
#' @param layer Character. Layer name. May be omitted when the source has
#'   exactly one layer; required otherwise.
#' @param var Character. Variable name within the layer.
#'
#' @return
#' \describe{
#'   \item{\code{tmap_src_layers}}{Character vector of layer names.}
#'   \item{\code{tmap_src_vars}}{Data frame with columns \code{variable},
#'     \code{class}, \code{categories} (list-column), and \code{palette}
#'     (list-column) for all variables in the layer.}
#'   \item{\code{tmap_src_cats}}{A list with elements \code{categories}
#'     (character vector of known category values) and \code{palette}
#'     (named character vector of hex colours), both \code{NULL} when no
#'     catalogue entry exists for \code{layer.var}.}
#' }
#'
#' @examples
#' \dontrun{
#' urls <- tmap_src_overture()
#' meta <- tmap_src_meta(urls$buildings)
#'
#' tmap_src_layers(meta)
#' #> [1] "building" "building_part"
#'
#' tmap_src_vars(meta, layer = "building")
#'
#' tmap_src_cats(meta, layer = "building", var = "subtype")
#' #> $categories
#' #>  [1] "residential" "commercial" ...
#' #> $palette
#' #>  residential  commercial ...
#' #>  "#f4a460"    "#4169e1"  ...
#' }
#'
#' @name tmap_src_accessors
NULL

#' @rdname tmap_src_accessors
#' @export
tmap_src_layers <- function(meta) meta$layers

#' @rdname tmap_src_accessors
#' @export
tmap_src_vars <- function(meta, layer = NULL) {
	layer <- .resolve_layer(meta, layer)
	meta$layer_vars[[layer]]
}

#' @rdname tmap_src_accessors
#' @export
tmap_src_cats <- function(meta, layer = NULL, var) {
	layer <- .resolve_layer(meta, layer)
	df    <- meta$layer_vars[[layer]]
	if (!var %in% df$variable)
		cli::cli_abort("Variable {.field {var}} not found in layer {.field {layer}}.")
	idx <- which(df$variable == var)
	list(
		categories = df$categories[[idx]],
		palette    = df$palette[[idx]]
	)
}

.resolve_layer <- function(meta, layer) {
	layers <- meta$layers
	if (is.null(layer)) {
		if (length(layers) == 1L) return(layers)
		cli::cli_abort(
			"Source has multiple layers ({.val {layers}}); please specify {.arg layer}."
		)
	}
	if (!layer %in% layers)
		cli::cli_abort("Layer {.field {layer}} not found. Available: {.val {layers}}.")
	layer
}
