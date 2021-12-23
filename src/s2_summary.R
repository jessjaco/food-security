library(tools)

library(exactextractr)
library(sf)
library(terra)
library(tidyverse)


img_summary <- function(img_path, labels) {
  print(img_path)
  img <- rast(img_path)
  img <- mask(img, img[["scl"]] == 5, maskvalues = 0, NA)[[1:12]]
  results <- exact_extract(img, labels, fun = c("mean", "stdev", "quantile"), quantiles = c(0, 0.25, 0.5, 0.75, 1))
  tmpFiles(remove = TRUE)
  names(results) <- paste0(file_path_sans_ext(basename(img_path)), "_", sub("^(.*)\\.(.*)$", "\\2_\\1", names(results)))
  results
}

process_labels <- function(s2_images, labels, output_path) {
  lapply(s2_images, img_summary, labels = labels) %>%
    bind_cols(labels, .) %>%
    st_set_geometry(NULL) %>%
    write_csv(output_path)
}

training_labels <- read_sf("data/training_labels.geojson")
test_labels <- read_sf("data/test_labels.geojson")
s2_images <- list.files("data/s2_tiffs", pattern = "*.tif", full.names = TRUE)

process_labels(s2_images, training_labels, "data/s2_training_data.csv")
process_labels(s2_images, test_labels, "data/s2_test_data.csv")
