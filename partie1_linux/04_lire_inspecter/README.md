# Chapitre 04 — Lire et inspecter des fichiers : premiers pas avec FASTA et FASTQ

> **Durée estimée** : 2 h
> **Prérequis** : [chapitre 03](../03_gerer_fichiers/README.md)
> **Chapitre suivant** : [05 — Flux, redirections et pipes](../05_flux_redirections_pipes/README.md)

## Ce que vous saurez faire à la fin de ce chapitre

- Choisir le bon outil pour lire un fichier selon sa taille (`cat`, `less`,
  `head`, `tail`).
- Mesurer un fichier (`wc`, `du`) et identifier sa vraie nature (`file`).
- Lire la structure d'un fichier **FASTA** et d'un fichier **FASTQ**.
- Lire, compresser et décompresser des fichiers `.gz` (`zcat`, `zless`,
  `gzip`) et des archives `.tar.gz` (`tar`).
- Vérifier qu'un fichier téléchargé est **complet et intact** (`md5sum`,
  `gzip -t`), et repérer les caractères invisibles (`cat -A`).

---

## 1. Pourquoi

Avant d'analyser des données, un bioinformaticien **les regarde**. Combien
de séquences ? Le fichier est-il complet ? Est-ce bien du FASTQ, ou une
page d'erreur HTML téléchargée par accident ? Le fichier vient-il de
Windows ? Une minute d'inspection évite des heures d'analyse sur des
données fausses.

La difficulté est que les fichiers biologiques sont souvent **énormes**.
Un FASTQ de séquençage humain compte des centaines de millions de lignes.
On ne l'ouvre pas dans un éditeur de texte : on l'inspecte par morceaux,
avec des outils adaptés.

---

## 2. Une image pour comprendre : examiner un échantillon

On n'analyse pas tout un tube pour savoir ce qu'il contient : on regarde
l'étiquette, on mesure le volume, on prélève une goutte.

| Au laboratoire | Dans le terminal |
|---|---|
| lire l'étiquette | `file` : quel est le vrai type de ce fichier ? |
| mesurer le volume | `wc`, `ls -lh`, `du` : combien de lignes, quel poids ? |
| prélever une goutte au début ou à la fin | `head`, `tail` |
| observer au microscope, champ par champ | `less` |
| vérifier que le scellé est intact | `md5sum`, `gzip -t` |

---

## 3. Afficher un fichier

### 3.1 `cat` : tout afficher d'un coup

```bash
cd ~/formation_linux
cat formats/genes.bed
```

```text
chrA	150	1050	gyrA	0	+
chrA	1170	1920	recA	0	-
chrA	2120	3320	rpoB	0	+
chrA	3500	4100	katG	0	-
chrA	4350	5310	ompC	0	+
chrP	100	961	blaTEM	0	+
chrP	1161	1761	tetA	0	-
```

`cat` (*concatenate*) affiche le contenu complet d'un fichier. C'est
parfait pour un **petit** fichier comme celui-ci, une liste de 7 gènes. Sur
un gros fichier, `cat` fait défiler des milliers de lignes en quelques
secondes : appuyez sur **Ctrl+C** pour l'arrêter.

### 3.2 `less` : parcourir un gros fichier

```bash
less genome.fasta
```

`less` affiche le fichier page par page, sans le charger d'un coup. C'est
l'outil de lecture des gros fichiers.

| Touche | Effet |
|---|---|
| Espace / **b** | page suivante / précédente |
| ↓ / ↑ | ligne par ligne |
| **g** / **G** | début / fin du fichier |
| **/**motif puis Entrée | chercher vers le bas (**n** : occurrence suivante, **N** : précédente) |
| **q** | quitter |

Essayez : ouvrez `genome.fasta`, tapez `/ATGCGT` puis Entrée. Les
occurrences du motif sont surlignées. Appuyez sur **n** pour passer à la
suivante, puis sur **q** pour quitter.

> **Bon réflexe** : pour un fichier aux lignes très longues (comme un SAM),
> utilisez `less -S`. Les lignes ne sont plus repliées, chaque
> enregistrement reste sur une ligne, et les flèches ← → font défiler
> horizontalement.

### 3.3 `head` et `tail` : le début et la fin

Vous connaissez `head` depuis le chapitre 01. `tail` fait la même chose
pour la **fin** du fichier :

```bash
tail -n 3 formats/variants.vcf
```

```text
chrA	5600	.	G	T	150	PASS	DP=63	GT:DP	0:40	1:23
chrP	350	.	C	T	120	PASS	DP=35	GT:DP	1:13	1:22
chrP	1500	.	C	A	150	PASS	DP=33	GT:DP	1:18	0:15
```

Deux usages de `tail` très courants en bioinformatique :

| Commande | Effet | Usage |
|---|---|---|
| `tail -n +2 fichier` | tout **à partir de la ligne 2** | sauter la ligne d'en-tête d'un tableau |
| `tail -f fichier.log` | affiche la fin, puis **les nouvelles lignes en direct** (Ctrl+C pour arrêter) | suivre la progression d'un calcul dans son journal |

```bash
tail -n +2 run_sequencage/echantillons.tsv
```

Cette commande affiche les 12 lignes d'échantillons, sans la ligne
d'en-tête `sample_id patient condition…`.

---

## 4. Mesurer et identifier

### 4.1 `wc` : compter

```bash
wc -l genome.fasta transcripts.fasta proteins.fasta
```

```text
  419 genome.fasta
  217 transcripts.fasta
  103 proteins.fasta
  739 total
```

| Option | Compte | Remarque |
|---|---|---|
| `-l` | les lignes | la plus utilisée |
| `-w` | les mots (suites de caractères séparées par des espaces) | |
| `-c` | les **octets** | |
| `-m` | les **caractères** | diffère de `-c` dès qu'il y a des accents |

```bash
wc -c run_sequencage/rapports/run_info.txt
wc -m run_sequencage/rapports/run_info.txt
```

```text
310 run_sequencage/rapports/run_info.txt
304 run_sequencage/rapports/run_info.txt
```

Ce fichier contient 6 lettres accentuées (é, à…), qui occupent chacune
2 octets en UTF-8 : 310 octets, mais 304 caractères.

> **Attention : 419 lignes, ce n'est pas 22 séquences.** Dans un FASTA, une
> séquence s'étale sur plusieurs lignes. Vous apprendrez à compter les
> séquences au chapitre 06 (`grep -c "^>"`).

### 4.2 `du` : le poids réel sur le disque

```bash
du -sh run_sequencage formats
```

```text
716K	run_sequencage
244K	formats
```

`du` (*disk usage*) mesure la place réellement occupée, **contenu des
sous-dossiers compris**, contrairement à la taille d'un dossier affichée par
`ls -l` (chapitre 02). Les options : `-s` donne un total par argument,
`-h` des tailles lisibles.

### 4.3 `file` : quel est le vrai type de ce fichier ?

Sous Linux, l'extension (`.fasta`, `.txt`) n'est qu'une convention pour les
humains. `file` examine le **contenu** :

```bash
file genome.fasta sample_01.fastq.gz formats formats/alignements.sam pieges/mesures_windows.tsv
```

```text
genome.fasta:               ASCII text
sample_01.fastq.gz:         gzip compressed data, was "sample_01.fastq", last modified: Tue Aug 18 11:44:17 2026, max compression, original size modulo 2^32 292035
formats:                    directory
formats/alignements.sam:    Sequence Alignment/Map (SAM), with header version 1.6
pieges/mesures_windows.tsv: ASCII text, with CRLF line terminators
```

Observez ce que `file` révèle :

- `genome.fasta` est du texte simple (ASCII) ;
- `sample_01.fastq.gz` est compressé, et `file` indique même son nom et
  sa taille d'origine ;
- `file` reconnaît le format SAM ;
- `mesures_windows.tsv` a des **fins de ligne Windows** (*CRLF*), une
  source classique de bugs (section 8).

> **Bon réflexe** : après un téléchargement, `file` vous dit tout de suite
> si vous avez obtenu des données ou une page d'erreur (`HTML document`).

---

## 5. Lire un fichier FASTA

```bash
head -n 3 genome.fasta
```

```text
>seq_exercice_01 organism=synthetic type=demo length=51
ATGCGTACGTTAGCTAGCTAGCTAGGCTAACGTTACGTAGCTAGCTGATCG
>seq_exercice_02 organism=synthetic type=demo length=49
```

Le format **FASTA** stocke des séquences d'ADN, d'ARN ou de protéines :

```text
>identifiant description facultative      ← en-tête : commence TOUJOURS par >
ATGCGTACGTTAGCTAGCTAG...                   ← la séquence, sur une ou plusieurs lignes
>identifiant_suivant ...
```

- L'en-tête commence par `>`, suivi d'un **identifiant** sans espace.
  Ce qui suit le premier espace est une description libre (ici l'organisme,
  le type et la longueur).
- La séquence peut être **repliée** sur plusieurs lignes, souvent de 60 ou
  70 caractères. C'est le cas des longues séquences de `genome.fasta`.
- Des lettres en **minuscules** (`acgt`) marquent souvent des régions
  répétées (*soft-masking*). Le jeu de données en contient, et vous les
  retrouverez au chapitre 06.

Ouvrez `genome.fasta` avec `less`, puis descendez avec Espace. Vous voyez
des séquences courtes sur une seule ligne, puis des séquences longues
repliées sur des dizaines de lignes.

---

## 6. Lire un fichier FASTQ

### 6.1 La structure en 4 lignes

Un fichier **FASTQ** contient les reads produits par un séquenceur, avec la
**qualité** de chaque base. **Chaque read occupe exactement 4 lignes** :

```bash
head -n 4 reads.fastq
```

```text
@DEMO_read_00001 length=85
TCACGGAGACGCGTAAAACCGCGCCTTCACGTCGTCTTGGTAAGTCCTTGTAAGATCGGAAGAGCACACGTCTGAACTCCAGTCA
+DEMO_read_00001
HHBIICIEHDDBC@BCBCCBBDC@BB>A??CAAD@C?=?;??<>A??<=?6A<==:B=>=;;889A:89;:7;8;9475976845
```

| Ligne | Contenu |
|---|---|
| 1 | `@` suivi de l'identifiant du read |
| 2 | la séquence lue |
| 3 | `+`, éventuellement suivi de l'identifiant répété |
| 4 | la qualité : **un caractère par base**, donc exactement la même longueur que la ligne 2 |

Chaque caractère de qualité code la confiance du séquenceur dans la base
correspondante : plus le caractère est « loin » dans la table ASCII (`I`
plutôt que `#`), meilleure est la base. Le calcul exact (score Phred) est
expliqué au chapitre 16.

> **Attention au piège de la ligne 4** : elle peut commencer par `@`, car
> `@` est aussi un caractère de qualité valide. On ne reconnaît donc pas un
> read au `@` de début de ligne : on le reconnaît à sa **position**
> (lignes 1, 5, 9…).

### 6.2 Compter les reads

Puisqu'un read occupe 4 lignes :

```bash
wc -l reads.fastq
```

```text
2000 reads.fastq
```

2000 lignes ÷ 4 = **500 reads**. Au chapitre 05, le shell fera la
division à votre place.

Si le nombre de lignes **n'est pas un multiple de 4**, le fichier est
abîmé. C'est le cas de ce fichier du dossier des pièges :

```bash
wc -l pieges/fastq_tronque.fastq
tail -n 3 pieges/fastq_tronque.fastq
```

```text
163 pieges/fastq_tronque.fastq
@lecture_41
ATTATGACCTCGCAAACCTGATTATGAAGACCCAACGGGTTGGTCAAGATCGAGGGAAAAACCATTATTGTACGAGAGCA
+
```

163 n'est pas divisible par 4. `tail` montre que la qualité du dernier read
manque : le fichier a été coupé, typiquement par un téléchargement
interrompu. La plupart des outils d'analyse s'arrêteraient sur une erreur,
ou pire, ignoreraient le read sans le dire.

### 6.3 L'en-tête d'un read Illumina

Les reads du run simulé ont un en-tête au format Illumina :

```text
@M07112:58:000000000-KX4LT:1:1101:1037:1511 1:N:0:7
 │      │  │               │ │    │    │    │ │ │ └ numéro d'échantillon (index)
 │      │  │               │ │    │    │    │ │ └ 0 : pas un read de contrôle
 │      │  │               │ │    │    │    │ └ N : read non filtré (Y = filtré)
 │      │  │               │ │    │    │    └ 1 : R1 (2 : R2)
 │      │  │               │ │    └────┴ coordonnées x:y du cluster sur la tuile
 │      │  │               │ └ tuile
 │      │  │               └ lane
 │      │  └ identifiant de la flow cell
 │      └ numéro du run
 └ identifiant de l'instrument
```

Le R1 et le R2 d'une même paire ont **le même identifiant** et ne
diffèrent que par le `1:` ou le `2:` après l'espace. C'est ainsi que les
outils retrouvent les partenaires.

---

## 7. Fichiers compressés

### 7.1 Pourquoi tout est en `.gz`

Les FASTQ sont presque toujours livrés compressés avec **gzip**
(extension `.gz`). Le texte d'ADN se compresse très bien, souvent à 3 ou 4
fois moins que sa taille d'origine, et la plupart des outils de
bioinformatique lisent directement le `.gz`.

Mais un `.gz` n'est **plus du texte** :

```bash
wc -l sample_01.fastq.gz
```

```text
404 sample_01.fastq.gz
```

Ce nombre ne veut rien dire : `wc` a compté les octets qui ressemblent par
hasard à des fins de ligne dans les données compressées. De même,
`cat sample_01.fastq.gz` afficherait des caractères illisibles.

> Si un `cat` sur un fichier binaire a déréglé l'affichage du terminal
> (caractères bizarres, couleurs), tapez `reset` puis Entrée.

### 7.2 Lire sans décompresser : `zcat`, `zless`

| Commande | Équivalent pour les fichiers non compressés |
|---|---|
| `zcat fichier.gz` | `cat` |
| `zless fichier.gz` | `less` |

```bash
zless run_sequencage/fastq/P07_S7_L001_R1_001.fastq.gz
```

Vous voyez les reads en clair, avec les mêmes touches que `less`.
**Réservez `zcat` aux petits fichiers** : sur un FASTQ, il affiche tout. Au
chapitre 05, vous combinerez `zcat` avec `head` et `wc` pour inspecter
n'importe quelle taille de fichier.

> **Sous macOS**, `zcat` peut refuser les `.gz` : utilisez `gzip -dc`,
> équivalent sur tous les systèmes.

### 7.3 Compresser et décompresser : `gzip`, `gunzip`

```bash
cp genome.fasta g.fasta
gzip g.fasta
ls -lh g.fasta.gz genome.fasta
```

```text
-rw-r--r-- 1 marie marie 8.4K Nov 24 23:17 g.fasta.gz
-rw-r--r-- 1 marie marie  25K Nov 24 23:17 genome.fasta
```

Le fichier est passé de 25K à 8.4K. Notez que **`gzip` remplace
l'original** : `g.fasta` n'existe plus, seul `g.fasta.gz` reste.

| Commande | Effet |
|---|---|
| `gzip fichier` | compresse en `fichier.gz` et **supprime** l'original |
| `gzip -k fichier` | compresse et **garde** (*keep*) l'original |
| `gunzip fichier.gz` | décompresse et supprime le `.gz` (`gunzip -k` pour le garder) |
| `gzip -l fichier.gz` | affiche les tailles compressée et d'origine |
| `gzip -t fichier.gz` | **teste** l'intégrité sans rien décompresser sur le disque |

```bash
gzip -l g.fasta.gz
```

```text
         compressed        uncompressed  ratio uncompressed_name
               8539               25447  66.5% g.fasta
```

---

## 8. Vérifier l'intégrité des données

### 8.1 Les sommes de contrôle : `md5sum`

Une **somme de contrôle** (*checksum*) est une empreinte calculée à partir
de tout le contenu d'un fichier. Si un seul octet change, l'empreinte
change complètement. Deux fichiers ayant la même empreinte sont identiques.

```bash
md5sum genome.fasta exercice_sequences.fasta proteins.fasta
```

```text
ab8401165463953e4292e60e41e24a96  genome.fasta
ab8401165463953e4292e60e41e24a96  exercice_sequences.fasta
05f2df77685841751af691d97cc4435d  proteins.fasta
```

`genome.fasta` et `exercice_sequences.fasta` ont la même empreinte : ce
sont deux copies identiques, sous deux noms.

Les plateformes de séquençage et les bases de données publiques
fournissent les empreintes de leurs fichiers. Après un transfert, on les
recalcule, et `md5sum -c` compare automatiquement :

```bash
cd ~/formation_linux/run_sequencage/fastq
head -n 2 MD5SUMS.txt
md5sum -c MD5SUMS.txt
```

```text
fb75d7122cc992cd04a57e40c96e6487  P01_S1_L001_R1_001.fastq.gz
bb20a3f8ceca20dc0cae71959b0df17e  P01_S1_L001_R2_001.fastq.gz
P01_S1_L001_R1_001.fastq.gz: OK
P01_S1_L001_R2_001.fastq.gz: OK
...
P11_S11_L001_R1_001.fastq.gz: OK
P11_S11_L001_R2_001.fastq.gz: FAILED
P12_S12_L001_R1_001.fastq.gz: OK
P12_S12_L001_R2_001.fastq.gz: OK
md5sum: WARNING: 1 computed checksum did NOT match
```

Voici l'explication du fichier anormalement petit repéré au chapitre 02 :
`P11_S11_L001_R2_001.fastq.gz` **ne correspond pas** à ce que la plateforme
a envoyé. On le confirme avec `gzip -t` :

```bash
gzip -t P11_S11_L001_R2_001.fastq.gz
```

```text
gzip: P11_S11_L001_R2_001.fastq.gz: unexpected end of file
```

Le fichier s'arrête au milieu des données compressées : le transfert a été
interrompu. **La seule bonne réaction est de le re-télécharger**. Analyser
un fichier tronqué donnerait des résultats faux sans aucun avertissement.

> `sha256sum` fonctionne exactement comme `md5sum`, avec une empreinte plus
> longue et plus sûre. Utilisez celle que fournit la source des données.

### 8.2 Les caractères invisibles : `cat -A`

Un fichier texte peut contenir des caractères qu'on ne voit pas : des
tabulations (qui ressemblent à des espaces) et des fins de ligne Windows.
`cat -A` les rend visibles :

```bash
cd ~/formation_linux
cat -A formats/genes.bed
```

```text
chrA^I150^I1050^IgyrA^I0^I+$
chrA^I1170^I1920^IrecA^I0^I-$
...
```

`^I` est une **tabulation**, `$` marque la **fin de ligne**. C'est la
signature d'un fichier tabulé Unix propre. Comparez avec un fichier venu
de Windows :

```bash
cat -A pieges/mesures_windows.tsv
```

```text
echantillon^Iconcentration_ng_ul^M$
P01^I52.3^M$
P02^I48.9^M$
P03^I61.0^M$
```

Le `^M` avant chaque `$` est le caractère « retour chariot » (CR) que
Windows ajoute à chaque fin de ligne. Il est invisible à l'écran, mais
pour Linux, la dernière colonne vaut `52.3` **suivi** d'un caractère
caché, et non `52.3`. C'est la source de bugs incompréhensibles : des
comparaisons qui échouent, des scripts qui refusent de s'exécuter
(`/usr/bin/env: 'bash\r'`). Vous apprendrez à corriger ce problème au
chapitre 07.

---

## 9. Les archives : `tar`

`gzip` compresse **un** fichier. Pour regrouper **un dossier entier** dans un
seul fichier (pour l'envoyer, l'archiver ou le télécharger), on utilise
`tar`, souvent combiné à gzip : c'est le format `.tar.gz`, que vous
croiserez en téléchargeant des bases de données ou des logiciels.

| Commande | Effet | Moyen mnémotechnique |
|---|---|---|
| `tar -czf archive.tar.gz dossier/` | **c**réer une archive compressée | *create, zip, file* |
| `tar -tzf archive.tar.gz` | **lister** le contenu sans extraire | *table* |
| `tar -xzf archive.tar.gz` | e**x**traire dans le dossier courant | *extract* |
| `tar -xzf archive.tar.gz -C dossier/` | extraire dans un autre dossier | |

```bash
tar -czf formats.tar.gz formats
tar -tzf formats.tar.gz
```

```text
formats/
formats/annotation.gff3
formats/annotation.gtf
formats/reference.fasta
formats/variants.vcf
formats/alignements.sam
formats/genes.bed
```

> **Bon réflexe : listez (`-t`) avant d'extraire (`-x`).** Une archive mal
> construite peut répandre des centaines de fichiers dans votre dossier
> courant, ou écraser des fichiers de même nom.

---

## 10. Pièges fréquents

| Situation | Symptôme | Solution |
|---|---|---|
| `cat` sur un très gros fichier | le terminal défile sans fin | **Ctrl+C**, puis `less` ou `head` |
| `cat` ou `head` sur un `.gz` | caractères illisibles | `zcat`, `zless` |
| `wc -l` sur un `.gz` | nombre absurde | `zcat` + `wc` (chapitre 05) |
| nombre de lignes d'un FASTQ non multiple de 4 | — | fichier tronqué ou corrompu : `tail`, puis re-télécharger |
| `gzip fichier` | l'original a disparu | c'est normal ; `gzip -k` pour le garder |
| `md5sum -c` affiche `FAILED` | — | re-télécharger le fichier ; ne jamais l'analyser |
| `file` indique `CRLF line terminators` | comparaisons qui échouent, scripts cassés | corriger les fins de ligne (chapitre 07) |
| `file` indique `HTML document` pour un `.fastq.gz` | — | le téléchargement a récupéré une page d'erreur : vérifier l'URL |

---

## 11. À vous de jouer

Commencez par `cd ~/formation_linux`.

### Exercice 1 : choisir le bon outil

*Objectif : adapter l'outil à la taille du fichier.*
Pour chaque besoin, quelle commande utilisez-vous ?
(a) lire en entier la feuille d'échantillons ; (b) parcourir
`alignements.sam` sans que les lignes soient repliées ; (c) voir les
5 derniers variants du VCF ; (d) lire la feuille d'échantillons sans sa
ligne d'en-tête.

<details>
<summary>Corrigé</summary>

```bash
cat run_sequencage/echantillons.tsv
less -S formats/alignements.sam
tail -n 5 formats/variants.vcf
tail -n +2 run_sequencage/echantillons.tsv
```
</details>

### Exercice 2 : combien d'échantillons, combien de reads ?

*Objectif : mesurer avec `wc` et raisonner sur le format.*
(a) Combien d'échantillons compte la feuille `echantillons.tsv` ?
(b) Le fichier `formats/alignements.sam` commence par des lignes d'en-tête
débutant par `@`. Ouvrez-le avec `less -S` : combien y a-t-il de lignes
d'en-tête ? Avec `wc -l`, déduisez-en le nombre de lectures alignées.

<details>
<summary>Corrigé</summary>

(a) `wc -l run_sequencage/echantillons.tsv` donne `13` : une ligne
d'en-tête et **12 échantillons**.

(b) `less -S` montre 5 lignes d'en-tête (`@HD`, deux `@SQ`, `@RG`, `@PG`).
`wc -l formats/alignements.sam` donne `855`, soit 855 − 5 = **850 lectures**.
Au chapitre 06, `grep -vc "^@"` fera ce calcul directement.
</details>

### Exercice 3 : anatomie d'un FASTQ

*Objectif : lire la structure en 4 lignes.*
Affichez les deux premiers reads de `reads.fastq`. Quelle est la longueur du
premier read d'après son en-tête ? Repérez-vous dans sa séquence la
séquence d'adaptateur Illumina `AGATCGGAAGAGC` ? Qu'est-ce que cela
signifie ?

<details>
<summary>Corrigé</summary>

```bash
head -n 8 reads.fastq
```

L'en-tête du premier read indique `length=85`. Sa séquence contient
`...TTGTAAGATCGGAAGAGCACACG...` : l'adaptateur est présent. Le fragment
d'ADN était plus court que la longueur de lecture, et le séquenceur a
continué à lire dans l'adaptateur. Ces bases ne sont pas biologiques et
doivent être retirées (*trimming*, module 20 de la Partie II). Le second
read, de 100 pb, ne contient pas l'adaptateur.
</details>

### Exercice 4 : la livraison est-elle complète ?

*Objectif : vérifier l'intégrité d'un jeu de données.*
La plateforme vous a livré le dossier `run_sequencage/fastq`. Vérifiez
toute la livraison, identifiez le ou les fichiers problématiques, et
confirmez le diagnostic par une seconde méthode. Rédigez en deux phrases le
message à envoyer à la plateforme.

<details>
<summary>Corrigé</summary>

```bash
cd ~/formation_linux/run_sequencage/fastq
md5sum -c MD5SUMS.txt
gzip -t P11_S11_L001_R2_001.fastq.gz
cd ~/formation_linux
```

Seul `P11_S11_L001_R2_001.fastq.gz` échoue (`FAILED`), et `gzip -t`
confirme qu'il est tronqué (`unexpected end of file`). Message possible :
« Bonjour, après vérification des sommes MD5 du run 2026-10-14_M07112_0058,
le fichier P11_S11_L001_R2_001.fastq.gz ne correspond pas à sa somme de
contrôle et l'archive gzip est incomplète. Pourriez-vous le renvoyer ? Les
23 autres fichiers sont conformes. »
</details>

### Exercice 5 : détecter un fichier Windows

*Objectif : `file` et `cat -A`.*
Parmi les fichiers du dossier `pieges`, lesquels ont des fins de ligne
Windows ? Montrez-le de deux façons.

<details>
<summary>Corrigé</summary>

```bash
file pieges/*
cat -A pieges/script_casse.sh
```

`file` signale `with CRLF line terminators` pour `mesures_windows.tsv` et
`script_casse.sh`, et `cat -A` montre les `^M$` en fin de ligne. Le script
cassé sera réparé au chapitre 13.
</details>

### Exercice 6 : archiver un dossier de résultats

*Objectif : `tar` en création, liste et extraction.*
Créez une archive `formats_sauvegarde.tar.gz` du dossier `formats`.
Listez son contenu, puis extrayez-la dans un nouveau dossier `verification`
et vérifiez avec `md5sum` que `variants.vcf` y est identique à l'original.

<details>
<summary>Corrigé</summary>

```bash
tar -czf formats_sauvegarde.tar.gz formats
tar -tzf formats_sauvegarde.tar.gz
mkdir verification
tar -xzf formats_sauvegarde.tar.gz -C verification
md5sum formats/variants.vcf verification/formats/variants.vcf
```

Les deux empreintes sont identiques : l'archive a fidèlement conservé le
fichier.
</details>

---

## 12. Défi : l'inspection d'un fichier inconnu

Un collègue vous transmet `sample_02.fastq.gz` en vous disant : « c'est un
FASTQ de 800 reads, non compressé à l'origine ». Sans jamais créer de
fichier décompressé sur le disque, vérifiez **tout ce que vous pouvez** :
est-ce vraiment un fichier gzip ? Est-il intact ? Quelle est sa taille
d'origine ? Son contenu ressemble-t-il à du FASTQ ? Le nombre de lignes de
la version décompressée est-il cohérent avec 800 reads ?

<details>
<summary>Indice</summary>

`file`, `gzip -t`, `gzip -l` et `zless` répondent aux quatre premières
questions. Pour la dernière, `zless` affiche les numéros de ligne si on
l'ouvre avec l'option `-N`, et la touche **G** mène à la fin du fichier.
</details>

<details>
<summary>Corrigé</summary>

```bash
file sample_02.fastq.gz
gzip -t sample_02.fastq.gz
gzip -l sample_02.fastq.gz
zless -N sample_02.fastq.gz
```

`file` confirme une compression gzip. `gzip -t` ne dit rien : pas de
message, pas d'erreur, le fichier est intact. `gzip -l` donne la taille
d'origine. Dans `zless -N`, les blocs de 4 lignes `@`, séquence, `+`,
qualité confirment le FASTQ, et **G** mène à la dernière ligne, numérotée
**3200** = 800 × 4. Tout est cohérent.

Au chapitre 05, la vérification du nombre de reads tiendra en une ligne :
`zcat sample_02.fastq.gz | wc -l`.
</details>

---

## L'essentiel

```text
cat  less (-S)  head  tail (-n +2, -f)   afficher selon la taille
wc -l -w -c -m        compter lignes, mots, octets, caractères
du -sh                poids réel d'un dossier
file                  vrai type d'un fichier (gzip ? texte ? CRLF ?)
FASTA : >en-tête puis séquence sur une ou plusieurs lignes
FASTQ : 4 lignes par read (@id, séquence, +, qualité) → lignes ÷ 4 = reads
zcat  zless  gzip (-k -l -t)  gunzip      fichiers .gz
md5sum -c SOMMES.txt  gzip -t             vérifier l'intégrité
cat -A                voir tabulations (^I), fins de ligne ($), CRLF (^M)
tar -czf / -tzf / -xzf (-C dossier)       créer, lister, extraire une archive
```

### Auto-évaluation

- [ ] Je choisis entre `cat`, `less`, `head` et `tail` selon la taille du fichier.
- [ ] J'explique la structure d'un FASTA et d'un FASTQ, et je compte les reads d'un FASTQ.
- [ ] Je sais pourquoi `wc -l` sur un `.gz` ne veut rien dire.
- [ ] Je vérifie l'intégrité d'une livraison avec `md5sum -c`.
- [ ] Je repère un fichier aux fins de ligne Windows.
- [ ] Je liste une archive `.tar.gz` avant de l'extraire.

## Documentation officielle

- `cat`, `head`, `tail`, `wc`, `du`, `md5sum` (GNU Coreutils) : <https://www.gnu.org/software/coreutils/manual/coreutils.html>
- `less` : <https://www.greenwoodsoftware.com/less/>
- `file` : <https://www.darwinsys.com/file/>
- `gzip` : <https://www.gnu.org/software/gzip/manual/gzip.html>
- `tar` : <https://www.gnu.org/software/tar/manual/tar.html>
- Format FASTQ : Cock P. J. A. *et al.* (2010), *Nucleic Acids Research* 38(6):1767-1771, DOI [10.1093/nar/gkp1137](https://doi.org/10.1093/nar/gkp1137)

**Prochaine étape** : [chapitre 05 — Flux, redirections et pipes](../05_flux_redirections_pipes/README.md).
