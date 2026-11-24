# Chapitre 02 — Le système de fichiers : se repérer et se déplacer

> **Durée estimée** : 1 h 30
> **Prérequis** : [chapitre 01](../01_premier_contact/README.md)
> **Chapitre suivant** : [03 — Gérer fichiers et dossiers](../03_gerer_fichiers/README.md)

## Ce que vous saurez faire à la fin de ce chapitre

- Savoir à tout moment **où vous êtes** dans le système (`pwd`).
- Explorer le contenu d'un dossier et lire les informations détaillées
  d'un fichier (`ls` et ses options).
- Vous déplacer d'un dossier à l'autre (`cd`).
- Désigner n'importe quel fichier par un **chemin absolu** ou un
  **chemin relatif**, et savoir lequel choisir.
- Nommer vos fichiers de façon à éviter les erreurs.

---

## 1. Pourquoi ce chapitre est décisif

Le message d'erreur le plus fréquent en bioinformatique est
`No such file or directory`. Dans la grande majorité des cas, le fichier
existe bel et bien, mais **pas là où la commande le cherche**.

Sur un serveur de calcul, il n'y a pas d'explorateur de fichiers sur
lequel cliquer. Pour lancer un aligneur, vous devez lui indiquer
exactement où se trouvent le génome de référence, les reads et le dossier
de sortie. Savoir écrire un **chemin** sans hésiter est donc la compétence
dont dépendent toutes les autres.

---

## 2. Une image pour comprendre : le campus et ses adresses

Imaginez un **campus universitaire**. L'entrée principale mène à des
bâtiments ; chaque bâtiment a des étages, et chaque étage a des salles.
Pour indiquer une salle à quelqu'un, vous avez deux façons de faire :

- l'**adresse complète**, qui fonctionne d'où que l'on parte : « Entrée
  principale → bâtiment Biologie → 2ᵉ étage → salle 204 » ;
- l'**indication relative**, qui dépend de l'endroit où l'on se trouve :
  « Depuis ici, montez d'un étage, c'est la 2ᵉ porte. »

Le système de fichiers Linux fonctionne de la même façon :

| Sur le campus | Sous Linux |
|---|---|
| l'entrée principale | la **racine** `/` |
| bâtiments, étages, salles | des **dossiers** (on dit aussi *répertoires*) imbriqués |
| un document posé dans une salle | un **fichier** |
| l'adresse complète | le **chemin absolu** : `/home/marie/formation_linux/genome.fasta` |
| l'indication relative | le **chemin relatif** : `formation_linux/genome.fasta`, depuis `/home/marie` |

> **Limite de l'image** : sur un campus, vous pouvez voir la salle voisine
> par la fenêtre. Dans un terminal, vous ne « voyez » rien tant que vous
> ne le demandez pas. Il faut prendre l'habitude de regarder où vous
> êtes (`pwd`) et ce qui vous entoure (`ls`).

---

## 3. Une seule arborescence, qui part de la racine

Sous Windows, chaque disque a sa lettre (`C:`, `D:`). Sous Linux, **tout**
part d'un point unique, la racine, notée `/`. Les disques, les clés USB et
même vos fichiers Windows (sous WSL) sont rattachés quelque part dans
cette arborescence unique.

```bash
ls /
```

Sortie (la liste exacte varie selon les systèmes) :

```text
bin                etc   lib.usr-is-merged  mnt   run                 srv  var
bin.usr-is-merged  home  lib64              opt   sbin                sys
boot               init  lost+found         proc  sbin.usr-is-merged  tmp
dev                lib   media              root  snap                usr
```

Vous n'avez pas à tout retenir. Quelques dossiers suffisent :

| Dossier | Contenu | Vous y écrirez ? |
|---|---|---|
| `/home` | les dossiers personnels des utilisateurs (`/home/marie`, `/home/paul`…) | **oui**, dans le vôtre |
| `/usr/bin` | les programmes (`/usr/bin/head`, vu au chapitre 01 avec `type`) | non |
| `/etc` | la configuration du système | non |
| `/tmp` | des fichiers temporaires, effacés régulièrement | rarement |
| `/mnt` | les disques rattachés. Sous WSL, `/mnt/c` est votre disque `C:` de Windows | à éviter (chapitre 00) |
| `/root` | le dossier personnel de l'administrateur | non |

> **Attention à la barre** : Linux sépare les dossiers par une barre
> oblique `/`, alors que Windows utilise une barre inverse `\`.
> `C:\Users\Marie` s'écrit `/mnt/c/Users/Marie` sous WSL.

---

## 4. Où suis-je ? `pwd`

```bash
cd ~/formation_linux
pwd
```

Sortie :

```text
/home/marie/formation_linux
```

`pwd` (*print working directory*) affiche le **dossier courant** :
l'endroit où vous vous trouvez. Ce chemin se lit de gauche à droite, en
partant de la racine : racine `/`, puis dossier `home`, puis dossier
`marie`, puis dossier `formation_linux`.

Le dossier courant est l'endroit où les commandes cherchent les fichiers
quand vous ne précisez pas de chemin. C'est pour cela que, au chapitre 01,
`head genome.fasta` trouvait le fichier : vous étiez dans le dossier qui
le contient.

> **Bon réflexe** : en cas de doute, ou après une erreur
> `No such file or directory`, tapez `pwd`.

---

## 5. Qu'y a-t-il ici ? `ls`

### 5.1 La liste simple

```bash
ls
```

Sortie :

```text
annotations.tsv           pieges          sample_01.fastq.gz
exercice_sequences.fasta  proteins.fasta  sample_02.fastq.gz
formats                   reads.fastq     sample_03.fastq.gz
genome.fasta              run_sequencage  transcripts.fasta
```

`ls` (*list*) affiche le contenu du dossier courant, trié par ordre
alphabétique et en colonnes adaptées à la largeur de la fenêtre. Selon les
réglages du terminal, les dossiers peuvent apparaître dans une autre
couleur.

Pour distinguer à coup sûr les dossiers des fichiers, ajoutez `-F`, qui
place un `/` à la fin des noms de dossiers :

```bash
ls -F
```

```text
annotations.tsv           pieges/         sample_01.fastq.gz
exercice_sequences.fasta  proteins.fasta  sample_02.fastq.gz
formats/                  reads.fastq     sample_03.fastq.gz
genome.fasta              run_sequencage/ transcripts.fasta
```

Vous pouvez aussi lister un autre dossier **sans vous y rendre**, en
donnant son nom en argument :

```bash
ls run_sequencage
```

```text
archives  echantillons.tsv  fastq  rapports
```

### 5.2 La liste détaillée : `ls -l`

```bash
ls -l
```

Sortie (début ; les dates seront celles de votre installation) :

```text
total 540
-rw-r--r-- 1 marie marie   3410 Nov 24 23:17 annotations.tsv
-rw-r--r-- 1 marie marie  25447 Nov 24 23:17 exercice_sequences.fasta
drwxr-xr-x 2 marie marie   4096 Nov 24 23:17 formats
-rw-r--r-- 1 marie marie  25447 Nov 24 23:17 genome.fasta
```

Chaque ligne décrit un élément :

```text
-rw-r--r--  1  marie  marie  25447  Nov 24 23:17  genome.fasta
│└───┬────┘     │      │      │         │            │
│    │          │      │      │         │            └ nom
│    │          │      │      │         └ date de dernière modification
│    │          │      │      └ taille en octets
│    │          │      └ groupe propriétaire
│    │          └ utilisateur propriétaire
│    └ permissions (qui peut lire, modifier, exécuter : chapitre 08)
└ type : - fichier, d dossier (directory), l lien (chapitre 03)
```

Les tailles en octets sont peu lisibles. Ajoutez `-h` (*human readable*) :

```bash
ls -lh
```

```text
total 540K
-rw-r--r-- 1 marie marie 3.4K Nov 24 23:17 annotations.tsv
-rw-r--r-- 1 marie marie  25K Nov 24 23:17 exercice_sequences.fasta
drwxr-xr-x 2 marie marie 4.0K Nov 24 23:17 formats
-rw-r--r-- 1 marie marie  25K Nov 24 23:17 genome.fasta
```

`K` signifie kilo-octets, `M` méga-octets, `G` giga-octets. Un fichier
FASTQ brut de séquençage humain pèse couramment plusieurs dizaines de `G`.

> La taille affichée pour un **dossier** (`4.0K`) n'est pas la taille de
> son contenu : c'est la place qu'occupe sa « table des matières ». Pour
> connaître le poids réel d'un dossier, il faudra `du -sh` (chapitre 04).

### 5.3 Les fichiers cachés : `ls -a`

```bash
ls -a run_sequencage
```

```text
.  ..  .run_termine  archives  echantillons.tsv  fastq  rapports
```

Trois nouveaux éléments apparaissent :

- `.run_termine` est un **fichier caché**. Sous Linux, tout nom qui
  commence par un point est masqué par défaut. Ce n'est pas une protection,
  c'est seulement une convention pour ne pas encombrer l'affichage. Les
  fichiers de configuration sont souvent cachés (par exemple
  `~/.bashrc`, chapitre 10).
- `.` désigne **le dossier lui-même**.
- `..` désigne **le dossier parent**, celui qui le contient.

Ces deux derniers existent dans chaque dossier, et ils vont vous servir
tout de suite.

### 5.4 Trier l'affichage

| Option | Effet | Usage typique |
|---|---|---|
| `-t` | du plus récent au plus ancien | « quel est le dernier fichier produit ? » |
| `-S` | du plus gros au plus petit | « qu'est-ce qui remplit mon disque ? » |
| `-r` | inverse l'ordre de tri | combiné aux précédentes |

Les options se combinent :

```bash
ls -lhS formats
```

```text
total 240K
-rw-r--r-- 1 marie marie 209K Nov 24 23:17 alignements.sam
-rw-r--r-- 1 marie marie 8.5K Nov 24 23:17 reference.fasta
-rw-r--r-- 1 marie marie 2.1K Nov 24 23:17 annotation.gff3
-rw-r--r-- 1 marie marie 2.1K Nov 24 23:17 annotation.gtf
-rw-r--r-- 1 marie marie 1.2K Nov 24 23:17 variants.vcf
-rw-r--r-- 1 marie marie  167 Nov 24 23:17 genes.bed
```

Le fichier d'alignements est de loin le plus volumineux. C'est typique : en
analyse NGS, ce sont les reads et leurs alignements qui occupent le disque.

---

## 6. Se déplacer : `cd`

### 6.1 Démonstration

`cd` (*change directory*) change le dossier courant. Suivez cette séquence
en tapant `pwd` après chaque `cd`. **Avant chaque commande, essayez de
prédire le résultat de `pwd`.**

```bash
cd ~/formation_linux
cd run_sequencage
pwd
```

```text
/home/marie/formation_linux/run_sequencage
```

```bash
cd fastq
pwd
```

```text
/home/marie/formation_linux/run_sequencage/fastq
```

```bash
cd ..
pwd
```

```text
/home/marie/formation_linux/run_sequencage
```

`..` vous a fait remonter d'un niveau. On peut remonter puis redescendre
en une seule fois :

```bash
cd ../formats
pwd
```

```text
/home/marie/formation_linux/formats
```

### 6.2 Les raccourcis de `cd`

| Commande | Destination |
|---|---|
| `cd dossier` | le sous-dossier `dossier` du dossier courant |
| `cd ..` | le dossier parent |
| `cd ../..` | deux niveaux au-dessus |
| `cd ~` ou simplement `cd` | votre dossier personnel (`/home/marie`) |
| `cd ~/formation_linux` | le bac à sable, d'où que vous partiez |
| `cd -` | le dossier où vous étiez juste avant (pratique pour faire des allers-retours) |
| `cd /` | la racine |

`cd` ne produit aucun message quand il réussit (voir le chapitre 01). C'est
l'invite qui vous montre où vous êtes : `marie@PC-LABO:~/formation_linux/formats$`.

### 6.3 Plan du bac à sable

La commande `tree`, qui dessine une arborescence, n'est pas installée par
défaut. Voici le plan de votre bac à sable (simplifié) :

```text
/home/marie/                         ← votre dossier personnel, alias ~
└── formation_linux/                 ← le bac à sable
    ├── genome.fasta, reads.fastq, … ← fichiers d'exercice
    ├── formats/                     ← formats biologiques (chapitre 16)
    ├── pieges/                      ← fichiers problématiques
    └── run_sequencage/              ← un run de séquençage simulé
        ├── .run_termine             ← fichier caché
        ├── echantillons.tsv         ← la feuille d'échantillons
        ├── fastq/                   ← 24 fichiers de reads + MD5SUMS.txt
        ├── rapports/
        │   └── run_info.txt
        └── archives/
            └── 2025-03_run_test/    ← un ancien run de test
```

> **Pour aller plus loin** : `ls -R dossier` liste un dossier et tous ses
> sous-dossiers, récursivement. Vous pouvez aussi installer `tree`
> (`sudo apt install tree`) ; ce n'est pas nécessaire pour le cours.

---

## 7. Chemins absolus et chemins relatifs

### 7.1 La différence

| | Chemin **absolu** | Chemin **relatif** |
|---|---|---|
| Commence par | `/` (ou `~`, qui le remplace) | n'importe quoi d'autre |
| Part de | la racine | le dossier courant |
| Exemple | `/home/marie/formation_linux/formats/genes.bed` | `formats/genes.bed` (depuis `~/formation_linux`) |
| Fonctionne | depuis n'importe où | seulement depuis le bon dossier |
| Avantage | sans ambiguïté | court |

### 7.2 On peut désigner un fichier sans s'y déplacer

**Toutes** les commandes acceptent des chemins, pas seulement `cd`. Depuis
le bac à sable :

```bash
cd ~/formation_linux
head -n 2 run_sequencage/echantillons.tsv
```

```text
sample_id	patient	condition	replicat	fichier_R1	fichier_R2
P01	P01	temoin	1	P01_S1_L001_R1_001.fastq.gz	P01_S1_L001_R2_001.fastq.gz
```

Et depuis un dossier profond, en remontant avec `..` :

```bash
cd ~/formation_linux/run_sequencage/fastq
head -n 3 ../../formats/genes.bed
```

```text
chrA	150	1050	gyrA	0	+
chrA	1170	1920	recA	0	-
chrA	2120	3320	rpoB	0	+
```

Lecture de `../../formats/genes.bed` : remonter à `run_sequencage` (`..`),
remonter à `formation_linux` (`..`), entrer dans `formats`, puis prendre
`genes.bed`.

> **Bon réflexe : la touche Tab complète aussi les chemins**, un dossier à
> la fois. Tapez `head run_s`, Tab, puis `ec`, Tab : vous obtenez
> `head run_sequencage/echantillons.tsv` sans faute de frappe. Si Tab ne
> complète pas, le chemin est faux à cet endroit précis.

### 7.3 Lequel choisir ?

- Au terminal, pour aller vite : le **relatif**.
- Dans un script, une note de protocole ou un fichier de configuration
  d'outil : l'**absolu**, ou un chemin relatif à un dossier de projet bien
  défini. Une commande qui ne fonctionne que si l'on se trouve au bon
  endroit est une source classique de pipelines « qui marchaient hier ».

---

## 8. Bien nommer ses fichiers

Linux accepte presque n'importe quel nom, mais certains noms vous
compliqueront la vie.

| Règle | Exemple à éviter | Exemple conseillé | Pourquoi |
|---|---|---|---|
| Pas d'espace | `mes resultats.txt` | `mes_resultats.txt` | le shell coupe aux espaces (chapitre 01, exercice 5) |
| Pas d'accent ni de caractère spécial (`é`, `(`, `&`, `'`, `*`) | `génome (v2).fasta` | `genome_v2.fasta` | certains caractères ont un sens pour le shell |
| Une casse cohérente | `Sample1.FASTQ`, `sample1.fastq` | `sample1.fastq` | ce sont deux fichiers différents |
| Les dates au format AAAA-MM-JJ | `14-10-26_run` | `2026-10-14_run` | l'ordre alphabétique devient l'ordre chronologique |
| Une extension qui dit le format | `donnees` | `donnees.tsv` | pour les humains (Linux ne regarde pas les extensions, chapitre 04) |

### Lire un nom de fichier Illumina

Les séquenceurs Illumina nomment leurs fichiers selon une convention que
vous croiserez partout :

```text
P07_S7_L001_R1_001.fastq.gz
│   │  │    │  │   └ format : FASTQ compressé avec gzip
│   │  │    │  └ numéro de morceau (toujours 001 aujourd'hui)
│   │  │    └ lecture : R1 = brin lu en premier, R2 = son partenaire (paired-end)
│   │  └ lane (piste) de la flow cell : L001
│   └ numéro de l'échantillon dans la feuille de run : S7
└ nom de l'échantillon : P07
```

Chaque échantillon séquencé en **paired-end** produit donc **deux**
fichiers, R1 et R2, qui vont toujours ensemble.

---

## 9. En bioinformatique

Sur un serveur de calcul partagé, les dossiers suivent souvent un schéma
de ce type (les noms exacts dépendent de chaque centre) :

```text
/home/marie          petit espace personnel, sauvegardé : scripts, configuration
/scratch/marie       grand espace rapide, NON sauvegardé, purgé : calculs en cours
/data/projet_arn     données partagées de l'équipe
```

Votre premier réflexe en arrivant sur un serveur sera donc : `pwd`, `ls`,
puis lire la documentation du centre pour savoir **où** stocker quoi.

---

## 10. Pièges fréquents

| Ce que vous tapez | Message | Cause | Solution |
|---|---|---|---|
| `cd genome.fasta` | `bash: cd: genome.fasta: Not a directory` | on ne peut pas « entrer » dans un fichier | `cd` n'accepte que des dossiers ; pour lire le fichier, utilisez `head` |
| `cd fastq` depuis `~/formation_linux` | `bash: cd: fastq: No such file or directory` | `fastq` est dans `run_sequencage`, pas ici | `pwd`, puis `cd run_sequencage/fastq` |
| `head formats/genes.bed` depuis `~` | `No such file or directory` | le chemin relatif part du mauvais dossier | `head formation_linux/formats/genes.bed`, ou le chemin absolu |
| `cd C:\Users\Marie` (sous WSL) | `No such file or directory` | chemin Windows | `cd /mnt/c/Users/Marie` |
| `ls` ne montre pas un fichier que vous savez présent | — | c'est un fichier caché (commence par un point) | `ls -a` |

**Perdu ?** Tapez `cd` puis Entrée : vous revenez dans votre dossier
personnel, d'où vous pouvez repartir (`cd formation_linux`).

---

## 11. À vous de jouer

Commencez chaque exercice par `cd ~/formation_linux`.

### Exercice 1 : lire un chemin

*Objectif : décomposer un chemin absolu.*
Dans le chemin `/home/marie/formation_linux/run_sequencage/rapports/run_info.txt`,
combien de dossiers faut-il traverser depuis la racine pour atteindre le
fichier ? Quel est le dossier parent de `run_info.txt` ?

<details>
<summary>Corrigé</summary>

Cinq dossiers : `home`, `marie`, `formation_linux`, `run_sequencage` et
`rapports`. Le parent de `run_info.txt` est `rapports`, dont le chemin
absolu est `/home/marie/formation_linux/run_sequencage/rapports`.
</details>

### Exercice 2 : explorer un run de séquençage

*Objectif : utiliser `ls` et ses options pour découvrir un dossier inconnu.*

1. Combien de fichiers contient `run_sequencage/fastq` ?
2. Lequel est le plus volumineux ? Le plus petit ?
3. Le dossier `run_sequencage` contient un fichier caché : affichez son
   contenu. Que vous apprend-il ?

<details>
<summary>Corrigé</summary>

```bash
ls run_sequencage/fastq
ls -lhS run_sequencage/fastq
ls -a run_sequencage
head run_sequencage/.run_termine
```

1. 25 fichiers : 24 fichiers FASTQ compressés (12 échantillons × R1/R2) et
   `MD5SUMS.txt`. Au chapitre 05, vous apprendrez à faire compter `ls`
   à votre place.
2. Avec `ls -lhS`, le plus gros fichier apparaît en premier
   (`P03_S3_L001_R1_001.fastq.gz`, 32K), le plus petit en dernier
   (`MD5SUMS.txt`). Juste avant lui, trois fichiers FASTQ sont nettement
   plus petits que les autres (15 à 17K) : les deux de P09, et
   `P11_S11_L001_R2_001.fastq.gz`.
   - Pour P09, R1 et R2 sont petits **tous les deux** : cet échantillon
     contient simplement moins de reads (le rapport du run en donne la
     raison).
   - Pour P11, **seul R2 est petit**, alors que son partenaire R1 pèse
     28K. C'est suspect : R1 et R2 contiennent le même nombre de reads et
     devraient avoir des tailles proches. Vous découvrirez ce qui lui est
     arrivé au chapitre 04.
   Gardez ces observations en tête : elles serviront au projet 1.
3. ```text
   Transfert terminé le 2026-10-15 à 07:42
   ```
   C'est un « fichier témoin » : certains systèmes de livraison en créent
   un pour signaler que le transfert des données est complet.
</details>

### Exercice 3 : absolu ou relatif ?

*Objectif : écrire les deux types de chemins.*
Écrivez le chemin du fichier R2 de l'échantillon P07 :

1. en chemin absolu ;
2. en chemin relatif depuis `~/formation_linux` ;
3. en chemin relatif depuis `~/formation_linux/formats`.

Vérifiez chaque réponse avec `ls -l CHEMIN`, depuis le bon dossier.

<details>
<summary>Corrigé</summary>

1. `/home/marie/formation_linux/run_sequencage/fastq/P07_S7_L001_R2_001.fastq.gz`
   (avec votre nom d'utilisateur ; `~/formation_linux/run_sequencage/fastq/P07_S7_L001_R2_001.fastq.gz`
   est équivalent).
2. `run_sequencage/fastq/P07_S7_L001_R2_001.fastq.gz`
3. `../run_sequencage/fastq/P07_S7_L001_R2_001.fastq.gz`
</details>

### Exercice 4 : la chasse au trésor

*Objectif : explorer une arborescence avec méthode.*
Votre encadrante vous écrit : « Peux-tu m'envoyer le chemin exact du
fichier R1 du patient P07 ? Attention, ne te trompe pas de run. »

Il existe **deux** fichiers nommés `P07_S7_L001_R1_001.fastq.gz` dans le
bac à sable. Trouvez-les, déterminez lequel est le bon, justifiez votre
choix, et donnez son chemin absolu.

<details>
<summary>Indice</summary>

Explorez `run_sequencage/archives` avec `ls -R`, puis lisez les fichiers
texte que vous y trouvez.
</details>

<details>
<summary>Corrigé</summary>

```bash
ls -R run_sequencage/archives
head run_sequencage/archives/2025-03_run_test/LISEZMOI.txt
head run_sequencage/rapports/run_info.txt
```

Le premier fichier se trouve dans `run_sequencage/fastq/`, le second dans
`run_sequencage/archives/2025-03_run_test/`. Le `LISEZMOI.txt` de ce
dernier dossier indique : `Run de test de mars 2025 : NE PAS utiliser pour
l'analyse.` Le bon fichier est donc :

```text
/home/marie/formation_linux/run_sequencage/fastq/P07_S7_L001_R1_001.fastq.gz
```

Leçon : **un nom de fichier ne suffit pas, c'est le chemin complet qui
identifie une donnée.** Lisez toujours les fichiers d'information (`README`,
`LISEZMOI`, rapports) qui accompagnent des données.
</details>

### Exercice 5 : naviguer sans se perdre

*Objectif : utiliser `..`, `-` et `~`.*
Depuis `~/formation_linux/run_sequencage/fastq`, rendez-vous dans
`~/formation_linux/formats` **en une seule commande `cd` relative**.
Revenez ensuite dans `fastq` avec la commande la plus courte possible,
puis retournez dans votre dossier personnel.

<details>
<summary>Corrigé</summary>

```bash
cd ~/formation_linux/run_sequencage/fastq
cd ../../formats
cd -
cd
```

`cd -` affiche le dossier où il vous ramène (`/home/marie/formation_linux/run_sequencage/fastq`),
et `cd` seul ramène au dossier personnel.
</details>

### Exercice 6 : renommer « pour de faux »

*Objectif : appliquer les règles de nommage.*
Proposez un meilleur nom pour chacun de ces fichiers :
`Résultats finaux (V2).xlsx`, `alignement patient 3.bam`,
`12-03-2026 run.txt`.

<details>
<summary>Corrigé</summary>

Par exemple : `resultats_finaux_v2.xlsx`, `alignement_patient03.bam` (le
zéro permet un tri correct de `patient03` à `patient12`), et
`2026-03-12_run.txt`. Vous apprendrez à renommer réellement des fichiers au
chapitre 03 (`mv`).
</details>

---

## 12. Défi

Sans jamais utiliser `cd`, et en restant dans votre dossier personnel
(`cd` puis Entrée pour y aller) :

1. affichez la première ligne de `genes.bed` **et** celle de
   `echantillons.tsv` en **une seule** commande ;
2. listez, du plus gros au plus petit et avec des tailles lisibles, le
   contenu du dossier `formats` ;
3. affichez le dossier parent de votre dossier personnel, et expliquez ce
   que vous y voyez.

<details>
<summary>Corrigé</summary>

```bash
head -n 1 formation_linux/formats/genes.bed formation_linux/run_sequencage/echantillons.tsv
ls -lhS formation_linux/formats
ls ..
```

Depuis `/home/marie`, `..` désigne `/home`. Vous y voyez votre propre
dossier (`marie`), et sur une machine partagée, ceux des autres
utilisateurs : sur un serveur, c'est là que vivent les dossiers de tous
vos collègues.
</details>

---

## L'essentiel

```text
/                      la racine : tout part d'ici
~                      votre dossier personnel (/home/marie)
.   ..                 le dossier courant / le dossier parent
pwd                    où suis-je ?
ls   -l -h -a -F -t -S  qu'y a-t-il ici ? (détails, tailles, cachés, types, tri)
cd chemin    cd ..    cd    cd -    se déplacer
Chemin absolu : commence par / (ou ~), fonctionne depuis partout
Chemin relatif : part du dossier courant
Noms de fichiers : sans espace, sans accent, dates en AAAA-MM-JJ
```

### Auto-évaluation

- [ ] Je sais à tout moment dans quel dossier je me trouve.
- [ ] Je lis chaque colonne d'un `ls -l`.
- [ ] J'écris le chemin absolu et le chemin relatif d'un même fichier.
- [ ] J'utilise `..` pour désigner un fichier situé ailleurs, sans m'y déplacer.
- [ ] Je sais retrouver un fichier caché.
- [ ] Je décode un nom de fichier Illumina.

## Documentation officielle

- `ls` (GNU Coreutils) : <https://www.gnu.org/software/coreutils/manual/html_node/ls-invocation.html>
- `cd` et `pwd` (manuel de Bash) : <https://www.gnu.org/software/bash/manual/html_node/Bourne-Shell-Builtins.html>
- Hiérarchie standard des dossiers Linux (FHS) : <https://refspecs.linuxfoundation.org/FHS_3.0/fhs/index.html>

**Prochaine étape** : [chapitre 03 — Gérer fichiers et dossiers](../03_gerer_fichiers/README.md).
