# Partie II — Bioinformatique appliquée

Les modules de cette partie appliquent les compétences de la
[Partie I — Linux pour biologistes](../partie1_linux/README.md) aux grandes
analyses de la bioinformatique : contrôle qualité, assemblage, alignement,
annotation, RNA-seq, variants, métagénomique, workflows et calcul
haute performance.

> **Prérequis** : la Partie I en entier, en particulier l'installation des
> logiciels avec conda ([chapitre 11](../partie1_linux/11_installer_logiciels/README.md)),
> les scripts robustes ([chapitre 13](../partie1_linux/13_scripts_bash_2/README.md)),
> SSH ([chapitre 14](../partie1_linux/14_ssh/README.md)) et les formats
> biologiques ([chapitre 16](../partie1_linux/16_formats_biologiques/README.md)).

> **État de cette partie** : ces modules proviennent de la version
> précédente du dépôt. Ils ont été déplacés ici et leurs renvois vers la
> Partie I ont été mis à jour, mais leur contenu n'a **pas encore** été
> refondu selon la [charte pédagogique](../docs/charte_pedagogique.md) de la
> Partie I (sorties réelles montrées, exercices corrigés, tests
> automatiques). Ils suivent encore l'ancien format de fiches (COMMAND,
> PURPOSE…). Leur refonte fera l'objet d'un audit et d'un plan dédiés.

Les modules conservent leur numérotation d'origine (08 à 26) : la Partie I
y renvoie sous ces numéros, par exemple « module 24 de la Partie II ».

## Les modules

| Bloc | Module | Contenu |
|---|---|---|
| **Mise en projet** | [08 — Acquisition de données](08_data_acquisition/README.md) | téléchargement de données publiques (NCBI, SRA, ENA), intégrité, cas vérifié |
| **Contrôle qualité** | [09 — Contrôle qualité](09_quality_control/README.md) | QC Illumina et Nanopore/PacBio, interprétation des métriques |
| | [10 — Trimming et filtrage](10_adapter_trimming_filtering/README.md) | retrait des adaptateurs, filtrage ; statut des outils Nanopore |
| **Assemblage, alignement, annotation** | [11 — Assemblage de novo](11_de_novo_assembly/README.md) | long reads (Flye) et short reads (SPAdes, MEGAHIT) |
| | [12 — Alignement](12_sequence_alignment/README.md) | minimap2, BWA-MEM2, Bowtie2, STAR, HISAT2 |
| | [13 — Qualité d'assemblage](13_assembly_quality/README.md) | polishing (Racon), QUAST, BUSCO |
| | [14 — Annotation de génome](14_genome_annotation/README.md) | annotation procaryote (Bakta) et eucaryote (BRAKER), annotation fonctionnelle |
| **Domaines d'application** | [15 — RNA-seq](15_rnaseq/README.md) | de FASTQ à l'enrichissement fonctionnel |
| | [16 — ChIP-seq](16_chipseq/README.md) | appel de pics, QC, réplicats, motifs |
| | [17 — Méthylation de l'ADN](17_dna_methylation/README.md) | bisulfite, méthylation différentielle |
| | [18 — GWAS](18_gwas/README.md) | génotypage, QC, structure de population, association |
| | [19 — Protéomique](19_proteomics/README.md) | identification et quantification MS, analyse différentielle |
| **Analyse de données** | [20 — Métagénomique](20_metagenomics/README.md) | profilage taxonomique, assemblage et binning, qualité des MAG |
| | [21 — Variant calling](21_variant_analysis/README.md) | appel, filtrage et annotation fonctionnelle des variants |
| | [22 — R et Bioconductor](22_r_statistics/README.md) | l'écosystème R pour la génomique |
| | [23 — Python pour la bioinformatique](23_python_bioinformatics/README.md) | Biopython, pandas, NumPy/SciPy, pysam |
| **Ingénierie et production** | [24 — Workflows](24_workflows/README.md) | Snakemake, Nextflow, nf-core |
| | [25 — Reproductibilité](25_reproducibility/README.md) | conteneurs (Docker, Apptainer), Git et GitHub |
| | [26 — Calcul haute performance](26_hpc/README.md) | SLURM, modules logiciels, bonnes pratiques sur cluster |

## Projets sur données réelles

- [Projet final : accumulation de mutations dans la LTEE d'*E. coli*](../projects/final_project_ltee_ecoli/README.md)
- [Mini-projet : résistance aux antibiotiques, typage et phylogénie de *Klebsiella pneumoniae*](../projects/mini_project_amr_kpneumoniae/README.md)

Les environnements conda de chaque module se trouvent dans [`../envs/`](../envs/).

---

**Retour** : [accueil du dépôt](../README.md)
