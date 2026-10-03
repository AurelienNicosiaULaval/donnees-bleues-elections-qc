source('R/transform.R'); source('R/legacy2012.R'); source('R/derive.R')
library(testthat)
test_that('les identifiants séparent carte, candidature et événement', {
 expect_false(district_key('1','2017','2022') == district_key('1','2026','2026'))
 expect_false(candidate_key('qc-prov-2022-10-03-general','d','1') == candidate_key('qc-prov-2026-10-05-general','d','1'))
 expect_match(source_time('2022-10-06T11:55:41,244-04:00'), '^2022-10-06T15:55:41[.]')
})
test_that('un dépouillement complet ne suffit pas à établir la finalité', {
 j <- list(statistiques = list(isResultatsFinaux=FALSE, nbElecteurInscrit=100, nbVoteValide=90, nbVoteRejete=2, nbVoteExerce=92, nbBureauVote=1, nbBureauVoteRempli=1, nbCirconscription=1, tauxParticipationTotal=99),
  circonscriptions = list(list(numeroCirconscription=1, nomCirconscription='Territoire de test', isResultatsFinaux=FALSE, nbElecteurInscrit=100, nbVoteValide=90, nbVoteRejete=2, nbVoteExerce=92, candidats=list(
   list(numeroCandidat=1, nom='Exemple A', prenom='Test', numeroPartiPolitique=1, nbVoteTotal=50, nbVoteAvance=10),
   list(numeroCandidat=2, nom='Exemple B', prenom='Test', numeroPartiPolitique=2, nbVoteTotal=40, nbVoteAvance=0)))))
 p <- tempfile(fileext='.json'); write_json(j,p,auto_unbox=TRUE)
 m <- list(raw_file=p,source_id='fixture',snapshot_id='fixture',observed_at='2026-10-06T00:15:00Z',retrieved_at='2026-10-06T00:15:01Z')
 s <- list(election_id='qc-prov-2026-10-05-general'); transform_results(s,m)
 expect_equal(unique(get('results_candidate',TABLES)$data_status),'preliminary')
 expect_true(all(is.na(get('results_candidate',TABLES)$elected_source)))
 expect_equal(get('elections',TABLES)$turnout_observed_pct,92)
 # La valeur extrapolée 99 demeure dans les champs sources, pas dans le taux observé.
 flush_large_tables()
 expect_true(any(get('result_source_fields',TABLES)$source_field=='tauxParticipationTotal'))
 unlink(p)
})
test_that('les octets et captures restent immuables', {
 m <- load_manifest()
 present <- m[file.exists(m$raw_file),]
 if (!nrow(present)) skip('Aucun brut local : vérifier les données publiques et le test de fixture')
 expect_true(all(vapply(seq_len(nrow(present)), function(i) identical(sha_file(present$raw_file[i]),present$sha256[i]), logical(1))))
 expect_false(anyDuplicated(m$snapshot_id)>0)
})
test_that('le flux de candidatures reste lié au scrutin vérifié', {
 p <- tempfile(fileext='.json'); write_json(list(list(oepevep_id=9999)),p,auto_unbox=TRUE)
 expect_error(transform_candidates(list(),list(raw_file=p)),'événement officiel 1126')
 unlink(p)
})
test_that('les géométries publiées sont valides et contextualisées', {
 library(sf)
 for(year in c('2017','2022','2026'))for(ext in c('gpkg','geojson')) {
  path <- paste0('data/processed/geography/districts_',year,if(ext=='geojson')'_simplified' else '','.',ext)
  x <- st_read(path,quiet=TRUE)
  expect_equal(nrow(x),if(year=='2026')127L else 125L)
  expect_true(all(st_is_valid(x)))
  expect_false(anyDuplicated(x$district_id)>0)
  expect_false(is.na(st_crs(x)))
 }
})
test_that('la diffusion exclut coordonnées et fichiers nominatifs', {
 paths <- list.files('data/processed', pattern='[.]csv([.]gz)?$', full.names=TRUE)
 for (p in paths) {
  columns <- names(read_meta(p))
  expect_false(any(grepl('adresse|postal|telephone|courriel|donateur|donatrice',columns,ignore.case=TRUE)),info=p)
 }
 tracked <- system2('git',c('ls-files'),stdout=TRUE,stderr=FALSE)
 expect_false(any(grepl('^data/(raw|external|interim)/|^data/processed/local_only/',tracked)))
})
# Vérification indépendante des tables réellement produites.
rm(list=ls(TABLES),envir=TABLES)
tc <- read_meta('metadata/table_catalog.csv'); dd <- read_meta('metadata/data_dictionary.csv')
for (i in seq_len(nrow(tc))) if (file.exists(tc$path[i])) {
 x <- read_meta(tc$path[i]); d <- filter(dd,table==tc$table[i])
 for (v in names(x)) if (d$type[match(v,d$variable)] %in% c('numeric','double','integer')) x[[v]] <- numeric_value(x[[v]])
 add_table(tc$table[i],x,tc$grain[i],tc$visibility[i]=='public')
}
flush_large_tables(); source('scripts/validate/validate.R'); validate_tables()
source('scripts/validate/publication.R')
cat('Tests terminés.\n')
