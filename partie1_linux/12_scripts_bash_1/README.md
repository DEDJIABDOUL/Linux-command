# Chapitre 12 — Scripts Bash (I) : automatiser un traitement sur tous vos échantillons

> **Durée estimée** : 3 h
> **Prérequis** : [chapitre 11](../11_installer_logiciels/README.md) (et la notion de variable du [chapitre 10](../10_environnement_shell/README.md))
> **Chapitre suivant** : [13 — Scripts Bash (II)](../13_scripts_bash_2/README.md)

## Ce que vous saurez faire à la fin de ce chapitre

- Écrire un script Bash dans un fichier, le commenter et l'exécuter.
- Lui passer des **arguments** (`$1`, `$#`, `$@`).
- Prendre des décisions avec **`if`** : le fichier existe-t-il ? le nombre
  de reads est-il suffisant ?
- Répéter un traitement avec **`for`** sur tous les fichiers d'un run, et
  avec **`while read`** sur chaque ligne d'une feuille d'échantillons.
- Produire un tableau de résultats à partir d'une boucle.

---

## 1. Pourquoi

Au projet 1, vous avez tapé une à une une vingtaine de commandes. Le mois
prochain, un nouveau run arrive : faudra-t-il tout retaper ? Et si un
collègue vous demande « comment as-tu obtenu ces chiffres ? »

Un **script** est un fichier qui contient des commandes, exécutées dans
l'ordre comme si vous les tapiez. Il apporte trois choses :

1. **Le temps** : 12 échantillons ou 1 200, c'est la même commande.
2. **L'exactitude** : la même opération est appliquée de façon identique à
   chaque fichier, sans faute de frappe ni oubli.
3. **La traçabilité** : le script **est** le protocole. On le relit, on le
   partage, on le versionne (chapitre 15), on le rejoue.

---

## 2. Une image pour comprendre : le protocole écrit

Un script, c'est un **protocole de manip** écrit pour un technicien qui
suit les instructions à la lettre :

| Protocole de labo | Script Bash |
|---|---|
| « Pour chaque tube du portoir… » | une boucle `for` |
| « Si la DO est inférieure à 0,1, noter ALERTE » | une condition `if` |
| « Échantillon : ___ » à compléter | un argument `$1` |
| les annotations en marge | les commentaires `#` |
| le protocole recopié dans le cahier de manip | le fichier script versionné |

---

## 3. Votre premier script

### 3.1 Écrire, exécuter

Créez un dossier pour vos scripts, puis le fichier avec nano (chapitre 10) :

```bash
cd ~/formation_linux
mkdir -p scripts
nano scripts/premier.sh
```

Tapez ce contenu, puis enregistrez (Ctrl+O, Entrée) et quittez (Ctrl+X) :

```bash
#!/bin/bash
# Mon premier script : quelques informations sur le run
echo "Analyse lancée par $USER le $(date +%Y-%m-%d)"
echo "Fichiers FASTQ dans le run : $(ls run_sequencage/fastq/*.fastq.gz | wc -l)"
```

```bash
bash scripts/premier.sh
```

```text
Analyse lancée par marie le 2026-11-25
Fichiers FASTQ dans le run : 24
```

- **`#!/bin/bash`**, la première ligne, s'appelle le *shebang*. Elle indique
  quel programme doit exécuter le fichier quand on le lance directement
  (`./scripts/premier.sh`, après `chmod u+x`, chapitre 08). On croise aussi
  `#!/usr/bin/env bash`, qui cherche `bash` dans le `PATH`.
- Les lignes qui commencent par **`#`** sont des **commentaires** : bash les
  ignore. Commentez le *pourquoi*, pas seulement le *quoi*.
- L'extension `.sh` est une convention pour les humains.

### 3.2 Le piège du dossier courant

```bash
chmod u+x scripts/compte_run.sh     # (script de la section 6)
cd scripts
./compte_run.sh
```

```text
gzip: run_sequencage/fastq/*_R1_001.fastq.gz: No such file or directory
echantillon	reads_R1
*	0
```

Les chemins relatifs d'un script partent du **dossier où vous êtes au
moment de le lancer**, pas du dossier où se trouve le script. Lancé depuis
`scripts/`, `run_sequencage/fastq` n'existe pas. Deux solutions :
**toujours lancer le script depuis le dossier du projet**, ou, mieux,
**passer les chemins en arguments** (section 4). C'est l'objet du
chapitre 13 de rendre les scripts indépendants de l'endroit d'où on les
lance.

---

## 4. Les arguments : `$1`, `$2`, `$#`, `$@`

### 4.1 Le principe

Les mots écrits après le nom du script sont ses **arguments** :

```bash
#!/bin/bash
echo "Nom du script : $0"
echo "Nombre d'arguments : $#"
echo "Premier : $1 ; deuxième : $2"
echo "Tous : $@"
```

```bash
bash scripts/arguments.sh P01 P07 P09
```

```text
Nom du script : scripts/arguments.sh
Nombre d'arguments : 3
Premier : P01 ; deuxième : P07
Tous : P01 P07 P09
```

| Variable | Contenu |
|---|---|
| `$0` | le nom du script |
| `$1`, `$2`… | le 1er, le 2e… argument |
| `$#` | le **nombre** d'arguments |
| `"$@"` | **tous** les arguments, chacun séparément (toujours entre guillemets) |

### 4.2 Un script réutilisable

`scripts/compte_reads.sh` :

```bash
#!/bin/bash
# Usage : bash compte_reads.sh FICHIER.fastq.gz
# Affiche le nombre de reads d'un FASTQ compressé.
fichier=$1
lignes=$(zcat "$fichier" | wc -l)
echo "$fichier : $(( lignes / 4 )) reads"
```

```bash
bash scripts/compte_reads.sh run_sequencage/fastq/P07_S7_L001_R1_001.fastq.gz
```

```text
run_sequencage/fastq/P07_S7_L001_R1_001.fastq.gz : 290 reads
```

Mais sans argument :

```bash
bash scripts/compte_reads.sh
```

```text
gzip: .gz: No such file or directory
 : 0 reads
```

Le script ne s'arrête pas et affiche un résultat absurde : `$1` est vide.
Il faut **vérifier** ce qu'on reçoit, avec `if`.

---

## 5. Décider : `if`

### 5.1 La syntaxe

```bash
if CONDITION; then
    commandes si vrai
elif AUTRE_CONDITION; then
    commandes si cette autre condition est vraie
else
    commandes sinon
fi
```

La **condition** est une commande : `if` regarde son **code de retour**
(chapitre 05). 0 = vrai, autre chose = faux. La commande la plus utilisée
pour écrire une condition est `[ … ]`, aussi nommée `test`.

> **Les espaces à l'intérieur des crochets sont obligatoires.** `[` est une
> commande, et ses éléments sont des arguments :
>
> ```text
> $ n=150; if [$n -lt 200]; then echo petit; fi
> [150: command not found
> ```

### 5.2 Les tests les plus utiles

| Test | Vrai si… |
|---|---|
| `[ -f "$f" ]` | `$f` existe et est un fichier |
| `[ -d "$d" ]` | `$d` existe et est un dossier |
| `[ -s "$f" ]` | `$f` existe et **n'est pas vide** |
| `[ ! -f "$f" ]` | `$f` n'existe **pas** (`!` inverse) |
| `[ "$a" = "$b" ]` / `!=` | les deux **textes** sont égaux / différents |
| `[ -z "$a" ]` | `$a` est vide |
| `[ "$n" -eq 10 ]` | **nombres** égaux (`-ne` différent) |
| `[ "$n" -lt 10 ]` / `-le` / `-gt` / `-ge` | `<`, `≤`, `>`, `≥` sur des **nombres** |
| `[ … ] && [ … ]` / `[ … ] \|\| [ … ]` | et / ou |

> **Attention : `=` compare du texte, `-eq` compare des nombres.** Et `<` ou
> `>` dans `[ ]` comparent du texte (et `>` y serait d'ailleurs une
> redirection). Pour des nombres : `-lt`, `-gt`.

Toute commande peut servir de condition : `if grep -q GGATCC fichier`,
`if gzip -t fichier.gz 2> /dev/null`…

### 5.3 Un script qui vérifie ses entrées

`scripts/compte_reads2.sh` :

```bash
#!/bin/bash
# Usage : bash compte_reads2.sh FICHIER.fastq.gz
if [ $# -ne 1 ]; then
    echo "Usage : $0 FICHIER.fastq.gz" >&2
    exit 1
fi
fichier=$1
if [ ! -f "$fichier" ]; then
    echo "Erreur : fichier introuvable : $fichier" >&2
    exit 1
fi
n=$(( $(zcat "$fichier" | wc -l) / 4 ))
if [ "$n" -lt 200 ]; then
    echo "$fichier : $n reads (ALERTE : moins de 200 reads)"
else
    echo "$fichier : $n reads"
fi
```

```bash
bash scripts/compte_reads2.sh
bash scripts/compte_reads2.sh inexistant.fastq.gz
bash scripts/compte_reads2.sh run_sequencage/fastq/P09_S9_L001_R1_001.fastq.gz
```

```text
Usage : scripts/compte_reads2.sh FICHIER.fastq.gz
Erreur : fichier introuvable : inexistant.fastq.gz
run_sequencage/fastq/P09_S9_L001_R1_001.fastq.gz : 150 reads (ALERTE : moins de 200 reads)
```

- **`exit 1`** arrête le script avec un code d'échec : un autre script ou
  `&&` saura qu'il a échoué. `exit 0` (ou la fin du script) signale un
  succès.
- **`>&2`** envoie le message sur la sortie d'**erreur** (chapitre 05) : si
  l'on redirige les résultats dans un fichier, les messages d'erreur ne s'y
  mélangent pas.
- Le message d'**usage** dit à l'utilisateur, c'est-à-dire à vous dans six
  mois, comment se servir du script.

---

## 6. Répéter : la boucle `for`

### 6.1 Sur une liste

```bash
for ech in P01 P07 P09; do
    echo "Échantillon : $ech"
done
```

```text
Échantillon : P01
Échantillon : P07
Échantillon : P09
```

La variable `ech` prend successivement chaque valeur de la liste, et le
**corps** de la boucle, entre `do` et `done`, s'exécute à chaque fois.

### 6.2 Sur des fichiers : l'usage majeur

Le joker produit la liste des fichiers (chapitre 03) :

```bash
for f in run_sequencage/fastq/*_R1_001.fastq.gz; do
    echo "$f"
done
```

Le script qui compte les reads de tout le run, `scripts/compte_run.sh` :

```bash
#!/bin/bash
# Compte les reads de chaque fichier R1 du run et écrit un tableau TSV.
printf "echantillon\treads_R1\n"
for f in run_sequencage/fastq/*_R1_001.fastq.gz; do
    nom=$(basename "$f")
    ech=${nom%%_*}
    n=$(( $(zcat "$f" | wc -l) / 4 ))
    printf "%s\t%d\n" "$ech" "$n"
done
```

```bash
bash scripts/compte_run.sh
```

```text
echantillon	reads_R1
P01	300
P02	280
P03	350
P04	310
P05	260
P06	330
P07	290
P08	340
P09	150
P10	320
P11	300
P12	270
```

Ce qui demandait au chapitre 05 une ligne par fichier tient maintenant en
un script de 7 lignes, qui fonctionnera tel quel sur le prochain run.

- `basename chemin` donne le nom du fichier sans son dossier
  (`P07_S7_L001_R1_001.fastq.gz`), `dirname` donne le dossier, et
  `basename chemin .fastq.gz` retire aussi l'extension.
- `${nom%%_*}` garde le nom de l'échantillon (chapitre 10, section 3.3).
- `printf` produit un TSV propre : on peut rediriger la sortie du script,
  `bash scripts/compte_run.sh > comptes_R1.tsv`.

### 6.3 Combiner `for` et `if`

Le R2 de chaque paire est-il intact ? `${f/_R1_/_R2_}` construit le nom du
R2 à partir de celui du R1 :

```bash
for f in run_sequencage/fastq/*_R1_001.fastq.gz; do
    r2=${f/_R1_/_R2_}
    if gzip -t "$r2" 2> /dev/null; then
        echo "$(basename "$r2") OK"
    else
        echo "$(basename "$r2") CORROMPU"
    fi
done
```

La dernière ligne utile de la sortie : `P11_S11_L001_R2_001.fastq.gz CORROMPU`.

### 6.4 Le piège du joker sans correspondance

```bash
for f in *.xyz; do echo "traitement de $f"; done
```

```text
traitement de *.xyz
```

Si aucun fichier ne correspond, le joker reste tel quel (chapitre 03), et la
boucle s'exécute **une fois** avec le texte littéral `*.xyz`. C'est
l'origine du `*   0` de la section 3.2. Protection : vérifiez l'existence du
fichier dans la boucle (`[ -e "$f" ] || continue`), ou activez
`shopt -s nullglob` en tête de script (chapitre 13).

> **Autres formes utiles** : `for i in $(seq 1 12)` pour une suite de
> nombres ; `continue` passe directement au tour suivant ; `break` sort de
> la boucle.

---

## 7. Lire un fichier ligne par ligne : `while read`

### 7.1 La feuille d'échantillons, moteur de l'analyse

Dans un vrai projet, ce n'est pas un joker qui définit les échantillons à
analyser, c'est la **feuille d'échantillons** (*sample sheet*) : elle
associe chaque échantillon à sa condition et à ses fichiers. La boucle
`while read` la lit ligne par ligne, en découpant les colonnes dans des
variables :

`scripts/verifier_feuille.sh` :

```bash
#!/bin/bash
# Vérifie que les fichiers déclarés dans la feuille d'échantillons existent.
feuille=run_sequencage/echantillons.tsv
dossier=run_sequencage/fastq
tail -n +2 "$feuille" | while IFS=$'\t' read -r id patient condition replicat r1 r2; do
    for f in "$r1" "$r2"; do
        if [ -s "$dossier/$f" ]; then
            statut="présent"
        else
            statut="MANQUANT"
        fi
        printf "%s\t%s\t%s\t%s\n" "$id" "$condition" "$f" "$statut"
    done
done
```

```bash
bash scripts/verifier_feuille.sh | head -n 4
```

```text
P01	temoin	P01_S1_L001_R1_001.fastq.gz	présent
P01	temoin	P01_S1_L001_R2_001.fastq.gz	présent
P02	temoin	P02_S2_L001_R1_001.fastq.gz	présent
P02	temoin	P02_S2_L001_R2_001.fastq.gz	présent
```

Lecture de la ligne clé :

| Élément | Rôle |
|---|---|
| `tail -n +2 "$feuille" \|` | envoie les lignes de données, sans l'en-tête |
| `while … ; do … done` | répète tant qu'il reste des lignes |
| `IFS=$'\t'` | découpe les lignes **aux tabulations** (`$'\t'` est une tabulation écrite pour Bash) |
| `read -r id patient … r2` | place chaque colonne dans une variable, dans l'ordre ; `-r` évite que les `\` soient interprétés |

Si un fichier manque, le script le signale : en déplaçant temporairement un
fichier, on obtient `P05	temoin	P05_S5_L001_R2_001.fastq.gz	MANQUANT`.

### 7.2 Le piège du pipe et des variables

```bash
compteur=0
tail -n +2 run_sequencage/echantillons.tsv | while read -r l; do compteur=$((compteur + 1)); done
echo "compteur = $compteur"
```

```text
compteur = 0
```

Une boucle placée **après un pipe** s'exécute dans un shell séparé : les
variables qu'elle modifie sont perdues à la sortie de la boucle. Pour garder
le résultat, on alimente la boucle **sans pipe**, par une redirection :

```bash
compteur=0
while read -r l; do compteur=$((compteur + 1)); done < <(tail -n +2 run_sequencage/echantillons.tsv)
echo "compteur = $compteur"
```

```text
compteur = 12
```

`< <(commande)` envoie la sortie d'une commande sur l'entrée de la boucle,
comme un fichier (*substitution de processus*). Si l'on n'a pas besoin des
variables après la boucle, la forme avec `|` convient très bien.

---

## 8. Choisir selon un motif : `case`

Pour tester une valeur contre plusieurs motifs, `case` est plus lisible
qu'une série de `if` :

```bash
ech=P09
case "$ech" in
    P0[1-6])  echo "témoin" ;;
    P0[7-9]|P1[0-2]) echo "traité" ;;
    *)        echo "inconnu" ;;
esac
```

Les motifs sont des jokers (chapitre 03), `|` signifie « ou », `*)` est le
cas par défaut, et chaque cas se termine par `;;`.

---

## 9. En bioinformatique

Presque tous les traitements d'un projet NGS prennent cette forme :

```bash
while IFS=$'\t' read -r id patient condition replicat r1 r2; do
    outil --entree1 "data/raw/$r1" --entree2 "data/raw/$r2" --sortie "resultats/$id"
done < <(tail -n +2 echantillons.tsv)
```

- **La feuille d'échantillons pilote l'analyse** : ajouter un échantillon,
  c'est ajouter une ligne, pas modifier le script.
- **Les noms de sortie dérivent des noms d'entrée** (`$id`, `${f%.fastq.gz}`) :
  on retrouve toujours quel résultat vient de quel échantillon.
- Les vrais projets ajoutent ensuite la robustesse (chapitre 13), puis
  passent à un **gestionnaire de workflow** comme Snakemake ou Nextflow
  (module 34 de la Partie II), qui sait reprendre une analyse interrompue
  et paralléliser les échantillons.

---

## 10. Pièges fréquents

| Situation | Symptôme | Solution |
|---|---|---|
| script lancé depuis un autre dossier | `No such file or directory`, ou `*` dans les résultats | lancer depuis le dossier du projet ; chemins en arguments |
| argument manquant | résultat absurde, commandes sur un nom vide | tester `$#` et afficher un usage |
| `[$n -lt 200]` | `[150: command not found` | espaces : `[ "$n" -lt 200 ]` |
| `[ $a = toto ]` avec `$a` vide | `unary operator expected` | guillemets : `[ "$a" = toto ]` |
| `=` pour des nombres, `-eq` pour du texte | comparaisons fausses | `-eq -lt -gt` pour les nombres |
| joker sans correspondance | la boucle traite le texte `*.xyz` | `[ -e "$f" ] \|\| continue` ; `nullglob` |
| `while read` après un `\|` | variables perdues après la boucle | `done < <(commande)` ou `done < fichier` |
| `read` sans `IFS=$'\t'` sur un TSV | colonnes mal découpées s'il y a des espaces | `IFS=$'\t' read -r …` |
| message d'erreur sur la sortie standard | mélangé aux résultats redirigés | `echo "…" >&2` |
| fichier script écrit sous Windows | `/usr/bin/env: 'bash\r'` ou `$'\r': command not found` | corriger les fins de ligne (chapitres 06 et 13) |

---

## 11. À vous de jouer

Travaillez dans `~/formation_linux` et rangez vos scripts dans `scripts/`.

### Exercice 1 : un script à argument

*Objectif : `$1`, `$#` et usage.*
Écrivez `scripts/nb_sequences.sh`, qui affiche le nombre de séquences du
fichier FASTA donné en argument, et affiche un usage puis s'arrête en
erreur si l'argument manque ou si le fichier n'existe pas.

<details>
<summary>Corrigé</summary>

```bash
#!/bin/bash
# Usage : bash nb_sequences.sh FICHIER.fasta
if [ $# -ne 1 ]; then
    echo "Usage : $0 FICHIER.fasta" >&2
    exit 1
fi
if [ ! -f "$1" ]; then
    echo "Erreur : fichier introuvable : $1" >&2
    exit 1
fi
echo "$1 : $(grep -c '^>' "$1") séquences"
```

```bash
bash scripts/nb_sequences.sh genome.fasta
```

```text
genome.fasta : 22 séquences
```
</details>

### Exercice 2 : toutes les séquences de tous les FASTA

*Objectif : boucle `for` sur des fichiers.*
Écrivez un script qui, pour chaque fichier `.fasta` du dossier courant,
affiche son nom et son nombre de séquences, séparés par une tabulation.

<details>
<summary>Corrigé</summary>

```bash
#!/bin/bash
for f in *.fasta; do
    printf "%s\t%d\n" "$f" "$(grep -c '^>' "$f")"
done
```

```text
exercice_sequences.fasta	22
genome.fasta	22
proteins.fasta	25
transcripts.fasta	40
```
</details>

### Exercice 3 : les reads des deux lectures

*Objectif : construire le nom du R2 à partir du R1.*
Complétez `compte_run.sh` pour qu'il affiche, pour chaque échantillon, le
nombre de reads du R1 **et** du R2, et une colonne `statut` qui vaut
`OK` si les deux nombres sont égaux, `DIFFERENT` sinon.

<details>
<summary>Corrigé</summary>

```bash
#!/bin/bash
printf "echantillon\treads_R1\treads_R2\tstatut\n"
for r1 in run_sequencage/fastq/*_R1_001.fastq.gz; do
    r2=${r1/_R1_/_R2_}
    nom=$(basename "$r1")
    ech=${nom%%_*}
    n1=$(( $(zcat "$r1" | wc -l) / 4 ))
    n2=$(( $(zcat "$r2" 2> /dev/null | wc -l) / 4 ))
    if [ "$n1" -eq "$n2" ]; then
        statut=OK
    else
        statut=DIFFERENT
    fi
    printf "%s\t%d\t%d\t%s\n" "$ech" "$n1" "$n2" "$statut"
done
```

La ligne de P11 devient `P11	300	172	DIFFERENT` : 691 lignes, divisées
par 4 en arithmétique entière, donnent 172. Le fichier tronqué est repéré
automatiquement.
</details>

### Exercice 4 : piloter par la feuille d'échantillons

*Objectif : `while read` et colonnes.*
À partir de `echantillons.tsv`, affichez pour chaque échantillon **traité**
seulement : son identifiant, son réplicat et le nombre de reads de son R1.

<details>
<summary>Corrigé</summary>

```bash
#!/bin/bash
while IFS=$'\t' read -r id patient condition replicat r1 r2; do
    if [ "$condition" = "traite" ]; then
        n=$(( $(zcat "run_sequencage/fastq/$r1" | wc -l) / 4 ))
        printf "%s\treplicat %s\t%d reads\n" "$id" "$replicat" "$n"
    fi
done < <(tail -n +2 run_sequencage/echantillons.tsv)
```

```text
P07	replicat 1	290 reads
P08	replicat 2	340 reads
P09	replicat 3	150 reads
P10	replicat 4	320 reads
P11	replicat 5	300 reads
P12	replicat 6	270 reads
```
</details>

### Exercice 5 : renommer en série

*Objectif : boucle et expansion de variables.*
Dans un dossier `renommes/`, créez pour chaque fichier R1 du run une
**copie** nommée `P01_R1.fastq.gz`, `P02_R1.fastq.gz`… Faites d'abord
afficher les commandes `cp` **sans les exécuter**, vérifiez-les, puis
lancez-les.

<details>
<summary>Corrigé</summary>

```bash
mkdir -p renommes
for f in run_sequencage/fastq/*_R1_001.fastq.gz; do
    nom=$(basename "$f")
    echo cp "$f" "renommes/${nom%%_*}_R1.fastq.gz"
done
```

Une fois la liste vérifiée, retirez le `echo` et relancez la boucle.
**Afficher avant d'exécuter** est le geste de sécurité des opérations en
série, comme `ls` avant `rm` (chapitre 03).
</details>

---

## 12. Défi : le projet 1 en un script

Transformez les étapes 1 et 3 à 5 du projet 1 en un **seul script**
`scripts/inventaire.sh`, qui écrit dans `resultats_inventaire/` le contrôle
MD5 et un tableau `echantillon condition lecture reads`, **sans copier ni
décompresser** de fichiers sur le disque. Le fichier corrompu doit être
signalé, mais pas compté.

<details>
<summary>Indice</summary>

Pour chaque ligne de la feuille d'échantillons, testez chacun des deux
fichiers avec `gzip -t` avant de compter ses reads avec `zcat | wc -l`.
Pour `md5sum -c`, placez-vous dans le dossier des fichiers avec `cd`, puis
revenez avec `cd -`.
</details>

<details>
<summary>Corrigé</summary>

```bash
#!/bin/bash
# Inventaire d'un run : intégrité et nombre de reads par fichier.
run=run_sequencage
sortie=resultats_inventaire
mkdir -p "$sortie"

cd "$run/fastq" && md5sum -c MD5SUMS.txt > "$OLDPWD/$sortie/controle_md5.txt" 2>&1
cd - > /dev/null

printf "echantillon\tcondition\tlecture\treads\n" > "$sortie/inventaire.tsv"
while IFS=$'\t' read -r id patient condition replicat r1 r2; do
    for f in "$r1" "$r2"; do
        chemin="$run/fastq/$f"
        lecture=$(echo "$f" | cut -d _ -f 4)
        if gzip -t "$chemin" 2> /dev/null; then
            n=$(( $(zcat "$chemin" | wc -l) / 4 ))
            printf "%s\t%s\t%s\t%d\n" "$id" "$condition" "$lecture" "$n" >> "$sortie/inventaire.tsv"
        else
            echo "ATTENTION : $f corrompu, non compté" >&2
        fi
    done
done < <(tail -n +2 "$run/echantillons.tsv")
echo "Inventaire écrit dans $sortie/"
```

```bash
bash scripts/inventaire.sh
```

```text
ATTENTION : P11_S11_L001_R2_001.fastq.gz corrompu, non compté
Inventaire écrit dans resultats_inventaire/
```

`$OLDPWD` contient le dossier précédent, celui d'où l'on vient avant le
`cd`. Le tableau compte 24 lignes : l'en-tête et 23 fichiers. Ce script
fonctionne, mais il reste fragile : un nom de dossier en dur, aucune
gestion d'erreur générale, aucun journal. Le chapitre 13 et le projet 2
vont le rendre robuste.
</details>

---

## L'essentiel

```text
#!/bin/bash   # commentaire        bash script.sh   ou   chmod u+x + ./script.sh
$0 $1 $2 $# "$@"                   nom, arguments, nombre, tous
if [ test ]; then …; elif …; else …; fi      espaces dans [ ] obligatoires
-f -d -s ! -z   = !=   -eq -ne -lt -le -gt -ge      tests fichiers, textes, nombres
exit 1 (échec)   echo "…" >&2 (message d'erreur)    usage si arguments manquants
for f in dossier/*_R1_*.fastq.gz; do … "$f" … done  boucle sur des fichiers
r2=${f/_R1_/_R2_}   nom=$(basename "$f")   ech=${nom%%_*}
while IFS=$'\t' read -r c1 c2 …; do … done < <(tail -n +2 feuille.tsv)
case "$x" in motif) …;; *) …;; esac
Afficher (echo) avant d'exécuter une opération en série.
```

### Auto-évaluation

- [ ] J'écris un script, je le commente et je l'exécute de deux façons.
- [ ] Mon script vérifie ses arguments et affiche un usage.
- [ ] J'écris une condition sur un fichier, un texte et un nombre.
- [ ] Je fais une boucle sur tous les FASTQ d'un dossier et je produis un tableau.
- [ ] Je lis une feuille d'échantillons avec `while read` et `IFS=$'\t'`.
- [ ] Je connais les pièges du dossier courant et du pipe avant `while`.

## Documentation officielle

- Manuel de Bash, structures de contrôle : <https://www.gnu.org/software/bash/manual/html_node/Conditional-Constructs.html> · <https://www.gnu.org/software/bash/manual/html_node/Looping-Constructs.html>
- Expressions conditionnelles (`[ ]`, `test`) : <https://www.gnu.org/software/bash/manual/html_node/Bash-Conditional-Expressions.html>
- `read` (manuel de Bash, *Bash Builtins*) : <https://www.gnu.org/software/bash/manual/html_node/Bash-Builtins.html>

**Prochaine étape** : [chapitre 13 — Scripts Bash (II)](../13_scripts_bash_2/README.md).
