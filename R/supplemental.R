suppressPackageStartupMessages(library(readxl))
transform_demographics <- function(s, m) {
 sheets <- excel_sheets(m$raw_file); sheet <- sheets[grepl('127 CEP', sheets)][1]
 if (is.na(sheet)) stop('Feuille démographique introuvable')
 x <- suppressMessages(read_excel(m$raw_file, sheet = sheet, col_names = FALSE, col_types = 'text'))
 # Deux lignes forment les noms; aucun code de territoire n'est inventé.
 territory <- str_squish(paste(ifelse(is.na(x[1, ]), '', x[1, ]), ifelse(is.na(x[2, ]), '', x[2, ])))
 refs <- get('electoral_districts', TABLES) |> filter(code_edition == '2026')
 code <- as.character(x[[1]]); label <- as.character(x[[2]])
 keep <- !is.na(code) & !is.na(label) & grepl('^TAB', code)
 for (k in 3:ncol(x)) {
  match <- which(normalize_header(refs$district_name) == normalize_header(territory[k]))
  did <- if (territory[k] == 'Province') 'qc-prov-province' else if (length(match) == 1) refs$district_id[match] else NA_character_
  if (is.na(did)) quality_event('demographic_territory', 'warning', s$source_id, territory[k])
  raw <- x[[k]][keep]
  z <- tibble(district_id = did, district_name_source = territory[k], census_year = 2021L, map_year = '2026',
    variable_code_source = code[keep], variable_label_source = label[keep], value_source = raw,
    value_numeric = numeric_value(raw), unit = ifelse(grepl('pourcentage', label[keep], ignore.case = TRUE), 'proportion_source_0_1', 'selon_libellé_source'),
    workbook_sheet = sheet)
  add_table('district_demographics', attach_context(z, m, 'official_census_compilation'), 'territoire × variable du Recensement 2021', FALSE)
 }
}
transform_html_tables <- function(s, m) {
 tabs <- read_html(m$raw_file) |> html_elements('main table, article table') |> html_table(convert = FALSE)
 if (!length(tabs)) tabs <- read_html(m$raw_file) |> html_elements('table') |> html_table(convert = FALSE)
 for (i in seq_along(tabs)) {
  x <- as_tibble(tabs[[i]], .name_repair = 'unique') |> mutate(across(everything(), as.character))
  if (!nrow(x)) next
  x$source_row <- seq_len(nrow(x)); x <- x |> pivot_longer(-source_row, names_to = 'source_variable', values_to = 'value_source')
  x$source_table_number <- i; x$source_title <- s$titre
  name <- if (s$group == 'candidate_stats') 'candidate_statistics' else if (s$group == 'turnout_history') 'turnout_history_source' else if (s$group == 'general_history') 'legacy_election_source_tables' else if (s$group == 'assnat') 'assnat_historical_source_tables' else 'finance_source_tables'
  add_table(name, attach_context(x, m), 'tableau officiel × ligne × colonne source', FALSE)
 }
}
transform_contributions <- function(s, m) {
 x <- read_delim(m$raw_file, delim = ';', skip = 2, locale = locale(encoding = 'windows-1252'), col_types = cols(.default = col_character()), show_col_types = FALSE)
 # Les noms des colonnes sont documentés sans exposer une valeur personnelle.
 write_csv_utf8(tibble(variable = names(x)), 'metadata/contribution_source_schema.csv')
 amount <- 'Montant total'
 party <- 'Entité politique'
 date <- "Date de l'événement"
 city <- 'Municipalité'
 if (!all(c(amount, party, date, city, 'Année financière') %in% names(x))) stop('Schéma contributions inattendu; sélectionner les champs explicitement')
 # La source est un total annuel par personne et entité, pas un journal de versements.
 z <- tibble(entity_type_source=x[["Type d'entité politique"]], entity_name_source=x[[party]],
   event_date_source=x[[date]], year=numeric_value(x[['Année financière']]),
   amount=parse_number(x[[amount]], locale=locale(decimal_mark=',', grouping_mark=' ')),
   installments=numeric_value(x[['Nombre de versements des donateurs']]), city_source=x[[city]])
 for (g in c('year', 'city_source')) {
  groupcols <- c('entity_type_source','entity_name_source','event_date_source','year', if (g=='city_source') 'city_source')
  a <- z |> group_by(across(all_of(groupcols))) |> summarise(contributor_entity_records=n(),
    contributions_count=ifelse(anyNA(installments), NA_real_, sum(installments)), missing_amount_count=sum(is.na(amount)),
    total_amount=ifelse(anyNA(amount), NA_real_, sum(amount)), median_amount=ifelse(anyNA(amount), NA_real_, median(amount)),
    q25_amount=ifelse(anyNA(amount), NA_real_, quantile(amount,.25,type=7)), q75_amount=ifelse(anyNA(amount), NA_real_, quantile(amount,.75,type=7)), .groups='drop')
  if (g=='city_source') a <- filter(a, contributor_entity_records>=5)
  a$aggregation <- g; a$amount_distribution_grain <- 'annual_person_entity_total_in_source'
  add_table(paste0('political_contributions_',ifelse(g=='city_source','city','aggregated')),attach_context(a,m,'aggregated'),paste('type et entité × événement × année',ifelse(g=='city_source','× ville','')),FALSE)
 }
 quality_event('contribution_grain','info',s$source_id,'Totaux annuels par personne et entité. Date de l’événement = campagne à la direction, pas date du versement. Aucune agrégation mensuelle construite.')
}
transform_supplemental <- function() {
 s <- load_catalog(); m <- latest_manifest()
 for (i in seq_len(nrow(m))) {
  r <- s |> filter(source_id == m$source_id[i]); if (!nrow(r) || !file.exists(m$raw_file[i])) next
  tryCatch({
   if (r$format == 'XLS' && r$group == 'map') transform_demographics(r, m[i, ])
   else if (r$group == 'contributions') transform_contributions(r, m[i, ])
   else if (r$format == 'HTML' && r$group %in% c('candidate_stats','turnout_history','general_history','assnat','limits')) transform_html_tables(r, m[i, ])
  }, error = function(e) quality_event('supplemental', 'error', r$source_id, conditionMessage(e)))
 }
}
