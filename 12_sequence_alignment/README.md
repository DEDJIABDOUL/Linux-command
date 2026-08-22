============================================================
MODULE 12 — ALIGNEMENT DE SÉQUENCES
============================================================

OBJECTIVE
------------------------------------------------------------
Positionner des reads sur un génome de référence ou un assemblage, en
choisissant un aligneur adapté au type de données (ADN vs ARN, reads
courts vs longs), et produire un fichier SAM/BAM exploitable par les
outils en aval (`05_biological_formats/`, section 3).

PREREQUISITES
------------------------------------------------------------
`05_biological_formats/` (structure SAM/BAM), `10_adapter_trimming_filtering/`,
`11_de_novo_assembly/` (pour l'alignement contre un assemblage propre).

WHY?
------------------------------------------------------------
```text
DNA alignment          l'ADN ne subit pas d'épissage : chaque read doit
                        correspondre à une région CONTIGUË du génome
                        (à l'exception d'indels courts).
RNA alignment           un read issu d'un ARNm mature peut chevaucher une
                        jonction exon-exon : l'aligneur doit tolérer de
                        grands "trous" (introns) dans l'alignement —
                        un aligneur ADN classique échouerait ou
                        produirait un alignement incorrect sur ces reads.
Long-read alignment      les reads longs (Nanopore/PacBio) ont un taux
                        d'erreur par base plus élevé que l'Illumina ;
                        l'algorithme d'alignement doit être tolérant à ce
                        bruit plutôt qu'optimisé pour une correspondance
                        quasi parfaite.
Pseudoalignment          (Salmon/kallisto, hors du périmètre de ce module)
                        détermine de quel transcrit un read est le plus
                        probablement issu SANS calculer un alignement
                        base par base complet — beaucoup plus rapide,
                        mais ne produit pas de coordonnées génomiques
                        exploitables de la même façon.
```

```text
RÈGLE: ne jamais utiliser un aligneur ADN classique (BWA-MEM2, Bowtie2)
       pour aligner des reads RNA-seq sur un génome (par opposition à un
       transcriptome) sans capacité d'épissage — les reads chevauchant
       une jonction exon-exon seraient mal alignés ou rejetés.
```

---

# 1. Minimap2 — reads longs et usages polyvalents

```text
COMMAND: minimap2
PURPOSE: aligneur polyvalent pour reads longs (Nanopore/PacBio) et
         également utilisable pour de l'ADN court, la détection
         d'overlaps entre reads (utilisé par Racon, module précédent), et
         l'alignement de longs ARNm avec épissage (mode spécifique).
SYNTAX: minimap2 -ax map-ont reference.fasta reads.fastq > alignement.sam
        minimap2 reference.fasta reads.fastq > overlaps.paf   (mode PAF, sans -a)
OPTIONS DE PRESET COURANTES:
  -ax map-ont     reads Nanopore vs référence (sortie SAM)
  -ax map-pb      reads PacBio (CLR) vs référence
  -ax map-hifi    reads PacBio HiFi vs référence
  -ax splice      ARNm avec épissage (RNA-seq long-read)
STATUT VÉRIFIÉ (2026-08-22): activement maintenu, dernière release
         2.31 (19 mai 2026). Le fichier `legacy/installation_and_execution.txt`
         fige la version v2.24 (2022) — une version bien plus récente est
         disponible et doit être préférée pour tout nouvel usage.
DOCUMENTATION: https://github.com/lh3/minimap2
EXERCISE: comparer la sortie PAF (utilisée dans le fichier legacy pour
         Racon) et la sortie SAM (-a) sur les mêmes reads — quelles
         colonnes sont communes, lesquelles sont spécifiques à chaque
         format (voir 05_biological_formats/, sections 3 et 6) ?
```

---

# 2. Reads courts ADN

```text
COMMAND: bwa-mem2 mem
PURPOSE: alignement de reads courts Illumina sur un génome de référence ;
         réimplémentation accélérée de l'algorithme BWA-MEM original
         (mêmes résultats, 1.3-3.1x plus rapide selon le cas d'usage).
SYNTAX: bwa-mem2 index reference.fasta
        bwa-mem2 mem -t 8 reference.fasta R1.fastq.gz R2.fastq.gz > alignement.sam
DOCUMENTATION: https://github.com/bwa-mem2/bwa-mem2
```

```text
COMMAND: bowtie2
PURPOSE: alignement de reads courts, historiquement très utilisé et
         toujours largement employé (notamment ChIP-seq, phases
         ultérieures), avec un contrôle fin de la sensibilité.
SYNTAX: bowtie2-build reference.fasta index_prefix
        bowtie2 -x index_prefix -1 R1.fastq.gz -2 R2.fastq.gz -S alignement.sam
DOCUMENTATION: https://bowtie-bio.sourceforge.net/bowtie2/index.shtml
         (manuel officiel) · source : https://github.com/BenLangmead/bowtie2
```

---

# 3. Reads courts ARN (RNA-seq, aligneurs "splice-aware")

```text
COMMAND: STAR
PURPOSE: aligneur RNA-seq tolérant à l'épissage, très utilisé en
         production (rapide, précis sur les jonctions).
SYNTAX (aperçu — traité en détail en 15_rnaseq/, phase ultérieure) :
        STAR --genomeDir index/ --readFilesIn R1.fastq.gz R2.fastq.gz --readFilesCommand zcat
DOCUMENTATION: https://github.com/alexdobin/STAR (manuel :
         doc/STARmanual.pdf dans le dépôt)
```

```text
COMMAND: hisat2
PURPOSE: aligneur RNA-seq tolérant à l'épissage, plus économe en mémoire
         que STAR (index basé sur un graphe FM hiérarchique).
SYNTAX: hisat2 -x index_prefix -1 R1.fastq.gz -2 R2.fastq.gz -S alignement.sam
DOCUMENTATION: https://daehwankimlab.github.io/hisat2/ (site officiel) ·
         source : https://github.com/DaehwanKimLab/hisat2
```

```text
NOTE DE PORTÉE: STAR et HISAT2 sont traités ici uniquement au niveau
         "quel outil pour quel besoin". Leur usage complet (construction
         d'index, options de comptage) est développé dans le module
         `15_rnaseq/`.
```

---

# 4. Manipuler le résultat : samtools (rappel)

```text
COMMAND: samtools view -b alignement.sam > alignement.bam
COMMAND: samtools sort alignement.bam -o alignement.sorted.bam
COMMAND: samtools index alignement.sorted.bam
COMMAND: samtools flagstat alignement.sorted.bam
PURPOSE: convertir SAM→BAM, trier par coordonnée (requis par la plupart
         des outils en aval), indexer (accès rapide par région), et
         obtenir un résumé du taux d'alignement.
DOCUMENTATION: https://www.htslib.org (déjà introduit en 05_biological_formats/)
INTERPRETATION IMPORTANTE (rappel §80 de la charte pédagogique) : un taux
         d'alignement élevé rapporté par flagstat NE garantit PAS que la
         conclusion biologique tirée en aval est correcte — ce n'est
         qu'un indicateur technique de la qualité du mapping, pas de la
         validité de l'hypothèse biologique testée.
```

---

TROUBLESHOOTING
------------------------------------------------------------
```text
SYMPTOM: taux d'alignement anormalement bas
CAUSE: mauvaise référence (mauvais organisme/assemblage/version),
       adaptateurs non retirés (module 10), ou aligneur inadapté au type
       de données (ex. reads RNA-seq alignés avec un aligneur non
       splice-aware sur le génome plutôt que le transcriptome).
DIAGNOSIS: vérifier la provenance et la version exacte de la référence
           (module 08), et le type de reads (module 05/09).
SOLUTION: corriger la référence ou l'outil utilisé selon le diagnostic.
PREVENTION: toujours documenter précisément la référence utilisée
            (module 07, data/reference/).
```
```text
SYMPTOM: erreur "index not found" au lancement de l'alignement
CAUSE: absence d'indexation préalable de la référence (bwa-mem2 index /
       bowtie2-build / index STAR).
DIAGNOSIS: vérifier la présence des fichiers d'index attendus.
SOLUTION: indexer la référence avant l'alignement — étape obligatoire,
          non implicite, pour tous les aligneurs de cette section.
PREVENTION: intégrer systématiquement l'étape d'indexation dans le
            script du pipeline (04_bash_scripting/).
```

GO FURTHER
------------------------------------------------------------
```text
Topic: alignement de séquences
Official documentation:
  https://github.com/lh3/minimap2
  https://github.com/bwa-mem2/bwa-mem2
  https://bowtie-bio.sourceforge.net/bowtie2/index.shtml
Topics to explore: alignement paired-end vs single-end, alignements
                    secondaires/supplémentaires (flags SAM), pseudoalignement
                    (Salmon/kallisto, traité en 15_rnaseq/)
```

DOCUMENTATION
------------------------------------------------------------
- minimap2 — https://github.com/lh3/minimap2
- BWA-MEM2 — https://github.com/bwa-mem2/bwa-mem2
- Bowtie2 — https://bowtie-bio.sourceforge.net/bowtie2/index.shtml · source : https://github.com/BenLangmead/bowtie2
- STAR — https://github.com/alexdobin/STAR
- HISAT2 — https://daehwankimlab.github.io/hisat2/ · source : https://github.com/DaehwanKimLab/hisat2
- samtools — https://www.htslib.org

SCIENTIFIC REFERENCES
------------------------------------------------------------
- Li H (2018). "Minimap2: pairwise alignment for nucleotide sequences."
  Bioinformatics, 34(18):3094-3100. DOI: 10.1093/bioinformatics/bty191
- Langmead B, Salzberg SL (2012). "Fast gapped-read alignment with
  Bowtie 2." Nature Methods, 9(4):357-359. DOI: 10.1038/nmeth.1923
- Dobin A et al. (2013). "STAR: ultrafast universal RNA-seq aligner."
  Bioinformatics, 29(1):15-21. DOI: 10.1093/bioinformatics/bts635
- Kim D, Paggi JM, Park C, Bennett C, Salzberg SL (2019). "Graph-based
  genome alignment and genotyping with HISAT2 and HISAT-genotype."
  Nature Biotechnology, 37(8):907-915. DOI: 10.1038/s41587-019-0201-4

NEXT MODULE
------------------------------------------------------------
`13_assembly_quality/` — évaluer la qualité d'un assemblage (QUAST, BUSCO).
