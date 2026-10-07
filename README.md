# Données bleues : élections provinciales québécoises

Dépôt autonome consacré aux données électorales officielles du Québec. La première version suit l’élection générale du 5 octobre 2026 et prépare l’archivage des résultats. Elle comprend des archives électorales, des résultats par bureau, les cartes, le financement et des compilations démographiques.

État documentaire initial : 3 octobre 2026. Inventaire actuel : 737 sources identifiées, 542 sources récupérées. 29 tables publiques et 26 tables locales produites. Les captures et mises à jour peuvent faire évoluer ces nombres.

## Sources et droits

Les [données ouvertes](https://www.dgeq.org/donnees.html), leurs [archives](https://www.dgeq.org/archives.html) et leur [documentation](https://www.dgeq.org/documentation.html) constituent la source primaire. Les autres pages et documents proviennent d’Élections Québec et de l’Assemblée nationale. Les compléments ISQ, Statistique Canada et Données Québec sont inventoriés séparément. Les routes JSON supplémentaires sont celles réellement utilisées dans le JavaScript public des pages historiques.

Les conditions varient par fichier. Les adaptations financières, démographiques et certaines archives supplémentaires sont reconstructibles localement et exclues de Git, car leurs droits d’adaptation publique ne sont pas confirmés. Lire [DATA_LICENSES.md](DATA_LICENSES.md), le [catalogue des sources](metadata/source_catalog.csv) et la [couverture détaillée](docs/coverage.md).

Comprend des données ouvertes octroyées sous la licence d’utilisation des données ouvertes du directeur général des élections disponible à l’adresse Web dgeq.org. L’octroi de la licence n’implique aucune approbation par le directeur général des élections de l’utilisation des données ouvertes qui en est faite.

## Tables produites

Une ligne de table peut représenter une observation à une capture donnée. Utiliser `R/read_tables.R` pour sélectionner la dernière capture par événement et source. Les CSV importants sont comprimés en gzip, lisibles directement avec readr ou pandas. Les copies pédagogiques sont sous `data/processed/teaching`.

| Table | Grain | Période | Source | Format | Mise à jour | Lignes | Accès |
|---|---|---|---|---|---|---:|---|
| `by_elections` | événement partiel × capture | voir catalogue des tables | Élections Québec; voir provenance | CSV UTF-8 | acquisition réussie | 17 | [fichier](data/processed/by_elections.csv) |
| `candidate_statistics` | tableau officiel × ligne × colonne source | voir source | Élections Québec; voir provenance | CSV UTF-8 | acquisition réussie | 456 | reconstruction locale |
| `candidates` | candidature à une élection | qc-prov-2026-10-05-general | Élections Québec; voir provenance | CSV UTF-8 | acquisition réussie | 5448 | [fichier](data/processed/candidates.csv) |
| `candidates_2012` | candidature officielle 2012 | qc-prov-2012-09-04-general | Élections Québec; voir provenance | CSV UTF-8 | acquisition réussie | 892 | [fichier](data/processed/candidates_2012.csv) |
| `district_crosswalk_2017_2026` | circonscription ancienne × nouvelle intersection dérivée | voir source | Élections Québec; voir provenance | CSV UTF-8 | acquisition réussie | 272 | [fichier](data/processed/district_crosswalk_2017_2026.csv) |
| `district_indicators` | élection × circonscription × capture | voir catalogue des tables | Élections Québec; voir provenance | CSV UTF-8 | acquisition réussie | 1414 | [fichier](data/processed/district_indicators.csv) |
| `district_map_changes_spatial` | ancienne × nouvelle circonscription, intersection dérivée | voir source | Élections Québec; voir provenance | CSV UTF-8 | acquisition réussie | 272 | [fichier](data/processed/district_map_changes_spatial.csv) |
| `election_calendar_2026` | événement officiel 2026 | qc-prov-2026-10-05-general | Élections Québec; voir provenance | CSV UTF-8 | acquisition réussie | 19 | [fichier](data/processed/election_calendar_2026.csv) |
| `elections` | élection × capture | voir catalogue des tables | Élections Québec; voir provenance | CSV UTF-8 | acquisition réussie | 32 | [fichier](data/processed/elections.csv) |
| `electoral_district_geometries` | circonscription × produit géométrique officiel | voir source | Élections Québec; voir provenance | CSV UTF-8 | acquisition réussie | 377 | [fichier](data/processed/electoral_district_geometries.csv) |
| `electoral_districts` | circonscription × carte × édition de codes | voir source | Élections Québec; voir provenance | CSV UTF-8 | acquisition réussie | 502 | [fichier](data/processed/electoral_districts.csv) |
| `financial_document_index` | document financier officiel | voir source | Élections Québec; voir provenance | CSV UTF-8 | acquisition réussie | 213 | reconstruction locale |
| `historical_candidate_results` | élection historique × candidature | voir catalogue des tables | Élections Québec; voir provenance | CSV UTF-8 | acquisition réussie | 3749 | [fichier](data/processed/historical_candidate_results.csv) |
| `historical_district_results` | élection historique × circonscription | voir catalogue des tables | Élections Québec; voir provenance | CSV UTF-8 | acquisition réussie | 525 | [fichier](data/processed/historical_district_results.csv) |
| `historical_party_results` | élection historique × parti | voir catalogue des tables | Élections Québec; voir provenance | CSV UTF-8 | acquisition réussie | 241 | [fichier](data/processed/historical_party_results.csv) |
| `historical_turnout` | élection historique × circonscription | voir catalogue des tables | Élections Québec; voir provenance | CSV UTF-8 | acquisition réussie | 525 | [fichier](data/processed/historical_turnout.csv) |
| `parties` | parti au registre × capture | voir source | Élections Québec; voir provenance | CSV UTF-8 | acquisition réussie | 120 | [fichier](data/processed/parties.csv) |
| `party_authorization_history` | autorisation officielle documentée × capture | voir source | Élections Québec; voir provenance | CSV UTF-8 | acquisition réussie | 120 | [fichier](data/processed/party_authorization_history.csv) |
| `party_officials` | parti × fonction publique × capture | voir source | Élections Québec; voir provenance | CSV UTF-8 | acquisition réussie | 360 | [fichier](data/processed/party_officials.csv) |
| `polling_candidate_links` | en-tête de candidature publié × circonscription × élection | voir catalogue des tables | Élections Québec; voir provenance | CSV UTF-8 | acquisition réussie | 3709 | [fichier](data/processed/polling_candidate_links.csv) |
| `polling_division_results` | élection × circonscription × unité publiée × candidature | voir catalogue des tables | Élections Québec; voir provenance | CSV UTF-8 gzip | acquisition réussie | 651327 | [fichier](data/processed/polling_division_results.csv.gz) |
| `polling_summary_fields` | fichier × ligne de total × champ source | voir catalogue des tables | Élections Québec; voir provenance | CSV UTF-8 | acquisition réussie | 14808 | [fichier](data/processed/polling_summary_fields.csv) |
| `polling_units` | élection × circonscription × unité publiée | voir catalogue des tables | Élections Québec; voir provenance | CSV UTF-8 | acquisition réussie | 91023 | [fichier](data/processed/polling_units.csv) |
| `registered_electors` | élection × circonscription × capture | qc-prov-2026-10-05-general | Élections Québec; voir provenance | CSV UTF-8 | acquisition réussie | 762 | [fichier](data/processed/registered_electors.csv) |
| `result_source_fields` | capture × entité × champ source | voir catalogue des tables | Élections Québec; voir provenance | CSV UTF-8 | acquisition réussie | 93457 | [fichier](data/processed/result_source_fields.csv) |
| `results_candidate` | élection × circonscription × candidature × capture | voir catalogue des tables | Élections Québec; voir provenance | CSV UTF-8 | acquisition réussie | 10105 | [fichier](data/processed/results_candidate.csv) |
| `results_candidate_2026` | candidature 2026 × capture | qc-prov-2026-10-05-general | Élections Québec; voir provenance | CSV UTF-8 | acquisition réussie | 6356 | [fichier](data/processed/results_candidate_2026.csv) |
| `results_party` | élection × parti × capture | voir catalogue des tables | Élections Québec; voir provenance | CSV UTF-8 | acquisition réussie | 388 | [fichier](data/processed/results_party.csv) |
| `results_party_2026` | parti 2026 × capture | qc-prov-2026-10-05-general | Élections Québec; voir provenance | CSV UTF-8 | acquisition réussie | 147 | [fichier](data/processed/results_party_2026.csv) |
| `turnout` | élection × circonscription × capture | voir catalogue des tables | Élections Québec; voir provenance | CSV UTF-8 | acquisition réussie | 1414 | [fichier](data/processed/turnout.csv) |
| `turnout_history` | élection historique × circonscription | voir catalogue des tables | Élections Québec; voir provenance | CSV UTF-8 | acquisition réussie | 525 | [fichier](data/processed/turnout_history.csv) |
| `turnout_preliminary_2026` | circonscription × capture | qc-prov-2026-10-05-general | Élections Québec; voir provenance | CSV UTF-8 | acquisition réussie | 254 | reconstruction locale |
| `assnat_historical_source_tables` | tableau officiel × ligne × colonne source | voir source | Assemblée nationale; voir provenance | CSV UTF-8 gzip | acquisition réussie | 110097 | reconstruction locale |
| `district_demographics` | territoire × variable du Recensement 2021 | voir source | Élections Québec; voir provenance | CSV UTF-8 gzip | acquisition réussie | 331776 | reconstruction locale |
| `district_map_changes` | carte historique officielle | voir source | Élections Québec; voir provenance | CSV UTF-8 | acquisition réussie | 13 | reconstruction locale |
| `election_expense_limits` | type d’élection × périmètre × période | voir source | Élections Québec; voir provenance | CSV UTF-8 | acquisition réussie | 18 | reconstruction locale |
| `finance_source_tables` | tableau officiel × ligne × colonne source | voir source | Élections Québec; voir provenance | CSV UTF-8 | acquisition réussie | 27 | reconstruction locale |
| `financial_source_cells` | document × page × ligne × cellule numérique | voir source | Élections Québec; voir provenance | CSV UTF-8 | acquisition réussie | 28618 | reconstruction locale |
| `legacy_election_source_tables` | tableau officiel × ligne × colonne source | voir source | Élections Québec; voir provenance | CSV UTF-8 | acquisition réussie | 70 | reconstruction locale |
| `legacy_elections` | élection historique × capture | voir catalogue des tables | Élections Québec; voir provenance | CSV UTF-8 | acquisition réussie | 65 | reconstruction locale |
| `legacy_historical_candidate_results` | élection historique × candidature source × capture | voir catalogue des tables | Élections Québec; voir provenance | CSV UTF-8 | acquisition réussie | 7527 | reconstruction locale |
| `legacy_historical_district_results` | élection historique × circonscription × capture | voir catalogue des tables | Élections Québec; voir provenance | CSV UTF-8 | acquisition réussie | 1442 | reconstruction locale |
| `legacy_historical_party_results` | élection historique × parti × capture | voir catalogue des tables | Élections Québec; voir provenance | CSV UTF-8 | acquisition réussie | 452 | reconstruction locale |
| `legacy_polling_division_results` | élection historique × unité × candidature source × capture | voir catalogue des tables | Élections Québec; voir provenance | CSV UTF-8 gzip | acquisition réussie | 491686 | reconstruction locale |
| `legacy_polling_units` | élection historique × unité publiée × capture | voir catalogue des tables | Élections Québec; voir provenance | CSV UTF-8 | acquisition réussie | 92549 | reconstruction locale |
| `party_balance_sheet` | entité × année × poste comptable vérifié | voir source | Élections Québec; voir provenance | CSV UTF-8 | acquisition réussie | 9 | reconstruction locale |
| `party_cashflows` | entité × année × poste comptable vérifié | voir source | Élections Québec; voir provenance | CSV UTF-8 | acquisition réussie | 15 | reconstruction locale |
| `party_finance_expenses` | entité × année × poste comptable vérifié | voir source | Élections Québec; voir provenance | CSV UTF-8 | acquisition réussie | 5 | reconstruction locale |
| `party_finance_income` | entité × année × poste comptable vérifié | voir source | Élections Québec; voir provenance | CSV UTF-8 | acquisition réussie | 1 | reconstruction locale |
| `party_finance_income_summary` | parti et instances × année × poste de revenus, récapitulation | voir source | Élections Québec; voir provenance | CSV UTF-8 | acquisition réussie | 154 | reconstruction locale |
| `party_finances_annual` | parti et instances × année, récapitulation officielle | voir source | Élections Québec; voir provenance | CSV UTF-8 | acquisition réussie | 22 | reconstruction locale |
| `party_public_funding` | parti × année | voir source | Élections Québec; voir provenance | CSV UTF-8 | acquisition réussie | 17 | reconstruction locale |
| `political_contributions_aggregated` | type et entité × événement × année | voir source | Élections Québec; voir provenance | CSV UTF-8 | acquisition réussie | 211 | reconstruction locale |
| `political_contributions_city` | type et entité × événement × année × ville | voir source | Élections Québec; voir provenance | CSV UTF-8 | acquisition réussie | 6113 | reconstruction locale |
| `turnout_history_source` | tableau officiel × ligne × colonne source | voir source | Élections Québec; voir provenance | CSV UTF-8 | acquisition réussie | 355 | reconstruction locale |

Les géométries officielles sont également diffusées en GeoPackage et en GeoJSON simplifié sous `data/processed/geography`. Le dictionnaire couvre les tables canoniques; les copies pédagogiques gardent les mêmes colonnes et définitions.

## Reconstruire

R 4.5.0, dépendances dans `renv.lock`, Python 3 et bibliothèques système GIS. Poppler et Tesseract français servent aux documents financiers locaux.

```r
install.packages("renv")
renv::restore()
```

```sh
make all
make test
```

La [documentation de reproduction](docs/reproducibility.md) décrit le cache, la reconstruction hors ligne et les dépendances. Les nouvelles consultations ne reconstituent pas les anciennes captures perdues.

## Exemple R

Exécuter depuis la racine du dépôt.

```r
library(readr)
library(dplyr)
library(ggplot2)
source("R/read_tables.R")

candidates <- read_electoral_table("candidates")
counts <- candidates |> count(district_id, name = "n_candidates")
ggplot(counts, aes(n_candidates)) +
  geom_histogram(binwidth = 1, boundary = .5) +
  labs(x = "Nombre de candidatures", y = "Circonscriptions") +
  theme_minimal()
```

Les [exemples complets](examples) couvrent participation historique, géographie avec sf et données locales.

## Exemple Python

```python
import pandas as pd
import geopandas as gpd

candidates = pd.read_csv("data/processed/candidates.csv", encoding="utf-8")
latest = candidates.groupby("source_id")["observed_at"].transform("max")
candidates = candidates.loc[candidates["observed_at"].eq(latest)]
counts = candidates.groupby("district_id").size().rename("n_candidates")
map_qc = gpd.read_file("data/processed/geography/districts_2026.gpkg")
joined = map_qc.merge(counts, on="district_id", validate="one_to_one")
print(joined[["district_id", "n_candidates"]].head())
```

## Actualisation et résultats 2026

Le workflow prévoit une acquisition quotidienne avant le scrutin, des captures toutes les quinze minutes pendant la fenêtre du dépouillement et une fréquence hebdomadaire ensuite. Les captures fréquentes cessent dès que la dernière capture est explicitement finale. Les horaires GitHub ne garantissent pas une cadence exacte. Les captures de résultats sont immuables sous `data/snapshots/results_2026`. Le récupérateur refuse les URLs de simulation avant l’ouverture officielle du 5 octobre à 20 h, America/Toronto.

Aucune donnée fictive de résultats 2026 n’est diffusée avant publication. Le statut final vient uniquement d’un indicateur officiel explicite. Un taux de bureaux renseignés de 100 % ne suffit pas. Le taux provincial extrapolé du producteur reste un champ source distinct du taux observé. Aucune projection ni recommandation électorale n’est produite.

## Qualité, provenance et limites

Les contrôles portent sur les identifiants, les captures, les sommes de votes, les bulletins, les ratios, les dates, les fractions spatiales et les chemins de diffusion. Le [dernier rapport](metadata/validation_latest.csv) décrit leur état; le [journal](metadata/quality_report.csv) conserve aussi les erreurs rencontrées pendant les lectures initiales. Les [résolutions](metadata/quality_resolutions.csv) distinguent les problèmes corrigés des points encore ouverts.

Chaque observation porte `source_id`, `snapshot_id`, `observed_at`, `retrieved_at`, `source_updated_at` et `data_status`. Le [dictionnaire](metadata/data_dictionary.csv), la [provenance](metadata/provenance.csv) et le [manifeste](metadata/acquisition_manifest.csv) relient tables, variables, captures, octets sources et scripts.

Les en-têtes de bureaux sans lien exact restent non résolus. Une intersection territoriale ne répartit ni personnes ni votes. Les totaux annuels personne-entité des contributions ne sont pas des versements individuels, et leur date de campagne n’est pas une date de don. Les bilans, flux et dépenses issus des autres PDF gardent une couverture de validation partielle. Les rapports préélectoraux 2026 ne sont pas encore disponibles dans la source consultée.

L’inventaire est systématique sur les index explorés et extensible; il ne prouve pas l’exhaustivité absolue de toutes les institutions. Les ressources inventoriées ne sont pas toutes téléchargées ni toutes normalisées. Le [modèle](docs/data_model.md) et la [politique de minimisation](docs/privacy.md) explicitent les choix.

## Enseignement et contribution

[Trente activités pédagogiques](docs/teaching_ideas.md) précisent niveaux, questions, tables et pièges. Lire [CONTRIBUTING.md](CONTRIBUTING.md) et [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md). Le code est sous MIT; les données gardent leurs droits propres. Utiliser `CITATION.cff` et citer chaque producteur officiel ainsi que la capture utilisée.
