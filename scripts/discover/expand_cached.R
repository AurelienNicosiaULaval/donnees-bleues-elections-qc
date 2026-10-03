# Inventorier les fichiers directement liés depuis les pages déjà téléchargées.
source('R/common.R');s<-load_catalog();m<-latest_manifest()
rows<-inner_join(filter(s,format=='HTML',group %in% c('general_history','assnat','map','district_profiles','atlas','finance','expenses','finance_bilan')),m,by='source_id',suffix=c('','_capture'))
new<-list()
for(i in seq_len(nrow(rows)))if(file.exists(rows$raw_file[i])) {
 r<-rows[i,];doc<-read_html(r$raw_file);scope<-html_elements(doc,'#tabProv');if(!length(scope))scope<-html_elements(doc,'main');if(!length(scope))scope<-doc
 links<-html_elements(scope,'a[href]');urls<-xml2::url_absolute(html_attr(links,'href'),r$url);labels<-html_text2(links)
 for(k in which(grepl('[.](pdf|xls|xlsx|csv|zip|json|xml)($|[?])',urls,ignore.case=TRUE))) {
  u<-urls[k];if(u %in% s$url || !grepl('electionsquebec[.]qc[.]ca|assnat[.]qc[.]ca',u))next
  fmt<-toupper(str_extract(tolower(u),'(pdf|xls|xlsx|csv|zip|json|xml)(?=$|[?])'))
  row<-r |> select(all_of(names(s))) |> mutate(source_id=src_id(u),url=u,titre=labels[k],description=paste('Fichier lié dans',r$titre),format=fmt,methode_acces='GET lien effectivement diffusé dans page officielle',verification_scope='cached_official_page_link',index_url=r$url,group='linked_documents',download_default='false',statut='raw_download',donnees_personnelles='à vérifier dans document',notes='Document inventorié; téléchargement explicite possible avec acquire(). Lecture et droits d’adaptation à contrôler.')
  new[[length(new)+1]]<-row;s<-bind_rows(s,row)
 }
}
write_csv_utf8(s,'metadata/source_catalog.csv');message(length(new),' documents liés ajoutés.')
