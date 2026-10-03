# Métadonnées générées pour chaque colonne et chaque source réellement utilisée.
FIELD_DESCRIPTIONS <- c(
 election_id='Identifiant contextualisé : Québec, provincial, date et type.', district_id='Carte, édition des codes et code de circonscription; ne pas joindre par nom.',
 candidate_id='Identifiant de candidature contextualisé; ne désigne pas une personne entre élections.', party_id='Identifiant administratif de groupe politique dans une élection.',
 party_registry_id='Identifiant de parti dans le REPAQ; distinct des anciens codes de résultats.',
 snapshot_id='Identifiant unique de la consultation et des octets sources.', source_id='Identifiant SHA-256 de l’URL dans le catalogue maître.',
 observed_at='Instant UTC où la source a été consultée; ne désigne pas la date de l’événement.', retrieved_at='Fin de la récupération, en UTC.',
 source_updated_at='Horodatage annoncé par le producteur, converti en UTC; manquant si absent.',
 row_source_updated_at='Date de mise à jour de la candidature annoncée dans la source.',
 data_status='État fourni par la source ou type explicite de transformation; finalité jamais inférée d’un pourcentage de dépouillement.',
 registered='Nombre d’électrices et électeurs inscrits selon le périmètre de ce fichier.',
 registered_at_decree='Inscrits au décret; exclut détention et vote hors Québec selon le producteur.',
 registered_after_revision='Inscrits après révision ordinaire; même exclusion.', registered_after_special_revision='Inscrits après révision spéciale; même exclusion.',
 votes='Bulletins attribués à cette candidature ou ce groupe dans le périmètre indiqué.', valid_ballots='Nombre de bulletins valides publié.',
 rejected_ballots='Nombre de bulletins rejetés publié.', votes_cast='Bulletins valides et rejetés; valeur source si disponible.',
 turnout_source_pct='Pourcentage de participation publié pour la circonscription.', turnout_observed_pct='Rapport des votes actuellement comptés aux inscrits; pendant le dépouillement, ce n’est pas la participation finale.',
 turnout_preliminary_pct='Taux préliminaire de dénombrement publié avant le dépouillement; aucun nombre de votants n’est reconstruit.',
 vote_share_source_pct='Pourcentage des votes tel que publié, avec ses arrondis.', vote_share_pct='Part des bulletins valides obtenue, recalculée.',
 polls_counted='Nombre de bureaux dont les résultats sont renseignés.', polls_total='Nombre total de bureaux annoncé.',
 lead_votes_source='Avance publiée pour le premier; zéro pour les autres selon la source.', rank_descriptive='Rang calculé sur les votes comptés; ex aequo au rang minimal, sans projection.',
 elected_source='Indication d’élection seulement si un champ officiel explicite existe; sinon manquant.',
 districts_leading_source='Nombre de circonscriptions en avance fourni par le producteur; avant finalité ne constitue pas un nombre d’élus.',
 seats_final_from_source='Nombre de circonscriptions en avance dans le fichier explicitement final; dérivation du champ source.',
 margin_votes='Différence de votes entre les deux premiers; manquant si moins de deux candidatures ou vote manquant.',
 effective_parties='Inverse de la somme des carrés des parts par groupe politique source; indépendants regroupés si le producteur les regroupe.',
 polling_division_source='Libellé de section/bureau/regroupement original; ne garantit pas une unité géographique unique.',
 polling_unit_id='Identifiant de ligne d’unité publiée dans un fichier et une élection; les numéros se répètent entre modalités.',
 candidate_header_source='En-tête original nom, prénom et appartenance politique dans le fichier de bureaux.',
 candidate_link_status='Appariement exact dans une même élection, circonscription et appartenance; aucun rapprochement de personnes entre années.',
 grouping_source='Regroupement d’urnes tel que publié, conservé sans désagrégation.', sector_source='Secteur tel que publié; aucune géométrie attribuée automatiquement.',
 source_field='Nom original de champ; toutes les valeurs scalaires utiles sont conservées.', source_value='Valeur originale sérialisée en texte; les types normalisés sont dans les tables spécialisées.',
 source_variable='Intitulé de colonne original du tableau officiel.', source_row='Numéro de ligne à l’intérieur du tableau extrait.', source_table_number='Numéro du tableau dans la page HTML source.',
 variable_code_source='Code original de variable dans le classeur démographique.', variable_label_source='Libellé original de la variable démographique.',
 value_source='Valeur originale, y compris les symboles de suppression; ne pas les remplacer par zéro.', value_numeric='Conversion numérique quand elle est possible, sinon manquant.',
 supplied_geometry_area_km2='Superficie de la géométrie fournie, calculée en projection équivalente EPSG:6933.',
 intersection_area_km2='Superficie d’intersection des deux produits géométriques officiels en EPSG:6933.',
 old_area_fraction='Part de la géométrie ancienne comprise dans l’intersection.', new_area_fraction='Part de la géométrie nouvelle comprise dans l’intersection.',
 population_fraction='Non estimée : aucune réallocation territoriale de population n’est effectuée.',
 contributions_count='Somme du nombre de versements annoncé pour les lignes personne-entité annuelles; aucune personne distincte inférée.', contributor_entity_records='Nombre de lignes annuelles personne-entité dans la source. Les mêmes personnes peuvent figurer dans plusieurs groupes.',
 total_amount='Somme des montants; manquant si un montant du groupe est manquant.', median_amount='Médiane des totaux annuels personne-entité; ne décrit pas les versements individuels.',
 q25_amount='Premier quartile des totaux annuels personne-entité, type 7.', q75_amount='Troisième quartile des totaux annuels personne-entité, type 7.',
 missing_amount_count='Nombre de contributions dont le montant n’a pas pu être lu.'
)
FORMULAS <- c(turnout_observed_pct='100 * votes_cast / registered, si registered > 0',
 vote_share_pct='100 * votes / valid_ballots, si valid_ballots > 0', rejected_ballots_pct='100 * rejected_ballots / votes_cast',
 margin_votes='max(votes) - second_max(votes)', effective_parties='1 / sum((votes_par_groupe / sum(votes))^2)',
 old_area_fraction='intersection_area_km2 / old_area_km2', new_area_fraction='intersection_area_km2 / new_area_km2',
 rank_descriptive='rank(-votes, ties.method = min)', seats_final_from_source='districts_leading_source si data_status == final',
 total_amount='sum(amount) si aucune valeur manquante', median_amount='median(amount)', q25_amount='quantile(amount, .25, type=7)', q75_amount='quantile(amount, .75, type=7)')
FIELD_DESCRIPTIONS <- as.list(FIELD_DESCRIPTIONS)
FORMULAS <- as.list(FORMULAS)
source('R/field_metadata.R')
export_all <- function() {
 previous_tables<-read_meta('metadata/table_catalog.csv'); previous_dictionary<-read_meta('metadata/data_dictionary.csv'); previous_provenance<-read_meta('metadata/provenance.csv')
 catalog <- load_catalog(); manifest <- load_manifest(); dictionaries <- list(); tables <- list(); provenance <- list()
 for (name in sort(ls(TABLES))) {
  x <- get(name, TABLES) |> distinct(); assign(name, x, TABLES)
  public <- isTRUE(VISIBILITY[[name]]); path <- paste0('data/processed/', if (public) '' else 'local_only/', name, if (nrow(x) >= 100000) '.csv.gz' else '.csv')
  write_csv_utf8(x, path)
  tables[[name]] <- tibble(table = name, grain = GRAINS[[name]], rows = nrow(x), columns = ncol(x), format = ifelse(grepl('[.]gz$', path), 'CSV UTF-8 gzip', 'CSV UTF-8'),
    period = if ('election_id' %in% names(x)) paste(sort(unique(x$election_id)), collapse = ';') else 'voir source',
    source = paste(sort(unique(x$source_id)), collapse = ';'), update = 'à chaque acquisition réussie', visibility = ifelse(public, 'public', 'local_only'), status = 'produced', path = path)
  ids <- unique(unlist(strsplit(x$source_id, ';', fixed = TRUE)))
  responsible <- if(grepl('^legacy_polling',name))'R/legacy_polls.R' else if(grepl('^legacy_(historical|elections)',name))'R/legacy_json.R' else if(grepl('^party_(finance|balance|cashflow|public_funding)|^financial_|^election_expense_limits$|^district_map_changes$',name))'R/finance.R; scripts/transform/financial_documents.py; scripts/transform/summary_2025.py' else if(name=='election_calendar_2026')'R/calendar.R' else if(grepl('demographics|contributions|source_tables|candidate_statistics|turnout_history_source',name))'R/supplemental.R' else if(grepl('geometries|crosswalk|map_changes_spatial',name))'R/spatial.R; R/derive.R' else 'R/transform.R; R/legacy2012.R; R/derive.R'
  for (v in names(x)) {
   desc <- FIELD_DESCRIPTIONS[[v]] %||% paste('Champ', v, '; interprétation et périmètre dans la source citée et le modèle relationnel.')
   derived <- v %in% names(FORMULAS) || grepl('_id$|observed_at|retrieved_at', v)
   dictionaries[[paste(name, v)]] <- tibble(table = name, variable = v, label_fr = gsub('_', ' ', v), description_fr = desc,
    type = class(x[[v]])[1], unit = if (grepl('_pct$', v)) 'pourcentage 0-100' else if (grepl('_fraction$', v)) 'proportion 0-1' else if (grepl('_km2$', v)) 'km2' else if (grepl('(_cad|amount)$', v)) 'CAD nominaux' else 'selon description',
    allowed_values = if (v == 'data_status') paste(sort(unique(x[[v]])), collapse = ';') else NA_character_,
    missing_definition = 'NA : absent, non diffusé, non applicable ou conversion impossible; jamais imputé. Consulter source et quality_report.',
    source = paste(ids, collapse = ';'), derived = derived, derivation = FORMULAS[[v]] %||% ifelse(derived, 'voir R/common.R et script de transformation', NA_character_),
    notes = ifelse(public, 'Droits : consulter DATA_LICENSES.md.', 'Transformation locale; autorisation d’adaptation non confirmée.'))
   for (id in ids) {
    s <- filter(catalog, source_id == id); ms <- filter(manifest, source_id == id)
    provenance[[paste(name, v, id)]] <- tibble(table = name, variable = v, organisme = s$organisme[1], source = id,
      url = s$url[1], download_date = paste(unique(ms$retrieved_at), collapse = ';'), format = s$format[1],
      raw_file = paste(unique(ms$raw_file), collapse = ';'), transformation = desc,
      responsible_script = paste0('pipeline.R; ',responsible),
      licence = s$licence[1], formula = FORMULAS[[v]] %||% NA_character_, source_variables = SOURCE_VARIABLES[[v]] %||% ifelse(derived, 'voir formule et script responsable', v),
      assumptions = 'Périmètre officiel conservé. Aucun rapprochement de personnes ni imputation. Aucun vote individuel inféré.', notes = NA_character_)
   }
  }
 }
 missing_tables<-setdiff(previous_tables$table,ls(TABLES))
 prior<-filter(previous_tables,table %in% missing_tables,visibility=='local_only',exists('mode') && mode!='all') |> mutate(status='produced_in_previous_local_build')
 write_csv_utf8(bind_rows(bind_rows(dictionaries) |> mutate(across(everything(),as.character)),filter(previous_dictionary,table %in% prior$table)), 'metadata/data_dictionary.csv')
 write_csv_utf8(bind_rows(bind_rows(tables) |> mutate(across(everything(),as.character)),prior), 'metadata/table_catalog.csv')
 write_csv_utf8(bind_rows(bind_rows(provenance),filter(previous_provenance,table %in% prior$table)), 'metadata/provenance.csv')
 # Copies pédagogiques contenant toutes les colonnes propres, sans fabrication de fichiers vides 2026.
 aliases <- c(candidates='qc2026_candidates', electoral_districts='qc2026_districts', registered_electors='qc2026_registered_electors',
  historical_candidate_results='qc_elections_history', historical_turnout='qc_turnout_history', results_candidate_2026='qc2026_results', results_party_2026='qc2026_party_results', district_crosswalk_2017_2026='qc_electoral_map_crosswalk')
 for (n in names(aliases)) if (exists(n, TABLES)) {
  x <- get(n, TABLES); if (n == 'electoral_districts') x <- filter(x, code_edition == '2026')
  write_csv_utf8(x, file.path('data/processed/teaching', paste0(aliases[[n]], '.csv')))
 }
 invisible(bind_rows(tables))
}
