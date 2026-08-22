# 08 — Acquisition de données biologiques publiques

OBJECTIVE
------------------------------------------------------------
Télécharger, vérifier l'intégrité, décompresser et documenter de vraies
données publiques dans l'arborescence définie au module précédent, en
utilisant une accession réelle et vérifiable (jamais inventée).

PREREQUISITES
------------------------------------------------------------
`06_environment_management/`, `07_project_organization/`.

WHY?
------------------------------------------------------------
La quasi-totalité des exercices bioinformatiques sérieux reposent sur des
données publiques déjà déposées dans une base internationale. Savoir les
retrouver et les télécharger de façon fiable et reproductible (avec
vérification d'intégrité) est un prérequis à toute analyse réelle.

---

# 1. Outils de transfert génériques

```text
COMMAND: wget
PURPOSE: télécharger un fichier depuis une URL (HTTP/HTTPS/FTP), de façon
         non interactive — adapté aux scripts et aux longs téléchargements.
SYNTAX: wget URL
        wget -O nom_local.ext URL     (choisir le nom du fichier local)
        wget -c URL                    (reprendre un téléchargement interrompu)
DOCUMENTATION: https://www.gnu.org/software/wget/manual/wget.html
```

```text
COMMAND: curl
PURPOSE: transférer des données depuis/vers une URL ; plus flexible que
         wget pour interagir avec des API (headers, méthodes HTTP).
SYNTAX: curl -O URL          (garde le nom de fichier distant)
        curl -L -o nom.ext URL   (-L suit les redirections HTTP)
DOCUMENTATION: https://curl.se/docs/ · manuel : https://curl.se/docs/manpage.html
```

```text
COMMAND: rsync
PURPOSE: synchroniser des fichiers/dossiers, en ne transférant que les
         différences — utile pour de très gros jeux de données ou des
         synchronisations répétées avec un serveur HPC.
SYNTAX: rsync -avzP source destination
OPTIONS: -a archive (préserve permissions/dates), -v verbeux,
         -z compression pendant le transfert, -P affiche la progression
         et permet la reprise
DOCUMENTATION: https://rsync.samba.org/documentation.html
```

```text
COMMON ERRORS (les trois outils):
  - URL mal copiée (http au lieu de https, espace en trop) → erreur de
    connexion ou fichier HTML d'erreur téléchargé à la place des données.
  - Téléchargement interrompu par une coupure réseau → toujours vérifier
    l'intégrité (section 3) avant utilisation, jamais supposer qu'un
    fichier de bonne taille est forcément complet et correct.
EXERCISE: comparer sur un même fichier public le comportement de
         `wget -c` et `curl -C -` après avoir interrompu volontairement
         le téléchargement (Ctrl+C) puis relancé la commande.
```

---

# 2. Compression et archives

```text
COMMAND: gzip / gunzip / zcat  (déjà vus en 01_linux_basics/)
COMMAND: tar
PURPOSE: regrouper plusieurs fichiers/dossiers dans une seule archive
         (souvent combinée à une compression gzip : .tar.gz).
SYNTAX: tar -xzf archive.tar.gz          (extraire une archive .tar.gz)
        tar -tzf archive.tar.gz          (lister le contenu SANS extraire)
        tar -czf archive.tar.gz dossier/ (créer une archive compressée)
OPTIONS: x=extraire, c=créer, t=lister, z=compression gzip, f=nom de fichier
DOCUMENTATION: https://www.gnu.org/software/tar/manual/tar.html
EXERCISE: lister le contenu d'une archive .tar.gz avec -tzf AVANT de
         l'extraire, pour vérifier qu'elle ne contient pas des centaines
         de fichiers dans le dossier courant par erreur.
```

---

# 3. Vérifier l'intégrité d'un téléchargement

```text
COMMAND: md5sum / sha256sum
PURPOSE: calculer une empreinte cryptographique d'un fichier et la
         comparer à celle publiée par la source, pour détecter toute
         corruption ou troncature survenue pendant le transfert.
SYNTAX: sha256sum fichier
        sha256sum -c fichier.sha256      (vérifie contre une somme fournie)
INTERPRETATION: si l'empreinte calculée diffère de celle publiée, le
         fichier est corrompu ou incomplet — ne jamais l'utiliser tel quel.
DOCUMENTATION: https://www.gnu.org/software/coreutils/manual/coreutils.html
EXERCISE: calculer `sha256sum` sur linux/genome.fasta et noter le
         résultat ; le recalculer après une copie (`cp`) du fichier pour
         vérifier qu'il est identique bit à bit.
```

---

# 4. Panorama des bases de données publiques

```text
NCBI (National Center for Biotechnology Information, USA)
  - SRA (Sequence Read Archive)   : reads de séquençage brute
  - GEO (Gene Expression Omnibus) : données d'expression (microarray, RNA-seq...)
  - Genome / Assembly / Datasets  : génomes de référence et annotations

ENA (European Nucleotide Archive, EMBL-EBI, Europe)
  - Miroir européen de la SRA, souvent PLUS SIMPLE d'accès : distribue
    directement les FASTQ compressés par HTTP/FTP, sans outil spécialisé.

Ensembl / Ensembl Genomes  : génomes de référence annotés, navigateur génomique
UCSC Genome Browser         : génomes de référence, annotations, outils utilitaires
UniProt                      : séquences et annotations protéiques
```

```text
DOCUMENTATION:
  NCBI SRA          — https://www.ncbi.nlm.nih.gov/sra/docs/sradownload/
  NCBI GEO           — https://www.ncbi.nlm.nih.gov/geo/info/
  NCBI Datasets (CLI)— https://www.ncbi.nlm.nih.gov/datasets/docs/v2/command-line-tools/
  ENA                 — https://ena-docs.readthedocs.io/
  Ensembl (upload/format doc, sert aussi de point d'entrée général) — https://www.ensembl.org/info/website/upload/gff.html
  UCSC Genome Browser — https://genome.ucsc.edu/FAQ/FAQformat.html
  UniProt (accès programmatique) — https://www.uniprot.org/help/programmatic_access
```

---

# 5. Étude de cas vérifiée : `SRR18392380`

Cette accession est utilisée dans `legacy/installation_and_execution.txt`
et a été **vérifiée à la date de rédaction de ce module** via l'API
officielle NCBI Entrez (`eutils`) : il s'agit d'un run de séquençage
Oxford Nanopore MinION (WGS) du génome de SARS-CoV-2, soumis en mars 2022
par Universiti Malaysia Pahang, contenant 82 559 reads pour environ
43 millions de bases.

## 5.1 Via SRA Toolkit (NCBI)

```text
COMMAND: prefetch puis fasterq-dump
PURPOSE: prefetch télécharge les données brutes SRA (.sra) ; fasterq-dump
         les convertit en FASTQ.
SYNTAX: prefetch SRR18392380
        fasterq-dump SRR18392380
INTERPRETATION: prefetch crée un dossier SRR18392380/ contenant le
         fichier .sra ; s'il échoue en cours de route, relancer la même
         commande reprend le téléchargement au lieu de repartir de zéro.
DOCUMENTATION: https://github.com/ncbi/sra-tools
         (dépôt officiel) · guide d'usage détaillé :
         https://github.com/ncbi/sra-tools/wiki/08.-prefetch-and-fasterq-dump
```

## 5.2 Via ENA (alternative souvent plus simple)

L'ENA republie les mêmes données de séquençage directement en FASTQ
compressé, accessibles par une URL HTTP stable, sans outil spécialisé :

```text
DOCUMENTATION: https://ena-docs.readthedocs.io/en/latest/retrieval/general-guide.html
EXERCISE: rechercher SRR18392380 sur le portail ENA (via le navigateur
         ENA, https://www.ebi.ac.uk/ena/browser/) et identifier l'URL
         FTP/HTTP directe du ou des fichiers FASTQ associés, à comparer
         avec la méthode SRA Toolkit ci-dessus.
```

## 5.3 Documenter le dataset (obligatoire)

```text
CONCEPT: avant d'utiliser un jeu de données public dans une analyse,
         documenter systématiquement :
```

```text
| Champ                | Valeur pour SRR18392380 |
|-----------------------|--------------------------|
| Base de données        | NCBI SRA |
| Accession               | SRR18392380 |
| Organisme               | Severe acute respiratory syndrome coronavirus 2 |
| Technologie              | Oxford Nanopore MinION |
| Stratégie                | WGS (whole genome sequencing) |
| Nombre de reads           | 82 559 |
| Bases totales              | ≈ 43 000 000 |
| Date de soumission          | 2022-03-21 |
| Soumis par                   | Universiti Malaysia Pahang |
```

```text
EXERCISE: créer project/data/metadata/SRR18392380.tsv reprenant ce
         tableau, en s'inspirant de l'arborescence du module 07.
```

---

TROUBLESHOOTING
------------------------------------------------------------
```text
SYMPTOM: fasterq-dump échoue ou est très lent
CAUSE: connexion réseau interrompue, ou absence d'exécution préalable de
       prefetch (fasterq-dump n'est pas conçu pour re-télécharger seul
       un run entier depuis zéro de façon fiable).
DIAGNOSIS: vérifier qu'un dossier SRR18392380/ contenant un fichier .sra
           existe déjà (issu de prefetch) avant d'appeler fasterq-dump.
SOLUTION: relancer prefetch (reprend où il s'est arrêté), puis fasterq-dump.
PREVENTION: toujours exécuter prefetch avant fasterq-dump, jamais l'inverse.
```
```text
SYMPTOM: un fichier téléchargé ne s'ouvre pas correctement (erreur de
         format, gzip corrompu...)
CAUSE: téléchargement incomplet ou interrompu.
DIAGNOSIS: comparer la somme de contrôle (section 3) à celle publiée par
           la source, si disponible ; sinon, `gzip -t fichier.gz` teste
           l'intégrité d'une archive gzip sans l'extraire.
SOLUTION: re-télécharger le fichier.
PREVENTION: toujours vérifier la taille et/ou la somme de contrôle après
            un téléchargement avant de l'utiliser dans un pipeline.
```

GO FURTHER
------------------------------------------------------------
```text
Topic: acquisition de données de séquençage
Official documentation:
  https://github.com/ncbi/sra-tools
  https://ena-docs.readthedocs.io/
Topics to explore: téléchargement par lot (liste d'accessions),
                    fasterq-dump --split-files pour du paired-end,
                    API Entrez pour automatiser une recherche
```

DOCUMENTATION
------------------------------------------------------------
- GNU Wget Manual — https://www.gnu.org/software/wget/manual/wget.html
- curl — https://curl.se/docs/
- rsync — https://rsync.samba.org/documentation.html
- GNU tar Manual — https://www.gnu.org/software/tar/manual/tar.html
- GNU Coreutils Manual (md5sum, sha256sum) — https://www.gnu.org/software/coreutils/manual/coreutils.html
- NCBI SRA download guide — https://www.ncbi.nlm.nih.gov/sra/docs/sradownload/
- SRA Toolkit (dépôt officiel) — https://github.com/ncbi/sra-tools
- NCBI GEO — https://www.ncbi.nlm.nih.gov/geo/info/
- NCBI Datasets CLI — https://www.ncbi.nlm.nih.gov/datasets/docs/v2/command-line-tools/
- ENA Documentation — https://ena-docs.readthedocs.io/
- UCSC Genome Browser FAQ — https://genome.ucsc.edu/FAQ/FAQformat.html
- UniProt Programmatic Access — https://www.uniprot.org/help/programmatic_access

NEXT MODULE
------------------------------------------------------------
`09_quality_control/` — contrôler la qualité des données téléchargées
avant tout traitement en aval.
