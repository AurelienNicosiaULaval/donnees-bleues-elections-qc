# Le fichier 2012 est un TSV en blocs, malgré son suffixe CSV.
transform_candidates_2012 <- function(s, m) {
 x <- readxl::read_excel(m$raw_file)
 did <- district_key(as.character(x$BSQ), '2011', '2011'); eid <- 'qc-prov-2012-09-04-general'
 z <- tibble(election_id = eid, district_id = did, candidate_id = candidate_key(eid, did, as.character(x$ID)),
   candidate_code = as.character(x$ID), last_name = x$NOM_CAND, first_name = x$PRENOM_CAND,
   party_name = x$PARTI, party_abbreviation = x$PARTI_ACRONYME, sex_source = x$GENRE)
 add_table('candidates_2012', attach_context(z, m, 'official_candidate_list'), 'candidature officielle 2012')
}
transform_polls_2012 <- function(s, m, f) {
 x <- suppressMessages(read_delim(f, delim = '\t', col_names = FALSE, col_types = cols(.default = col_character()),
   locale = locale(encoding = 'windows-1252'), trim_ws = TRUE, show_col_types = FALSE))
 starts <- which(x[[1]] == 'CIRCONSCRIPTION'); ends <- c(starts[-1] - 1, nrow(x))
 eid <- 'qc-prov-2012-09-04-general'
 refs <- get('electoral_districts', TABLES) |> filter(code_edition == '2011')
 candrefs <- if (exists('candidates_2012', TABLES)) get('candidates_2012', TABLES) else tibble()
 for (k in seq_along(starts)) {
  start <- starts[k]; name <- x[[1]][start + 1]
  matches <- which(normalize_header(refs$district_name) == normalize_header(name))
  if (length(matches) != 1) stop('Circonscription 2012 non appariée : ', name)
  did <- refs$district_id[matches]; block <- x[(start + 3):ends[k], ]
  cidx <- which(!is.na(as.character(x[start, ])) & seq_len(ncol(x)) >= 5 & seq_len(ncol(x)) <= ncol(x) - 2)
  cnames <- map_chr(cidx, ~ as.character(x[[.x]][start])); firsts <- map_chr(cidx, ~ as.character(x[[.x]][start + 1])); parties <- map_chr(cidx, ~ as.character(x[[.x]][start + 2]))
  total_row <- which(block[[1]] == 'GRAND TOTAL'); if (length(total_row) != 1) stop('Grand total 2012 ambigu')
  totals <- block[total_row, ]; valid <- numeric_value(totals[[ncol(x)-1]]); rejected <- numeric_value(totals[[ncol(x)]]); registered <- numeric_value(totals[[4]])
  t <- tibble(election_id = eid, district_id = did, district_code = refs$district_code[matches], district_name = name,
    map_year = '2011', code_edition = '2011', registered = registered, valid_ballots = valid,
    rejected_ballots = rejected, votes_cast = valid + rejected, turnout_observed_pct = 100 * (valid + rejected) / registered)
  add_table('turnout', attach_context(t, m, 'final'), 'élection × circonscription × capture')
  keep <- !grepl('TOTAL', ifelse(is.na(block[[1]]), '', block[[1]])) & !is.na(numeric_value(block[[ncol(x)-1]]))
  b <- block[keep, ]; unit_id <- paste(eid, did, basename(f), start, which(keep), sep = ':')
  units <- tibble(election_id = eid, district_id = did, polling_unit_id = unit_id, polling_division_source = b[[3]],
    district_name = name, registered = numeric_value(b[[4]]), valid_ballots = numeric_value(b[[ncol(x)-1]]),
    rejected_ballots = numeric_value(b[[ncol(x)]]), sector_source = b[[2]], municipalities_source = b[[1]], source_file = basename(f))
  units$votes_cast <- units$valid_ballots + units$rejected_ballots
  add_table('polling_units', attach_context(units, m, 'final'), 'élection × circonscription × unité publiée')
  votes <- map_dbl(cidx, ~ numeric_value(totals[[.x]]))
  for (q in seq_along(cidx)) {
   header <- paste(cnames[q], firsts[q], parties[q])
   id <- paste(eid, did, 'poll-candidate', substr(digest(header, serialize = FALSE, algo = 'sha256'), 1, 12), sep = '-')
   linked <- FALSE
   if (nrow(candrefs)) {
    rr <- candrefs |> filter(district_id == did)
    found <- which(normalize_header(paste(rr$last_name, rr$first_name, rr$party_abbreviation)) == normalize_header(header))
    if (length(found) == 1) { id <- rr$candidate_id[found]; linked <- TRUE }
   }
   pid <- paste(eid, 'party-abbreviation', normalize_header(parties[q]), sep = '-')
   c <- tibble(election_id = eid, district_id = did, candidate_id = id, candidate_code = NA_character_,
     first_name = firsts[q], last_name = cnames[q], party_id = pid, party_abbreviation = parties[q],
     votes = votes[q], vote_share_pct = 100 * votes[q] / valid, rank_descriptive = rank(-votes, ties.method = 'min')[q],
     elected_source = NA, lead_votes_source = NA_real_)
   add_table('results_candidate', attach_context(c, m, 'final'), 'élection × circonscription × candidature × capture')
   p <- tibble(election_id = eid, district_id = did, polling_unit_id = unit_id, candidate_id = id,
     candidate_header_source = header, candidate_link_status = ifelse(linked, 'exact_name_party_district_election', 'unmatched_source_header'), votes = numeric_value(b[[cidx[q]]]))
   add_table('polling_division_results', attach_context(p, m, 'final'), 'élection × circonscription × unité publiée × candidature')
  }
 }
}
