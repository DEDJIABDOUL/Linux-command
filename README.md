# Linux-command — De Linux à la bioinformatique professionnelle

Un parcours pratique et progressif qui transforme un débutant complet en
Linux en un analyste capable de conduire une analyse bioinformatique
réelle, reproductible, sur de vraies données publiques.

## Objectifs

Ce dépôt vise à faire maîtriser Linux et Bash appliqués à des données
biologiques réelles, et à faire comprendre en profondeur chaque commande
utilisée : pourquoi, sur quelles données, avec quel résultat, et comment
l'interpréter. La progression va d'une commande isolée vers des scripts,
puis vers des pipelines reproductibles (Conda, puis Snakemake/Nextflow
dans les modules avancés). L'ensemble de la chaîne d'analyse est couvert :
QC, assemblage, alignement, annotation, RNA-seq, ChIP-seq, méthylation,
GWAS, protéomique, métagénomique, variant calling, R/Python, workflows
formels (Snakemake/Nextflow/nf-core), conteneurs et calcul HPC.

## Public visé

Aucun prérequis Linux ni bioinformatique n'est nécessaire pour commencer.
Voir `00_orientation/README.md` pour le détail du public visé et de la
méthode pédagogique.

## Prérequis techniques

Un terminal Linux, macOS, ou WSL/Git Bash sous Windows suffit. Aucun
logiciel bioinformatique préinstallé n'est requis avant le module
`06_environment_management/`, où l'installation se fait via
Conda/Mamba/Bioconda.

## Parcours d'apprentissage

```text
Linux (01)
   ↓
Linux appliqué à la bioinformatique (02)
   ↓
Text processing sur données biologiques (03)
   ↓
Bash scripting (04)
   ↓
Formats biologiques : FASTA/FASTQ/SAM/BAM/VCF/BED/GFF/GTF (05)
   ↓
Environnements reproductibles : Conda/Mamba/Bioconda (06)
   ↓
Organisation de projet (07) → Acquisition de données publiques (08)
   ↓
Contrôle qualité (09) → Trimming/filtrage (10)
   ↓
Assemblage de novo (11) → Alignement (12) → Polishing/QC d'assemblage (13)
   ↓
Annotation de génome (14)
   ↓
RNA-seq (15) → ChIP-seq (16) → Méthylation ADN (17) → GWAS (18) → Protéomique (19)
   ↓
Métagénomique (20) → Variant calling (21) → R/Bioconductor (22) → Python (23)
   ↓
Workflows Snakemake/Nextflow/nf-core (24) → Conteneurs & Git (25) → HPC (26)
```

**Les 26 modules ci-dessus sont tous rédigés.** Le projet final
intégrateur est désormais livré dans
[`projects/final_project_ltee_ecoli/`](projects/final_project_ltee_ecoli/README.md)
(accumulation de variants dans une population *E. coli* de la Long-Term
Evolution Experiment, Lenski lab). Les mini-projets par domaine restent
à construire (voir `projects/README.md` et `docs/audit_report.md`).

## Architecture du dépôt

| Emplacement | Contenu |
|---|---|
| `00_orientation/` | Vue d'ensemble, méthode, feuille de route détaillée |
| `01_linux_basics/` → `26_hpc/` | Les 26 modules de cours (voir tableau ci-dessous) |
| `linux/` | Jeu de données d'entraînement synthétique (FASTA, FASTQ, TSV) et ses exercices corrigés |
| `envs/` | Environnements Conda par domaine (un par module 06-20 ; voir `06_environment_management/README.md`, section 4, pour la liste complète) |
| `scripts/` | Scripts Bash réels et testés issus de `04_bash_scripting/` |
| `legacy/` | Matériau pédagogique historique, préservé tel quel pour référence |
| `docs/` | Rapport d'audit, référence des outils (à venir : formats, commandes, pipelines) |

## Modules disponibles

| Module | Contenu |
|---|---|
| [`01_linux_basics`](01_linux_basics/README.md) | Terminal, navigation, fichiers, permissions, processus |
| [`02_linux_for_bioinformatics`](02_linux_for_bioinformatics/README.md) | Premiers pas sur FASTA/FASTQ |
| [`03_text_processing`](03_text_processing/README.md) | grep/sed/awk/cut/sort/uniq appliqués aux données biologiques |
| [`04_bash_scripting`](04_bash_scripting/README.md) | Variables, boucles, fonctions, scripts robustes |
| [`05_biological_formats`](05_biological_formats/README.md) | FASTA/FASTQ approfondis, introduction SAM/BAM/VCF/BED/GFF/GTF |
| [`06_environment_management`](06_environment_management/README.md) | Conda/Mamba/Bioconda, reproductibilité |
| [`07_project_organization`](07_project_organization/README.md) | Arborescence professionnelle d'un projet bioinformatique |
| [`08_data_acquisition`](08_data_acquisition/README.md) | Téléchargement de données publiques (NCBI/SRA/ENA), intégrité, cas vérifié |
| [`09_quality_control`](09_quality_control/README.md) | QC Illumina et Nanopore/PacBio, interprétation des métriques |
| [`10_adapter_trimming_filtering`](10_adapter_trimming_filtering/README.md) | Trimming/filtrage, statuts d'outils Nanopore vérifiés (Porechop abandonware, NanoFilt → chopper) |
| [`11_de_novo_assembly`](11_de_novo_assembly/README.md) | Assemblage long reads (Flye) et short reads (SPAdes/MEGAHIT) ; Canu confirmé terminé |
| [`12_sequence_alignment`](12_sequence_alignment/README.md) | minimap2, BWA-MEM2, Bowtie2, STAR, HISAT2 |
| [`13_assembly_quality`](13_assembly_quality/README.md) | Polishing (Racon), QUAST, BUSCO |
| [`14_genome_annotation`](14_genome_annotation/README.md) | Annotation procaryote (Bakta) et eucaryote (BRAKER), annotation fonctionnelle |
| [`15_rnaseq`](15_rnaseq/README.md) | Pipeline RNA-seq complet, de FASTQ à l'enrichissement fonctionnel |
| [`16_chipseq`](16_chipseq/README.md) | Peak calling, QC, reproductibilité entre réplicats, motifs |
| [`17_dna_methylation`](17_dna_methylation/README.md) | Bisulfite sequencing, analyse différentielle de méthylation |
| [`18_gwas`](18_gwas/README.md) | Génotypage, QC, structure de population, association |
| [`19_proteomics`](19_proteomics/README.md) | Identification/quantification MS, analyse différentielle |
| [`20_metagenomics`](20_metagenomics/README.md) | Profilage taxonomique, assemblage/binning, qualité de MAG |
| [`21_variant_analysis`](21_variant_analysis/README.md) | Variant calling, filtrage, annotation fonctionnelle |
| [`22_r_statistics`](22_r_statistics/README.md) | Écosystème R/Bioconductor |
| [`23_python_bioinformatics`](23_python_bioinformatics/README.md) | Biopython, pandas, NumPy/SciPy, pysam |
| [`24_workflows`](24_workflows/README.md) | Snakemake, Nextflow, nf-core |
| [`25_reproducibility`](25_reproducibility/README.md) | Conteneurs (Docker/Apptainer), Git/GitHub |
| [`26_hpc`](26_hpc/README.md) | SLURM, modules logiciels, bonnes pratiques cluster |

Les 26 modules de la feuille de route sont désormais tous disponibles,
ainsi que le projet final intégrateur (`projects/final_project_ltee_ecoli/`).
Les mini-projets par domaine restent planifiés dans `projects/`, voir
`docs/audit_report.md`, section « Implementation roadmap ».

## Jeux de données

Le dossier [`linux/`](linux/README.md) contient un jeu de données
synthétique conçu pour ce dépôt (22 séquences génomiques, 40 transcrits,
25 protéines, 500 reads FASTQ avec adaptateurs Illumina, 3 échantillons
compressés, une table d'annotations TSV), avec 13 exercices corrigés.

## Outils couverts

Voir [`docs/tools_reference.md`](docs/tools_reference.md) pour la liste
complète des outils déjà traités, chacun avec sa documentation officielle
vérifiée (jamais d'URL inventée) et son statut de maintenance.

## Documentation du dépôt

- [`docs/audit_report.md`](docs/audit_report.md) — audit initial complet,
  méthodologie de transformation, feuille de route.
- [`docs/tools_reference.md`](docs/tools_reference.md) — référence
  centrale des outils.

## Reproductibilité

Chaque module documente les commandes exécutées, leurs entrées, leurs
sorties attendues, et les liens vers la documentation officielle des
outils utilisés. Les environnements logiciels sont figés via Conda/Mamba
dans `envs/` (voir `06_environment_management/`). Aucune URL ni référence
scientifique n'est ajoutée à ce dépôt sans vérification préalable.

## Contribution

Ce dépôt est construit de façon incrémentale, module par module, jamais
en une seule passe massive. La méthodologie détaillée se trouve dans
`docs/audit_report.md`.

## Licence

Voir le dépôt GitHub pour les conditions de licence applicables.
