# NYC Borough Vehicle Collisions
#
# Plots the number of annual vehicle collisions in the boroughs of New York City. Supports
# parameters to be passed as extras via the Dagster Pipes context.
#
# Sourced from https://catalog.data.gov/dataset/motor-vehicle-collisions-crashes
#
# USAGE
#
#     $ r -f analyses/nyc-vehicle-collisions.R
#
# PREREQUISITES
#
#     install.packages("zlib")
#     install.packages("tidyverse", repos = "http://cran.us.r-project.org")
#

library(R6)
library(base64enc)
library(jsonlite)
library(tidyverse)
library(zlib)

####################################################################################################
#                                          Dagster Pipes                                           #
####################################################################################################


DAGSTER_PIPES_CONTEXT_ENV_VAR <- "DAGSTER_PIPES_CONTEXT"
DAGSTER_PIPES_MESSAGES_ENV_VAR <- "DAGSTER_PIPES_MESSAGES"

# translation of
# https://github.com/dagster-io/dagster/blob/258d9ca0db/python_modules/dagster-pipes/dagster_pipes/__init__.py#L354-L367
decode_env_var <- function(encoded_value) {
    compressed_data <- base64decode(encoded_value)
    decompressed_data <- rawToChar(decompress(compressed_data))
    parsed_value <- fromJSON(decompressed_data)

    return(parsed_value)
}

# partial translation of
# https://github.com/dagster-io/dagster/blob/258d9ca0db/python_modules/dagster-pipes/dagster_pipes/__init__.py#L604
load_context <- function(params) {
    FILE_PATH_KEY <- "path"
    DIRECT_KEY <- "data"

    if (FILE_PATH_KEY %in% names(params)) {
        return(read_json(params$path))
    } else if (DIRECT_KEY %in% names(params)) {
        return(params$data)
    }
    stop(sprintf(
        'Invalid params, expected key "%s" or "%s", received %s',
        params$FILE_PATH_KEY,
        params$DIRECT_KEY,
        toString(params)
    ))
}

# partial translation of
# https://github.com/dagster-io/dagster/blob/258d9ca0db/python_modules/dagster-pipes/dagster_pipes/__init__.py#L798-L838
open_dagster_pipes <- function() {
    context_env_var <- Sys.getenv(DAGSTER_PIPES_CONTEXT_ENV_VAR)
    context_params <- decode_env_var(context_env_var)

    msg_env_var <- Sys.getenv(DAGSTER_PIPES_MESSAGES_ENV_VAR)
    messages_params <- decode_env_var(msg_env_var)

    return(list(
        context_params = context_params,
        messages_params = messages_params
    ))
}

# NOTE: we are not currently passing protocol information as R does not support underscore prefixes
# in variable names.
#
# PIPES_PROTOCOL_VERSION_FIELD <- "__dagster_pipes_version"
# PIPES_PROTOCOL_VERSION <- "0.1"

PipesLogger <- R6Class("PipesLogger",
    public = list(
        temporary_file_path = NULL,
        initialize = function(params) {
            self$temporary_file_path <- params$messages_params$path
            print(self$temporary_file_path)
        },
        open = function() {
            private$write_message(self$temporary_file_path, private$make_message("opened", list()))
        },
        close = function() {
            private$write_message(self$temporary_file_path, private$make_message("closed", list()))
        },
        info = function(message) {
            private$write_message(self$temporary_file_path, private$make_message("log", list(message = message, level = "INFO")))
        }
    ),
    private = list(
        # translation of
        # https://github.com/dagster-io/dagster/blob/258d9ca0db7fcc16d167e55fee35b3cf3f125b2e/python_modules/dagster-pipes/dagster_pipes/__init__.py#L60
        make_message = function(method, params) {
            return(toJSON(
                list(
                    method = method,
                    params = params
                ),
                auto_unbox = TRUE
            ))
        },
        # translation of
        # https://github.com/dagster-io/dagster/blob/258d9ca0db7fcc16d167e55fee35b3cf3f125b2e/python_modules/dagster-pipes/dagster_pipes/__init__.py#L931
        write_message = function(file, message) {
            msg <- message
            cat(msg, file = file, append = TRUE, sep = "\n")
        }
    )
)

params <- open_dagster_pipes()

context <- load_context(params$context_params)

logger <- PipesLogger$new(params)

logger$open()

####################################################################################################
#                                             Pipeline                                             #
####################################################################################################


vehicle_collisions_url <- ifelse(
    exists("context$extras$vehicle_collisions_url"),
    context$extras$vehicle_collisions_url,
    "https://data.cityofnewyork.us/api/views/h9gi-nx95/rows.csv"
)

vehicle_collisions_cache_path <- ifelse(
    exists("context$extras$vehicle_collisions_cache_path"),
    context$extras$vehicle_collisions_cache_path,
    "data/nyc-collisions.csv"
)

plot_output_path <- ifelse(
    exists("context$extras$plot_output_path"),
    context$extras$plot_output_path,
    "nyc-vehicle-collisions-by-borough.png"
)

logger$info(sprintf("vehicle collision source data url: %s", vehicle_collisions_url))
logger$info(sprintf("vehicle collision cached data path: %s", vehicle_collisions_cache_path))

if (file.exists(vehicle_collisions_cache_path)) {
    df <- read_csv(vehicle_collisions_cache_path)
} else {
    df <- read_csv(vehicle_collisions_url)
    dir.create("data", showWarnings = FALSE, recursive = TRUE)
    write.csv(df, file = VEHICLE_COLLISIONS_CACHE_PATH, row.names = TRUE)
}

colnames(df) <- gsub(" ", "_", colnames(df))

df_collision_counts <- df %>%
    filter(!is.na(BOROUGH)) %>%
    mutate(CRASH_YEAR = format(strptime(CRASH_DATE, "%m/%d/%Y"), "%Y")) %>%
    group_by(BOROUGH, CRASH_YEAR) %>%
    count(name = "CRASH_COUNT")

g <- ggplot(df_collision_counts, aes(x = CRASH_YEAR, y = CRASH_COUNT, group = BOROUGH)) +
    ggtitle("NYC Vehicle Collisions by Borough") +
    xlab("Year") +
    ylab("Number of Collisions") +
    geom_line() +
    facet_wrap(~BOROUGH, ncol = 1) +
    stat_smooth(method = "lm", fullrange = TRUE, color = "purple", linetype = "dashed", size = 0.4)

logger$info(sprintf("saving plot to: %s", plot_output_path))
ggsave(plot_output_path, plot = g, dpi = 600)

# Don't forget to close the logger; in the future we may want to see if R supports context
# managers...
logger$close()
