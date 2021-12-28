library(tidyverse)
library(rjson)
library(xgboost)
source("src/utils.R")

d <- read_csv("data/training_data.csv")
test_d <- read_csv("data/test_data.csv")

params <- list(
  max_depth = 5, min_child_weight = 1, gamma = 0, subsample = 0.8,
  colsample_bytree = 0.8, eta = 0.05, nthread = 7,
  objective = "multi:softprob", num_class = length(unique(d$crop_id))
)

m <- run_run(d, test_d, params, "7")
