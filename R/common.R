# Fonctions partagées : identifiants, E/S, provenance et horodatage UTC.
suppressPackageStartupMessages({
 library(readr); library(dplyr); library(tidyr); library(purrr)
 library(jsonlite); library(httr2); library(xml2); library(rvest)
 library(digest); library(stringr); library(lubridate)
})
options(readr.show_col_types = FALSE)
utc_now <- function() format(Sys.time(), '%Y-%m-%dT%H:%M:%OS3Z', tz = 'UTC')
sha_file <- function(path) digest::digest(file = path, algo = 'sha256')
src_id <- function(url) paste0('src_', substr(digest(url, algo = 'sha256', serialize = FALSE), 1, 12))
read_meta <- function(path) if (file.exists(path)) read_csv(path, col_types = cols(.default = col_character()), na = c('', 'NA'), show_col_types = FALSE) else tibble()
write_csv_utf8 <- function(x, path) {
 dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
 x <- x |> mutate(across(where(is.character), ~ iconv(.x, from = 'UTF-8', to = 'UTF-8', sub = 'byte')))
 tmp <- paste0(path, '.tmp')
 if (grepl('[.]gz$', path)) { conn <- gzfile(tmp, 'wb'); readr::write_csv(x, conn, na = 'NA'); close(conn) } else readr::write_csv(x, tmp, na = 'NA')
 if (!file.rename(tmp, path)) stop('Échec écriture atomique : ', path)
}
append_csv <- function(x, path) write_csv_utf8(bind_rows(read_meta(path), mutate(x, across(everything(), as.character))), path)
scalar <- function(x, key, default = NA_character_) { v <- x[[key]]; if (is.null(v) || length(v) != 1L) default else v }
numeric_value <- function(x) suppressWarnings(as.numeric(as.character(x)))
source_time <- function(x) {
 if (is.na(x) || !nzchar(x)) return(NA_character_)
 v <- suppressWarnings(lubridate::parse_date_time(str_replace_all(x, ',', '.'),
   orders = c('ymd HMSz', 'ymd HMS', 'b d Y IMS p'), tz = 'America/Toronto', quiet = TRUE))
 if (is.na(v)) NA_character_ else format(v, '%Y-%m-%dT%H:%M:%OS3Z', tz = 'UTC')
}
map_info <- function(eid) {
 date <- str_extract(eid, '\\d{4}-\\d{2}-\\d{2}')
 if (date >= '2026-10-05') c(map_year = '2026', code_edition = '2026')
 else if (date >= '2022-01-01') c(map_year = '2017', code_edition = '2022')
 else if (date >= '2018-10-01') c(map_year = '2017', code_edition = '2017')
 else if(date >= '2012-01-01') c(map_year='2011',code_edition='2011')
 else {
  # Historique officiel d’utilisation des cartes; avant 1948, carte non attribuée.
  dates<-c('2003-01-01','1994-01-01','1989-01-01','1985-01-01','1981-01-01','1973-01-01','1966-01-01','1960-01-01','1956-01-01','1948-01-01')
  maps<-c('2001','1992','1988','1985','1980','1972','1965','1960','1954','1945')
  k<-which(date>=dates)[1]
  c(map_year=if(is.na(k))NA_character_ else maps[k],code_edition=paste0('historical-',substr(date,1,4)))
 }
}
district_key <- function(code, map_year, code_edition) paste('qc-prov', map_year, code_edition, code, sep = '-')
party_key <- function(eid, code) ifelse(is.na(code), NA_character_, paste(eid, 'party', code, sep = '-'))
candidate_key <- function(eid, did, code) paste(eid, did, 'candidate', code, sep = '-')
quality_event <- function(check, severity, source_id, detail, table = NA_character_) {
 append_csv(tibble(observed_at = utc_now(), check = check, severity = severity,
   source_id = source_id, table = table, detail = detail), 'metadata/quality_report.csv')
}
read_source_csv <- function(path) {
 # Certains CSV annoncés UTF-8 sont en réalité Windows-1252.
 b <- readBin(path, 'raw', n = file.info(path)$size); s <- rawToChar(b)
 encoding <- if (validUTF8(s)) 'UTF-8' else 'windows-1252'
 read_delim(path, delim = ';', locale = locale(encoding = encoding), col_types = cols(.default = col_character()), trim_ws = TRUE, na = c('', 'NA'), name_repair = 'unique', show_col_types = FALSE)
}
load_catalog <- function() read_meta('metadata/source_catalog.csv')
load_manifest <- function() read_meta('metadata/acquisition_manifest.csv')
latest_manifest <- function() load_manifest() |> group_by(source_id) |> slice_tail(n = 1) |> ungroup()
`%||%` <- function(x, y) if (is.null(x)) y else x
