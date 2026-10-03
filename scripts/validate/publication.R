source('R/common.R')
tracked<-system2('git',c('ls-files'),stdout=TRUE)
stopifnot(!any(grepl('(^data/(raw|external|interim)/|^data/processed/local_only/|logs_|[.]tmp$)',tracked)))
stopifnot(!any(grepl('contributions-pro-fr[.]csv',tracked)))
catalog<-read_meta('metadata/table_catalog.csv');public<-filter(catalog,visibility=='public')
sources<-load_catalog()
for(i in seq_len(nrow(public))) {
 ids<-strsplit(public$source[i],';',fixed=TRUE)[[1]]
 stopifnot(all(sources$derived_publication[match(ids,sources$source_id)]=='public'))
}
message('Diffusion : chemins et licences vérifiés.')
