library(tools)

library(exactextractr)
library(sf)
library(terra)
library(tidyverse)


img_summary <- function(img_path, labels, type = "s2") {
  print(img_path)
  img <- rast(img_path)
  if (type == "s2") {
    img <- mask(img, img[["scl"]] %in% c(4, 5), maskvalues = 0)[[1:12]]
    img[["NDVI"]] <- 10000 * ((img[["B08"]] - img[["B04"]]) / (img[["B08"]] + img[["B04"]]))
  } else { # s1
    # Remove mask, doesn't look like it's needed
    img <- img[[c("angle", "vh", "vv")]]
    # see
    # https://github.com/AI4EO/tum-planet-radearth-ai4food-challenge/blob/main/notebook/starter-pack.ipynb
    dop <- img[["vv"]] / (img[["vv"]] + img[["vh"]])
    img[["rvi"]] <- 10000 * sqrt(dop) * ((4 * img[["vh"]]) / (img[["vv"]] + img[["vh"]]))
  }
  results <- exact_extract(img, labels, fun = c("mean", "stdev", "quantile"), quantiles = c(0, 0.25, 0.5, 0.75, 1))
  tmpFiles(remove = TRUE)
  names(results) <- paste0(file_path_sans_ext(basename(img_path)), "_", sub("^(.*)\\.(.*)$", "\\2_\\1", names(results)))
  results
}

s1_images <- function() list.files("data/s1_tiffs", pattern = "*.tif$", full.names = TRUE)

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

process_labels <- function(labels, images, output_path, type = "s2") {
  lapply(images, img_summary, labels = labels, type = type) %>%
    bind_cols(labels, .)
}

read_sf("data/training_labels.geojson") %>%
  process_labels(s1_images(), type = "s1") %>%
  process_labels(s2_images(TRUE)) %>%
  st_set_geometry(NULL) %>%
  write_csv("data/training_data.csv")

read_sf("data/test_labels.geojson") %>%
  process_labels(s1_images(), type = "s1") %>%
  process_labels(s2_images(TRUE)) %>%
  st_set_geometry(NULL) %>%
  write_csv("data/test_data.csv")
