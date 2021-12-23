library(tidyverse)
library(rjson)
library(xgboost)

d <- read_csv("data/s2_training_data.csv")

label <- d$crop_id - 1
features <- select(d, -fid, -crop_id, -crop_name)

dg <- xgb.DMatrix(data = as.matrix(features), label = as.matrix(label))

params <- list(
  max_depth = 2, eta = 0.1, nthread = 7, objective = "multi:softprob",
  num_class = length(unique(label))
)

cv <- xgb.cv(params = params, data = dg, nrounds = 10000, nfold = 10, early_stopping_rounds = 3, prediction = TRUE)

m <- xgboost(
  data = dg, max_depth = 2, eta = 0.1, nthread = 7, objective = "multi:softprob",
  num_class = length(unique(label)), nrounds = 307
)
# 307 is nroudsn from cv


test_df <- read_csv("data/s2_test_data.csv")
pred_matrix <- predict(m, test_d, reshape = TRUE)

obj_names <- as.character(seq_len(nrow(test_df)) - 1)

fid <- test_df$fid
names(fid) <- obj_names

crop_id <- apply(pred_matrix, 1, which.max)
names(crop_id) <- obj_names

crop_names <- c("Wheat", "Barley", "Canola", "Lucerne/Medics", "Small grain grazing")
crop_name <- crop_names[crop_id]
names(crop_name) <- obj_names

rowNames(pred_matrix) <- obj_names

predict_list <- list(
  fid = fid,
  crop_id = crop_id,
  crop_name = crop_name,
  crop_probs = as.list(as.data.frame(t(pred_matrix)))
)

toJSON(predict_list) %>% writeLines("data/submission_1.json")
