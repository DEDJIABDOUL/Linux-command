============================================================
MODULE 11 — ASSEMBLAGE DE NOVO
============================================================

OBJECTIVE
------------------------------------------------------------
Reconstruire un génome (ou un contig) à partir de reads bruts, sans
génome de référence, en choisissant un assembleur adapté à la technologie
de séquençage — jamais un assembleur "universel".

PREREQUISITES
------------------------------------------------------------
`09_quality_control/`, `10_adapter_trimming_filtering/` (l'assemblage se
fait toujours sur des reads déjà contrôlés et nettoyés).

BIOLOGICAL CONCEPT
------------------------------------------------------------
```text
read       fragment de séquence brut issu du séquenceur
contig     séquence continue reconstruite par chevauchement de reads
scaffold   plusieurs contigs ordonnés/orientés, séparés par des lacunes
           (gaps) estimées, quand l'information le permet (paired-end,
           long reads couvrant les régions répétées)
coverage   nombre moyen de reads couvrant chaque position du génome
           assemblé — une couverture insuffisante fragmente l'assemblage
misassembly  erreur de reconstruction (réarrangement, inversion,
           duplication) que les reads ne permettaient pas de résoudre
           correctement
```

WHY?
------------------------------------------------------------
Le choix de l'assembleur dépend fondamentalement du TYPE de reads
disponibles : les assembleurs conçus pour des reads courts et précis
(Illumina) reposent sur des graphes de de Bruijn ; ceux conçus pour des
reads longs et bruités (Nanopore/PacBio) reposent sur des graphes de
chevauchement/répétition, tolérants à un taux d'erreur bien plus élevé.
Utiliser le mauvais assembleur pour la mauvaise technologie produit
généralement un assemblage médiocre, même avec des données de bonne
qualité.

---

# 1. Statut vérifié des outils du fichier legacy

## 1.1 Canu — AVERTISSEMENT IMPORTANT

```text
COMMAND: canu -d output_dir -p prefix genomeSize=5m -nanopore reads.fastq
PURPOSE: assemblage de novo de reads longs (PacBio, Nanopore), avec
         correction d'erreurs, trimming et assemblage intégrés.
STATUT VÉRIFIÉ (2026-08-22) : Canu v2.3 (17 décembre 2024) est la
         **dernière release officielle**. Les notes de publication des
         développeurs indiquent explicitement : « Do not expect another
         release. This is it, folks. The sequencing technology has moved
         on and Canu is all but obsolete now. » Canu reste installable et
         fonctionnel (via Bioconda), mais ne recevra plus de mise à jour.
RECOMMANDATION: conserver Canu pour comprendre le principe historique de
         l'assemblage long-read avec correction intégrée (et pour
         reproduire le pipeline du fichier legacy), mais utiliser Flye
         (section 2) pour tout nouvel assemblage long-read en 2026.
DOCUMENTATION: https://github.com/marbl/canu · manuel :
         https://canu.readthedocs.io/en/latest/index.html
```

---

# 2. Assemblage de reads longs (Nanopore/PacBio) — recommandation actuelle

```text
COMMAND: flye
PURPOSE: assembleur de novo pour reads longs bruités (PacBio/ONT), basé
         sur un graphe de répétition, avec sortie de contigs polis.
SYNTAX: flye --nanopore-raw reads.fastq --out-dir resultats_flye/ --threads 8
OPTIONS COURANTES:
  --nanopore-raw / --nanopore-corr / --nanopore-hq   selon le niveau de
         correction déjà appliqué aux reads
  --pacbio-raw / --pacbio-hifi                        équivalents PacBio
  --genome-size                                        taille approximative
         attendue (optionnelle selon version)
STATUT VÉRIFIÉ (2026-08-22) : activement maintenu, dernière release 2.9.6
         (2 mai 2025).
DOCUMENTATION: https://github.com/mikolmogorov/Flye
```

---

# 3. Assemblage de reads courts (Illumina)

```text
COMMAND: spades.py
PURPOSE: assembleur de novo à graphe de de Bruijn pour reads courts
         Illumina, avec des modes dédiés (isolate, meta, rna, plasmid...).
SYNTAX: spades.py --isolate -1 R1.fastq.gz -2 R2.fastq.gz -o resultats_spades/
DOCUMENTATION: https://github.com/ablab/spades (documentation complète :
         https://ablab.github.io/spades/)
```

```text
COMMAND: megahit
PURPOSE: assembleur ultra-rapide et économe en mémoire, optimisé pour la
         métagénomique mais utilisable en assemblage simple.
SYNTAX: megahit -1 R1.fastq.gz -2 R2.fastq.gz -o resultats_megahit/
DOCUMENTATION: https://github.com/voutcn/megahit
```

```text
COMMON ERRORS (tous assembleurs):
  - lancer un assembleur short-read (SPAdes/MEGAHIT) sur des reads longs,
    ou l'inverse — les hypothèses algorithmiques ne correspondent pas,
    résultat systématiquement dégradé, parfois sans message d'erreur clair.
  - négliger la couverture minimale requise par l'outil (documentée dans
    chaque manuel) avant de lancer un assemblage coûteux en temps de calcul.
EXERCISE: pour le dataset SRR18392380 documenté au module 08 (Nanopore,
         SARS-CoV-2), justifier pourquoi Flye est le choix approprié et
         pourquoi SPAdes/MEGAHIT ne le seraient pas directement sur ces
         mêmes reads bruts.
```

---

TROUBLESHOOTING
------------------------------------------------------------
```text
SYMPTOM: assemblage très fragmenté (beaucoup de petits contigs)
CAUSE: couverture insuffisante, reads de mauvaise qualité non filtrés en
       amont (module 10), ou régions répétées non résolues par la
       longueur de read disponible.
DIAGNOSIS: vérifier la couverture moyenne (nombre de bases / taille de
           génome attendue) et revisiter le rapport de QC (module 09).
SOLUTION: augmenter la profondeur de séquençage si possible, ou revoir
          les paramètres de filtrage (module 10) qui ont pu être trop
          stricts.
PREVENTION: toujours estimer la couverture attendue avant de lancer un
            assemblage.
```
```text
SYMPTOM: canu -nanopore échoue avec des reads Nanopore récents haute
         précision (ex. duplex, simplex Q20+)
CAUSE: Canu, figé depuis fin 2024, n'a pas suivi les évolutions récentes
       des chimies de basecalling Nanopore.
DIAGNOSIS: vérifier la version de Canu utilisée et son adéquation avec la
           chimie de séquençage réellement employée.
SOLUTION: utiliser Flye, activement maintenu et mis à jour pour les
          chimies récentes.
PREVENTION: privilégier un outil activement maintenu pour tout nouveau
            projet (voir docs/tools_reference.md).
```

GO FURTHER
------------------------------------------------------------
```text
Topic: assemblage de novo
Official documentation:
  https://github.com/mikolmogorov/Flye
  https://ablab.github.io/spades/
  https://github.com/voutcn/megahit
Topics to explore: assemblage hybride (reads courts + longs), correction
                    d'erreurs pré-assemblage, assemblage de génomes
                    polyploïdes
```

DOCUMENTATION
------------------------------------------------------------
- Canu — https://github.com/marbl/canu · manuel : https://canu.readthedocs.io/en/latest/index.html
- Flye — https://github.com/mikolmogorov/Flye
- SPAdes — https://github.com/ablab/spades · doc : https://ablab.github.io/spades/
- MEGAHIT — https://github.com/voutcn/megahit

SCIENTIFIC REFERENCES
------------------------------------------------------------
- Koren S et al. (2017). "Canu: scalable and accurate long-read assembly
  via adaptive k-mer weighting and repeat separation." Genome Research,
  27(5):722-736. DOI: 10.1101/gr.215087.116
- Kolmogorov M, Yuan J, Lin Y, Pevzner PA (2019). "Assembly of long,
  error-prone reads using repeat graphs." Nature Biotechnology,
  37:540-546. DOI: 10.1038/s41587-019-0072-8
- Li D, Liu CM, Luo R, Sadakane K, Lam TW (2015). "MEGAHIT: an ultra-fast
  single-node solution for large and complex metagenomics assembly via
  succinct de Bruijn graph." Bioinformatics, 31(10):1674-1676.

NEXT MODULE
------------------------------------------------------------
`12_sequence_alignment/` — aligner des reads sur un assemblage ou un
génome de référence.
