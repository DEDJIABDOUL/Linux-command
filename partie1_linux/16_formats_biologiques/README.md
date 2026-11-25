# Chapitre 16 — Les formats biologiques en pratique : FASTA, FASTQ, SAM/BAM, BED, GFF, VCF

> **Durée estimée** : 3 h
> **Prérequis** : [chapitre 15](../15_git/README.md), environnement `formation_partie1` ([chapitre 11](../11_installer_logiciels/README.md))
> **Chapitre suivant** : [17 — Organiser un projet](../17_organiser_projet/README.md)

## Ce que vous saurez faire à la fin de ce chapitre

- Lire et interroger les six formats incontournables de l'analyse NGS, en
  sachant **quelle question chacun permet de poser**.
- Calculer un score de qualité Phred à partir d'un FASTQ.
- Décoder un alignement SAM : FLAG, position, MAPQ, CIGAR ; convertir,
  trier, indexer un BAM et interroger une région.
- **Ne plus jamais confondre** coordonnées 0-based (BED) et 1-based (GFF,
  VCF, SAM).
- Filtrer un VCF avec `bcftools`, et croiser régions et variants avec
  `bedtools`.

Toutes les commandes se lancent dans `~/formation_linux/formats`, avec
l'environnement actif :

```bash
conda activate formation_partie1
cd ~/formation_linux/formats
```

---

## 1. Pourquoi

Une analyse NGS est une **chaîne de formats** : chaque outil lit un format
et en produit un autre. Savoir les lire, c'est pouvoir **vérifier chaque
étape** au lieu de faire confiance aveuglément aux outils.

```text
séquenceur → FASTQ (reads + qualité)
                │  alignement sur une référence FASTA
                ▼
             SAM / BAM (où chaque read s'aligne)
                │  appel de variants
                ▼
             VCF (où le génome diffère de la référence)
                │  croisement avec l'annotation GFF / GTF / BED
                ▼
             « quels gènes sont touchés ? »
```

Les fichiers du dossier `formats/` forment justement une telle chaîne,
cohérente de bout en bout : un mini-génome bactérien (le chromosome `chrA`
et le plasmide `chrP`), ses 7 gènes, les lectures de la souche `evolue_A`
alignées dessus, et les variants de deux souches évoluées. Toutes ces
données sont synthétiques.

---

## 2. Une image pour comprendre : le dossier d'un patient

| Format | Dans le dossier médical | Question à laquelle il répond |
|---|---|---|
| **FASTA** | l'atlas d'anatomie de référence | quelle est la séquence ? |
| **FASTQ** | les clichés bruts, avec leur netteté | qu'a lu le séquenceur, et avec quelle confiance ? |
| **SAM/BAM** | chaque cliché placé sur l'atlas | où s'aligne chaque read ? |
| **BED / GFF / GTF** | les régions annotées de l'atlas | où sont les gènes ? |
| **VCF** | le compte rendu des anomalies | où ce génome diffère-t-il de la référence ? |

---

## 3. FASTA : accéder directement à une région

Vous connaissez la structure du FASTA (chapitre 04). Pour un génome de
plusieurs Go, on ne relit pas tout le fichier pour en extraire 30 bases : on
crée un **index**.

```bash
samtools faidx reference.fasta
cat reference.fasta.fai
```

```text
chrA	6000	42	60	61
chrP	2400	6184	60	61
```

Le fichier `.fai` indique, pour chaque séquence : son nom, sa longueur, la
position du début de la séquence dans le fichier (en octets), le nombre de
bases par ligne et le nombre d'octets par ligne. Grâce à lui, `samtools`
saute directement au bon endroit :

```bash
samtools faidx reference.fasta chrA:151-180
```

```text
>chrA:151-180
ATGAAATACCTAGCCCATGTAGCCGGACAT
```

Les régions s'écrivent `séquence:début-fin`, **en 1-based, bornes
incluses**, comme dans un article : `chrA:151-180` donne bien 30 bases.
C'est le début du gène gyrA : il commence par `ATG`, le codon d'initiation.

---

## 4. FASTQ : décoder la qualité

Chaque caractère de la 4ᵉ ligne d'un read code un **score de qualité
Phred** `Q`, qui exprime la probabilité `P` que la base soit fausse :

```text
Q = −10 × log10(P)        Q10 → 1 erreur sur 10   Q20 → 1/100   Q30 → 1/1 000   Q40 → 1/10 000
```

Le caractère est celui dont le **code ASCII** vaut `Q + 33` (codage
« Phred+33 », standard depuis 2011). `printf '%d' "'X"` affiche le code
ASCII d'un caractère :

```bash
printf '%d\n' "'I"
echo $(( $(printf '%d' "'I") - 33 ))
```

```text
73
40
```

`I` code donc Q40. Le premier read de `reads.fastq` commence par la qualité
`HHBII…` :

```bash
for c in H B I C 5; do printf "%s=Q%d " $c $(( $(printf "%d" "'$c") - 33 )); done; echo
```

```text
H=Q39 B=Q33 I=Q40 C=Q34 5=Q20
```

En pratique, on ne décode pas à la main : `seqkit fx2tab -q` calcule la
qualité moyenne de chaque read. La moyenne par échantillon confirme le
diagnostic du projet 1 :

```bash
seqkit fx2tab -n -q ../run_sequencage/fastq/P01_S1_L001_R1_001.fastq.gz | awk '{ s += $NF } END { printf "%.1f\n", s / NR }'
seqkit fx2tab -n -q ../run_sequencage/fastq/P09_S9_L001_R1_001.fastq.gz | awk '{ s += $NF } END { printf "%.1f\n", s / NR }'
```

```text
28.8
15.8
```

P09 a une qualité moyenne proche de Q16, soit environ une erreur toutes les
40 bases : bien en dessous du seuil de Q30 visé en séquençage Illumina.

---

## 5. SAM et BAM : les alignements

### 5.1 L'en-tête et les colonnes

```bash
samtools view -H alignements.sam
```

```text
@HD	VN:1.6	SO:coordinate
@SQ	SN:chrA	LN:6000
@SQ	SN:chrP	LN:2400
@RG	ID:evolue_A	SM:evolue_A	PL:ILLUMINA
@PG	ID:simulateur	PN:generer_donnees.py	VN:1.0	CL:python3 tools/generer_donnees.py
@PG	ID:samtools	PN:samtools	PP:simulateur	VN:1.25	CL:samtools view -H alignements.sam
```

`@SQ` liste les séquences de référence, `@RG` le groupe de lectures
(l'échantillon) et `@PG` les programmes qui ont produit ou lu le fichier :
`samtools` vient d'ajouter sa propre ligne, ce qui garde une trace de la
chaîne de traitement. Viennent ensuite les lectures, une par ligne, en
11 colonnes obligatoires :

```bash
samtools view alignements.sam | head -n 2 | cut -f 1-9
```

```text
read0001	16	chrA	31	60	100M	*	0	0
read0002	0	chrA	51	60	100M	*	0	0
```

| Col. | Nom | Exemple | Signification |
|---|---|---|---|
| 1 | QNAME | `read0001` | nom du read |
| 2 | **FLAG** | `16` | propriétés codées en bits (section 5.2) |
| 3 | RNAME | `chrA` | séquence de référence |
| 4 | **POS** | `31` | position de la 1re base alignée, **1-based** |
| 5 | **MAPQ** | `60` | confiance dans la position (Phred : 60 = très sûre ; 0 = le read pourrait s'aligner ailleurs) |
| 6 | **CIGAR** | `100M` | description de l'alignement (section 5.3) |
| 7-9 | RNEXT, PNEXT, TLEN | `* 0 0` | le partenaire, en paired-end (ici single-end) |
| 10-11 | SEQ, QUAL | | la séquence et sa qualité |

### 5.2 Le FLAG : plusieurs informations dans un seul nombre

Chaque propriété vaut une puissance de 2, et le FLAG est leur **somme**.
`samtools flags` décode :

```bash
samtools flags 16
samtools flags 4
```

```text
0x10	16	REVERSE
0x4	4	UNMAP
```

| Bit | Valeur | Signification |
|---|---|---|
| 0x1 | 1 | read apparié (paired-end) |
| 0x2 | 2 | paire correctement alignée |
| 0x4 | 4 | **read non aligné** |
| 0x10 | 16 | aligné sur le **brin inverse** |
| 0x100 | 256 | alignement secondaire |
| 0x400 | 1024 | duplicat PCR ou optique |

`-f N` garde les reads qui **ont** le bit N, `-F N` ceux qui **ne l'ont pas** :

```bash
samtools view -c alignements.sam
samtools view -c -F 4 alignements.sam
samtools view -c -f 4 alignements.sam
samtools view -c -q 30 alignements.sam
```

```text
850
820
30
782
```

850 lectures, dont 820 alignées et 30 non alignées ; 782 ont un MAPQ d'au
moins 30. `samtools flagstat` donne le bilan complet :

```text
850 + 0 in total (QC-passed reads + QC-failed reads)
…
820 + 0 mapped (96.47% : N/A)
```

### 5.3 Le CIGAR : décrire l'alignement

| Lettre | Signification |
|---|---|
| `M` | base alignée (identique **ou non** à la référence) |
| `I` | **insertion** dans le read par rapport à la référence |
| `D` | **délétion** dans le read |
| `S` | base « coupée » (*soft clipping*) : présente dans le read, non alignée |
| `N` | saut dans la référence (introns, en RNA-seq) |

```bash
samtools view alignements.sam | cut -f 6 | grep -v "^100M$" | sort | uniq -c | sort -rn | head -n 4
```

```text
     30 *
      2 64M1I35M
      2 30M2D70M
      1 81M1I18M
```

`30M2D70M` : 30 bases alignées, puis 2 bases de la référence **absentes**
du read, puis 70 bases alignées. Ce sont les traces de la délétion présente
dans la souche `evolue_A` (section 7). `*` correspond aux reads non alignés.

### 5.4 BAM : trier, indexer, interroger une région

Le **BAM** est la version binaire et compressée du SAM : même contenu, 3 à
4 fois plus petit. **Trié par position et indexé**, il permet d'extraire
instantanément les reads d'une région :

```bash
samtools sort -o alignements.bam alignements.sam
samtools index alignements.bam
ls -lh alignements.*
```

```text
-rw-r--r-- 1 marie marie  64K Nov 25 00:18 alignements.bam
-rw-r--r-- 1 marie marie  176 Nov 25 00:18 alignements.bam.bai
-rw-r--r-- 1 marie marie 209K Nov 25 00:18 alignements.sam
```

```bash
samtools view -c alignements.bam chrA:400-420
samtools coverage alignements.bam
```

```text
12
#rname	startpos	endpos	numreads	covbases	coverage	meandepth	meanbaseq	meanmapq
chrA	1	6000	600	5967	99.45	9.99833	30.6	57.6
chrP	1	2400	220	2381	99.2083	9.16667	30.6	57.1
```

12 reads couvrent la région 400-420. Le chromosome est couvert à 99,5 %,
avec une **profondeur moyenne** d'environ 10× : chaque base est lue
10 fois en moyenne.

**Voir un variant dans les reads** : `samtools mpileup` empile les bases
lues à une position.

```bash
samtools mpileup -f reference.fasta -r chrA:412-412 alignements.bam
```

```text
chrA	412	A	11	gGGgggGGGGG
```

Position 412 : la référence porte un `A`, mais les 11 reads lisent un `G`
(majuscule : brin direct ; minuscule : brin inverse). La souche porte la
mutation A→G, soutenue par toutes les lectures, sur les deux brins.

---

## 6. BED, GFF3, GTF : les annotations, et le piège des coordonnées

### 6.1 Le même gène, trois écritures

```text
GFF3 : chrA  synthese  gene  151  1050  .  +  .  ID=gene01;Name=gyrA;product=…
GTF  : chrA  synthese  CDS   151  1050  .  +  0  gene_id "gene01"; transcript_id "mrna01"; gene_name "gyrA";
BED  : chrA  150       1050  gyrA  0  +
```

| | GFF3 / GTF / VCF / SAM | BED |
|---|---|---|
| première base | **1** | **0** |
| la fin est | **incluse** | **exclue** |
| gyrA s'écrit | `151 1050` | `150 1050` |
| longueur | fin − début + 1 = 900 | fin − début = 900 |

Les deux décrivent **exactement les mêmes 900 bases**. Vérification :

```bash
samtools faidx reference.fasta chrA:151-153
bedtools getfasta -fi reference.fasta -bed <(printf "chrA\t150\t153\n")
bedtools getfasta -fi reference.fasta -bed <(printf "chrA\t151\t153\n")
```

```text
>chrA:151-153
ATG
>chrA:150-153
ATG
>chrA:151-153
TG
```

Le codon d'initiation `ATG` s'écrit `151-153` en 1-based et `150 153` en
BED. Écrire `151` dans un BED **perd une base** et décale le cadre de
lecture, sans le moindre message d'erreur.

> **Règle : à chaque conversion entre BED et un autre format, début − 1 (ou
> + 1).** Au chapitre 07, vous l'avez programmée en awk.

### 6.2 Extraire et traduire les gènes

```bash
bedtools getfasta -s -name -fi reference.fasta -bed genes.bed > genes.fasta
seqkit fx2tab -n -l genes.fasta | head -n 3
seqkit translate genes.fasta | seqkit subseq -r 1:12 | grep -v "^>" | head -n 3
```

```text
gyrA::chrA:150-1050(+)	900
recA::chrA:1170-1920(-)	750
rpoB::chrA:2120-3320(+)	1200
MKYLAHVAGHSL
MPPINKDIRRRS
MTENILSRPRLR
```

`-s` tient compte du **brin** : pour recA, sur le brin `-`, bedtools
extrait le **reverse complement**, ce qui donne la séquence lue par
l'ARN polymérase. Les protéines commencent toutes par `M` (méthionine), et
chacune ne contient qu'un seul codon stop, à la fin (`*`). C'est la preuve
que les coordonnées et les brins sont corrects.

---

## 7. VCF : les variants

### 7.1 Lire et interroger

```bash
bcftools view -H variants.vcf | head -n 2
bcftools query -l variants.vcf
```

```text
chrA	95	.	T	C	87	PASS	DP=27	GT:DP	1:13	1:14
chrA	412	.	A	G	60	PASS	DP=41	GT:DP	1:17	1:24
evolue_A
evolue_B
```

`bcftools query -f` extrait les champs choisis, dans le format de votre
choix (`[ ]` répète pour chaque échantillon) :

```bash
bcftools query -f "%CHROM\t%POS\t%REF\t%ALT\t%QUAL\t%FILTER\t[%GT\t]\n" variants.vcf | head -n 4
```

```text
chrA	95	T	C	87	PASS	1	1
chrA	412	A	G	60	PASS	1	1
chrA	655	T	A	18	LowQual	1	0
chrA	1388	C	A	22	LowQual	0	1
```

Ce génome est **haploïde** (une bactérie) : le génotype vaut `0` (allèle de
référence) ou `1` (allèle alternatif). Chez un organisme diploïde, il
s'écrirait `0/0`, `0/1` (hétérozygote) ou `1/1`.

### 7.2 Filtrer

| Commande | Garde |
|---|---|
| `bcftools view -f PASS` | les variants qui ont passé les filtres |
| `bcftools view -i 'QUAL>=100'` | ceux qui satisfont une expression (`-e` : ceux qui ne la satisfont pas) |
| `bcftools view -v snps` / `-v indels` | les SNP / les indels |
| `bcftools view -s evolue_A` | les colonnes d'un seul échantillon |
| `bcftools view -H` | sans l'en-tête |

> **Piège : `-s` et `-i` dans la même commande.**
> `bcftools view -s evolue_B -i 'GT="alt"'` ne garde **pas** seulement les
> variants d'evolue_B : le filtre `-i` est évalué sur **tous** les
> échantillons, avant la sélection par `-s`. Il garde donc tout variant que
> l'une des deux souches porte (ici, les 14). Faites-le en deux temps, avec
> un pipe :
> `bcftools view -s evolue_B variants.vcf | bcftools view -H -i 'GT="alt"'`
> donne bien les 8 variants d'evolue_B. **Vérifiez toujours un filtre sur un
> cas dont vous connaissez la réponse.**

```bash
bcftools view -H -v indels variants.vcf | cut -f 1-5
```

```text
chrA	1703	.	TTA	T
chrA	2967	.	A	AG
```

Une délétion de 2 pb (`TTA` → `T` : la base d'ancrage `T` est conservée, et
les deux bases `TA` disparaissent) et une insertion de 1 pb.

### 7.3 Compresser et indexer

Comme pour le BAM, un VCF volumineux se compresse (en **BGZF**, une variante
de gzip découpée en blocs) et s'indexe pour interroger une région :

```bash
bcftools view -Oz -o variants.vcf.gz variants.vcf
bcftools index variants.vcf.gz
bcftools view -H variants.vcf.gz chrA:2000-3500 | cut -f 1,2,4,5
```

```text
chrA	2480	A	C
chrA	2967	A	AG
chrA	3120	A	G
chrA	3420	A	T
```

`bcftools stats variants.vcf | grep "^SN"` résume le fichier : 2
échantillons, 14 variants, 12 SNP, 2 indels.

---

## 8. Croiser régions et variants : bedtools

`bedtools` répond aux questions du type « qu'est-ce qui chevauche quoi ? »,
sur tous les formats de régions : BED, GFF, VCF, BAM.

**Quels variants tombent dans des gènes, et lesquels ?**

```bash
bedtools intersect -a variants.vcf -b genes.bed -wa -wb | cut -f 2,4,5,15 | head -n 4
bedtools intersect -a variants.vcf -b genes.bed -v | cut -f 1,2,4,5
```

```text
412	A	G	gyrA
655	T	A	gyrA
1388	C	A	recA
1703	TTA	T	recA
chrA	95	T	C
chrA	3420	A	T
chrA	5600	G	T
```

`-wa -wb` affiche la ligne du variant **et** celle du gène qu'il chevauche ;
`-v` garde les variants qui ne chevauchent **aucun** gène (ici, 3 variants
intergéniques).

**Combien de variants par gène ? Quelle couverture ?**

```bash
bedtools intersect -a genes.bed -b variants.vcf -c
bedtools coverage -a genes.bed -b alignements.bam | cut -f 4,7,10
```

```text
chrA	150	1050	gyrA	0	+	2
chrA	1170	1920	recA	0	-	2
chrA	2120	3320	rpoB	0	+	3
…
gyrA	82	1.0000000
recA	92	1.0000000
…
```

Chaque gène est couvert à 100 % par des lectures (dernière colonne) : on
peut se fier aux génotypes de la souche `evolue_A` dans tous les gènes.

| Commande bedtools | Question |
|---|---|
| `intersect -a A -b B` | les éléments de A qui chevauchent B (`-v` : qui ne chevauchent pas ; `-c` : combien de chevauchements) |
| `getfasta -fi ref.fa -bed regions.bed` | la séquence des régions |
| `coverage -a regions -b reads.bam` | la couverture de chaque région |
| `sort -i` | trier par chromosome et position |
| `merge -i` | fusionner les régions qui se chevauchent |

> **Les fichiers BED doivent être tabulés.** Avec des espaces, `bedtools`
> répond `Error: unable to open file or unable to determine types for
> file … Please ensure that your file is TAB delimited`.

---

## 9. Pièges fréquents

| Situation | Symptôme | Solution |
|---|---|---|
| coordonnées BED et GFF/VCF mélangées | décalage d'une base, cadre de lecture faux | début − 1 vers BED, + 1 depuis BED |
| BAM non trié ou non indexé | `samtools view fichier.bam région` refuse, ou il faut tout relire | `samtools sort` puis `samtools index` |
| région mal écrite (`chrZ`, `chr1` au lieu de `chrA`) | `specifies an invalid region or unknown reference` | les noms exacts : `samtools view -H` (`@SQ`), `cut -f 1 ref.fa.fai` |
| VCF compressé avec `gzip` au lieu de BGZF | `bcftools index` refuse | `bcftools view -Oz -o f.vcf.gz`, ou `bgzip` |
| FLAG lu « à l'œil » | mauvaise interprétation | `samtools flags N` |
| MAPQ 0 ignoré | reads mal placés comptés comme preuves | `-q 30` |
| BED séparé par des espaces | erreur `TAB delimited` | `\t` ; vérifier avec `cat -A` |
| `-s` oublié dans `getfasta` | gènes du brin `-` à l'envers | `-s` |

---

## 10. À vous de jouer

Toujours dans `~/formation_linux/formats`, environnement actif.

### Exercice 1 : un codon par ses coordonnées

*Objectif : 1-based et 0-based.*
Le gène blaTEM est annoté dans `genes.bed` de `100` à `961` sur `chrP`,
brin `+`. Donnez la région de son codon **stop** en notation `samtools`
(1-based) et en BED, extrayez-le des deux façons, et vérifiez que c'est
bien un codon stop.

<details>
<summary>Corrigé</summary>

En BED, la fin (961) est exclue : les trois dernières bases sont `958 961`.
En 1-based, bornes incluses : `chrP:959-961`.

```bash
samtools faidx reference.fasta chrP:959-961
bedtools getfasta -fi reference.fasta -bed <(printf "chrP\t958\t961\n")
```

Les deux donnent `TAG`, un codon stop.
</details>

### Exercice 2 : le bilan d'un alignement

*Objectif : `samtools view -c`, `-f`, `-F`, `-q`.*
Combien de lectures (a) sont alignées sur le brin inverse ? (b) sont alignées
sur le plasmide `chrP` ? (c) ont un MAPQ inférieur à 30 parmi les lectures
alignées ?

<details>
<summary>Corrigé</summary>

```bash
samtools view -c -f 16 alignements.bam
samtools view -c alignements.bam chrP
echo $(( $(samtools view -c -F 4 alignements.bam) - $(samtools view -c -F 4 -q 30 alignements.bam) ))
```

(a) `409`. (b) `220`. (c) 820 − 782 = `38`. La troisième réponse combine
deux comptages et l'arithmétique du chapitre 05.
</details>

### Exercice 3 : la délétion vue dans les reads

*Objectif : relier CIGAR, VCF et pileup.*
Le VCF annonce une délétion à la position 1703 de chrA. Affichez trois reads
qui la portent, et expliquez leur CIGAR.

<details>
<summary>Corrigé</summary>

```bash
samtools view alignements.bam chrA:1700-1705 | cut -f 1-6 | head -n 3
```

```text
read0141	16	chrA	1636	60	68M2D32M
read0142	16	chrA	1641	60	63M2D37M
read0143	0	chrA	1644	12	60M2D40M
```

read0141 commence à 1636 : 68 bases alignées (1636 à 1703), puis 2 bases de
la référence absentes (1704 et 1705), puis 32 bases. Le `TTA` → `T` du VCF
(ancré en 1703) correspond exactement à ce trou. Le MAPQ de read0143 n'est
que de 12 : on ne l'utiliserait pas comme preuve.
</details>

### Exercice 4 : comparer deux souches

*Objectif : `bcftools query` et les génotypes.*
Combien de variants portent chacune des deux souches (génotype `1`) ?
Combien en partagent-elles ? Ne comptez que les variants `PASS`.

<details>
<summary>Indice</summary>

`bcftools query -f '[%GT\t]\n'` donne les deux génotypes sur une ligne, et
awk compte les lignes où la colonne 1, la colonne 2, ou les deux valent `1`.
</details>

<details>
<summary>Corrigé</summary>

```bash
bcftools view -f PASS variants.vcf | bcftools query -f '[%GT\t]\n' | awk '$1 == 1 { a++ } $2 == 1 { b++ } $1 == 1 && $2 == 1 { ab++ } END { print a, b, ab }'
```

```text
7 6 4
```

Parmi les 9 variants PASS, evolue_A en porte 7 et evolue_B en porte 6, dont
4 en commun. evolue_A a donc 3 mutations propres, et evolue_B 2.
</details>

---

## 11. Défi : la carte des mutations par gène

Produisez, pour la souche `evolue_A` et pour les seuls variants `PASS`
qu'elle porte, un tableau `gene position ref alt profondeur_alt` où la
dernière colonne donne le **nombre de lectures du BAM** qui portent
l'allèle alternatif. C'est une vérification indépendante de l'appel de
variants.

<details>
<summary>Indice</summary>

1. `bcftools view -f PASS -s evolue_A` garde la colonne de la souche ; un
   second `bcftools view -i 'GT="alt"'`, après un pipe, ne garde que les
   variants qu'elle porte. `bedtools intersect -wa -wb` y ajoute le gène.
2. Pour chaque ligne (`while read`, chapitre 12), `samtools mpileup -r`
   donne la colonne des bases lues. Pour un SNP, comptez avec `grep -o -i`
   la base alternative dans cette colonne.
</details>

<details>
<summary>Corrigé</summary>

```bash
bcftools view -f PASS -s evolue_A variants.vcf | bcftools view -i 'GT="alt"' -Oz -o A.vcf.gz
bcftools index A.vcf.gz
bedtools intersect -a A.vcf.gz -b genes.bed -wa -wb | awk 'BEGIN { OFS = "\t" } { print $1, $2, $4, $5, $(NF-2) }' > A_genes.tsv
while IFS=$'\t' read -r chrom pos ref alt gene; do
    bases=$(samtools mpileup -f reference.fasta -r "$chrom:$pos-$pos" alignements.bam 2> /dev/null | cut -f 5)
    if [ ${#ref} -eq 1 ] && [ ${#alt} -eq 1 ]; then
        n=$(echo "$bases" | grep -o -i "$alt" | wc -l)
    else
        n=$(echo "$bases" | grep -o "[+-][0-9]" | wc -l)
    fi
    printf "%s\t%s\t%s\t%s\t%s\n" "$gene" "$pos" "$ref" "$alt" "$n"
done < A_genes.tsv
```

```text
gyrA	412	A	G	11
rpoB	2967	A	AG	10
katG	3800	A	G	8
ompC	4750	T	C	5
blaTEM	350	C	T	12
tetA	1500	C	A	8
```

Chaque variant est soutenu par 5 à 12 lectures, ce qui correspond à la
profondeur d'environ 10× : l'appel de variants est cohérent avec les
alignements. Pour l'insertion, `mpileup` note chaque base insérée par `+1G`,
d'où le comptage des motifs `+chiffre` ou `-chiffre`. Vous irez plus loin
au projet 3.
</details>

---

## L'essentiel

```text
FASTA   samtools faidx ref.fa ; samtools faidx ref.fa chrA:151-180      (1-based, bornes incluses)
FASTQ   Q = code ASCII − 33 ; Q30 = 1 erreur / 1000 ; seqkit fx2tab -q
SAM     QNAME FLAG RNAME POS MAPQ CIGAR … SEQ QUAL    samtools flags N
        samtools view -c  -f 4 / -F 4  -q 30  ;  samtools flagstat
        CIGAR : M aligné, I insertion, D délétion, S coupé, N intron
BAM     samtools sort -o f.bam f.sam ; samtools index f.bam ; samtools view f.bam chrA:400-420
        samtools coverage ; samtools mpileup -f ref.fa -r chrA:412-412 f.bam
BED     0-based, fin exclue ; GFF/GTF/VCF/SAM : 1-based, fin incluse → début − 1
VCF     bcftools view -H / -f PASS / -i 'QUAL>=30' / -v snps|indels / -s échantillon
        bcftools query -f '%CHROM\t%POS\t%REF\t%ALT[\t%GT]\n' ; bcftools view -Oz ; bcftools index
bedtools intersect -wa -wb / -v / -c ; getfasta -s -name ; coverage
```

### Auto-évaluation

- [ ] Je sais quelle question permet de poser chacun des six formats.
- [ ] Je calcule un score Phred à partir d'un caractère de qualité.
- [ ] Je décode un FLAG et un CIGAR, et je trie et indexe un BAM.
- [ ] Je convertis sans erreur des coordonnées entre BED et GFF/VCF.
- [ ] Je filtre un VCF et je croise des variants avec des gènes.
- [ ] Je vérifie un variant directement dans les lectures alignées.

## Documentation officielle

- Spécifications SAM, BAM, CRAM, VCF, BED (hts-specs) : <https://samtools.github.io/hts-specs/>
- samtools et bcftools : <https://www.htslib.org/doc/>
- bedtools : <https://bedtools.readthedocs.io/>
- GFF3 : <https://github.com/The-Sequence-Ontology/Specifications/blob/master/gff3.md>
- Cock P. J. A. *et al.* (2010), « The Sanger FASTQ file format for sequences with quality scores, and the Solexa/Illumina FASTQ variants », *Nucleic Acids Research* 38(6):1767-1771, DOI [10.1093/nar/gkp1137](https://doi.org/10.1093/nar/gkp1137)
- Danecek P. *et al.* (2021), « Twelve years of SAMtools and BCFtools », *GigaScience* 10(2):giab008, DOI [10.1093/gigascience/giab008](https://doi.org/10.1093/gigascience/giab008)
- Quinlan A. R. et Hall I. M. (2010), « BEDTools: a flexible suite of utilities for comparing genomic features », *Bioinformatics* 26(6):841-842, DOI [10.1093/bioinformatics/btq033](https://doi.org/10.1093/bioinformatics/btq033)

**Prochaine étape** : [chapitre 17 — Organiser un projet](../17_organiser_projet/README.md).
