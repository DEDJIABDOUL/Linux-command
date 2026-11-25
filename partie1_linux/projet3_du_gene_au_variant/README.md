# Projet 3 — Du gène au variant : quelles mutations, et quelles conséquences ?

> **Durée estimée** : 3 à 4 h
> **Prérequis** : chapitres [16](../16_formats_biologiques/README.md) et [17](../17_organiser_projet/README.md), environnement `formation_partie1`
> **Mobilise** : samtools, bcftools, bedtools, seqkit, coordonnées 0/1-based, boucles, awk, script robuste
> **Suite** : [Projet de synthèse](../projet_synthese/README.md)

## La situation

Deux souches bactériennes, `evolue_A` et `evolue_B`, ont été cultivées
pendant des centaines de générations en présence d'antibiotiques, puis
séquencées. L'équipe a déjà appelé les variants par rapport à la souche
ancestrale (`formats/variants.vcf`), et dispose des lectures de la souche
`evolue_A` alignées sur la référence (`formats/alignements.sam`).

Votre encadrante pose trois questions :

1. **Quels gènes** sont touchés chez chaque souche ?
2. Ces mutations sont-elles **réelles**, c'est-à-dire bien soutenues par les
   lectures ?
3. Quelles sont leurs **conséquences sur les protéines** : changement
   d'acide aminé, mutation synonyme, décalage du cadre de lecture ?

Plusieurs gènes du génome évoquent des cibles d'antibiotiques bien connues
chez les bactéries : `gyrA` (cible des quinolones), `rpoB` (rifampicine),
`katG`, ou `blaTEM`, une β-lactamase. Les données sont **synthétiques** :
les mutations n'ont pas de signification clinique réelle, mais la démarche
est exactement celle d'une étude de résistance.

---

## Le cahier des charges

Un script `du_gene_au_variant.sh SOUCHE`, lancé depuis `~/formation_linux`,
qui écrit dans `projet3/SOUCHE/` :

| Fichier | Contenu |
|---|---|
| `variants.vcf.gz` (+ index) | les variants `PASS` **portés par la souche** |
| `variants_genes.tsv` | `chrom pos ref alt gene` pour les variants situés dans un gène |
| `variants_intergeniques.tsv` | les autres |
| `changements_proteiques.tsv` | `gene changement`, par exemple `gyrA I88V` |
| `rapport.tsv` | `gene position ref alt reads_alt consequence` |

La colonne `consequence` vaut le changement d'acide aminé (`I88V`),
`synonyme`, `decalage_du_cadre(Npb)` ou `indel_en_phase(Npb)`.
`reads_alt` vaut le nombre de lectures qui portent l'allèle alternatif, ou
`NA` si le BAM ne contient pas les lectures de cette souche.

Le script vérifie qu'il reçoit une souche existante, et que les quatre
outils sont disponibles.

---

## Étape 1 — Préparer les données

Dans `projet3/SOUCHE/` : copiez la référence et indexez-la, triez et indexez
le BAM (chapitre 16, sections 3 et 5.4).

**Point de contrôle** : `samtools view -c projet3/evolue_A/alignements.bam chrA:400-420`
affiche `12`.

---

## Étape 2 — Les variants de la souche

Gardez les variants `PASS` dont le génotype de la souche est `1`.

> **Attention au piège du chapitre 16** : `-s` et `-i` dans une même
> commande `bcftools view` ne font pas ce que l'on croit. Testez votre
> filtre sur les deux souches : leurs nombres de variants doivent
> **différer**.

**Point de contrôle** : 7 variants pour `evolue_A`, 6 pour `evolue_B`.

<details>
<summary>Indice</summary>

`bcftools view -f PASS -s "$souche" variants.vcf | bcftools view -i 'GT="alt"' -Oz -o …`,
puis `bcftools index`.
</details>

---

## Étape 3 — Dans quels gènes ?

Avec `bedtools intersect`, séparez les variants situés dans un gène (en
ajoutant le nom du gène) de ceux qui sont intergéniques.

**Point de contrôle** : pour `evolue_A`, 6 variants dans des gènes (gyrA,
rpoB, katG, ompC, blaTEM, tetA) et 1 intergénique (`chrA 95`). Pour
`evolue_B`, 3 dans des gènes (gyrA, katG, blaTEM) et 3 intergéniques.

---

## Étape 4 — Les mutations sont-elles soutenues par les lectures ?

Pour chaque variant situé dans un gène, comptez dans le BAM les lectures qui
portent l'allèle alternatif (le défi du chapitre 16 en donne la méthode).
Comme le BAM ne contient que les lectures d'**une** souche, lisez son nom
dans l'en-tête `@RG` (champ `SM:`), et écrivez `NA` pour l'autre souche.

**Point de contrôle** : pour `evolue_A`, 5 à 12 lectures par variant
(gyrA : 11, rpoB : 10, katG : 8, ompC : 5, blaTEM : 12, tetA : 8). La
profondeur moyenne étant d'environ 10× (chapitre 16), chaque mutation est
soutenue par la quasi-totalité des lectures qui la couvrent.

---

## Étape 5 — Les conséquences sur les protéines

C'est le cœur biologique du projet. La démarche :

1. construire la séquence du génome **de la souche**, en appliquant ses
   variants à la référence : `bcftools consensus` ;
2. extraire les 7 gènes de la référence **et** de ce génome muté, en tenant
   compte du brin (`bedtools getfasta -s`), puis les traduire
   (`seqkit translate`) ;
3. comparer les protéines **acide aminé par acide aminé**, et noter chaque
   différence sous la forme `I88V` : l'isoleucine en position 88 est devenue
   une valine.

<details>
<summary>Indice : comparer deux protéines en awk</summary>

`seqkit fx2tab` met chaque protéine sur une ligne (`nom<TAB>séquence`).
`paste proteines_ref.tsv proteines_souche.tsv` place les deux versions côte
à côte, et awk compare les caractères un par un avec `substr($2, i, 1)` et
`substr($4, i, 1)`.
</details>

### Le piège des indels : à découvrir avant de corriger

Faites d'abord l'étape 5 en appliquant **tous** les variants d'evolue_A, y
compris l'insertion dans rpoB. Regardez les changements obtenus pour katG
et ompC :

```text
katG	M1W
katG	A2R
ompC	M1D
ompC	K2E
…
```

`M1W` : la méthionine **initiale** de katG serait devenue un tryptophane ?
C'est biologiquement absurde. La raison : l'insertion d'une base dans rpoB
(position 2967) **allonge** le chromosome muté d'une base
(`seqkit fx2tab -n -l` affiche 6001 au lieu de 6000). Toutes les positions
situées en aval sont donc décalées d'une base, alors que vous extrayez katG
et ompC avec les coordonnées de la **référence** : vous lisez à côté.

> **Leçon** : une coordonnée n'a de sens que **par rapport à une séquence
> donnée**. Après des insertions ou des délétions, les coordonnées de la
> référence ne s'appliquent plus au génome muté. Les outils professionnels
> d'annotation des variants (VEP, SnpEff : module 21 de la Partie II) gèrent
> ce problème pour vous. Ici, la solution simple est de :
> - construire le consensus avec les **seuls SNP** (`bcftools view -v snps`)
>   pour calculer les changements d'acides aminés ;
> - qualifier les indels à part : une longueur non multiple de 3 décale le
>   cadre de lecture.

**Point de contrôle** (SNP seulement, evolue_A) :

```text
gyrA	I88V
katG	S101P
ompC	Y134H
blaTEM	R84W
tetA	V88F
```

Vérifiez l'un d'eux **à la main**. ompC est sur le brin `+`, et commence à la
position 4351 (BED `4350`). La mutation en 4750 touche la base n° 400 du
gène, c'est-à-dire la 1ʳᵉ base du codon n° 134 (`(400 − 1) / 3 + 1`) :

```bash
samtools faidx projet3/evolue_A/ref.fasta chrA:4750-4752
samtools faidx projet3/evolue_A/consensus_snps.fasta chrA:4750-4752
```

```text
>chrA:4750-4752
TAC
>chrA:4750-4752
CAC
```

`TAC` (tyrosine, Y) devient `CAC` (histidine, H) : c'est bien Y134H.

---

## Étape 6 — Le rapport

Assemblez `rapport.tsv`. Pour un SNP, la conséquence est le changement
protéique du gène, ou `synonyme` s'il n'y en a pas. Pour un indel, calculez
`longueur(ALT) − longueur(REF)` : si ce nombre n'est pas un multiple de 3,
c'est un décalage du cadre de lecture.

**Point de contrôle** : `bash du_gene_au_variant.sh evolue_A` affiche :

```text
Variants PASS portés par evolue_A : 7
Dans un gène : 6 ; intergéniques : 1
gene    position  ref  alt  reads_alt  consequence
gyrA    412       A    G    11         I88V
rpoB    2967      A    AG   10         decalage_du_cadre(1pb)
katG    3800      A    G    8          S101P
ompC    4750      T    C    5          Y134H
blaTEM  350       C    T    12         R84W
tetA    1500      C    A    8          V88F
```

et `bash du_gene_au_variant.sh evolue_B` :

```text
Variants PASS portés par evolue_B : 6
Dans un gène : 3 ; intergéniques : 3
gene    position  ref  alt  reads_alt  consequence
gyrA    412       A    G    NA         I88V
katG    3800      A    G    NA         S101P
blaTEM  350       C    T    NA         R84W
```

---

## Étape 7 — Interpréter

Rédigez quelques lignes de conclusion, en vous appuyant uniquement sur les
résultats :

- Quelles mutations les deux souches **partagent-elles** ? Quelle hypothèse
  évolutive cela suggère-t-il ?
- Quelles mutations sont **propres** à evolue_A ?
- Pourquoi la mutation de rpoB est-elle probablement la plus lourde de
  conséquences pour la protéine ?
- Quelle donnée manque pour confirmer les mutations d'evolue_B ?

<details>
<summary>Éléments de réponse</summary>

- Les deux souches partagent **gyrA I88V, katG S101P et blaTEM R84W**. Des
  mutations identiques dans deux lignées indépendantes suggèrent soit un
  ancêtre commun qui les portait déjà, soit une **évolution convergente**
  sous la même pression de sélection. Pour trancher, il faudrait séquencer
  des échantillons intermédiaires.
- evolue_A porte en plus une insertion dans **rpoB**, et des changements
  dans **ompC** (une porine : sa modification peut réduire l'entrée d'un
  antibiotique) et **tetA** (une pompe d'efflux).
- L'insertion d'une base dans rpoB **décale le cadre de lecture** à partir
  du codon 283 environ : toute la suite de la protéine est modifiée, et un
  codon stop prématuré apparaît généralement. C'est bien plus drastique
  qu'une substitution d'un seul acide aminé.
- Les mutations d'evolue_B n'ont pas pu être vérifiées dans les lectures
  (`NA`) : il faudrait aligner **ses propres lectures**.

Une conclusion honnête distingue toujours ce qui est **observé** (une
mutation soutenue par 11 lectures) de ce qui est **supposé** (son effet sur
la résistance), qui demanderait une validation expérimentale.
</details>

---

## Grille d'évaluation

| Critère | ✔ |
|---|---|
| les variants sont bien filtrés **par souche** (7 et 6, et non 9 et 9) | |
| les coordonnées 0/1-based sont correctes : les protéines de référence commencent par `M` et ne contiennent qu'un seul stop, en fin de séquence | |
| l'artefact `M1W` a été compris et évité | |
| au moins un changement protéique vérifié à la main, codon à l'appui | |
| le rapport est produit par un script relançable, qui passe ShellCheck | |
| l'interprétation distingue l'observé du supposé | |

---

## Solution complète

<details>
<summary>Afficher la solution</summary>

```bash
#!/bin/bash
# du_gene_au_variant.sh — des variants d'une souche à leurs conséquences sur les protéines.
#
# Usage : bash du_gene_au_variant.sh SOUCHE
#   (à lancer depuis ~/formation_linux, environnement formation_partie1 actif)
# Résultats dans projet3/SOUCHE/
set -euo pipefail

[ $# -eq 1 ] || { echo "Usage : $0 SOUCHE (evolue_A ou evolue_B)" >&2; exit 1; }
souche=$1
F=formats
S=projet3/$souche
for outil in samtools bcftools bedtools seqkit; do
    command -v "$outil" > /dev/null || { echo "Erreur : $outil introuvable (conda activate formation_partie1)" >&2; exit 1; }
done
bcftools query -l "$F/variants.vcf" | grep -qx "$souche" || { echo "Erreur : souche inconnue : $souche" >&2; exit 1; }
mkdir -p "$S"

# 1. Préparer : référence indexée, BAM trié et indexé
cp "$F/reference.fasta" "$S/ref.fasta"
samtools faidx "$S/ref.fasta"
samtools sort -o "$S/alignements.bam" "$F/alignements.sam" 2> /dev/null
samtools index "$S/alignements.bam"

# 2. Les variants PASS portés par la souche
# (deux étapes : avec -s et -i dans la même commande, -i serait évalué
#  sur TOUS les échantillons avant la sélection de la souche)
bcftools view -f PASS -s "$souche" "$F/variants.vcf" | bcftools view -i 'GT="alt"' -Oz -o "$S/variants.vcf.gz"
bcftools index -f "$S/variants.vcf.gz"
echo "Variants PASS portés par $souche : $(bcftools view -H "$S/variants.vcf.gz" | wc -l)"

# 3. Dans quels gènes ?
bedtools intersect -a "$S/variants.vcf.gz" -b "$F/genes.bed" -wa -wb \
    | awk 'BEGIN { OFS = "\t" } { print $1, $2, $4, $5, $(NF-2) }' > "$S/variants_genes.tsv"
bedtools intersect -a "$S/variants.vcf.gz" -b "$F/genes.bed" -v | cut -f 1,2,4,5 > "$S/variants_intergeniques.tsv"
echo "Dans un gène : $(wc -l < "$S/variants_genes.tsv") ; intergéniques : $(wc -l < "$S/variants_intergeniques.tsv")"

# 4. Les conséquences protéiques des SNP : référence et consensus SNP, traduits
bcftools view -v snps "$S/variants.vcf.gz" -Oz -o "$S/snps.vcf.gz"
bcftools index -f "$S/snps.vcf.gz"
bcftools consensus -f "$S/ref.fasta" "$S/snps.vcf.gz" -o "$S/consensus_snps.fasta" 2> /dev/null
samtools faidx "$S/consensus_snps.fasta"
for genome in ref consensus_snps; do
    fasta="$S/ref.fasta"
    [ "$genome" = ref ] || fasta="$S/consensus_snps.fasta"
    bedtools getfasta -s -name -fi "$fasta" -bed "$F/genes.bed" | seqkit translate | seqkit fx2tab | cut -f 1,2 > "$S/proteines_$genome.tsv"
done
paste "$S/proteines_ref.tsv" "$S/proteines_consensus_snps.tsv" \
    | awk -F '\t' '{ g = $1; sub(/::.*/, "", g)
                     for (i = 1; i <= length($2); i++) {
                         a = substr($2, i, 1); b = substr($4, i, 1)
                         if (a != b) printf "%s\t%s%d%s\n", g, a, i, b
                     } }' > "$S/changements_proteiques.tsv"

# 5. Le rapport : chaque variant dans un gène, son soutien dans les reads, sa conséquence
#    (les lectures du BAM ne viennent que d'un échantillon : celui de son en-tête @RG)
echantillon_bam=$(samtools view -H "$S/alignements.bam" | awk -F '\t' '/^@RG/ { for (i = 2; i <= NF; i++) if ($i ~ /^SM:/) print substr($i, 4) }')
printf "gene\tposition\tref\talt\treads_alt\tconsequence\n" > "$S/rapport.tsv"
while IFS=$'\t' read -r chrom pos ref alt gene; do
    bases=$(samtools mpileup -f "$S/ref.fasta" -r "$chrom:$pos-$pos" "$S/alignements.bam" 2> /dev/null | cut -f 5)
    if [ "$souche" != "$echantillon_bam" ]; then
        n=NA
    elif [ ${#ref} -eq 1 ] && [ ${#alt} -eq 1 ]; then
        n=$(echo "$bases" | grep -o -i "$alt" | wc -l)
    else
        n=$(echo "$bases" | grep -o "[+-][0-9]" | wc -l)
    fi
    if [ ${#ref} -eq 1 ] && [ ${#alt} -eq 1 ]; then
        consequence=$(awk -v g="$gene" '$1 == g { print $2 }' "$S/changements_proteiques.tsv" | paste -sd,)
        [ -n "$consequence" ] || consequence="synonyme"
    else
        diff_taille=$(( ${#alt} - ${#ref} ))
        if [ $(( diff_taille % 3 )) -ne 0 ]; then
            consequence="decalage_du_cadre(${diff_taille}pb)"
        else
            consequence="indel_en_phase(${diff_taille}pb)"
        fi
    fi
    printf "%s\t%s\t%s\t%s\t%s\t%s\n" "$gene" "$pos" "$ref" "$alt" "$n" "$consequence" >> "$S/rapport.tsv"
done < "$S/variants_genes.tsv"

column -t "$S/rapport.tsv"
```

Lancement :

```bash
conda activate formation_partie1
cd ~/formation_linux
bash du_gene_au_variant.sh evolue_A
bash du_gene_au_variant.sh evolue_B
```
</details>
