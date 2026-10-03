source('R/common.R')
acquire <- function(s, refresh = FALSE) {
 # Les URL de simulation et de production sont identiques : attendre l’ouverture officielle.
 if (s$group == 'current' && grepl('/resultats/resultats[.](json|xml|csv)$',s$url) && Sys.time() < as.POSIXct('2026-10-05 20:00:00',tz='America/Toronto')) return(invisible(NULL))
 old <- load_manifest(); if (nrow(old)) old <- filter(old, source_id == s$source_id)
 if (!refresh && nrow(old) && file.exists(tail(old$raw_file, 1))) return(invisible(tail(old$raw_file, 1)))
 if (s$format == 'HTML' && s$group %in% c('donors', 'complementary')) return(invisible(NULL))
 at <- utc_now(); status <- NA_integer_; temp <- tempfile(); on.exit(unlink(temp), add = TRUE)
 message('Acquisition : ', s$source_id, ' ', basename(s$url))
 tryCatch({
  resp <- tryCatch(request(s$url) |> req_user_agent('DonneesBleues-ElectionsQC/0.1 (+https://github.com/AurelienNicosiaULaval/donnees-bleues-elections-qc)') |> req_timeout(120) |> req_retry(max_tries = 3, max_seconds = 250) |> req_error(is_error = function(resp) FALSE) |> req_perform(path = temp), error = function(e) {
    out <- system2(Sys.getenv('ELECTIONS_PYTHON', 'python3'), c(shQuote('scripts/download/fetch.py'), shQuote(s$url), shQuote(temp)), stdout = TRUE)
    if (!is.null(attr(out, 'status'))) stop(conditionMessage(e))
    structure(fromJSON(paste(out, collapse = '\n')), class = 'python_response')
  })
  status <- if (inherits(resp, 'python_response')) resp$status else resp_status(resp); if (status != 200L) stop('HTTP ', status)
  if (!file.info(temp)$size) stop('Réponse vide')
  first <- if (s$format %in% c('JSON', 'CSV', 'HTML', 'XML')) iconv(rawToChar(readBin(temp, 'raw', n = 100L)), from='UTF-8', to='UTF-8', sub='byte') else ''
  if (s$format != 'HTML' && grepl('^\\s*<(html|!DOCTYPE)', first, ignore.case = TRUE)) stop('Contenu HTML inattendu')
  hash <- sha_file(temp); path <- file.path('data/raw', s$source_id, paste0(hash, '.', tolower(s$format)))
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE); if (!file.exists(path)) file.copy(temp, path)
  snap <- paste0(s$source_id, '_', gsub('[^0-9]', '', at), '_', substr(hash, 1, 12))
  rec <- tibble(source_id = s$source_id, snapshot_id = snap, observed_at = at, retrieved_at = utc_now(), source_updated_at = NA_character_, http_last_modified = if (inherits(resp, 'python_response')) resp$last_modified %||% NA_character_ else resp_header(resp, 'last-modified') %||% NA_character_, etag = if (inherits(resp, 'python_response')) resp$etag %||% NA_character_ else resp_header(resp, 'etag') %||% NA_character_, sha256 = hash, bytes = file.info(path)$size, raw_file = path, url = s$url)
  append_csv(rec, 'metadata/acquisition_manifest.csv')
  append_csv(tibble(source_id = s$source_id, retrieved_at = rec$retrieved_at, http_status = status, outcome = 'success', detail = hash), 'metadata/download_log.csv')
  if (s$group == 'current' && grepl('/resultats/resultats.json$', s$url)) {
   target <- file.path('data/snapshots/results_2026', paste0(gsub('[^0-9]', '', at), '_', substr(hash, 1, 12), '.json'))
   dir.create(dirname(target), recursive = TRUE, showWarnings = FALSE)
   if (!file.exists(target)) file.copy(path, target)
   rec$raw_file <- target; append_csv(rec, 'data/snapshots/results_2026/index.csv')
  }
  invisible(path)
 }, error = function(e) {
  append_csv(tibble(source_id = s$source_id, retrieved_at = utc_now(), http_status = status, outcome = 'unavailable', detail = conditionMessage(e)), 'metadata/download_log.csv')
  quality_event('acquisition', 'warning', s$source_id, conditionMessage(e)); invisible(NULL)
 })
}
acquire_all <- function(refresh = FALSE, mode = 'all') {
 s <- load_catalog(); selected <- s$download_default == 'true'
 daily <- selected & (s$group %in% c('turnout', 'candidate_stats') | grepl('candidatures.json|pp_autorises.json|electeur_inscrit.csv|/resultats/resultats.json', s$url))
 if (mode == 'daily') selected <- daily
 if (mode == 'weekly') {
  new_documents <- selected & !s$source_id %in% load_manifest()$source_id & s$group %in% c('finance','expenses','pre_election') & s$format=='PDF'
  new_archives <- selected & !s$source_id %in% load_manifest()$source_id & s$group=='archives' & s$format %in% c('JSON','ZIP')
  selected <- daily | new_documents | new_archives | s$group %in% c('allocations','allocations_json','limits','contributions','pre_election','finance_bilan')
 }
 # Une fois la finalité explicitement annoncée, seules les demandes manuelles
 # ciblées peuvent reprendre le flux de dépouillement; les autres sources continuent.
 idx <- read_meta('data/snapshots/results_2026/index.csv')
 if(mode %in% c('daily','weekly') && nrow(idx)) {
  last <- idx[order(idx$observed_at,decreasing=TRUE)[1],]
  if(file.exists(last$raw_file)) {
   j<-fromJSON(last$raw_file,simplifyVector=FALSE)
   if(isTRUE(j$statistiques$isResultatsFinaux))selected <- selected & !grepl('/resultats/resultats.json$',s$url)
  }
 }
 if (mode == 'results') selected <- s$group == 'current' & grepl('/resultats/resultats.json$', s$url)
 for (i in which(selected)) { acquire(s[i, ], refresh); Sys.sleep(0.75) }
}
if (sys.nframe() == 0L) {
 args <- commandArgs(TRUE); acquire_all('--refresh' %in% args, if ('--results' %in% args) 'results' else if ('--daily' %in% args) 'daily' else 'all')
}
