============================================================
MODULE 21 — VARIANT CALLING ET ANNOTATION
============================================================

OBJECTIVE
------------------------------------------------------------
Identifier les variants génétiques (SNPs, indels) d'un échantillon par
rapport à un génome de référence, filtrer les appels peu fiables, et
prédire leur effet fonctionnel probable — l'étape qui produit en amont
les génotypes utilisés au module `18_gwas/`.

PREREQUISITES
------------------------------------------------------------
`12_sequence_alignment/` (BWA-MEM2), `05_biological_formats/` (VCF),
`14_genome_annotation/`.

BIOLOGICAL CONCEPT
------------------------------------------------------------
```text
variant calling   processus statistique d'identification des positions où
                   les reads alignés diffèrent de façon fiable de la
                   référence — à distinguer d'une simple différence
                   ponctuelle (erreur de séquençage, erreur d'alignement).
SNP                 Single Nucleotide Polymorphism : substitution d'une
                   seule base.
indel                insertion ou délétion d'une ou plusieurs bases.
germline vs somatic   un variant germline est présent dans toutes les
                   cellules d'un individu (hérité) ; un variant somatique
                   n'apparaît que dans un sous-ensemble de cellules
                   (ex. tumeur) — les deux exigent des approches
                   statistiques différentes.
```

---

# 1. Pipeline général

```text
FASTQ
  ↓
alignement (BWA-MEM2)          (12_sequence_alignment/)
  ↓
BAM trié, dédupliqué           (16_chipseq/, section 2.2 — MarkDuplicates)
  ↓
variant calling
  ↓
VCF brut
  ↓
filtrage
  ↓
annotation fonctionnelle
  ↓
interprétation
```

---

# 2. Variant calling

## 2.1 bcftools (rapide, pipeline léger)

```text
COMMAND: bcftools mpileup | bcftools call
PURPOSE: pipeline de variant calling léger et rapide, adapté aux projets
         de taille modérée et à l'enseignement du principe général.
SYNTAX: bcftools mpileup -f reference.fasta alignement.bam | \
        bcftools call -mv -Oz -o variants.vcf.gz
DOCUMENTATION: https://samtools.github.io/bcftools/ (déjà introduit en
         18_gwas/)
```

## 2.2 GATK (référence pour le calling germline/somatique rigoureux)

```text
COMMAND: gatk HaplotypeCaller
PURPOSE: appel de variants germline par assemblage local en haplotypes
         (plus précis sur les indels et les régions complexes qu'une
         approche de comptage positionnel simple).
SYNTAX (workflow simplifié — le workflow GATK complet inclut
         BaseRecalibrator, non détaillé ici) :
        gatk HaplotypeCaller -R reference.fasta -I alignement.bam -O variants.vcf.gz
DOCUMENTATION: https://gatk.broadinstitute.org/hc/en-us/categories/360002302312-Getting-Started
         (documentation officielle, inclut les « GATK Best Practices »
         workflows complets pour le calling germline et somatique)
COMMON ERRORS: appliquer directement le workflow germline standard à des
         données tumorales (variants somatiques) — GATK propose des
         workflows dédiés distincts (Mutect2 pour le somatique), à ne
         pas confondre avec HaplotypeCaller (germline).
```

```text
QUAND CHOISIR QUOI: bcftools est plus rapide et suffisant pour de
         nombreux projets de recherche standard ; GATK est la référence
         de facto en contexte clinique/diagnostique, avec un ensemble de
         bonnes pratiques (recalibration de qualité de base, filtrage par
         apprentissage automatique VQSR) plus abouti pour les grands
         projets humains. Le choix doit être justifié par le contexte du
         projet, jamais automatique.
```

---

# 3. Filtrage des variants

```text
CONCEPT: un VCF brut contient inévitablement des faux positifs (erreurs
         d'alignement dans les régions répétées, artefacts de séquençage).
         Filtrer avant toute interprétation biologique.
```

```bash
bcftools filter -e 'QUAL<30 || DP<10' variants.vcf.gz -Oz -o variants_filtres.vcf.gz
```

```text
INTERPRETATION: QUAL (confiance du variant) et DP (profondeur de
         couverture à la position) sont des critères de filtrage
         courants — les SEUILS eux-mêmes doivent être justifiés par les
         caractéristiques réelles du jeu de données (profondeur moyenne
         de séquençage obtenue), jamais copiés d'un autre projet sans
         vérification (voir 10_adapter_trimming_filtering/, règle de
         paramétrage).
DOCUMENTATION: https://samtools.github.io/bcftools/bcftools.html#filter
```

---

# 4. Annotation fonctionnelle des variants

## 4.1 Ensembl VEP

```text
COMMAND: vep
PURPOSE: prédire l'effet de chaque variant sur les transcrits/protéines
         connus (synonyme, faux-sens, non-sens, site d'épissage...), et
         rapporter les fréquences alléliques connues (gnomAD, 1000
         Genomes) pour aider à la priorisation.
SYNTAX: vep -i variants_filtres.vcf.gz -o resultats_vep.txt --cache
DOCUMENTATION: https://www.ensembl.org/info/docs/tools/vep/index.html
         (documentation officielle Ensembl) · dépôt :
         https://github.com/Ensembl/ensembl-vep
```

## 4.2 SnpEff

```text
COMMAND: snpEff
PURPOSE: alternative à VEP, annotation rapide de l'effet prévisible de
         chaque variant à partir d'une base de données de génome
         construite localement ou téléchargée.
SYNTAX: snpEff genome_id variants_filtres.vcf.gz > variants_annotes.vcf
DOCUMENTATION: https://pcingola.github.io/SnpEff/ (documentation
         officielle) · dépôt : https://github.com/pcingola/SnpEff
```

```text
CONCEPTS CLÉS EN SORTIE:
  synonyme        changement de codon sans changement d'acide aminé
  faux-sens (missense)   changement d'acide aminé
  non-sens (nonsense)     introduction prématurée d'un codon stop
  site d'épissage          variant affectant potentiellement l'épissage
                           (proche d'une jonction exon-intron)
```

```text
RAPPEL MÉTHODOLOGIQUE: une prédiction d'effet "délétère" par VEP/SnpEff
         est une HYPOTHÈSE computationnelle basée sur des modèles de
         conservation/structure — pas une preuve de pathogénicité. Une
         classification clinique rigoureuse (ex. critères ACMG en
         contexte médical humain) combine plusieurs sources de preuve,
         bien au-delà de la seule prédiction d'effet.
```

---

TROUBLESHOOTING
------------------------------------------------------------
```text
SYMPTOM: un très grand nombre de variants appelés dans des régions
         répétées/basse complexité du génome
CAUSE: erreurs d'alignement fréquentes dans ces régions (multi-mapping
       ambigu), plutôt que de vrais variants.
DIAGNOSIS: croiser la position des variants suspects avec une annotation
           de régions répétées connues.
SOLUTION: appliquer un masque d'exclusion de ces régions avant
          interprétation, ou augmenter le seuil de qualité de mapping
          utilisé en amont (12_sequence_alignment/).
PREVENTION: ne jamais interpréter un variant isolé dans une région
            répétée sans vérification manuelle (visualisation IGV).
```
```text
SYMPTOM: VEP/SnpEff ne trouve aucune annotation pour une grande partie
         des variants
CAUSE: version du génome de référence utilisée pour l'annotation
       différente de celle utilisée pour l'alignement/calling (ex. GRCh37
       vs GRCh38).
DIAGNOSIS: vérifier la version exacte de l'assemblage à chaque étape du
           pipeline.
SOLUTION: régénérer l'annotation avec la base correspondant EXACTEMENT à
          la version de référence utilisée en amont.
PREVENTION: documenter la version précise de l'assemblage dès
            l'acquisition de la référence (08_data_acquisition/).
```

GO FURTHER
------------------------------------------------------------
```text
Topic: variant calling et annotation
Official documentation:
  https://gatk.broadinstitute.org/hc/en-us/categories/360002302312-Getting-Started
  https://samtools.github.io/bcftools/
  https://www.ensembl.org/info/docs/tools/vep/index.html
Topics to explore: variant calling somatique (Mutect2), variants
                    structuraux (SV, hors SNP/indel), imputation de
                    génotypes pour les études de population
```

DOCUMENTATION
------------------------------------------------------------
- GATK — https://gatk.broadinstitute.org/hc/en-us/categories/360002302312-Getting-Started · source : https://github.com/broadinstitute/gatk
- bcftools — https://samtools.github.io/bcftools/
- Ensembl VEP — https://www.ensembl.org/info/docs/tools/vep/index.html · source : https://github.com/Ensembl/ensembl-vep
- SnpEff — https://pcingola.github.io/SnpEff/ · source : https://github.com/pcingola/SnpEff

SCIENTIFIC REFERENCES
------------------------------------------------------------
- McKenna A et al. (2010). "The Genome Analysis Toolkit: a MapReduce
  framework for analyzing next-generation DNA sequencing data." Genome
  Research, 20(9):1297-1303. DOI: 10.1101/gr.107524.110
- McLaren W et al. (2016). "The Ensembl Variant Effect Predictor." Genome
  Biology, 17(1):122. DOI: 10.1186/s13059-016-0974-4
- Cingolani P et al. (2012). "A program for annotating and predicting the
  effects of single nucleotide polymorphisms, SnpEff." Fly, 6(2):80-92.
  DOI: 10.4161/fly.19695

NEXT MODULE
------------------------------------------------------------
`22_r_statistics/` — l'écosystème R/Bioconductor déjà mobilisé dans
plusieurs modules précédents (DESeq2, methylKit, MSstats...), présenté
pour lui-même.
