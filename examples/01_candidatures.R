# Exécuter depuis la racine du dépôt.
library(readr)
library(dplyr)
library(ggplot2)
source('R/read_tables.R')
candidates <- read_electoral_table('candidates')
districts <- read_electoral_table('electoral_districts') |>
 filter(code_edition=='2026') |>
 distinct(district_id,district_name)
counts <- candidates |>
 count(district_id,name='n_candidates') |>
 left_join(districts,by='district_id')
stopifnot(sum(counts$n_candidates)==nrow(candidates),!anyNA(counts$district_name))
print(counts)
plot <- ggplot(counts,aes(x=n_candidates)) +
 geom_histogram(binwidth=1,boundary=.5,fill='#227ca8',color='white') +
 labs(x='Nombre de candidatures',y='Circonscriptions',title='Candidatures provinciales, capture 2026') +
 theme_minimal()
print(plot)
