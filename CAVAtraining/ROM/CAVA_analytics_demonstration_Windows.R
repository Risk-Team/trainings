## CAVA Analytics demonstration script - Windows

# This R script provides a demonstration of CAVA Analytics capabilities. 
# It is intended for use by Windows users who are unable to run CAVA Analytics in VS Code using a Conda environment.

#---------------------------------------------------------------------------------#
# 1. Load packages

library(CAVAanalytics)
library(ggplot2)

if (!requireNamespace("patchwork", quietly = TRUE)) {
  install.packages("patchwork")
}
library(patchwork)

if (!requireNamespace("qs2", quietly = TRUE)) {
  install.packages("qs2")
}
library(qs2)

packageVersion("CAVAanalytics")

getwd()

#---------------------------------------------------------------------------------#
## 2. Load data
# `load_data()` selects Mauritius, resolves the remote files, streams the required grid cells and harmonizes units and time.
# "Mauritius_climate_ET0_tasmax.qs2" refers to a dataset downloaded during the training. Data must now be loaded separately.

cache_file <- file.path("Mauritius_climate_ET0_tasmax.qs2")

if (file.exists(cache_file)) {
  mauritius_tasmax <- qs_read(cache_file)
} else {
  # This takes about 10 minutes
  mauritius_tasmax <- load_data(
    path.to.data = "CORDEX-CORE-BC",
    path.to.obs = "ERA5",
    country = "Mauritius",
    variable = "tasmax",
    years.hist = 1980:2005,
    years.obs = 1990:2024,
    years.proj = 2030:2059,
    domain = "AFR-22"
  )
  qs_save(mauritius_tasmax, cache_file)
}

#---------------------------------------------------------------------------------#
## 3. Inspect the loaded object

class(mauritius_tasmax)
names(attributes(mauritius_tasmax))
colnames(mauritius_tasmax[[1]])
mauritius_tasmax[[1]]$experiment

#---------------------------------------------------------------------------------#
## 4. Historical climate and a threshold indicator
# First map the mean observed maximum temperature. Then count the annual number of days above 35 °C by season.

obs_mean <- observations(
  mauritius_tasmax,
  season = list(1:12)
)

plotting(
  obs_mean,
  plot_titles = "Mean maximum temperature (°C)",
  palette = IPCC_palette(type = "tmp", divergent = FALSE)
)

# Plots and climate data can be saved as image files or as rasters using the following code.
# These lines must be included after each "plotting" function to save each plot.
# Note: you need to change step2 to the name of the dataset you have generated.
ggsave("obs_tasmax_mean.jpeg", dpi = 300)
extract_raster(step2 = obs_mean, file.extension = "obs_tasmax_mean.tif")

obs_hot_days <- observations(
  mauritius_tasmax,
  season = list(1:3, 4:6, 7:9, 10:12),
  uppert = 30
)

plotting(
  obs_hot_days,
  plot_titles = "Days above 30 °C",
  palette = IPCC_palette(type = "tmp", divergent = FALSE)
)

#---------------------------------------------------------------------------------#
## 6. Model biases
# Compare historical model simulations with ERA5. These data already received bias correction, so the function evaluates the remaining bias without applying another correction.

heat_bias <- model_biases(
  mauritius_tasmax,
  season = list(1:12),
  uppert = 30,
  bias.correction = FALSE
)

plotting(
  heat_bias,
  ensemble = TRUE,
  plot_titles = "Bias in days above 30 °C",
  palette = IPCC_palette(type = "tmp", divergent = TRUE)
)

#---------------------------------------------------------------------------------#
## 7. Future projections
# `projections()` can return the ensemble mean, ensemble spread, individual models and annual time series.

future_hot_days <- projections(
  mauritius_tasmax,
  season = list(1:3, 4:6, 7:9, 10:12),
  uppert = 30,
  bias.correction = FALSE
)

p_mean <- plotting(
  future_hot_days,
  ensemble = TRUE,
  plot_titles = "Projected days above 30 °C",
  palette = IPCC_palette(type = "tmp", divergent = FALSE)
)
p_mean

p_spread <- plotting(
  future_hot_days,
  ensemble = FALSE,
  plot_titles = "Projected days above 30 °C",
  palette = IPCC_palette(type = "tmp", divergent = FALSE)
)
p_spread

plotting(
  future_hot_days,
  ensemble = TRUE,
  temporal = TRUE,
  plot_titles = "Annual days above 30 °C",
  palette = c("#0072B2", "#D55E00")
)

#---------------------------------------------------------------------------------#
## 8. Consecutive-day indicators
# The same analysis functions can calculate the longest hot spell or the number of heat waves.

longest_hot_spell <- projections(
  mauritius_tasmax,
  season = list(1:12),
  uppert = 30,
  consecutive = TRUE,
  duration = "max",
  bias.correction = FALSE
)

plotting(
  longest_hot_spell,
  ensemble = TRUE,
  plot_titles = "Longest spell above 30 °C",
  palette = IPCC_palette(type = "tmp", divergent = FALSE)
)

heatwave_frequency <- projections(
  mauritius_tasmax,
  season = list(1:12),
  uppert = 30,
  consecutive = TRUE,
  duration = 3,
  frequency = TRUE,
  bias.correction = FALSE
)

plotting(
  heatwave_frequency,
  ensemble = TRUE,
  plot_titles = "Heat waves per year",
  palette = IPCC_palette(type = "tmp", divergent = FALSE)
)

#---------------------------------------------------------------------------------#
## 9. Climate change signal and model agreement
# Compare the future and historical periods. Stippling follows the package convention for insufficient agreement on the sign of change.

heat_change <- climate_change_signal(
  mauritius_tasmax,
  season = list(1:3, 4:6, 7:9, 10:12),
  uppert = 30,
  bias.correction = FALSE
)

plotting(
  heat_change,
  ensemble = TRUE,
  plot_titles = "Change in days above 30 °C",
  palette = IPCC_palette(type = "tmp", divergent = TRUE),
  point_size = 0.08
)

plotting(
  heat_change,
  ensemble = TRUE,
  temporal = TRUE,
  plot_titles = "Annual change in hot days",
  palette = c("#0072B2", "#D55E00")
)
  
#---------------------------------------------------------------------------------#
## 10. Export the analytical result
# The export writes ensemble mean and standard-deviation GeoTIFFs to `outputs/`.

extract_raster(
  heat_change,
  file.extension = "mauritius_heat_change.tif",
  ensemble = TRUE,
  path = "outputs/"
)

list.files("outputs", pattern = "\\.tif$", full.names = TRUE)

#---------------------------------------------------------------------------------#
## Optional extensions

# Repeat the workflow with `variable = "pr"` and `aggr.m = "sum"`.
# Use `percentage = TRUE` in `climate_change_signal()` for relative precipitation change.
# Use `load_data_and_projections()` or `load_data_and_climate_change_signal()` for large regions processed in spatial chunks.
# Use a custom area with `country = NULL`, `xlim` and `ylim`.

# Documentation: [CAVAanalytics introduction](https://un-fao.github.io/CAVAanalytics/articles/Introduction.html) and [advanced indicators](https://un-fao.github.io/CAVAanalytics/articles/more_advanced.html).

#---------------------------------------------------------------------------------#
## Takeaway
# CAVAanalytics connects remote climate data to country-scale indicators, ensemble interpretation, maps and GIS-ready outputs in one reproducible R workflow.