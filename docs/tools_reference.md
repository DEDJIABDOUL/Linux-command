# Référence centrale des outils

Ce tableau recense tous les outils couverts par les 26 modules du dépôt
(`01_linux_basics/` à `26_hpc/`), avec leur documentation officielle
vérifiée. Il sera étendu si de nouveaux modules sont ajoutés (mini-projets,
`projects/`, voir `00_orientation/README.md` et `audit_report.md`). Toute
URL listée ici a été vérifiée par recherche officielle avant ajout,
aucune n'est inventée.

| Outil | Domaine | Rôle | Documentation officielle | Dépôt source | Statut |
|---|---|---|---|---|---|
| Bash | Shell / scripting | Interpréteur de commandes, scripting | https://www.gnu.org/software/bash/manual/bash.html | https://savannah.gnu.org/git/?group=bash | Actif |
| GNU Coreutils (ls, cp, mv, rm, mkdir, cat, head, tail, wc, du, df, chmod, tee, date...) | Linux fondamental | Utilitaires de fichiers de base | https://www.gnu.org/software/coreutils/manual/coreutils.html | https://github.com/coreutils/coreutils | Actif |
| GNU Findutils (find, xargs) | Linux fondamental | Recherche de fichiers | https://www.gnu.org/software/findutils/manual/ | — (Savannah GNU) | Actif |
| GNU grep | Text processing | Recherche de motifs texte | https://www.gnu.org/software/grep/manual/grep.html | — (Savannah GNU) | Actif |
| GNU sed | Text processing | Édition de flux (remplacement de texte) | https://www.gnu.org/software/sed/manual/sed.html | — (Savannah GNU) | Actif |
| GNU Awk (gawk) | Text processing | Traitement de texte structuré en colonnes | https://www.gnu.org/software/gawk/manual/gawk.html | https://github.com/gnu-mirror-unofficial/gawk (miroir) | Actif |
| less | Linux fondamental | Lecture progressive de fichiers volumineux | https://www.greenwoodsoftware.com/less/ | https://github.com/gwsw/less | Actif |
| htop | Linux fondamental | Visualisation interactive des processus | https://htop.dev/ | https://github.com/htop-dev/htop | Actif |
| procps-ng (ps, top, free) | Linux fondamental | Processus et ressources système | — | https://gitlab.com/procps-ng/procps | Actif |
| ShellCheck | Bash scripting | Analyse statique de scripts shell | https://www.shellcheck.net/ | https://github.com/koalaman/shellcheck | Actif |
| Conda | Environnements | Gestionnaire de paquets/environnements | https://docs.conda.io/projects/conda/en/stable/ | https://github.com/conda/conda | Actif |
| Mamba | Environnements | Résolveur de dépendances rapide, compatible Conda | https://mamba.readthedocs.io/ | https://github.com/mamba-org/mamba | Actif |
| Miniforge | Environnements | Distribution d'installation Conda/Mamba (conda-forge par défaut) | — | https://github.com/conda-forge/miniforge | Actif |
| Bioconda | Environnements | Canal de paquets bioinformatiques pour Conda | https://bioconda.github.io/ | https://github.com/bioconda | Actif |
| SeqKit | Formats FASTA/FASTQ | Statistiques et manipulation FASTA/FASTQ | https://bioinf.shenwei.me/seqkit/ | https://github.com/shenwei356/seqkit | Actif |
| samtools | Formats SAM/BAM/CRAM | Manipulation d'alignements (introduit conceptuellement en 05, usage pratique en phase alignement) | https://www.htslib.org | https://github.com/samtools/samtools | Actif |
| GNU Wget | Acquisition de données | Téléchargement HTTP/HTTPS/FTP non interactif | https://www.gnu.org/software/wget/manual/wget.html | https://ftp.gnu.org/gnu/wget/ | Actif |
| curl | Acquisition de données | Transfert de données via URL, API | https://curl.se/docs/ | https://github.com/curl/curl | Actif |
| rsync | Acquisition de données | Synchronisation différentielle de fichiers | https://rsync.samba.org/documentation.html | https://github.com/RsyncProject/rsync | Actif |
| GNU tar | Acquisition de données | Archivage/désarchivage | https://www.gnu.org/software/tar/manual/tar.html | — (Savannah GNU) | Actif |
| SRA Toolkit (prefetch, fasterq-dump) | Acquisition de données | Téléchargement/conversion de données NCBI SRA | https://github.com/ncbi/sra-tools/wiki/08.-prefetch-and-fasterq-dump | https://github.com/ncbi/sra-tools | Actif |
| ENA (European Nucleotide Archive) | Acquisition de données | Miroir européen de la SRA, FASTQ directement accessibles | https://ena-docs.readthedocs.io/ | — | Actif |
| NCBI Datasets (CLI) | Acquisition de données | Téléchargement de génomes/annotations NCBI | https://www.ncbi.nlm.nih.gov/datasets/docs/v2/command-line-tools/ | https://github.com/ncbi/datasets | Actif |
| NCBI GEO | Acquisition de données | Dépôt de données d'expression (microarray, RNA-seq) | https://www.ncbi.nlm.nih.gov/geo/info/ | — | Actif |
| UCSC Genome Browser | Acquisition de données / formats | Génomes de référence, spécification BED | https://genome.ucsc.edu/FAQ/FAQformat.html | — | Actif |
| UniProt | Acquisition de données | Séquences et annotations protéiques | https://www.uniprot.org/help/programmatic_access | — | Actif |
| FastQC | QC Illumina | Rapport de QC par fichier FASTQ | https://www.bioinformatics.babraham.ac.uk/projects/fastqc/ | https://github.com/s-andrews/FastQC | Actif |
| MultiQC | QC (agrégation) | Rapport agrégé multi-échantillons/multi-outils | https://multiqc.info/docs/ | https://github.com/MultiQC/MultiQC | Actif |
| NanoPlot | QC Nanopore/PacBio | Statistiques et visualisations de reads longs | https://github.com/wdecoster/NanoPlot | https://github.com/wdecoster/NanoPlot | Actif |
| LongQC | QC Nanopore/PacBio | QC dédié reads longs (couverture, complexité librairie) | https://github.com/yfukasawa/LongQC | https://github.com/yfukasawa/LongQC | **Actif** — vérifié 2026-08-22, dernière release 1.2.3 (2026-03-25) |
| Cutadapt | Trimming Illumina | Retrait d'adaptateurs tolérant aux erreurs | https://cutadapt.readthedocs.io/en/stable/ | https://github.com/marcelm/cutadapt | Actif |
| fastp | Trimming/QC Illumina | QC + trimming + filtrage tout-en-un | https://github.com/OpenGene/fastp | https://github.com/OpenGene/fastp | Actif |
| chopper | Trimming/filtrage Nanopore/PacBio | Filtrage qualité/longueur, successeur de NanoFilt+NanoLyse | https://github.com/wdecoster/chopper | https://github.com/wdecoster/chopper | Actif — successeur officiel de NanoFilt |
| Porechop | Trimming d'adaptateurs Nanopore | Retrait d'adaptateurs Nanopore par motifs connus | https://github.com/rrwick/Porechop | https://github.com/rrwick/Porechop | **Abandonware** — déclaré par l'auteur en 2018 ; conservé pour valeur pédagogique uniquement |
| Porechop_ABI | Trimming d'adaptateurs Nanopore | Fork maintenu de Porechop, découverte automatique d'adaptateurs | https://github.com/bonsai-team/Porechop_ABI | https://github.com/bonsai-team/Porechop_ABI | Actif (fork communautaire, pas un successeur officiel de l'auteur original) |
| NanoFilt | Filtrage qualité/longueur Nanopore | Filtrage de reads longs (Python) | https://github.com/wdecoster/nanofilt | https://github.com/wdecoster/nanofilt | **Non maintenu** — remplacé par chopper (même auteur) |
| Canu | Assemblage de novo long reads | Assemblage long-read avec correction intégrée | https://canu.readthedocs.io/en/latest/index.html | https://github.com/marbl/canu | **Terminé** — v2.3 (2024-12-17) déclarée dernière release par les développeurs eux-mêmes |
| Flye | Assemblage de novo long reads | Assemblage long-read par graphe de répétition | https://github.com/mikolmogorov/Flye | https://github.com/mikolmogorov/Flye | Actif — vérifié 2026-08-22, dernière release 2.9.6 (2025-05-02) — recommandé à la place de Canu |
| SPAdes | Assemblage de novo short reads | Assemblage Illumina par graphe de de Bruijn | https://ablab.github.io/spades/ | https://github.com/ablab/spades | Actif |
| MEGAHIT | Assemblage de novo short reads | Assemblage ultra-rapide, optimisé métagénomique | https://github.com/voutcn/megahit | https://github.com/voutcn/megahit | Actif |
| minimap2 | Alignement long reads | Aligneur polyvalent long reads / overlaps / ARN épissé | https://github.com/lh3/minimap2 | https://github.com/lh3/minimap2 | Actif — vérifié 2026-08-22, dernière release 2.31 (2026-05-19) ; version figée du fichier legacy (v2.24) obsolète |
| BWA-MEM2 | Alignement short reads ADN | Aligneur ADN court, accéléré | https://github.com/bwa-mem2/bwa-mem2 | https://github.com/bwa-mem2/bwa-mem2 | Actif |
| Bowtie2 | Alignement short reads ADN | Aligneur ADN court, historique et toujours utilisé | https://bowtie-bio.sourceforge.net/bowtie2/index.shtml | https://github.com/BenLangmead/bowtie2 | Actif |
| STAR | Alignement RNA-seq | Aligneur ARN tolérant à l'épissage | https://github.com/alexdobin/STAR | https://github.com/alexdobin/STAR | Actif |
| HISAT2 | Alignement RNA-seq | Aligneur ARN tolérant à l'épissage, économe en mémoire | https://daehwankimlab.github.io/hisat2/ | https://github.com/DaehwanKimLab/hisat2 | Actif |
| Racon | Polishing d'assemblage | Correction d'assemblage par consensus | https://github.com/lbcb-sci/racon | https://github.com/lbcb-sci/racon | Actif — dépôt déplacé depuis isovic/racon (non maintenu), vérifié 2026-08-22 |
| QUAST | QC d'assemblage | Statistiques d'assemblage (N50, misassemblies...) | https://quast.sourceforge.net/docs/manual.html | https://github.com/ablab/quast | Actif — vérifié 2026-08-22, version 5.3.0 |
| BUSCO | QC d'assemblage | Complétude par orthologues universels à copie unique | https://busco.ezlab.org/busco_userguide.html | https://gitlab.com/ezlab/busco | Actif |
| Prokka | Annotation procaryote | Annotation rapide de génomes bactériens | https://github.com/tseemann/prokka | https://github.com/tseemann/prokka | **Non maintenu** — l'auteur recommande explicitement Bakta comme successeur |
| Bakta | Annotation procaryote | Annotation standardisée de génomes bactériens/MAGs | https://github.com/oschwengers/bakta | https://github.com/oschwengers/bakta | Actif — successeur recommandé par l'auteur de Prokka |
| BRAKER | Annotation eucaryote | Prédiction de gènes eucaryotes (GeneMark + AUGUSTUS) | https://github.com/Gaius-Augustus/BRAKER | https://github.com/Gaius-Augustus/BRAKER | Actif |
| AUGUSTUS | Annotation eucaryote | Prédiction de gènes par HMM (utilisé via BRAKER) | https://github.com/Gaius-Augustus/Augustus | https://github.com/Gaius-Augustus/Augustus | Actif |
| BLAST+ | Similarité de séquences | Recherche de similarité locale (nucl./prot.) | https://www.ncbi.nlm.nih.gov/books/NBK279690/ | — (NCBI) | Actif |
| DIAMOND | Similarité de séquences | Recherche de similarité protéique accélérée | https://github.com/bbuchfink/diamond/wiki | https://github.com/bbuchfink/diamond | Actif |
| InterProScan | Annotation fonctionnelle | Domaines/motifs protéiques, termes GO | https://interproscan-docs.readthedocs.io/ | https://github.com/ebi-pf-team/interproscan | Actif |
| eggNOG-mapper | Annotation fonctionnelle | Annotation par orthologie précalculée (GO/KEGG) | https://github.com/eggnogdb/eggnog-mapper/wiki | https://github.com/eggnogdb/eggnog-mapper | Actif |
| Salmon | RNA-seq | Pseudoalignement / quantification de transcrits | https://salmon.readthedocs.io/ | https://github.com/COMBINE-lab/salmon | Actif |
| featureCounts (Subread) | RNA-seq | Comptage de reads par gène | https://subread.sourceforge.net/featureCounts.html | — (SourceForge) | Actif |
| StringTie | RNA-seq | Assemblage/quantification de transcrits | https://ccb.jhu.edu/software/stringtie/ | https://github.com/gpertea/stringtie | Actif |
| tximport | RNA-seq (R/Bioconductor) | Import d'estimations transcrit → gène | https://bioconductor.org/packages/release/bioc/html/tximport.html | https://github.com/thelovelab/tximport | Actif |
| DESeq2 | RNA-seq (R/Bioconductor) | Expression différentielle (modèle binomial négatif) | https://bioconductor.org/packages/release/bioc/html/DESeq2.html | https://github.com/thelovelab/DESeq2 | Actif |
| edgeR | RNA-seq (R/Bioconductor) | Expression différentielle (données de comptage) | https://bioconductor.org/packages/release/bioc/html/edgeR.html | — (Bioconductor) | Actif |
| limma | RNA-seq (R/Bioconductor) | Modèles linéaires pour expression différentielle | https://bioconductor.org/packages/release/bioc/html/limma.html | — (Bioconductor) | Actif |
| clusterProfiler | RNA-seq (R/Bioconductor) | Enrichissement fonctionnel GO/KEGG | https://bioconductor.org/packages/release/bioc/html/clusterProfiler.html | https://github.com/YuLab-SMU/clusterProfiler | Actif |
| MACS3 (ex-MACS2) | ChIP-seq | Peak calling | https://macs3-project.github.io/MACS/ | https://github.com/macs3-project/MACS | Actif — développement déplacé de MACS2 vers MACS3 (vérifié 2026-08-22, v3.0.3) |
| deepTools | ChIP-seq / QC | Visualisation, QC de corrélation/enrichissement | https://deeptools.readthedocs.io/ | https://github.com/deeptools/deepTools | Actif |
| bedtools | Formats BED / génomique | Arithmétique d'intervalles génomiques | https://bedtools.readthedocs.io/ | https://github.com/arq5x/bedtools2 | Actif |
| IDR | ChIP-seq | Reproductibilité de pics entre réplicats | https://github.com/nboley/idr | https://github.com/nboley/idr | Actif |
| HOMER | ChIP-seq | Découverte de motifs de liaison | http://homer.ucsd.edu/homer/motif/ | — | Actif |
| Picard (MarkDuplicates) | SAM/BAM | Marquage des doublons PCR | https://gatk.broadinstitute.org/hc/en-us/articles/35967618836635-MarkDuplicates-Picard | https://github.com/broadinstitute/picard | Actif |
| Bismark | Méthylation ADN | Alignement bisulfite et methylation calling | https://felixkrueger.github.io/Bismark/ | https://github.com/FelixKrueger/Bismark | Actif |
| Trim Galore | Méthylation ADN / trimming | Wrapper Cutadapt+FastQC, mode RRBS | https://github.com/FelixKrueger/TrimGalore | https://github.com/FelixKrueger/TrimGalore | Actif |
| methylKit | Méthylation ADN (R/Bioconductor) | Analyse différentielle de méthylation | https://www.bioconductor.org/packages/release/bioc/html/methylKit.html | https://github.com/al2na/methylKit | Actif |
| DSS | Méthylation ADN (R/Bioconductor) | DML/DMR par modèle bayésien (faible réplication) | https://www.bioconductor.org/packages/release/bioc/html/DSS.html | — (Bioconductor) | Actif |
| PLINK 2.0 | GWAS | Génotypage, QC, PCA, association | https://www.cog-genomics.org/plink/2.0/ | https://github.com/chrchang/plink-ng | Actif |
| bcftools | GWAS / VCF | Manipulation de VCF/BCF | https://samtools.github.io/bcftools/ | https://github.com/samtools/bcftools | Actif |
| VCFtools | GWAS / VCF | Manipulation de VCF (historique) | https://vcftools.github.io/ | https://github.com/vcftools/vcftools | Activité de mise à jour réduite — bcftools recommandé pour les nouveaux pipelines |
| ADMIXTURE | GWAS | Estimation d'ascendance/structure de population | https://dalexander.github.io/admixture/ | — | Actif |
| MaxQuant | Protéomique | Identification/quantification DDA (moteur Andromeda) | https://maxquant.org/ | — (voir coxdocs.org) | Actif |
| FragPipe (MSFragger) | Protéomique | Plateforme d'identification/quantification DDA+DIA | https://fragpipe.nesvilab.org/ | https://github.com/Nesvilab/FragPipe | Actif |
| DIA-NN | Protéomique | Traitement de données DIA | https://github.com/vdemichev/DiaNN | https://github.com/vdemichev/DiaNN | Actif |
| MSstats | Protéomique (R/Bioconductor) | Quantification différentielle statistique | https://msstats.org/ | https://github.com/Vitek-Lab/MSstats | Actif |
| Kraken2 | Métagénomique | Profilage taxonomique par k-mers | https://github.com/DerrickWood/kraken2/wiki | https://github.com/DerrickWood/kraken2 | Actif |
| Bracken | Métagénomique | Ré-estimation d'abondance à partir de Kraken2 | https://github.com/jenniferlu717/Bracken | https://github.com/jenniferlu717/Bracken | Actif |
| MetaBAT2 | Métagénomique | Binning de contigs métagénomiques | https://bitbucket.org/berkeleylab/metabat | https://bitbucket.org/berkeleylab/metabat | Actif |
| CheckM2 | Métagénomique | Qualité de MAG (complétude/contamination, ML) | https://github.com/chklovski/CheckM2 | https://github.com/chklovski/CheckM2 | Actif — recommandé plutôt que CheckM1 |
| CheckM1 | Métagénomique | Qualité de MAG (référence historique) | https://github.com/Ecogenomics/CheckM | https://github.com/Ecogenomics/CheckM | Actif, mais CheckM2 recommandé pour les nouveaux projets |
| GTDB-Tk | Métagénomique | Classification taxonomique de MAGs (GTDB) | https://ecogenomics.github.io/GTDBTk/ | https://github.com/Ecogenomics/GTDBTk | Actif |
| GATK | Variant calling | Appel de variants germline/somatique | https://gatk.broadinstitute.org/hc/en-us/categories/360002302312-Getting-Started | https://github.com/broadinstitute/gatk | Actif |
| Ensembl VEP | Annotation de variants | Prédiction d'effet fonctionnel de variants | https://www.ensembl.org/info/docs/tools/vep/index.html | https://github.com/Ensembl/ensembl-vep | Actif |
| SnpEff | Annotation de variants | Prédiction d'effet fonctionnel de variants | https://pcingola.github.io/SnpEff/ | https://github.com/pcingola/SnpEff | Actif |
| Bioconductor | R / écosystème | Distribution de packages R pour la génomique | https://www.bioconductor.org/help/ | — | Actif |
| Biostrings (R) | Formats FASTA/FASTQ (R) | Manipulation de séquences biologiques | https://bioconductor.org/packages/Biostrings | https://github.com/Bioconductor/Biostrings | Actif |
| GenomicRanges (R) | Formats BED/GFF (R) | Intervalles génomiques | https://bioconductor.org/packages/release/bioc/html/GenomicRanges.html | https://github.com/Bioconductor/GenomicRanges | Actif |
| ShortRead (R) | Formats FASTQ (R) | Manipulation de FASTQ en R | https://bioconductor.org/packages/release/bioc/html/ShortRead.html | https://github.com/Bioconductor/ShortRead | Actif (fonctionnalités partiellement reprises par d'autres packages) |
| ggplot2 (R) | Visualisation | Grammaire des graphiques | https://ggplot2.tidyverse.org/ | https://github.com/tidyverse/ggplot2 | Actif |
| Biopython | Python / séquences | Manipulation de séquences biologiques | https://biopython.org/docs/latest/Tutorial/ | https://github.com/biopython/biopython | Actif |
| pandas | Python / données tabulaires | Manipulation de données tabulaires | https://pandas.pydata.org/docs/ | — | Actif |
| NumPy | Python / calcul numérique | Tableaux numériques | https://numpy.org/doc/ | — | Actif |
| SciPy | Python / statistiques | Routines statistiques et numériques | https://docs.scipy.org/doc/scipy/ | — | Actif |
| pysam | Python / SAM-BAM-VCF | Interface Python à htslib | https://pysam.readthedocs.io/ | https://github.com/pysam-developers/pysam | Actif |
| Cookiecutter Data Science | Organisation de projet | Template de structure de projet de données | https://cookiecutter-data-science.drivendata.org/ | https://github.com/drivendataorg/cookiecutter-data-science | Actif |
| Snakemake | Workflows | Moteur de workflow déclaratif (règles) | https://snakemake.readthedocs.io/ | — | Actif |
| Nextflow | Workflows | Moteur de workflow (process/channels) | https://www.nextflow.io/docs/latest/ | https://github.com/nextflow-io/nextflow | Actif |
| nf-core | Workflows | Collection de pipelines Nextflow communautaires | https://nf-co.re/docs | https://github.com/nf-core | Actif |
| Docker | Reproductibilité / conteneurs | Conteneurisation d'environnements | https://docs.docker.com/ | https://github.com/docker | Actif |
| Apptainer | Reproductibilité / conteneurs | Conteneurisation adaptée au HPC (ex-Singularity) | https://apptainer.org/docs/ | https://github.com/apptainer/apptainer | Actif |
| Git | Reproductibilité / versionnage | Versionnage de code | https://git-scm.com/doc | — | Actif |
| SLURM | HPC | Ordonnanceur de jobs sur cluster | https://slurm.schedmd.com/documentation.html | — | Actif |
| Lmod | HPC | Gestionnaire de modules logiciels | https://lmod.readthedocs.io/ | https://github.com/TACC/Lmod | Actif |
