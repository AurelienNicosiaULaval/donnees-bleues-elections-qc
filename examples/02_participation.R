library(readr)
library(dplyr)
library(ggplot2)
source('R/read_tables.R')
x <- read_electoral_table('historical_turnout') |>
 filter(grepl('general$',election_id))
series <- x |>
 group_by(election_id) |>
 summarise(registered=sum(registered),votes_cast=sum(votes_cast),.groups='drop') |>
 mutate(date=as.Date(sub('qc-prov-([0-9-]+)-general','\\1',election_id)),
        turnout_pct=100*votes_cast/registered)
print(series)
print(ggplot(series,aes(date,turnout_pct)) + geom_line() + geom_point() +
 labs(x='Scrutin',y='Participation recalculée (%)',caption='Somme des votes exprimés divisée par somme des inscrits; périmètre des fichiers officiels.') + theme_minimal())
