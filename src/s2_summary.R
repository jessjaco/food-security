library(tools)

library(sf)
library(terra)
library(exactextractr)


img_summary <- function(img_path, labels) {
  print(img_path)
  img <- rast(img_path)
  img <- mask(img, img[["scl"]] == 5, maskvalues = 0, NA)[[1:12]]
  results <- exact_extract(img, labels, fun = c("mean", "stdev", "quantile"), quantiles = c(0, 0.25, 0.5, 0.75, 1))
  tmpFiles(remove = TRUE)
  names(results) <- paste0(file_path_sans_ext(basename(img_path)), "_", sub("^(.*)\\.(.*)$", "\\2_\\1", names(results)))
  results
}

labels <- read_sf("data/labels.geojson")
s2_images <- list.files("data/", pattern = "*.tif", full.names = TRUE)

lapply(s2_images, img_summary, labels = labels) %>%
  bind_cols(labels, .) %>%
  st_set_geometry(NULL) %>%
  write_csv("data/s2_data.csv")
