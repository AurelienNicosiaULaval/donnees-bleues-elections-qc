# Transcription des événements lisibles dans le calendrier officiel DGE-5 (26-07).
transform_calendar <- function() {
 s<-load_catalog() |> filter(grepl('/DGE-5-VF.pdf$',url)); m<-latest_manifest() |> filter(source_id %in% s$source_id)
 if(!nrow(m)) return(invisible(NULL))
 events<-tibble(event_code=c('decree','candidacy_open','electoral_expense_period_open','revision_open','outside_quebec_registration_close','candidacy_close','withdrawal_ballot_close','advance_vote_1','advance_vote_2','returning_officer_vote_1','returning_officer_vote_2','returning_officer_vote_3','returning_officer_vote_4','returning_officer_vote_5','special_revision_close','polling_day','expense_period_close','vote_tally','judicial_recount_application_close'),
  event_date=c('2026-08-27','2026-08-27','2026-08-28','2026-09-14','2026-09-16','2026-09-17','2026-09-20','2026-09-27','2026-09-28','2026-09-25','2026-09-26','2026-09-29','2026-09-30','2026-10-01','2026-10-01','2026-10-05','2026-10-05','2026-10-06','2026-10-13'),
  event_label=c('Prise du décret','Premier jour de dépôt de candidature','Premier jour de contrôle des dépenses électorales','Début de révision ordinaire','Dernier jour de demande de vote hors Québec','Clôture des candidatures','Dernier jour de retrait sans apparition sur le bulletin','Vote par anticipation','Vote par anticipation','Vote au bureau du directeur du scrutin','Vote au bureau du directeur du scrutin','Vote au bureau du directeur du scrutin','Vote au bureau du directeur du scrutin','Vote au bureau du directeur du scrutin','Dernier jour de demande à la révision spéciale','Jour du scrutin','Fin de la période de dépenses électorales','Recensement des votes','Dernier jour de demande de dépouillement judiciaire'),
  local_start=c(NA,NA,NA,NA,NA,NA,NA,'09:30','09:30','09:30','09:30','09:30','09:30','09:30',NA,'09:30',NA,NA,NA),
  local_end=c(NA,NA,NA,NA,NA,'14:00',NA,'20:00','20:00','20:00','16:00','20:00','20:00','14:00','14:00','20:00','20:00',NA,NA),
  legal_article_source=c('128;131','237','401','180;193','287','237','257','300;301.2','300;301.2','263;274','263;274','263;274','263;274','263;274','222','302;303;333','401','371','384;385'))
 events$election_id<-'qc-prov-2026-10-05-general';events$event_id<-paste(events$election_id,events$event_code,sep='-');events$time_zone<-'America/Toronto';events$source_document_version<-'DGE-5 (26-07) EG-JVS';events$source_page<-1L
 add_table('election_calendar_2026',attach_context(events,m[1,],'official_calendar_transcribed'),'événement officiel 2026')
}
