library(tidyverse)
library(rjson)
library(xgboost)
source("src/utils.R")

d <- read_csv("data/training_data.csv")
test_d <- read_csv("data/test_data.csv")
model_id <- "6b"

params <- list(
  max_depth = 5, min_child_weight = 1, gamma = 0, subsample = 0.8,
  colsample_bytree = 0.8, eta = 0.1, nthread = 7,
  objective = "multi:softprob", num_class = length(unique(d$crop_id))
)

results <- run_run(d, test_d, params, model_id)

training_predictions <- make_predictions(results$model, d)
read_sf("data/training_labels.geojson") %>%
  left_join(training_predictions) %>%
  write_sf(glue("data/submissions/{model_id}_training_predictions.geojson"))
