library(tidyverse)
d <- read_csv("data/s2_good_training_data.csv") %>%
  select(fid, crop_name, ends_with("mean")) %>%
  pivot_longer(ends_with("mean"), names_to = c("time", ".value"), names_pattern = "^s2_([^_]+)_(.+)$") %>%
  mutate(date = as.Date(paste0(time, "-2017"), format = "%j-%Y"), NDVI = 1000 * (B08_mean - B04_mean) / (B08_mean + B04_mean))
