# 01_boundary.R
# Boundary of Ho Chi Minh City as of July 2025 (former Ho Chi Minh City,
# Binh Duong and Ba Ria - Vung Tau). Mainland only: Con Dao special zone
# (~76 km2, 16 islands) is excluded.

library(geodata)
library(sf)
library(stringi)

# Province boundaries of Vietnam (GADM 4.1, before the July 2025 merger)
vnm <- st_as_sf(gadm("VNM", level = 1, path = "data/raw"))
vnm$province <- stri_trans_general(vnm$NAME_1, "Latin-ASCII")

# The three former provinces that form the new city
hcmc_parts <- vnm[grepl("Ho Chi Minh|Binh Duong|Vung Tau", vnm$province), ]
stopifnot(nrow(hcmc_parts) == 3)

hcmc <- st_as_sf(st_union(hcmc_parts))

# Checks: area ~6,709 km2 (mainland)
st_area(st_transform(hcmc, 32648)) / 1e6
plot(st_geometry(hcmc))

st_write(hcmc, "data/hcmc_boundary.gpkg", delete_dsn = TRUE)
