# Chapitre 06 — Chercher et filtrer : grep, expressions régulières, cut, sort, uniq

> **Durée estimée** : 2 h 30
> **Prérequis** : [chapitre 05](../05_flux_redirections_pipes/README.md)
> **Chapitre suivant** : [07 — awk et sed pour les données biologiques](../07_awk_sed/README.md)

## Ce que vous saurez faire à la fin de ce chapitre

- Retrouver les lignes qui contiennent un motif, ou qui ne le contiennent
  pas (`grep`), et compter les séquences d'un FASTA.
- Décrire un motif avec une **expression régulière** : début de ligne,
  alternatives, répétitions.
- Extraire des colonnes d'un tableau (`cut`), trier (`sort`) et compter
  les valeurs distinctes (`uniq -c`).
- Transformer des caractères (`tr`) : majuscules, brin complémentaire,
  fins de ligne Windows.
- Mettre un FASTQ « à plat » pour l'interroger sans se tromper de ligne
  (`paste - - - -`).

---

## 1. Pourquoi

Les fichiers biologiques sont des textes structurés : une ligne par variant
dans un VCF, une ligne par gène dans un BED, quatre lignes par read dans un
FASTQ. La plupart des questions qu'on leur pose sont des questions de
**tri** et de **comptage** :

- Combien de séquences dans ce FASTA ?
- Quels variants n'ont pas passé les filtres de qualité ?
- Combien de reads contiennent l'adaptateur ? Combien contiennent des `N` ?
- Combien d'annotations de chaque type, et sur quel brin ?

Avec les cinq outils de ce chapitre, chacune de ces questions tient en une
ligne, quelle que soit la taille du fichier.

---

## 2. Une image pour comprendre : la chaîne de tri

Imaginez le tri d'un grand arrivage de tubes :

| Étape | Outil | Ce qu'il fait |
|---|---|---|
| ne garder que les tubes portant une certaine mention | `grep` | filtre des **lignes** |
| ne lire qu'une case de l'étiquette | `cut` | extrait des **colonnes** |
| ranger les tubes par ordre | `sort` | trie les lignes |
| regrouper les tubes identiques et les compter | `uniq -c` | compte les lignes identiques **voisines** |
| réécrire certaines lettres de l'étiquette | `tr` | remplace des **caractères** |

Reliés par des pipes (chapitre 05), ces outils forment une chaîne de tri
complète.

---

## 3. `grep` : filtrer des lignes

### 3.1 L'essentiel

`grep MOTIF fichier` affiche les lignes qui contiennent le motif.
L'en-tête d'un FASTA commence par `>`, et `^` signifie « début de ligne »
(section 4) :

```bash
cd ~/formation_linux
grep "^>" proteins.fasta | head -n 3
```

```text
>prot_001 organism=Homo_sapiens type=protein length=217
>prot_002 organism=Homo_sapiens type=protein length=94
>prot_003 organism=Homo_sapiens type=protein length=179
```

**Compter les séquences d'un FASTA** est l'usage le plus courant de `grep`
en bioinformatique. Au chapitre 04, `wc -l` ne pouvait pas le faire :

```bash
grep -c "^>" genome.fasta transcripts.fasta proteins.fasta
```

```text
genome.fasta:22
transcripts.fasta:40
proteins.fasta:25
```

| Option | Effet | Exemple d'usage |
|---|---|---|
| `-c` | compte les lignes trouvées au lieu de les afficher | nombre de séquences |
| `-v` | **inverse** : les lignes qui ne contiennent **pas** le motif | les séquences sans leurs en-têtes |
| `-i` | ignore la casse | trouver aussi les régions en minuscules |
| `-n` | affiche le numéro de chaque ligne | localiser dans le fichier |
| `-o` | affiche seulement la partie trouvée, une par ligne | compter des **occurrences** |
| `-w` | le motif doit être un mot entier | `LowQual` sans `LowQuality` |
| `-l` | affiche seulement le nom des fichiers qui contiennent le motif | « quels fichiers parlent de… ? » |
| `-r` | cherche dans tous les fichiers d'un dossier, récursivement | fouiller une arborescence |
| `-A 1` / `-B 1` | affiche aussi 1 ligne **après** / **avant** chaque ligne trouvée | l'en-tête et le début de sa séquence |
| `-E` | expressions régulières étendues (section 4) | `"GAATTC\|GGATCC"` |

### 3.2 Démonstrations

**Les séquences seules**, sans les en-têtes :

```bash
grep -v "^>" genome.fasta | head -n 2
```

```text
ATGCGTACGTTAGCTAGCTAGCTAGGCTAACGTTACGTAGCTAGCTGATCG
TTGACCGTAGCTAGGCTAACGATCGTACGGTACCTAGCTAGGATCGTAA
```

**Un en-tête et la ligne qui le suit** :

```bash
grep -A 1 "^>seq_exercice_03" genome.fasta
```

```text
>seq_exercice_03 organism=synthetic type=demo length=48
CGATGCTAGCTAACGTTAGGCTAGCTAGGCTAACGATCGTAGCTAACG
```

**Les régions en minuscules** (*soft-masked*) :

```bash
grep -c ATGCGT genome.fasta
grep -ic ATGCGT genome.fasta
```

```text
29
31
```

Deux lignes de plus avec `-i` : elles contiennent `atgcgt` en minuscules.
Dans un génome, ces minuscules marquent souvent des régions répétées ; le
motif y est biologiquement présent, mais un `grep` sensible à la casse ne le
voit pas.

**Dans quels fichiers ?**

```bash
grep -l ATGCGT *.fasta
```

```text
exercice_sequences.fasta
genome.fasta
transcripts.fasta
```

**Dans tout un dossier** :

```bash
grep -r "P09" run_sequencage/rapports
```

```text
run_sequencage/rapports/run_info.txt:Remarque   : le patient P09 a été prélevé dans de mauvaises conditions.
```

### 3.3 Quand `grep` ne trouve rien

Le site de restriction de l'enzyme EcoRI est `GAATTC`. Est-il présent dans
le génome de référence ?

```bash
grep GAATTC formats/reference.fasta
echo "code : $?"
```

```text
code : 1
```

Rien ne s'affiche, et le code de retour vaut **1**. Pour `grep`, le code `0`
signifie « trouvé », `1` « rien trouvé », et `2` une vraie erreur (par
exemple un fichier absent). Vous utiliserez cette convention dans les
scripts : `grep -q MOTIF fichier && echo présent` (`-q` : ne rien afficher,
renvoyer seulement le code).

### 3.4 Lignes ou occurrences ?

`grep -c` compte des **lignes**, pas des occurrences. Le fichier
`pieges/motif_coupe.fasta` a été construit pour le montrer :

```bash
grep -c ATGCGT pieges/motif_coupe.fasta
grep -o ATGCGT pieges/motif_coupe.fasta | wc -l
grep -v "^>" pieges/motif_coupe.fasta | tr -d "\n" | grep -o ATGCGT | wc -l
```

```text
1
2
3
```

1. **1 ligne** contient le motif…
2. … mais elle le contient **2 fois** : `-o` sort chaque occurrence sur sa
   propre ligne, et `wc -l` les compte ;
3. et il y a en réalité **3 occurrences** : la troisième est coupée en
   deux par le repliement de la séquence (`…ATG` en fin de ligne, `CGT…`
   au début de la suivante). Supprimer les retours à la ligne avec `tr -d`
   (section 8) la fait apparaître.

> **Limite à retenir** : `grep` est un outil de texte, pas d'analyse de
> séquences. Le procédé `tr -d "\n"` ne vaut que pour un fichier contenant
> **une seule** séquence : sur un FASTA multiple, il collerait les
> séquences entre elles et pourrait créer de faux motifs à leur jonction.
> Pour chercher des motifs de façon fiable, on utilise des outils dédiés
> comme `seqkit locate` (chapitre 11), qui gèrent aussi le brin
> complémentaire.

---

## 4. Les expressions régulières

### 4.1 Le principe

Une **expression régulière** (*regex*) est un motif qui décrit une
**famille** de textes. On l'a déjà utilisée : `^>` signifie « un `>` en
début de ligne ».

| Symbole | Signification | Exemple | Correspond à |
|---|---|---|---|
| `^` | début de ligne | `^>` | les en-têtes FASTA |
| `$` | fin de ligne | `+$` | les lignes qui finissent par `+` |
| `.` | n'importe quel caractère, un seul | `G.ATCC` | `GGATCC`, `GAATCC`… |
| `[ ]` | un caractère parmi ceux listés | `[ACGT]` | une base |
| `[^ ]` | un caractère **absent** de la liste | `[^ACGT]` | tout sauf une base majuscule |
| `*` | le précédent, **0 fois ou plus** | `AT*G` | `AG`, `ATG`, `ATTG`… |
| avec `-E` : `+` | le précédent, **1 fois ou plus** | `^[ACGT]+$` | une ligne faite uniquement de bases |
| avec `-E` : `?` | le précédent, 0 ou 1 fois | `colou?r` | `color`, `colour` |
| avec `-E` : `{n}`, `{n,m}` | répété n fois, entre n et m fois | `[0-9]{4}` | quatre chiffres |
| avec `-E` : `\|` | **ou** | `GAATTC\|GGATCC` | l'un ou l'autre site |
| avec `-E` : `( )` | regroupe | `^>(chr\|plasmid)` | en-têtes commençant par `chr` ou `plasmid` |
| `\` | rend littéral le caractère suivant | `\.` | un vrai point |

> **Toujours des guillemets autour d'une regex.** Sans eux, le shell
> interprète lui-même `*`, `?`, `[ ]` ou `|` (chapitres 03 et 05) avant que
> `grep` ne les voie.

### 4.2 Démonstrations

**Les en-têtes qui commencent par `chr` ou `plasmid`** :

```bash
grep -E "^>(chr|plasmid)" genome.fasta
```

```text
>chr1 organism=Escherichia_coli type=genomic length=4800
>chr2 organism=Escherichia_coli type=genomic length=3600
>chr3 organism=Escherichia_coli type=genomic length=2880
>chr4 organism=Escherichia_coli type=genomic length=1920
>plasmid_pUC19 organism=Escherichia_coli type=plasmid length=960
```

**Les séquences d'au moins 1 000 pb**, d'après l'en-tête (`length=`
suivi d'au moins quatre chiffres) :

```bash
grep "^>" genome.fasta | grep -E "length=[0-9]{4}"
```

**Les lignes de séquence entièrement en majuscules ACGT** et celles qui
contiennent au moins une minuscule :

```bash
grep -c -E "^[ACGT]+$" genome.fasta
grep -c "[acgt]" genome.fasta
```

```text
371
41
```

**Le site BamHI (`GGATCC`) ou EcoRI (`GAATTC`)**, en comptant chaque
occurrence trouvée :

```bash
grep -o -E "GAATTC|GGATCC" formats/reference.fasta | sort | uniq -c
```

```text
      5 GGATCC
```

Cinq sites BamHI, aucun site EcoRI. La combinaison `sort | uniq -c` est
expliquée en section 7.

**Le piège du point** : dans une regex, `.` signifie « n'importe quel
caractère ».

```bash
grep "." formats/genes.bed | wc -l
grep "\." formats/genes.bed | wc -l
```

```text
7
0
```

`"."` correspond à toute ligne non vide, alors que `"\."` cherche un vrai
point, et le fichier BED n'en contient aucun.

---

## 5. `grep` sur un FASTQ : le piège des 4 lignes

Combien de reads de P09 contiennent au moins une base indéterminée `N` ?

```bash
zcat run_sequencage/fastq/P09_S9_L001_R1_001.fastq.gz | grep -c N
```

```text
292
```

292, alors que le fichier ne contient que 150 reads : **impossible**.
Regardez un en-tête :

```text
@M07112:58:000000000-KX4LT:1:1101:1037:1511 1:N:0:9
```

Il contient `:N:` (« read non filtré », chapitre 04). `grep` a compté les
150 en-têtes en plus des séquences. La qualité aussi peut contenir des
lettres. Il faut donc ne chercher **que dans les lignes de séquence**.

### La solution : mettre chaque read sur une ligne

`paste - - - -` lit 4 lignes et les colle en une seule, séparées par des
tabulations. Chaque read devient une ligne de 4 colonnes :

```bash
zcat run_sequencage/fastq/P09_S9_L001_R1_001.fastq.gz | paste - - - - | head -n 1
```

```text
@M07112:58:000000000-KX4LT:1:1101:1037:1511 1:N:0:9	ACCGTCGGAGCATTAGGATCAGGGGATCACAGTTCCGATGNGCGAGTACAAAAACGGTCAGCGCACCCAGCTGAACGTTATTATACTCACGTTTCTCGCG	+	<6:66;8:6:48449989444658758734827767421374354562254002…
```

La séquence est maintenant la colonne 2, et `cut` (section 6) l'extrait :

```bash
zcat run_sequencage/fastq/P09_S9_L001_R1_001.fastq.gz | paste - - - - | cut -f 2 | grep -c N
zcat run_sequencage/fastq/P01_S1_L001_R1_001.fastq.gz | paste - - - - | cut -f 2 | grep -c N
```

```text
142
25
```

**142 reads sur 150** contiennent au moins un `N` pour P09, contre 25 sur
300 pour P01. Le même procédé compte les reads qui contiennent
l'adaptateur : 21 sur 150 pour P09 (14 %), 15 sur 300 pour P01 (5 %). P09
cumule les problèmes : c'est l'échantillon mal prélevé signalé dans le
rapport du run.

> **Bon réflexe** : avant de faire confiance à un comptage, **vérifiez
> qu'il est plausible**. Plus de lignes trouvées que de reads, c'est le
> signe d'un motif qui touche aussi des lignes non visées.

---

## 6. `cut` : extraire des colonnes

```bash
cut -f 1,3 run_sequencage/echantillons.tsv | head -n 4
```

```text
sample_id	condition
P01	temoin
P02	temoin
P03	temoin
```

| Option | Effet |
|---|---|
| `-f 1,3` | colonnes 1 et 3 ; `-f 2-4` de la 2 à la 4 ; `-f 3-` de la 3 à la fin |
| `-d " "` | séparateur de colonnes (par défaut : la **tabulation**) |
| `-c 2-` | caractères 2 et suivants, au lieu des colonnes |

Les en-têtes FASTA sont séparés par des espaces :

```bash
grep "^>" genome.fasta | cut -d " " -f 1 | head -n 3
```

```text
>seq_exercice_01
>seq_exercice_02
>seq_exercice_03
```

Et pour retirer le `>` initial :

```bash
grep "^>" genome.fasta | cut -c 2- | head -n 2
```

```text
seq_exercice_01 organism=synthetic type=demo length=51
seq_exercice_02 organism=synthetic type=demo length=49
```

> **Attention** : `cut -d " "` considère **chaque** espace comme un
> séparateur. Deux espaces consécutifs créent une colonne vide. Pour des
> colonnes séparées par un nombre variable d'espaces, utilisez `awk`
> (chapitre 07).

---

## 7. `sort` et `uniq` : trier et compter

### 7.1 `sort`

```bash
printf "9\n100\n25\n" | sort
printf "9\n100\n25\n" | sort -n
```

```text
100
25
9
9
25
100
```

Par défaut, `sort` trie **alphabétiquement**, caractère par caractère : `1`
vient avant `2` et `9`, donc `100` passe en tête. Pour des nombres, il faut
`-n`. (`printf` affiche du texte, comme `echo`, et `\n` y désigne un retour
à la ligne.)

| Option | Effet |
|---|---|
| `-n` | tri numérique |
| `-r` | ordre inverse |
| `-u` | supprime les doublons |
| `-k 2,2` | trie sur la colonne 2 **uniquement** (`-k 2,2n` : numérique) |
| `-t ";"` | séparateur de colonnes (par défaut : les espaces et tabulations) |

Plusieurs clés se combinent : trier un BED **par chromosome, puis par
position de début** est un prérequis de nombreux outils (bedtools, par
exemple) :

```bash
sort -k 1,1 -k 2,2n annotations.tsv | head -n 4
```

```text
chr1	97	540	+	promoter	lacZ
chr1	380	542	-	UTR3	dnaA
chr1	641	1435	+	exon	tufA
chr1	663	798	+	UTR3	gyrA
```

> **Écrivez `-k 2,2` et non `-k 2`** : `-k 2` signifie « de la colonne 2
> jusqu'à la fin de la ligne », ce qui donne des tris surprenants dès qu'il
> y a des égalités.

### 7.2 `uniq` et la combinaison `sort | uniq -c`

`uniq` fusionne les lignes identiques **consécutives**. Il faut donc
**toujours trier avant**. Combien d'échantillons par condition ?

```bash
cut -f 3 run_sequencage/echantillons.tsv | tail -n +2 | sort | uniq -c
```

```text
      6 temoin
      6 traite
```

Ce pipeline est un classique à connaître par cœur. Ajouté à la fin,
`sort -rn` classe du plus fréquent au plus rare. Quels types d'annotations
contient `annotations.tsv` ?

```bash
cut -f 5 annotations.tsv | tail -n +2 | sort | uniq -c | sort -rn
```

```text
     25 repeat
     25 promoter
     21 UTR5
     14 exon
     13 intron
     13 CDS
      9 UTR3
```

Lisez-le pas à pas : prendre la colonne 5, sauter l'en-tête, trier,
compter les valeurs identiques, puis trier ces comptes du plus grand au
plus petit.

| Option de `uniq` | Effet |
|---|---|
| `-c` | préfixe chaque ligne par son nombre d'occurrences |
| `-d` | n'affiche que les lignes présentes **plusieurs fois** |
| `-u` | n'affiche que les lignes présentes **une seule fois** |

---

## 8. `tr` : remplacer ou supprimer des caractères

`tr` lit l'entrée standard (il ne prend **pas** de nom de fichier : on lui
donne un pipe ou `<`) et remplace chaque caractère de la première liste par
le caractère correspondant de la seconde.

**Mettre une séquence en majuscules** :

```bash
echo "atgcgtNNacgt" | tr "acgt" "ACGT"
```

```text
ATGCGTNNACGT
```

**Le brin complémentaire, puis le reverse complement** : `rev` inverse
l'ordre des caractères de chaque ligne.

```bash
echo "ATGCGTTAGC" | tr "ACGT" "TGCA"
echo "ATGCGTTAGC" | rev | tr "ACGT" "TGCA"
```

```text
TACGCAATCG
GCTAACGCAT
```

**Supprimer des caractères** avec `-d` : retirer les `N`, ou corriger les
fins de ligne Windows repérées au chapitre 04 (`\r` est le retour chariot
`^M`) :

```bash
tr -d "\r" < pieges/mesures_windows.tsv > mesures_unix.tsv
file mesures_unix.tsv
```

```text
mesures_unix.tsv: ASCII text
```

La mention `with CRLF line terminators` a disparu : le fichier est
maintenant au format Unix.

---

## 9. Mettre en forme : `column -t`

Un TSV dont les colonnes ont des largeurs différentes est difficile à lire.
`column -t` aligne les colonnes :

```bash
column -t run_sequencage/echantillons.tsv | head -n 3
```

```text
sample_id  patient  condition  replicat  fichier_R1                    fichier_R2
P01        P01      temoin     1         P01_S1_L001_R1_001.fastq.gz   P01_S1_L001_R2_001.fastq.gz
P02        P02      temoin     2         P02_S2_L001_R1_001.fastq.gz   P02_S2_L001_R2_001.fastq.gz
```

> `column -t` est fait pour **l'affichage** : n'enregistrez pas sa sortie
> comme fichier de données, car elle remplace les tabulations par des
> espaces.

---

## 10. En bioinformatique : un aide-mémoire de questions courantes

| Question | Commande |
|---|---|
| Combien de séquences dans un FASTA ? | `grep -c "^>" fichier.fasta` |
| Quels identifiants ? | `grep "^>" fichier.fasta \| cut -d " " -f 1 \| cut -c 2-` |
| Combien de variants dans un VCF ? | `grep -vc "^#" variants.vcf` |
| Combien de variants par chromosome ? | `grep -v "^#" variants.vcf \| cut -f 1 \| sort \| uniq -c` |
| Les variants qui ont passé les filtres ? | `grep -v "^#" variants.vcf \| grep -w PASS` |
| Combien de reads contiennent un motif ? | `zcat r.fastq.gz \| paste - - - - \| cut -f 2 \| grep -c MOTIF` |
| Combien de gènes sur le brin + ? | `cut -f 6 genes.bed \| sort \| uniq -c` |
| Trier un BED par position | `sort -k 1,1 -k 2,2n regions.bed` |
| Reverse complement d'une amorce | `echo SEQ \| rev \| tr ACGT TGCA` |

---

## 11. Pièges fréquents

| Situation | Symptôme | Solution |
|---|---|---|
| regex sans guillemets | résultats incohérents, erreurs du shell | `grep "motif"` |
| `grep -c` pour compter des occurrences | trop peu | `grep -o … \| wc -l` |
| `grep` sur un FASTQ brut | plus de résultats que de reads | `paste - - - - \| cut -f 2` |
| motif coupé par le repliement FASTA | occurrences manquantes | outils dédiés (`seqkit locate`) |
| oubli de `-i` | régions en minuscules ignorées | `grep -i` |
| `uniq -c` sans `sort` | une même valeur comptée en plusieurs morceaux | `sort \| uniq -c` |
| `sort` sur des nombres | `100` avant `9` | `sort -n`, ou `-k N,Nn` |
| `sort -k 2` | tri sur toute la fin de ligne | `-k 2,2` |
| `grep "."` pour un point | toutes les lignes trouvées | `grep "\."` |
| la ligne d'en-tête comptée avec les données | un de trop | `tail -n +2`, `grep -v "^#"` |
| `tr` avec un nom de fichier | `extra operand` | `tr … < fichier` |

---

## 12. À vous de jouer

Commencez par `cd ~/formation_linux`.

### Exercice 1 : bilan d'un VCF

*Objectif : `grep -v`, `-c`, `-w`, et le piège de l'en-tête.*
Dans `formats/variants.vcf` : (a) combien de variants (lignes de données) ?
(b) combien ont passé les filtres (`PASS`) ? (c) listez la position, la base
de référence et la base alternative des variants `LowQual`.

<details>
<summary>Corrigé</summary>

```bash
grep -vc "^#" formats/variants.vcf
grep -v "^#" formats/variants.vcf | grep -wc PASS
grep -v "^#" formats/variants.vcf | grep -w LowQual | cut -f 2,4,5
```

(a) `14` variants. (b) `9`. (c) 5 variants :

```text
655	T	A
1388	C	A
1703	TTA	T
2480	A	C
3120	A	G
```

**Le piège** : `grep LowQual formats/variants.vcf | wc -l` donne `6`, car
l'en-tête contient la ligne `##FILTER=<ID=LowQual,…>`. Éliminez toujours
l'en-tête (`grep -v "^#"`) avant de compter des données.
</details>

### Exercice 2 : la carte de restriction

*Objectif : `grep -o` et les occurrences.*
Combien de sites BamHI (`GGATCC`) le génome `formats/reference.fasta`
contient-il ? Le résultat change-t-il si l'on tient compte des motifs
coupés par le repliement des lignes ? Pourquoi la méthode
`tr -d "\n"` est-elle ici à manier avec prudence ?

<details>
<summary>Corrigé</summary>

```bash
grep -o GGATCC formats/reference.fasta | wc -l
grep -v "^>" formats/reference.fasta | tr -d "\n" | grep -o GGATCC | wc -l
```

Les deux donnent `5` : aucun site n'est coupé en fin de ligne.

Prudence : ce fichier contient **deux** séquences (`chrA` et `chrP`).
`tr -d "\n"` les colle bout à bout, ce qui pourrait créer un faux site à
leur jonction. Ici, il n'y en a pas, mais seul un outil comme `seqkit`
donnerait une réponse garantie, séquence par séquence.
</details>

### Exercice 3 : la qualité de deux échantillons

*Objectif : interroger un FASTQ sans se tromper de lignes.*
Pour les R1 de P01 et de P09, calculez le nombre de reads qui contiennent
au moins un `N`, et le nombre de reads qui contiennent l'adaptateur
`AGATCGGAAGAGC`. Rapportez ces nombres au nombre total de reads.

<details>
<summary>Corrigé</summary>

```bash
zcat run_sequencage/fastq/P01_S1_L001_R1_001.fastq.gz | paste - - - - | cut -f 2 | grep -c N
zcat run_sequencage/fastq/P01_S1_L001_R1_001.fastq.gz | paste - - - - | cut -f 2 | grep -c AGATCGGAAGAGC
zcat run_sequencage/fastq/P09_S9_L001_R1_001.fastq.gz | paste - - - - | cut -f 2 | grep -c N
zcat run_sequencage/fastq/P09_S9_L001_R1_001.fastq.gz | paste - - - - | cut -f 2 | grep -c AGATCGGAAGAGC
```

| | Reads | avec N | avec adaptateur |
|---|---|---|---|
| P01 | 300 | 25 (8 %) | 15 (5 %) |
| P09 | 150 | 142 (95 %) | 21 (14 %) |

Les pourcentages sont calculés de tête : le shell ne calcule qu'avec des
entiers. Au chapitre 07, `awk` les calculera pour vous.
</details>

### Exercice 4 : explorer une table d'annotations

*Objectif : `cut`, `sort`, `uniq -c`.*
Dans `annotations.tsv` : (a) combien d'annotations par chromosome ?
(b) combien sur chaque brin ? (c) quels sont les 3 gènes les plus annotés ?

<details>
<summary>Corrigé</summary>

```bash
cut -f 1 annotations.tsv | tail -n +2 | sort | uniq -c
cut -f 4 annotations.tsv | tail -n +2 | sort | uniq -c
cut -f 6 annotations.tsv | tail -n +2 | sort | uniq -c | sort -rn | head -n 3
```

(a) chr1 : 37, chr2 : 27, chr3 : 24, chr4 : 32. (b) 66 sur le brin `+`,
54 sur le brin `-`. (c) gyrA (21), puis tufA et lacZ (18 chacun).
</details>

### Exercice 5 : préparer une amorce

*Objectif : `tr` et `rev`.*
Pour détecter l'adaptateur sur le brin opposé, vous avez besoin du reverse
complement de `AGATCGGAAGAGC`. Calculez-le.

<details>
<summary>Corrigé</summary>

```bash
echo "AGATCGGAAGAGC" | rev | tr "ACGT" "TGCA"
```

```text
GCTCTTCCGATCT
```
</details>

### Exercice 6 : réparer un fichier Windows

*Objectif : `tr -d`.*
Créez une version Unix de `pieges/mesures_windows.tsv`, nommée
`mesures_unix.tsv`, et prouvez de deux façons que la correction a
fonctionné.

<details>
<summary>Corrigé</summary>

```bash
tr -d "\r" < pieges/mesures_windows.tsv > mesures_unix.tsv
file mesures_unix.tsv
cat -A mesures_unix.tsv
```

`file` n'indique plus `CRLF`, et `cat -A` montre des fins de ligne `$`
sans `^M`. On écrit dans un **nouveau** fichier (chapitre 05, section 4.3).
</details>

---

## 13. Défi : quels organismes ?

Produisez, en une seule ligne de commande, la liste des organismes
représentés dans `genome.fasta`, **sans le préfixe `organism=`**, du plus
représenté au moins représenté, avec le nombre de séquences de chacun.

<details>
<summary>Indice</summary>

Deux `cut` successifs : l'un avec l'espace comme séparateur, l'autre avec
le signe `=`.
</details>

<details>
<summary>Corrigé</summary>

```bash
grep "^>" genome.fasta | cut -d " " -f 2 | cut -d "=" -f 2 | sort | uniq -c | sort -rn
```

```text
      8 synthetic
      8 Escherichia_coli
      4 Saccharomyces_cerevisiae
      2 Arabidopsis_thaliana
```

Six commandes, une question biologique résolue. En cas d'égalité (8 et 8),
l'ordre entre les ex æquo peut varier selon les systèmes.
</details>

---

## L'essentiel

```text
grep "motif" f      -c compter  -v inverser  -i casse  -n numéros  -o occurrences
                    -w mot entier  -l fichiers  -r récursif  -A/-B contexte  -E étendue
Regex : ^ début  $ fin  . un caractère  [ACGT] un parmi  [^ACGT] aucun de
        * 0+   (avec -E) + 1+  ? 0-1  {n,m}  a|b  ( )   \. point littéral
grep -c "^>" f.fasta              nombre de séquences
grep -vc "^#" f.vcf               nombre de variants
zcat f.fastq.gz | paste - - - - | cut -f 2    les séquences d'un FASTQ
cut -f 1,3   -d " "   -c 2-        colonnes, séparateur, caractères
sort -n -r -u -k 2,2n -t           trier
sort | uniq -c | sort -rn          compter les valeurs distinctes
tr "acgt" "ACGT"    rev | tr ACGT TGCA    tr -d "\r"
column -t                          aligner pour lire
```

### Auto-évaluation

- [ ] Je compte les séquences d'un FASTA et les variants d'un VCF.
- [ ] Je distingue un comptage de lignes d'un comptage d'occurrences.
- [ ] J'écris une expression régulière avec `^`, `[ ]`, `+` et `|`.
- [ ] Je cherche un motif dans les séquences d'un FASTQ sans toucher aux en-têtes.
- [ ] J'utilise `sort | uniq -c | sort -rn` pour résumer une colonne.
- [ ] Je calcule le reverse complement d'une séquence et je corrige des fins de ligne Windows.

## Documentation officielle

- `grep` (GNU) : <https://www.gnu.org/software/grep/manual/grep.html>
- Expressions régulières (manuel de grep) : <https://www.gnu.org/software/grep/manual/html_node/Regular-Expressions.html>
- `cut`, `sort`, `uniq`, `tr`, `paste` (GNU Coreutils) : <https://www.gnu.org/software/coreutils/manual/coreutils.html>

**Prochaine étape** : [chapitre 07 — awk et sed pour les données biologiques](../07_awk_sed/README.md).
