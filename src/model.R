source("src/utils.R")

prep_d <- function(d) {
  d %>%
    select(fid, crop_name, crop_id, contains("q50")) %>%
    select(-contains("angle"))
}

d <- prep_d(read_csv("data/training_data.csv"))
test_d <- prep_d(read_csv("data/test_data.csv"))

model_id <- "6"

params <- list(
  max_depth = 5, min_child_weight = 3, gamma = 0,
  subsample = 0.6, colsample_bytree = 0.6, eta = 0.1, nthread = 7,
  objective = "multi:softprob",
  num_class = length(unique(d$crop_id)),
  eval_metric = "mlogloss",
  weight = TRUE
)

results <- run_run(d, params, model_id, test_d)
