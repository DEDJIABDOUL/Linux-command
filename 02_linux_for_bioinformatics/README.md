============================================================
MODULE 02 — LINUX APPLIQUÉ À LA BIOINFORMATIQUE : PREMIERS PAS SUR FASTA/FASTQ
============================================================

OBJECTIVE
------------------------------------------------------------
Utiliser les commandes apprises dans `01_linux_basics/` pour explorer de
vrais formats de données biologiques : FASTA (séquences) et FASTQ (reads de
séquençage avec qualité). Ce module reste volontairement simple ; l'étude
approfondie de ces formats (encodage Phred, formats binaires SAM/BAM...)
est traitée dans `05_biological_formats/`.

PREREQUISITES
------------------------------------------------------------
`01_linux_basics/` (pwd, ls, cd, cat, less, head, wc, grep de base).

INPUT DATA
------------------------------------------------------------
Ce module utilise le jeu de données situé dans `linux/` (décrit en détail
dans le `README.md` à la racine du dépôt) :

| Fichier | Contenu |
|---|---|
| `linux/genome.fasta` | 22 séquences génomiques synthétiques |
| `linux/transcripts.fasta` | 40 transcrits (ARNm) |
| `linux/proteins.fasta` | 25 séquences protéiques |
| `linux/reads.fastq` | 500 reads de 100 pb, avec adaptateurs Illumina intégrés |
| `linux/sample_01/02/03.fastq.gz` | reads compressés (1200/800/1500 reads) |

Se placer dans `Linux-command/linux/` avant d'exécuter les commandes
ci-dessous.

---

# 1. Le format FASTA

BIOLOGICAL CONCEPT
------------------------------------------------------------
FASTA est le format texte le plus simple pour représenter une ou plusieurs
séquences (ADN, ARN ou protéine). Chaque enregistrement comprend :

```text
>identifiant description_optionnelle
SEQUENCEREPARTIESURUNEOUPLUSIEURSLIGNES
```

La ligne d'en-tête commence toujours par `>`. La séquence peut être
repliée sur plusieurs lignes, souvent 60 ou 70 caractères par ligne :
c'est le cas dans `genome.fasta`.

WHY?
------------------------------------------------------------
Comprendre cette structure est indispensable avant d'écrire la moindre
commande : un motif biologique à cheval sur deux lignes repliées, par
exemple, est **invisible** pour un simple `grep` (voir section 3).

## 1.1 Compter les séquences

```text
COMMAND: grep -c "^>" genome.fasta
PURPOSE: compter le nombre d'enregistrements FASTA en comptant les lignes
         d'en-tête (qui commencent par >).
SYNTAX: grep -c "motif" fichier
INPUT: linux/genome.fasta
OPTIONS:
  -c   affiche uniquement le nombre de lignes correspondantes, pas leur contenu
  "^>" motif d'expression régulière : ^ ancre en début de ligne, > est le
       caractère littéral attendu
OUTPUT: 22
INTERPRETATION: 22 lignes commencent par >, donc le fichier contient
         22 séquences.
COMMON ERRORS: oublier le `^` compterait aussi un `>` apparaissant ailleurs
         qu'en début de ligne (rare en FASTA, mais une mauvaise habitude).
DOCUMENTATION: https://www.gnu.org/software/grep/manual/grep.html
EXERCISE: exécuter la même commande sur transcripts.fasta (réponse
         attendue : 40) et proteins.fasta (réponse attendue : 25).
```

## 1.2 Afficher uniquement les en-têtes, ou uniquement les séquences

```bash
grep "^>" genome.fasta       # en-têtes seuls
grep -v "^>" genome.fasta    # tout sauf les en-têtes (les lignes de séquence)
```

`-v` inverse la correspondance : `grep -v` affiche les lignes qui NE
contiennent PAS le motif.

## 1.3 Compter les bases (pas seulement les lignes)

```text
COMMAND: grep -v "^>" genome.fasta | tr -d '\n' | wc -c
PURPOSE: calculer le nombre total de bases dans le fichier, indépendamment
         du repliement des lignes.
INPUT: linux/genome.fasta
PIPELINE:
  grep -v "^>"   → conserve uniquement les lignes de séquence
  tr -d '\n'     → supprime tous les retours à la ligne, concatène tout
  wc -c          → compte les caractères restants
OUTPUT: 23718
INTERPRETATION: `wc -l` seul ne donnerait que le nombre de LIGNES, pas de
         bases — une séquence repliée sur 5 lignes n'est pas 5 bases.
DOCUMENTATION: https://www.gnu.org/software/coreutils/manual/coreutils.html
         (tr, wc) — les deux appartiennent à GNU Coreutils
EXERCISE: recalculer ce total pour transcripts.fasta et comparer avec
         `seqkit stats` (section 4) une fois SeqKit installé (module 06).
```

---

# 2. Le format FASTQ

BIOLOGICAL CONCEPT
------------------------------------------------------------
FASTQ représente les lectures brutes issues d'un séquenceur (reads), avec
leur qualité base par base. Chaque read occupe exactement 4 lignes :

```text
@identifiant_du_read
SEQUENCE
+
SCORE_DE_QUALITE (même longueur que la séquence)
```

L'encodage précis des scores de qualité (Phred) est détaillé dans
`05_biological_formats/`. Pour l'instant, il suffit de savoir que chaque
caractère de la ligne de qualité correspond à la base située à la même
position sur la ligne de séquence.

## 2.1 Compter les reads

```text
COMMAND: echo $(( $(wc -l < reads.fastq) / 4 ))
PURPOSE: un FASTQ valide a exactement 4 lignes par read ; diviser le
         nombre total de lignes par 4 donne le nombre de reads.
INPUT: linux/reads.fastq
OUTPUT: 500
INTERPRETATION: cette méthode suppose un FASTQ bien formé à 4 lignes par
         enregistrement, sans ligne vide parasite.
COMMON ERRORS: un FASTQ corrompu ou mal généré (lignes manquantes) fausse
         silencieusement ce calcul — préférer `seqkit stats` (module 06)
         dès que l'outil est disponible, car il valide la structure.
DOCUMENTATION: https://www.gnu.org/software/bash/manual/bash.html
         ($(( )) est l'arithmétique Bash ; wc est documenté dans GNU
         Coreutils Manual)
EXERCISE: appliquer la même formule aux fichiers compressés :
```
```bash
echo $(( $(zcat sample_01.fastq.gz | wc -l) / 4 ))   # → 1200
echo $(( $(zcat sample_02.fastq.gz | wc -l) / 4 ))   # → 800
echo $(( $(zcat sample_03.fastq.gz | wc -l) / 4 ))   # → 1500
```

## 2.2 Isoler la ligne de séquence de chaque read

```text
COMMAND: awk 'NR%4==2' reads.fastq
PURPOSE: extraire uniquement les lignes de séquence (la 2e ligne de
         chaque bloc de 4), en ignorant en-têtes et qualités qui
         contiennent eux aussi des lettres A/C/G/N.
INTERPRETATION: NR est le numéro de ligne courant (Number of Records) ;
         NR%4==2 sélectionne les lignes 2, 6, 10, 14... c'est-à-dire la
         2e ligne de chaque groupe de 4.
DOCUMENTATION: https://www.gnu.org/software/gawk/manual/gawk.html
EXERCISE: compter les reads contenant l'adaptateur Illumina implanté dans
         le jeu de données :
```
```bash
awk 'NR%4==2' reads.fastq | grep -c "AGATCGGAAGAGC"   # → 56 reads contaminés
```

---

# 3. Rechercher un motif biologique — et sa limite

```text
COMMAND: grep -n "ATGCGT" genome.fasta
PURPOSE: localiser les lignes contenant un motif nucléotidique donné.
OPTIONS: -n affiche le numéro de ligne, -i ignore la casse (majuscule/minuscule)
INTERPRETATION IMPORTANTE: en FASTA, les régions en minuscules signalent
         souvent des régions "soft-masked" (répétitions). `grep -i` les
         détecte, `grep` seul les ignore — sur ce jeu de données :
```
```bash
grep -c  "ATGCGT" genome.fasta   # → 29 lignes
grep -ic "ATGCGT" genome.fasta   # → 31 lignes (2 de plus grâce à -i)
```
```text
LIMITE FONDAMENTALE: grep -c compte des LIGNES contenant le motif, pas le
         nombre d'occurrences réelles, et un motif à cheval sur deux
         lignes repliées est invisible pour grep. C'est précisément pour
         cette raison qu'un outil dédié comme SeqKit (module 06) est
         préférable dès qu'on manipule sérieusement du FASTA/FASTQ.
DOCUMENTATION: https://www.gnu.org/software/grep/manual/grep.html
EXERCISE: comparer le nombre de lignes contenant ATGCGT au nombre réel
         d'occurrences :
```
```bash
grep -v "^>" genome.fasta | grep -o "ATGCGT" | wc -l
```

---

TROUBLESHOOTING
------------------------------------------------------------
```text
SYMPTOM: le nombre de reads calculé via wc -l / 4 semble incohérent
CAUSE: le fichier FASTQ contient des lignes vides ou est tronqué
       (téléchargement interrompu, par exemple).
DIAGNOSIS: vérifier que wc -l retourne un multiple de 4 :
           echo $(( $(wc -l < fichier.fastq) % 4 ))   # doit valoir 0
SOLUTION: re-télécharger ou régénérer le fichier ; valider avec un outil
          dédié (seqkit stats, module 06) plutôt qu'un calcul manuel.
PREVENTION: toujours valider un FASTQ téléchargé avant de l'utiliser.
```
```text
SYMPTOM: grep -c "ATGCGT" retourne un nombre inférieur au nombre réel
         d'occurrences attendu
CAUSE: grep -c compte des lignes, pas des occurrences ; de plus les
       séquences FASTA repliées peuvent couper un motif entre deux lignes.
DIAGNOSIS: comparer avec grep -o ... | wc -l (compte les occurrences non
           chevauchantes sur chaque ligne prise séparément).
SOLUTION: utiliser seqkit locate pour une recherche fiable sur la
          séquence complète, indépendamment du repliement (module 06).
PREVENTION: ne jamais présenter grep comme un outil d'analyse de séquence
            complet — c'est un outil de recherche de texte générique.
```

DOCUMENTATION
------------------------------------------------------------
- GNU grep Manual — https://www.gnu.org/software/grep/manual/grep.html
- GNU Awk User's Guide — https://www.gnu.org/software/gawk/manual/gawk.html
- GNU Coreutils Manual (tr, wc) — https://www.gnu.org/software/coreutils/manual/coreutils.html
- GNU Bash Reference Manual — https://www.gnu.org/software/bash/manual/bash.html

NEXT MODULE
------------------------------------------------------------
`03_text_processing/` — combiner grep/sed/awk/cut/sort/uniq en pipelines
pour analyser des annotations et des fichiers tabulaires biologiques.
