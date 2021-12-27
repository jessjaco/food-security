library(tidyverse)
library(rjson)
library(xgboost)
source("src/utils.R")

d <- read_csv("data/s2_good_training_data.csv") %>%
  add_NDVI()

test_d <- read_csv("data/s2_good_test_data.csv") %>% add_NDVI()

params <- list(
  max_depth = 5, min_child_weight = 1, gamma = 0, subsample = 0.8,
  colsample_bytree = 0.8, eta = 0.1, nthread = 7, objective = "multi:softprob",
  num_class = length(unique(d$crop_id))
)

run_run(d, test_d, params, "5", weight = TRUE)
