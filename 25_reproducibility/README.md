============================================================
MODULE 25 — REPRODUCTIBILITÉ : CONTENEURS, GIT ET GITHUB
============================================================

OBJECTIVE
------------------------------------------------------------
Compléter les piliers de la reproductibilité scientifique déjà entamés
avec Conda (module 06) : figer l'environnement système complet avec des
conteneurs (Docker/Apptainer), et versionner le code avec Git/GitHub pour
la collaboration et la traçabilité.

PREREQUISITES
------------------------------------------------------------
`06_environment_management/`, `24_workflows/`.

WHY?
------------------------------------------------------------
Un environnement Conda fige les VERSIONS de logiciels, mais dépend encore
du système d'exploitation hôte. Un conteneur va plus loin : il fige
l'intégralité de l'environnement d'exécution (bibliothèques système,
dépendances de bas niveau), garantissant qu'un pipeline s'exécute à
l'identique sur n'importe quelle machine hôte compatible — condition
souvent requise pour publier une analyse reproductible ou l'exécuter sur
un cluster HPC partagé (module 26).

---

# 1. Conteneurs — Docker

```text
COMMAND: docker
PURPOSE: créer, distribuer et exécuter des conteneurs — environnements
         isolés et reproductibles définis par un fichier texte
         (Dockerfile), décrivant précisément chaque dépendance installée.
SYNTAX: docker pull nom_image:tag           (récupérer une image existante)
        docker run -v $(pwd):/data image commande    (exécuter, en montant
                                                         le dossier courant)
DOCUMENTATION: https://docs.docker.com/ (documentation officielle complète)
COMMON ERRORS: oublier de monter (-v) le dossier contenant les données —
         le conteneur ne voit alors que son propre système de fichiers
         interne, isolé de l'hôte par conception.
```

```text
CONCEPT (Dockerfile) : un Dockerfile décrit, ligne par ligne, comment
         construire une image reproductible :
```
```dockerfile
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y samtools=1.17-1
COPY script_pipeline.sh /usr/local/bin/
ENTRYPOINT ["script_pipeline.sh"]
```
```text
INTERPRETATION: figer la version exacte des paquets installés (samtools=1.17-1
         ci-dessus) est ce qui rend l'image réellement reproductible dans
         le temps — une image qui installe "la dernière version
         disponible" au moment du build n'offre pas la même garantie
         plusieurs mois plus tard.
```

---

# 2. Conteneurs — Apptainer (anciennement Singularity)

```text
COMMAND: apptainer
PURPOSE: format de conteneur alternatif à Docker, largement préféré en
         environnement HPC (module 26) car il ne nécessite pas de
         privilèges administrateur pour l'exécution, contrairement à
         Docker par défaut — considération de sécurité importante sur un
         cluster partagé entre plusieurs utilisateurs.
SYNTAX: apptainer pull docker://nom_image:tag   (convertir une image
                                                    Docker existante)
        apptainer exec image.sif commande
DOCUMENTATION: https://apptainer.org/docs/ (documentation officielle) ·
         dépôt : https://github.com/apptainer/apptainer
CONTEXTE HISTORIQUE: Apptainer est l'ancien projet Singularity, renommé
         après son transfert à la Linux Foundation — même outil en
         continuité de développement, pas un remplacement par un tiers.
```

```text
QUAND CHOISIR QUOI: Docker est le standard le plus répandu pour le
         développement et le partage d'images (Docker Hub) ; Apptainer
         est généralement imposé par les environnements HPC pour des
         raisons de sécurité (module 26). Les images Docker restent
         utilisables via Apptainer (conversion directe), ce qui permet de
         développer sous Docker et déployer sous Apptainer sans tout
         reconstruire.
```

---

# 3. Git — versionner le code d'un projet bioinformatique

```text
COMMAND: git init / git status / git add / git commit
PURPOSE: suivre l'historique des modifications d'un projet (scripts,
         Snakefile/main.nf, documentation) — jamais les données brutes
         volumineuses (voir .gitignore, déjà en place dans ce dépôt,
         module 07).
SYNTAX: git init
        git add scripts/pipeline.sh
        git commit -m "Ajoute le script d'alignement"
        git log
        git diff
DOCUMENTATION: https://git-scm.com/doc (documentation officielle
         complète, incluant le livre Pro Git gratuit en ligne)
```

```text
COMMAND: git branch / git pull / git push
PURPOSE: travailler sur des branches parallèles (une fonctionnalité ou
         une expérience à la fois), et synchroniser avec un dépôt distant
         (GitHub) pour la collaboration.
SYNTAX: git branch nouvelle-analyse
        git checkout nouvelle-analyse
        git push origin nouvelle-analyse
```

```text
GIT COMME OUTIL DE REPRODUCTIBILITÉ SCIENTIFIQUE: référencer, dans un
         rapport ou une publication, le hash de commit exact utilisé pour
         produire un résultat (`git log -1 --format=%H`) permet à
         quiconque de retrouver l'état EXACT du code au moment de
         l'analyse — bien plus précis qu'un numéro de version informel.
```

---

TROUBLESHOOTING
------------------------------------------------------------
```text
SYMPTOM: "Permission denied" en essayant d'exécuter `docker run` sans
         `sudo`
CAUSE: sur de nombreux systèmes, l'exécution de Docker nécessite des
       privilèges administrateur ou l'appartenance au groupe `docker`.
DIAGNOSIS: vérifier l'appartenance au groupe docker (`groups`).
SOLUTION: soit s'ajouter au groupe docker (configuration système, hors
          périmètre bioinformatique), soit utiliser Apptainer qui ne
          nécessite pas ce privilège — considération pertinente en
          contexte HPC partagé (module 26).
PREVENTION: privilégier Apptainer d'emblée dans un contexte de cluster
            partagé multi-utilisateurs.
```
```text
SYMPTOM: un gros fichier de données a été accidentellement commité dans
         Git, gonflant l'historique du dépôt
CAUSE: absence d'un .gitignore couvrant ce type de fichier au moment du
       commit (voir module 07, .gitignore de ce dépôt).
DIAGNOSIS: `git log --stat` pour repérer le commit fautif.
SOLUTION: retirer le fichier de l'historique nécessite une réécriture
          d'historique (git filter-repo ou équivalent) — une opération
          délicate, à effectuer avec prudence et de préférence avant tout
          partage du dépôt.
PREVENTION: toujours vérifier `git status` avant un `git add` large, et
            maintenir un .gitignore à jour dès le début du projet.
```

GO FURTHER
------------------------------------------------------------
```text
Topic: conteneurs et versionnage
Official documentation:
  https://docs.docker.com/
  https://apptainer.org/docs/
  https://git-scm.com/doc
Topics to explore: intégration de conteneurs dans Snakemake/Nextflow
                    (module 24, -profile docker/singularity), GitHub
                    Actions pour l'intégration continue d'un pipeline,
                    dépôts de données (Zenodo) pour l'archivage de
                    résultats avec DOI
```

DOCUMENTATION
------------------------------------------------------------
- Docker — https://docs.docker.com/
- Apptainer — https://apptainer.org/docs/ · source : https://github.com/apptainer/apptainer
- Git — https://git-scm.com/doc

SCIENTIFIC REFERENCES
------------------------------------------------------------
- Kurtzer GM, Sochat V, Bauer MW (2017). "Singularity: Scientific
  containers for mobility of compute." PLOS ONE, 12(5):e0177459.
  DOI: 10.1371/journal.pone.0177459
- Merkel D (2014). "Docker: lightweight Linux containers for consistent
  development and deployment." Linux Journal, 2014(239).

NEXT MODULE
------------------------------------------------------------
`26_hpc/` — exécuter ces workflows et conteneurs sur un cluster de
calcul haute performance, dernier module de la feuille de route.
