# Chapitre 07 — awk et sed : calculer et transformer des données biologiques

> **Durée estimée** : 3 h
> **Prérequis** : [chapitre 06](../06_chercher_filtrer/README.md)
> **Suite** : [Projet 1 — Inventaire d'un run de séquençage](../projet1_inventaire_run/README.md)

## Ce que vous saurez faire à la fin de ce chapitre

- Sélectionner des lignes selon une **condition sur une colonne**
  (« les gènes de plus de 800 pb », « les variants de QUAL ≥ 30 »).
- **Calculer** : longueurs, sommes, moyennes, pourcentages, avec des
  décimales.
- Compter par catégorie avec un **tableau associatif**.
- Écrire les petits programmes classiques de la bioinformatique : longueur
  et taux de GC de chaque séquence d'un FASTA, statistiques d'un FASTQ,
  conversion GFF vers BED.
- **Rechercher et remplacer** du texte avec `sed` : renommer des en-têtes,
  supprimer des lignes, corriger un fichier.

---

## 1. Pourquoi

Avec `grep`, `cut` et `sort`, vous savez filtrer, extraire et compter. Il
vous manque encore deux choses :

- **comparer des valeurs** : `grep` ne sait pas répondre à « QUAL ≥ 30 »
  ni à « longueur > 800 », car pour lui `100` et `99` ne sont que du texte ;
- **calculer** : un pourcentage de reads, une longueur moyenne, un taux de
  GC. Le shell ne calcule qu'avec des entiers (chapitre 05).

`awk` fait les deux. C'est un petit langage de programmation conçu pour les
fichiers en colonnes, c'est-à-dire exactement le format de la plupart des
fichiers biologiques. `sed`, lui, est l'outil de **recherche-remplacement**
en série.

---

## 2. Une image pour comprendre : le technicien et sa fiche de consignes

Imaginez un technicien qui reçoit une pile de fiches (les **lignes**) et une
consigne écrite : « *pour chaque fiche où la case 6 vaut `-`, recopie les
cases 4 et 1* ». Il traite les fiches une par une, dans l'ordre, sans en
sauter.

C'est exactement le fonctionnement d'`awk` :

```text
awk 'CONDITION { ACTION }' fichier
```

Pour **chaque ligne** du fichier, si la **condition** est vraie, `awk`
exécute l'**action**. Il découpe automatiquement chaque ligne en
**champs** (les colonnes), numérotés `$1`, `$2`, `$3`…, et `$0` désigne la
ligne entière.

- Sans condition, l'action s'applique à toutes les lignes.
- Sans action, `awk` affiche les lignes qui remplissent la condition.

> **Toujours des apostrophes `' '` autour du programme awk.** À
> l'intérieur, `$1` doit être lu par awk, et non remplacé par le shell
> (chapitre 10).

---

## 3. Les colonnes : `$1`, `$2`… et le séparateur

### 3.1 Afficher, réordonner, calculer

```bash
cd ~/formation_linux
awk '{ print $4, $1 }' formats/genes.bed | head -n 3
```

```text
gyrA chrA
recA chrA
rpoB chrA
```

Les colonnes d'un BED sont : chromosome, début, fin, nom, score, brin. La
longueur d'un gène est donc `$3 - $2`. Contrairement à `cut`, awk calcule :

```bash
awk '{ print $4, $3 - $2 }' formats/genes.bed
```

```text
gyrA 900
recA 750
rpoB 1200
katG 600
ompC 960
blaTEM 861
tetA 600
```

### 3.2 Le séparateur de champs

Par défaut, awk découpe la ligne aux **espaces et tabulations**, quel que
soit leur nombre. Pour un fichier tabulé dont les colonnes peuvent
contenir des espaces, on impose la tabulation avec `-F '\t'` :

```bash
awk -F '\t' 'NR > 1 { print $1, $3 }' run_sequencage/echantillons.tsv | head -n 3
```

```text
P01 temoin
P02 temoin
P03 temoin
```

Dans la sortie, awk sépare les champs par un **espace**. Pour produire du
TSV, on fixe le séparateur de sortie `OFS` (*output field separator*) au
début du programme, dans un bloc `BEGIN` (section 5) :

```bash
awk 'BEGIN { OFS = "\t" } { print $4, $1, $2, $3 }' formats/genes.bed | head -n 2
```

```text
gyrA	chrA	150	1050
recA	chrA	1170	1920
```

### 3.3 Les variables intégrées

| Variable | Signification |
|---|---|
| `$0` | la ligne entière |
| `$1`, `$2`… | les champs |
| `NF` | le **nombre de champs** de la ligne ; `$NF` est donc le dernier champ |
| `NR` | le **numéro de la ligne** en cours (1, 2, 3…) |
| `FNR` | le numéro de ligne **dans le fichier en cours** (repart à 1 à chaque fichier) |
| `FILENAME` | le nom du fichier en cours |
| `FS` / `OFS` | les séparateurs d'entrée / de sortie |

---

## 4. Les conditions : filtrer avec intelligence

| Opérateur | Signification | Exemple |
|---|---|---|
| `==` `!=` | égal, différent | `$6 == "-"` |
| `<` `<=` `>` `>=` | comparaisons **numériques** | `$6 >= 30` |
| `~` `!~` | correspond (ou non) à une regex | `$1 ~ /^chr/` |
| `&&` `\|\|` `!` | et, ou, non | `NR > 1 && $3 == "traite"` |
| `/regex/` | la ligne correspond à la regex | `/^>/` |

**Les gènes du brin `-`** :

```bash
awk '$6 == "-"' formats/genes.bed
```

```text
chrA	1170	1920	recA	0	-
chrA	3500	4100	katG	0	-
chrP	1161	1761	tetA	0	-
```

**Les gènes de plus de 800 pb**, ce que `grep` ne sait pas faire :

```bash
awk '$3 - $2 > 800 { print $4 }' formats/genes.bed
```

```text
gyrA
rpoB
ompC
blaTEM
```

**Les échantillons traités**, en sautant l'en-tête :

```bash
awk -F '\t' 'NR > 1 && $3 == "traite" { print $1 }' run_sequencage/echantillons.tsv
```

```text
P07
P08
P09
P10
P11
P12
```

**Les variants de bonne qualité** (QUAL, colonne 6, ≥ 30), hors en-tête :

```bash
awk -F '\t' '!/^#/ && $6 >= 30' formats/variants.vcf | wc -l
```

```text
9
```

**Les indels**, dont l'allèle de référence et l'allèle alternatif n'ont pas
la même longueur (`length()` donne la longueur d'un texte) :

```bash
awk -F '\t' '!/^#/ && length($4) != length($5)' formats/variants.vcf | cut -f 1,2,4,5
```

```text
chrA	1703	TTA	T
chrA	2967	A	AG
```

Une délétion de 2 pb et une insertion de 1 pb.

> **Piège : la ligne d'en-tête comparée comme du texte.** Sans `NR > 1`,
> `awk -F '\t' '$2 > 50' pieges/mesures_windows.tsv` affiche aussi la ligne
> d'en-tête. `concentration_ng_ul` n'est pas un nombre, donc awk la
> compare **comme du texte** à `"50"`, et la trouve « plus grande ».
> Excluez toujours l'en-tête avant de comparer des nombres.

---

## 5. Calculer : variables, `BEGIN` et `END`

Un programme awk peut avoir trois parties :

```text
awk 'BEGIN { avant la 1re ligne }  { pour chaque ligne }  END { après la dernière ligne }'
```

Les **variables** se créent simplement en les utilisant. Elles valent 0 (ou
un texte vide) au départ. `total += x` est un raccourci pour
`total = total + x`.

**La longueur totale et la longueur moyenne des gènes** :

```bash
awk '{ total += $3 - $2 } END { print "Longueur totale :", total, "pb ; moyenne :", total / NR, "pb" }' formats/genes.bed
```

```text
Longueur totale : 5871 pb ; moyenne : 838.714 pb
```

Dans le bloc `END`, `NR` vaut le numéro de la dernière ligne, donc le nombre
total de lignes. Et contrairement au shell, **awk calcule avec des
décimales** : `awk 'BEGIN { print 10 / 3 }'` affiche `3.33333`.

### Mettre en forme avec `printf`

`printf` contrôle précisément l'affichage, grâce à des « formats » qui
indiquent comment écrire chaque valeur :

| Format | Affiche | Exemple |
|---|---|---|
| `%s` | du texte | `gyrA` |
| `%d` | un entier | `900` |
| `%.1f` | un nombre avec 1 décimale | `0.9` |
| `\t`, `\n` | une tabulation, un retour à la ligne | |

```bash
awk '{ printf "%s\t%.1f kb\n", $4, ($3 - $2) / 1000 }' formats/genes.bed
```

```text
gyrA	0.9 kb
recA	0.8 kb
rpoB	1.2 kb
katG	0.6 kb
ompC	1.0 kb
blaTEM	0.9 kb
tetA	0.6 kb
```

Contrairement à `print`, `printf` n'ajoute pas de retour à la ligne : il
faut écrire `\n` soi-même.

---

## 6. Compter par catégorie : les tableaux associatifs

Un **tableau associatif** est une collection de cases repérées par un
**nom** plutôt que par un numéro : `n["CDS"]`, `n["exon"]`… C'est l'outil
idéal pour compter par catégorie en **une seule lecture** du fichier :

```bash
awk -F '\t' 'NR > 1 { n[$5]++ } END { for (t in n) print t, n[t] }' annotations.tsv | sort
```

```text
CDS 13
UTR3 9
UTR5 21
exon 14
intron 13
promoter 25
repeat 25
```

Lecture :

- `n[$5]++` ajoute 1 à la case dont le nom est la valeur de la colonne 5 ;
- dans `END`, `for (t in n)` parcourt toutes les cases ;
- on obtient le même résultat qu'avec `cut | sort | uniq -c`.

> **L'ordre de `for (t in n)` est imprévisible** : ajoutez `| sort` pour un
> résultat stable.

L'avantage sur `uniq -c` : on peut **additionner** autre chose que des
occurrences. Par exemple, la longueur totale annotée par type de feature :
`awk -F '\t' 'NR > 1 { L[$5] += $3 - $2 } END { for (t in L) print t, L[t] }' annotations.tsv`.

---

## 7. Les classiques de la bioinformatique en awk

### 7.1 La longueur de chaque séquence d'un FASTA

```bash
awk '/^>/ { if (id) print id, len; id = substr($1, 2); len = 0; next }
     { len += length($0) }
     END { print id, len }' formats/reference.fasta
```

```text
chrA 6000
chrP 2400
```

Ce programme est un modèle à comprendre, car il sert partout :

| Partie | Rôle |
|---|---|
| `/^>/ { … }` | sur un en-tête : |
| `if (id) print id, len` | … afficher la séquence **précédente** (s'il y en a une) |
| `id = substr($1, 2)` | … retenir le nouvel identifiant, sans le `>` (`substr` extrait un morceau de texte à partir du 2ᵉ caractère) |
| `len = 0; next` | … remettre le compteur à zéro et passer à la ligne suivante |
| `{ len += length($0) }` | sur une ligne de séquence : ajouter sa longueur |
| `END { print id, len }` | à la fin : afficher la **dernière** séquence, qu'aucun en-tête n'a suivie |

Un programme awk peut s'écrire sur plusieurs lignes, entre les mêmes
apostrophes : c'est plus lisible.

### 7.2 Le taux de GC de chaque séquence

`gsub(/regex/, "remplacement")` remplace toutes les occurrences d'un motif
dans la ligne et **renvoie leur nombre** : avec un remplacement vide, c'est
un compteur de bases.

```bash
echo GGCCATAT | awk '{ print gsub(/[GC]/, "") }'
```

```text
4
```

```bash
awk '/^>/ { if (id) printf "%s\t%d\t%.1f\n", id, len, 100 * gc / len
            id = substr($1, 2); len = 0; gc = 0; next }
     { len += length($0); gc += gsub(/[GCgc]/, "") }
     END { printf "%s\t%d\t%.1f\n", id, len, 100 * gc / len }' formats/reference.fasta
```

```text
chrA	6000	49.6
chrP	2400	48.2
```

> **Attention à l'ordre** : `gsub` **modifie la ligne**. Ici, on mesure
> d'abord `length($0)`, puis on compte les G et C. Dans l'ordre inverse, la
> longueur serait mesurée après suppression des G et C, et le pourcentage
> serait faux.

### 7.3 Les statistiques d'un FASTQ

Dans un FASTQ, la séquence est la 2ᵉ ligne de chaque bloc de 4 : ce sont
les lignes dont le numéro donne un reste de 2 quand on le divise par 4
(`NR % 4 == 2`). Cette condition remplace le `paste - - - -` du chapitre 06 :

```bash
awk 'NR % 4 == 2 { n++; s += length($0) }
     END { printf "%d reads, longueur moyenne %.1f pb\n", n, s / n }' reads.fastq
```

```text
500 reads, longueur moyenne 99.2 pb
```

Avec un pipe, cela fonctionne aussi sur un fichier compressé, et awk
calcule enfin le pourcentage :

```bash
zcat run_sequencage/fastq/P09_S9_L001_R1_001.fastq.gz | awk 'NR % 4 == 2 { n++; if ($0 ~ /N/) avecN++ }
     END { printf "%d/%d reads avec N (%.1f %%)\n", avecN, n, 100 * avecN / n }'
```

```text
142/150 reads avec N (94.7 %)
```

Dans `printf`, `%%` affiche un vrai signe `%`.

**Retrouver les reads courts et leur identifiant** : la ligne 1 de chaque
bloc est mémorisée, puis affichée si la ligne 2 est courte.

```bash
awk 'NR % 4 == 1 { id = $1 } NR % 4 == 2 && length($0) < 90 { print id, length($0) }' reads.fastq | head -n 3
```

```text
@DEMO_read_00001 85
@DEMO_read_00011 87
@DEMO_read_00017 82
```

### 7.4 Convertir du GFF3 en BED

GFF3 numérote les bases à partir de **1** (intervalles fermés), BED à partir
de **0** (intervalles semi-ouverts). Pour convertir, on retranche 1 au début
et on garde la fin. C'est l'erreur de coordonnées la plus répandue en
bioinformatique.

```bash
awk -F '\t' 'BEGIN { OFS = "\t" } $3 == "gene" { print $1, $4 - 1, $5 }' formats/annotation.gff3 | head -n 3
```

```text
chrA	150	1050
chrA	1170	1920
chrA	2120	3320
```

Le gène gyrA, annoté de **151 à 1050** dans le GFF3, devient
**150 1050** en BED. Les deux décrivent les mêmes 900 bases. Vérification
complète dans l'exercice 4.

### 7.5 Combiner deux fichiers : `NR == FNR`

Quand awk lit deux fichiers à la suite, `NR == FNR` n'est vrai **que
pendant la lecture du premier**, car `NR` compte toutes les lignes et
`FNR` repart à 1 au second fichier. On s'en sert pour **mémoriser** une
table, puis **annoter** le second fichier :

```bash
printf "P01\t300\nP09\t150\n" > comptes.tsv
awk -F '\t' 'NR == FNR { cond[$1] = $3; next } { print $0 "\t" cond[$1] }' run_sequencage/echantillons.tsv comptes.tsv
```

```text
P01	300	temoin
P09	150	traite
```

Premier fichier (la feuille d'échantillons) : on range la condition
(colonne 3) dans une case nommée d'après l'identifiant (colonne 1), puis
`next` passe à la ligne suivante. Second fichier : on ajoute la condition
qui correspond à chaque identifiant. Vous utiliserez ce procédé dans le
projet 1.

---

## 8. `sed` : rechercher et remplacer

### 8.1 La substitution

```text
sed 's/MOTIF/REMPLACEMENT/' fichier
```

`sed` (*stream editor*) lit le fichier ligne par ligne, applique la
substitution et affiche le résultat. **Le fichier d'origine n'est pas
modifié.**

```bash
echo "chrA chrA chrA" | sed 's/chr/ch/'
echo "chrA chrA chrA" | sed 's/chr/ch/g'
```

```text
chA chrA chrA
chA chA chA
```

Sans `g` (*global*), seule la **première** occurrence de chaque ligne est
remplacée.

**Simplifier les en-têtes d'un FASTA**, en retirant `organism=` :

```bash
sed 's/organism=//' genome.fasta | grep "^>" | head -n 2
```

```text
>seq_exercice_01 synthetic type=demo length=51
>seq_exercice_02 synthetic type=demo length=49
```

**Ne garder que l'identifiant** : beaucoup d'outils exigent des en-têtes
courts. Avec `-E`, les parenthèses **capturent** une partie du motif, que
`\1` réinsère dans le remplacement :

```bash
sed -E 's/^>([^ ]+) .*/>\1/' genome.fasta | head -n 2
```

```text
>seq_exercice_01
ATGCGTACGTTAGCTAGCTAGCTAGGCTAACGTTACGTAGCTAGCTGATCG
```

Lecture du motif : début de ligne, `>`, puis une suite de caractères
**sans espace** (capturée), un espace, et tout le reste (`.*`). Le tout est
remplacé par `>` suivi de la partie capturée. Les lignes de séquence, qui
ne commencent pas par `>`, sont laissées telles quelles.

> **Le séparateur n'est pas obligatoirement `/`.** Pour remplacer des
> chemins qui contiennent des `/`, utilisez un autre caractère :
> `sed 's#/home/marie#~#'`.

### 8.2 Sélectionner et supprimer des lignes

| Commande | Effet |
|---|---|
| `sed -n '2p'` | affiche seulement la ligne 2 (`-n` : rien par défaut ; `p` : afficher) |
| `sed -n '5,8p'` | les lignes 5 à 8, par exemple le 2ᵉ read d'un FASTQ |
| `sed '1d'` | tout, sauf la ligne 1 (`d` : supprimer) |
| `sed '/^#/d'` | tout, sauf les lignes qui commencent par `#` |
| `sed 's/\r$//'` | retire le retour chariot de fin de ligne (fichiers Windows) |

```bash
sed '/^#/d' formats/variants.vcf | head -n 2
```

```text
chrA	95	.	T	C	87	PASS	DP=27	GT:DP	1:13	1:14
chrA	412	.	A	G	60	PASS	DP=41	GT:DP	1:17	1:24
```

### 8.3 Modifier un fichier en place : `sed -i`

> **Attention** : `sed -i` **modifie directement le fichier**, sans
> confirmation. Testez toujours la commande **sans** `-i` d'abord, et
> demandez une sauvegarde automatique en écrivant `-i.bak`.

```bash
cp formats/genes.bed test.bed
sed -i.bak 's/chrP/plasmide/' test.bed
ls test.bed*
```

```text
test.bed
test.bed.bak
```

`test.bed` est modifié, et `test.bed.bak` contient l'original. Sous
**macOS**, la syntaxe diffère : `sed -i '' 's/…/…/' fichier`, ou
`sed -i.bak …`, qui fonctionne sur les deux systèmes.

---

## 9. awk, sed, grep, cut : lequel choisir ?

| Besoin | Outil le plus simple |
|---|---|
| garder les lignes qui contiennent un motif | `grep` |
| extraire des colonnes telles quelles | `cut` |
| condition **numérique** sur une colonne | `awk` |
| calcul, moyenne, pourcentage | `awk` |
| compter ou additionner par catégorie | `awk` (tableau associatif) |
| logique par bloc (FASTA multi-lignes, FASTQ) | `awk` |
| remplacer du texte | `sed` |
| supprimer des lignes selon un motif | `sed '/motif/d'` ou `grep -v` |

Au-delà de quelques lignes d'awk, un script Python ou R devient plus
lisible : ce sera l'objet des modules 26 et 27 (Partie II).

---

## 10. Pièges fréquents

| Situation | Symptôme | Solution |
|---|---|---|
| programme awk entre guillemets doubles `" "` | `$1` remplacé par le shell, résultat vide ou faux | apostrophes `' '` |
| fichier tabulé avec espaces dans les colonnes | colonnes décalées | `-F '\t'` |
| sortie awk en espaces alors qu'on veut du TSV | colonnes collées par des espaces | `BEGIN { OFS = "\t" }` |
| comparaison numérique sur l'en-tête | la ligne d'en-tête passe le filtre | `NR > 1`, `!/^#/` |
| dernière séquence d'un FASTA absente | une séquence de moins | afficher aussi dans `END` |
| `gsub` avant `length` | longueurs fausses | mesurer d'abord, compter ensuite |
| `for (x in tab)` en désordre | ordre changeant d'une exécution à l'autre | `\| sort` |
| `sed` sans `g` | seule la 1re occurrence remplacée | `s/…/…/g` |
| `sed -i` qui détruit un fichier | aucune trace de l'original | tester sans `-i` ; `-i.bak` |
| coordonnées GFF copiées telles quelles en BED | décalage d'une base | début − 1 |

---

## 11. À vous de jouer

Commencez par `cd ~/formation_linux`.

### Exercice 1 : sélectionner des gènes

*Objectif : conditions numériques et texte.*
Dans `formats/genes.bed`, affichez (a) les gènes du chromosome `chrA`
situés sur le brin `+` ; (b) le nom et la longueur des gènes de moins de
700 pb ; (c) les gènes dont le **début** est compris entre 1 000 et 3 000.

<details>
<summary>Corrigé</summary>

```bash
awk '$1 == "chrA" && $6 == "+"' formats/genes.bed
awk '$3 - $2 < 700 { print $4, $3 - $2 }' formats/genes.bed
awk '$2 > 1000 && $2 < 3000' formats/genes.bed
```

(a) gyrA, rpoB et ompC. (b) katG 600 et tetA 600. (c) recA, rpoB et tetA
(débuts 1170, 2120 et 1161).
</details>

### Exercice 2 : la longueur des séquences

*Objectif : adapter le programme de la section 7.1.*
Affichez la longueur de chaque séquence de `genome.fasta`, triées de la plus
longue à la plus courte, et ne gardez que les 3 premières. Comparez avec les
longueurs annoncées dans les en-têtes (`length=`).

<details>
<summary>Corrigé</summary>

```bash
awk '/^>/ { if (id) print id, len; id = substr($1, 2); len = 0; next }
     { len += length($0) }
     END { print id, len }' genome.fasta | sort -k 2,2nr | head -n 3
grep "^>" genome.fasta | grep -E "^>chr[12] "
```

`chr1` (4800), `chr2` (3600) et `chr3` (2880) arrivent en tête, et les
longueurs calculées correspondent à celles des en-têtes. Ce contrôle de
cohérence vaut la peine d'être fait : un en-tête peut mentir, la séquence
jamais.
</details>

### Exercice 3 : un mini-rapport qualité de FASTQ

*Objectif : `NR % 4`, calculs et `printf`.*
Pour le R1 de P01 (compressé), affichez en une ligne : le nombre de reads,
le nombre total de bases et le pourcentage de reads qui contiennent
l'adaptateur `AGATCGGAAGAGC`, avec une décimale.

<details>
<summary>Corrigé</summary>

```bash
zcat run_sequencage/fastq/P01_S1_L001_R1_001.fastq.gz | awk 'NR % 4 == 2 { n++; b += length($0); if ($0 ~ /AGATCGGAAGAGC/) a++ }
     END { printf "%d reads, %d bases, %.1f %% avec adaptateur\n", n, b, 100 * a / n }'
```

```text
300 reads, 30000 bases, 5.0 % avec adaptateur
```
</details>

### Exercice 4 : GFF3 vers BED, et preuve

*Objectif : conversion de coordonnées et vérification.*
Recréez `formats/genes.bed` à partir de `formats/annotation.gff3` : pour
chaque ligne `gene`, écrivez le chromosome, le début − 1, la fin, le nom du
gène, `0` et le brin, séparés par des tabulations. Enregistrez le résultat
dans `genes_depuis_gff.bed` et prouvez qu'il est identique à l'original.

<details>
<summary>Indice</summary>

Dans la colonne 9 (`ID=gene01;Name=gyrA;product=…`), le nom est le 2ᵉ
élément séparé par `;`. `split(texte, morceaux, ";")` découpe un texte dans
un tableau numéroté (`morceaux[1]`, `morceaux[2]`…), et `sub("Name=", "", x)`
retire `Name=` de `x`.
</details>

<details>
<summary>Corrigé</summary>

```bash
awk -F '\t' 'BEGIN { OFS = "\t" }
     $3 == "gene" { split($9, a, ";"); sub("Name=", "", a[2]); print $1, $4 - 1, $5, a[2], 0, $7 }' formats/annotation.gff3 > genes_depuis_gff.bed
diff genes_depuis_gff.bed formats/genes.bed && echo IDENTIQUES
```

```text
IDENTIQUES
```

`diff` n'affiche rien et renvoie 0 : les fichiers sont identiques, et
`&&` affiche alors `IDENTIQUES`. Sans le `- 1`, chaque ligne différerait
d'une base.
</details>

### Exercice 5 : nettoyer des en-têtes

*Objectif : `sed` avec capture.*
Produisez `genome_court.fasta`, une copie de `genome.fasta` dont les
en-têtes ne contiennent plus que l'identifiant. Vérifiez le nombre de
séquences et le nombre de lignes.

<details>
<summary>Corrigé</summary>

```bash
sed -E 's/^>([^ ]+) .*/>\1/' genome.fasta > genome_court.fasta
grep -c "^>" genome_court.fasta
wc -l genome.fasta genome_court.fasta
grep "^>" genome_court.fasta | head -n 3
```

22 séquences et 419 lignes dans les deux fichiers : seuls les en-têtes ont
changé.
</details>

### Exercice 6 : compter et additionner par catégorie

*Objectif : tableaux associatifs.*
Dans `annotations.tsv`, calculez pour chaque type de feature (colonne 5) le
**nombre** d'annotations **et** leur **longueur moyenne**, avec une décimale,
triés par type.

<details>
<summary>Corrigé</summary>

```bash
awk -F '\t' 'NR > 1 { n[$5]++; L[$5] += $3 - $2 }
     END { for (t in n) printf "%s\t%d\t%.1f\n", t, n[t], L[t] / n[t] }' annotations.tsv | sort
```

Deux tableaux, remplis pendant la même lecture : l'un compte, l'autre
additionne les longueurs. Le bloc `END` divise l'un par l'autre.
</details>

---

## 12. Défi : le tableau de bord du génome de référence

Produisez pour `formats/reference.fasta` un tableau TSV avec, pour chaque
séquence : identifiant, longueur, taux de GC (une décimale) et **nombre de
gènes** annotés dans `formats/genes.bed`. Le résultat attendu :

```text
chrA	6000	49.6	5
chrP	2400	48.2	2
```

<details>
<summary>Indice</summary>

Deux étapes : (1) le programme GC de la section 7.2, enregistré dans un
fichier ; (2) un awk à deux fichiers (`NR == FNR`) qui compte d'abord les
gènes par chromosome dans `genes.bed`, puis ajoute ce nombre à chaque ligne
du tableau de l'étape 1.
</details>

<details>
<summary>Corrigé</summary>

```bash
awk '/^>/ { if (id) printf "%s\t%d\t%.1f\n", id, len, 100 * gc / len
            id = substr($1, 2); len = 0; gc = 0; next }
     { len += length($0); gc += gsub(/[GCgc]/, "") }
     END { printf "%s\t%d\t%.1f\n", id, len, 100 * gc / len }' formats/reference.fasta > gc.tsv
awk -F '\t' 'NR == FNR { ngenes[$1]++; next } { print $0 "\t" ngenes[$1] }' formats/genes.bed gc.tsv
```

Ce défi assemble presque tout le chapitre : traitement par blocs, calcul,
`printf`, tableau associatif et combinaison de deux fichiers.
</details>

---

## L'essentiel

```text
awk 'CONDITION { ACTION }' f       pour chaque ligne : si condition, alors action
$0 ligne  $1 $2 champs  $NF dernier  NF nb champs  NR n° ligne  FNR  FILENAME
-F '\t'   BEGIN { OFS = "\t" }    séparateurs d'entrée et de sortie
== != < > ~ && || !  /regex/       conditions
BEGIN { }  END { }  x += …         initialiser, conclure, cumuler (avec décimales)
printf "%s\t%d\t%.1f\n", …         sortie formatée
n[$5]++ ; for (k in n) …           compter par catégorie
length()  substr()  gsub()  split()  sub()   fonctions utiles
NR % 4 == 2                        les séquences d'un FASTQ
NR == FNR { …; next }              mémoriser un 1er fichier, annoter le 2e
GFF (1-based) → BED (0-based) : début − 1
sed 's/a/b/g'   sed -E 's/(x)…/\1/'   sed -n '5,8p'   sed '/^#/d'   sed -i.bak
```

### Auto-évaluation

- [ ] Je filtre des lignes avec une condition numérique sur une colonne.
- [ ] Je calcule une somme, une moyenne et un pourcentage avec awk.
- [ ] Je compte par catégorie avec un tableau associatif.
- [ ] J'écris (ou je retrouve et je comprends) le programme de longueur des séquences d'un FASTA.
- [ ] Je convertis des coordonnées GFF en BED sans erreur d'une base.
- [ ] Je remplace du texte avec `sed`, et je teste toujours avant `sed -i`.

## Documentation officielle

- GNU Awk User's Guide : <https://www.gnu.org/software/gawk/manual/gawk.html>
- GNU sed : <https://www.gnu.org/software/sed/manual/sed.html>
- Spécification GFF3 : <https://github.com/The-Sequence-Ontology/Specifications/blob/master/gff3.md>
- Format BED (UCSC) : <https://genome.ucsc.edu/FAQ/FAQformat.html#format1>

**Prochaine étape** : [Projet 1 — Inventaire d'un run de séquençage](../projet1_inventaire_run/README.md).
