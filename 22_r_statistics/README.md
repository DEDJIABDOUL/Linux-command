============================================================
MODULE 22 — R ET BIOCONDUCTOR POUR LA BIOINFORMATIQUE
============================================================

OBJECTIVE
------------------------------------------------------------
Situer l'écosystème R/Bioconductor utilisé dans plusieurs modules
précédents (DESeq2, edgeR, limma, methylKit, DSS, MSstats, clusterProfiler)
dans une vue d'ensemble cohérente, et présenter les packages généralistes
de manipulation de données biologiques non encore couverts.

PREREQUISITES
------------------------------------------------------------
`15_rnaseq/` à `21_variant_analysis/` (packages R déjà rencontrés en
contexte).

NOTE DE PORTÉE
------------------------------------------------------------
Ce module ne réexplique pas les statistiques déjà traitées dans leur
contexte (expression différentielle en 15, méthylation en 17,
association génétique en 18) — il présente l'écosystème R/Bioconductor
lui-même et les packages transversaux de manipulation de données
génomiques (Biostrings, GenomicRanges, ShortRead, ggplot2).

---

# 1. Bioconductor — l'écosystème, pas juste des packages

```text
CONCEPT: Bioconductor est un projet de logiciel open source construit
         autour de R, qui distribue des packages spécifiquement dédiés à
         l'analyse de données génomiques, avec des exigences de qualité
         (documentation, tests, vignettes) plus strictes que le CRAN
         généraliste.
INSTALLATION: contrairement aux packages CRAN classiques (install.packages()),
         les packages Bioconductor s'installent via un gestionnaire dédié :
```
```r
if (!require("BiocManager", quietly = TRUE))
    install.packages("BiocManager")
BiocManager::install("NomDuPackage")
```
```text
DOCUMENTATION: https://www.bioconductor.org/help/ (portail officiel)
EXERCISE: installer Biostrings (section 2) et consulter sa vignette avec
         browseVignettes("Biostrings") — c'est le réflexe systématique
         pour découvrir l'usage réel d'un package Bioconductor, plus
         fiable qu'une recherche web générique.
```

---

# 2. Biostrings — manipuler des séquences biologiques en R

```text
COMMAND: DNAString() / DNAStringSet() / readDNAStringSet()
PURPOSE: représenter efficacement en mémoire des séquences ADN/ARN/
         protéiques et leurs collections, avec des opérations vectorisées
         (complément inverse, traduction, recherche de motif) bien plus
         rapides qu'une manipulation de chaînes de caractères R classiques.
SYNTAX (R) :
        library(Biostrings)
        genome <- readDNAStringSet("linux/genome.fasta")
        reverseComplement(genome[1])
        vmatchPattern("ATGCGT", genome)
DOCUMENTATION: https://bioconductor.org/packages/Biostrings (page
         officielle du package, release) · source :
         https://github.com/Bioconductor/Biostrings
EXERCISE: reproduire en R, avec Biostrings, la recherche du motif ATGCGT
         déjà effectuée avec grep et seqkit (module 02) sur
         linux/genome.fasta, et comparer le nombre d'occurrences trouvées.
```

---

# 3. GenomicRanges — représenter des intervalles génomiques

```text
COMMAND: GRanges()
PURPOSE: représenter et manipuler des intervalles génomiques (comparable
         en esprit à BED/GFF — 05_biological_formats/) directement en R,
         avec des opérations ensemblistes (intersection, union, distance)
         équivalentes à bedtools (16_chipseq/) mais intégrées au
         workflow R/Bioconductor.
SYNTAX (R) :
        library(GenomicRanges)
        pics <- GRanges(seqnames = "chr1", ranges = IRanges(start = 1001, end = 2000))
DOCUMENTATION: https://bioconductor.org/packages/release/bioc/html/GenomicRanges.html
         · vignette d'introduction officielle liée depuis cette page
INTERPRETATION: GenomicRanges est le socle sur lequel reposent de
         nombreux autres packages Bioconductor (dont plusieurs déjà
         rencontrés indirectement) — comprendre GRanges facilite
         l'apprentissage de l'ensemble de l'écosystème.
```

---

# 4. ShortRead — manipuler des FASTQ en R

```text
COMMAND: readFastq()
PURPOSE: charger et manipuler des fichiers FASTQ directement en R,
         utile pour des analyses de QC personnalisées au-delà de ce que
         proposent FastQC/NanoPlot (module 09).
SYNTAX (R) :
        library(ShortRead)
        reads <- readFastq("linux/reads.fastq")
DOCUMENTATION: https://bioconductor.org/packages/release/bioc/html/ShortRead.html
NOTE: une partie des fonctionnalités historiques de ShortRead a été
         reprise par des packages plus récents et spécialisés — consulter
         la vignette officielle pour l'état actuel avant de bâtir un
         nouveau pipeline dessus.
```

---

# 5. ggplot2 — visualisation

```text
COMMAND: ggplot()
PURPOSE: construire des visualisations selon la « grammaire des
         graphiques » (couche de données + esthétiques + géométries) —
         standard de facto pour les figures publiées en bioinformatique R
         (PCA du module 15, Manhattan plot du module 18...).
SYNTAX (R) :
        library(ggplot2)
        ggplot(donnees, aes(x = PC1, y = PC2, color = condition)) + geom_point()
DOCUMENTATION: https://ggplot2.tidyverse.org/ (documentation officielle)
```

---

TROUBLESHOOTING
------------------------------------------------------------
```text
SYMPTOM: BiocManager::install() échoue ou installe une version
         incompatible avec la version de R installée
CAUSE: chaque release Bioconductor est liée à une plage de versions R
       précise — une version de R trop ancienne ou trop récente peut
       ne pas correspondre à la release Bioconductor courante.
DIAGNOSIS: vérifier la compatibilité version R / version Bioconductor
           sur https://www.bioconductor.org/help/.
SOLUTION: mettre à jour R (ou utiliser un environnement Conda dédié —
          06_environment_management/) pour aligner les versions.
PREVENTION: documenter systématiquement la version de R et de
            Bioconductor utilisées dans un projet (reproductibilité).
```

GO FURTHER
------------------------------------------------------------
```text
Topic: écosystème R/Bioconductor
Official documentation:
  https://www.bioconductor.org/help/
  https://bioconductor.org/packages/Biostrings
  https://bioconductor.org/packages/release/bioc/html/GenomicRanges.html
Topics to explore: rtracklayer (import/export de formats de pistes
                    génomiques), SummarizedExperiment (structure de
                    données standard sous-jacente à DESeq2/edgeR),
                    Bioconductor Docker images pour la reproductibilité
```

DOCUMENTATION
------------------------------------------------------------
- Bioconductor — https://www.bioconductor.org/help/
- Biostrings — https://bioconductor.org/packages/Biostrings · source : https://github.com/Bioconductor/Biostrings
- GenomicRanges — https://bioconductor.org/packages/release/bioc/html/GenomicRanges.html
- ShortRead — https://bioconductor.org/packages/release/bioc/html/ShortRead.html
- ggplot2 — https://ggplot2.tidyverse.org/ · source : https://github.com/tidyverse/ggplot2

SCIENTIFIC REFERENCES
------------------------------------------------------------
- Gentleman RC et al. (2004). "Bioconductor: open software development
  for computational biology and bioinformatics." Genome Biology, 5:R80.
  DOI: 10.1186/gb-2004-5-10-r80
- Lawrence M et al. (2013). "Software for Computing and Annotating
  Genomic Ranges." PLoS Computational Biology, 9(8):e1003118.
  DOI: 10.1371/journal.pcbi.1003118

NEXT MODULE
------------------------------------------------------------
`23_python_bioinformatics/` — l'équivalent Python de cet écosystème
(Biopython, pandas, pysam).
