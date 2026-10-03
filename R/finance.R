# Les sorties financières adaptées restent locales, selon les droits actuels.
transform_financial_indexes <- function() {
 s<-load_catalog();m<-latest_manifest();idx<-inner_join(s |> filter(group %in% c('finance','expenses','pre_election'),format=='PDF'),m,by='source_id',suffix=c('','_capture'))
 if(nrow(idx)) {
  z<-idx |> transmute(document_id=source_id,document_title=titre,document_url=url,financial_year_source=str_extract(url,'20[0-9]{2}'),document_group=group,sha256=sha256,bytes=numeric_value(bytes),extraction_status='source_pdf_retained; see financial_extraction_inventory')
  # Pas de texte libre de coordonnées dans ce seul index.
  add_table('financial_document_index',bind_cols(z,idx |> select(source_id,snapshot_id,observed_at,retrieved_at) |> mutate(source_updated_at=NA_character_,data_status='document_index')),'document financier officiel',FALSE)
 }
 for(g in c('limits','allocations','map_history','district_history','district_profiles')) {
  rows<-inner_join(filter(s,group==g),m,by='source_id',suffix=c('','_capture'))
  for(i in seq_len(nrow(rows))) {
   r<-rows[i,]
   if(!file.exists(r$raw_file))next
   doc<-read_html(r$raw_file);scope<-html_elements(doc,'#tabProv');if(!length(scope))scope<-doc
   tabs<-html_elements(scope,'table') |> html_table(convert=FALSE)
   if(g=='allocations' && length(tabs) && ncol(tabs[[1]])>=2 && nrow(tabs[[1]])) {
    headings <- html_elements(doc,'h2') |> html_text2()
    year <- str_extract(headings[grepl('Allocations versées aux partis politiques provinciaux en',headings,fixed=TRUE)],'20[0-9]{2}')
    if(length(year)!=1L || is.na(year))stop('Année provinciale des allocations non déterminée dans la page officielle.')
    x<-as_tibble(tabs[[1]]);z<-tibble(entity_name_source=x[[1]],financial_year=as.integer(year),allocation_paid_cad=parse_number(x[[2]],locale=locale(decimal_mark=',',grouping_mark=' ')),value_source=x[[2]])
    z<-filter(z,!grepl('^Total$',entity_name_source,ignore.case=TRUE));add_table('party_public_funding',attach_context(z,r,'official_public_funding'),'parti × année',FALSE)
   }
   if(g=='limits' && length(tabs)) {
    for(k in seq_along(tabs)) {
     x<-as_tibble(tabs[[k]],.name_repair='unique') |> mutate(across(everything(),as.character));names(x)[1]<-'scope_source';x<-pivot_longer(x,-scope_source,names_to='validity_period_source',values_to='rate_source')
     x$rate_cad_per_elector<-parse_number(x$rate_source,locale=locale(decimal_mark=',',grouping_mark=' '));x$table_source<-k
     x$election_kind_source<-ifelse(k==1,'general',ifelse(k==2,'partial','voir intitulé source'))
     add_table('election_expense_limits',attach_context(x,r,'official_rate'),'type d’élection × périmètre × période',FALSE)
    }
   }
   if(g=='map_history' && length(tabs)) {
    x<-as_tibble(tabs[[1]]) |> mutate(across(everything(),as.character));names(x)<-c('map_year_source','district_count_source','events_source')[seq_len(ncol(x))]
    add_table('district_map_changes',attach_context(x,r,'official_history'),'carte historique officielle',FALSE)
   }
  }
 }
 ar<-inner_join(filter(s,group=='allocations_json'),m,by='source_id',suffix=c('','_capture'))
 for(i in seq_len(nrow(ar)))if(file.exists(ar$raw_file[i])) {
  r<-ar[i,]
  page <- inner_join(filter(s,group=='allocations',format=='HTML'),m,by='source_id',suffix=c('','_capture'))
  if(nrow(page)!=1L || !file.exists(page$raw_file))stop('Page officielle des allocations requise pour déterminer l’exercice.')
  if(substr(page$retrieved_at,1,10)!=substr(r$retrieved_at,1,10))stop('Capturer la page et le JSON des allocations le même jour pour vérifier l’exercice.')
  headings <- html_elements(read_html(page$raw_file),'h2') |> html_text2()
  year <- str_extract(headings[grepl('Allocations versées aux partis politiques provinciaux en',headings,fixed=TRUE)],'20[0-9]{2}')
  if(length(year)!=1L || is.na(year))stop('Année provinciale des allocations non déterminée dans la page officielle.')
  j<-fromJSON(r$raw_file);z<-as_tibble(j) |> mutate(financial_year=as.integer(year),entity_name_source=nom_parti,party_code_source=as.character(numero_parti),allocation_paid_cad=numeric_value(montant),year_context_source_id=page$source_id,year_context_snapshot_id=page$snapshot_id)
  add_table('party_public_funding',attach_context(z,r,'official_public_funding'),'parti × année',FALSE)
 }
 inv<-read_meta('metadata/financial_extraction_inventory.csv');cells<-read_meta('data/interim/financial/financial_source_cells.csv.gz')
 if(nrow(cells)) {
  # Extraction mécanique seulement. Les colonnes d’exercice/périmètre restent à valider.
  cells$value_numeric<-numeric_value(cells$value_numeric)
  add_table('financial_source_cells',cells,'document × page × ligne × cellule numérique',FALSE)
 }
 profiles<-read_meta('metadata/financial_profiles.csv')
 if(nrow(cells)&&nrow(profiles)) {
  current<-latest_manifest() |> select(source_id,raw_sha256=sha256)
  rules<-inner_join(profiles,current,by=c('source_id','raw_sha256'))
  approved<-inner_join(cells,rules,by=c('source_id','source_page','line_label_source','source_numeric_column')) |>
   mutate(value_cad=value_numeric,financial_year=numeric_value(financial_year),entity_scope_source='party_audited_2025; comparative 2024 excluded',data_status='official_financial_cell_visually_verified')
  for(n in unique(approved$table))add_table(n,approved |> filter(table==n) |> select(-table,-raw_sha256),'entité × année × poste comptable vérifié',FALSE)
 }
 reviewed<-read_meta('data/interim/financial/summary_2025_reviewed.csv')
 if(nrow(reviewed)) {
  rev<-read_meta('metadata/financial_summary_review.csv') |> select(review_hash,reviewed_entity_name=entity_name_source)
  reviewed<-left_join(reviewed,rev,by='review_hash') |> mutate(entity_name_source=reviewed_entity_name,entity_scope_source='party_and_instances; inter_entity_transfers_excluded') |> select(-reviewed_entity_name)
  amounts<-grep('_cad$',names(reviewed),value=TRUE);reviewed<-reviewed |> mutate(across(all_of(amounts),numeric_value),financial_year=numeric_value(financial_year))
  reviewed$report_status_source<-ifelse(reviewed$entity_name_source %in% c('Démocratie directe','Union nationale'),'report_not_produced','report_produced')
  add_table('party_finances_annual',reviewed,'parti et instances × année, récapitulation officielle',FALSE)
  inc<-reviewed |> pivot_longer(all_of(setdiff(amounts,'total_expenses_cad')),names_to='account_source',values_to='value_cad')
  add_table('party_finance_income_summary',inc,'parti et instances × année × poste de revenus, récapitulation',FALSE)
 }
}
