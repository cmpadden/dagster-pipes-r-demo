# NYC Borough Vehicle Collisions
#
# USAGE
#
#     $ r -f analyses/nyc-vehicle-collisions.R
#

install.packages("tidyverse", repos = "http://cran.us.r-project.org")

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

df_collision_counts <- df %>%
  filter(!is.na(BOROUGH)) %>%
  mutate(CRASH_YEAR = format(strptime(CRASH_DATE, "%m/%d/%Y"), "%Y")) %>%
  group_by(BOROUGH, CRASH_YEAR) %>%
  count(name = "CRASH_COUNT")

g <- ggplot(df_collision_counts, aes(x=CRASH_YEAR, y=CRASH_COUNT, group=BOROUGH)) +
  ggtitle("NYC Vehicle Collisions by Borough") +
  xlab("Year") +
  ylab("Number of Collisions") +
  geom_line() +
  facet_wrap(~BOROUGH, ncol = 1)  +
  stat_smooth(method="lm", fullrange=TRUE, color='purple', linetype='dashed', size=0.4)

ggsave('nyc-vehicle-collisions-by-borough.png', plot=g, dpi=600)
