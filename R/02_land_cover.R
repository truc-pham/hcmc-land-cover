library(terra)
library(sf)

lc <- rast("data/raw/hcmc_worldcover_2021.tif")
lc

hcmc <- st_read("data/hcmc_boundary.gpkg")
hcmc <- st_transform(hcmc, crs(lc))

lc_city <- crop(lc, vect(hcmc))
lc_city <- mask(lc_city, vect(hcmc))

plot(lc_city)