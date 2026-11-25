# Partie II — Bioinformatique appliquée

Les modules de cette partie appliquent les compétences de la
[Partie I — Linux pour biologistes](../partie1_linux/README.md) aux grandes
analyses de la bioinformatique. La numérotation continue celle de la
Partie I : chapitres 00 à 17, puis modules 18 à 36.

> **Prérequis** : la Partie I en entier, en particulier l'installation des
> logiciels avec conda ([chapitre 11](../partie1_linux/11_installer_logiciels/README.md)),
> les scripts robustes ([chapitre 13](../partie1_linux/13_scripts_bash_2/README.md)),
> SSH ([chapitre 14](../partie1_linux/14_ssh/README.md)) et les formats
> biologiques ([chapitre 16](../partie1_linux/16_formats_biologiques/README.md)).

> **État de cette partie : refonte en cours.** Les modules ont été remis
> dans un ordre où aucune notion n'est utilisée avant d'être enseignée, et
> leurs erreurs les plus graves ont été corrigées. Leur contenu suit encore
> l'ancien format de fiches (COMMAND, PURPOSE…) : ils seront réécrits un à
> un selon la [charte pédagogique](../docs/charte_pedagogique.md) de la
> Partie I, avec des exercices corrigés et entièrement pratiqués sur des
> jeux de données inclus dans le dépôt.

## Les modules

| Bloc | Module | Contenu |
|---|---|---|
| **E · Données et qualité** | [18 — Acquisition de données](18_acquisition_donnees/README.md) | bases publiques (NCBI, SRA, ENA), téléchargement, intégrité |
| | [19 — Contrôle qualité](19_controle_qualite/README.md) | QC Illumina et Nanopore/PacBio, interprétation des métriques |
| | [20 — Trimming et filtrage](20_trimming_filtrage/README.md) | retrait des adaptateurs, filtrage ; statut des outils Nanopore |
| **F · Génome de référence** | [21 — Alignement](21_alignement/README.md) | minimap2, BWA-MEM2, Bowtie2, STAR, HISAT2 |
| | [22 — Appel de variants](22_appel_variants/README.md) | appel, filtrage et annotation fonctionnelle des variants |
| | [23 — Assemblage de novo](23_assemblage/README.md) | long reads (Flye) et short reads (SPAdes, MEGAHIT) |
| | [24 — Qualité d'assemblage](24_qualite_assemblage/README.md) | polishing (Racon), QUAST, BUSCO |
| | [25 — Annotation de génome](25_annotation/README.md) | annotation procaryote (Bakta) et eucaryote (BRAKER), annotation fonctionnelle |
| **G · Analyser en R et Python** | [26 — R et Bioconductor](26_r_bioconductor/README.md) | l'écosystème R pour la génomique |
| | [27 — Python](27_python/README.md) | Biopython, pandas, NumPy/SciPy, pysam |
| **H · Omiques** | [28 — RNA-seq](28_rnaseq/README.md) | de FASTQ à l'enrichissement fonctionnel |
| | [29 — ChIP-seq](29_chipseq/README.md) | appel de pics, QC, réplicats, motifs |
| | [30 — Méthylation de l'ADN](30_methylation/README.md) | bisulfite, méthylation différentielle |
| | [31 — GWAS](31_gwas/README.md) | génotypage, QC, structure de population, association |
| | [32 — Protéomique](32_proteomique/README.md) | identification et quantification MS, analyse différentielle |
| | [33 — Métagénomique](33_metagenomique/README.md) | profilage taxonomique, assemblage et binning, qualité des MAG |
| **I · Production** | [34 — Workflows](34_workflows/README.md) | Snakemake, Nextflow, nf-core |
| | [35 — Conteneurs](35_conteneurs/README.md) | Docker, Apptainer |
| | [36 — Calcul haute performance](36_hpc/README.md) | SLURM, modules logiciels, bonnes pratiques sur cluster |

**Pourquoi cet ordre ?** L'alignement et l'appel de variants viennent
avant l'assemblage, car ils sont plus simples et plus fréquents. R et Python
viennent avant les omiques, qui les utilisent (DESeq2 en RNA-seq, par
exemple). Le GWAS vient après l'appel de variants, qui produit ses
génotypes.

## Projets sur données réelles

- [Projet final : accumulation de mutations dans la LTEE d'*E. coli*](../projects/final_project_ltee_ecoli/README.md)
- [Mini-projet : résistance aux antibiotiques, typage et phylogénie de *Klebsiella pneumoniae*](../projects/mini_project_amr_kpneumoniae/README.md)

Les environnements conda de chaque module se trouvent dans [`../envs/`](../envs/).

---

**Retour** : [accueil du dépôt](../README.md)
