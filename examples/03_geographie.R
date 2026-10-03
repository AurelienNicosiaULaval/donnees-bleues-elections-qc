library(sf)
library(readr)
library(dplyr)
library(ggplot2)
source('R/read_tables.R')
map <- st_read('data/processed/geography/districts_2026.gpkg',quiet=TRUE)
crosswalk <- read_electoral_table('district_crosswalk_2017_2026')
summary <- crosswalk |>
 group_by(new_district_id) |>
 summarise(old_territories=n_distinct(old_district_id),.groups='drop')
map <- map |> left_join(summary,by=c('district_id'='new_district_id'))
print(ggplot(map) + geom_sf(aes(fill=old_territories),linewidth=.1) +
 scale_fill_viridis_c(name='Anciens territoires\navec intersection') + theme_void())
# Une fraction de superficie n’est pas une fraction de population ou de votes.
