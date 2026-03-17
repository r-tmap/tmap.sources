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
