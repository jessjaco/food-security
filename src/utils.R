library(tidyverse)
library(glue)

make_predictions <- function(m, test_df, output_file_stem) {
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
  tar(paste0(output_file_stem, ".tar.gz"), basename(json_file), compression = "gzip", tar = paste0("tar -C ", dirname(output_file_stem)))
}

add_NDVI <- function(d) {
  d %>%
    distinct() %>%
    select(fid, ends_with("mean")) %>%
    pivot_longer(ends_with("mean"), names_to = c("time", ".value"), names_pattern = "^s2_([^_]+)_(.+)$") %>%
    mutate(NDVI = 1000 * (B08_mean - B04_mean) / (B08_mean + B04_mean)) %>%
    select(-ends_with("mean")) %>%
    pivot_wider(names_from = "time", values_from = "NDVI", names_glue = "{.value}_{time}") %>%
    full_join(d)
}

run_run <- function(training_d, test_d, params, id, nrounds = "cv", seed = 1337,
                    output_dir = "data/submissions", weight = FALSE) {
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
      early_stopping_rounds = 10, prediction = TRUE
    )
    nrounds <- cv$best_iteration
    saveRDS(cv, glue("{output_dir}/{id}_cv.rds"))
  }


  m <- do.call(xgboost, c(data = dg, nrounds = nrounds, params))
  xgb.save(m, glue("{output_dir}/{id}.xgb"))

  make_predictions(m, test_d, glue("{output_dir}/{id}"))
  return(m)
}
