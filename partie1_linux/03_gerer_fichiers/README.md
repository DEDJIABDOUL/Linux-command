# Chapitre 03 — Gérer fichiers et dossiers sans rien perdre

> **Durée estimée** : 2 h
> **Prérequis** : [chapitre 02](../02_systeme_de_fichiers/README.md)
> **Chapitre suivant** : [04 — Lire et inspecter des fichiers](../04_lire_inspecter/README.md)

## Ce que vous saurez faire à la fin de ce chapitre

- Créer l'arborescence complète d'un projet en une commande (`mkdir -p`,
  accolades).
- Copier, déplacer, renommer et supprimer des fichiers et des dossiers
  (`cp`, `mv`, `rm`, `rmdir`), **sans écraser ni perdre de données par
  accident**.
- Désigner des dizaines de fichiers à la fois avec les **jokers**
  (`*`, `?`, `[ ]`).
- Créer des **liens symboliques** vers des données volumineuses au lieu
  de les copier (`ln -s`).
- Retrouver des fichiers dans une arborescence (`find`).

---

## 1. Pourquoi

La plateforme vient de livrer 24 fichiers FASTQ. Vous voulez les ranger
dans votre projet, mettre de côté ceux des témoins, et préparer des
dossiers pour les résultats. Avec la souris, ce sont des dizaines de
glisser-déposer. Ici, chaque opération tient en une ligne, quel que soit
le nombre de fichiers.

En contrepartie, la ligne de commande **ne demande pas confirmation** et
**n'a pas de corbeille**. Ce chapitre vous apprend donc autant les
commandes que les gestes de sécurité qui les accompagnent.

---

## 2. Une image pour comprendre : la paillasse sans filet

Travailler en ligne de commande, c'est manipuler des tubes sans étiquette
de confirmation : le geste est rapide et précis, mais un tube vidé dans
l'évier ne se récupère pas. Les bons manipulateurs ont donc des
**réflexes** :

| À la paillasse | Dans le terminal |
|---|---|
| on relit l'étiquette avant de vider un tube | on vérifie avec `ls` avant `rm` |
| on aliquote l'échantillon précieux au lieu de travailler sur l'original | on travaille sur des copies (le bac à sable) et on protège les données brutes |
| on demande « tu es sûr ? » avant une opération irréversible | on utilise `-i` (interactif) |

---

## 3. Créer des dossiers : `mkdir`

```bash
cd ~/formation_linux
mkdir mon_projet
ls -F
```

Un nouveau dossier `mon_projet/` apparaît. Essayez maintenant de créer
d'un coup un sous-dossier dans un sous-dossier qui n'existe pas encore :

```bash
mkdir mon_projet/data/raw
```

```text
mkdir: cannot create directory ‘mon_projet/data/raw’: No such file or directory
```

`mkdir` refuse, car le dossier intermédiaire `data` n'existe pas. L'option
`-p` (*parents*) crée tous les dossiers manquants du chemin, et ne signale
pas d'erreur s'ils existent déjà :

```bash
mkdir -p mon_projet/data/raw
```

### Les accolades : créer plusieurs dossiers d'un coup

Le shell **développe** les accolades avant d'exécuter la commande. `echo`
permet de voir ce développement :

```bash
echo mon_projet/{data,scripts,results}
```

```text
mon_projet/data mon_projet/scripts mon_projet/results
```

Combinées à `mkdir -p`, les accolades créent une arborescence entière en
une ligne :

```bash
mkdir -p mon_projet/{scripts,results,docs}
ls mon_projet
```

```text
data  docs  results  scripts
```

> **Attention : pas d'espace dans les accolades.** `{data, scripts}`
> n'est pas développé, et produit des noms inattendus.

### Créer un fichier vide : `touch`

```bash
touch mon_projet/notes.txt
ls -l mon_projet/notes.txt
```

```text
-rw-r--r-- 1 marie marie 0 Nov 24 23:17 mon_projet/notes.txt
```

Le fichier existe et pèse 0 octet. Sur un fichier déjà existant, `touch`
ne change pas le contenu : il met seulement à jour sa date de modification.

---

## 4. Copier : `cp`

```text
cp  SOURCE  DESTINATION
```

**Copier dans un dossier** (le nom est conservé) :

```bash
cp genome.fasta mon_projet/data/raw/
ls mon_projet/data/raw
```

```text
genome.fasta
```

**Copier sous un nouveau nom** :

```bash
cp genome.fasta copie.fasta
```

**Copier un dossier** : il faut l'option `-r` (*récursif* : le dossier et
tout ce qu'il contient).

```bash
cp formats mon_projet/
```

```text
cp: -r not specified; omitting directory 'formats'
```

```bash
cp -r formats mon_projet/
```

### Le piège : `cp` écrase sans prévenir

Si la destination existe déjà, `cp` la **remplace sans rien demander**.
L'option `-i` (*interactive*) demande une confirmation :

```bash
cp -i genome.fasta copie.fasta
```

```text
cp: overwrite 'copie.fasta'?
```

Répondez `n` (non) puis Entrée pour annuler, ou `y` (oui) pour écraser.

> Vous croiserez aussi `cp -n` (« ne jamais écraser »). Sur Ubuntu 24.04,
> il affiche l'avertissement `behavior of -n is non-portable` : préférez
> `-i`.

---

## 5. Déplacer et renommer : `mv`

`mv` (*move*) déplace un fichier. **Renommer, c'est déplacer dans le même
dossier sous un autre nom** : il n'existe pas de commande « rename »
distincte.

```bash
mv copie.fasta sauvegarde_genome.fasta
mv sauvegarde_genome.fasta mon_projet/
ls mon_projet
```

```text
data  docs  formats  notes.txt  results  sauvegarde_genome.fasta  scripts
```

Contrairement à `cp`, `mv` déplace les dossiers sans option particulière.

> **Attention** : comme `cp`, `mv` **écrase** une destination existante
> sans prévenir. Avec `mv -i`, il demande une confirmation
> (`mv: overwrite 'b.txt'?`).

---

## 6. Supprimer : `rm` et `rmdir`

> **Attention : `rm` est définitif.** Il n'y a pas de corbeille. Un
> fichier supprimé avec `rm` est perdu, sauf sauvegarde.

```bash
touch a_supprimer.txt
rm a_supprimer.txt
ls a_supprimer.txt
```

```text
ls: cannot access 'a_supprimer.txt': No such file or directory
```

Le message d'erreur confirme ici que la suppression a fonctionné.

### Supprimer un dossier

```bash
rm mon_projet/docs
```

```text
rm: cannot remove 'mon_projet/docs': Is a directory
```

Deux possibilités :

| Commande | Effet | Risque |
|---|---|---|
| `rmdir dossier` | supprime le dossier **seulement s'il est vide** | aucun : il refuse s'il reste quelque chose (`Directory not empty`) |
| `rm -r dossier` | supprime le dossier **et tout son contenu** | élevé : tout disparaît d'un coup |

```bash
rmdir mon_projet/docs
```

### Les gestes de sécurité

1. **Regardez avant de supprimer** : remplacez `rm` par `ls` avec les mêmes
   arguments, vérifiez la liste, puis remettez `rm`. Avec la flèche ↑,
   cela ne coûte que quelques touches.
2. **Utilisez `rm -i`** quand vous supprimez plusieurs fichiers : chaque
   suppression est confirmée.

   ```bash
   touch c.txt
   rm -i c.txt
   ```

   ```text
   rm: remove regular empty file 'c.txt'?
   ```

3. **Méfiez-vous de `rm -rf`**, que vous croiserez sur Internet. `-f`
   (*force*) supprime toute question et tout message d'erreur. **Ne
   l'utilisez jamais sur un chemin que vous n'avez pas vérifié**, et jamais
   précédé de `sudo`.
4. **Ne travaillez jamais sur vos seules données brutes.** Gardez
   l'original en lieu sûr (chapitre 08 : le rendre non modifiable).

---

## 7. Les jokers : désigner beaucoup de fichiers à la fois

### 7.1 Le principe

Un **joker** (*wildcard*) est un caractère spécial que le **shell**
remplace par la liste des noms de fichiers qui correspondent au motif,
avant d'exécuter la commande.

| Joker | Correspond à | Exemple | Désigne |
|---|---|---|---|
| `*` | n'importe quelle suite de caractères (même vide) | `*.fasta` | tous les fichiers finissant par `.fasta` |
| `?` | exactement un caractère | `sample_0?.fastq.gz` | `sample_01`, `sample_02`, `sample_03` |
| `[ ]` | un caractère parmi ceux listés | `P0[1-6]*` | les noms commençant par P01 à P06 |

`echo` permet de voir ce que le shell fabrique, **sans rien exécuter
d'autre** :

```bash
echo *.fasta
```

```text
exercice_sequences.fasta genome.fasta proteins.fasta transcripts.fasta
```

```bash
echo sample_0?.fastq.gz
```

```text
sample_01.fastq.gz sample_02.fastq.gz sample_03.fastq.gz
```

### 7.2 Sur un vrai run de séquençage

Les noms Illumina (chapitre 02, section 8) se prêtent parfaitement aux
jokers. Tous les fichiers R1 :

```bash
ls run_sequencage/fastq/*_R1_*
```

Les R1 des six témoins, P01 à P06 :

```bash
echo run_sequencage/fastq/P0[1-6]_*_R1_*
```

```text
run_sequencage/fastq/P01_S1_L001_R1_001.fastq.gz run_sequencage/fastq/P02_S2_L001_R1_001.fastq.gz run_sequencage/fastq/P03_S3_L001_R1_001.fastq.gz run_sequencage/fastq/P04_S4_L001_R1_001.fastq.gz run_sequencage/fastq/P05_S5_L001_R1_001.fastq.gz run_sequencage/fastq/P06_S6_L001_R1_001.fastq.gz
```

Les R2 des patients P10 à P12 :

```bash
ls run_sequencage/fastq/P1[0-2]*R2*
```

```text
run_sequencage/fastq/P10_S10_L001_R2_001.fastq.gz
run_sequencage/fastq/P11_S11_L001_R2_001.fastq.gz
run_sequencage/fastq/P12_S12_L001_R2_001.fastq.gz
```

### 7.3 Ce qu'il faut savoir sur les jokers

- **C'est le shell qui travaille, pas la commande.** `ls`, `cp` ou `rm` ne
  voient jamais l'étoile : ils reçoivent directement la liste des fichiers.
  C'est pourquoi les jokers fonctionnent avec **toutes** les commandes.
- **Si rien ne correspond, le motif est transmis tel quel** :

  ```bash
  ls *.xyz
  ```

  ```text
  ls: cannot access '*.xyz': No such file or directory
  ```

- **`*` ne désigne pas les fichiers cachés** : `echo run_sequencage/*` ne
  montre pas `.run_termine`.
- **Testez toujours un joker avec `echo` ou `ls` avant de l'utiliser avec
  `rm`.** `rm *` supprime tout le contenu du dossier courant. Avec une
  espace de trop, `rm * .fastq` (au lieu de `rm *.fastq`) supprime **tous**
  les fichiers.

---

## 8. Les liens symboliques : `ln -s`

### 8.1 Pourquoi

En analyse NGS, les fichiers bruts pèsent des dizaines de gigaoctets. Les
copier dans chaque projet gaspillerait le disque, et créerait des doublons
dont on ne saurait plus lequel est l'original. On crée plutôt un **lien
symbolique** : un petit fichier qui **pointe** vers l'original, comme un
raccourci Windows.

```text
ln -s  CIBLE  NOM_DU_LIEN
```

### 8.2 Démonstration

```bash
cd ~/formation_linux/mon_projet/data/raw
ln -s ../../../run_sequencage/fastq/P07_S7_L001_R1_001.fastq.gz P07_R1.fastq.gz
ls -l P07_R1.fastq.gz
```

```text
lrwxrwxrwx 1 marie marie 57 Nov 24 23:17 P07_R1.fastq.gz -> ../../../run_sequencage/fastq/P07_S7_L001_R1_001.fastq.gz
```

Le `l` en tête de ligne signale un lien, et la flèche `->` indique sa
cible. Les commandes qui lisent `P07_R1.fastq.gz` lisent en réalité
l'original.

Un lien peut aussi pointer vers un dossier entier, ici avec un chemin
absolu :

```bash
cd ~/formation_linux
ln -s ~/formation_linux/run_sequencage/fastq mon_projet/data/fastq_run
ls mon_projet/data/fastq_run
```

`mon_projet/data/fastq_run` affiche les 25 fichiers du run, sans qu'aucun
octet n'ait été copié.

### 8.3 Les pièges des liens

- **Le chemin relatif d'un lien part du dossier où se trouve le lien**, et
  non du dossier où vous êtes au moment de le créer. C'est pour cela qu'on
  s'est placé dans `data/raw` en 8.2. En cas de doute, utilisez un chemin
  absolu.
- **Un lien dont la cible disparaît est « cassé »** : il reste visible,
  mais il est inutilisable.

  ```bash
  ln -s fichier_qui_nexiste_pas lien_casse
  head lien_casse
  ```

  ```text
  head: cannot open 'lien_casse' for reading: No such file or directory
  ```

- **Supprimer le lien (`rm lien_casse`) ne touche pas la cible.** En
  revanche, **modifier le contenu** via le lien modifie l'original.

---

## 9. Retrouver des fichiers : `find`

`ls` montre un dossier. `find` **fouille une arborescence entière** :

```text
find  OÙ_CHERCHER  CRITÈRES
```

```bash
find run_sequencage -name "P07*"
```

```text
run_sequencage/fastq/P07_S7_L001_R1_001.fastq.gz
run_sequencage/fastq/P07_S7_L001_R2_001.fastq.gz
run_sequencage/archives/2025-03_run_test/P07_S7_L001_R1_001.fastq.gz
```

En une commande, `find` retrouve les trois fichiers P07, y compris le
fichier leurre de la chasse au trésor du chapitre 02.

| Critère | Signification | Exemple |
|---|---|---|
| `-name "motif"` | nom correspondant au motif (sensible à la casse) | `-name "*.sam"` |
| `-iname "motif"` | idem, sans tenir compte de la casse | `-iname "*lisez*"` |
| `-type f` / `-type d` | uniquement les fichiers / les dossiers | `find . -type d` |
| `-size +100k` | plus gros que 100 Ko (`M` pour Mo, `G` pour Go) | `-size +1G` |
| `-mmin -60` / `-mtime -7` | modifié il y a moins de 60 minutes / 7 jours | « qu'ai-je produit aujourd'hui ? » |

```bash
find . -type f -size +100k
```

```text
./sample_01.fastq.gz
./formats/alignements.sam
./sample_03.fastq.gz
./mon_projet/formats/alignements.sam
./reads.fastq
```

> `find` affiche les fichiers dans l'ordre où il les rencontre sur le
> disque, qui n'est pas alphabétique. L'ordre peut différer chez vous.

### Le piège : mettre le motif entre guillemets

```bash
find . -name *.txt
```

Si le dossier courant contient lui-même plusieurs fichiers `.txt`, le
**shell** remplace `*.txt` par leurs noms **avant** que `find` ne voie la
commande (section 7.3), et `find` reçoit des arguments qui n'ont plus de
sens :

```text
find: paths must precede expression: `notes2.txt'
find: possible unquoted pattern after predicate `-name'?
```

Avec des guillemets, `"*.txt"` est transmis intact à `find`, qui applique
lui-même le motif dans toute l'arborescence : **écrivez toujours
`-name "*.txt"`**.

---

## 10. Pièges fréquents

| Situation | Message | Solution |
|---|---|---|
| `mkdir a/b/c` alors que `a` n'existe pas | `cannot create directory … No such file or directory` | `mkdir -p` |
| copier un dossier sans `-r` | `-r not specified; omitting directory` | `cp -r` |
| `rm` sur un dossier | `Is a directory` | `rmdir` s'il est vide, sinon `rm -r` après vérification |
| `rmdir` sur un dossier non vide | `Directory not empty` | c'est une protection : vérifiez le contenu avec `ls` |
| joker sans correspondance | `cannot access '*.xyz'` | vérifiez le motif avec `echo` |
| `find -name` sans guillemets | `paths must precede expression` | `-name "motif"` |
| fichier écrasé par `cp` ou `mv` | aucun message ! | prévenir avec `-i` ; récupérer depuis une sauvegarde |

---

## 11. À vous de jouer

Commencez par `cd ~/formation_linux`. Si vous avez déjà fait les
démonstrations, supprimez d'abord le dossier de démonstration
(`rm -ri mon_projet`, en répondant `y` à chaque question), ou remettez le
bac à sable à neuf (`bash ~/Linux-command/setup.sh --reset`).

### Exercice 1 : l'arborescence d'un projet

*Objectif : `mkdir -p` et accolades.*
En **une seule commande**, créez l'arborescence suivante :

```text
projet_amr/
├── data/
│   ├── raw/
│   └── metadata/
├── scripts/
└── results/
    ├── qc/
    └── variants/
```

<details>
<summary>Corrigé</summary>

```bash
mkdir -p projet_amr/{data/{raw,metadata},scripts,results/{qc,variants}}
ls -R projet_amr
```

Les accolades peuvent s'imbriquer. Vérifiez toujours le résultat avec
`ls -R`.
</details>

### Exercice 2 : relier les données brutes sans les copier

*Objectif : `ln -s`.*
Dans `projet_amr/data/raw/`, créez un lien symbolique vers **le dossier**
`run_sequencage/fastq`, nommé `run_2026-10-14`. Vérifiez que
`ls projet_amr/data/raw/run_2026-10-14/` affiche bien les fichiers du run.

<details>
<summary>Corrigé</summary>

Avec un chemin absolu, sans souci de point de départ :

```bash
ln -s ~/formation_linux/run_sequencage/fastq projet_amr/data/raw/run_2026-10-14
ls projet_amr/data/raw/run_2026-10-14/
```

Avec un chemin relatif, celui-ci doit partir de `projet_amr/data/raw` (le
dossier du lien) : `ln -s ../../../run_sequencage/fastq projet_amr/data/raw/run_2026-10-14`.
</details>

### Exercice 3 : trier les échantillons avec des jokers

*Objectif : `[ ]` et `*`.*
Créez `projet_amr/data/temoins/` et `projet_amr/data/traites/`. Copiez-y
respectivement les fichiers FASTQ (R1 **et** R2) des témoins P01 à P06 et
des traités P07 à P12. Vérifiez qu'il y a 12 fichiers dans chaque dossier.

<details>
<summary>Indice</summary>

Les traités sont P07, P08, P09 (motif `P0[7-9]`) **et** P10, P11, P12
(motif `P1[0-2]`). Une commande peut recevoir plusieurs motifs.
</details>

<details>
<summary>Corrigé</summary>

```bash
mkdir -p projet_amr/data/{temoins,traites}
cp run_sequencage/fastq/P0[1-6]_*.fastq.gz projet_amr/data/temoins/
cp run_sequencage/fastq/P0[7-9]_*.fastq.gz run_sequencage/fastq/P1[0-2]_*.fastq.gz projet_amr/data/traites/
ls projet_amr/data/temoins projet_amr/data/traites
```

Comptez les fichiers à l'œil : il y en a 12 dans chaque dossier. Au
chapitre 05, `ls | wc -l` comptera à votre place.

Dans un vrai projet, on créerait plutôt des **liens** que des copies
(exercice 2) : les vrais fichiers sont bien plus volumineux.
</details>

### Exercice 4 : renommer pour la clarté

*Objectif : `mv`.*
Dans `projet_amr/data/temoins/`, renommez
`P01_S1_L001_R1_001.fastq.gz` en `P01_temoin_R1.fastq.gz`. Puis
déplacez-le dans `projet_amr/data/raw/`.

<details>
<summary>Corrigé</summary>

```bash
mv projet_amr/data/temoins/P01_S1_L001_R1_001.fastq.gz projet_amr/data/temoins/P01_temoin_R1.fastq.gz
mv projet_amr/data/temoins/P01_temoin_R1.fastq.gz projet_amr/data/raw/
```

On peut aussi faire les deux en une seule commande :
`mv ANCIEN_CHEMIN projet_amr/data/raw/P01_temoin_R1.fastq.gz`. Renommer
des dizaines de fichiers d'un coup demande une boucle (chapitre 12).
</details>

### Exercice 5 : faire le ménage en sécurité

*Objectif : `ls` avant `rm`, `rmdir`, `rm -i`.*
Supprimez tous les fichiers R2 du dossier `projet_amr/data/traites/`, en
vérifiant d'abord ce que le joker désigne. Supprimez ensuite le dossier
`projet_amr/results/variants/` avec la commande la plus sûre possible.

<details>
<summary>Corrigé</summary>

```bash
ls projet_amr/data/traites/*_R2_*
rm -i projet_amr/data/traites/*_R2_*
rmdir projet_amr/results/variants
```

`ls` montre les six fichiers visés, puis `rm -i` demande une confirmation
pour chacun. `rmdir` est le plus sûr pour un dossier : il refuserait si le
dossier n'était pas vide.
</details>

### Exercice 6 : `find` en enquête

*Objectif : combiner les critères de `find`.*
Depuis `~/formation_linux` : (1) listez tous les sous-dossiers du dossier
`run_sequencage` ; (2) retrouvez tous les fichiers dont le nom contient
`lisez`, quelle que soit la casse ; (3) trouvez tous les fichiers
`.fastq.gz` du bac à sable de plus de 100 Ko.

<details>
<summary>Corrigé</summary>

```bash
find run_sequencage -type d
find . -iname "*lisez*"
find . -name "*.fastq.gz" -size +100k
```

(2) trouve `run_sequencage/archives/2025-03_run_test/LISEZMOI.txt`.
(3) trouve `sample_01.fastq.gz` et `sample_03.fastq.gz` : les FASTQ du
run, autour de 30 Ko chacun, sont trop petits. Plusieurs critères écrits
à la suite doivent **tous** être vrais.
</details>

---

## 12. Défi : préparer la livraison pour un collègue

Un collègue analyse uniquement les **R1 des patients traités dont le
numéro est pair** (P08, P10, P12). Préparez un dossier
`livraison_collegue/` qui contient :

- un sous-dossier `fastq/` avec des **liens** (pas des copies) vers ces
  trois fichiers ;
- une copie de la feuille d'échantillons ;
- un fichier vide `LISEZMOI.txt`.

Vérifiez avec `ls -lR livraison_collegue` que les liens pointent vers des
fichiers qui existent.

<details>
<summary>Indice</summary>

`P[01][02468]` correspond aux noms où le 2ᵉ caractère est 0 ou 1 et le 3ᵉ
un chiffre pair. Mais il désigne aussi P02, P04 et P06, qui sont des
témoins. Il est plus sûr d'écrire les trois motifs explicitement, ou
d'utiliser les accolades : `P{08,10,12}`.
</details>

<details>
<summary>Corrigé</summary>

```bash
cd ~/formation_linux
mkdir -p livraison_collegue/fastq
ln -s ~/formation_linux/run_sequencage/fastq/P{08,10,12}_*_R1_001.fastq.gz livraison_collegue/fastq/
cp run_sequencage/echantillons.tsv livraison_collegue/
touch livraison_collegue/LISEZMOI.txt
ls -lR livraison_collegue
```

Avec plusieurs cibles, `ln -s` crée un lien par cible dans le dossier de
destination. Les cibles sont données en chemin absolu, donc les liens
fonctionnent quel que soit l'endroit d'où on les lit.

Leçon : quand un motif à joker devient compliqué, **énumérez** plutôt les
éléments. Un motif trop astucieux qui prend un fichier de trop est une
erreur silencieuse.
</details>

---

## L'essentiel

```text
mkdir -p a/{b,c}/d        créer une arborescence
touch fichier             créer un fichier vide
cp  -r  -i                copier (dossier : -r ; confirmer : -i)
mv  -i                    déplacer ou renommer
rm  -i   rm -r   rmdir    supprimer : DÉFINITIF, pas de corbeille
*   ?   [1-6]   {a,b}     jokers et accolades, développés par le shell
ln -s CIBLE LIEN          lien symbolique : pointer plutôt que copier
find . -name "*.sam" -type f -size +1G      chercher (guillemets !)
Avant rm : vérifier avec ls ou echo.  Jamais rm -rf sans vérifier.
```

### Auto-évaluation

- [ ] Je crée l'arborescence d'un projet en une commande.
- [ ] Je sais que `cp` et `mv` écrasent sans prévenir, et comment l'éviter.
- [ ] Je vérifie systématiquement un joker avant de l'utiliser avec `rm`.
- [ ] Je sélectionne un sous-ensemble d'échantillons avec `[ ]` ou `{ }`.
- [ ] Je crée un lien symbolique et je sais vérifier qu'il n'est pas cassé.
- [ ] Je retrouve un fichier dans une arborescence avec `find`.

## Documentation officielle

- `cp`, `mv`, `rm`, `mkdir`, `ln` (GNU Coreutils) : <https://www.gnu.org/software/coreutils/manual/coreutils.html>
- Jokers et accolades (manuel de Bash, *Filename Expansion* et *Brace Expansion*) : <https://www.gnu.org/software/bash/manual/html_node/Shell-Expansions.html>
- `find` (GNU Findutils) : <https://www.gnu.org/software/findutils/manual/html_mono/find.html>

**Prochaine étape** : [chapitre 04 — Lire et inspecter des fichiers](../04_lire_inspecter/README.md).
