library(tidyverse)
library(rjson)
library(xgboost)

d <- read_csv("data/s2_training_data.csv")

label <- d$crop_id - 1
features <- select(d, -fid, -crop_id, -crop_name)

dg <- xgb.DMatrix(data = as.matrix(features), label = as.matrix(label))

params <- list(
  max_depth = 5, min_child_weight = 1, gamma = 0, subsample = 0.8, colsample_bytree = 0.8, eta = 0.3, nthread = 7, objective = "multi:softprob",
  num_class = length(unique(label))
)
cv_og <- xgb.cv(params = list(max_depth = 2, eta = 0.1, objective = "multi:softprob", num_class = 5), data = dg, nrounds = 10000, nfold = 10, early_stopping_rounds = 3, prediction = TRUE)
cv <- xgb.cv(params = params, data = dg, nrounds = 10000, nfold = 10, early_stopping_rounds = 3, prediction = TRUE)

browser()
m_og <- do.call(xgboost, c(data = dg, nrounds = 360, max_depth = 2, eta = 0.1, objective = "multi:softprob", num_class = 5))
m <- do.call(xgboost, c(data = dg, nrounds = 33, params))


make_predictions <- function(m, output_file_stem) {
  test_df <- read_csv("data/s2_test_data.csv")

  obj_names <- as.character(seq_len(nrow(test_df)) - 1)

  fid <- test_df$fid
  names(fid) <- obj_names

  test_d <- test_df %>%
    select(-fid, -crop_id, -crop_name) %>%
    as.matrix() %>%
    xgb.DMatrix()

  pred_matrix <- predict(m, test_d, reshape = TRUE)

  crop_id <- apply(pred_matrix, 1, which.max)
  names(crop_id) <- obj_names

  crop_names <- c("Wheat", "Barley", "Canola", "Lucerne/Medics", "Small grain grazing")
  crop_name <- crop_names[crop_id]
  names(crop_name) <- obj_names

  rownames(pred_matrix) <- obj_names

  predict_list <- list(
    fid = fid,
    crop_id = crop_id,
    crop_name = crop_name,
    crop_probs = as.list(as.data.frame(t(pred_matrix)))
  )

  json_file <- paste0(output_file_stem, ".json")
  toJSON(predict_list) %>% writeLines(json_file)
  tar(paste0(output_file_stem, ".tar.gz"), json_file, compression = "gzip")
}

make_predictions(m, "data/submissions/2")
make_predictions(m_og, "data/submissions/1_alt")
