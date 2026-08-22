# 20 — Métagénomique

OBJECTIVE
------------------------------------------------------------
Analyser un échantillon environnemental ou microbiome contenant un
mélange d'organismes, par deux approches complémentaires : le profilage
taxonomique direct (qui est présent, en quelle proportion) et
l'assemblage suivi du binning (reconstruction de génomes individuels,
les MAGs).

PREREQUISITES
------------------------------------------------------------
`09_quality_control/`, `10_adapter_trimming_filtering/`,
`11_de_novo_assembly/` (MEGAHIT), `13_assembly_quality/` (BUSCO).

BIOLOGICAL CONCEPT
------------------------------------------------------------
```text
métagénome        ensemble du matériel génétique séquencé directement à
                   partir d'un échantillon environnemental, contenant
                   potentiellement des centaines d'organismes différents,
                   sans isolement/culture préalable.
profilage taxonomique   classification directe des reads (ou k-mers)
                   contre une base de référence, sans étape d'assemblage —
                   rapide, donne une estimation de composition.
binning             regroupement des contigs d'un assemblage métagénomique
                   en groupes correspondant chacun probablement à un seul
                   organisme, sur la base de signatures de composition et
                   de profils de couverture.
MAG                 Metagenome-Assembled Genome : génome reconstruit à
                   partir d'un bin, jamais garanti complet ni pur —
                   toujours accompagné d'une estimation de complétude et
                   de contamination.
```

WHY?
------------------------------------------------------------
Contrairement à un assemblage de génome unique (module 11), un
assemblage métagénomique mélange des organismes de complexité et
d'abondance très différentes — d'où la nécessité d'un binning
post-assemblage pour tenter de séparer à nouveau les génomes individuels,
avec un succès qui dépend fortement de la diversité et de la profondeur
de l'échantillon.

---

# 0. Environnement de ce module

```bash
conda env create -f envs/metagenomics.yml
conda activate metagenomics
```

```text
CONTENU: kraken2, bracken, metabat2, checkm2, gtdbtk — voir
         envs/metagenomics.yml pour le détail. CheckM1 (section 4.3,
         référence historique) n'est pas inclus par défaut.
```

# 1. Deux stratégies, pas une seule

```text
Profilage direct (Kraken2/Bracken)
  Rapide, ne nécessite pas d'assemblage, donne une composition
  taxonomique globale — mais limité à ce qui est déjà représenté dans la
  base de référence utilisée (rien de nouveau ne peut être "découvert",
  seulement classé ou laissé non classifié).

Assemblage + binning (MEGAHIT → MetaBAT2 → CheckM2/GTDB-Tk)
  Plus coûteux en calcul, mais permet de reconstruire des génomes
  potentiellement nouveaux (non représentés dans les bases existantes) et
  d'étudier leur contenu génique complet.
```

---

# 2. Profilage taxonomique avec Kraken2 + Bracken

```text
COMMAND: kraken2
PURPOSE: classifier chaque read contre une base de référence taxonomique
         par correspondance exacte de k-mers, très rapide.
SYNTAX: kraken2 --db base_kraken2/ --paired R1.fastq.gz R2.fastq.gz \
               --report rapport_kraken.txt --output classification.txt
DOCUMENTATION: https://github.com/DerrickWood/kraken2/wiki (wiki officiel,
         manuel complet) · site historique : https://ccb.jhu.edu/software/kraken2/
```

```text
COMMAND: bracken
PURPOSE: ré-estimer statistiquement l'abondance par espèce (ou autre rang
         taxonomique) à partir du rapport Kraken2, en corrigeant les
         biais liés à la longueur/similarité des génomes de référence.
SYNTAX: bracken -d base_kraken2/ -i rapport_kraken.txt -o abondances.txt -l S
DOCUMENTATION: https://github.com/jenniferlu717/Bracken (dépôt officiel)
COMMON ERRORS: interpréter directement le rapport Kraken2 brut comme une
         estimation d'abondance relative fiable — c'est précisément le
         rôle de Bracken de corriger ce biais ; ne pas sauter cette étape.
```

---

# 3. Host removal (retrait de l'ADN hôte)

```text
CONCEPT: pour un échantillon issu d'un hôte (ex. microbiome intestinal
         humain), retirer les reads correspondant au génome de l'hôte
         AVANT le profilage/assemblage — via un alignement (Bowtie2/
         BWA-MEM2, module 12) contre le génome de l'hôte, en conservant
         uniquement les reads NON alignés.
WHY: sans ce retrait, une proportion souvent importante des reads
     (parfois majoritaire) appartient à l'hôte et non au microbiome
     étudié, faussant toutes les estimations d'abondance en aval.
```

---

# 4. Assemblage et binning

## 4.1 Assemblage (rappel module 11)

```bash
megahit -1 R1_sans_hote.fastq.gz -2 R2_sans_hote.fastq.gz -o resultats_megahit/
```

## 4.2 Binning avec MetaBAT2

```text
COMMAND: metabat2
PURPOSE: regrouper les contigs d'un assemblage métagénomique en bins
         (génomes candidats), à partir de leur composition en
         tétranucléotides et de leur profil de couverture (calculé sur
         plusieurs échantillons si disponibles).
SYNTAX: jgi_summarize_bam_contig_depths --outputDepth profondeur.txt alignement_tri.bam
        metabat2 -i assembly.fasta -a profondeur.txt -o bins/bin
DOCUMENTATION: https://bitbucket.org/berkeleylab/metabat (dépôt officiel,
         hébergé sur Bitbucket et non GitHub)
```

## 4.3 Évaluation de la qualité des MAGs avec CheckM2

```text
COMMAND: checkm2 predict
PURPOSE: estimer la complétude et la contamination de chaque bin/MAG, via
         un modèle de machine learning entraîné sur un grand nombre de
         génomes de référence — approche indépendante de la lignée
         taxonomique, contrairement à CheckM1.
SYNTAX: checkm2 predict --input bins/ --output-directory resultats_checkm2/
STATUT VÉRIFIÉ (2026-08-22) : CheckM2 (dépôt chklovski/CheckM2) est
         l'outil actuellement recommandé, plus rapide et plus précis que
         CheckM1 selon la publication de référence (Chklovski et al.
         2023) — CheckM1 (Ecogenomics/CheckM) reste maintenu et largement
         cité, mais CheckM2 est préférable pour un nouveau projet.
DOCUMENTATION: https://github.com/chklovski/CheckM2
INTERPRETATION: un MAG est classiquement qualifié de « haute qualité »
         selon des seuils combinés de complétude ET de contamination
         (par ex. > 90% complétude, < 5% contamination selon les
         standards MIMAG) — ne jamais juger un MAG sur la seule
         complétude sans considérer la contamination.
```

## 4.4 Classification taxonomique des MAGs avec GTDB-Tk

```text
COMMAND: gtdbtk classify_wf
PURPOSE: assigner une classification taxonomique standardisée à chaque
         MAG, selon la Genome Taxonomy Database (GTDB) — une taxonomie
         basée sur la phylogénomique, potentiellement différente de la
         taxonomie NCBI classique pour certains taxons.
SYNTAX: gtdbtk classify_wf --genome_dir bins_qc_filtres/ --out_dir resultats_gtdbtk/ --cpus 8
DOCUMENTATION: https://ecogenomics.github.io/GTDBTk/ (documentation
         officielle) · dépôt : https://github.com/Ecogenomics/GTDBTk
COMMON ERRORS: comparer directement une classification GTDB à une
         classification NCBI sans noter qu'il s'agit de deux systèmes
         taxonomiques distincts, qui peuvent diverger notablement pour
         certains groupes (réorganisations phylogénomiques importantes).
```

---

TROUBLESHOOTING
------------------------------------------------------------
```text
SYMPTOM: une grande proportion de reads reste "unclassified" par Kraken2
CAUSE: organismes non représentés dans la base de référence utilisée
       (bases de référence toujours incomplètes, en particulier pour des
       environnements peu étudiés), ou base de référence trop restreinte.
DIAGNOSIS: vérifier la base utilisée et sa date de construction/mise à
           jour — une base ancienne ou restreinte à quelques taxons
           produit systématiquement plus de reads non classifiés.
SOLUTION: envisager une base plus large (selon les ressources
          disponibles), ou reconnaître que l'assemblage+binning
          (section 4) peut révéler des organismes absents de la base de
          classification directe.
PREVENTION: documenter systématiquement la version et la date de la base
            Kraken2 utilisée (07_project_organization/, reproductibilité).
```
```text
SYMPTOM: de nombreux bins MetaBAT2 ont une contamination CheckM2 élevée
CAUSE: mélange de plusieurs organismes proches dans un même bin —
       fréquent dans les communautés microbiennes complexes ou peu
       profondément séquencées, où la résolution du binning est limitée.
DIAGNOSIS: examiner la profondeur de séquençage et la diversité de
           l'échantillon.
SOLUTION: filtrer les bins de mauvaise qualité avant l'annotation ou la
          classification GTDB-Tk (section 4.4) plutôt que de les
          conserver tels quels.
PREVENTION: ne jamais présenter un MAG à forte contamination comme un
            génome fiable sans filtrage qualité préalable.
```

GO FURTHER
------------------------------------------------------------
```text
Topic: métagénomique
Official documentation:
  https://github.com/DerrickWood/kraken2/wiki
  https://bitbucket.org/berkeleylab/metabat
  https://github.com/chklovski/CheckM2
  https://ecogenomics.github.io/GTDBTk/
Topics to explore: métagénomique fonctionnelle (assignation fonctionnelle
                    des MAGs, via les outils du module 14_genome_annotation/),
                    métatranscriptomique, séquençage long-read appliqué à
                    la métagénomique (meilleure résolution de binning)
```

DOCUMENTATION
------------------------------------------------------------
- Kraken2 — https://github.com/DerrickWood/kraken2/wiki
- Bracken — https://github.com/jenniferlu717/Bracken
- MetaBAT2 — https://bitbucket.org/berkeleylab/metabat
- CheckM2 — https://github.com/chklovski/CheckM2
- CheckM1 (référence historique, toujours maintenu) — https://github.com/Ecogenomics/CheckM
- GTDB-Tk — https://ecogenomics.github.io/GTDBTk/ · source : https://github.com/Ecogenomics/GTDBTk

SCIENTIFIC REFERENCES
------------------------------------------------------------
- Wood DE, Lu J, Langmead B (2019). "Improved metagenomic analysis with
  Kraken 2." Genome Biology, 20:257. DOI: 10.1186/s13059-019-1891-0
- Lu J, Breitwieser FP, Thielen P, Salzberg SL (2017). "Bracken:
  estimating species abundance in metagenomics data." PeerJ Computer
  Science, 3:e104. DOI: 10.7717/peerj-cs.104
- Kang DD et al. (2019). "MetaBAT 2: an adaptive binning algorithm for
  robust and efficient genome reconstruction from metagenome assemblies."
  PeerJ, 7:e7359. DOI: 10.7717/peerj.7359
- Parks DH, Imelfort M, Skennerton CT, Hugenholtz P, Tyson GW (2015).
  "CheckM: assessing the quality of microbial genomes recovered from
  isolates, single cells, and metagenomes." Genome Research, 25(7):1043-1055.
  DOI: 10.1101/gr.186072.114 (référence d'origine de CheckM1)
- Chklovski A, Parks DH, Woodcroft BJ, Tyson GW (2023). "CheckM2: a
  rapid, scalable and accurate tool for assessing microbial genome
  quality using machine learning." Nature Methods, 20:1203-1212.
  DOI: 10.1038/s41592-023-01940-w (recommandé pour les nouveaux projets)
- Chaumeil PA, Mussig AJ, Hugenholtz P, Parks DH (2020). "GTDB-Tk: a
  toolkit to classify genomes with the Genome Taxonomy Database."
  Bioinformatics, 36(6):1925-1927. DOI: 10.1093/bioinformatics/btz848

NEXT MODULE
------------------------------------------------------------
`21_variant_analysis/` — l'appel de variants proprement dit, en amont
du GWAS déjà traité au module 18.
