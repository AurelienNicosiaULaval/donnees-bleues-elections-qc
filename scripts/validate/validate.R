# Contrôles sur les observations, sans modification des valeurs officielles.
validate_tables <- function() {
 failures <- character(); checks <- list()
 check <- function(name, ok, detail, severity = 'error', table = NA_character_) {
  passed <- isTRUE(ok); checks[[length(checks) + 1]] <<- tibble(observed_at = utc_now(), check = name,
    severity = ifelse(passed, 'pass', severity), source_id = NA_character_, table = table, detail = detail)
  if (!passed && severity == 'error') failures <<- c(failures, paste(name, detail))
 }
 pkeys <- list(elections = c('election_id','snapshot_id'), candidates = c('candidate_id','snapshot_id'),
  candidates_2012 = c('candidate_id','snapshot_id'), electoral_districts = c('district_id','snapshot_id'),
  results_candidate = c('election_id','district_id','candidate_id','snapshot_id'), results_party = c('election_id','party_id','snapshot_id'),
  turnout = c('election_id','district_id','snapshot_id'), registered_electors = c('election_id','district_id','snapshot_id'),
  polling_division_results = c('polling_unit_id','candidate_id','snapshot_id'), polling_units = c('polling_unit_id','snapshot_id'))
 for (n in ls(TABLES)) {
  x <- get(n, TABLES)
  check(paste0(n, ':timestamp'), all(!is.na(x$retrieved_at) & !is.na(x$observed_at) & !is.na(x$snapshot_id)), 'horodatage et capture présents', table = n)
  sourceids <- unique(unlist(strsplit(x$source_id, ';', fixed = TRUE)))
  check(paste0(n, ':provenance'), all(sourceids %in% load_catalog()$source_id), 'chaque source appartient au catalogue', table = n)
  if (n %in% names(pkeys)) check(paste0(n, ':key'), !anyDuplicated(x[pkeys[[n]]]), paste(pkeys[[n]], collapse = ' × '), table = n)
  for (v in intersect(c('registered','valid_ballots','rejected_ballots','votes_cast','votes','polls_counted','polls_total'), names(x))) {
   a <- x[[v]]; check(paste0(n, ':', v), all(is.na(a) | a >= 0 & a == floor(a)), 'comptage entier non négatif', table = n)
  }
  if(all(c('valid_ballots','rejected_ballots','votes_cast') %in% names(x))) {
   bad<-x |> filter(!is.na(votes_cast),!is.na(valid_ballots),!is.na(rejected_ballots),votes_cast!=valid_ballots+rejected_ballots)
   known<-read_meta('metadata/known_source_issues.csv') |> filter(table==n,check=='ballots')
   manifest<-load_manifest()
   accepted<-logical(nrow(bad))
   for(k in seq_len(nrow(bad))) {
    did<-if('district_id' %in% names(bad))bad$district_id[k]else NA_character_
    row<-known |> filter(election_id==bad$election_id[k],source_id==bad$source_id[k],(is.na(district_id)&is.na(did))|district_id==did)
    hash<-manifest$sha256[match(bad$snapshot_id[k],manifest$snapshot_id)]
    accepted[k]<-nrow(row)==1 && !is.na(hash) && identical(hash,row$raw_sha256)
   }
   check(paste0(n,':ballots'),nrow(bad)==0,paste(nrow(bad),'non-concordances; valides + rejetés = exprimés quand applicable'),severity=if(all(accepted))'warning' else 'error',table=n)
   if(nrow(bad))write_csv_utf8(bad,paste0('data/interim/quality/',n,'_ballot_discrepancies.csv'))
  }
  if (all(c('turnout_observed_pct','registered','votes_cast') %in% names(x))) check(paste0(n, ':turnout'), all(is.na(x$turnout_observed_pct) | abs(x$turnout_observed_pct - 100*x$votes_cast/x$registered) < 1e-6), 'taux recalculé cohérent', table = n)
 }
 if (all(c('turnout','results_candidate') %in% ls(TABLES))) {
  r <- get('results_candidate', TABLES) |> group_by(election_id,district_id,snapshot_id) |> summarise(sum_votes = ifelse(anyNA(votes), NA_real_, sum(votes)), .groups = 'drop')
  d <- get('turnout', TABLES) |> filter(data_status == 'final') |> left_join(r, by = c('election_id','district_id','snapshot_id'))
  check('candidate_vote_totals', all(is.na(d$sum_votes) | d$sum_votes == d$valid_ballots), 'sommes des candidats = bulletins valides finaux', table = 'results_candidate')
 }
 if (all(c('polling_division_results','polling_units') %in% ls(TABLES))) {
  p <- get('polling_division_results', TABLES) |> group_by(polling_unit_id,snapshot_id) |> summarise(sum_votes = ifelse(anyNA(votes), NA_real_, sum(votes)), .groups = 'drop')
  u <- get('polling_units', TABLES) |> left_join(p, by = c('polling_unit_id','snapshot_id'))
  bad <- u |> filter(!is.na(sum_votes), sum_votes != valid_ballots)
  check('polling_vote_totals', nrow(bad) == 0, paste(nrow(bad), 'unités dont les votes ne concordent pas'), table = 'polling_units')
  if (nrow(bad)) write_csv_utf8(bad, 'metadata/polling_inconsistencies.csv')
  pr <- get('polling_division_results', TABLES)
  check('polling_links', all(pr$candidate_link_status == 'exact_name_party_district_election'), paste(sum(pr$candidate_link_status == 'unmatched_source_header'), 'appariements laissés non résolus'), 'warning', 'polling_division_results')
 }
 if(all(c('legacy_polling_units','legacy_polling_division_results') %in% ls(TABLES))) {
  p<-get('legacy_polling_division_results',TABLES) |> group_by(polling_unit_id,snapshot_id) |> summarise(sum_votes=ifelse(anyNA(votes),NA_real_,sum(votes)),.groups='drop')
  u<-left_join(get('legacy_polling_units',TABLES),p,by=c('polling_unit_id','snapshot_id'))
  bad<-filter(u,!is.na(sum_votes),sum_votes!=valid_ballots)
  check('legacy_polling_vote_totals',nrow(bad)==0,paste(nrow(bad),'unités historiques non réconciliées'),table='legacy_polling_units')
  if(nrow(bad))write_csv_utf8(bad,'data/interim/quality/legacy_polling_inconsistencies.csv')
 }
 if(all(c('legacy_historical_candidate_results','legacy_historical_district_results') %in% ls(TABLES))) {
  p<-get('legacy_historical_candidate_results',TABLES) |> group_by(election_id,district_id,snapshot_id) |> summarise(sum_votes=ifelse(anyNA(votes),NA_real_,sum(votes)),.groups='drop')
  u<-left_join(get('legacy_historical_district_results',TABLES),p,by=c('election_id','district_id','snapshot_id'))
  check('legacy_candidate_vote_totals',all(is.na(u$sum_votes)|is.na(u$valid_ballots)|u$sum_votes==u$valid_ballots),'sommes historiques concordent quand les comptages numériques sont fournis',table='legacy_historical_candidate_results')
 }
 if(exists('district_crosswalk_2017_2026',TABLES)) {
  z<-get('district_crosswalk_2017_2026',TABLES)
  check('crosswalk_fractions',all(z$old_area_fraction>=0 & z$old_area_fraction<=1+1e-6 & z$new_area_fraction>=0 & z$new_area_fraction<=1+1e-6),'fractions dans [0,1], tolérance numérique 1e-6',table='district_crosswalk_2017_2026')
 }
 for(n in c('results_candidate','historical_candidate_results','legacy_historical_candidate_results'))if(exists(n,TABLES)) {
  x<-get(n,TABLES)
  if(!'valid_ballots' %in% names(x) && exists('turnout',TABLES))x<-left_join(x,get('turnout',TABLES) |> select(election_id,district_id,snapshot_id,valid_ballots),by=c('election_id','district_id','snapshot_id'))
  if('valid_ballots' %in% names(x))check(paste0(n,':shares'),all(is.na(x$vote_share_pct)|is.na(x$valid_ballots)|abs(x$vote_share_pct-100*x$votes/x$valid_ballots)<1e-6),'parts recalculées concordantes',table=n)
 }
 if(exists('election_calendar_2026',TABLES)) {
  x<-get('election_calendar_2026',TABLES)
  check('calendar_dates',all(!is.na(as.Date(x$event_date))),'dates de calendrier valides',table='election_calendar_2026')
 }
 if (exists('candidates', TABLES)) {
  c <- get('candidates', TABLES); latest <- max(c$observed_at); c <- filter(c, observed_at == latest)
  check('2026_candidates', nrow(c) == 908, 'Contrôle de référence daté : 908 au 3 octobre 2026; une rectification ultérieure doit être revue.', severity=ifelse(all(substr(c$retrieved_at,1,10)=='2026-10-03'),'error','warning'),table='candidates')
  check('2026_candidate_districts', n_distinct(c$district_id) == 127, '127 circonscriptions officielles', table = 'candidates')
  # Le contrôle est daté et doit être revérifié après toute rectification officielle.
 }
 if (exists('electoral_districts', TABLES)) {
  d <- get('electoral_districts', TABLES) |> filter(code_edition == '2026') |> distinct(district_id)
  check('2026_map_count', nrow(d) == 127, '127 circonscriptions dans la liste officielle', table = 'electoral_districts')
 }
 if (exists('results_candidate', TABLES)) {
  r <- get('results_candidate', TABLES)
  check('result_status', all(r$data_status %in% c('preliminary','final')), 'final uniquement selon source', table = 'results_candidate')
  check('no_preliminary_elected', all(is.na(r$elected_source[r$data_status == 'preliminary'])), 'aucune élection annoncée sur la base d’un fichier préliminaire', table = 'results_candidate')
 }
 report <- bind_rows(checks); append_csv(report, 'metadata/quality_report.csv'); write_csv_utf8(report, 'metadata/validation_latest.csv')
 if (length(failures)) stop(paste(failures, collapse = '\n'))
 invisible(report)
}
