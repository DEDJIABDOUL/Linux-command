============================================================
MODULE 17 — MÉTHYLATION DE L'ADN
============================================================

OBJECTIVE
------------------------------------------------------------
Analyser des données de séquençage bisulfite pour quantifier la
méthylation de l'ADN base par base, et identifier des régions
différentiellement méthylées (DMR) entre conditions.

PREREQUISITES
------------------------------------------------------------
`09_quality_control/`, `10_adapter_trimming_filtering/`,
`05_biological_formats/` (structure SAM/BAM).

BIOLOGICAL CONCEPT
------------------------------------------------------------
```text
méthylation de l'ADN    ajout d'un groupe méthyle sur une cytosine
                         (le plus souvent dans un contexte CpG chez les
                         mammifères), modification épigénétique associée
                         à la régulation de l'expression génique.
bisulfite sequencing     traitement chimique qui convertit les cytosines
                         NON méthylées en uracile (lues comme T après
                         PCR), alors que les cytosines MÉTHYLÉES restent
                         inchangées (lues comme C) — la différence C/T
                         observée après séquençage code directement l'état
                         de méthylation.
WGBS                      Whole-Genome Bisulfite Sequencing : couverture
                         de l'ensemble du génome, coûteux mais exhaustif.
RRBS                      Reduced Representation Bisulfite Sequencing :
                         se concentre sur les régions riches en CpG
                         (via digestion enzymatique ciblée), moins coûteux.
DMR                        Differentially Methylated Region : région où
                         le niveau de méthylation diffère significativement
                         entre deux conditions/groupes.
```

WHY?
------------------------------------------------------------
```text
POURQUOI L'ALIGNEMENT BISULFITE EST DIFFÉRENT D'UN ALIGNEMENT ADN STANDARD

Après conversion bisulfite, un read ne correspond plus exactement au
génome de référence : toutes les cytosines non méthylées sont devenues
des T. Un aligneur ADN classique (BWA-MEM2, Bowtie2 — module 12) traiterait
ce nombre élevé de mésappariements C→T comme des erreurs ou des variants,
et échouerait à aligner correctement la majorité des reads. Un aligneur
bisulfite dédié (Bismark) résout ce problème en générant des versions
in silico converties du génome de référence (C→T sur un brin, G→A sur
l'autre) et en alignant les reads convertis contre ces génomes convertis,
puis en déduisant l'état de méthylation réel par comparaison à la
séquence de référence originale.
```

---

# 1. Préparation des reads

```text
COMMAND: trim_galore
PURPOSE: wrapper autour de Cutadapt et FastQC (déjà vus en
         09_quality_control/ et 10_adapter_trimming_filtering/), avec un
         mode --rrbs dédié qui gère la particularité des reads RRBS
         (base artefactuelle ajoutée par la digestion enzymatique en fin
         de read).
SYNTAX: trim_galore --rrbs R1.fastq.gz         (RRBS)
        trim_galore --paired R1.fastq.gz R2.fastq.gz   (WGBS paired-end)
STATUT VÉRIFIÉ (2026-08-22) : activement maintenu par le même auteur que
         Bismark (Felix Krueger) ; une réécriture Rust (v2.0) est
         disponible en parallèle de la version historique, en remplacement
         direct pour les scripts/pipelines existants.
DOCUMENTATION: https://github.com/FelixKrueger/TrimGalore (dépôt officiel,
         guide utilisateur et guide RRBS spécifique inclus)
```

---

# 2. Alignement bisulfite et methylation calling avec Bismark

```text
COMMAND: bismark_genome_preparation
PURPOSE: préparer les génomes convertis in silico (C→T et G→A) requis
         par Bismark, à partir du génome de référence standard.
SYNTAX: bismark_genome_preparation dossier_reference/
```

```text
COMMAND: bismark
PURPOSE: aligner les reads bisulfite convertis contre les génomes
         convertis, et produire un BAM annoté de l'information de
         méthylation par read.
SYNTAX: bismark --genome dossier_reference/ -1 R1_trimmed.fastq.gz -2 R2_trimmed.fastq.gz
STATUT VÉRIFIÉ (2026-08-22) : activement maintenu (Felix Krueger,
         Babraham Bioinformatics puis Altos Labs), avec une réécriture
         Rust récente en parallèle de la version Perl historique.
DOCUMENTATION: https://www.bioinformatics.babraham.ac.uk/projects/bismark/
         (site officiel) · documentation en ligne :
         https://felixkrueger.github.io/Bismark/ · dépôt :
         https://github.com/FelixKrueger/Bismark
```

```text
COMMAND: bismark_methylation_extractor
PURPOSE: extraire, à partir du BAM produit par bismark, le niveau de
         méthylation base par base, séparé par contexte (CpG, CHG, CHH).
SYNTAX: bismark_methylation_extractor --comprehensive --bedGraph alignement_bismark.bam
OUTPUT: fichiers de contexte de méthylation + un fichier bedGraph/coverage
         exploitable par methylKit ou DSS (section 3).
COMMON ERRORS: interpréter le contexte CHG/CHH comme négligeable par
         défaut — chez les plantes notamment, la méthylation non-CpG
         est biologiquement significative ; ne jamais l'ignorer sans
         justification liée à l'organisme étudié.
```

---

# 3. Analyse différentielle de méthylation

## 3.1 methylKit (R/Bioconductor)

```text
COMMAND: methRead() / calculateDiffMeth()
PURPOSE: importer les sorties Bismark dans R, filtrer par couverture,
         et tester la différence de méthylation entre groupes,
         base par base ou par région (tiling windows).
SYNTAX (R) :
        library(methylKit)
        obj <- methRead(liste_fichiers_coverage, sample.id = ids, treatment = groupes, assembly = "genome_ref")
        diff <- calculateDiffMeth(obj)
DOCUMENTATION: https://www.bioconductor.org/packages/release/bioc/html/methylKit.html
         (vignette officielle) · dépôt : https://github.com/al2na/methylKit
```

## 3.2 DSS (R/Bioconductor)

```text
COMMAND: DMLtest() / callDMR()
PURPOSE: modèle bayésien hiérarchique dédié aux données de comptage
         base-résolution (bêta-binomial), particulièrement recommandé
         quand le nombre de réplicats biologiques est faible — situation
         fréquente et coûteuse à corriger en WGBS.
SYNTAX (R) :
        library(DSS)
        test_dml <- DMLtest(objet_bsseq, group1 = echantillons_A, group2 = echantillons_B)
        dmrs <- callDMR(test_dml)
DOCUMENTATION: https://www.bioconductor.org/packages/release/bioc/html/DSS.html
```

```text
QUAND CHOISIR QUOI: methylKit offre un cadre plus généraliste (filtrage,
         visualisation, annotation intégrée) ; DSS est privilégié quand
         le nombre de réplicats est faible, grâce à son emprunt de force
         statistique (shrinkage) entre positions. Ne jamais choisir l'un
         ou l'autre "par défaut" — le nombre de réplicats disponibles
         doit guider ce choix.
```

---

TROUBLESHOOTING
------------------------------------------------------------
```text
SYMPTOM: taux de conversion bisulfite anormalement bas rapporté par
         Bismark (beaucoup de C non converties même en contexte non-CpG)
CAUSE: conversion bisulfite chimique incomplète lors de la préparation
       de l'échantillon (problème de laboratoire, pas bioinformatique).
DIAGNOSIS: vérifier le taux de conversion sur le contexte CHH (qui ne
           devrait quasiment jamais être méthylé chez les mammifères) —
           un taux de non-conversion élevé y indique un problème de
           protocole plutôt qu'un signal biologique réel.
SOLUTION: si le taux de conversion est trop faible, les résultats de
          méthylation en aval ne sont pas fiables — envisager de refaire
          la préparation d'échantillon.
PREVENTION: toujours vérifier ce contrôle qualité AVANT d'interpréter des
            différences de méthylation en CpG.
```
```text
SYMPTOM: très peu de DMRs détectées malgré une hypothèse biologique forte
CAUSE: couverture insuffisante à certaines positions CpG, ou nombre de
       réplicats trop faible pour la puissance statistique requise.
DIAGNOSIS: vérifier la distribution de couverture par position
           (filtrage typique : exclure les positions à très faible
           couverture avant le test différentiel).
SOLUTION: envisager DSS plutôt que methylKit si le nombre de réplicats
          est très limité (section 3.2) ; envisager un séquençage plus
          profond ou davantage de réplicats pour une nouvelle expérience.
PREVENTION: estimer la puissance statistique attendue avant de planifier
            le nombre de réplicats et la profondeur de séquençage.
```

GO FURTHER
------------------------------------------------------------
```text
Topic: méthylation de l'ADN
Official documentation:
  https://felixkrueger.github.io/Bismark/
  https://www.bioconductor.org/packages/release/bioc/html/methylKit.html
  https://www.bioconductor.org/packages/release/bioc/html/DSS.html
Topics to explore: 5hmC (hydroxyméthylation, protocoles oxBS-seq/TAB-seq,
                    pris en charge par methylKit), séquençage Nanopore
                    natif sans conversion bisulfite (détection directe de
                    méthylation, hors périmètre de ce module)
```

DOCUMENTATION
------------------------------------------------------------
- Bismark — https://www.bioinformatics.babraham.ac.uk/projects/bismark/ · doc en ligne : https://felixkrueger.github.io/Bismark/
- Trim Galore — https://github.com/FelixKrueger/TrimGalore
- methylKit — https://www.bioconductor.org/packages/release/bioc/html/methylKit.html
- DSS — https://www.bioconductor.org/packages/release/bioc/html/DSS.html

SCIENTIFIC REFERENCES
------------------------------------------------------------
- Krueger F, Andrews SR (2011). "Bismark: a flexible aligner and
  methylation caller for Bisulfite-Seq applications." Bioinformatics,
  27(11):1571-1572. DOI: 10.1093/bioinformatics/btr167
- Akalin A et al. (2012). "methylKit: a comprehensive R package for the
  analysis of genome-wide DNA methylation profiles." Genome Biology,
  13:R87. DOI: 10.1186/gb-2012-13-10-r87
- Feng H, Conneely KN, Wu H (2014). "A Bayesian hierarchical model to
  detect differentially methylated loci from single nucleotide
  resolution sequencing data." Nucleic Acids Research, 42(8):e69.
  DOI: 10.1093/nar/gku154

NEXT MODULE
------------------------------------------------------------
`18_gwas/` — passer de variants individuels à une étude d'association
pangénomique.
