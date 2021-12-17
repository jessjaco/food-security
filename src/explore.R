library(sf)

label_files <- list.files("data/ref_fusion_competition_south_africa_train_labels", recursive = TRUE, pattern = "*.geojson", full.names = TRUE)

labels <- do.call(rbind, lapply(label_files, read_sf))


