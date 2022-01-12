library(keras)
library(tidyverse)
source("src/utils.R")

get_label <- function(d) to_categorical(d$crop_id - 1)
get_feature <- function(d) {
  select(d, -fid, -crop_name, -crop_id) %>%
    mutate(across(everything(), ~ replace_na(scale(.), 0))) %>%
    as.matrix()
}

d <- read_csv("data/training_data.csv")
label <- get_label(d)
feature <- get_feature(d)

split_d <- split_train_set(d, 0.8)
train_label <- get_label(split_d$train_d)
validation_label <- get_label(split_d$validation_d)

train_feature <- get_feature(split_d$train_d)
validation_feature <- get_feature(split_d$validation_d)

m <- keras_model_sequential() %>%
  layer_dense(units = 64, activation = "selu", input_shape = c(ncol(train_feature))) %>%
  layer_dense(units = 64, activation = "selu") %>%
  layer_dense(units = 5, activation = "softmax")

m %>% compile(
  optimizer = "rmsprop",
  loss = "categorical_crossentropy",
  metrics = c("accuracy")
)

fit(m, train_feature, train_label, epochs = 30, batch_size = 128, validation_data = list(validation_feature, validation_label))

test_d <- read_csv("data/test_data.csv")

make_predictions(m, test_d, scale = TRUE, output_file_stem = "data/submissions/mlp2")
