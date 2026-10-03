# Après make all : les adaptations suivantes restent locales pour les droits actuels.
library(readr)
library(dplyr)
source('R/read_tables.R')
demographics <- read_electoral_table('district_demographics')
variables <- demographics |> distinct(variable_code_source,variable_label_source,unit)
print(variables)
# Sélectionner un code effectivement présent; éviter une jointure massive de toutes les variables.
selected_code <- variables$variable_code_source[1]
print(demographics |> filter(variable_code_source==selected_code) |>
 select(district_id,variable_label_source,value_source,value_numeric,unit))
contributions <- read_electoral_table('political_contributions_aggregated')
print(contributions |> filter(entity_type_source=='Parti') |>
 select(entity_name_source,year,contributor_entity_records,contributions_count,total_amount))
