library(glue)
library(keras)
library(tidyverse)
library(xgboost)
library(rjson)

cce <- function(label_vec, pred_mat) {
  y_true <- to_categorical(label_vec - 1)
  y_pred <- to_categorical(apply(pred_mat, 1, which.max) - 1)
  mean(k_get_value(loss_categorical_crossentropy(y_true, y_pred)))
}

cce_xgb <- function(preds, dtrain) {
  # Ultimately, this is the same as merror
  label_vec <- getinfo(dtrain, "label") + 1
  pred_mat <- matrix(preds, ncol = length(unique(label_vec)), byrow = TRUE)
  list(metric = "cce", value = cce(label_vec, pred_mat))
}

mlogloss <- function(label_vec, pred_matrix) {
  selection <- matrix(ncol = 2, c(1:nrow(pred_matrix), label_vec))
  -mean(log(pred_matrix[selection]))
}

make_predictions <- function(m, test_df, output_file_stem = NA, scale = FALSE) {
  obj_names <- as.character(seq_len(nrow(test_df)) - 1)

  fid <- test_df$fid
  names(fid) <- obj_names

  test_d <- test_df %>%
    select(-fid, -crop_id, -crop_name) %>%
    mutate(across(everything(), ~ replace_na(scale(.), 0))) %>%
    as.matrix() %>%
    xgb.DMatrix()

  pred_matrix <- predict(m, test_d, reshape = TRUE)

  crop_id <- apply(pred_matrix, 1, which.max)
  names(crop_id) <- obj_names

  crop_names <- c("Wheat", "Barley", "Canola", "Lucerne/Medics", "Small grain grazing")
  crop_name <- crop_names[crop_id]
  names(crop_name) <- obj_names
  rownames(pred_matrix) <- obj_names

  if (!is.na(output_file_stem)) {
    predict_list <- list(
      fid = fid,
      crop_id = crop_id,
      crop_name = crop_name,
      crop_probs = as.list(as.data.frame(t(pred_matrix)))
    )

    json_file <- paste0(output_file_stem, ".json")
    toJSON(predict_list) %>% writeLines(json_file)
    tar(paste0(output_file_stem, ".tar.gz"), basename(json_file), compression = "gzip", tar = paste0("tar -C ", dirname(output_file_stem)))
  }

  pred_df <- as.data.frame(pred_matrix)
  names(pred_df) <- paste0("pred_crop_prob_", 1:ncol(pred_df))
  results <- cbind(data.frame(fid = fid, pred_crop_id = crop_id, pred_crop_name = crop_name), pred_df)

  if (!is.na(output_file_stem)) {
    write_csv(results, paste0(output_file_stem, "_predictions.csv"))
  }
  results
}

split_train_set <- function(d, train_proportion) {
  n_train_samples <- ceiling(nrow(d) * train_proportion)
  train_rows <- sample(nrow(d), n_train_samples, replace = FALSE)
  list(train_d = d[train_rows, ], validation_d = d[!1:nrow(d) %in% train_rows, ])
}

run_run <- function(training_d, params, id, test_d = NA, nrounds = "cv",
                    seed = 1337, output_dir = "data/submissions",
                    weight = FALSE) {
  set.seed(seed)

  label <- training_d$crop_id - 1
  features <- select(training_d, -fid, -crop_id, -crop_name)

  dg <- xgb.DMatrix(data = as.matrix(features), label = as.matrix(label))

  if (weight) {
    # Right? See
    # https://datascience.stackexchange.com/questions/16342/unbalanced-multiclass-data-with-xgboost
    # but, it doesn't seem to be doing anything
    class_counts <- table(training_d$crop_id)
    weight_values <- as.numeric(min(class_counts) / class_counts)
    params <- c(params, list(weight = weight_values[training_d$crop_id]))
  }

  if (nrounds == "cv") {
    cv <- xgb.cv(
      params = params, data = dg, nrounds = 10000, nfold = 10,
      early_stopping_rounds = 10, prediction = TRUE, maximize = FALSE
    )
    nrounds <- cv$best_iteration
    saveRDS(cv, glue("{output_dir}/{id}_cv.rds"))
  }


  m <- do.call(xgboost, c(data = dg, nrounds = nrounds, params))
  xgb.save(m, glue("{output_dir}/{id}.xgb"))
  saveRDS(m, glue("{output_dir}/{id}.rds"))

  results <- list(model = m)
  if (!is.na(test_d)) {
    predictions <- make_predictions(m, test_d, glue("{output_dir}/{id}"))
    results <- c(results, list(predictions = predictions))
  }
  results
}
