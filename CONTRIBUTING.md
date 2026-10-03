# Contribuer

Utiliser R pour les transformations et les métadonnées communes. Proposer une modification documentée par demande de fusion.

1. Identifier une URL réellement publiée dans un index officiel et documenter son périmètre provincial dans `metadata/source_catalog.csv`.
2. Vérifier la licence du fichier, les données personnelles présentes et les droits d’adaptation avant de choisir une sortie publique.
3. Ajouter l’extracteur et préserver les champs originaux utiles, les valeurs manquantes et les horodatages. Les bruts restent immuables, identifiés par SHA-256.
4. Exécuter `make offline` avec le cache local ou `make all`, puis `make test`. Documenter toute variation de schéma ou incohérence officielle dans le rapport de qualité.
5. Examiner les fichiers effectivement suivis avant de publier. Aucun fichier nominatif de contributions, coordonnées personnelles, brut ou sortie `local_only` ne doit entrer dans Git.

Un nom de personne ne suffit pas à relier des candidatures entre élections. Un nom de circonscription ne suffit pas à relier des territoires. Toute jointure incertaine doit rester explicitement non résolue.

Les nouvelles données financières extraites mécaniquement restent à vérifier. Une reconnaissance optique n’est pas une validation comptable. Toute règle validée est liée à un checksum et à une page du document.

Pour signaler un défaut, fournir la source, la capture, la table et la règle concernées, sans copier des renseignements personnels.
