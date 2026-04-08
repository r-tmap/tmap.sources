#' Get Overture Maps PMTiles URLs
#'
#' Returns a named list of PMTiles URLs for all Overture themes, optionally
#' for a specific release. When \code{release = "latest"} (the default), the
#' release version is resolved via the Overture STAC catalog.
#'
#' @param release Character. Either \code{"latest"} (default) or an explicit
#'   release string such as \code{"2026-03-18"} (without the minor \code{.0}
#'   suffix).
#' @return A named list of character URLs, one per theme:
#'   \code{addresses}, \code{base}, \code{buildings}, \code{divisions},
#'   \code{places}, \code{transportation}.
#' @export
#' @examples
#' \dontrun{
#' urls <- tmap_source_overture()
#' meta <- tmap_source_meta(urls$buildings)
#' }
tmap_source_overture <- function(release = "latest") {
	themes <- c("addresses", "base", "buildings", "divisions",
				"places", "transportation")

	if (identical(release, "latest")) {
		release <- .overture_latest_release()  # returns e.g. "2026-03-18.0"
	} else {
		# Normalise: accept with or without minor version suffix
		if (!grepl("\\.\\d+$", release)) release <- paste0(release, ".0")
	}

	# New canonical URL as of ~2026-01-21: tiles.overturemaps.org
	# (the old overturemaps-tiles-us-west-2-beta.s3.amazonaws.com only
	#  goes up to ~2024-08-20 and is no longer updated)
	urls <- paste0("https://tiles.overturemaps.org/", release, "/", themes, ".pmtiles")
	stats::setNames(as.list(urls), themes)
}

# Internal: the STAC "latest" field already includes the minor version (e.g. "2026-03-18.0")
# so we keep it as-is for tiles.overturemaps.org (which uses the full version with .0)
.overture_latest_release <- function() {
	stac_url <- "https://stac.overturemaps.org/catalog.json"
	resp <- tryCatch(
		jsonlite::fromJSON(stac_url),
		error = function(e) cli::cli_abort(
			"Could not fetch Overture STAC catalog: {conditionMessage(e)}"
		)
	)
	release <- resp[["latest"]]
	if (is.null(release))
		cli::cli_abort("Unexpected STAC catalog format: no 'latest' field found.")
	release  # e.g. "2026-03-18.0" — keep full version for tiles.overturemaps.org
}



#' List layers in a tmap source
#'
#' Convenience wrapper around \code{\link{tmap_source_meta}} that returns only
#' the layer names.
#'
#' @param meta List. Output of \code{\link{tmap_source_meta}}.
#' @return Character vector of layer names.
#' @export
tmap_source_layers <- function(meta) {
	meta$layers
}


#' Get the bounding box of a tmap source
#'
#' Convenience wrapper that exposes the bounding box computed inside
#' \code{\link{tmap_source_meta}}.
#'
#' @param meta List. Output of \code{\link{tmap_source_meta}}.
#' @return An \code{sf} bounding box (\code{bbox}) with CRS OGC:CRS84.
#' @export
tmap_source_bbox <- function(meta) {
	meta$bbox
}


#' Get variables for a layer in a tmap source
#'
#' Returns the variable names and their R classes for a given layer.
#'
#' @param meta List. Output of \code{\link{tmap_source_meta}}.
#' @param layer Character. Layer name; must be one of \code{tmap_source_layers(meta)}.
#'   If the source has exactly one layer, it can be omitted.
#' @return A data frame with columns \code{variable} and \code{class}.
#' @export
tmap_source_vars <- function(meta, layer = NULL) {
	layer <- .resolve_layer(meta, layer)
	meta$layer_vars[[layer]]
}


#' Get categories and suggested colours for a layer variable
#'
#' Returns the known category values for a categorical variable, and — for
#' variables where Overture publishes a closed value set — a suggested named
#' colour palette.  Palettes are only provided where the categories are
#' authoritatively documented in the Overture schema; no palette is returned
#' for open-ended fields.
#'
#' @param meta List. Output of \code{\link{tmap_source_meta}}.
#' @param layer Character. Layer name (may be omitted for single-layer sources).
#' @param var Character. Variable name within the layer.
#' @return A list with elements:
#'   \describe{
#'     \item{\code{categories}}{Character vector of known category values.}
#'     \item{\code{palette}}{Named character vector of hex colours, or
#'       \code{NULL} if no palette is defined for this variable.}
#'   }
#' @export
tmap_source_cats <- function(meta, layer = NULL, var) {
	layer <- .resolve_layer(meta, layer)
	vars_df <- meta$layer_vars[[layer]]

	if (!var %in% vars_df$variable)
		cli::cli_abort("Variable {.field {var}} not found in layer {.field {layer}}.")

	var_class <- vars_df$class[vars_df$variable == var]
	if (var_class != "character")
		cli::cli_warn("Variable {.field {var}} has class {.cls {var_class}}; categories are only meaningful for character variables.")

	key <- paste(layer, var, sep = ".")
	known <- .overture_cats()

	if (key %in% names(known)) {
		known[[key]]
	} else {
		cli::cli_inform(c(
			"i" = "No hardcoded categories for {.field {layer}}.{.field {var}}.",
			" " = "Only variables with a closed, schema-documented value set are included."
		))
		list(categories = character(0), palette = NULL)
	}
}


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

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


# Hardcoded category catalogues derived from the Overture schema.
# Only variables with a *closed*, schema-documented value set are listed.
# Sources:
#   buildings/subtype  – https://docs.overturemaps.org/schema/concepts/by-theme/buildings/
#   transportation/subtype – https://docs.overturemaps.org/guides/transportation/
#
# Colours for building subtype follow a functional logic (residential = warm,
# civic/education = blue tones, industrial = grey, etc.) inspired by
# conventional urban-mapping palettes.  Transportation subtype colours match
# standard cartographic conventions (road = grey, rail = purple, water = blue).
.overture_cats <- function() {
	list(

		# --- buildings : subtype ---------------------------------------------------
		# Categories and palette verified against actual Overture data.
		# Note: schema docs say "education" but data uses "educational".
		`building.subtype` = list(
			categories = c(
				"residential", "commercial", "industrial", "educational",
				"civic", "religious", "medical", "transportation",
				"entertainment", "agricultural", "military", "outbuilding",
				"service"
			),
			palette = c(
				residential   = "#f4a460",
				commercial    = "#4169e1",
				industrial    = "#708090",
				educational   = "#ffd700",
				civic         = "#dc143c",
				religious     = "#9370db",
				medical       = "#ff6347",
				transportation = "#20b2aa",
				entertainment = "#ff69b4",
				agricultural  = "#6b8e23",
				military      = "#556b2f",
				outbuilding   = "#d2b48c",
				service       = "#87ceeb"
			)
		),

		# --- transportation : subtype ----------------------------------------------
		`segment.subtype` = list(
			categories = c("road", "rail", "water"),
			palette = c(
				road  = "#B0B0B0",
				rail  = "#8B6BB1",
				water = "#6BAED6"
			)
		)
	)
}

