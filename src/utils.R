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
  tar(paste0(output_file_stem, ".tar.gz"), json_file, compression = "gzip", tar = "tar")
}
