source("src/utils.R")

d <- read_csv("data/training_data.csv")
set.seed(1337)
split_d <- split_train_set(d, 0.6)

pars <- list(
  max_depth = seq(3, 10, 2),
  min_child_weight = seq(1, 6, 2),
  gamma = 0,
  subsample = 0.8,
  colsample_bytree = 0.8,
  eta = 0.1,
  nthread = 7,
  objective = "multi:softprob",
  num_class = length(unique(d$crop_id)),
  eval_metric = "merror"
)

params <- cross_df(pars)
n_runs <- nrow(params)
test_values <- data.frame(id = numeric(n_runs), loss = numeric(n_runs), test_loss = numeric(n_runs))

for (i in 1:nrow(params)) {
  results <- do.call(run_run, list(training_d = split_d$train_d, params = as.list(params[i, ]), id = i))
  pred_mat <- make_predictions(results$model, split_d$validation_d) %>%
    select(contains("crop_prob")) %>%
    as.matrix()
  test_loss <- cce(split_d$validation_d$crop_id, pred_mat)
  print(paste(i, test_loss))
  test_values[i, "id"] <- i
  test_values[i, "loss"] <- tail(results$model$evaluation_log[[2]], n = 1)
  test_values[i, "test_loss"] <- test_loss
}

# pred_matrix = pred %>% select(contains('crop_prob'))  %>% as.matrix
# mlogloss(split_d$validation_d$crop_id, pred_matrix)


# training_predictions <- make_predictions(results$model, d)
# read_sf("data/training_labels.geojson") %>%
#  left_join(training_predictions) %>%
#  write_sf(glue("data/submissions/{model_id}_training_predictions.geojson"))
