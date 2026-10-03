# Banque d’activités

Les tables `local_only` exigent une reconstruction et ne doivent pas être redistribuées comme adaptations sans clarification des droits. Les activités marquées « futur » deviennent exécutables lorsque le producteur publie les fichiers. Aucune activité ne cherche à déduire un vote individuel.

| Activité | Niveau et notions | Tables | Question | Piège d’interprétation |
|---|---|---|---|---|
| 1. Distribution de la participation | Introduction; histogramme, quantiles | historical_turnout | Quelle dispersion entre circonscriptions d’un scrutin ? | Définition et périmètre des inscrits |
| 2. Participation et taille | Introduction; nuage de points, pondération | turnout | Le taux varie-t-il avec le nombre d’inscrits ? | Association agrégée, pas causalité |
| 3. Moyenne des taux ou taux global | Introduction; moyennes pondérées | historical_turnout | Pourquoi deux résumés provinciaux diffèrent-ils ? | Moyenne simple des taux ne vaut pas ratio des sommes |
| 4. Bulletins rejetés | Introduction; proportions | polling_units | Comment varie le taux de rejet dans une élection ? | Dénominateur : votes exprimés, pas bulletins valides |
| 5. Marges électorales | Intermédiaire; statistiques d’ordre | district_indicators | Quelle est la distribution des écarts entre deux premiers ? | Marge descriptive, sans classement normatif |
| 6. Nombre de candidatures | Introduction; données de comptage | candidates | Combien de candidatures par territoire ? | Une candidature n’est pas un identifiant permanent de personne |
| 7. Couverture des partis | Introduction; tables de contingence | candidates | Quel est le nombre de territoires avec candidature par groupe ? | Code de parti contextualisé, indépendants regroupés selon source |
| 8. Fragmentation descriptive | Intermédiaire; parts, concentration | district_indicators, results_candidate | Comment varie 1/somme(p²) ? | Dépend du regroupement officiel des indépendants |
| 9. Participation historique | Introduction; séries temporelles | historical_turnout, legacy_elections locale | Comment évolue le ratio provincial ? | Couverture inégale et dates d’observation distinctes |
| 10. Comparaisons entre scrutins | Intermédiaire; appariements | historical_candidate_results | Quels territoires ont réellement la même délimitation ? | Noms identiques ne suffisent pas |
| 11. Changement de carte | Avancé; géométrie, intersections | district_crosswalk_2017_2026 | Combien d’anciens territoires recouvrent un nouveau ? | Surface ne représente ni population ni vote |
| 12. Résultats hiérarchiques | Avancé; modèles multiniveaux descriptifs | polling_division_results, polling_units | Quelle part de variation des proportions se situe entre territoires ? | Regroupements d’urnes et modalités ne sont pas des sections uniformes |
| 13. Choroplèthes | Intermédiaire; sf, sémiologie | geography, turnout | Comment les choix de classes changent-ils la lecture ? | Grandes superficies visuellement dominantes |
| 14. Snapshots du dépouillement, futur | Intermédiaire; séries irrégulières | results_candidate_2026, snapshots | Comment progresse le nombre de bureaux renseignés ? | Arrivée des bureaux non aléatoire; aucune projection |
| 15. Savoir à quel moment, futur | Avancé; données bitemporelles | snapshots, acquisition_manifest | Que savait-on lors d’une capture donnée ? | observed_at ne désigne pas l’heure de mise à jour source |
| 16. Nettoyer du JSON | Intermédiaire; listes, types | bruts récupérés, result_source_fields | Comment passer d’un objet imbriqué à plusieurs tables ? | Ne pas recycler une statistique extrapolée comme taux observé |
| 17. Base relationnelle | Intermédiaire; clés et jointures | elections, electoral_districts, candidates | Quelles jointures produisent une multiplication des lignes ? | Captures multiples et éditions de codes |
| 18. Contributions annuelles | Intermédiaire; sommes, médianes, quantiles | political_contributions_aggregated locale | Quelle est la distribution des totaux annuels personne-entité ? | Ce ne sont pas les montants de versements individuels |
| 19. Contributions par ville | Avancé; cellules supprimées | political_contributions_city locale | Comment le seuil de diffusion modifie-t-il la couverture ? | Les cellules omises ne sont pas des zéros; aucune réidentification |
| 20. Financement public | Introduction; montants nominaux | party_public_funding locale | Comment vérifier le total provincial d’allocations ? | Année et catégorie de financement exactes; pas d’inflation corrigée implicitement |
| 21. Rapports financiers | Avancé; comptabilité et qualité | party_finances_annual locale | Pourquoi le sommaire et les comptes du parti diffèrent-ils ? | Instances, transferts et arrondis changent le périmètre |
| 22. OCR et validation | Avancé; extraction, erreurs de mesure | financial_source_cells locale, financial_summary_review | Quels chiffres une reconnaissance optique déforme-t-elle ? | Accord automatique ne remplace pas la lecture du PDF |
| 23. Dépenses et plafonds | Intermédiaire; dénominateurs | election_expense_limits locale, financial_source_cells locale | Quels taux s’appliquent à quel périmètre ? | Ne pas calculer un plafond légal avec un fichier d’inscrits incomplet |
| 24. Démographie agrégée | Avancé; données longues et régression descriptive | district_demographics locale | Quelles variables sont comparables entre territoires 2026 ? | Compilation officielle 2021, unités, suppressions et temporalité |
| 25. Inférence écologique | Avancé; identification, exemples mathématiques | turnout, démographie locale | Pourquoi une association territoriale ne permet-elle pas une conclusion individuelle ? | Éviter de reconstruire des comportements personnels |
| 26. Valeurs manquantes | Introduction; mécanismes de manque | party_finances_annual, legacy_historical_candidate_results locales | Que signifie un rapport non produit ou une élection sans vote numérique ? | Ne pas remplacer automatiquement par zéro |
| 27. Calendrier | Introduction; dates, intervalles | election_calendar_2026 | Combien de jours séparent les jalons officiels ? | Heures locales et heures UTC |
| 28. Reproductibilité | Intermédiaire; Git, checksums, environnement | métadonnées, pipeline | Peut-on reconstruire les mêmes valeurs à partir des mêmes octets ? | Une récupération nouvelle n’est pas une capture ancienne |
| 29. Audit des jointures | Avancé; appariement conservateur | polling_division_results | Quels en-têtes restent sans lien exact ? | Ne pas résoudre par un simple nom proche |
| 30. Qualité officielle | Intermédiaire; réconciliation | quality_report, validation_latest | Comment documenter une incohérence sans la corriger silencieusement ? | Distinguer erreur du lecteur et incohérence de la source |
