library(dplyr)
library(sf)


labels_8 <- read_sf("data/input/ref_fusion_competition_south_africa_train_labels/ref_fusion_competition_south_africa_train_labels_34S_19E_258N/labels.geojson")

labels_9 <- read_sf("data/input/ref_fusion_competition_south_africa_train_labels/ref_fusion_competition_south_africa_train_labels_34S_19E_259N/labels.geojson")

rbind(labels_8, labels_9) %>% write_sf("data/training_labels.geojson")

read_sf("data/input/ref_fusion_competition_south_africa_test_labels/ref_fusion_competition_south_africa_test_labels_34S_20E_259N/labels.geojson") %>%
  write_sf("data/test_labels.geojson")
