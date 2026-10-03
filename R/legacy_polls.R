# Archives XLS/TSV 1998-2008 : en-têtes propres à chaque bloc de circonscription.
transform_legacy_polls_all <- function() {
 s<-load_catalog();m<-latest_manifest();rows<-inner_join(filter(s,group=='legacy_polls'),m,by='source_id',suffix=c('','_capture'))
 for(i in seq_len(nrow(rows)))if(file.exists(rows$raw_file[i]))tryCatch({
  r<-rows[i,];folder<-file.path('data/interim',r$sha256);system2('python3',c('scripts/download/unpack_zip.py',shQuote(r$raw_file),shQuote(folder)))
  members<-read_meta(file.path(folder,'members.csv'))
  for(fileindex in seq_len(nrow(members))) {
   path<-file.path(folder,members$file[fileindex]);excel<-grepl('[.]xlsx?$',path);sheets<-if(excel)readxl::excel_sheets(path)else'file'
   for(sheet in sheets) {
    message('Archive bureaux : ',r$election_id,' ',sheet)
    if(excel) x<-suppressMessages(readxl::read_excel(path,sheet=sheet,col_names=FALSE,col_types='text')) else {
     # Le TXT 2003 est en OEM/DOS CP850, pas Windows-1252 (0x90 = É).
     utf8<-paste0(path,'.utf8');status<-system2('python3',c('scripts/download/text_to_utf8.py',shQuote(path),shQuote(utf8),'cp850'))
     if(status!=0)stop('Conversion CP850 impossible')
     ncols<-max(lengths(strsplit(readLines(utf8,warn=FALSE), '\t',fixed=TRUE)))
     x<-as_tibble(read.delim(utf8,sep='\t',header=FALSE,col.names=paste0('V',seq_len(ncols)),colClasses='character',quote='',fill=TRUE,check.names=FALSE,fileEncoding='UTF-8',strip.white=TRUE),.name_repair='unique')
    }
    if(!nrow(x))next
    starts<-which(x[[1]]=='CIRCONSCRIPTION');ends<-c(starts[-1]-1,nrow(x));if(!length(starts))next
    refs<-get('legacy_historical_district_results',TABLES) |> filter(election_id==r$election_id) |> distinct(district_id,district_name)
    cr<-get('legacy_historical_candidate_results',TABLES) |> filter(election_id==r$election_id)
    for(k in seq_along(starts)) {
     st<-starts[k];head<-as.character(x[st+1,]);vcol<-which(gsub('[^A-Za-z]','',head)=='BV')[1];brcol<-which(gsub('[^A-Za-z]','',head)=='BR')[1]
     if(anyNA(c(vcol,brcol)))stop('Colonnes de bulletins absentes dans bloc historique')
     name<-x[[1]][st+1];match<-which(normalize_header(refs$district_name)==normalize_header(name))
     if(length(match)!=1) {
      # Vérification de territoire par plusieurs triplets exacts de candidatures du même événement.
      cols<-which(seq_len(ncol(x))>=5 & seq_len(ncol(x))<vcol & !is.na(as.character(x[st,])))
      ids<-character()
      for(col in cols) {
       same<-cr |> filter(normalize_header(last_name)==normalize_header(x[[col]][st]),normalize_header(first_name)==normalize_header(x[[col]][st+1]),normalize_header(party_abbreviation)==normalize_header(x[[col]][st+2]))
       if(nrow(same)==1)ids<-c(ids,same$district_id)
      }
      if(length(ids)>=2 && n_distinct(ids)==1) {
       match<-which(refs$district_id==ids[1])
       quality_event('legacy_territory_label','warning',r$source_id,paste('Libellé source',name,'relié à',refs$district_name[match],'par au moins deux triplets exacts nom-prénom-parti du même événement.'))
      } else stop('Territoire historique ambigu : ',name)
     }
     did<-refs$district_id[match];block<-x[(st+3):ends[k],];keep<-!grepl('TOTAL',ifelse(is.na(block[[1]]),'',block[[1]])) & !is.na(numeric_value(block[[vcol]]))
     actual<-block[keep,];idx<-which(keep)+st+2;uid<-paste(r$election_id,did,members$file[fileindex],sheet,idx,sep='-')
     u<-tibble(election_id=r$election_id,district_id=did,polling_unit_id=uid,source_file=members$original_member[fileindex],source_sheet=sheet,source_row=idx,municipalities_source=actual[[1]],sector_source=actual[[2]],polling_division_source=actual[[3]],registered=numeric_value(actual[[4]]),valid_ballots=numeric_value(actual[[vcol]]),rejected_ballots=numeric_value(actual[[brcol]]))
     u$votes_cast<-u$valid_ballots+u$rejected_ballots;add_table('legacy_polling_units',attach_context(u,r,'official_historical_polling_table'),'élection historique × unité publiée × capture',FALSE)
     cidx<-which(seq_len(ncol(x))>=5 & seq_len(ncol(x))<vcol & !is.na(as.character(x[st,])))
     for(col in cidx) {
      last<-x[[col]][st];first<-x[[col]][st+1];party<-x[[col]][st+2];ref<-cr |> filter(district_id==did,normalize_header(last_name)==normalize_header(last),normalize_header(first_name)==normalize_header(first),normalize_header(party_abbreviation)==normalize_header(party))
      exact<-nrow(ref)==1;cid<-if(exact)ref$candidate_id else paste(r$election_id,did,'polling-header',substr(digest(paste(last,first,party),algo='sha256'),1,12),sep='-')
      z<-tibble(election_id=r$election_id,district_id=did,polling_unit_id=uid,candidate_id=cid,candidate_header_source=paste(last,first,party),candidate_link_status=ifelse(exact,'exact_name_party_district_election','unmatched_source_header'),votes=numeric_value(actual[[col]]))
      add_table('legacy_polling_division_results',attach_context(z,r,'official_historical_polling_table'),'élection historique × unité × candidature source × capture',FALSE)
     }
    }
   }
  }
 },error=function(e)quality_event('legacy_polling','error',rows$source_id[i],conditionMessage(e)))
}
