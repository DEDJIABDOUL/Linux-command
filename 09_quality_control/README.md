# 09 — Contrôle qualité (QC) des données de séquençage

OBJECTIVE
------------------------------------------------------------
Évaluer la qualité de reads bruts avant toute analyse, en choisissant des
outils adaptés à la technologie de séquençage (Illumina / Oxford Nanopore
/ PacBio), et savoir interpréter — pas seulement lire — un rapport de QC.

PREREQUISITES
------------------------------------------------------------
`05_biological_formats/` (encodage Phred), `06_environment_management/`,
`08_data_acquisition/`.

WHY?
------------------------------------------------------------
Aucune étape en aval (assemblage, alignement, variant calling...) ne peut
compenser des données de mauvaise qualité en entrée. Le QC est la
première étape de tout pipeline réel, et sa sortie conditionne les choix
de nettoyage du module suivant (`10_adapter_trimming_filtering/`).

AVERTISSEMENT MÉTHODOLOGIQUE
------------------------------------------------------------
```text
PASS  ≠ jeu de données biologiquement parfait
WARN  ≠ jeu de données inutilisable
FAIL  ≠ analyse impossible
```
Un rapport de QC est un ensemble d'indices statistiques génériques,
calculés sans connaissance du protocole expérimental. Un « FAIL » sur le
contenu en GC, par exemple, est attendu et normal pour un organisme dont
le génome a un contenu en GC extrême (certains amplicons ciblés,
certaines bactéries) — ce n'est pas nécessairement une erreur technique.
Toute alerte doit être interprétée à la lumière du protocole, jamais lue
mécaniquement.

---

# 0. Environnement de ce module

```bash
conda env create -f envs/qc.yml
conda activate qc
```

```text
CONTENU: fastqc, multiqc, nanoplot (voir envs/qc.yml pour le détail et les
         raisons de ce regroupement). LongQC est traité séparément en
         section 2.2, car son installation nécessite une compilation
         manuelle plutôt qu'un simple paquet Conda.
```

# 1. QC pour données Illumina (short reads)

## 1.1 FastQC

```text
COMMAND: fastqc
PURPOSE: générer un rapport HTML de contrôle qualité par fichier FASTQ.
SYNTAX: fastqc fichier.fastq.gz -o dossier_sortie/
OUTPUT: un rapport HTML + une archive .zip par fichier d'entrée
DOCUMENTATION: https://www.bioinformatics.babraham.ac.uk/projects/fastqc/
         (site officiel, Babraham Bioinformatics) · code source :
         https://github.com/s-andrews/FastQC
```

### Interprétation des métriques clés

```text
METRIC: Per base sequence quality
WHAT: distribution du score Phred à chaque position du read.
WHY IT MATTERS: une chute de qualité en fin de read est un phénomène
         technique NORMAL sur Illumina (le signal s'affaiblit au fil du
         cycle de séquençage) — ce n'est pas nécessairement une anomalie.
WHAT IS CONCERNING: une qualité basse dès les premiers cycles, ou une
         chute brutale bien avant la fin attendue du read.
POSSIBLE CAUSES: problème de préparation de librairie, surcharge de la
         cellule de flux, défaut d'appel de base.
WHAT TO DO: envisager un trimming qualité (module 10) adapté ; ne
         JAMAIS choisir un seuil de qualité minimal arbitraire sans le
         justifier par le protocole et l'objectif de l'analyse (voir
         module 10, section sur les paramètres).
```

```text
METRIC: Adapter Content
WHAT: proportion de reads contenant encore une séquence d'adaptateur de
         séquençage.
WHY IT MATTERS: un adaptateur non retiré peut s'aligner faussement ou
         fausser un assemblage.
WHAT TO DO: trimming d'adaptateurs (module 10) si le taux est significatif.
```

```text
METRIC: Sequence Duplication Levels
WHAT: proportion de séquences identiques.
WHY IT MATTERS: une forte duplication est ATTENDUE et normale pour du
         RNA-seq (gènes très exprimés) ou de l'amplicon — mais suspecte
         pour du WGS à faible profondeur, où elle peut signaler un excès
         de cycles de PCR pendant la préparation de librairie.
WHAT TO DO: interpréter TOUJOURS ce signal à la lumière du type
         d'expérience, jamais isolément.
```

```text
METRIC: Overrepresented sequences / Per sequence GC content
WHAT: séquences anormalement fréquentes ; distribution du %GC globale
         comparée à une distribution théorique normale.
WHAT IS CONCERNING: une contamination (adaptateur résiduel, séquence
         d'un autre organisme) peut produire un pic GC ou une séquence
         surreprésentée inattendue.
WHAT TO DO: examiner l'identité des séquences surreprésentées avant de
         conclure — un pic GC peut aussi simplement refléter la biologie
         réelle de l'organisme étudié (voir avertissement méthodologique
         ci-dessus).
```

## 1.2 MultiQC — agréger plusieurs rapports

```text
COMMAND: multiqc
PURPOSE: parcourir un dossier de résultats (FastQC, Samtools, et bien
         d'autres outils reconnus automatiquement) et produire UN seul
         rapport HTML interactif agrégeant tous les échantillons.
SYNTAX: multiqc dossier_de_resultats/ -o dossier_sortie/
INTERPRETATION: particulièrement utile dès que le nombre d'échantillons
         dépasse quelques unités — comparer visuellement tous les
         échantillons d'un coup plutôt que d'ouvrir un rapport par un.
DOCUMENTATION: https://multiqc.info/docs/ (documentation officielle) ·
         code source : https://github.com/MultiQC/MultiQC
EXERCISE: après avoir créé l'environnement `envs/qc.yml` (voir section 0
         ci-dessous), exécuter fastqc puis multiqc sur les 3 échantillons
         compressés linux/sample_01/02/03.fastq.gz et comparer les trois
         profils de qualité dans un seul rapport.
```

---

# 2. QC pour données Oxford Nanopore et PacBio (long reads)

## 2.1 NanoPlot — recommandation actuelle pour Nanopore/PacBio

```text
COMMAND: NanoPlot
PURPOSE: statistiques et visualisations de reads longs (FASTQ, FASTA,
         BAM/CRAM, ou résumés spécifiques au séquenceur), pour Oxford
         Nanopore ET PacBio.
SYNTAX: NanoPlot --fastq reads.fastq.gz -o dossier_sortie/
STATUT VÉRIFIÉ (2026-08-22) : projet activement maintenu (auteur
         wdecoster, même auteur que NanoFilt/chopper), fait partie de la
         suite d'outils NanoPack.
DOCUMENTATION: https://github.com/wdecoster/NanoPlot (dépôt officiel,
         contient le guide d'usage) — suite complète :
         https://github.com/wdecoster/nanopack
```

## 2.2 LongQC — alternative également maintenue

```text
COMMAND: longQC.py sampleqc
PURPOSE: contrôle qualité dédié aux reads longs PacBio et ONT (couverture,
         longueur, complexité de la librairie, occupation des pores...).
SYNTAX (reprise du fichier legacy, chemins à adapter à l'arborescence du
         module 07) :
```
```bash
python longQC.py sampleqc -x ont-rapid -o resultats_qc/ reads.fastq
```
```text
STATUT VÉRIFIÉ (2026-08-22) : CONTRAIREMENT à ce que suggérait l'audit
         initial (`docs/audit_report.md`), LongQC est activement
         maintenu — dernière release LongQC-1.2.3 publiée le
         2026-03-25, vérifiée directement via le flux de releases GitHub
         officiel. Il ne doit donc PAS être présenté comme obsolète.
DOCUMENTATION: https://github.com/yfukasawa/LongQC (dépôt officiel,
         seule source de documentation disponible pour cet outil — pas de
         site dédié séparé)
COMMON ERRORS: le preset `-x` doit correspondre exactement à la
         technologie et à la chimie utilisées (ex. ont-rapid, ont-ligation,
         rs2, sequel...) — un mauvais preset fausse l'interprétation des
         métriques de longueur/qualité attendues.
```

---

TROUBLESHOOTING
------------------------------------------------------------
```text
SYMPTOM: FastQC signale FAIL sur "Per base sequence content" pour des
         données par ailleurs visiblement correctes
CAUSE: fréquente pour les premières bases d'un read Illumina, liée au
       biais d'amorçage aléatoire (random hexamer priming) — un
       phénomène technique connu, pas une erreur d'expérience.
DIAGNOSIS: comparer avec des rapports FastQC publiés pour la même
           technologie/protocole (voir la documentation officielle
           FastQC, qui documente ce cas).
SOLUTION: pas d'action systématique requise ; documenter l'observation
          plutôt que rejeter les données sans réflexion.
PREVENTION: toujours lire la documentation d'interprétation de chaque
            module FastQC avant de réagir à un WARN/FAIL isolé.
```
```text
SYMPTOM: longQC.py échoue avec un preset -x incorrect
CAUSE: preset ne correspondant pas à la technologie/chimie réelle du run.
DIAGNOSIS: vérifier les métadonnées du run (section 08_data_acquisition/,
           documentation systématique du dataset).
SOLUTION: relancer avec le preset correct (voir liste dans la
          documentation officielle du dépôt).
PREVENTION: toujours documenter la technologie exacte au moment de
            l'acquisition des données (module 08).
```

GO FURTHER
------------------------------------------------------------
```text
Topic: interprétation de rapports de QC
Official documentation:
  https://www.bioinformatics.babraham.ac.uk/projects/fastqc/
  https://multiqc.info/docs/
Topics to explore: modules FastQC désactivables/configurables, intégration
                    MultiQC dans un pipeline Snakemake/Nextflow (phases
                    ultérieures)
```

DOCUMENTATION
------------------------------------------------------------
- FastQC — https://www.bioinformatics.babraham.ac.uk/projects/fastqc/ · source : https://github.com/s-andrews/FastQC
- MultiQC — https://multiqc.info/docs/ · source : https://github.com/MultiQC/MultiQC
- NanoPlot — https://github.com/wdecoster/NanoPlot
- LongQC — https://github.com/yfukasawa/LongQC

SCIENTIFIC REFERENCES
------------------------------------------------------------
- Andrews S (2010). "FastQC: A Quality Control Tool for High Throughput
  Sequence Data" [logiciel, sans publication associée — citation du
  logiciel lui-même]. https://www.bioinformatics.babraham.ac.uk/projects/fastqc/
- Ewels P, Magnusson M, Lundin S, Käller M (2016). "MultiQC: summarize
  analysis results for multiple tools and samples in a single report."
  Bioinformatics, 32(19):3047-3048. DOI: 10.1093/bioinformatics/btw354
- De Coster W, D'Hert S, Schultz DT, Cruts M, Van Broeckhoven C (2018).
  "NanoPack: visualizing and processing long-read sequencing data."
  Bioinformatics, 34(15):2666-2669. DOI: 10.1093/bioinformatics/bty149
  (référence d'origine de NanoPlot ; mis à jour par NanoPack2, De Coster
  & Rademakers 2023, DOI: 10.1093/bioinformatics/btad311)
- Fukasawa Y, Ermini L, Wang H, Carty K, Cheung MS (2020). "LongQC: A
  Quality Control Tool for Third Generation Sequencing Long Read Data."
  G3 (Bethesda), 10(4):1193-1196. DOI: 10.1534/g3.119.400864

NEXT MODULE
------------------------------------------------------------
`10_adapter_trimming_filtering/` — nettoyer les données en fonction des
signaux de QC observés dans ce module.
