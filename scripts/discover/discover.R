# Relire les index officiels, sans construire d’URL de téléchargement par conjecture.
source('R/common.R')
seeds <- read_meta('metadata/discovery_seeds.csv'); catalog <- load_catalog(); found <- list()
for (i in seq_len(nrow(seeds))) {
 s <- seeds[i, ]
 tryCatch({
  response <- request(s$url) |> req_user_agent('DonneesBleues-ElectionsQC/0.1') |> req_timeout(120) |> req_retry(max_tries=3) |> req_perform()
  doc <- read_html(resp_body_string(response))
  scope <- html_elements(doc, '#tabProv'); if (!length(scope)) scope <- html_elements(doc, 'main')
  if (!length(scope)) scope <- doc
  links <- html_elements(scope, 'a[href]'); urls <- xml2::url_absolute(html_attr(links, 'href'), s$url)
  labels <- html_text2(links)
  keep <- grepl('[.](csv|json|xml|xls|xlsx|zip|pdf)($|[?])|/resultats-(generales|partielles)/[0-9]|/circonscriptions-provinciales/[^/]+/$', urls, ignore.case=TRUE)
  urls <- urls[keep]; labels <- labels[keep]
  for (j in seq_along(urls)) {
   if (!grepl('^https?://',urls[j]) || urls[j] %in% catalog$url) next
   ext <- str_extract(tolower(urls[j]), '(csv|json|xml|xls|xlsx|zip|pdf)(?=$|[?])') %||% NA_character_
   if (is.na(ext)) ext <- 'html'
   archive <- str_match(urls[j], '/(gen|par|part)([0-9]{4}-[0-9]{2}-[0-9]{2})/(resultats[.]json|resultats-bureau-vote[.]zip)$')
   known_archive <- s$licence=='DGEQ-open-data' && !is.na(archive[1,1]) && archive[1,3]>='2014-01-01'
   eid <- if(known_archive)paste0('qc-prov-',archive[1,3],ifelse(archive[1,2]=='gen','-general','-partial')) else NA_character_
   financial_pdf <- ext=='pdf' && s$group %in% c('finance','expenses','pre_election')
   row <- tibble(source_id=src_id(urls[j]), organisme=s$organisme, titre=labels[j], url=urls[j], description='Lien diffusé dans un index officiel; interprétation détaillée à vérifier.',
    format=toupper(ext), granularite='selon fichier officiel', periode_couverte=str_extract(urls[j],'(18|19|20)[0-9]{2}'), frequence_mise_a_jour='selon producteur',
    licence=s$licence, license_url=s$license_url, methode_acces='GET du lien effectivement publié', last_verified=as.character(Sys.Date()), verification_scope='index_link',
    donnees_personnelles='à vérifier avant diffusion', statut=ifelse(ext=='html','scraping_required','raw_download'),
    redistribution=ifelse(s$licence=='DGEQ-open-data','oui sous conditions','voir licence, adaptation non confirmée'), derived_publication=ifelse(s$licence=='DGEQ-open-data','public','local_only'),
    index_url=s$url, group=ifelse(known_archive,'archives',s$group), election_id=eid, download_default=ifelse(financial_pdf || known_archive,'true','false'), notes=if(financial_pdf)'Document financier officiel activé pour récupération locale; cellules extraites sans validation comptable automatique.' else if(known_archive)'Archive ouverte liée dans un index officiel; date lue dans son URL publiée, schéma et cohérence contrôlés avant diffusion.' else 'Nouvelle source découverte; extracteur et contrôle du périmètre requis avant activation.')
   found[[length(found)+1]] <- row; catalog <- bind_rows(catalog,row)
  }
 }, error=function(e) quality_event('discovery','warning',src_id(s$url),conditionMessage(e)))
 Sys.sleep(.75)
}
write_csv_utf8(distinct(catalog,url,.keep_all=TRUE),'metadata/source_catalog.csv')
message(length(found),' nouvelles sources; aucun extracteur ni droit de redistribution supposé.')
