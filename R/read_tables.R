# Charger une table publiée et rétablir ses types à partir du dictionnaire.
read_electoral_table <- function(name, latest = TRUE, directory = '.') {
 library(readr); library(dplyr)
 catalog <- read_csv(file.path(directory,'metadata/table_catalog.csv'),show_col_types=FALSE)
 dictionary <- read_csv(file.path(directory,'metadata/data_dictionary.csv'),show_col_types=FALSE)
 row <- filter(catalog,table==name)
 if(nrow(row)!=1L||!file.exists(file.path(directory,row$path)))stop('Table absente ou réservée à une reconstruction locale : ',name)
 x <- read_csv(file.path(directory,row$path),col_types=cols(.default=col_character()),na=c('NA',''),show_col_types=FALSE)
 d <- filter(dictionary,table==name)
 for(v in intersect(names(x),d$variable)) {
  type<-d$type[match(v,d$variable)]
  if(type %in% c('numeric','integer','double'))x[[v]]<-as.numeric(x[[v]])
  else if(type=='logical')x[[v]]<-as.logical(x[[v]])
 }
 if(latest && 'observed_at' %in% names(x)) {
  # Chaque source a sa propre chronologie; ne pas jeter un événement historique.
  keys<-intersect(c('election_id','source_id'),names(x))
  if(length(keys))x<-x |> group_by(across(all_of(keys))) |> filter(observed_at==max(observed_at)) |> ungroup()
 }
 x
}
