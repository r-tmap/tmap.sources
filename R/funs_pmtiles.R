read_pmtiles_range_local <- function(path, offset, length) {
	con <- file(path, "rb")
	on.exit(close(con))
	seek(con, offset)
	readBin(con, "raw", n = length)
}

pmtiles_range_request <- function(url, offset, length) {
	req <- httr2::request(url) |>
		httr2::req_headers(
			Range = sprintf("bytes=%.0f-%.0f", offset, offset + length - 1)
		) |>
		httr2::req_perform()
	httr2::resp_body_raw(req)
}

read_le_uint64 <- function(raw_bytes) {
	sum(as.numeric(raw_bytes) * 256^(0:7))
}

read_le_int32 <- function(b) {
	val <- sum(as.numeric(b) * 256^(0:3))
	if (val >= 2^31) val <- val - 2^32
	val
}

read_pmtiles_header_impl <- function(range_fn) {
	hdr <- range_fn(0, 127)

	if (!startsWith(rawToChar(hdr[1:7]), "PMTiles")) stop("Not a valid PMTiles file")

	compression_name <- c("unknown", "none", "gzip", "brotli", "zstd")
	tile_type_name   <- c("unknown", "mvt", "png", "jpeg", "webp", "avif")

	list(
		spec_version         = as.integer(hdr[8]),
		internal_compression = compression_name[as.integer(hdr[98]) + 1],
		tile_compression     = compression_name[as.integer(hdr[99]) + 1],
		tile_type            = tile_type_name[as.integer(hdr[100]) + 1],
		minzoom              = as.integer(hdr[101]),
		maxzoom              = as.integer(hdr[102]),
		bounds               = c(
			read_le_int32(hdr[103:106]) / 1e7,
			read_le_int32(hdr[107:110]) / 1e7,
			read_le_int32(hdr[111:114]) / 1e7,
			read_le_int32(hdr[115:118]) / 1e7
		),
		center               = c(
			read_le_int32(hdr[120:123]) / 1e7,
			read_le_int32(hdr[124:127]) / 1e7,
			as.integer(hdr[119])
		)
	)
}

read_pmtiles_metadata_impl <- function(range_fn) {
	hdr <- range_fn(0, 127)

	meta_offset <- read_le_uint64(hdr[25:32])
	meta_length <- read_le_uint64(hdr[33:40])

	meta_raw <- range_fn(meta_offset, meta_length)

	is_gzip <- meta_raw[1] == as.raw(0x1f) && meta_raw[2] == as.raw(0x8b)
	meta_json <- if (is_gzip) {
		rawToChar(memDecompress(meta_raw, type = "gzip"))
	} else {
		rawToChar(meta_raw)
	}

	jsonlite::fromJSON(meta_json, simplifyVector = FALSE)
}

read_pmtiles_info <- function(source) {
	is_local <- !grepl("^https?://", source)

	range_fn <- if (is_local) {
		function(offset, length) read_pmtiles_range_local(source, offset, length)
	} else {
		function(offset, length) pmtiles_range_request(source, offset, length)
	}

	list(
		header   = read_pmtiles_header_impl(range_fn),
		metadata = read_pmtiles_metadata_impl(range_fn)
	)
}

