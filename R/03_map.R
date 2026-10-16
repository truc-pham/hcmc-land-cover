# 03_map.R
# Land cover map of Ho Chi Minh City (2021 data, July 2025 boundary, mainland only)

library(terra)
library(sf)
library(ggplot2)
library(ggspatial)

# 1. Data: land cover, boundary and class areas from the earlier steps ----------
lc   <- rast("data/raw/hcmc_worldcover_2021.tif")
hcmc <- st_transform(st_read("data/hcmc_boundary.gpkg", quiet = TRUE), crs(lc))
lc_city <- mask(crop(lc, vect(hcmc)), vect(hcmc))   # keep only pixels inside the city
coltab(lc_city) <- NULL                             # drop Earth Engine's colour table
area <- read.csv("outputs/hcmc_land_cover_by_class.csv")

# 2. Pixels for drawing: 50 m (most common class in each 5 x 5 block) ----------
#    Drawing only; the area table above uses the full 10 m data
lc_map <- aggregate(lc_city, fact = 5, fun = "modal", na.rm = TRUE)
lc_df  <- as.data.frame(lc_map, xy = TRUE, na.rm = TRUE)
names(lc_df)[3] <- "value"

# 3. Legend: official WorldCover colours, sorted by share -----------------------
lc_legend <- data.frame(
  value  = c(10, 20, 30, 40, 50, 60, 80, 90, 95),
  class  = c("Tree cover", "Shrubland", "Grassland", "Cropland", "Built-up",
             "Bare / sparse vegetation", "Permanent water bodies",
             "Herbaceous wetland", "Mangroves"),
  colour = c("#006400", "#ffbb22", "#ffff4c", "#f096ff", "#fa0000",
             "#b4b4b4", "#0064c8", "#0096a0", "#00cf75")
)
lc_legend <- merge(lc_legend, area[, c("value", "share_pct")], by = "value")
lc_legend <- lc_legend[order(-lc_legend$share_pct), ]
lc_legend$label <- paste0(lc_legend$class, " (", lc_legend$share_pct, "%)")

lc_df$class <- factor(lc_legend$class[match(lc_df$value, lc_legend$value)],
                      levels = lc_legend$class)

# 4. Map: pixels, boundary, legend, scale bar, north arrow, lat/long grid --------
p <- ggplot() +
  geom_raster(data = lc_df, aes(x = x, y = y, fill = class)) +
  geom_sf(data = hcmc, fill = NA, colour = "grey20", linewidth = 0.4) +
  scale_fill_manual(values = setNames(lc_legend$colour, lc_legend$class),
                    labels = lc_legend$label,
                    name   = "Land cover\n(share of city area)") +
  annotation_scale(location = "bl", width_hint = 0.25, text_cex = 0.8) +
  annotation_north_arrow(location = "tr", which_north = "true",
                         height = unit(1.2, "cm"), width = unit(1.2, "cm"),
                         style = north_arrow_fancy_orienteering) +
  coord_sf(crs = 32648, datum = 4326, expand = FALSE) +   # UTM map, degree grid
  labs(title    = "Land cover of Ho Chi Minh City, 2021",
       subtitle = "City boundary as of July 2025 (mainland; Con Dao special zone not shown)",
       caption  = paste0("Data: ESA WorldCover 10 m 2021 v200 (Zanaga et al., 2022), CC BY 4.0; ",
                         "boundaries: GADM 4.1.\nMap: Truc Pham, 2026"),
       x = NULL, y = NULL) +
  theme_bw(base_size = 11) +
  theme(panel.grid.major = element_line(colour = "grey70", linewidth = 0.2,
                                        linetype = "dashed"),
        legend.key.size  = unit(0.5, "cm"),
        plot.title       = element_text(face = "bold", size = 15),
        plot.caption     = element_text(colour = "grey40", hjust = 0, size = 8))

# 5. Save a print-quality image ---------------------------------------------------
ggsave("outputs/hcmc_land_cover_map.png", p, width = 10, height = 8, dpi = 300, bg = "white")