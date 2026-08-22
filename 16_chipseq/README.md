# 16 — ChIP-seq : de FASTQ aux pics d'enrichissement

OBJECTIVE
------------------------------------------------------------
Identifier les régions génomiques où une protéine (facteur de
transcription, marque d'histone) est enrichie, à partir de données
ChIP-seq, en comprenant chaque étape de filtrage et en évaluant
correctement la reproductibilité entre réplicats.

PREREQUISITES
------------------------------------------------------------
`10_adapter_trimming_filtering/`, `12_sequence_alignment/` (Bowtie2/BWA-MEM2),
`05_biological_formats/` (BED, samtools).

BIOLOGICAL CONCEPT
------------------------------------------------------------
```text
input     échantillon de contrôle SANS immunoprécipitation (chromatine
          fragmentée brute) — sert de référence de bruit de fond.
ChIP      échantillon immunoprécipité avec un anticorps ciblant la
          protéine d'intérêt (facteur de transcription, histone modifiée).
peak      région où le signal ChIP est statistiquement enrichi par
          rapport à l'input.
narrow peak   pic étroit et bien délimité, typique des facteurs de
          transcription se liant à un site précis.
broad peak    signal étalé sur une large région, typique de certaines
          marques d'histones (ex. H3K27me3, H3K9me3).
```

WHY?
------------------------------------------------------------
Sans échantillon input, il est impossible de distinguer un enrichissement
biologique réel d'un biais technique (accessibilité chromatinienne,
nombre de copies, biais de fragmentation) — c'est pourquoi un pipeline
ChIP-seq sans contrôle input n'est généralement pas interprétable de
façon fiable.

---

# 0. Environnement de ce module

```bash
conda env create -f envs/chipseq.yml
conda activate chipseq
```

```text
CONTENU: macs3, deeptools, bedtools, samtools, idr, homer, picard — voir
         envs/chipseq.yml pour le détail.
```

# 1. Pipeline général

```text
FASTQ (ChIP + input)
  ↓
QC + trimming              (09_quality_control/, 10_adapter_trimming_filtering/)
  ↓
alignement (Bowtie2/BWA-MEM2)   (12_sequence_alignment/)
  ↓
filtrage (qualité de mapping, doublons)
  ↓
peak calling (MACS3, ChIP vs input)
  ↓
QC des pics (FRiP)
  ↓
reproductibilité entre réplicats (IDR)
  ↓
annotation des pics
  ↓
analyse de motifs
  ↓
interprétation biologique
```

---

# 2. Filtrage post-alignement

## 2.1 Filtrage par qualité de mapping (rappel samtools)

```bash
samtools view -b -q 30 alignement.bam > alignement.filtre.bam
```

```text
INTERPRETATION: -q 30 exclut les alignements de faible confiance
         (multi-mapping ambigu). Ce seuil doit être choisi et justifié —
         pas copié aveuglément (voir 10_adapter_trimming_filtering/,
         règle de paramétrage).
```

## 2.2 Marquage des doublons de PCR

```text
COMMAND: picard MarkDuplicates
PURPOSE: identifier les reads dupliqués (probablement issus d'une
         sur-amplification PCR plutôt que de fragments biologiquement
         distincts) et les marquer pour exclusion.
SYNTAX: picard MarkDuplicates I=alignement.filtre.bam O=alignement.dedup.bam M=metriques.txt
         puis : samtools view -b -F 1024 alignement.dedup.bam > alignement.final.bam
DOCUMENTATION: https://gatk.broadinstitute.org/hc/en-us/articles/35967618836635-MarkDuplicates-Picard
COMMON ERRORS: retirer les doublons AVANT le peak calling n'est pas
         toujours souhaitable pour tous les designs (ex. données à très
         forte profondeur où la duplication naturelle est significative)
         — documenter le choix, ne jamais l'appliquer par réflexe.
```

---

# 3. Peak calling avec MACS3

```text
COMMAND: macs3 callpeak
PURPOSE: identifier les régions où le signal ChIP est statistiquement
         enrichi par rapport à l'input, en modélisant le décalage de
         fragment et le bruit de fond local.
SYNTAX: macs3 callpeak -t chip.final.bam -c input.final.bam \
               -f BAM -g mm -n echantillon --outdir resultats_macs/
OPTIONS COURANTES:
  -f BAM       format d'entrée
  -g           taille effective du génome (mm=souris, hs=humain, ou une
               valeur numérique pour un autre organisme)
  --broad      active le mode broad peak (marques d'histones étendues)
STATUT VÉRIFIÉ (2026-08-22) : le développement actif s'est déplacé de
         MACS2 vers **MACS3** (dépôt macs3-project/MACS) ; MACS2 ne reçoit
         plus que des correctifs de maintenance. MACS3 conserve la
         compatibilité de principe avec MACS2 (mêmes concepts, options
         largement similaires) mais doit être préféré pour tout nouveau
         projet. Version stable vérifiée : 3.0.3 (2025-02-20).
DOCUMENTATION: https://macs3-project.github.io/MACS/ (documentation
         officielle) · dépôt : https://github.com/macs3-project/MACS
OUTPUT: fichier narrowPeak (ou broadPeak) — variante de BED
         (05_biological_formats/) avec colonnes supplémentaires
         (score d'enrichissement, q-value).
```

---

# 4. Contrôle qualité spécifique ChIP-seq

## 4.1 FRiP (Fraction of Reads in Peaks)

```text
METRIC: FRiP
WHAT: proportion des reads alignés qui tombent à l'intérieur des pics
      appelés.
WHY IT MATTERS: un FRiP élevé indique un enrichissement ChIP efficace ;
      un FRiP très faible peut signaler un anticorps peu spécifique ou
      un échec d'immunoprécipitation.
WHAT IS CONCERNING: pas de seuil universel — les guidelines ENCODE/
      modENCODE (Landt et al. 2012, référence ci-dessous) documentent des
      fourchettes indicatives selon le type de cible, à consulter plutôt
      qu'un seuil arbitraire mémorisé.
CALCUL (via bedtools) :
```
```bash
bedtools intersect -a alignement.final.bam -b pics.narrowPeak -u | samtools view -c
```

## 4.2 deepTools — visualisation et QC

```text
COMMAND: bamCoverage / plotFingerprint / multiBamSummary
PURPOSE: bamCoverage convertit un BAM en signal continu (bigWig) pour
         visualisation (ex. IGV) ; plotFingerprint évalue visuellement
         la spécificité de l'enrichissement ChIP par rapport à l'input ;
         multiBamSummary/plotCorrelation évaluent la corrélation entre
         réplicats.
SYNTAX: bamCoverage -b alignement.final.bam -o signal.bw
        plotFingerprint -b chip.bam input.bam -o fingerprint.png
DOCUMENTATION: https://deeptools.readthedocs.io/ (documentation officielle)
```

## 4.3 IDR — reproductibilité entre réplicats

```text
COMMAND: idr
PURPOSE: quantifier la reproductibilité du classement des pics entre
         deux réplicats biologiques, et déterminer un seuil de
         significativité stable basé sur cette reproductibilité plutôt
         qu'un seuil de p-value arbitraire par réplicat individuel.
SYNTAX: idr --samples replicat1_pics.narrowPeak replicat2_pics.narrowPeak --output-file idr_resultats.txt
DOCUMENTATION: https://github.com/nboley/idr (dépôt officiel, méthode
         standardisée par le consortium ENCODE)
INTERPRETATION: des pics reproductibles entre réplicats biologiques
         indépendants ont beaucoup plus de chances de refléter un
         événement biologique réel qu'un artefact technique propre à un
         seul réplicat.
```

---

# 5. Annotation des pics et analyse de motifs

```text
CONCEPT: une fois les pics obtenus (fichier BED-like), les rattacher aux
         gènes les plus proches (bedtools closest contre une annotation
         GTF/GFF, 14_genome_annotation/) pour formuler des hypothèses de
         régulation, puis rechercher des motifs de liaison enrichis pour
         identifier le facteur de transcription probable ou ses
         partenaires.
```

```text
COMMAND: findMotifsGenome.pl (HOMER)
PURPOSE: découverte de motifs de novo et comparaison à des bases de
         motifs connus, dans les régions des pics identifiés.
SYNTAX: findMotifsGenome.pl pics.narrowPeak genome.fasta resultats_motifs/ -size 200
DOCUMENTATION: http://homer.ucsd.edu/homer/motif/ (documentation officielle)
```

```text
RAPPEL MÉTHODOLOGIQUE (§80) : un pic ChIP-seq indique une association
         physique probable entre la protéine et l'ADN dans les
         conditions expérimentales testées — il NE PROUVE PAS, à lui
         seul, une fonction régulatrice biologique du site (« Peak ≠
         biological function proven »). Une validation fonctionnelle
         complémentaire (rapporteur, CRISPR, expression du gène associé)
         est nécessaire pour établir un lien causal.
```

---

TROUBLESHOOTING
------------------------------------------------------------
```text
SYMPTOM: très peu de pics détectés, ou aucun
CAUSE: échec d'immunoprécipitation (anticorps peu spécifique/inefficace),
       profondeur de séquençage insuffisante, ou paramètre -g (taille de
       génome effective) incorrect.
DIAGNOSIS: examiner plotFingerprint (section 4.2) — une courbe ChIP très
           proche de la diagonale (comme l'input) indique un
           enrichissement faible ou absent.
SOLUTION: vérifier l'anticorps et le protocole expérimental avant de
          blâmer les paramètres bioinformatiques.
PREVENTION: toujours inclure un contrôle input et vérifier le
            fingerprint avant d'investir du temps dans l'aval du pipeline.
```
```text
SYMPTOM: très peu de pics reproductibles entre réplicats (IDR élevé)
CAUSE: variabilité biologique/technique entre réplicats, ou paramètres de
       peak calling incohérents entre les deux runs MACS3.
DIAGNOSIS: vérifier que les deux réplicats ont été traités avec
           exactement les mêmes paramètres (04_bash_scripting/, logging).
SOLUTION: harmoniser les paramètres ; si le problème persiste, envisager
          un problème de qualité d'un des réplicats (retour au QC, module 09).
PREVENTION: journaliser systématiquement les paramètres exacts de chaque
            exécution MACS3.
```

GO FURTHER
------------------------------------------------------------
```text
Topic: ChIP-seq
Official documentation:
  https://macs3-project.github.io/MACS/
  https://deeptools.readthedocs.io/
  https://bedtools.readthedocs.io/
Topics to explore: ATAC-seq (accessibilité chromatinienne, pipeline très
                    proche du ChIP-seq sans anticorps), CUT&RUN/CUT&Tag
                    (alternatives plus récentes au ChIP-seq classique)
```

DOCUMENTATION
------------------------------------------------------------
- MACS3 — https://macs3-project.github.io/MACS/ · source : https://github.com/macs3-project/MACS
- deepTools — https://deeptools.readthedocs.io/ · source : https://github.com/deeptools/deepTools
- bedtools — https://bedtools.readthedocs.io/ · source : https://github.com/arq5x/bedtools2
- IDR — https://github.com/nboley/idr
- HOMER — http://homer.ucsd.edu/homer/motif/
- Picard MarkDuplicates — https://gatk.broadinstitute.org/hc/en-us/articles/35967618836635-MarkDuplicates-Picard

SCIENTIFIC REFERENCES
------------------------------------------------------------
- Zhang Y et al. (2008). "Model-based Analysis of ChIP-Seq (MACS)."
  Genome Biology, 9:R137. DOI: 10.1186/gb-2008-9-9-r137
- Ramírez F et al. (2016). "deepTools2: a next generation web server for
  deep-sequencing data analysis." Nucleic Acids Research, 44(W1):W160-W165.
  DOI: 10.1093/nar/gkw257
- Quinlan AR, Hall IM (2010). "BEDTools: a flexible suite of utilities
  for comparing genomic features." Bioinformatics, 26(6):841-842.
  DOI: 10.1093/bioinformatics/btq033
- Landt SG et al. (2012). "ChIP-seq guidelines and practices of the
  ENCODE and modENCODE consortia." Genome Research, 22(9):1813-1831.
  DOI: 10.1101/gr.136184.111
- Li Q, Brown JB, Huang H, Bickel PJ (2011). "Measuring reproducibility
  of high-throughput experiments." The Annals of Applied Statistics,
  5(3):1752-1779. DOI: 10.1214/11-AOAS466 (référence méthodologique de
  l'IDR)
- Heinz S et al. (2010). "Simple Combinations of Lineage-Determining
  Transcription Factors Prime cis-Regulatory Elements Required for
  Macrophage and B Cell Identities." Molecular Cell, 38(4):576-589.
  DOI: 10.1016/j.molcel.2010.05.004

NEXT MODULE
------------------------------------------------------------
`17_dna_methylation/` — une autre marque épigénétique, avec un pipeline
d'alignement spécifique (bisulfite).
