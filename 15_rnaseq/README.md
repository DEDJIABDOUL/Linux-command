============================================================
MODULE 15 — RNA-SEQ : DE FASTQ À L'INTERPRÉTATION BIOLOGIQUE
============================================================

OBJECTIVE
------------------------------------------------------------
Conduire une analyse RNA-seq complète — quantification de l'expression
génique et détection de gènes différentiellement exprimés entre
conditions — en comprenant chaque étape individuellement AVANT toute
automatisation en pipeline formel (Snakemake/Nextflow, phases ultérieures).

PREREQUISITES
------------------------------------------------------------
`09_quality_control/`, `10_adapter_trimming_filtering/`,
`12_sequence_alignment/` (STAR/HISAT2), `14_genome_annotation/` (GTF/GFF).

RÈGLE FONDAMENTALE (§32 de la charte pédagogique)
------------------------------------------------------------
```text
Ne jamais exécuter directement :
    nextflow run nf-core/rnaseq ...
sans avoir compris ce qui se passe à l'intérieur. Ce module déroule
chaque étape manuellement ; l'automatisation via nf-core/rnaseq est
traitée dans les phases ultérieures (Snakemake/Nextflow) comme un
accélérateur, jamais comme une boîte noire.
```

---

# 1. Vue d'ensemble du pipeline

```text
FASTQ
  ↓
QC                          (09_quality_control/)
  ↓
adapter trimming            (10_adapter_trimming_filtering/)
  ↓
QC post-trimming             (09_quality_control/, à ré-exécuter)
  ↓
référence (génome + annotation GTF/GFF)   (08_data_acquisition/, 14_genome_annotation/)
  ↓
alignement (STAR/HISAT2) OU pseudoalignement (Salmon)
  ↓
quantification (featureCounts / StringTie / Salmon)
  ↓
matrice de comptages (gènes × échantillons)
  ↓
import/normalisation (tximport si Salmon, DESeq2/edgeR sinon)
  ↓
analyse exploratoire (PCA, clustering)
  ↓
expression différentielle (DESeq2 / edgeR / limma)
  ↓
enrichissement fonctionnel (clusterProfiler)
  ↓
interprétation biologique
```

DEUX STRATÉGIES, PAS UNE SEULE
------------------------------------------------------------
```text
Alignement classique (STAR/HISAT2 → featureCounts/StringTie)
  Produit un BAM exploitable pour d'autres usages (visualisation, variant
  calling sur transcrit...), mais plus lent.

Pseudoalignement (Salmon)
  Beaucoup plus rapide, ne produit pas de BAM classique (sauf option
  spécifique), mais suffit largement pour la quantification et
  l'expression différentielle standard.
```
Le choix dépend de l'objectif : pas d'outil « par défaut » sans raison.

---

# 2. Alignement classique et comptage

## 2.1 Alignement (rappel du module 12)

```bash
STAR --genomeDir index_star/ --readFilesIn R1.fastq.gz R2.fastq.gz \
     --readFilesCommand zcat --outSAMtype BAM SortedByCoordinate \
     --runThreadN 8 --outFileNamePrefix resultats/sample1_
```

## 2.2 featureCounts — comptage par gène

```text
COMMAND: featureCounts
PURPOSE: compter, pour chaque gène d'une annotation GTF, le nombre de
         reads alignés qui lui sont attribués — produit la matrice de
         comptages brute nécessaire à DESeq2/edgeR.
SYNTAX: featureCounts -a annotation.gtf -o comptages.txt -T 8 -p \
        sample1.bam sample2.bam sample3.bam
OPTIONS:
  -a   fichier d'annotation GTF/GFF (14_genome_annotation/)
  -p   reads paired-end (compte les FRAGMENTS, pas les reads individuels)
  -T   nombre de threads
DOCUMENTATION: https://subread.sourceforge.net/featureCounts.html
         (documentation officielle du paquet Subread)
COMMON ERRORS: annotation GTF ne correspondant pas exactement à la
         version du génome utilisée pour l'alignement (chromosome
         renommé, version différente) — produit un comptage
         silencieusement erroné (très peu de reads assignés) plutôt
         qu'une erreur explicite.
```

## 2.3 StringTie — assemblage et quantification de transcrits

```text
COMMAND: stringtie
PURPOSE: assembler et quantifier des transcrits (y compris isoformes)
         à partir d'un alignement RNA-seq trié, avec ou sans annotation
         de référence guidant l'assemblage.
SYNTAX: stringtie sample1.sorted.bam -G annotation.gtf -o sample1.gtf -p 8
DOCUMENTATION: https://ccb.jhu.edu/software/stringtie/ (site officiel) ·
         source : https://github.com/gpertea/stringtie
```

---

# 3. Pseudoalignement avec Salmon

```text
COMMAND: salmon quant
PURPOSE: quantifier l'abondance de chaque transcrit directement à partir
         des reads, sans alignement base par base complet contre le
         génome — beaucoup plus rapide, avec correction de biais
         intégrée (contenu en GC des fragments).
SYNTAX: salmon index -t transcriptome.fasta -i index_salmon/
        salmon quant -i index_salmon/ -l A -1 R1.fastq.gz -2 R2.fastq.gz \
               -p 8 --validateMappings -o resultats_salmon/sample1/
OPTIONS:
  -l A   détection automatique du type de librairie (orientation/stranding)
DOCUMENTATION: https://salmon.readthedocs.io/ (documentation officielle) ·
         source : https://github.com/COMBINE-lab/salmon
```

## 3.1 Importer les résultats Salmon au niveau gène : tximport

```text
COMMAND: tximport() (package R/Bioconductor)
PURPOSE: agréger les estimations d'abondance au niveau TRANSCRIT
         (produites par Salmon) en une matrice au niveau GÈNE, avec un
         offset de longueur corrigé, prête pour DESeq2/edgeR.
SYNTAX (R) :
        library(tximport)
        txi <- tximport(fichiers_quant_sf, type = "salmon", tx2gene = table_tx2gene)
DOCUMENTATION: https://bioconductor.org/packages/release/bioc/html/tximport.html
INTERPRETATION IMPORTANTE: les estimations au niveau transcrit, puis
         agrégées au niveau gène, donnent des inférences plus robustes
         que la quantification directe au niveau gène — c'est précisément
         la justification scientifique de tximport (voir référence
         Soneson et al. 2015 en fin de module).
```

---

# 4. De la matrice de comptages à l'expression différentielle

## 4.1 DESeq2

```text
COMMAND: DESeq() (package R/Bioconductor)
PURPOSE: modéliser les comptages bruts par une loi binomiale négative,
         normaliser par la taille de librairie, et tester la différence
         d'expression entre conditions.
SYNTAX (R) :
        library(DESeq2)
        dds <- DESeqDataSetFromMatrix(countData = comptages, colData = metadata, design = ~ condition)
        dds <- DESeq(dds)
        resultats <- results(dds, contrast = c("condition", "traite", "controle"))
INPUT: matrice de comptages BRUTS (jamais déjà normalisés — DESeq2
       effectue sa propre normalisation interne).
DOCUMENTATION: https://bioconductor.org/packages/release/bioc/html/DESeq2.html
         (vignette officielle accessible via browseVignettes("DESeq2") dans R)
```

## 4.2 edgeR et limma — alternatives

```text
DOCUMENTATION edgeR: https://bioconductor.org/packages/release/bioc/html/edgeR.html
DOCUMENTATION limma: https://bioconductor.org/packages/release/bioc/html/limma.html
```

```text
QUAND CHOISIR QUOI (aperçu, sans imposer un choix unique) :
  DESeq2   modèle binomial négatif, réglages par défaut robustes, très
           utilisé pour des designs simples à modérément complexes.
  edgeR    même famille de modèle, plus de flexibilité sur les tests
           (exact test, GLM, quasi-likelihood), historique en RNA-seq et
           d'autres données de comptage (ChIP-seq, ATAC-seq...).
  limma    (avec voom pour RNA-seq) transforme les comptages pour les
           ramener à un cadre de modèles linéaires classiques — pratique
           pour des designs expérimentaux complexes (facteurs multiples,
           effets appariés).
Ne jamais choisir un outil uniquement parce qu'il est le plus cité — le
choix doit être justifié par le design expérimental réel.
```

## 4.3 Analyse exploratoire AVANT interprétation

```text
CONCEPT: avant de lire la moindre p-value, toujours visualiser une PCA
         (Analyse en Composantes Principales) des échantillons normalisés
         (ex. via plotPCA() de DESeq2 après une transformation
         variance-stabilisante).
WHY: une PCA révèle immédiatement des problèmes structurels — un effet de
     lot (batch effect) plus fort que l'effet biologique étudié, un
     échantillon aberrant (outlier) à exclure ou investiguer — AVANT de
     produire des résultats d'expression différentielle qui seraient
     autrement trompeurs.
```

---

# 5. Interprétation — rappel des pièges méthodologiques (§80 de la charte)

```text
Differential expression ≠ causalité biologique
Low p-value ≠ importance biologique (toujours regarder le log2 fold-change
     en complément, jamais la p-value seule)
Significatif statistiquement ≠ pertinent biologiquement à l'échelle de
     l'organisme entier
```

```text
CORRECTION DE TESTS MULTIPLES: tester des dizaines de milliers de gènes
         simultanément exige une correction (FDR de Benjamini-Hochberg,
         intégrée par défaut dans results() de DESeq2 — colonne padj) —
         ne jamais interpréter la colonne pvalue brute sans regarder
         padj.
```

---

# 6. Enrichissement fonctionnel

```text
COMMAND: enrichGO() / enrichKEGG() (package R/Bioconductor clusterProfiler)
PURPOSE: déterminer si les gènes différentiellement exprimés sont
         statistiquement surreprésentés dans certaines catégories
         fonctionnelles (GO) ou voies métaboliques (KEGG), au-delà de ce
         qu'on attendrait par hasard.
SYNTAX (R) :
        library(clusterProfiler)
        resultats_go <- enrichGO(gene = liste_genes_significatifs, OrgDb = base_annotation, ont = "BP")
DOCUMENTATION: https://bioconductor.org/packages/release/bioc/html/clusterProfiler.html
INTERPRETATION: un enrichissement significatif propose une HYPOTHÈSE sur
         le processus biologique impliqué — ce n'est pas une preuve
         mécanistique en soi (voir §80, "Peak ≠ biological function
         proven", principe transposable ici).
```

---

TROUBLESHOOTING
------------------------------------------------------------
```text
SYMPTOM: featureCounts assigne très peu de reads à des gènes malgré un
         bon taux d'alignement global (flagstat)
CAUSE: incompatibilité entre l'annotation GTF utilisée et la référence
       d'alignement (version différente, noms de chromosomes non
       concordants — ex. "chr1" vs "1").
DIAGNOSIS: comparer les identifiants de chromosomes du GTF et du fichier
           d'index utilisé pour l'alignement.
SOLUTION: régénérer l'annotation et l'index à partir de LA MÊME source
          (même version d'assemblage).
PREVENTION: documenter précisément la provenance et version de chaque
            fichier de référence (07_project_organization/, data/reference/).
```
```text
SYMPTOM: la PCA des échantillons ne sépare pas les conditions attendues
CAUSE: effet de lot dominant, erreur d'étiquetage des échantillons dans
       les métadonnées, ou effet biologique réellement faible/absent.
DIAGNOSIS: colorer la PCA par différents facteurs de métadonnées (lot,
           date d'extraction, opérateur) pour identifier la source de
           variance dominante.
SOLUTION: intégrer le facteur de confusion identifié dans le design du
          modèle DESeq2/edgeR (design = ~ lot + condition), ou corriger
          l'étiquetage si l'erreur est administrative.
PREVENTION: documenter systématiquement les métadonnées techniques dès
            l'acquisition (08_data_acquisition/, data/metadata/).
```

GO FURTHER
------------------------------------------------------------
```text
Topic: RNA-seq quantification et expression différentielle
Official documentation:
  https://salmon.readthedocs.io/
  https://bioconductor.org/packages/release/bioc/html/DESeq2.html
  https://bioconductor.org/packages/release/bioc/html/clusterProfiler.html
Topics to explore: RNA-seq d'isoformes (transcrits alternatifs), designs
                    à facteurs multiples (interaction), single-cell
                    RNA-seq (hors périmètre de ce module)
```

DOCUMENTATION
------------------------------------------------------------
- Salmon — https://salmon.readthedocs.io/ · source : https://github.com/COMBINE-lab/salmon
- featureCounts (Subread) — https://subread.sourceforge.net/featureCounts.html
- StringTie — https://ccb.jhu.edu/software/stringtie/ · source : https://github.com/gpertea/stringtie
- tximport — https://bioconductor.org/packages/release/bioc/html/tximport.html
- DESeq2 — https://bioconductor.org/packages/release/bioc/html/DESeq2.html
- edgeR — https://bioconductor.org/packages/release/bioc/html/edgeR.html
- limma — https://bioconductor.org/packages/release/bioc/html/limma.html
- clusterProfiler — https://bioconductor.org/packages/release/bioc/html/clusterProfiler.html

SCIENTIFIC REFERENCES
------------------------------------------------------------
- Patro R, Duggal G, Love MI, Irizarry RA, Kingsford C (2017). "Salmon
  provides fast and bias-aware quantification of transcript expression."
  Nature Methods, 14:417-419. DOI: 10.1038/nmeth.4197
- Liao Y, Smyth GK, Shi W (2014). "featureCounts: an efficient
  general-purpose program for assigning sequence reads to genomic
  features." Bioinformatics, 30(7):923-930. DOI: 10.1093/bioinformatics/btt656
- Pertea M et al. (2015). "StringTie enables improved reconstruction of a
  transcriptome from RNA-seq reads." Nature Biotechnology, 33:290-295.
  DOI: 10.1038/nbt.3122
- Soneson C, Love MI, Robinson MD (2015). "Differential analyses for
  RNA-seq: transcript-level estimates improve gene-level inferences."
  F1000Research, 4:1521. DOI: 10.12688/f1000research.7563.1
- Love MI, Huber W, Anders S (2014). "Moderated estimation of fold change
  and dispersion for RNA-seq data with DESeq2." Genome Biology, 15:550.
- Robinson MD, McCarthy DJ, Smyth GK (2010). "edgeR: a Bioconductor
  package for differential expression analysis of digital gene expression
  data." Bioinformatics, 26(1):139-140. DOI: 10.1093/bioinformatics/btp616
- Ritchie ME et al. (2015). "limma powers differential expression
  analyses for RNA-sequencing and microarray studies." Nucleic Acids
  Research, 43(7):e47. DOI: 10.1093/nar/gkv007
- Wu T et al. (2021). "clusterProfiler 4.0: A universal enrichment tool
  for interpreting omics data." The Innovation, 2(3):100141.
  DOI: 10.1016/j.xinn.2021.100141

NEXT MODULE
------------------------------------------------------------
`16_chipseq/` — appliquer une logique de comptage similaire (peaks au
lieu de gènes) à des données ChIP-seq.
