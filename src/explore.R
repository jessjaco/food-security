library(tidyverse)
d <- read_csv("data/s2_training_data.csv") 

d %>% select(crop_name, ends_with('rvi_q75')) %>% pivot_longer(ends_with('rvi_q75'), names_to=c('time', '.value'), names_pattern='^s1_([^_]+)_(.+)$') %>% group_by(crop_name, time) %>% summarise(rvi_q75 = mean(rvi_q75)) %>% mutate(date=as.Date(paste0(time, "-2017"), format = "%j-%Y")) %>% ggplot(aes(x=date, y=rvi_q75, colour=crop_name)) + geom_line()

