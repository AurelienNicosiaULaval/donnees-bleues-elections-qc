# Archives chargées par les pages officielles, hors licence ouverte vérifiée.
transform_legacy_results <- function(s,m) {
 j<-fromJSON(m$raw_file,simplifyVector=FALSE);if(is.null(j$statistiques)||is.null(j$circonscriptions))stop('Schéma historique JSON inattendu')
 eid<-s$election_id;mi<-map_info(eid);z<-j$statistiques
 status<-if(isTRUE(z$isResultatsFinaux))'final' else if(identical(z$isResultatsFinaux,FALSE))'preliminary' else 'historical_published_finality_unspecified'
 updated<-source_time(scalar(z,'iso8601DateMAJ'))
 e<-tibble(election_id=eid,election_date=str_extract(eid,'[0-9]{4}-[0-9]{2}-[0-9]{2}'),election_type=ifelse(grepl('general$',eid),'general','partial'),electoral_level='provincial',map_year=mi[['map_year']],code_edition=mi[['code_edition']],district_count=numeric_value(scalar(z,'nbCirconscription')),registered=numeric_value(scalar(z,'nbElecteurInscrit')),valid_ballots=numeric_value(scalar(z,'nbVoteValide')),rejected_ballots=numeric_value(scalar(z,'nbVoteRejete')),votes_cast=numeric_value(scalar(z,'nbVoteExerce')))
 e$turnout_observed_pct<-ifelse(e$registered>0,100*e$votes_cast/e$registered,NA_real_)
 add_table('legacy_elections',attach_context(e,m,status,updated),'élection historique × capture',FALSE)
 party_id_for<-function(abbr)paste(eid,'party-abbreviation',substr(digest(abbr,algo='sha256',serialize=FALSE),1,12),sep='-')
 for(p in z$partisPolitiques) {
  abbr<-scalar(p,'abreviationPartiPolitique');a<-tibble(election_id=eid,party_id=party_id_for(abbr),party_abbreviation=abbr,party_name=scalar(p,'nomPartiPolitique'),party_code_source=as.character(scalar(p,'numeroPartiPolitique')),party_identity_basis='source_abbreviation_in_event',votes=numeric_value(scalar(p,'nbVoteTotal')),vote_share_source_pct=numeric_value(scalar(p,'tauxVoteTotal')),candidates_count_source=numeric_value(scalar(p,'nbCandidat')),districts_leading_source=numeric_value(scalar(p,'nbCirconscriptionsEnAvance')))
  add_table('legacy_historical_party_results',attach_context(a,m,status,updated),'élection historique × parti × capture',FALSE)
 }
 for(d in j$circonscriptions) {
  code<-as.character(scalar(d,'numeroCirconscription'));did<-district_key(code,mi[['map_year']],mi[['code_edition']])
  a<-tibble(election_id=eid,district_id=did,district_code=code,district_name=scalar(d,'nomCirconscription'),map_year=mi[['map_year']],code_edition=mi[['code_edition']],registered=numeric_value(scalar(d,'nbElecteurInscrit')),valid_ballots=numeric_value(scalar(d,'nbVoteValide')),rejected_ballots=numeric_value(scalar(d,'nbVoteRejete')),votes_cast=numeric_value(scalar(d,'nbVoteExerce')),turnout_source_pct=numeric_value(scalar(d,'tauxParticipation')))
  a$turnout_observed_pct<-ifelse(a$registered>0,100*a$votes_cast/a$registered,NA_real_)
  add_table('legacy_historical_district_results',attach_context(a,m,status,updated),'élection historique × circonscription × capture',FALSE)
  votes<-map_dbl(d$candidats,~numeric_value(scalar(.x,'nbVoteTotal')))
  for(i in seq_along(d$candidats)) {
   c<-d$candidats[[i]];abbr<-scalar(c,'abreviationPartiPolitique')
   a<-tibble(election_id=eid,district_id=did,candidate_id=paste(eid,did,'source-record',i,sep='-'),candidate_identity_basis='position_in_district_json; no cross_event_person_link',candidate_code_source=as.character(scalar(c,'numeroCandidat')),last_name=scalar(c,'nom'),first_name=scalar(c,'prenom'),party_id=party_id_for(abbr),party_abbreviation=abbr,votes=votes[i],valid_ballots=numeric_value(scalar(d,'nbVoteValide')),vote_share_source_pct=numeric_value(scalar(c,'tauxVote')),rank_descriptive=rank(-votes,ties.method='min',na.last='keep')[i],lead_votes_source=numeric_value(scalar(c,'nbVoteAvance')),elected_source=if(!is.null(c$isElu))as.logical(c$isElu)else NA)
   a$vote_share_pct<-ifelse(a$valid_ballots>0,100*a$votes/a$valid_ballots,NA_real_)
   add_table('legacy_historical_candidate_results',attach_context(a,m,status,updated),'élection historique × candidature source × capture',FALSE)
  }
 }
}
transform_legacy_json_all<-function() {
 s<-load_catalog();m<-latest_manifest();rows<-inner_join(filter(s,group=='legacy_json'),m,by='source_id',suffix=c('','_capture'))
 for(i in seq_len(nrow(rows)))if(file.exists(rows$raw_file[i]))tryCatch(transform_legacy_results(rows[i,],rows[i,]),error=function(e)quality_event('legacy_json','error',rows$source_id[i],conditionMessage(e)))
}
