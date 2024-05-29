install.packages("tidyverse")

library(tidyverse)

# https://catalog.data.gov/dataset/motor-vehicle-collisions-crashes

VEHICLE_COLLISIONS_URL <- "https://data.cityofnewyork.us/api/views/h9gi-nx95/rows.csv"
VEHICLE_COLLISIONS_CACHE_PATH <- "data/nyc-collisions.csv"


if (file.exists(VEHICLE_COLLISIONS_CACHE_PATH)) {
  df <- read_csv(VEHICLE_COLLISIONS_CACHE_PATH)
} else {
  df <- read_csv(VEHICLE_COLLISIONS_URL)
  dir.create("data", showWarnings = FALSE, recursive = TRUE)
  write.csv(df, file = VEHICLE_COLLISIONS_CACHE_PATH, row.names = TRUE)
}


colnames(df) <- gsub(" ", "_", colnames(df))

df %>%
  filter(!is.na(BOROUGH)) %>%
  mutate(CRASH_YEAR = format(strptime(CRASH_DATE, "%m/%d/%Y"), "%Y")) %>%
  group_by(BOROUGH, CRASH_YEAR) %>%
  count(name = "CRASH_COUNT")




# time of day

# filter where borough is not NA
#

# cache data to file so that subsequent runs aren't pulled from data.gov
