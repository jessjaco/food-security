library(tidyverse)
library(xgboost)

d <- read_csv("data/s2_data.csv")

label <- d$crop_id - 1
features <- select(d, -fid, -crop_id, -crop_name)

dg <- xgb.DMatrix(data = features, label = label)

params <- list(
  max_depth = 3, eta = 0.3, nrounds = 100, nthread = 8, objective = "multi:softprob",
  num_class = 5
)

bst <- cv(params = params, data = dg, nrounds = 10, nfold = 2)

# pred_matrix <- predict(bst, dgtest, reshape = TRUE)
# pred_crop_ids <- apply(pred_matrix, 1, function(x) which.max(x))
# accuracy <- sum((pred_crop_ids - 1) == test_labels) / length(test_labels)
# print(accuracy)
