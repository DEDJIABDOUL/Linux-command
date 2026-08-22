============================================================
MODULE 13 — POLISHING ET QUALITÉ D'ASSEMBLAGE
============================================================

OBJECTIVE
------------------------------------------------------------
Améliorer un assemblage brut par polishing (correction à partir des reads
réalignés), puis l'évaluer avec plusieurs métriques complémentaires —
jamais une seule métrique isolée.

PREREQUISITES
------------------------------------------------------------
`11_de_novo_assembly/`, `12_sequence_alignment/`.

WHY?
------------------------------------------------------------
```text
assemblage brut
      ↓
alignement des reads sur l'assemblage (module 12)
      ↓
polishing (ce module, section 1)
      ↓
nouvel assemblage corrigé
      ↓
contrôle qualité (ce module, sections 2-3)
```
Un assembleur long-read produit un brouillon dont le taux d'erreur reste
proche de celui des reads bruts. Le polishing recalcule un consensus plus
précis en réalignant les mêmes reads (ou des reads courts complémentaires)
contre ce brouillon.

---

# 1. Polishing avec Racon

```text
COMMAND: racon
PURPOSE: module de consensus autonome et rapide pour corriger un
         assemblage brut à partir des reads originaux et de leur
         alignement contre cet assemblage (overlaps).
SYNTAX (reprise du fichier legacy) :
        racon -u reads.fastq overlaps.paf contigs.fasta > contigs_polished.fasta
INPUT: les reads originaux, un fichier d'overlaps (PAF, produit par
       minimap2 — module 12), et l'assemblage brut à corriger.
STATUT VÉRIFIÉ (2026-08-22) : le dépôt original `isovic/racon` (référencé
         dans `legacy/installation_and_execution.txt`) affiche désormais
         un avis officiel indiquant qu'il n'est plus maintenu, et redirige
         vers le nouveau dépôt officiel :
         **https://github.com/lbcb-sci/racon**
DOCUMENTATION: https://github.com/lbcb-sci/racon (dépôt officiel actuel)
COMMON ERRORS: utiliser encore l'ancienne URL `isovic/racon` dans un
         script d'installation — mettre à jour vers `lbcb-sci/racon`.
EXERCISE: sur le pipeline du fichier legacy (Canu → minimap2 → Racon →
         QUAST), remplacer Canu par Flye (module 11) et minimap2 par sa
         version actuelle (module 12), en gardant Racon pour le polishing,
         puis documenter chaque changement de version dans un log
         (04_bash_scripting/, section 5.5).
```

---

# 2. QUAST — statistiques d'assemblage

```text
COMMAND: quast.py
PURPOSE: calculer un ensemble de métriques standard d'assemblage,
         éventuellement en comparaison avec un génome de référence.
SYNTAX (reprise du fichier legacy) :
        quast.py assembly.fasta -o resultats_quast/
STATUT VÉRIFIÉ (2026-08-22): activement maintenu, version actuelle 5.3.0.
DOCUMENTATION: https://github.com/ablab/quast (dépôt officiel) · manuel
         détaillé : https://quast.sourceforge.net/docs/manual.html
```

### Interprétation des métriques clés

```text
METRIC: N50
WHAT: longueur L telle que 50% du total assemblé est contenu dans des
      contigs de longueur ≥ L.
WHY IT MATTERS: mesure la contiguïté de l'assemblage.
WHAT IS CONCERNING: un N50 élevé N'EST PAS automatiquement un meilleur
      assemblage — un assembleur peut produire de longs contigs en
      fusionnant à tort des régions répétées (misassembly), gonflant le
      N50 artificiellement. TOUJOURS croiser avec le nombre de
      misassemblies rapporté et, si possible, une évaluation de
      complétude (BUSCO, section 3).
```

```text
METRIC: L50, N90
WHAT: L50 = nombre minimal de contigs dont la somme atteint 50% de la
      taille totale ; N90 = équivalent de N50 pour un seuil de 90%.
WHY IT MATTERS: complètent le N50 pour juger la distribution complète des
      tailles de contigs, pas seulement son centre.
```

```text
METRIC: # misassemblies (nécessite un génome de référence)
WHAT: nombre de points où l'assemblage diffère structurellement d'une
      référence (réarrangement, inversion, translocation).
WHY IT MATTERS: un assemblage avec un excellent N50 mais de nombreuses
      misassemblies est en réalité de mauvaise qualité — c'est
      l'illustration directe du principe "N50 élevé ≠ meilleur assemblage".
```

---

# 3. BUSCO — complétude fonctionnelle

```text
COMMAND: busco
PURPOSE: estimer la complétude d'un assemblage (ou d'un jeu de gènes) en
         recherchant des orthologues universels à copie unique attendus
         chez le clade de l'organisme étudié (base de données OrthoDB).
SYNTAX: busco -i assembly.fasta -l lineage_dataset -o resultats_busco -m genome
OUTPUT: pourcentage de BUSCOs complets (simple ou dupliqués), fragmentés,
         manquants.
INTERPRETATION: un fort taux de BUSCOs manquants peut signaler un
         assemblage incomplet, MAIS aussi un choix de lineage_dataset mal
         adapté à l'organisme réel — toujours vérifier la pertinence du
         jeu de données de référence choisi avant de conclure à un
         problème d'assemblage.
DOCUMENTATION: https://busco.ezlab.org (site officiel) · manuel :
         https://busco.ezlab.org/busco_userguide.html · dépôt :
         https://gitlab.com/ezlab/busco
```

```text
RÈGLE DE SYNTHÈSE: ne jamais juger un assemblage sur une seule métrique.
         Croiser systématiquement N50/L50 (contiguïté), misassemblies
         (exactitude structurelle) et complétude BUSCO (exhaustivité
         biologique) avant de conclure.
```

---

TROUBLESHOOTING
------------------------------------------------------------
```text
SYMPTOM: QUAST rapporte un excellent N50 mais BUSCO rapporte un taux de
         complétude faible
CAUSE: assemblage contigu mais probablement incomplet (régions non
       assemblées, faible couverture locale, ou contamination diluant la
       couverture réelle du génome cible).
DIAGNOSIS: vérifier la couverture par région, et si l'échantillon aurait
           pu contenir de l'ADN d'organismes contaminants.
SOLUTION: ré-examiner le QC initial (module 09) et envisager une
          profondeur de séquençage supplémentaire.
PREVENTION: toujours interpréter QUAST et BUSCO ensemble, jamais isolément.
```
```text
SYMPTOM: racon échoue avec une erreur de correspondance entre fichiers
CAUSE: les reads, l'assemblage et le fichier PAF fournis à racon ne
       proviennent pas de la même exécution de minimap2 (module 12).
DIAGNOSIS: vérifier que le PAF a bien été généré avec CE fichier
           d'assemblage précis et CES reads précis.
SOLUTION: régénérer l'alignement PAF si l'assemblage ou les reads ont
          changé entre-temps.
PREVENTION: journaliser (04_bash_scripting/) l'ordre exact des commandes
            et des fichiers utilisés à chaque étape du pipeline.
```

GO FURTHER
------------------------------------------------------------
```text
Topic: évaluation d'assemblage
Official documentation:
  https://quast.sourceforge.net/docs/manual.html
  https://busco.ezlab.org/busco_userguide.html
Topics to explore: MetaQUAST (métagénomique), QUAST-LG (grands génomes),
                    plusieurs itérations de polishing successives
                    (Racon puis Medaka, phases ultérieures)
```

DOCUMENTATION
------------------------------------------------------------
- Racon (dépôt officiel actuel) — https://github.com/lbcb-sci/racon
- QUAST — https://github.com/ablab/quast · manuel : https://quast.sourceforge.net/docs/manual.html
- BUSCO — https://busco.ezlab.org · manuel : https://busco.ezlab.org/busco_userguide.html

SCIENTIFIC REFERENCES
------------------------------------------------------------
- Vaser R, Sović I, Nagarajan N, Šikić M (2017). "Fast and accurate de
  novo genome assembly from long uncorrected reads." Genome Research,
  27(5):737-746. DOI: 10.1101/gr.214270.116
- Gurevich A, Saveliev V, Vyahhi N, Tesler G (2013). "QUAST: quality
  assessment tool for genome assemblies." Bioinformatics, 29(8):1072-1075.
  DOI: 10.1093/bioinformatics/btt086
- Manni M, Berkeley MR, Seppey M, Simão FA, Zdobnov EM (2021). "BUSCO
  Update: Novel and Streamlined Workflows along with Broader and Deeper
  Phylogenetic Coverage for Scoring of Eukaryotic, Prokaryotic, and Viral
  Genomes." Molecular Biology and Evolution, 38(10):4647-4654.
  DOI: 10.1093/molbev/msab199

NEXT MODULE
------------------------------------------------------------
`14_genome_annotation/` — annoter l'assemblage une fois sa qualité
validée. Ce module 13 clôt la reprise complète du pipeline documenté dans
`legacy/installation_and_execution.txt` (LongQC → Porechop/NanoFilt →
Canu → Minimap2 → Racon → QUAST), désormais entièrement repris, vérifié
et modernisé à travers les modules 06 et 09 à 13.
