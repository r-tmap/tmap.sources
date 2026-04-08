load_all("../tmap")
load_all("../tmap.mapgl")
load_all()


tm_shape(NLD_dist) +
	tm_polygons(fill = "edu_appl_sci", fill.scale = tm_scale_intervals(style = "kmeans", values = "plasma"))


NLD_dist$edu_ids = cut(NLD_dist$edu_appl_sci, breaks = c(0, 21.5, 29.5, 39.8, 51.5, 90))

NLD_dist$edu_fill = c4a("plasma", 5)[cut(NLD_dist$edu_appl_sci, breaks = c(0, 21.5, 29.5, 39.8, 51.5, 90), include.lowest = TRUE)]
NLD_dist$edu_fill[is.na(NLD_dist$edu_fill)] = c4a_na("plasma")


freestile(
	NLD_dist,
	"NLD_dist.pmtiles",
	layer_name = "edu",
	min_zoom = 4,
	max_zoom = 15
)

tmap_mode("maplibre")

tm_shape("NLD_dist.pmtiles") +
	tm_polygons(fill = "edu_fill") +
	tm_add_legend(fill = c4a("plasma", n = 5), labels = levels(NLD_dist$edu_ids), type = "polygons")

tm_shape("http://localhost:6515/NLD_dist.pmtiles") +
	tm_polygons(fill = "edu_fill") +
	tm_add_legend(fill = c4a("plasma", n = 5), labels = levels(NLD_dist$edu_ids), type = "polygons")

tm_shape("http://localhost:6515/NLD_dist.pmtiles", layer = "edu") +
	tm_polygons(fill = "edu_fill") +
	tm_add_legend(fill = c4a("plasma", n = 5), labels = levels(NLD_dist$edu_ids), type = "polygons")


load_all("../freestiler/")

view_tiles("NLD_dist.pmtiles")

serve_tiles("NLD_dist.pmtiles")

library(mapgl)
maplibre() |>
	mapgl::add_pmtiles_source(id = "test123", url = "http://127.0.0.1:7948/NLD_dist.pmtiles") |>
	mapgl::add_fill_layer(id = "temp", source = "test123", source_layer = "edu", fill_color = "#ffff00")

maplibre() |>
	mapgl::add_pmtiles_source(id = "test123", url = "http://localhost:8080/NLD_dist.pmtiles") |>
	mapgl::add_fill_layer(id = "temp", source = "test123", source_layer = "edu", fill_color = mapgl::get_column("edu_fill"))


maplibre() |>
	mapgl::add_pmtiles_source(id = "test123", url = "http://localhost:4234/NLD_dist.pmtiles") |>
	mapgl::add_fill_layer(id = "temp", source = "test123", source_layer = "edu", fill_color = mapgl::get_column("edu_fill"))



pmtiles::pm_show("https://overturemaps-tiles-us-west-2-beta.s3.amazonaws.com/2024-07-22/buildings.pmtiles", metadata = T, header_json = T)

freestiler:::.pmtiles_metadata("NLD_dist.pmtiles")
pmtiles::pm_show("NLD_dist.pmtiles", metadata = T)


tmap_source("https://overturemaps-tiles-us-west-2-beta.s3.amazonaws.com/2024-07-22/buildings.pmtiles")


tm_shape("https://overturemaps-tiles-us-west-2-beta.s3.amazonaws.com/2024-07-22/buildings.pmtiles") +
	tm_polygons(fill = "facade_color")

library(mapgl)
maplibre() |>
	mapgl::add_pmtiles_source(id = "test123", url = "https://overturemaps-tiles-us-west-2-beta.s3.amazonaws.com/2024-07-22/buildings.pmtiles") |>
	mapgl::add_fill_layer(id = "temp", source = "test123", source_layer = "building", fill_color = mapgl::get_column("facade_color"))



meta = read_pmtiles_info(source)
layer = "building"


b = get_pmtiles_sample_values(source, layer)

tmap_source(source)



source = "NLD_dist.pmtiles"
source = "https://f004.backblazeb2.com/file/geospatial/koppen_geiger_climatezones_1991_2020_1km_numeric_3857.pmtiles"
source = "https://overturemaps-tiles-us-west-2-beta.s3.amazonaws.com/2024-07-22/buildings.pmtiles"

tmap_source(source)

source = "https://overturemaps-tiles-us-west-2-beta.s3.amazonaws.com/2024-07-22/buildings.pmtiles"

tm_shape(source) +
	tm_polygons()

tm_shape(source) +
	tm_raster()


maplibre() |>
	mapgl::add_pmtiles_source(id = "test123", url = "https://f004.backblazeb2.com/file/geospatial/koppen_geiger_climatezones_1991_2020_1km_numeric_3857.pmtiles") |>
	mapgl::add_raster_layer(id = "temp", source = "test123")

maplibre(
	style  = carto_style("positron"),
	center = c(-100, 37),
	zoom   = 3
) |>
	add_pmtiles_source(
		id = "koppen-source",
		url = "https://f004.backblazeb2.com/file/geospatial/koppen_geiger_climatezones_1991_2020_1km_numeric_3857.pmtiles",
		source_type  = "raster"
	) |>
	add_raster_layer(
		id = "koppen-layer",
		source = "koppen-source"
	)



urls = tmap_source_overture()


urls$buildings

meta = tmap_source_meta(urls$transportation)
meta = tmap_source_meta(urls$buildings)
tmap_source_layers(meta)
tmap_source_vars(meta, layer = "building")
tmap_source_cats(meta, layer = "building", var = "subtype")
tmap_source_cats(meta, layer = "building", var = "subtype")

tmap_source_vars(meta, layer = "segment")

tm_shape(meta$input, layer = "building") +
	tm_polygons(fill = "subtype")

