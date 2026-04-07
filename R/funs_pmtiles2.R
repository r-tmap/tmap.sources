# Read a varint from a raw vector, returns list(value, bytes_consumed)
read_varint <- function(buf, pos) {
	result <- 0
	shift <- 0
	repeat {
		b <- as.integer(buf[pos])
		result <- result + bitwAnd(b, 0x7F) * 2^shift
		pos <- pos + 1
		shift <- shift + 7
		if (bitwAnd(b, 0x80) == 0) break
	}
	list(value = result, pos = pos)
}


# Skip a field we don't care about
skip_field <- function(buf, pos, wire_type) {
	if (wire_type == 0) {        # varint
		v <- read_varint(buf, pos)
		v$pos
	} else if (wire_type == 1) { # 64-bit
		pos + 8
	} else if (wire_type == 2) { # length-delimited
		v <- read_varint(buf, pos)
		v$pos + v$value
	} else if (wire_type == 5) { # 32-bit
		pos + 4
	} else {
		stop("Unknown wire type: ", wire_type)
	}
}

parse_mvt_value <- function(buf, len, start_pos) {
	pos <- start_pos
	end <- pos + len
	result <- NULL
	while (pos < end) {
		tag <- read_tag(buf, pos)
		pos <- tag$pos
		if (tag$field_number == 1 && tag$wire_type == 2) {  # string_value
			v <- read_varint(buf, pos); pos <- v$pos
			result <- rawToChar(buf[pos:(pos + v$value - 1)])
			pos <- pos + v$value
		} else if (tag$field_number == 2 && tag$wire_type == 5) {  # float_value
			result <- readBin(as.raw(buf[pos:(pos+3)]), "numeric", size = 4, endian = "little")
			pos <- pos + 4
		} else if (tag$field_number == 3 && tag$wire_type == 1) {  # double_value
			result <- readBin(as.raw(buf[pos:(pos+7)]), "numeric", size = 8, endian = "little")
			pos <- pos + 8
		} else if (tag$field_number == 4 && tag$wire_type == 0) {  # int_value
			v <- read_varint(buf, pos); pos <- v$pos
			result <- v$value
		} else if (tag$field_number == 5 && tag$wire_type == 0) {  # uint_value
			v <- read_varint(buf, pos); pos <- v$pos
			result <- v$value
		} else if (tag$field_number == 6 && tag$wire_type == 0) {  # sint_value (zigzag)
			v <- read_varint(buf, pos); pos <- v$pos
			# zigzag decode: (n >>> 1) ^ -(n & 1)
			result <- bitwXor(bitwShiftR(v$value, 1), -bitwAnd(v$value, 1))
		} else if (tag$field_number == 7 && tag$wire_type == 0) {  # bool_value
			v <- read_varint(buf, pos); pos <- v$pos
			result <- as.logical(v$value)
		} else {
			pos <- skip_field(buf, pos, tag$wire_type)
		}
	}
	result
}

# Parse one MVT layer, extract keys + value pool only (skip geometry)
parse_mvt_layer <- function(buf, len, start_pos) {
	pos <- start_pos
	end <- pos + len
	name <- NULL
	keys <- c()
	values <- list()

	while (pos < end) {
		tag <- read_tag(buf, pos)
		pos <- tag$pos

		if (tag$field_number == 1 && tag$wire_type == 2) {
			# Layer name
			v <- read_varint(buf, pos); pos <- v$pos
			name <- rawToChar(buf[pos:(pos + v$value - 1)])
			pos <- pos + v$value

		} else if (tag$field_number == 3 && tag$wire_type == 2) {
			# Key string
			v <- read_varint(buf, pos); pos <- v$pos
			keys <- c(keys, rawToChar(buf[pos:(pos + v$value - 1)]))
			pos <- pos + v$value

		} else if (tag$field_number == 4 && tag$wire_type == 2) {
			# Value message
			v <- read_varint(buf, pos); pos <- v$pos
			values <- c(values, list(parse_mvt_value(buf, v$value, pos)))
			pos <- pos + v$value

		} else {
			# Skip features, extent, version etc.
			pos <- skip_field(buf, pos, tag$wire_type)
		}
	}

	list(name = name, keys = keys, values = values)
}

# Top-level: parse all layers from a decompressed MVT tile
parse_mvt_tile <- function(tile_raw) {
	# Decompress if gzip
	is_gzip <- tile_raw[1] == as.raw(0x1f) && tile_raw[2] == as.raw(0x8b)
	buf <- if (is_gzip) memDecompress(tile_raw, type = "gzip") else tile_raw

	pos <- 1L
	layers <- list()

	while (pos <= length(buf)) {
		tag <- read_tag(buf, pos)
		pos <- tag$pos

		if (tag$field_number == 3 && tag$wire_type == 2) {
			# Layer
			v <- read_varint(buf, pos); pos <- v$pos
			layer <- parse_mvt_layer(buf, v$value, pos)
			layers[[layer$name]] <- setNames(layer$values, layer$keys)
			pos <- pos + v$value
		} else {
			pos <- skip_field(buf, pos, tag$wire_type)
		}
	}
	layers
}

get_pmtiles_sample_values <- function(source, max_values = 5) {
	is_local <- !grepl("^https?://", source)
	range_fn <- if (is_local) {
		function(offset, length) read_pmtiles_range_local(source, offset, length)
	} else {
		function(offset, length) pmtiles_range_request(source, offset, length)
	}

	tile_raw <- get_pmtile_any(range_fn)
	layers <- parse_mvt_tile(tile_raw)

	lapply(layers, function(layer_vals) {
		lapply(layer_vals, function(v) {
			unique(unlist(v))[seq_len(min(max_values, length(unique(v))))]
		})
	})
}


get_pmtile_z0 <- function(range_fn) {
	hdr_raw <- range_fn(0, 127)

	root_offset <- read_le_uint64(hdr_raw[9:16])
	root_length <- read_le_uint64(hdr_raw[17:24])
	internal_compression <- as.integer(hdr_raw[98])

	root_raw <- range_fn(root_offset, root_length)
	root_buf <- if (internal_compression == 2L) {
		memDecompress(root_raw, type = "gzip")
	} else {
		root_raw
	}

	pos <- 1L
	num_entries_v <- read_varint(root_buf, pos)
	pos <- num_entries_v$pos
	num_entries <- num_entries_v$value
	message("Root directory has ", num_entries, " entries")

	tile_ids <- numeric(num_entries)
	last_id <- 0
	for (i in seq_len(num_entries)) {
		v <- read_varint(root_buf, pos); pos <- v$pos
		last_id <- last_id + v$value
		tile_ids[i] <- last_id
	}

	run_lengths <- numeric(num_entries)
	for (i in seq_len(num_entries)) {
		v <- read_varint(root_buf, pos); pos <- v$pos
		run_lengths[i] <- v$value
	}

	lengths <- numeric(num_entries)
	for (i in seq_len(num_entries)) {
		v <- read_varint(root_buf, pos); pos <- v$pos
		lengths[i] <- v$value
	}

	offsets <- numeric(num_entries)
	for (i in seq_len(num_entries)) {
		v <- read_varint(root_buf, pos); pos <- v$pos
		offsets[i] <- if (i == 1) v$value else offsets[i-1] + v$value
	}

	message("First 5 tile IDs: ", paste(tile_ids[1:min(5, num_entries)], collapse = ", "))
	message("run_lengths[1:5]: ", paste(run_lengths[1:min(5, num_entries)], collapse = ", "))

	# Convert tile IDs to z/x/y to understand what we have
	for (i in 1:min(5, num_entries)) {
		zxy <- hilbert_id_to_zxy(tile_ids[i])
		message("  tile_id=", tile_ids[i], " -> z=", zxy[1], " x=", zxy[2], " y=", zxy[3],
				" run_length=", run_lengths[i], " length=", lengths[i])
	}

	tile_data_offset <- read_le_uint64(hdr_raw[57:64])

	# Find lowest zoom tile as fallback
	idx <- which(run_lengths == 0)[1]  # run_length=0 means it's a leaf directory pointer
	# Actually just take the first real tile entry (run_length >= 1)
	idx <- which(run_lengths >= 1)[1]
	if (is.na(idx)) stop("No tiles found in root directory")

	message("Using first available tile_id=", tile_ids[idx])
	tile_offset <- tile_data_offset + offsets[idx]
	tile_length <- lengths[idx]

	range_fn(tile_offset, tile_length)
}

# Helper: convert Hilbert tile ID back to z/x/y (for debugging)
hilbert_id_to_zxy <- function(id) {
	acc <- 0
	for (z in 0:26) {
		num_tiles <- 4^z
		if (acc + num_tiles > id) {
			hilbert_d <- id - acc
			xy <- hilbert_d_to_xy(hilbert_d, z)
			return(c(z, xy[1], xy[2]))
		}
		acc <- acc + num_tiles
	}
}

hilbert_d_to_xy <- function(d, n_bits) {
	x <- 0; y <- 0
	s <- 1
	t <- d
	while (s < 2^n_bits) {
		rx <- bitwAnd(bitwShiftR(t, 1), 1L)
		ry <- bitwAnd(bitwXor(t, rx), 1L)
		if (ry == 0) {
			if (rx == 1) { x <- s - 1 - x; y <- s - 1 - y }
			tmp <- x; x <- y; y <- tmp
		}
		x <- x + s * rx
		y <- y + s * ry
		t <- bitwShiftR(t, 2)
		s <- s * 2
	}
	c(x, y)
}


get_pmtile_any <- function(range_fn) {
	hdr_raw <- range_fn(0, 127)

	root_offset <- read_le_uint64(hdr_raw[9:16])
	root_length <- read_le_uint64(hdr_raw[17:24])
	leaf_dir_offset <- read_le_uint64(hdr_raw[41:48])
	tile_data_offset <- read_le_uint64(hdr_raw[57:64])
	internal_compression <- as.integer(hdr_raw[98])

	decompress <- function(raw) safe_decompress(raw, internal_compression)

	parse_directory <- function(buf) {
		pos <- 1L
		n_v <- read_varint(buf, pos); pos <- n_v$pos
		n <- n_v$value

		tile_ids <- numeric(n); last_id <- 0
		for (i in seq_len(n)) {
			v <- read_varint(buf, pos); pos <- v$pos
			last_id <- last_id + v$value
			tile_ids[i] <- last_id
		}
		run_lengths <- numeric(n)
		for (i in seq_len(n)) {
			v <- read_varint(buf, pos); pos <- v$pos
			run_lengths[i] <- v$value
		}
		lengths <- numeric(n)
		for (i in seq_len(n)) {
			v <- read_varint(buf, pos); pos <- v$pos
			lengths[i] <- v$value
		}
		offsets <- numeric(n)
		for (i in seq_len(n)) {
			v <- read_varint(buf, pos); pos <- v$pos
			offsets[i] <- if (i == 1) v$value else offsets[i-1] + v$value
		}
		list(tile_ids = tile_ids, run_lengths = run_lengths,
			 lengths = lengths, offsets = offsets)
	}

	# Parse root directory
	root_buf <- decompress(range_fn(root_offset, root_length))
	root <- parse_directory(root_buf)

	# All run_length == 0 means leaf directory pointers
	# Pick first leaf, fetch it, then get first real tile from there
	leaf_idx <- which(root$run_lengths == 0)[1]
	message("Following leaf directory pointer at index ", leaf_idx,
			" (tile_id=", root$tile_ids[leaf_idx], ")")

	# Leaf offset is relative to leaf_dir_offset, not tile_data_offset
	leaf_raw <- range_fn(leaf_dir_offset + root$offsets[leaf_idx],
						 root$lengths[leaf_idx])
	leaf <- parse_directory(decompress(leaf_raw))

	message("Leaf directory has ", length(leaf$tile_ids), " entries")
	message("First 3 run_lengths: ", paste(leaf$run_lengths[1:3], collapse = ", "))

	message("Leaf directory has ", length(leaf$tile_ids), " entries")
	message("First 3 run_lengths: ", paste(leaf$run_lengths[1:3], collapse = ", "))
	message("First 3 tile_ids:    ", paste(leaf$tile_ids[1:3], collapse = ", "))
	message("First 3 offsets:     ", paste(leaf$offsets[1:3], collapse = ", "))
	message("First 3 lengths:     ", paste(leaf$lengths[1:3], collapse = ", "))

	# Find first actual tile (run_length >= 1)
	tile_idx <- which(leaf$run_lengths >= 1)[1]
	if (is.na(tile_idx)) stop("No real tiles found in leaf directory")

	zxy <- hilbert_id_to_zxy(leaf$tile_ids[tile_idx])
	message("Fetching tile z=", zxy[1], " x=", zxy[2], " y=", zxy[3],
			" length=", leaf$lengths[tile_idx])

	range_fn(tile_data_offset + leaf$offsets[tile_idx], leaf$lengths[tile_idx])
}

safe_decompress <- function(raw, compression) {
	# Try to detect compression from magic bytes rather than trusting the flag
	if (length(raw) >= 2 && raw[1] == as.raw(0x1f) && raw[2] == as.raw(0x8b)) {
		memDecompress(raw, type = "gzip")
	} else if (length(raw) >= 4 &&
			   raw[1] == as.raw(0x28) && raw[2] == as.raw(0xb5) &&
			   raw[3] == as.raw(0x2f) && raw[4] == as.raw(0xfd)) {
		memDecompress(raw, type = "zstd")
	} else {
		raw  # assume uncompressed
	}
}

skip_field <- function(buf, pos, wire_type) {
	if (wire_type == 0) {        # varint
		v <- read_varint(buf, pos)
		v$pos
	} else if (wire_type == 1) { # 64-bit
		pos + 8
	} else if (wire_type == 2) { # length-delimited
		v <- read_varint(buf, pos)
		v$pos + v$value
	} else if (wire_type == 5) { # 32-bit
		pos + 4
	} else if (wire_type == 3 || wire_type == 4) { # start/end group (deprecated)
		pos
	} else if (wire_type == 6) { # fixed 32-bit (same as wire_type 5)
		pos + 4
	} else {
		# Unknown wire type - skip 1 byte and hope for the best
		message("Skipping unknown wire type: ", wire_type, " at pos ", pos)
		pos + 1
	}
}

read_tag <- function(buf, pos) {
	v <- read_varint(buf, pos)
	val <- v$value
	list(
		field_number = floor(val / 8),   # avoid bitwShiftR overflow
		wire_type    = val %% 8,         # avoid bitwAnd overflow
		pos          = v$pos
	)
}



