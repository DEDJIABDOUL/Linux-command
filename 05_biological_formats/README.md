============================================================
MODULE 05 — FORMATS BIOLOGIQUES : FASTA, FASTQ, ET INTRODUCTION À SAM/BAM/VCF/BED/GFF/GTF
============================================================

OBJECTIVE
------------------------------------------------------------
Comprendre en profondeur la structure, le rôle et les limites des formats
de données incontournables en bioinformatique, avant de les manipuler avec
des outils dédiés dans les modules suivants (QC, alignement, variant
calling — phases ultérieures du programme).

PREREQUISITES
------------------------------------------------------------
`01_linux_basics/` à `04_bash_scripting/`.

NOTE DE PORTÉE
------------------------------------------------------------
Ce module est volontairement **conceptuel**. Générer soi-même un vrai
fichier SAM/BAM (via un aligneur) ou VCF (via un appelant de variants)
relève des modules d'alignement et de variant calling, prévus dans les
phases suivantes du programme (voir `docs/audit_report.md`). Ici,
l'objectif est de savoir **reconnaître, lire et interpréter** ces formats
quand on les rencontre.

---

# 1. FASTA, approfondissement

```text
>identifiant description_optionnelle
SEQUENCE (ADN, ARN ou protéine, repliée ou non sur plusieurs lignes)
```

L'alphabet ADN/ARN attendu est `A C G T` (ADN) ou `A C G U` (ARN), plus
`N` pour une base indéterminée. L'alphabet protéique regroupe les 20
acides aminés standards (codes à une lettre), plus quelques codes
d'ambiguïté. Les minuscules (`a c g t`) signalent conventionnellement des
régions « soft-masked », souvent des répétitions génomiques : le contenu
biologique est identique, seule la casse porte une information
d'annotation.

```text
COMMON ERRORS: confondre une région soft-maskée (minuscule) avec une
         base de qualité différente — la casse en FASTA n'encode AUCUNE
         qualité, contrairement à FASTQ.
DOCUMENTATION: aucune norme unique centralisée pour FASTA (format
         historique, NCBI en documente l'usage) ; en pratique, le format
         attendu par les outils modernes est celui décrit par la
         spécification htslib : https://github.com/samtools/hts-specs
```

---

# 2. FASTQ — l'encodage de qualité Phred

```text
@identifiant_du_read commentaire_optionnel
SEQUENCE
+ (identifiant répété ou vide)
QUALITE (même longueur que SEQUENCE, un caractère par base)
```

BIOLOGICAL CONCEPT
------------------------------------------------------------
Chaque caractère de la ligne de qualité encode un score Phred `Q`, qui
représente la probabilité d'erreur estimée par le séquenceur pour la base
correspondante :

```text
Q = -10 × log10(P_erreur)
```

| Score Phred (Q) | Probabilité d'erreur | Précision |
|---|---|---|
| 10 | 1/10 | 90 % |
| 20 | 1/100 | 99 % |
| 30 | 1/1000 | 99.9 % |
| 40 | 1/10000 | 99.99 % |

L'encodage standard actuel (Illumina 1.8+, Sanger) est **Phred+33** : le
score Q est représenté par le caractère ASCII dont le code vaut `Q + 33`.
Exemple : `!` (code ASCII 33) correspond à Q0 (qualité minimale/absente),
`I` (code ASCII 73) correspond à Q40.

```text
COMMON ERRORS: d'anciens fichiers (avant 2011, notamment certains
         pipelines Illumina très anciens) pouvaient utiliser un encodage
         Phred+64. Mélanger les deux encodages sans le savoir fausse
         silencieusement toute analyse de qualité en aval. En cas de
         doute sur un fichier ancien ou d'origine incertaine, vérifier
         l'encodage réel (des outils de QC modernes comme FastQC le
         détectent automatiquement — module ultérieur) avant tout
         traitement.
```

Single-end vs paired-end :

```text
Single-end : un seul fichier FASTQ par échantillon (un read par fragment
             d'ADN séquencé dans un seul sens).
Paired-end : deux fichiers FASTQ appariés (souvent suffixés _R1/_R2),
             chaque paire de reads correspondant aux deux extrémités d'un
             même fragment d'ADN, séquencées dans les deux sens.
```

```text
DOCUMENTATION: pas de norme centralisée unique pour FASTQ non plus ; la
         référence pratique la plus citée reste :
         Cock PJA et al. (2010) "The Sanger FASTQ file format for
         sequences with quality scores, and the Solexa/Illumina FASTQ
         variants." Nucleic Acids Research 38(6):1767-1771.
         DOI: 10.1093/nar/gkp1137
EXERCISE: dans linux/reads.fastq, extraire la ligne de qualité du premier
         read et calculer manuellement le score Phred du premier
         caractère.
```
```bash
sed -n '4p' reads.fastq | cut -c1     # premier caractère de qualité du 1er read
```

---

# 3. SAM / BAM / CRAM — alignements

```text
CONCEPT: un fichier d'alignement associe chaque read à une position sur
         un génome de référence (ou signale qu'il ne s'aligne nulle
         part). SAM est la version texte, BAM sa version binaire
         compressée (même contenu, bien plus compact et rapide à
         indexer), CRAM une version encore plus compressée qui peut
         référencer le génome pour économiser de l'espace.
```

Structure SAM simplifiée (en-tête `@`, puis une ligne par read aligné,
colonnes séparées par des tabulations) :

```text
@HD  VN:1.6  SO:coordinate
@SQ  SN:chr1  LN:248956422
QNAME  FLAG  RNAME  POS  MAPQ  CIGAR  RNEXT  PNEXT  TLEN  SEQ  QUAL
read001  0    chr1    100   60    100M   *      0     0    ACGT...  IIII...
```

```text
INTERPRETATION DES COLONNES CLÉS:
  QNAME  nom du read
  FLAG   code numérique bit-à-bit décrivant l'alignement (apparié,
         brin inverse, alignement secondaire...)
  RNAME  chromosome/séquence de référence
  POS    position de début de l'alignement (1-based)
  MAPQ   qualité de mapping (confiance de l'alignement, échelle Phred-like)
  CIGAR  description alignement/insertions/délétions (ex. 100M = 100 bases
         alignées sans indel)
COMMON ERRORS: interpréter un FLAG sans le décoder correctement — chaque
         bit a une signification précise (ex. bit 4 = read non aligné) ;
         ne jamais deviner un FLAG « à l'œil ».
DOCUMENTATION: spécification officielle SAM/BAM/CRAM (dépôt
         samtools/hts-specs, mainteneur du standard) :
         https://github.com/samtools/hts-specs
         version publiée : https://samtools.github.io/hts-specs/
OUTIL DE RÉFÉRENCE: samtools (`view`, `sort`, `index`, `flagstat`, `stats`)
         — site officiel https://www.htslib.org · dépôt source
         https://github.com/samtools/samtools (traité en détail dans les
         modules d'alignement, phase ultérieure).
```

---

# 4. BED / GFF3 / GTF — annotations de régions génomiques

```text
CONCEPT COMMUN: ces trois formats décrivent des régions ou des features
         (gènes, exons, pics ChIP-seq...) sur un génome de référence,
         mais avec des conventions différentes — ne jamais les confondre
         silencieusement.
```

## 4.1 BED (Browser Extensible Data)

```text
chr1    1000    2000    feature_1    0    +
```

```text
STRUCTURE: texte tabulaire, 3 colonnes obligatoires (chromosome, début,
         fin) + jusqu'à 9 colonnes optionnelles (nom, score, brin...).
PIÈGE FONDAMENTAL: les coordonnées BED sont 0-based, demi-ouvertes
         ([début, fin[) : la ligne ci-dessus décrit les bases 1001 à 2000
         en numérotation 1-based habituelle, PAS la base 1000.
DOCUMENTATION: UCSC Genome Browser FAQ (référence historique et la plus
         citée) : https://genome.ucsc.edu/FAQ/FAQformat.html
         Spécification formelle plus récente (2021, GA4GH) publiée dans
         hts-specs : https://samtools.github.io/hts-specs/BEDv1.pdf
OUTIL DE RÉFÉRENCE: bedtools (module ultérieur).
```

## 4.2 GFF3 (General Feature Format v3)

```text
chr1  source  gene  1001  9000  .  +  .  ID=gene1;Name=BRCA1
```

```text
STRUCTURE: 9 colonnes tabulées ; coordonnées 1-based, intervalle fermé
         (contrairement à BED). La 9e colonne (attributs) encode une
         hiérarchie (gène → transcrit → exon) via des clés=valeurs.
DOCUMENTATION: spécification officielle, Sequence Ontology Project :
         https://github.com/The-Sequence-Ontology/Specifications/blob/master/gff3.md
```

## 4.3 GTF (Gene Transfer Format, ≈ GFF2)

```text
chr1  source  gene  1001  9000  .  +  .  gene_id "BRCA1"; gene_name "BRCA1";
```

```text
STRUCTURE: même structure générale que GFF3 (9 colonnes, coordonnées
         1-based), mais la 9e colonne suit une syntaxe différente
         (clé "valeur"; plutôt que clé=valeur;), et ne représente que
         2 niveaux de hiérarchie contre une hiérarchie arbitraire pour
         GFF3.
COMMON ERRORS: traiter un fichier GTF avec un parseur écrit pour GFF3 (ou
         inversement) sans adapter le format des attributs — erreur
         fréquente qui casse silencieusement l'extraction d'attributs.
DOCUMENTATION: documentation Ensembl du format GFF/GTF (référence la plus
         citée en pratique) : https://www.ensembl.org/info/website/upload/gff.html
```

---

# 5. VCF / BCF — variants génomiques

```text
##fileformat=VCFv4.2
#CHROM  POS  ID  REF  ALT  QUAL  FILTER  INFO       FORMAT  SAMPLE1
chr1    150  .   A    G    99    PASS    DP=30;AF=0.5  GT:DP  0/1:30
```

```text
STRUCTURE: en-tête de métadonnées (lignes ##...), une ligne d'en-tête de
         colonnes (#CHROM...), puis une ligne par variant. BCF est
         l'équivalent binaire compressé et indexé de VCF (même relation
         que SAM/BAM).
INTERPRETATION DES COLONNES CLÉS:
  REF/ALT  allèle de référence / allèle(s) alternatif(s) observé(s)
  QUAL     confiance du variant appelé (échelle Phred-like)
  FILTER   PASS si le variant passe tous les filtres appliqués, sinon le
           nom du filtre qui l'a rejeté
  FORMAT/SAMPLE  génotype par échantillon (GT), ex. 0/1 = hétérozygote
DOCUMENTATION: spécification officielle, maintenue par la Global Alliance
         for Genomics & Health dans le dépôt samtools/hts-specs :
         https://github.com/samtools/hts-specs
OUTIL DE RÉFÉRENCE: bcftools (module variant calling, phase ultérieure).
```

---

# 6. Autres formats à connaître (aperçu)

```text
PAF  Pairwise mApping Format — sortie texte tabulaire de minimap2 pour
     des alignements approximatifs (long reads, overlaps) ; rencontré
     dans le module d'assemblage.
FAI  index d'un fichier FASTA (généré par `samtools faidx`), permettant
     un accès direct à une sous-région sans relire tout le fichier.
```

---

TROUBLESHOOTING
------------------------------------------------------------
```text
SYMPTOM: une coordonnée extraite d'un fichier BED ne correspond pas à la
         position attendue quand on la compare « à la main » à une
         séquence FASTA
CAUSE: confusion entre les coordonnées 0-based demi-ouvertes de BED et
       les coordonnées 1-based fermées de GFF3/GTF/VCF/FASTA.
DIAGNOSIS: relire la définition exacte du format concerné (section 4).
SOLUTION: toujours convertir explicitement entre systèmes de coordonnées
          au lieu de supposer qu'un chiffre de position est directement
          comparable d'un format à l'autre.
PREVENTION: documenter systématiquement, dans un pipeline, le système de
            coordonnées utilisé à chaque étape.
```
```text
SYMPTOM: un score de qualité FASTQ semble aberrant (très élevé ou négatif
         après un calcul manuel)
CAUSE: encodage Phred+64 au lieu de Phred+33 supposé, ou erreur de calcul
       de l'offset ASCII.
DIAGNOSIS: vérifier l'origine et l'ancienneté du fichier ; un outil de QC
           dédié détecte l'encodage automatiquement.
SOLUTION: ne jamais supposer l'encodage sans vérification sur un fichier
          d'origine incertaine.
PREVENTION: les données Illumina modernes (1.8+) sont en Phred+33 — le
            risque concerne surtout d'anciens jeux de données archivés.
```

GO FURTHER
------------------------------------------------------------
```text
Topic: formats haut débit (SAM/BAM/CRAM/VCF/BCF)
Official documentation: https://github.com/samtools/hts-specs
Topics to explore: codes FLAG SAM en détail, chaînes CIGAR avancées
                    (indels, clipping), champs INFO/FORMAT personnalisés VCF

Topic: formats d'annotation (BED/GFF3/GTF)
Official documentation:
  https://genome.ucsc.edu/FAQ/FAQformat.html
  https://github.com/The-Sequence-Ontology/Specifications/blob/master/gff3.md
  https://www.ensembl.org/info/website/upload/gff.html
Topics to explore: conversion GTF ↔ GFF3, BED12 (structure exon/intron)
```

DOCUMENTATION
------------------------------------------------------------
- Spécifications SAM/BAM/CRAM/VCF/BCF (samtools/hts-specs) — https://github.com/samtools/hts-specs
- samtools (site officiel) — https://www.htslib.org · source — https://github.com/samtools/samtools
- UCSC Genome Browser FAQ (BED) — https://genome.ucsc.edu/FAQ/FAQformat.html
- Sequence Ontology GFF3 spec — https://github.com/The-Sequence-Ontology/Specifications/blob/master/gff3.md
- Ensembl GFF/GTF format — https://www.ensembl.org/info/website/upload/gff.html

SCIENTIFIC REFERENCES
------------------------------------------------------------
- Cock PJA, Fields CJ, Goto N, Heuer ML, Rice PM (2010). "The Sanger FASTQ
  file format for sequences with quality scores, and the Solexa/Illumina
  FASTQ variants." Nucleic Acids Research, 38(6):1767-1771.
  DOI: 10.1093/nar/gkp1137
- Li H et al. (2009). "The Sequence Alignment/Map format and SAMtools."
  Bioinformatics, 25(16):2078-2079. DOI: 10.1093/bioinformatics/btp352

NEXT MODULE
------------------------------------------------------------
`06_environment_management/` — installer, avec Conda/Mamba/Bioconda, les
premiers outils qui produisent et manipulent réellement ces formats.
