============================================================
MODULE 07 — ORGANISATION D'UN PROJET BIOINFORMATIQUE
============================================================

OBJECTIVE
------------------------------------------------------------
Adopter, dès le premier projet, une arborescence professionnelle qui
sépare clairement les données brutes, les données traitées, le code, les
résultats et la documentation — condition pratique de la reproductibilité
avant même d'utiliser un moteur de workflow (Snakemake/Nextflow, phases
ultérieures).

PREREQUISITES
------------------------------------------------------------
`04_bash_scripting/` (mkdir -p), `06_environment_management/`.

WHY?
------------------------------------------------------------
Un projet bioinformatique dont les fichiers bruts, les scripts et les
résultats intermédiaires sont mélangés dans un seul dossier devient vite
impossible à auditer, à partager, ou à relancer proprement après une
interruption. Une arborescence standardisée permet à quiconque (y compris
soi-même six mois plus tard) de retrouver instantanément « où est quoi ».

---

# 1. Arborescence type

```text
project/
├── data/
│   ├── raw/          données brutes, jamais modifiées après acquisition
│   ├── processed/     données nettoyées/filtrées (sorties des étapes de QC)
│   ├── metadata/       description des échantillons (qui, quoi, quand, comment)
│   └── reference/      génome(s)/annotation(s) de référence, index
├── scripts/            scripts d'analyse et d'automatisation
├── results/             résultats finaux (tableaux, figures)
├── qc/                   rapports de contrôle qualité
├── logs/                 journaux d'exécution
├── envs/                 environnements Conda/Mamba documentés
├── workflows/           définitions Snakemake/Nextflow (phases ultérieures)
├── docs/                 documentation du projet
└── README.md
```

```text
RÈGLE FONDAMENTALE: data/raw/ est en lecture seule dans les faits — on ne
         modifie JAMAIS un fichier de data/raw/ en place. Toute
         transformation produit un nouveau fichier dans data/processed/
         ou results/. Cette règle seule évite la perte accidentelle de
         données brutes irremplaçables.
EXERCISE: créer cette arborescence complète en une seule commande.
```

```bash
mkdir -p project/{data/{raw,processed,metadata,reference},scripts,results,qc,logs,envs,workflows,docs}
touch project/README.md
```

---

# 2. Pourquoi chaque dossier existe

```text
data/raw/        Preuve de ce qui a réellement été mesuré/téléchargé.
                  Ne jamais écraser. En cas de doute sur une analyse, on
                  doit toujours pouvoir repartir de ce dossier.
data/processed/  Sorties intermédiaires reproductibles (reads filtrés,
                  BAM triés...). Peut être régénéré à tout moment à partir
                  de data/raw/ + scripts/ + envs/ — donc généralement
                  exclu du contrôle de version (voir .gitignore, module 06
                  et racine du dépôt).
data/metadata/    Table décrivant chaque échantillon (organisme, condition
                  expérimentale, réplicat, date, technologie de
                  séquençage...). Indispensable pour toute analyse
                  statistique en aval (RNA-seq, GWAS...).
data/reference/   Génome(s) de référence, annotations (GFF/GTF), index
                  d'aligneur — partagés entre plusieurs échantillons.
scripts/          Code source : scripts Bash, R, Python. Versionné avec Git.
results/          Sorties destinées à être interprétées ou publiées :
                  tableaux finaux, figures.
qc/               Rapports de contrôle qualité (FastQC, MultiQC...), pour
                  audit rapide sans re-parcourir tous les logs.
logs/             Traces d'exécution : quand, quoi, avec quels paramètres,
                  quelles erreurs éventuelles (voir 04_bash_scripting/,
                  section logging).
envs/             Fichiers .yml Conda/Mamba, un par domaine (voir
                  06_environment_management/).
workflows/        Définitions de pipeline formelles (Snakemake/Nextflow),
                  introduites dans les phases ultérieures du programme.
docs/             Documentation complémentaire (méthodes, décisions).
```

---

# 3. Application à ce dépôt

Ce dépôt suit déjà une variante de cette organisation, adaptée à son
usage pédagogique (modules de cours numérotés plutôt qu'un seul dossier
`results/` d'analyse) :

```text
Linux-command/
├── linux/               ≈ data/ (jeu de données d'entraînement)
├── envs/                 identique en rôle à project/envs/
├── scripts/               identique en rôle à project/scripts/ (voir scripts/README.md)
├── docs/                   identique en rôle à project/docs/
├── legacy/                 matériau historique, préservé tel quel pour référence
├── projects/                mini-projets et projet final (planifiés, voir docs/audit_report.md)
└── 01_linux_basics/.../26_hpc/   les 26 modules de cours (spécifique à ce dépôt pédagogique)
```

```text
EXERCISE: pour un futur mini-projet d'analyse (phases ultérieures),
         créer une arborescence project/ complète comme en section 1, et
         y placer une première entrée dans data/metadata/samples.tsv
         décrivant, par exemple, les 3 échantillons compressés de
         linux/sample_01/02/03.fastq.gz (colonnes suggérées : sample_id,
         organism, condition, n_reads, source). Copier ensuite
         scripts/stats.sh (dépôt réel, voir scripts/README.md) dans
         project/scripts/ pour vérifier que le script fonctionne bien
         depuis cette nouvelle arborescence.
```

---

TROUBLESHOOTING
------------------------------------------------------------
```text
SYMPTOM: impossible de savoir comment un fichier de résultats a été
         généré, plusieurs mois après
CAUSE: absence de logs et de séparation claire scripts/ vs results/.
DIAGNOSIS: le fichier de résultat n'a pas de log associé ni de script
           identifiable qui l'a produit.
SOLUTION: adopter systématiquement l'arborescence de ce module et
          journaliser (04_bash_scripting/, section 5.5) chaque exécution.
PREVENTION: ne jamais lancer une commande d'analyse « à la main » sans
            trace, en dehors de l'exploration ponctuelle.
```

GO FURTHER
------------------------------------------------------------
```text
Topic: organisation de projets de données
Official documentation: https://cookiecutter-data-science.drivendata.org/
Topics to explore: Cookiecutter Data Science (DrivenData), un template de
                    projet largement utilisé hors bioinformatique mais
                    fondé sur les mêmes principes (séparation données
                    brutes/traitées, code, résultats) ; comparer sa
                    structure à celle proposée en section 1
```

DOCUMENTATION
------------------------------------------------------------
- GNU Coreutils Manual (mkdir -p, accolades de développement de chemin) — https://www.gnu.org/software/coreutils/manual/coreutils.html
- GNU Bash Reference Manual (Brace Expansion) — https://www.gnu.org/software/bash/manual/bash.html
- Cookiecutter Data Science — https://cookiecutter-data-science.drivendata.org/ · source : https://github.com/drivendataorg/cookiecutter-data-science

NEXT MODULE
------------------------------------------------------------
`08_data_acquisition/` — télécharger de vraies données publiques dans
cette arborescence (NCBI, SRA, ENA).
