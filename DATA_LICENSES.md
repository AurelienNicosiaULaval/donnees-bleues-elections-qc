# Droits par source

Le code est sous MIT (`LICENSE-CODE`). Les données ne reçoivent pas cette licence. Les droits sont décrits source par source dans `metadata/source_catalog.csv` : titulaire (`organisme`), licence, URL des conditions, redistribution, publication des adaptations et restrictions (`notes`). Cet inventaire est l’autorité pour chaque fichier, plutôt qu’une licence commune présumée.

| Famille | Titulaire | Conditions vérifiées le 3 octobre 2026 | Diffusion dans ce dépôt |
|---|---|---|---|
| Fichiers référencés sur dgeq.org, dont candidatures, REPAQ, résultats, électeurs, archives et certains fichiers GIS | Directeur général des élections | [Licence des données ouvertes](https://www.dgeq.org/licence.html), reproduction, compilation, adaptation et publication sous conditions d’attribution | Tables et géométries produites à partir de ces seuls fichiers |
| Pages Élections Québec, rapports financiers, contributions, compilation démographique, statistiques et autres documents hors des liens couverts par dgeq.org | Directeur général des élections | [Conditions d’utilisation](https://www.electionsquebec.qc.ca/notre-institution/conditions-dutilisation/), reproduction non commerciale avec attribution; adaptation nécessitant une autorisation | Scripts de récupération et métadonnées publics; tables adaptées locales et ignorées par Git |
| Assemblée nationale, ISQ, Statistique Canada et Données Québec | Producteur indiqué pour chaque source | Licence du fichier à vérifier individuellement; l’accès public ne vaut pas autorisation de redistribution | Inventaire et mécanismes d’accès; pas d’adaptation diffusée tant que les droits ne sont pas confirmés |
| Sources non officielles | Titulaires respectifs | Aucun fichier intégré dans cette version | Dossier `external` réservé et ignoré |

La licence dgeq.org couvre les fichiers vers lesquels ce site dirige effectivement. Le nom de domaine `donnees.electionsquebec.qc.ca` seul ne suffit pas à établir la licence. Les restrictions d’un autre producteur ne sont pas remplacées par cette licence.

Mention requise pour les données ouvertes :

> Comprend des données ouvertes octroyées sous la licence d’utilisation des données ouvertes du directeur général des élections disponible à l’adresse Web dgeq.org. L’octroi de la licence n’implique aucune approbation par le directeur général des élections de l’utilisation des données ouvertes qui en est faite.

Pour les originaux consultés hors de ce régime : source Élections Québec, © Directeur général des élections, année indiquée dans le document. Les scripts ne transmettent pas les adaptations locales vers GitHub. Une autorisation écrite ou une clarification explicite de licence sera nécessaire pour modifier leur visibilité.

Le fichier nominatif des contributions reste local même si ses droits deviennent plus permissifs. Une agrégation ne suffit pas, à elle seule, à régler les droits d’adaptation. Les cellules par ville de moins de cinq lignes annuelles personne-entité sont omises; cette règle n’est pas présentée comme une garantie générale d’anonymat.
