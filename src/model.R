source("src/utils.R")

prep_d <- function(d) {
  d %>%
    select(fid, crop_name, crop_id, starts_with("pt") & contains("q50")) %>%
    # select(-contains("angle")) %>%
    #    pivot_longer(starts_with("pt"), names_to = c("time", "var", ".value"),
    #    names_pattern = "^pt_([^_]+)_([^_]+)_(.*)$") %>%
    pivot_longer(starts_with("pt"),
      names_to = c("time", ".value", "var"),
      names_pattern = "^pt_([^_]+_[^_]+)_([^.]+)\\.(.*)$",
    ) %>%
    group_by(fid, var) %>%
    mutate(q50 = scale(q50)[, 1]) %>%
    ungroup() %>%
    pivot_wider(names_from = c("time", "var"), names_prefix = "v", values_from = "q50")
}

d <- prep_d(read_csv("data/training_data_2.csv")[-2544, ])
test_d <- prep_d(read_csv("data/test_data_2.csv"))
# d <- prep_d(read_csv("data/training_data_cross.csv"))
# test_d <- prep_d(read_csv("data/test_data_cross.csv"))

# 18 -> only q50
# 19 -> take out angle
# 20 mcw = 3, subsamples = 0.6 final testloss .608
# 21 mcw = 4 .605
# 22 gamma = 0.00001, .6044
# 23 merror, .196
# 24 mcw 5, .190
# 25 cce_xgb (identical to merror)
# 26
model_id <- "30"

params <- list(
  max_depth = 5, min_child_weight = 3, gamma = 0,
  subsample = 0.6, colsample_bytree = 0.6, eta = 0.1, nthread = 7,
  objective = "multi:softprob",
  num_class = length(unique(d$crop_id)),
  eval_metric = "mlogloss",
  weight = TRUE
)

results <- run_run(d, params, model_id, test_d)

# training_predictions <- make_predictions(results$model, d)
# read_sf("data/training_labels.geojson") %>%
#  left_join(training_predictions) %>%
#  write_sf(glue("data/submissions/{model_id}_training_predictions.geojson"))
