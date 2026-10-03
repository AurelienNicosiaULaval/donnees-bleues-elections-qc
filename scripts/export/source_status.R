# États distincts : source identifiée, récupérée, utilisée, publiée et validée.
source('R/common.R')
s <- load_catalog(); m <- latest_manifest(); t <- read_meta('metadata/table_catalog.csv')
log <- read_meta('metadata/download_log.csv')
status <- lapply(seq_len(nrow(s)),function(i) {
 r<-s[i,];used<-t[vapply(strsplit(t$source,';',fixed=TRUE),function(ids)r$source_id %in% ids,logical(1)),]
 captures<-m |> filter(source_id==r$source_id);attempts<-log |> filter(source_id==r$source_id)
 tibble(source_id=r$source_id,identified=TRUE,retrieved=nrow(captures)>0,
  latest_retrieved_at=if(nrow(captures))captures$retrieved_at[1] else NA_character_,
  latest_attempt_outcome=if(nrow(attempts))tail(attempts$outcome,1) else 'not_attempted',
  normalized_tables=paste(used$table,collapse=';'),public_tables=paste(used$table[used$visibility=='public'],collapse=';'),
  publication_policy=r$derived_publication,interpretation_status=if(nrow(used))'see_table_status_and_dictionary' else 'not_normalized')
})
write_csv_utf8(bind_rows(status),'metadata/source_status.csv')
if(mode=='all') {
q<-read_meta('metadata/quality_report.csv') |> filter(severity=='error')
resolved<-lapply(split(q,paste(q$check,q$source_id)),function(x) {
 id<-x$source_id[1];check<-x$check[1]
 used<-any(vapply(strsplit(t$source,';',fixed=TRUE),function(ids)id %in% ids,logical(1)))
 known<-check %in% c('legacy_elections:ballots','legacy_historical_district_results:ballots')
 tibble(check=check,source_id=id,first_observed_at=min(x$observed_at),last_error_at=max(x$observed_at),
  status=if(known)'official_source_issue_preserved' else if(used)'corrected_parser_current_build_succeeded' else 'open_not_used',
  resolution=if(known)'Valeurs officielles conservées; exception limitée à la table, unité et empreinte dans known_source_issues.csv.' else if(used)'Source relue dans la reconstruction complète réussie; contrôler le rapport actuel et la provenance pour les tables concernées.' else 'Aucune table actuelle issue de cette source ne prouve la résolution; poursuivre la vérification.',
  historical_error_details=paste(unique(x$detail),collapse=' | '))
})
write_csv_utf8(bind_rows(resolved),'metadata/quality_resolutions.csv')
}
