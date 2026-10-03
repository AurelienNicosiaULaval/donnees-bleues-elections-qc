# Reconstruire et actualiser

## Environnement

R 4.5.0 et versions des bibliothèques dans `renv.lock`. Python 3 n’utilise que sa bibliothèque standard pour télécharger et extraire les archives. Les exemples Python utilisent pandas et geopandas, indiqués dans `python/requirements.txt`.

```r
install.packages("renv")
renv::restore()
```

Pour la récupération et les analyses géographiques, prévoir les bibliothèques système habituelles de sf (GDAL, GEOS, PROJ, udunits). Les extractions de documents financiers utilisent Poppler (`pdftotext`, `pdftoppm`) et Tesseract avec la langue française. Leur absence est signalée; les PDF restent récupérables et les valeurs OCR ne deviennent jamais des valeurs vérifiées.

## Commandes

```sh
make all       # récupérer les sources activées et reconstruire toutes les tables
make offline   # reconstruire exclusivement à partir des bruts locaux
make test      # contrôles indépendants et tests de fixtures
make update    # nouvelle capture des sources courantes
make results   # capture ciblée du résultat 2026, après ouverture officielle
make weekly    # veille des index, nouvelles archives ouvertes et rapports locaux
make discover  # relire les index, ajouter les liens réellement publiés
make finances  # extraire les cellules financières numériques, localement
```

Les fichiers `data/processed` peuvent être retirés puis reconstruits par `make all` avec le réseau et les dépendances disponibles, ou par `make offline` avec un cache complet. Les anciennes captures indisponibles chez le producteur ne peuvent pas être recréées par une récupération nouvelle. Leur manifeste et leurs empreintes permettent de distinguer ces situations.

Les bruts se trouvent sous `data/raw/<source_id>/<sha256>.<format>`. Les octets sont immuables. Une consultation ajoute une capture et un instant UTC. La réutilisation du cache n’ajoute pas de capture. Les transformations ne réécrivent pas les valeurs sources.

Une reconstruction hors ligne depuis les mêmes captures doit reproduire les valeurs et identifiants. Les journaux de validation ont un nouvel instant d’exécution; les fichiers GIS peuvent avoir des métadonnées internes différentes. Il faut comparer les données, plutôt que les seuls octets d’un GeoPackage ou du journal.

Pour vérifier les contenus, exécuter `python3 scripts/validate/rebuild_hashes.py --record /tmp/elections-baseline.json` avant de retirer `data/processed`, puis reconstruire et exécuter `python3 scripts/validate/rebuild_hashes.py --compare /tmp/elections-baseline.json`. Ce contrôle compare les CSV décomprimés et les GeoJSON. Les GeoPackage sont contrôlés séparément par les tests géographiques. Le résultat figure dans `metadata/reproducibility_check.csv`.

## Automatisation

La validation publique s’exécute sur les modifications et les demandes de fusion. L’acquisition utilise une seule exécution à la fois et des requêtes espacées de 0,75 seconde. Les échecs HTTP, les changements de schéma et les erreurs de lecture sont consignés.

Le workflow d’acquisition est quotidien avant le scrutin et pendant la semaine qui suit. Il prévoit une capture toutes les quinze minutes de 00 h à 06 h UTC le 6 octobre 2026, soit à partir de 20 h locale le 5 octobre. GitHub Actions peut retarder ou omettre une exécution planifiée; ce dispositif n’est pas une garantie de capture toutes les quinze minutes. L’horaire annuel est neutralisé par une vérification de la date 2026.

Après cette période, la mise à jour est hebdomadaire. Une exécution manuelle permet de sélectionner le mode. Le statut final doit toujours venir du producteur. Une capture à 100 % de bureaux renseignés peut rester préliminaire.

Les captures fréquentes planifiées s’arrêtent dès que la dernière capture annonce explicitement la finalité. Les modes quotidien et hebdomadaire cessent alors de récupérer le flux de dépouillement, tout en poursuivant les autres sources. Le mode manuel `results` permet une vérification supplémentaire. La veille hebdomadaire active les nouveaux PDF financiers pour extraction locale et les nouvelles archives ouvertes reconnues dans les liens du producteur; un format inconnu reste à intégrer après examen.

Le fichier mutable des candidatures doit toujours annoncer l’événement officiel 1126. Un autre événement déclenche une erreur afin d’éviter de l’étiqueter comme un scrutin de 2026. L’année des allocations provinciales est lue dans le titre de la page officielle, consultée le même jour que son JSON.

Les premières URLs de résultats peuvent servir à des simulations avant le scrutin. Le récupérateur refuse de les intégrer avant le 5 octobre 2026 à 20 h, America/Toronto. Les fixtures de tests sont temporaires et ne sont jamais des observations.

## Contrôles avant diffusion

Les commandes échouent sur les violations des règles comptables vérifiables et des clés. Les avertissements d’appariement sont conservés. Le workflow vérifie les chemins suivis et la licence de chaque source contribuant à une table publique. Le dossier `local_only`, les bruts, les documents intermédiaires et le fichier nominatif des contributions sont ignorés par Git.

Sur une copie propre, les tests publics vérifient les tables diffusées et les fixtures. Le test des empreintes de bruts est explicitement ignoré si aucun brut local n’est présent, plutôt que présenté comme effectué.
