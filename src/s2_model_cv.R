library(tidyverse)
library(rjson)
library(xgboost)
source("src/utils.R")

d <- read_csv("data/s2_good_training_data.csv")

label <- d$crop_id - 1
features <- select(d, -fid, -crop_id, -crop_name)

dg <- xgb.DMatrix(data = as.matrix(features), label = as.matrix(label))

params <- list(
  max_depth = 5, min_child_weight = 1, gamma = 0, subsample = 0.8,
  colsample_bytree = 0.8, eta = 0.3, nthread = 7, objective = "multi:softprob",
  num_class = length(unique(label))
)
cv <- xgb.cv(
  params = params, data = dg, nrounds = 10000, nfold = 10,
  early_stopping_rounds = 3, prediction = TRUE
)
saveRDS(cv, "data/submissions/2_good_cv.rds")

browser()
m <- do.call(xgboost, c(data = dg, nrounds = cv$best_iteration, params))
xgb.save(m, "data/submissions/2_good.xgb")

make_predictions(m, read_csv("data/s2_good_test_data.csv"), "data/submissions/2_good")
