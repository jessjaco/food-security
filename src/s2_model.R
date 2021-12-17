library(tidyverse)
library(xgboost)

d <- read_csv("data/s2_data.csv")

test_proportion <- 0.2
n_test_samples <- ceiling(nrow(d) * test_proportion)
test_rows <- sample(nrow(d), n_test_samples, replace = FALSE)

label <- d$crop_id - 1
features <- select(d, -fid, -crop_id, -crop_name)
all_rows <- 1:nrow(d)
train_rows <- all_rows[!all_rows %in% test_rows]

test_labels <- as.matrix(label[test_rows])
test_features <- as.matrix(features[test_rows, ])

train_labels <- as.matrix(label[train_rows])
train_features <- as.matrix(features[train_rows, ])

dgtrain <- xgb.DMatrix(data = train_features, label = train_labels)
dgtest <- xgb.DMatrix(data = test_features, label = test_labels)

params <- list(
  max_depth = 2, eta = 0.3,
  nrounds = 1000, nthread = 8, objective = "multi:softprob", num_class = 5
)

bst <- xgboost(params = params, data = dgtrain)

pred_matrix <- predict(bst, dgtest, reshape = TRUE)
pred_crop_ids <- apply(pred_matrix, 1, function(x) which.max(x))
accuracy <- sum((pred_crop_ids - 1) == test_labels) / length(test_labels)
print(accuracy)
