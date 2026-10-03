# Exécuter depuis la racine : Rscript pipeline.R [--offline] [--refresh] [--daily] [--results]
source('scripts/download/acquire.R')
run_started<-utc_now()
args <- commandArgs(TRUE); mode <- if ('--results' %in% args) 'results' else if ('--daily' %in% args) 'daily' else if ('--weekly' %in% args) 'weekly' else 'all'
if (!'--offline' %in% args) acquire_all(refresh = '--refresh' %in% args, mode = mode)
# Extractions financières locales; les valeurs reconnues ne sont jamais publiées automatiquement.
if(mode %in% c('all','weekly') && nzchar(Sys.which('pdftotext'))) {
 ocr<-nzchar(Sys.which('tesseract')) && nzchar(Sys.which('pdftoppm'))
 status<-system2(Sys.getenv('ELECTIONS_PYTHON','python3'),c('scripts/transform/financial_documents.py',if(ocr)'--ocr-summary'))
 if(status!=0)quality_event('financial_text','warning',NA_character_,'Extraction mécanique impossible; conserver les PDF sources.')
 if(ocr)system2(Sys.getenv('ELECTIONS_PYTHON','python3'),'scripts/transform/summary_2025.py',stdout=FALSE)
}
source('R/transform.R'); source('R/legacy2012.R'); source('R/supplemental.R'); source('R/spatial.R'); source('R/derive.R'); source('R/export.R'); source('R/calendar.R'); source('R/finance.R'); source('R/legacy_json.R'); source('R/legacy_polls.R')
if (mode != 'all') {
 # Garder les captures publiques antérieures dans les mises à jour ciblées.
 tc <- read_meta('metadata/table_catalog.csv')
 derived_tables <- c('historical_candidate_results','historical_district_results','historical_party_results','historical_turnout','turnout_history','by_elections','district_indicators','polling_candidate_links','district_map_changes_spatial','results_candidate_2026','results_party_2026')
 available <- load_manifest(); available <- available$snapshot_id[file.exists(available$raw_file)]
 for (i in seq_len(nrow(tc))) if (tc$visibility[i] == 'public' && file.exists(tc$path[i])) {
  if(tc$table[i] %in% derived_tables)next
  # Préserver les textes sources; les espaces finaux ne créent pas une seconde
  # observation après lecture d’un CSV. Les captures relues depuis leurs octets
  # remplacent seulement leur copie publiée, sans dédoublonnage arbitraire de clé.
  x <- read_csv(tc$path[i],col_types=cols(.default=col_character()),na='NA',trim_ws=FALSE,show_col_types=FALSE)
  keep <- !x$snapshot_id %in% available
  if(tc$table[i]=='elections')keep <- keep | x$data_status=='pre_election'
  x <- x[keep,]
  if(tc$table[i] %in% c('elections','results_party'))x <- filter(x,election_id!='qc-prov-2012-09-04-general')
  dd <- read_meta('metadata/data_dictionary.csv') |> filter(table == tc$table[i])
  for (v in intersect(names(x), dd$variable)) {
   ty <- dd$type[match(v, dd$variable)]
   if (ty %in% c('numeric', 'double', 'integer')) x[[v]] <- numeric_value(x[[v]])
   else if (ty == 'logical') x[[v]] <- as.logical(x[[v]])
  }
  add_table(tc$table[i], x, tc$grain[i])
 }
}
message('Étape : archives ouvertes'); transform_all(); message('Étape : JSON historiques'); transform_legacy_json_all(); flush_large_tables(); message('Étape : anciens bureaux XLS'); transform_legacy_polls_all(); message('Étape : compléments'); transform_supplemental(); transform_calendar(); transform_financial_indexes(); if (mode == 'all') {message('Étape : géographie'); transform_spatial()}; message('Étape : indicateurs et exports'); flush_large_tables(); derive_all(); flush_large_tables();
new_errors<-read_meta('metadata/quality_report.csv') |> filter(observed_at>=run_started,severity=='error')
if(nrow(new_errors))stop('Erreurs de transformation : voir metadata/quality_report.csv. Aucune nouvelle diffusion autorisée.')
export_all()
source('scripts/validate/validate.R')
validate_tables()
source('scripts/export/source_status.R')
source('scripts/export/documentation.R')
cat('Pipeline terminé. Consulter metadata/table_catalog.csv et metadata/quality_report.csv.\n')
