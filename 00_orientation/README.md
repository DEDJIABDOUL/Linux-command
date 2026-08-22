# 00 — Orientation

## Objectif de ce dépôt

Ce dépôt transforme progressivement un débutant complet en Linux en un analyste
capable de conduire une analyse bioinformatique réelle, de bout en bout, sur de
vraies données publiques, et de la rendre reproductible.

Il ne s'agit pas d'une liste de commandes à mémoriser. Chaque commande présentée
répond systématiquement aux questions suivantes :

```text
Pourquoi cette commande ?
Sur quelles données ?
Que produit-elle exactement ?
Comment vérifier qu'elle a fonctionné ?
Comment interpréter son résultat ?
Quelles sont ses limites ?
```

## Public visé

Aucun prérequis Linux n'est supposé pour commencer au module
`01_linux_basics/`. Aucun prérequis en biologie moléculaire n'est
supposé non plus pour les tout premiers modules : les notions (FASTA,
FASTQ, lecture/`read`, qualité Phred...) sont introduites au fur et à
mesure qu'elles deviennent nécessaires. Le rythme est progressif, du
débutant à l'intermédiaire, puis à l'avancé et au professionnel (voir
`docs/audit_report.md`, section « Critère de réussite »).

## Comment utiliser ce dépôt

1. Suivre les modules dans l'ordre numéroté (`01_`, `02_`, `03_`, ...) : chaque
   module s'appuie sur les précédents.
2. Exécuter réellement chaque commande présentée, sur les jeux de données
   fournis dans `linux/` pour les premiers modules, puis sur de vraies
   données publiques pour les modules avancés (téléchargement documenté
   module par module).
3. Faire les exercices avant de lire la solution.
4. Consulter systématiquement les liens de documentation officielle
   fournis pour chaque outil, sans jamais se contenter d'une commande
   copiée sans comprendre ses options.

## Où trouver quoi

| Besoin | Emplacement |
|---|---|
| Vue d'ensemble du dépôt, méthodologie, historique | `docs/audit_report.md` |
| Référence centralisée des outils (doc officielle, statut, alternatives) | `docs/tools_reference.md` |
| Jeux de données d'exercice (FASTA, FASTQ, TSV synthétiques) | `linux/` (voir `README.md` à la racine) |
| Matériau historique en cours de restructuration | `legacy/` |
| Environnements Conda documentés par domaine | `envs/` |
| Modules de cours | `01_linux_basics/` → ... (voir tableau ci-dessous) |

## Feuille de route des modules

Les 26 modules ci-dessous sont tous marqués **[disponible]** : la feuille
de route complète est rédigée. Voir `docs/audit_report.md` pour la
méthodologie suivie et pour la suite planifiée (`projects/`).

| Module | Contenu | Statut |
|---|---|---|
| `01_linux_basics` | Terminal, navigation, fichiers, permissions, processus | **[disponible]** |
| `02_linux_for_bioinformatics` | Premiers pas sur FASTA/FASTQ avec les commandes de base | **[disponible]** |
| `03_text_processing` | `grep`/`sed`/`awk`/`cut`/`sort`/`uniq`/`tr` appliqués aux données biologiques | **[disponible]** |
| `04_bash_scripting` | Variables, boucles, fonctions, scripts robustes | **[disponible]** |
| `05_biological_formats` | FASTA/FASTQ en profondeur, introduction SAM/BAM/VCF/BED/GFF/GTF | **[disponible]** |
| `06_environment_management` | Conda/Mamba/Bioconda, reproductibilité des environnements | **[disponible]** |
| `07_project_organization` | Arborescence professionnelle d'un projet bioinformatique | **[disponible]** |
| `08_data_acquisition` | Téléchargement de données publiques (NCBI/SRA/ENA), intégrité, cas vérifié SRR18392380 | **[disponible]** |
| `09_quality_control` | QC Illumina (FastQC/MultiQC) et Nanopore/PacBio (NanoPlot/LongQC), interprétation des métriques | **[disponible]** |
| `10_adapter_trimming_filtering` | Trimming/filtrage Illumina (Cutadapt/fastp) et Nanopore (chopper), statuts d'outils vérifiés | **[disponible]** |
| `11_de_novo_assembly` | Assemblage long reads (Flye) et short reads (SPAdes/MEGAHIT) ; statut de Canu vérifié (terminé) | **[disponible]** |
| `12_sequence_alignment` | minimap2, BWA-MEM2, Bowtie2, STAR, HISAT2 ; différences ADN/ARN/long-read | **[disponible]** |
| `13_assembly_quality` | Polishing (Racon), QUAST, BUSCO | **[disponible]** |
| `14_genome_annotation` | Annotation procaryote (Bakta) et eucaryote (BRAKER), annotation fonctionnelle (BLAST/DIAMOND/InterProScan/eggNOG-mapper) | **[disponible]** |
| `15_rnaseq` | Pipeline RNA-seq complet : alignement/pseudoalignement, quantification, DESeq2/edgeR/limma, enrichissement fonctionnel | **[disponible]** |
| `16_chipseq` | Peak calling (MACS3), QC (FRiP, deepTools), reproductibilité (IDR), motifs (HOMER) | **[disponible]** |
| `17_dna_methylation` | Bisulfite sequencing (Bismark), analyse différentielle (methylKit/DSS) | **[disponible]** |
| `18_gwas` | Génotypage, QC, structure de population (PCA/ADMIXTURE), association (PLINK2) | **[disponible]** |
| `19_proteomics` | Identification/quantification MS (MaxQuant/FragPipe/DIA-NN), MSstats | **[disponible]** |
| `20_metagenomics` | Profilage taxonomique (Kraken2/Bracken), binning (MetaBAT2), qualité de MAG (CheckM2), taxonomie (GTDB-Tk) | **[disponible]** |
| `21_variant_analysis` | Variant calling (GATK/bcftools), filtrage, annotation (VEP/SnpEff) | **[disponible]** |
| `22_r_statistics` | Écosystème R/Bioconductor (Biostrings, GenomicRanges, ShortRead, ggplot2) | **[disponible]** |
| `23_python_bioinformatics` | Biopython, pandas, NumPy/SciPy, pysam | **[disponible]** |
| `24_workflows` | Snakemake, Nextflow, nf-core (jamais en boîte noire) | **[disponible]** |
| `25_reproducibility` | Conteneurs (Docker/Apptainer), Git/GitHub | **[disponible]** |
| `26_hpc` | SLURM, modules logiciels (Lmod), bonnes pratiques cluster | **[disponible]** |

**Les 26 modules de la feuille de route sont désormais tous rédigés.** La
suite naturelle, mini-projets et projet final intégrateur, est à
construire dans `projects/` (non encore rédigé, voir `docs/audit_report.md`).

## Jeu de données d'entraînement

Le dossier `linux/` contient un jeu de données synthétique conçu spécifiquement
pour ce dépôt (22 séquences génomiques, 40 transcrits, 25 protéines, 500 reads
FASTQ avec adaptateurs, 3 échantillons compressés, une table d'annotations TSV).
Il est décrit en détail dans `README.md` (racine du dépôt) avec des exercices
corrigés. Les modules `02_`, `03_` et `05_` s'appuient dessus.
