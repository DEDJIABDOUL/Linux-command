# Projet 1 — Inventaire d'un run de séquençage

> **Durée estimée** : 3 à 4 h
> **Prérequis** : chapitres [01](../01_premier_contact/README.md) à [07](../07_awk_sed/README.md)
> **Mobilise** : chemins, jokers, intégrité (`md5sum`, `gzip`), pipes et redirections, `grep`, `sort`, `awk`
> **Suite** : chapitre 08 — Utilisateurs et permissions *(en cours de rédaction)*

## La situation

Vous êtes en stage dans un laboratoire de microbiologie. La plateforme de
séquençage vient de livrer le run `2026-10-14_M07112_0058` : 12 patients,
séquencés en paired-end 2 × 100 pb. Six patients sont des **témoins**, six
ont reçu un **traitement**.

Avant que l'équipe ne lance la moindre analyse (contrôle qualité, trimming,
alignement), votre encadrante vous demande un **inventaire** de la
livraison :

> « Vérifie que tout est arrivé intact, compte les reads de chaque fichier,
> repère les échantillons à problème, et envoie-moi un tableau
> récapitulatif avec deux ou trois lignes de conclusion. »

C'est le premier geste de toute analyse NGS. Il prend une heure et évite
d'en perdre des dizaines sur des données inexploitables.

Les données sont dans `~/formation_linux/run_sequencage/`.

---

## Le cahier des charges

À la fin du projet, le dossier `~/formation_linux/projet1/resultats/` doit
contenir :

| Fichier | Contenu |
|---|---|
| `controle_md5.txt` | le résultat de la vérification des sommes de contrôle |
| `inventaire_run.tsv` | un tableau tabulé, **une ligne par fichier FASTQ intègre**, avec l'en-tête : `echantillon condition lecture reads bases pct_N pct_adaptateur` |
| `conclusions.txt` | quelques lignes : fichiers reçus et intègres, échantillons à problème, et l'action à mener pour chacun |

Les contraintes :

- **ne jamais modifier** le dossier `run_sequencage/` : ce sont les données
  brutes ;
- n'utiliser que des commandes vues dans les chapitres 01 à 07 ;
- supprimer les fichiers intermédiaires volumineux à la fin du projet.

> **Comment travailler.** Chaque étape propose un objectif, des indices
> gradués et un **point de contrôle** chiffré. Ne passez à l'étape suivante
> que lorsque vous obtenez le point de contrôle. La solution complète est
> repliée à la fin : ne l'ouvrez qu'après avoir vraiment essayé. Se tromper,
> lire l'erreur et corriger, c'est exactement la compétence que ce projet
> entraîne.

---

## Étape 0 — Préparer l'espace de travail

Créez l'arborescence `~/formation_linux/projet1/`, avec deux sous-dossiers :
`resultats/` pour les livrables et `travail/` pour les fichiers
intermédiaires.

<details>
<summary>Indice</summary>

Chapitre 03 : `mkdir -p` et les accolades.
</details>

**Point de contrôle** : `ls ~/formation_linux/projet1` affiche
`resultats  travail`.

---

## Étape 1 — La livraison est-elle intacte ?

Vérifiez les 24 fichiers FASTQ à l'aide de `MD5SUMS.txt`. Enregistrez le
résultat complet, **messages d'avertissement compris**, dans
`projet1/resultats/controle_md5.txt`. Affichez ensuite uniquement les lignes
qui signalent un problème.

<details>
<summary>Indice 1</summary>

`md5sum -c` doit être lancé **depuis le dossier** qui contient les fichiers
(chapitre 04, section 8.1), car `MD5SUMS.txt` ne contient que des noms de
fichiers, sans chemin. Pensez à revenir ensuite dans `~/formation_linux`.
</details>

<details>
<summary>Indice 2</summary>

Pour capturer aussi l'avertissement : `> fichier 2>&1` (chapitre 05). Pour
n'afficher que les problèmes : `grep -v` sur les lignes qui se terminent par
`: OK`.
</details>

**Point de contrôle** :

```text
P11_S11_L001_R2_001.fastq.gz: FAILED
md5sum: WARNING: 1 computed checksum did NOT match
```

**Question** : que faut-il faire de ce fichier ? Notez votre réponse, elle
ira dans les conclusions.

---

## Étape 2 — Préparer les fichiers à analyser

Pour analyser **tous les fichiers en une seule commande awk**, il faut des
fichiers non compressés : awk ne lit pas le gzip. Copiez donc les FASTQ dans
`projet1/travail/` et décompressez-les là. Les originaux restent intacts.

Mais attention : **le fichier corrompu ne doit pas être analysé**. Un
fichier tronqué donnerait des chiffres faux sans avertissement (chapitre 05,
section 6.4). Écartez-le de votre copie de travail **avant** de
décompresser.

<details>
<summary>Indice</summary>

Trois commandes : `cp` avec un joker, `rm` de la copie (et seulement de la
copie !) du fichier corrompu, puis `gunzip` avec un joker.
</details>

**Point de contrôle** : `ls projet1/travail/*.fastq | wc -l` affiche
**23**, et `ls projet1/travail/*.gz` ne trouve plus aucun fichier.

> **Et si on ne l'avait pas écarté ?** Essayez-le une fois, dans un dossier
> à part : `gunzip` affiche `unexpected end of file` sur le fichier tronqué,
> puis **s'arrête**. Les fichiers suivants (ceux de P12) restent compressés.
> On n'obtient alors que **21** fichiers au lieu de 23, et sans le point de
> contrôle, deux échantillons auraient disparu de l'inventaire en silence.
> Leçon : **après chaque étape, vérifiez que vous avez le nombre de fichiers
> attendu.**

---

## Étape 3 — Compter les reads de chaque fichier

Commencez simplement : avec **un seul** awk sur les 23 fichiers, affichez
pour chaque fichier son nom et son nombre de reads.

<details>
<summary>Indice 1</summary>

Quand awk lit plusieurs fichiers, `FILENAME` contient le nom du fichier en
cours, et `FNR` le numéro de ligne **dans ce fichier** (chapitre 07,
section 3.3). Les séquences sont les lignes où `FNR % 4 == 2`.
</details>

<details>
<summary>Indice 2</summary>

Un tableau associatif indexé par le nom de fichier : `n[FILENAME]++`, puis
`for (f in n)` dans le bloc `END`. Ajoutez `| sort` pour un ordre stable.
</details>

**Point de contrôle** (début) :

```text
projet1/travail/P01_S1_L001_R1_001.fastq 300
projet1/travail/P01_S1_L001_R2_001.fastq 300
projet1/travail/P02_S2_L001_R1_001.fastq 280
```

> **Pourquoi `FNR` et pas `NR` ?** `NR` continue de compter d'un fichier à
> l'autre. Au deuxième fichier, sa ligne 2 aurait le numéro 1202, et
> `NR % 4 == 2` resterait vrai uniquement parce que chaque fichier compte un
> multiple de 4 lignes. Sur un fichier mal formé, tout serait décalé. `FNR`
> repart à 1 au début de chaque fichier : c'est la bonne variable.

---

## Étape 4 — Les statistiques complètes

Étendez votre programme pour produire, pour chaque fichier, une ligne
tabulée :

```text
échantillon   lecture   reads   bases   %reads_avec_N   %reads_avec_adaptateur
```

Le nom de l'échantillon (`P01`) et la lecture (`R1`) se trouvent dans le nom
du fichier. Les pourcentages ont une décimale. Enregistrez le résultat, trié,
dans `projet1/resultats/stats.tsv`.

<details>
<summary>Indice 1 : les compteurs</summary>

En plus de `n[f]++`, cumulez `b[f] += length($0)` pour les bases, et
comptez les reads qui contiennent `N` ou l'adaptateur `AGATCGGAAGAGC` avec
une condition `if ($0 ~ /…/)`.
</details>

<details>
<summary>Indice 2 : découper le nom de fichier</summary>

Dans le bloc `END`, pour chaque `f` :
`nom = f; sub(/.*\//, "", nom)` retire le chemin (tout jusqu'au dernier
`/`), puis `split(nom, p, "_")` découpe `P01_S1_L001_R1_001.fastq` en
`p[1]` = `P01`, `p[2]` = `S1`, `p[3]` = `L001`, `p[4]` = `R1`…
</details>

<details>
<summary>Indice 3 : l'affichage</summary>

`printf "%s\t%s\t%d\t%d\t%.1f\t%.1f\n", p[1], p[4], n[f], b[f], 100 * avecN[f] / n[f], 100 * adapt[f] / n[f]`
</details>

**Point de contrôle** : `wc -l projet1/resultats/stats.tsv` affiche **23**,
et le fichier commence par :

```text
P01	R1	300	30000	8.3	5.0
P01	R2	300	30000	11.7	4.7
```

---

## Étape 5 — Ajouter la condition et l'en-tête

Le tableau final doit indiquer la condition (`temoin` ou `traite`) de chaque
échantillon, qui se trouve dans `run_sequencage/echantillons.tsv`.

1. Écrivez la ligne d'en-tête dans `projet1/resultats/inventaire_run.tsv`.
2. Ajoutez-y, à la suite, les lignes de `stats.tsv` complétées par la
   condition, insérée en 2ᵉ colonne.

<details>
<summary>Indice 1 : l'en-tête</summary>

`printf 'echantillon\tcondition\tlecture\treads\tbases\tpct_N\tpct_adaptateur\n' > …`
crée le fichier. Les lignes suivantes devront être **ajoutées** (`>>`).
</details>

<details>
<summary>Indice 2 : la condition</summary>

awk à deux fichiers, `NR == FNR` (chapitre 07, section 7.5) : mémorisez
`cond[$1] = $3` en lisant la feuille d'échantillons, puis, pour chaque ligne
de `stats.tsv`, affichez `$1`, `cond[$1]`, puis les colonnes 2 à 6. Fixez
`FS` **et** `OFS` à la tabulation dans un bloc `BEGIN`.
</details>

**Point de contrôle** : `column -t projet1/resultats/inventaire_run.tsv`
affiche 24 lignes (l'en-tête et 23 fichiers). Extrait :

```text
echantillon  condition  lecture  reads  bases  pct_N  pct_adaptateur
P01          temoin     R1       300    30000  8.3    5.0
...
P09          traite     R1       150    15000  94.7   14.0
P09          traite     R2       150    15000  96.7   13.3
...
P11          traite     R1       300    30000  10.7   2.3
P12          traite     R1       270    27000  14.8   2.2
P12          traite     R2       270    27000  21.9   1.9
```

---

## Étape 6 — Repérer les problèmes automatiquement

Lire le tableau à l'œil fonctionne pour 23 lignes, pas pour 2 000. Écrivez
deux commandes awk sur `inventaire_run.tsv` :

1. les fichiers dont **plus de 50 %** des reads contiennent un `N`, **ou**
   dont **plus de 10 %** contiennent l'adaptateur ;
2. les échantillons dont le R1 et le R2 **n'ont pas le même nombre de
   reads**, ou dont l'un des deux manque.

<details>
<summary>Indice pour la commande 2</summary>

Deux tableaux : `r1[$1] = $4` sur les lignes R1, `r2[$1] = $4` sur les
lignes R2. Dans `END`, pour chaque échantillon `e` de `r1` :
`if (!(e in r2)) print e, "R2 absent"`, sinon comparer `r1[e]` et `r2[e]`.
</details>

**Point de contrôle** : la commande 1 signale les deux fichiers de **P09** ;
la commande 2 signale **P11** (`R2 absent`).

---

## Étape 7 — Conclure et ranger

1. Rédigez `projet1/resultats/conclusions.txt` avec `echo` et `>>`. Il doit
   indiquer au minimum :
   - la date et l'identifiant du run ;
   - le nombre de fichiers reçus et intègres, **calculés par des commandes**
     (`$( )`) et non recopiés à la main ;
   - pour chaque échantillon à problème, le constat et l'action à mener.
2. Supprimez le dossier `travail/`, après avoir vérifié que vos livrables
   sont complets. Il ne contient que des copies décompressées, qu'on peut
   toujours régénérer à partir des données brutes.

**Point de contrôle** : `ls projet1/resultats` affiche les livrables du
cahier des charges, et `du -sh projet1` donne quelques dizaines de Ko.

---

## Grille d'auto-évaluation

| Critère | ✔ |
|---|---|
| `run_sequencage/` n'a pas été modifié (`md5sum -c` donne toujours 23 OK et 1 FAILED) | |
| `controle_md5.txt` contient aussi l'avertissement de `md5sum` | |
| le fichier corrompu n'a **pas** été analysé, et il est signalé dans les conclusions | |
| `inventaire_run.tsv` a 24 lignes, est tabulé (`cat -A` montre des `^I`) et comporte un en-tête | |
| les nombres de reads sont cohérents avec le chapitre 05 (P07 : 290, P09 : 150) | |
| P09 et P11 sont identifiés **par des commandes**, pas à l'œil | |
| les chiffres de `conclusions.txt` sont calculés, pas recopiés | |
| le dossier `travail/` a été supprimé | |

---

## Pour aller plus loin

- **Comparer les conditions** : calculez le nombre moyen de reads R1 par
  condition, en excluant P09 et P11. La profondeur de séquençage est-elle
  équilibrée entre témoins et traités ? (Réponse : 305 reads en moyenne dans
  les deux groupes.)
- **Rejouer l'inventaire en une commande** : relancer les étapes 2 à 6 à la
  main serait fastidieux pour le prochain run. Au chapitre 12, vous
  transformerez ce projet en **script** réutilisable, et au projet 2 en
  véritable petit pipeline.
- **La vraie vie** : en pratique, cet inventaire est complété par un
  contrôle qualité dédié, avec FastQC et MultiQC (module 09 de la Partie II),
  qui calcule bien d'autres indicateurs (qualité par position, contenu en
  GC, duplication).

---

## Solution complète

> Ouvrez-la seulement après avoir essayé. Plusieurs solutions sont
> possibles : la vôtre est correcte si elle atteint tous les points de
> contrôle.

<details>
<summary>Afficher la solution</summary>

```bash
# Étape 0 — espace de travail
cd ~/formation_linux
mkdir -p projet1/{resultats,travail}

# Étape 1 — intégrité (md5sum -c depuis le dossier des fichiers)
cd run_sequencage/fastq
md5sum -c MD5SUMS.txt > ../../projet1/resultats/controle_md5.txt 2>&1
cd ~/formation_linux
grep -v ": OK$" projet1/resultats/controle_md5.txt

# Étape 2 — copies de travail, sans le fichier corrompu
cp run_sequencage/fastq/*.fastq.gz projet1/travail/
rm projet1/travail/P11_S11_L001_R2_001.fastq.gz
gunzip projet1/travail/*.fastq.gz
ls projet1/travail/*.fastq | wc -l                      # 23

# Étape 3 — reads par fichier
awk 'FNR % 4 == 2 { n[FILENAME]++ } END { for (f in n) print f, n[f] }' projet1/travail/*.fastq | sort

# Étape 4 — statistiques complètes
awk 'FNR % 4 == 2 {
         f = FILENAME
         n[f]++
         b[f] += length($0)
         if ($0 ~ /N/) avecN[f]++
         if ($0 ~ /AGATCGGAAGAGC/) adapt[f]++
     }
     END {
         for (f in n) {
             nom = f; sub(/.*\//, "", nom)
             split(nom, p, "_")
             printf "%s\t%s\t%d\t%d\t%.1f\t%.1f\n", p[1], p[4], n[f], b[f], 100 * avecN[f] / n[f], 100 * adapt[f] / n[f]
         }
     }' projet1/travail/*.fastq | sort > projet1/resultats/stats.tsv
wc -l projet1/resultats/stats.tsv                       # 23

# Étape 5 — en-tête, puis lignes complétées par la condition
printf 'echantillon\tcondition\tlecture\treads\tbases\tpct_N\tpct_adaptateur\n' > projet1/resultats/inventaire_run.tsv
awk 'BEGIN { FS = OFS = "\t" }
     NR == FNR { cond[$1] = $3; next }
     { print $1, cond[$1], $2, $3, $4, $5, $6 }' run_sequencage/echantillons.tsv projet1/resultats/stats.tsv >> projet1/resultats/inventaire_run.tsv
column -t projet1/resultats/inventaire_run.tsv

# Étape 6 — détection automatique des problèmes
awk -F '\t' 'NR > 1 && ($6 > 50 || $7 > 10)' projet1/resultats/inventaire_run.tsv
awk -F '\t' 'NR > 1 && $3 == "R1" { r1[$1] = $4 }
             NR > 1 && $3 == "R2" { r2[$1] = $4 }
             END { for (e in r1) {
                       if (!(e in r2)) print e, "R2 absent"
                       else if (r1[e] != r2[e]) print e, "R1 =", r1[e], "R2 =", r2[e]
                   } }' projet1/resultats/inventaire_run.tsv

# Étape 7 — conclusions et rangement
echo "Inventaire du run 2026-10-14_M07112_0058 ($(date +%Y-%m-%d))" > projet1/resultats/conclusions.txt
echo "Fichiers reçus : $(ls run_sequencage/fastq/*.fastq.gz | wc -l) ; intègres : $(grep -c ': OK$' projet1/resultats/controle_md5.txt)" >> projet1/resultats/conclusions.txt
echo "P11 R2 : somme MD5 incorrecte, archive gzip tronquée -> demander un nouvel envoi à la plateforme." >> projet1/resultats/conclusions.txt
echo "P09 : 95 % des reads contiennent des N, 14 % des adaptateurs, 2 fois moins de reads -> prélèvement défectueux (cf. run_info.txt), à exclure ou à re-séquencer." >> projet1/resultats/conclusions.txt
echo "Autres échantillons : 260 à 350 paires de reads, N < 25 %, adaptateurs < 6 % -> exploitables." >> projet1/resultats/conclusions.txt
cat projet1/resultats/conclusions.txt
rm -r projet1/travail
ls projet1/resultats
```

Le fichier de conclusions obtenu :

```text
Inventaire du run 2026-10-14_M07112_0058 (2026-11-24)
Fichiers reçus : 24 ; intègres : 23
P11 R2 : somme MD5 incorrecte, archive gzip tronquée -> demander un nouvel envoi à la plateforme.
P09 : 95 % des reads contiennent des N, 14 % des adaptateurs, 2 fois moins de reads -> prélèvement défectueux (cf. run_info.txt), à exclure ou à re-séquencer.
Autres échantillons : 260 à 350 paires de reads, N < 25 %, adaptateurs < 6 % -> exploitables.
```

`ls projet1/resultats` affiche aussi `stats.tsv`, le fichier intermédiaire
de l'étape 4. Il est léger, et on peut le garder ou le supprimer.

**Pourquoi c'est un bon inventaire** : chaque chiffre a été produit par une
commande que l'on peut relancer, et les données brutes n'ont jamais été
touchées. Les deux problèmes ont été détectés par des règles explicites
(seuils, cohérence R1/R2), et non par un coup d'œil. Ce sont les trois
principes de toute analyse reproductible.
</details>
