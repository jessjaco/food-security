library(magrittr)
library(tidyverse)


cross_summarize <- function(d) {
  bands <- c("B01", "B02", "B03", "B04", "B05", "B06", "B07", "B08", "B8A", "B09", "B11", "B12")
  stats <- c("mean", "stdev", "q00", "q25", "q50", "q75", "q100")
  for (band in bands) {
    for (stat in stats) {
      stat_end <- glue("{band}_{stat}")
      var_name <- glue("mean_{stat_end}")
      sd_var_name <- glue("sd_{stat_end}")
      min_var_name <- glue("min_{stat_end}")
      max_var_name <- glue("max_{stat_end}")
      d %<>%
        rowwise %>%
        mutate(
          {{ var_name }} := mean(c_across(ends_with(stat_end)), na.rm = TRUE),
          {{ sd_var_name }} := sd(c_across(ends_with(stat_end)), na.rm = TRUE),
          {{ min_var_name }} := min(c_across(ends_with(stat_end)), na.rm = TRUE),
          {{ max_var_name }} := max(c_across(ends_with(stat_end)), na.rm = TRUE)
        )
    }
  }
  d
}

read_csv("data/s2_training_data.csv") %>%
  cross_summarize() %>%
  select(-starts_with("s2")) %>%
  write_csv("data/s2_training_data_summary.csv")

read_csv("data/s2_test_data.csv") %>%
  cross_summarize() %>%
  select(-starts_with("s2")) %>%
  write_csv("data/s2_test_data_summary.csv")
