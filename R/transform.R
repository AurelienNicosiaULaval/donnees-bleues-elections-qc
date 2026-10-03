source('R/common.R')
# Les tables sont accumulées en mémoire; les fichiers publics et locaux restent séparés.
TABLES <- new.env(parent = emptyenv()); GRAINS <- list(); VISIBILITY <- list()
PENDING <- new.env(parent=emptyenv())
LARGE_TABLES <- c('polling_division_results','polling_units','polling_summary_fields','result_source_fields','legacy_polling_units','legacy_polling_division_results','legacy_historical_candidate_results')
add_table <- function(name, x, grain, public=TRUE) {
 if(!nrow(x))return(invisible(NULL))
 GRAINS[[name]] <<- grain; VISIBILITY[[name]] <<- public
 if(name %in% LARGE_TABLES) {
  chunks<-if(exists(name,PENDING,inherits=FALSE))get(name,PENDING)else list()
  chunks[[length(chunks)+1L]]<-x;assign(name,chunks,PENDING)
 } else {
  if(exists(name,TABLES,inherits=FALSE))x<-bind_rows(get(name,TABLES),x)
  assign(name,x,TABLES)
 }
}
flush_large_tables <- function() {
 for(name in ls(PENDING)) {
  chunks<-get(name,PENDING)
  if(exists(name,TABLES,inherits=FALSE))chunks<-c(list(get(name,TABLES)),chunks)
  assign(name,bind_rows(chunks),TABLES)
 }
 rm(list=ls(PENDING),envir=PENDING)
 invisible(gc())
}

context <- function(m, status = 'observed', updated = NA_character_) tibble(
 source_id = m$source_id, snapshot_id = m$snapshot_id, observed_at = m$observed_at,
 retrieved_at = m$retrieved_at, source_updated_at = updated, data_status = status)
attach_context <- function(x, m, status = 'observed', updated = NA_character_) {
 cbind(x, context(m, status, updated)[rep(1L, nrow(x)), ]) |> as_tibble()
}
source_fields <- function(obj, kind, eid, entity, m, status) {
 keys <- names(obj)[map_lgl(obj, function(v) is.null(v) || is.atomic(v) && length(v) <= 1)]
 x <- tibble(election_id = eid, entity_type = kind, entity_id = entity, source_field = keys,
   source_value = map_chr(keys, function(k) as.character(scalar(obj, k))))
 add_table('result_source_fields', attach_context(x, m, status), 'capture × entité × champ source')
}
transform_results <- function(s, m) {
 j <- fromJSON(m$raw_file, simplifyVector = FALSE)
 if (is.null(j$statistiques) || is.null(j$circonscriptions)) stop('Schéma de résultats inattendu')
 eid <- s$election_id; if (is.na(eid) || !nzchar(eid)) eid <- 'qc-prov-2026-10-05-general'
 mi <- map_info(eid); z <- j$statistiques
 status <- if (isTRUE(z$isResultatsFinaux)) 'final' else 'preliminary'
 updated <- source_time(scalar(z, 'iso8601DateMAJ'))
 ev <- tibble(election_id = eid, election_date = str_extract(eid, '\\d{4}-\\d{2}-\\d{2}'),
   election_type = ifelse(grepl('general$', eid), 'general', 'partial'), electoral_level = 'provincial',
   map_year = mi[['map_year']], code_edition = mi[['code_edition']],
   district_count = numeric_value(scalar(z, 'nbCirconscription')), registered = numeric_value(scalar(z, 'nbElecteurInscrit')),
   valid_ballots = numeric_value(scalar(z, 'nbVoteValide')), rejected_ballots = numeric_value(scalar(z, 'nbVoteRejete')),
   votes_cast = numeric_value(scalar(z, 'nbVoteExerce')), polls_total = numeric_value(scalar(z, 'nbBureauVote')),
   polls_counted = numeric_value(scalar(z, 'nbBureauVoteRempli')))
 ev$turnout_observed_pct <- ifelse(ev$registered > 0, 100 * ev$votes_cast / ev$registered, NA_real_)
 add_table('elections', attach_context(ev, m, status, updated), 'élection × capture')
 source_fields(z, 'election', eid, eid, m, status)
 for (p in z$partisPolitiques) {
  id <- party_key(eid, scalar(p, 'numeroPartiPolitique'))
  x <- tibble(election_id = eid, party_id = id, party_code = as.character(scalar(p, 'numeroPartiPolitique')),
    party_name = scalar(p, 'nomPartiPolitique'), party_abbreviation = scalar(p, 'abreviationPartiPolitique'),
    votes = numeric_value(scalar(p, 'nbVoteTotal')), vote_share_source_pct = numeric_value(scalar(p, 'tauxVoteTotal')),
    candidates_count_source = numeric_value(scalar(p, 'nbCandidat')),
    districts_leading_source = numeric_value(scalar(p, 'nbCirconscriptionsEnAvance')))
  x$vote_share_pct <- ifelse(ev$valid_ballots > 0, 100 * x$votes / ev$valid_ballots, NA_real_)
  x$seats_final_from_source <- if (status == 'final') x$districts_leading_source else NA_real_
  add_table('results_party', attach_context(x, m, status, updated), 'élection × parti × capture')
  source_fields(p, 'party', eid, id, m, status)
 }
 for (d in j$circonscriptions) {
  did <- district_key(scalar(d, 'numeroCirconscription'), mi[['map_year']], mi[['code_edition']])
  ds <- if (isTRUE(d$isResultatsFinaux)) 'final' else 'preliminary'; du <- source_time(scalar(d, 'iso8601DateMAJ'))
  x <- tibble(election_id = eid, district_id = did, district_code = as.character(scalar(d, 'numeroCirconscription')),
    district_name = scalar(d, 'nomCirconscription'), map_year = mi[['map_year']], code_edition = mi[['code_edition']],
    registered = numeric_value(scalar(d, 'nbElecteurInscrit')), valid_ballots = numeric_value(scalar(d, 'nbVoteValide')),
    rejected_ballots = numeric_value(scalar(d, 'nbVoteRejete')), votes_cast = numeric_value(scalar(d, 'nbVoteExerce')),
    turnout_source_pct = numeric_value(scalar(d, 'tauxParticipation')), polls_counted = numeric_value(scalar(d, 'nbBureauComplete')),
    polls_total = numeric_value(scalar(d, 'nbBureauTotal')))
  x$turnout_observed_pct <- ifelse(x$registered > 0, 100 * x$votes_cast / x$registered, NA_real_)
  x$rejected_ballots_pct <- ifelse(x$votes_cast > 0, 100 * x$rejected_ballots / x$votes_cast, NA_real_)
  add_table('turnout', attach_context(x, m, ds, du), 'élection × circonscription × capture')
  source_fields(d, 'district', eid, did, m, ds)
  votes <- map_dbl(d$candidats, ~ numeric_value(scalar(.x, 'nbVoteTotal')))
  for (k in seq_along(d$candidats)) {
   c <- d$candidats[[k]]; cid <- candidate_key(eid, did, scalar(c, 'numeroCandidat'))
   v <- tibble(election_id = eid, district_id = did, candidate_id = cid, candidate_code = as.character(scalar(c, 'numeroCandidat')),
     last_name = scalar(c, 'nom'), first_name = scalar(c, 'prenom'), party_id = party_key(eid, scalar(c, 'numeroPartiPolitique')),
     party_code = as.character(scalar(c, 'numeroPartiPolitique')), party_abbreviation = scalar(c, 'abreviationPartiPolitique'),
     votes = votes[k], vote_share_source_pct = numeric_value(scalar(c, 'tauxVote')),
     lead_votes_source = numeric_value(scalar(c, 'nbVoteAvance')))
   v$vote_share_pct <- ifelse(x$valid_ballots > 0, 100 * v$votes / x$valid_ballots, NA_real_)
   v$rank_descriptive <- if (all(is.na(votes))) NA_integer_ else rank(-votes, ties.method = 'min', na.last = 'keep')[k]
   v$elected_source <- scalar(c, 'isElu', NA)
   add_table('results_candidate', attach_context(v, m, ds, du), 'élection × circonscription × candidature × capture')
   source_fields(c, 'candidate', eid, cid, m, ds)
  }
 }
}
transform_candidates <- function(s, m) {
 j <- fromJSON(m$raw_file, simplifyVector = FALSE); eid <- 'qc-prov-2026-10-05-general'
 events <- unique(vapply(j, function(c) as.character(scalar(c, 'oepevep_id')), character(1)))
 if (!identical(events, '1126')) stop('Le fichier courant ne correspond plus à l’événement officiel 1126 (2026). Revoir le catalogue avant intégration.')
 x <- map_dfr(j, function(c) {
  did <- district_key(scalar(c, 'code_circonscription'), '2026', '2026')
  tibble(election_id = eid, district_id = did, candidate_id = candidate_key(eid, did, scalar(c, 'numero')),
    candidate_code = as.character(scalar(c, 'numero')), source_event_id = as.character(scalar(c, 'oepevep_id')),
    first_name = scalar(c, 'prenom_bulletin_vote'), last_name = scalar(c, 'nom_bulletin_vote'),
    party_id = party_key(eid, scalar(c, 'afpparp_numero')), party_code = as.character(scalar(c, 'afpparp_numero')),
    party_name = scalar(c, 'nom_parti'), party_abbreviation = scalar(c, 'abreviation_parti'),
    independent_mention_source = scalar(c, 'mention_independant_bull_vote'), status_source = scalar(c, 'statut'),
    state_source = scalar(c, 'etat'), outgoing_member_source = scalar(c, 'depute_sortant'),
    official_agent_first_name = scalar(c, 'prenom_agent_off'), official_agent_last_name = scalar(c, 'nom_agent_off'),
    sex_source = scalar(c, 'sexe'), age_source = numeric_value(scalar(c, 'age')),
    row_source_updated_at = source_time(scalar(c, 'date_heure_maj')))
 })
 add_table('candidates', attach_context(x, m, 'accepted_list'), 'candidature à une élection')
}
transform_parties <- function(s, m) {
 j <- fromJSON(m$raw_file, simplifyVector = FALSE)
 for (p in j) {
  id <- paste0('qc-prov-repaq-', scalar(p, 'id'))
  x <- tibble(party_registry_id = id, registry_code = scalar(p, 'id'), former_code = scalar(p, 'id_ancien'),
    party_name = scalar(p, 'nom'), former_name = scalar(p, 'ancienNom'), name_changed_on = scalar(p, 'dateChangementNom'),
    authorized_on = scalar(p, 'dateAutorisation'), registry_status = 'listed_authorized')
  add_table('parties', attach_context(x, m), 'parti au registre × capture')
  add_table('party_authorization_history', attach_context(select(x, party_registry_id, authorized_on), m), 'autorisation officielle documentée × capture')
  for (o in p$intervenants) if (scalar(o, 'type') %in% c('AO', 'CHEF', 'REPOFF')) {
   y <- tibble(party_registry_id = id, role_source = scalar(o, 'type'), official_name = scalar(o, 'nom'),
     appointed_on = scalar(o, 'dateNomination'), resigned_on = scalar(o, 'dateDemission'))
   add_table('party_officials', attach_context(y, m), 'parti × fonction publique × capture')
  }
 }
}
transform_district_list <- function(s, m) {
 x <- read_source_csv(m$raw_file); edition <- str_extract(s$url, '(2011|2017|2022|2026)')
 code_col <- which(grepl('code|^BSQ$', names(x), ignore.case = TRUE))[1]
 name_col <- which(grepl('circonscription', names(x), ignore.case = TRUE))[1]
 if (is.na(code_col) || is.na(name_col)) stop('Colonnes circonscription manquantes')
 year <- ifelse(edition == '2022', '2017', edition)
 z <- tibble(district_id = district_key(x[[code_col]], year, edition), district_code = x[[code_col]],
   district_name = x[[name_col]], map_year = year, code_edition = edition)
 add_table('electoral_districts', attach_context(z, m), 'circonscription × carte × édition de codes')
}
transform_electors <- function(s, m) {
 x <- read_source_csv(m$raw_file); eid <- 'qc-prov-2026-10-05-general'
 required <- c('CODE_CIRCONSCRIPTION', 'NOMBRE_ELECTEURS_AU_DECRET', 'NOMBRE_ELECTEURS_APRES_REVISION_ORDINAIRE', 'NOMBRE_ELECTEURS_APRES_REVISION_SPECIALE')
 if (!all(required %in% names(x))) stop('Schéma inscrits changé')
 y <- tibble(election_id = eid, district_id = district_key(x$CODE_CIRCONSCRIPTION, '2026', '2026'),
   registered_at_decree = numeric_value(x$NOMBRE_ELECTEURS_AU_DECRET),
   registered_after_revision = numeric_value(x$NOMBRE_ELECTEURS_APRES_REVISION_ORDINAIRE),
   registered_after_special_revision = numeric_value(x$NOMBRE_ELECTEURS_APRES_REVISION_SPECIALE))
 # Ce total exclut les personnes détenues et le vote hors Québec, selon le producteur.
 add_table('registered_electors', attach_context(y, m, 'electoral_roll_stage'), 'élection × circonscription × capture')
}
transform_preliminary <- function(s, m) {
 x <- read_source_csv(m$raw_file)
 y <- tibble(election_id = 'qc-prov-2026-10-05-general', district_id = district_key(x$CODE_CIRCONSCRIPTION, '2026', '2026'),
   district_name = x$NOM_CIRCONSCRIPTION, turnout_preliminary_pct = numeric_value(x$TAUX_PARTICIPATION_PRELIMINAIRE),
   update_type = 'preliminary_turnout_source', registered = NA_real_, votes_cast = NA_real_)
 # Un taux arrondi ne permet pas de reconstruire un nombre de votants.
 add_table('turnout_preliminary_2026', attach_context(y, m, 'preliminary'), 'circonscription × capture', FALSE)
}
normalize_header <- function(x) gsub('[^A-Z0-9]', '', toupper(iconv(x, to = 'ASCII//TRANSLIT')))
transform_polls <- function(s, m) {
 folder <- file.path('data/interim/polls', m$sha256); dir.create(folder, recursive = TRUE, showWarnings = FALSE)
 entries <- unzip(m$raw_file, list = TRUE)$Name
 if (any(grepl('(^/|[.][.])', entries))) stop('Chemin ZIP non sûr')
 status <- system2(Sys.getenv('ELECTIONS_PYTHON', 'python3'), c(shQuote('scripts/download/unpack_zip.py'), shQuote(m$raw_file), shQuote(folder)))
 if (status != 0) stop('Extraction ZIP échouée')
 eid <- s$election_id; mi <- map_info(eid)
 refs <- if (exists('results_candidate', TABLES)) get('results_candidate', TABLES) |> filter(election_id == eid) else tibble()
 for (f in list.files(folder, pattern = '^member_.*[.]csv$', full.names = TRUE)) {
  if (grepl('gen2012', s$url)) { transform_polls_2012(s, m, f); next }
  x <- suppressMessages(read_source_csv(f))
  aliases <- c('Section de vote' = 'S.V.', 'Électeurs inscrits' = 'É.I.', 'Bulletins valides' = 'B.V.', 'Bulletins rejetés' = 'B.R.', 'Nom des municipalités' = 'Nom des Municipalités')
  for (a in names(aliases)) if (a %in% names(x)) names(x)[names(x) == a] <- aliases[[a]]
  req <- c('Code', 'Circonscription', 'S.V.', 'É.I.', 'B.V.', 'B.R.')
  if (!all(req %in% names(x))) { quality_event('poll_schema', 'warning', s$source_id, basename(f)); next }
  base <- which(names(x) == 'É.I.'); end <- which(names(x) == 'B.V.')
  if (end <= base + 1) next
  cand_cols <- names(x)[seq.int(base + 1, end - 1)]
  did <- district_key(x$Code, mi[['map_year']], mi[['code_edition']])
  keep <- !is.na(numeric_value(x[['B.V.']])) & !grepl('total', paste(x[['S.V.']], x[['Nom des Municipalités']]), ignore.case = TRUE)
  # Les totaux sommaires sont conservés séparément; ils ne deviennent pas de fausses urnes.
  summaries <- x[!keep, ]
  if (nrow(summaries)) {
   summaries$source_summary_row <- which(!keep)
   summaries <- mutate(summaries, across(everything(), as.character)) |> pivot_longer(-source_summary_row, names_to = 'source_field', values_to = 'source_value')
   summaries$source_file <- basename(f); summaries$election_id <- eid
   add_table('polling_summary_fields', attach_context(summaries, m, 'final'), 'fichier × ligne de total × champ source')
  }
  x <- x[keep, ]; did <- did[keep]
  if (!nrow(x)) next
  b <- tibble(election_id = eid, district_id = did, polling_division_source = x[['S.V.']],
    polling_unit_id = paste(eid, did, basename(f), seq_len(nrow(x)), sep = ':'),
    district_name = x$Circonscription, registered = numeric_value(x[['É.I.']]), valid_ballots = numeric_value(x[['B.V.']]),
    rejected_ballots = numeric_value(x[['B.R.']]), source_file = basename(f),
    sector_source = if ('Secteur' %in% names(x)) x$Secteur else NA_character_,
    grouping_source = if ('Regroupement' %in% names(x)) x$Regroupement else NA_character_,
    municipalities_source = if ('Nom des Municipalités' %in% names(x)) x[['Nom des Municipalités']] else NA_character_)
  b$votes_cast <- b$valid_ballots + b$rejected_ballots
  add_table('polling_units', attach_context(b, m, 'final'), 'élection × circonscription × unité publiée')
  for (column in cand_cols) {
   id <- paste(eid, did[1], 'poll-candidate', substr(digest(column, serialize = FALSE, algo = 'sha256'), 1, 12), sep = '-')
   linked <- FALSE
   if (nrow(refs)) {
    rr <- refs |> filter(district_id == did[1]) |> distinct(candidate_id, last_name, first_name, party_abbreviation)
    match <- which(normalize_header(paste(rr$last_name, rr$first_name, rr$party_abbreviation)) == normalize_header(column))
    if (length(match) == 1) { id <- rr$candidate_id[match]; linked <- TRUE }
   }
   v <- tibble(election_id = eid, district_id = did, polling_unit_id = b$polling_unit_id,
     candidate_id = id, candidate_header_source = column, candidate_link_status = ifelse(linked, 'exact_name_party_district_election', 'unmatched_source_header'), votes = numeric_value(x[[column]]))
   add_table('polling_division_results', attach_context(v, m, 'final'), 'élection × circonscription × unité publiée × candidature')
  }
 }
}
transform_all <- function() {
 catalog <- load_catalog(); manifest <- latest_manifest()
 # Les listes précèdent les fichiers de bureaux dont les noms sont à relier.
 manifest <- manifest |> arrange(case_when(grepl('liste_circonscriptions|Liste_complete', url) ~ 0L, grepl('/resultats.json$', url) ~ 1L, TRUE ~ 2L))
 for (i in seq_len(nrow(manifest))) {
  m <- manifest[i, ]; s <- catalog |> filter(source_id == m$source_id)
  if (!nrow(s) || !file.exists(m$raw_file) || s$group %in% c('legacy_json','legacy_polls')) next
  tryCatch({
   u <- s$url
   if (grepl('/resultats.json$', u)) transform_results(s, m)
   else if (grepl('Liste_complete_des_candidats.xls$', u)) transform_candidates_2012(s, m)
   else if (grepl('/candidatures.json$', u)) transform_candidates(s, m)
   else if (grepl('/pp_autorises.json$', u)) transform_parties(s, m)
   else if (grepl('liste_circonscriptions', u)) transform_district_list(s, m)
   else if (grepl('/electeur_inscrit.csv$', u)) transform_electors(s, m)
   else if (grepl('taux_participation_preliminaire.csv$', u)) transform_preliminary(s, m)
   else if (grepl('resultats-bureau-vote.zip$', u)) transform_polls(s, m)
  }, error = function(e) quality_event('transform', 'error', s$source_id, conditionMessage(e)))
 }
 # Rejouer toutes les captures 2026; les versions historiques fixes ne sont pas dupliquées.
 idx <- read_meta('data/snapshots/results_2026/index.csv')
 if (nrow(idx) > 1) for (i in seq_len(nrow(idx) - 1L)) {
  s <- catalog |> filter(source_id == idx$source_id[i]); transform_results(s, idx[i, ])
 }
 # Historiser les fichiers variables sans jamais inférer la date de leur état source.
 allm <- load_manifest()
 for (pattern in c('/candidatures.json$', '/pp_autorises.json$', 'taux_participation_preliminaire.csv$', '/electeur_inscrit.csv$')) {
  rows <- allm |> filter(grepl(pattern, url)) |> group_by(source_id) |> filter(row_number() < n()) |> ungroup()
  rows <- rows[file.exists(rows$raw_file), ]
  if (nrow(rows)) for (i in seq_len(nrow(rows))) {
   s <- catalog |> filter(source_id == rows$source_id[i]); m <- rows[i, ]
   if (grepl('candidatures', pattern)) transform_candidates(s, m)
   else if (grepl('autorises', pattern)) transform_parties(s, m)
   else if (grepl('preliminaire', pattern)) transform_preliminary(s, m)
   else transform_electors(s, m)
  }
 }
}
