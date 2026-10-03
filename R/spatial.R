# Géométries originales, export GeoPackage et intersections descriptives.
suppressPackageStartupMessages(library(sf))
GEOMETRIES <- list()
transform_geometry <- function(s, m) {
 edition <- str_extract(s$url, '(2017|2022|2026)'); year <- ifelse(edition == '2022', '2017', edition)
 if (grepl('[.]zip$', s$url)) {
  folder <- file.path('data/interim/geography', m$sha256); dir.create(folder, recursive = TRUE, showWarnings = FALSE)
  status <- system2('python3', c('scripts/download/unpack_geometry.py', shQuote(m$raw_file), shQuote(folder)))
  if (status != 0) stop('Extraction géographique impossible')
  path <- list.files(folder, pattern = '^layer_[0-9]+[.]shp$', full.names = TRUE)[1]
 } else path <- m$raw_file
 x <- st_read(path, quiet = TRUE)
 code <- names(x)[names(x) %in% c('CO_CEP', 'CO_CEP_2017', 'CO_CEP_2022', 'CODE_CEP', 'CODE')][1]
 name <- names(x)[names(x) %in% c('NM_CEP', 'NOM_CEP', 'NOM')][1]
 if (is.na(code) || is.na(name)) stop('Schéma géospatial inattendu : ', paste(names(x), collapse = ', '))
 x$district_id <- district_key(x[[code]], year, edition)
 x$map_year <- year; x$code_edition <- edition; x$source_id <- m$source_id
 x$snapshot_id <- m$snapshot_id; x$observed_at <- m$observed_at; x$retrieved_at <- m$retrieved_at
 x$data_status <- 'official_boundary'; x$source_updated_at <- NA_character_
 valid <- st_is_valid(x); if (any(!valid)) quality_event('geometry_validity', 'warning', s$source_id, paste(sum(!valid), 'géométries invalides dans original'))
 # Les attributs sources restent présents dans le GeoPackage original.
 gpkg <- paste0('data/processed/geography/districts_', edition, '.gpkg')
 dir.create(dirname(gpkg), recursive = TRUE, showWarnings = FALSE)
 if (file.exists(gpkg)) unlink(gpkg)
 st_write(x, gpkg, quiet = TRUE)
 y <- st_transform(st_make_valid(x), 6933)
 z <- tibble(district_id = x$district_id, map_year = year, code_edition = edition,
   district_name = as.character(x[[name]]), geometry_valid_source = valid,
   supplied_geometry_area_km2 = as.numeric(st_area(y)) / 1e6,
   source_geometry_product = basename(s$url))
 add_table('electoral_district_geometries', attach_context(z, m, 'official_boundary'), 'circonscription × produit géométrique officiel')
 # Généralisation dérivée; aucune utilisation pour la correspondance spatiale.
 simple <- st_simplify(y, dTolerance = 150, preserveTopology = TRUE) |> st_transform(4326)
 gj <- paste0('data/processed/geography/districts_', edition, '_simplified.geojson')
 if (file.exists(gj)) unlink(gj)
 st_write(simple, gj, driver = 'GeoJSON', quiet = TRUE)
 GEOMETRIES[[edition]] <<- x
}
transform_spatial <- function() {
 s <- load_catalog(); m <- latest_manifest()
 rows <- s |> filter(grepl('circonscriptions_electorales.*shapefile[.]zip$', url) | grepl('circonscriptions_electorales_sans_eau_2026.json$', url)) |> inner_join(m, by = 'source_id', suffix = c('', '_manifest'))
 # Le Shapefile intégral est préféré au produit sans eau pour les intersections.
 if (any(grepl('2026_shapefile', rows$url))) rows <- rows |> filter(!grepl('sans_eau', url))
 for (i in seq_len(nrow(rows))) tryCatch({
  r <- rows[i, ]; transform_geometry(r, r)
 }, error = function(e) quality_event('geometry', 'error', rows$source_id[i], conditionMessage(e)))
 if (all(c('2022', '2026') %in% names(GEOMETRIES))) {
  a <- st_transform(st_make_valid(GEOMETRIES[['2022']]), 6933)
  b <- st_transform(st_make_valid(GEOMETRIES[['2026']]), 6933)
  area_a <- as.numeric(st_area(a)); area_b <- as.numeric(st_area(b))
  a$old_district_id <- a$district_id; b$new_district_id <- b$district_id
  a$old_area_km2 <- area_a / 1e6; b$new_area_km2 <- area_b / 1e6
  z <- suppressWarnings(st_intersection(a[c('old_district_id','old_area_km2')], b[c('new_district_id','new_area_km2')]))
  z$intersection_area_km2 <- as.numeric(st_area(z)) / 1e6
  z <- st_drop_geometry(z) |> filter(intersection_area_km2 > 1e-6) |>
    mutate(old_area_fraction = intersection_area_km2 / old_area_km2, new_area_fraction = intersection_area_km2 / new_area_km2,
      method = 'official_geometry_intersection_EPSG6933', population_fraction = NA_real_, data_status = 'derived',
      source_id = paste(unique(a$source_id), unique(b$source_id), sep = ';'),
      snapshot_id = paste(unique(a$snapshot_id), unique(b$snapshot_id), sep = ';'),
      observed_at = max(c(a$observed_at, b$observed_at)), retrieved_at = max(c(a$retrieved_at, b$retrieved_at)), source_updated_at = NA_character_)
  add_table('district_crosswalk_2017_2026', z, 'circonscription ancienne × nouvelle intersection dérivée')
 }
}
