library(tools)

library(exactextractr)
library(sf)
library(terra)
library(tidyverse)

index <- function(band1, band2) 10000 * ((band1 - band2) / (band1 + band2))

img_summary <- function(img_path, labels, type = "s2") {
  print(img_path)
  if (type == "s2") {
    img <- rast(img_path)
    img <- mask(img, img[["scl"]] %in% c(4, 5), maskvalues = 0)[[1:12]]
    img[["NDVI"]] <- index(img[["B08"]], img[["B04"]])
    img[["NDVIa"]] <- index(img[["B8A"]], img[["B04"]])
    img[["NDWI"]] <- index(img[["B03"]], img[["B08"]])
    img[["NDWIa"]] <- index(img[["B8A"]], img[["B11"]])
    img[["NDYI"]] <- index(img[["B03"]], img[["B02"]])
    img[["PSRI"]] <- 10000 * ((img[["B04"]] - img[["B02"]]) / img[["B06"]])
  } else if (type == "pt") {
    img <- merge(terra::src(lapply(img_path, rast)))
    img[["NDVI"]] <- index(img[["sr_4"]], img[["sr_3"]])
  } else { # s1
    img <- rast(img_path)
    # Remove mask, doesn't look like it's needed
    img <- img[[c("angle", "vh", "vv")]]
    # see
    # https://github.com/AI4EO/tum-planet-radearth-ai4food-challenge/blob/main/notebook/starter-pack.ipynb
    # This is "dual-pol" RVI
    dop <- img[["vv"]] / (img[["vv"]] + img[["vh"]])
    img[["rvi"]] <- 10000 * sqrt(dop) * ((4 * img[["vh"]]) / (img[["vv"]] + img[["vh"]]))
  }
  results <- exact_extract(img, labels, fun = c("mean", "stdev", "quantile"), quantiles = c(0, 0.25, 0.5, 0.75, 1))
  tmpFiles(remove = TRUE)
  if (type == "pt") {
    names(results) <- paste0("pt_", str_sub(dirname(img_path[[1]]), start = -5), "_", names(results))
  } else {
    names(results) <- paste0(file_path_sans_ext(basename(img_path)), "_", sub("^(.*)\\.(.*)$", "\\2_\\1", names(results)))
  }
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

planet_images <- function() {
  images8 <- list.files("data/input/ref_fusion_competition_south_africa_train_source_planet_5day",
    pattern = "^.*258.*$", full.names = TRUE
  )
  lapply(images8, function(directory) {
    image8 <- file.path(directory, "sr.tif")
    image9 <- sub("258N", "259N", image8)
    image10 <- gsub("train", "test", sub("19E", "20E", image9))
    list(image8, image9, image10)
  })
}

process_labels <- function(labels, images, output_path, type = "s2") {
  lapply(images, img_summary, labels = labels, type = type) %>%
    bind_cols(labels, .)
}

read_sf("data/training_labels.geojson") %>%
  process_labels(planet_images(), type = "pt") %>%
  process_labels(s2_images(TRUE)) %>%
  process_labels(s1_images(), type = "s1") %>%
  st_set_geometry(NULL) %>%
  write_csv("data/training_data_2.csv")

read_sf("data/test_labels.geojson") %>%
  process_labels(planet_images(), type = "pt") %>%
  process_labels(s2_images(TRUE)) %>%
  process_labels(s1_images(), type = "s1") %>%
  st_set_geometry(NULL) %>%
  write_csv("data/test_data_2.csv")
