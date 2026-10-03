# Couverture et limites de disponibilité

Inventaire établi par lecture des index officiels, des liens de fichiers et des routes effectivement utilisées dans le JavaScript public d’Élections Québec, le 3 octobre 2026. Il décrit les sources identifiées dans le périmètre provincial. Il ne prouve pas l’exhaustivité absolue de tous les documents de toutes les institutions. Les fichiers découverts sans lecteur validé restent explicitement à intégrer.

| Dimension | Traitement | Limites |
|---|---|---|
| Candidatures 2026 | JSON, 908 candidatures et 127 territoires vérifiés | Pas d’âge ou de sexe inféré; rectifications futures doivent être revues |
| Partis et responsables | JSON REPAQ courant, autorisations et fonctions publiques utiles | La liste courante ne reconstitue pas toutes les dates de retrait historiques |
| Carte 2026 | Liste, Shapefile, GeoPackage et GeoJSON simplifié; intersections avec carte utilisée en 2022 | Version établie en juin 2026 à distinguer de la proposition antérieure; fractions de superficie seulement |
| Démographie | Compilation officielle du Recensement 2021 pour les 127 territoires et la province | Adaptation locale; unités et symboles de suppression conservés |
| Inscrits 2026 | Décret et révisions disponibles | Le fichier exclut les électeurs en détention et hors Québec selon sa documentation; ne pas en déduire un plafond juridique |
| Participation préliminaire | CSV et captures locales successives | Taux seuls dans le CSV; pas de nombre de votants reconstitué; heure annoncée sur la page distincte de la capture |
| Résultats récents et bureaux | JSON/ZIP ouverts et lecteur spécifique 2012 | Appariements d’en-têtes conservateurs, pas de rapprochement approximatif |
| Historique supplémentaire | JSON chargés par les pages officielles et tableaux de l’Assemblée nationale, récupérés et transformés localement | Droits distincts, numéros administratifs souvent absents, finalité non renseignée dans certains fichiers, élections sans vote numérique possibles |
| Bureaux 1998-2008 | XLS et texte tabulé, lecteur par blocs et feuilles | Droits d’adaptation non confirmés; pas de géométrie attribuée automatiquement |
| Finances annuelles | Rapports 2019-2025, extraction numérique locale, sommaire 2025 vérifié visuellement | Les autres tableaux de revenus, dépenses, bilans et flux nécessitent encore une vérification de leur exercice et de leur périmètre |
| Bilans et flux | Profils de lecture liés aux empreintes, exemple vérifié sur un rapport 2025 | Couverture partielle; ne pas présenter le corpus complet comme normalisé et validé |
| Contributions | Totaux annuels personne-entité, agrégations locales et suppression de petites cellules | Aucune date mensuelle de versement disponible dans ce fichier; pas de distribution des versements individuels |
| Financement public et limites | Tableaux provinciaux récupérés et transformés localement | Taux et allocations distincts; pas de plafond calculé à partir d’inscrits incomplets |
| Dépenses électorales | Sommaires PDF récupérés et cellules sources extraites localement | Catégories numériques non encore toutes validées; les rapports individuels peuvent nécessiter une demande d’accès |
| Dépenses préélectorales 2026 | Page officielle inventoriée et surveillable | Aucun rapport disponible au 3 octobre 2026 |
| Résultats et bureaux 2026 | Récupérateur et archivage préparés | Observations créées seulement à la publication officielle; aucun CSV fictif |
| Calendrier | Événements transcrits du calendrier DGE-5 (26-07), page vérifiée | Dates de proclamation non inventées |
| Histoire des personnes | Candidatures contextualisées | Aucun identifiant de personne entre élections, faute de clé officielle fiable |
| Modes de vote | Libellés et regroupements originaux conservés lorsqu’ils existent | Pas de modalité attribuée par conjecture |
| Sources complémentaires | ISQ, Statistique Canada, Données Québec, Assemblée nationale et atlas historiques inventoriés | Licence et périmètre de chaque ressource à contrôler avant adaptation publique |

Les états à suivre sont la récupération, l’extraction, la validation et la publication. Un fichier téléchargé n’est pas une table validée. Une table locale validée n’est pas une adaptation librement redistribuable. Les erreurs historiques des premières lectures restent dans le journal, avec leurs résolutions documentées.

Le JSON officiel de 1973 présente un écart de dix bulletins entre les votes exprimés et la somme des bulletins valides et rejetés, dans Terrebonne et dans le total provincial. Les valeurs restent inchangées. Les deux exceptions figurent dans `metadata/known_source_issues.csv` et ne s’appliquent qu’à l’empreinte exacte du fichier contrôlé. Toute nouvelle incohérence demeure bloquante.
