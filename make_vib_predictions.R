#! /usr/bin/Rscript

if("argparser" %in% rownames(installed.packages()) == FALSE) {install.packages("argparser")}
if("randomForest" %in% rownames(installed.packages()) == FALSE) {install.packages("randomForest")}
if("terra" %in% rownames(installed.packages()) == FALSE) {install.packages("terra")}
if("lubridate" %in% rownames(installed.packages()) == FALSE) {install.packages("lubridate")}
if("dplyr" %in% rownames(installed.packages()) == FALSE) {install.packages("dplyr")}
if("ggplot2" %in% rownames(installed.packages()) == FALSE) {install.packages("ggplot2")}
if("colorspace" %in% rownames(installed.packages()) == FALSE) {install.packages("colorspace")}
if("rnaturalearth" %in% rownames(installed.packages()) == FALSE) {install.packages("rnaturalearth")}
if("rnaturalearthdata" %in% rownames(installed.packages()) == FALSE) {install.packages("rnaturalearthdata")}
if("sf" %in% rownames(installed.packages()) == FALSE) {install.packages("sf")}

library(argparser)
library(randomForest)
library(terra)
library(dplyr)
library(lubridate)
library(ggplot2)
library(colorspace)
library(rnaturalearth)
library(rnaturalearthdata)
library(sf)

print("Finished loading libraries.")

# parse command line arguments
parser <- arg_parser("Make random forest Vp predictions for the GoSL")
parser <- add_argument(parser, "--raster_dir", help = "Input CMEMS raster directory")
parser <- add_argument(parser, "--model_dir", help = "Directory containing RF model objects")
parser <- add_argument(parser, "--out_dir", help = "Output directory for predicted raster")
parsed_args <- parse_args(parser)

print("Successfully parsed command line arguments.")

# load world shapefiles
world <- ne_countries(scale = "medium", returnclass = "sf") %>% st_transform(crs = st_crs(4326))

# load random forest models
rfmodel_list <- list()
for (days_offset in 1:7) {
  print(paste("Loading RF model", days_offset))
  rfmodel_list[[days_offset]] <- readRDS(sprintf("%s/rfmodel_off%d.rds", parsed_args$model_dir, days_offset))
}

print("Successfully retrieved models from file.")

# get current date
current_date <- format(Sys.Date(), "%Y-%m-%d")

# get yesterday's date
yesterday_date <- as.Date(current_date) - 1

# set prediction dates for 7 days out from yesterday's date
# (i.e. predict_date_1 would be today, 1 day out from yesterday)
predict_date_list <- list()
for (days_offset in 1:7) {
  print(paste("Offsetting datetime string by", days_offset))
  predict_date_list[[days_offset]] <- yesterday_date + days_offset
}
# predict_date_list[[1]] is equal to current_date, but for consistency
# predict_date_list[[2]] is tomorrow
# predict_date_list[[3]] is day after tomorrow
# predict_date_list[[4]] etc...

print("Successfully offset datetime strings.")

# load rasters
temperature_raster <- rast(sprintf("%s/temperature_%s.nc", parsed_args$raster_dir, yesterday_date)) %>%
  project("EPSG:4326") # %>% 
  # terra::aggregate(fact = 3, fun = mean)
salinity_raster <- rast(sprintf("%s/salinity_%s.nc", parsed_args$raster_dir, yesterday_date)) %>% 
  project("EPSG:4326") # %>% 
  # terra::aggregate(fact = 3, fun = mean)

print("Successfully loaded environmental rasters from file.")

raster_stack <- c(temperature_raster, salinity_raster) # stack rasters on top of each other
df_stack <- as.data.frame(raster_stack, xy = TRUE) # turn into data frame
df_out <- df_stack # make a copy of the data frame from the stacked rasters
df_out[,c(1:2)] <- NULL # remove first two columns (these are the x,y data which the random forest model does not need)
# rename columns to sst and sal so that the model will recognize them
colnames(df_out)[1] <- "sst"
colnames(df_out)[2] <- "sal"

print("Stacked and broke apart rasters.")

# predict for all 7 models out
make_vp_predictions <- function (rf_model) {
  vp_prediction <- predict(rf_model, newdata = df_out, type = "prob")
  return(vp_prediction)
}
predicted_vp_probabilities_raw_list <- lapply(rfmodel_list, make_vp_predictions)

print("Predicted Vp outbreak probabilities.")

# create a data frame with the predicted TRUE probability (in column 2) along with x,y data to make a raster
create_prediction_df <- function (vp_probabilities_raw) {
  out_probability_df <- data.frame(x = df_stack$x, y = df_stack$y, predprob = vp_probabilities_raw[,2])
  return(out_probability_df)
}
out_raster_df_list <- lapply(predicted_vp_probabilities_raw_list, create_prediction_df)

print("Prepared predicted data for conversion to raster.")

# make a raster from the data frame
# this is not straightforward because it has to go to png format for web display
# i have found the easiest way is to use ggplot and turn everything off, basically

plot_predicted_vp_raster <- function (probability_df) {
  out_probability_raster <- ggplot(probability_df) +
    geom_raster(aes(x = x, y = y, fill = predprob)) +
    scale_fill_continuous_sequential(
      palette = "Reds 3",
      limits = c(0, 1),
      aesthetics = "fill",
      labels = scales::label_percent()
    ) +
    geom_sf(data = world,
            colour = "azure4",
            fill = "#EBEDD1") +
    coord_sf(
      xlim = c(-69.91667, -55.16667),
      ylim = c(42.16667, 50.91667),
      expand = FALSE,
      datum = st_crs(4326)
    ) +
    scale_x_continuous(expand = c(0, 0)) +
    scale_y_continuous(expand = c(0, 0)) +
    theme(
      aspect.ratio = 2 / 3,
      panel.background = element_rect(fill = "transparent", colour = NA),
      plot.background = element_rect(fill = "transparent", colour = NA),
      panel.grid = element_blank(),
      panel.border = element_blank(),
      plot.margin = margin(0, 0, 0, 0, "null"),
      panel.spacing = unit(0, "null"),
      axis.ticks = element_blank(),
      axis.text = element_blank(),
      axis.title = element_blank(),
      axis.line = element_blank(),
      axis.ticks.length = unit(0, "null"),
      legend.position = c(0.9, 0.25),
      legend.title = element_blank(),
      legend.box.background = element_rect(colour = "black")
    )
  return(out_probability_raster)
}
out_probability_raster_list <- lapply(out_raster_df_list, plot_predicted_vp_raster)

print("Created raster plots in ggplot2.")

# make filepaths for each of the output rasters
make_output_filepaths <- function (predicted_date) {
  out_filepath <- sprintf("%s/predprob_gen%s_for%s.png", parsed_args$out_dir, current_date, predicted_date)
}
output_filepaths_list <- lapply(predict_date_list, make_output_filepaths)

# save each of the output rasters
save_output_vp_rasters <- function (output_filepath, output_raster) {
  ggsave(output_filepath, plot = output_raster, width = 1500, height = 1000, units = "px")
}
mapply(save_output_vp_rasters, output_filepaths_list, out_probability_raster_list)

print("Successfully created output rasters.")
