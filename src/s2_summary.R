library(tools)

library(exactextractr)
library(sf)
library(terra)
library(tidyverse)


img_summary <- function(img_path, labels) {
  print(img_path)
  img <- rast(img_path)
  img <- mask(img, img[["scl"]] %in% c(4, 5), maskvalues = 0)[[1:12]]
  results <- exact_extract(img, labels, fun = c("mean", "stdev", "quantile"), quantiles = c(0, 0.25, 0.5, 0.75, 1))
  tmpFiles(remove = TRUE)
  names(results) <- paste0(file_path_sans_ext(basename(img_path)), "_", sub("^(.*)\\.(.*)$", "\\2_\\1", names(results)))
  results
}

s2_images <- function(good_only = FALSE) {
  s2_images <- list.files("data/s2_tiffs", pattern = "*.tif$", full.names = TRUE)
  if (good_only) {
    jdays <- sub("^.*_([^_]+).tif", "\\1", s2_images)
    good_jdays <- c(
      "108", "128", "183", "188", "193", "198", "203", "208",
      "218", "233", "238", "243", "246", "253", "273", "278",
      "283", "293", "303", "308", "323", "328", "333"
    )
    return(s2_images[jdays %in% good_jdays])
  }
  s2_images
}

process_labels <- function(s2_images, labels, output_path) {
  lapply(s2_images, img_summary, labels = labels) %>%
    bind_cols(labels, .) %>%
    st_set_geometry(NULL) %>%
    write_csv(output_path)
}


training_labels <- read_sf("data/training_labels.geojson")
test_labels <- read_sf("data/test_labels.geojson")

# process_labels(s2_images(), training_labels, "data/s2_training_data.csv")
# process_labels(s2_images(), test_labels, "data/s2_test_data.csv")

process_labels(s2_images(TRUE), training_labels, "data/s2_good_training_data.csv")
process_labels(s2_images(TRUE), test_labels, "data/s2_good_test_data.csv")
