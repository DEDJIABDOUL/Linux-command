============================================================
MODULE 03 — TEXT PROCESSING POUR BIOINFORMATICIENS
============================================================

OBJECTIVE
------------------------------------------------------------
Combiner les outils Unix de manipulation de texte (`grep`, `sed`, `awk`,
`cut`, `sort`, `uniq`, `tr`) en pipelines pour analyser de vrais fichiers
tabulaires et FASTA biologiques, et maîtriser les redirections (`>`, `>>`,
`<`) et le pipe (`|`) qui les relient entre eux.

PREREQUISITES
------------------------------------------------------------
`01_linux_basics/`, `02_linux_for_bioinformatics/`.

INPUT DATA
------------------------------------------------------------
`linux/genome.fasta` (22 séquences, en-têtes structurés
`>id organism=... type=... length=...`) et `linux/annotations.tsv`
(120 annotations, 6 colonnes).

---

# 1. Redirections

```text
CONCEPT: > écrit (et remplace) un fichier ; >> ajoute à la fin d'un
         fichier existant ; < utilise un fichier comme entrée d'une
         commande au lieu du clavier.
```

```bash
grep "^>" genome.fasta > chromosomes.txt     # crée/écrase chromosomes.txt
grep "^>" genome.fasta >> chromosomes.txt    # ajoute à la suite
wc -l < genome.fasta                          # lit genome.fasta comme entrée
```

```text
COMMON ERRORS: confondre > et >> écrase accidentellement un fichier de
         résultats précédent — vérifier avec `ls` avant d'écraser un
         fichier qui a demandé du temps de calcul à produire.
DOCUMENTATION: https://www.gnu.org/software/bash/manual/bash.html
         (Bash Reference Manual, chapitre « Redirections »)
```

# 2. Le pipe `|`

```text
CONCEPT: envoie la sortie d'une commande directement en entrée de la
         commande suivante, sans fichier intermédiaire.
```

```bash
grep "^>" genome.fasta | wc -l         # nombre de séquences, sans fichier temporaire
grep "^>" genome.fasta | sort          # en-têtes triés alphabétiquement
```

```text
DOCUMENTATION: https://www.gnu.org/software/bash/manual/bash.html
         (chapitre « Pipelines »)
EXERCISE: combiner trois commandes en un seul pipeline pour compter le
         nombre d'organismes distincts cités dans les en-têtes de
         genome.fasta (solution section 3.1 ci-dessous).
```

---

# 3. `cut`, `sort`, `uniq` — exploiter des en-têtes structurés

Les en-têtes de `genome.fasta` suivent le format
`>id organism=... type=... length=...`, séparés par des espaces.

## 3.1 `cut` — extraire une colonne

```text
COMMAND: cut -d' ' -f2
PURPOSE: extraire le 2e champ d'une ligne, selon un délimiteur donné.
SYNTAX: cut -d'délimiteur' -f numéro(s) fichier
OPTIONS:
  -d   caractère délimiteur (espace ici, tabulation par défaut sur TSV)
  -f   numéro(s) de champ à extraire (peut être une liste : -f1,3)
DOCUMENTATION: https://www.gnu.org/software/coreutils/manual/coreutils.html
```

```bash
grep "^>" genome.fasta | cut -d' ' -f2 | sort | uniq -c
```

```text
OUTPUT ATTENDU:
      2 organism=Arabidopsis_thaliana
      8 organism=Escherichia_coli
      4 organism=Saccharomyces_cerevisiae
      8 organism=synthetic
INTERPRETATION: `sort` place les valeurs identiques à la suite les unes
         des autres (obligatoire avant uniq, qui ne détecte que les
         répétitions CONSÉCUTIVES) ; `uniq -c` compte les occurrences de
         chaque valeur distincte.
COMMON ERRORS: appeler `uniq -c` sans `sort` avant donne un résultat
         incorrect si les lignes identiques ne sont pas déjà groupées.
EXERCISE: refaire la même analyse sur le 3e champ (type=...) pour voir la
         répartition par type de séquence.
```

## 3.2 Sur un fichier TSV réel : `annotations.tsv`

```bash
head -1 annotations.tsv                                    # en-têtes de colonnes
cut -f5 annotations.tsv | tail -n +2 | sort | uniq -c | sort -rn
```

```text
INTERPRETATION: `tail -n +2` saute la ligne d'en-tête ; `sort -rn` en fin
         de pipeline trie le résultat par effectif décroissant (-r =
         reverse, -n = tri numérique plutôt qu'alphabétique).
DOCUMENTATION: https://www.gnu.org/software/coreutils/manual/coreutils.html
         (cut, sort, uniq, tail)
```

---

# 4. `awk` — traiter des colonnes avec logique

```text
COMMAND: awk -F'\t' 'NR>1 && $3-$2 > 500 {print $1, $6, $3-$2}' annotations.tsv
PURPOSE: filtrer les annotations dont la longueur (colonne 3 - colonne 2)
         dépasse 500, en ignorant l'en-tête.
SYNTAX: awk 'condition {action}' fichier
OPTIONS: -F'\t' définit la tabulation comme séparateur de champs (au lieu
         de l'espace par défaut)
INTERPRETATION: $1, $2, $3... désignent les colonnes ; NR est le numéro
         de ligne courant ; la condition avant {action} filtre les lignes
         traitées.
DOCUMENTATION: https://www.gnu.org/software/gawk/manual/gawk.html
EXERCISE: lister les valeurs uniques de la 6e colonne :
```
```bash
awk -F'\t' 'NR>1 {print $6}' annotations.tsv | sort -u
```

---

# 5. `sed` — remplacer du texte

```text
COMMAND: sed 's/ATGCGT/[ATGCGT]/g' genome.fasta
PURPOSE: entourer chaque occurrence d'un motif de crochets, pour
         visualisation ou annotation textuelle simple.
SYNTAX: sed 's/motif/remplacement/g' fichier
OPTIONS: le g final = global (toutes les occurrences de la ligne, pas
         seulement la première)
INTERPRETATION: sed affiche le résultat sur la sortie standard ; il ne
         modifie PAS le fichier d'origine sans l'option -i.
COMMON ERRORS: `sed -i` modifie le fichier EN PLACE, sans sauvegarde par
         défaut sous GNU sed — toujours tester d'abord sans -i, ou
         rediriger vers un nouveau fichier.
DOCUMENTATION: https://www.gnu.org/software/sed/manual/sed.html
IMPORTANT: cette méthode est une manipulation TEXTUELLE. Pour annoter de
         vraies coordonnées génomiques de façon exploitable par d'autres
         outils, utiliser un format dédié comme BED (voir
         05_biological_formats/) avec bedtools.
EXERCISE: sauvegarder le résultat dans un nouveau fichier plutôt que de
         l'afficher seulement à l'écran :
```
```bash
sed 's/ATGCGT/[ATGCGT]/g' genome.fasta > results/genome_annotated.fasta
```

---

# 6. Pipeline complet : séparer un FASTA par séquence

```text
COMMAND:
awk '/^>/ { if (f) close(f); f = "results/split/" substr($1,2) ".fasta" }
     f    { print > f }' genome.fasta
PURPOSE: créer un fichier FASTA distinct par séquence.
INTERPRETATION:
  - /^>/ détecte chaque ligne d'en-tête et ouvre un nouveau fichier de
    sortie nommé d'après le premier champ de l'en-tête.
  - substr($1,2) retire le caractère > du nom de fichier ($1 seul, pas
    $0, pour éviter d'inclure toute la description avec ses espaces dans
    le nom de fichier).
  - close(f) ferme le fichier précédent avant d'en ouvrir un nouveau,
    pour éviter de garder des dizaines de fichiers ouverts simultanément.
COMMON ERRORS: utiliser substr($0,2) au lieu de substr($1,2) produirait
         des noms de fichiers contenant des espaces et la description
         complète — un piège classique.
DOCUMENTATION: https://www.gnu.org/software/gawk/manual/gawk.html
EXERCISE: exécuter la commande (après `mkdir -p results/split`) et
         vérifier `ls results/split | wc -l` → 22 fichiers attendus.
```

---

TROUBLESHOOTING
------------------------------------------------------------
```text
SYMPTOM: uniq -c donne des comptages incorrects (valeurs répétées non
         regroupées)
CAUSE: uniq ne détecte que les doublons de lignes CONSÉCUTIVES.
DIAGNOSIS: relire le pipeline — sort est-il bien appelé avant uniq ?
SOLUTION: toujours faire précéder uniq d'un sort sur les mêmes clés.
PREVENTION: retenir le motif `sort | uniq -c` comme un binôme indissociable.
```
```text
SYMPTOM: sed -i modifie un fichier de façon inattendue / irréversible
CAUSE: -i édite en place sans confirmation.
DIAGNOSIS: le fichier d'origine a été altéré.
SOLUTION: restaurer depuis une sauvegarde ou depuis Git (git checkout --
          fichier) si le fichier est versionné.
PREVENTION: toujours tester une commande sed sans -i d'abord, puis
            rediriger vers un nouveau fichier, ou utiliser -i.bak pour
            garder une copie de sauvegarde automatique.
```

GO FURTHER
------------------------------------------------------------
```text
Command: awk
Official documentation: https://www.gnu.org/software/gawk/manual/gawk.html
Topics to explore: BEGIN/END, tableaux associatifs, fonctions définies
                    par l'utilisateur, expressions régulières étendues

Command: sed
Official documentation: https://www.gnu.org/software/sed/manual/sed.html
Topics to explore: espace de maintien (hold space), adressage par plage
                    de lignes, scripts sed multi-commandes
```

DOCUMENTATION
------------------------------------------------------------
- GNU grep Manual — https://www.gnu.org/software/grep/manual/grep.html
- GNU sed Manual — https://www.gnu.org/software/sed/manual/sed.html
- GNU Awk User's Guide — https://www.gnu.org/software/gawk/manual/gawk.html
- GNU Coreutils Manual (cut, sort, uniq, tr) — https://www.gnu.org/software/coreutils/manual/coreutils.html
- GNU Bash Reference Manual (redirections, pipelines) — https://www.gnu.org/software/bash/manual/bash.html

NEXT MODULE
------------------------------------------------------------
`04_bash_scripting/` — transformer ces pipelines répétés en scripts Bash
robustes et réutilisables sur plusieurs échantillons.
