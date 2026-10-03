# Indicateurs descriptifs : aucun modèle, extrapolation ni recommandation.
derive_all <- function() {
 if (exists('results_candidate', TABLES)) {
  r <- get('results_candidate', TABLES)
  a <- r |> group_by(election_id, district_id, snapshot_id, data_status, source_id, observed_at, retrieved_at, source_updated_at) |>
    summarise(candidates_count = n(), parties_count = n_distinct(party_id, na.rm = TRUE),
      valid_votes_from_candidates = ifelse(anyNA(votes), NA_real_, sum(votes)),
      margin_votes = ifelse(n() >= 2 && !anyNA(votes), sort(votes, decreasing = TRUE)[1] - sort(votes, decreasing = TRUE)[2], NA_real_),
      effective_parties = ifelse(sum(votes, na.rm = TRUE) > 0 && !anyNA(votes) && !anyNA(party_id),
        1 / sum((tapply(votes, party_id, sum) / sum(votes))^2), NA_real_), .groups = 'drop')
  add_table('district_indicators', a, 'élection × circonscription × capture')
  add_table('historical_candidate_results', filter(r, election_id != 'qc-prov-2026-10-05-general'), 'élection historique × candidature')
  add_table('results_candidate_2026', filter(r, election_id == 'qc-prov-2026-10-05-general'), 'candidature 2026 × capture')
 }
 if (exists('turnout', TABLES)) {
  r <- get('turnout', TABLES)
  add_table('historical_district_results', filter(r, election_id != 'qc-prov-2026-10-05-general'), 'élection historique × circonscription')
  add_table('historical_turnout', filter(r, election_id != 'qc-prov-2026-10-05-general'), 'élection historique × circonscription')
  if (any(r$election_id == 'qc-prov-2012-09-04-general')) {
   a <- r |> filter(election_id == 'qc-prov-2012-09-04-general') |> group_by(election_id, snapshot_id, source_id, observed_at, retrieved_at, source_updated_at, data_status) |>
     summarise(election_date = '2012-09-04', election_type = 'general', electoral_level = 'provincial', map_year = '2011', code_edition = '2011',
       district_count = n(), registered = sum(registered), valid_ballots = sum(valid_ballots), rejected_ballots = sum(rejected_ballots), votes_cast = sum(votes_cast), .groups = 'drop')
   a$turnout_observed_pct <- 100 * a$votes_cast / a$registered
   add_table('elections', a, 'élection × capture')
   r <- get('results_candidate', TABLES) |> filter(election_id == 'qc-prov-2012-09-04-general')
   p <- r |> group_by(election_id, party_id, party_abbreviation, snapshot_id, source_id, observed_at, retrieved_at, source_updated_at, data_status) |>
     summarise(votes = sum(votes), candidates_count_source = n(), .groups = 'drop')
   p$vote_share_pct <- 100 * p$votes / sum(p$votes)
   add_table('results_party', p, 'élection × parti × capture')
  }
 }
 if (exists('results_party', TABLES)) {
  p <- get('results_party', TABLES)
  add_table('historical_party_results', filter(p, election_id != 'qc-prov-2026-10-05-general'), 'élection historique × parti')
  add_table('results_party_2026', filter(p, election_id == 'qc-prov-2026-10-05-general'), 'parti 2026 × capture')
 }
 if (exists('elections', TABLES)) add_table('by_elections', filter(get('elections', TABLES), election_type == 'partial'), 'événement partiel × capture')
 if(exists('polling_division_results',TABLES)) {
  p<-get('polling_division_results',TABLES)
  z<-p |> group_by(election_id,district_id,candidate_id,candidate_header_source,candidate_link_status,source_id,snapshot_id,observed_at,retrieved_at,source_updated_at,data_status) |> summarise(published_units=n(),.groups='drop')
  add_table('polling_candidate_links',z,'en-tête de candidature publié × circonscription × élection')
 }
 if (exists('district_crosswalk_2017_2026',TABLES)) {
  z<-get('district_crosswalk_2017_2026',TABLES)
  names_ref<-get('electoral_districts',TABLES) |> select(district_id,district_name) |> distinct()
  z<-z |> left_join(rename(names_ref,old_district_id=district_id,old_name_source=district_name),by='old_district_id') |>
   left_join(rename(names_ref,new_district_id=district_id,new_name_source=district_name),by='new_district_id')
  z$change_evidence<-'geometric_overlap; no official predecessor relationship inferred'
  add_table('district_map_changes_spatial',z,'ancienne × nouvelle circonscription, intersection dérivée')
 }
 if (exists('historical_turnout',TABLES)) add_table('turnout_history',get('historical_turnout',TABLES),'élection historique × circonscription')
 if (exists('candidates', TABLES) && !exists('results_candidate_2026', TABLES)) {
  c <- get('candidates', TABLES) |> filter(observed_at == max(observed_at))
  m <- context(as.list(c[1, c('source_id','snapshot_id','observed_at','retrieved_at')]), 'pre_election')
  e <- tibble(election_id = 'qc-prov-2026-10-05-general', election_date = '2026-10-05', election_type = 'general', electoral_level = 'provincial', map_year = '2026', code_edition = '2026',
    district_count = n_distinct(c$district_id), candidate_count = nrow(c), party_count = n_distinct(c$party_id, na.rm = TRUE))
  add_table('elections', cbind(e, m), 'élection × capture')
 }
}
