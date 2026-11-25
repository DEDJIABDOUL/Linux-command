# Chapitre 13 — Scripts Bash (II) : des scripts robustes, journalisés et débogables

> **Durée estimée** : 3 h
> **Prérequis** : [chapitre 12](../12_scripts_bash_1/README.md), environnement conda `formation_partie1` ([chapitre 11](../11_installer_logiciels/README.md))
> **Suite** : [Projet 2 — Mon premier pipeline Bash](../projet2_pipeline_bash/README.md)

## Ce que vous saurez faire à la fin de ce chapitre

- Faire **s'arrêter** un script à la première erreur, au lieu de continuer
  en produisant des résultats faux (`set -euo pipefail`), et connaître les
  limites de ce mécanisme.
- Organiser un script en **fonctions**.
- Accepter des **options nommées** (`--entree`, `--sortie`) et vérifier les
  prérequis (fichiers, outils).
- **Journaliser** l'exécution, et **nettoyer** les fichiers temporaires
  quoi qu'il arrive (`trap`).
- **Déboguer** méthodiquement : `bash -n`, `bash -x`, ShellCheck, et réparer
  un script cassé.

---

## 1. Pourquoi

Un script naïf **continue** après une erreur. Ce comportement, utile au
terminal, est dangereux dans un script :

```bash
#!/bin/bash
cd dossier_inexistant
echo "Suppression des fichiers temporaires de $(pwd)"
```

```text
scripts/danger.sh: line 2: cd: dossier_inexistant: No such file or directory
Suppression des fichiers temporaires de /home/marie/formation_linux
```

Le `cd` a échoué, mais le script a continué **dans un autre dossier que
prévu**. Si la ligne suivante avait été un `rm`, il aurait effacé les
fichiers du mauvais dossier. En analyse, le même mécanisme produit des
résultats calculés sur un fichier vide ou tronqué, sans aucune alerte. Un
script destiné à tourner sans surveillance, la nuit, sur 200 échantillons,
doit donc **échouer bruyamment** plutôt que réussir faussement.

---

## 2. Une image pour comprendre : la check-list et l'arrêt d'urgence

Un protocole de laboratoire sérieux comporte une **check-list** avant de
commencer (réactifs présents ? appareil calibré ?), un **arrêt immédiat** si
une étape échoue (la PCR n'a rien donné : on ne lance pas le séquençage),
un **cahier de manip** rempli au fur et à mesure, et un **rangement** de la
paillasse, même si la manip a été interrompue. C'est exactement ce que ce
chapitre ajoute à vos scripts :

| Protocole | Script |
|---|---|
| check-list | vérification des arguments, fichiers et outils |
| arrêt si une étape échoue | `set -euo pipefail` |
| cahier de manip | fonction `log` et fichier journal |
| rangement en fin de manip | `trap … EXIT` |

---

## 3. `set -euo pipefail` : l'arrêt d'urgence

Placez cette ligne juste après le shebang de **tous** vos scripts :

```bash
#!/bin/bash
set -euo pipefail
```

### 3.1 `-e` : arrêter à la première erreur

Avec `set -e` ajouté au script de la section 1 :

```text
scripts/danger2.sh: line 3: cd: dossier_inexistant: No such file or directory
code 1
```

Le script s'arrête sur la commande en échec, et renvoie un code d'erreur. La
ligne dangereuse n'est jamais exécutée.

### 3.2 `-u` : interdire les variables non définies

```bash
echantillon=P07
echo "Fichier : ${echantilon}_R1.fastq.gz"     # faute de frappe : echantilon
```

Sans `-u` : `Fichier : _R1.fastq.gz` (variable vide, aucune alerte).
Avec `set -u` :

```text
scripts/faute2.sh: line 4: echantilon: unbound variable
```

### 3.3 `-o pipefail` : un pipeline échoue si l'une de ses commandes échoue

Par défaut, le code de retour d'un pipeline est celui de sa **dernière**
commande. Le fichier tronqué du chapitre 05 :

```bash
set -e
n=$(zcat run_sequencage/fastq/P11_S11_L001_R2_001.fastq.gz | wc -l)
echo "$n lignes"
```

```text
gzip: run_sequencage/fastq/P11_S11_L001_R2_001.fastq.gz: unexpected end of file
691 lignes
code 0
```

Malgré `-e`, le script continue : `wc` a réussi, donc le pipeline aussi. Avec
`set -eo pipefail` :

```text
gzip: run_sequencage/fastq/P11_S11_L001_R2_001.fastq.gz: unexpected end of file
code 1
```

Le chiffre faux n'est plus jamais produit.

### 3.4 Les limites à connaître

`set -e` n'est pas magique :

- **Il ne s'applique pas** aux commandes testées par `if`, `while`, `&&` ou
  `||` : un échec y est attendu, c'est justement ce qu'on teste.
- **Certaines commandes « échouent » normalement.** `grep -c` renvoie 1
  quand il ne trouve rien (chapitre 06) :

  ```bash
  set -euo pipefail
  n=$(grep -c GAATTC formats/reference.fasta)
  echo "$n sites EcoRI"
  ```

  Le script s'arrête **sans rien afficher**, avec le code 1. Quand « zéro
  résultat » est une réponse valable, dites-le explicitement avec
  `|| true` :

  ```bash
  n=$(grep -c GAATTC formats/reference.fasta || true)
  ```

  ```text
  0 sites EcoRI
  ```

- **Un outil peut signaler une erreur sans échouer** : au chapitre 11,
  `seqkit stats` sur un fichier tronqué affichait `[ERRO]` mais renvoyait 0.
  Vérifiez aussi que les fichiers de sortie attendus existent et ne sont
  pas vides (`[ -s fichier ]`).

### 3.5 `shopt -s nullglob` : pas de joker fantôme

Le joker sans correspondance du chapitre 12 traitait le texte `*.xyz` comme
un fichier. Avec `shopt -s nullglob`, un joker sans correspondance ne donne
**rien**, et la boucle ne s'exécute pas :

```bash
shopt -s nullglob
for f in *.xyz; do echo "traitement $f"; done
echo "boucle terminée"
```

```text
boucle terminée
```

---

## 4. Les fonctions

Une **fonction** est un bloc de commandes nommé, qu'on appelle comme une
commande. Elle rend un script lisible : chaque étape a un nom.

```bash
compter_reads() {
    local fichier=$1
    echo $(( $(zcat "$fichier" | wc -l) / 4 ))
}

n=$(compter_reads run_sequencage/fastq/P07_S7_L001_R1_001.fastq.gz)
```

- Une fonction se définit **avant** d'être appelée.
- À l'intérieur, `$1`, `$2`… sont les arguments **de la fonction**, pas
  ceux du script.
- **`local`** limite la variable à la fonction : sans lui, `fichier`
  écraserait une éventuelle variable du même nom ailleurs dans le script.
- Une fonction « renvoie » un résultat en l'**affichant** (`echo`), qu'on
  récupère avec `$( )`. `return 1` la fait échouer, comme `exit` pour un
  script.

---

## 5. Le journal : une fonction `log`

```bash
log() {
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a analyse.log >&2
}

log "Début de l'analyse"
log "P07 R1 : $n reads"
```

```text
[2026-11-25 10:42:13] Début de l'analyse
[2026-11-25 10:42:13] P07 R1 : 290 reads
```

Chaque message est horodaté, affiché sur la sortie d'erreur (pour ne pas
polluer les résultats redirigés), et ajouté à `analyse.log` par `tee -a`
(chapitre 05). `"$*"` regroupe tous les arguments de la fonction en un seul
texte. Six mois plus tard, le journal dira quand l'analyse a tourné, sur
quoi, et ce qui s'est passé.

---

## 6. Nettoyer quoi qu'il arrive : `trap`

Les analyses créent souvent des fichiers temporaires volumineux. Si le
script s'arrête sur une erreur (grâce à `set -e`), ils restent sur le
disque. `trap … EXIT` exécute une commande **à la sortie du script, quelle
qu'en soit la raison** :

```bash
#!/bin/bash
set -euo pipefail
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"; echo "nettoyage de $tmp" >&2' EXIT
echo "travail dans $tmp"
zcat run_sequencage/fastq/P07_S7_L001_R1_001.fastq.gz > "$tmp/P07.fastq"
wc -l < "$tmp/P07.fastq"
false
echo "jamais affiché"
```

```text
travail dans /tmp/tmp.XXXX
1160
nettoyage de /tmp/tmp.XXXX
```

`mktemp -d` crée un dossier temporaire au nom unique. La commande `false`,
qui échoue toujours, simule une erreur : le script s'arrête, mais le dossier
temporaire est quand même supprimé.

---

## 7. Des options nommées et une check-list

### 7.1 Pourquoi des options nommées

`bash script.sh run_sequencage/fastq resultats 4` : dans six mois, qui se
souviendra de l'ordre des arguments ?
`bash script.sh --entree run_sequencage/fastq --sortie resultats --threads 4`
se lit tout seul.

### 7.2 Le modèle

Ce modèle est celui du script `scripts/pipeline_template.sh` du dépôt :

```bash
#!/bin/bash
set -euo pipefail

usage() {
    echo "Usage : $0 --entree DOSSIER --sortie DOSSIER [--threads N]" >&2
    exit 1
}

threads=4                                  # valeur par défaut
while [ $# -gt 0 ]; do
    case "$1" in
        --entree)  entree=$2;  shift 2 ;;
        --sortie)  sortie=$2;  shift 2 ;;
        --threads) threads=$2; shift 2 ;;
        -h|--aide) usage ;;
        *) echo "Option inconnue : $1" >&2; usage ;;
    esac
done

# Check-list
[ -n "${entree:-}" ] && [ -n "${sortie:-}" ] || usage
[ -d "$entree" ] || { echo "Erreur : dossier introuvable : $entree" >&2; exit 1; }
command -v seqkit > /dev/null || { echo "Erreur : seqkit introuvable (conda activate formation_partie1 ?)" >&2; exit 1; }
mkdir -p "$sortie"
```

| Élément | Rôle |
|---|---|
| `while [ $# -gt 0 ]` | tant qu'il reste des arguments… |
| `case "$1" in --entree) …` | … on regarde le premier (chapitre 12, section 8) |
| `shift 2` | on « consomme » l'option et sa valeur ; `$3` devient `$1` |
| `${entree:-}` | vide si `entree` n'est pas définie, ce qui évite que `set -u` arrête le script avant le message d'usage |
| `[ … ] \|\| { …; exit 1; }` | une check-list compacte : si le test échoue, message et arrêt |
| `command -v outil` | l'outil est-il dans le `PATH` ? (chapitre 10) |

---

## 8. Déboguer méthodiquement

| Outil | Ce qu'il fait | Quand |
|---|---|---|
| `bash -n script.sh` | vérifie la **syntaxe** sans rien exécuter | après chaque modification importante |
| `shellcheck script.sh` | analyse le script et signale les erreurs probables et les mauvaises pratiques | **toujours**, avant d'utiliser un script |
| `bash -x script.sh` | affiche chaque commande **après** remplacement des variables, juste avant de l'exécuter | quand le script ne fait pas ce qu'on croit |
| `echo` provisoires | affichent la valeur d'une variable à un endroit précis | pour vérifier une hypothèse |

`bash -n` repère par exemple un `if` sans `fi` :

```text
scripts/syntaxe.sh: line 3: syntax error: unexpected end of file
```

ShellCheck est installé dans l'environnement `formation_partie1`
(chapitre 11) : `conda activate formation_partie1`.

---

## 9. Atelier : réparer `script_casse.sh`

Le fichier `pieges/script_casse.sh` contient **cinq erreurs** typiques. Il
doit compter les paires de reads de chaque échantillon du run. Réparons-le
**en lisant les messages, un par un**. Travaillez sur une copie :

```bash
cd ~/formation_linux
cp pieges/script_casse.sh scripts/casse.sh
cd scripts
```

**Erreur 1 : le fichier n'est pas exécutable**

```text
$ ./casse.sh
bash: ./casse.sh: Permission denied
```

Diagnostic : `ls -l casse.sh` montre l'absence de `x` (chapitre 08).
Correction : `chmod u+x casse.sh`.

**Erreur 2 : des fins de ligne Windows**

```text
$ ./casse.sh
/usr/bin/env: ‘bash\r’: No such file or directory
```

Le `\r` révèle des fins de ligne Windows : le système cherche un programme
nommé `bash\r`. Avec `bash casse.sh`, le message est différent mais la cause
est la même :

```text
casse.sh: line 4: set: pipefail: invalid option name
```

Diagnostic : `file casse.sh` affiche `with CRLF line terminators`, et
`cat -A casse.sh` montre des `^M$` (chapitre 04). Correction (chapitre 06) :

```bash
tr -d '\r' < casse.sh > casse_unix.sh
```

**Erreur 3 : un mauvais chemin**

```text
$ bash casse_unix.sh
gzip: ../run_sequencage/fastqs/*_R1_001.fastq.gz: No such file or directory
```

Le joker n'a rien trouvé, donc `zcat` a reçu le motif littéral. Le dossier
s'appelle `fastq`, et non `fastqs`. `bash -x` montre la valeur de
`DOSSIER` :

```text
+ DOSSIER=../run_sequencage/fastqs
+ for f in $DOSSIER/*_R1_001.fastq.gz
++ zcat '../run_sequencage/fastqs/*_R1_001.fastq.gz'
```

Correction : `DOSSIER=../run_sequencage/fastq`.

**Erreur 4 : une variable jamais définie**

```text
$ bash casse_unix.sh
casse_unix.sh: line 10: SORTIE: unbound variable
```

`set -u` fait son travail : `$SORTIE` n'a jamais reçu de valeur. Sans `-u`,
la redirection `>> $SORTIE` aurait échoué de façon bien plus obscure.

**Erreur 5 : des variables sans guillemets**

ShellCheck signale ce que l'exécution ne montre pas encore :

```text
$ shellcheck casse_unix.sh

In casse_unix.sh line 8:
for f in $DOSSIER/*_R1_001.fastq.gz; do
         ^------^ SC2231 (info): Quote expansions in this for loop glob to prevent wordsplitting, e.g. "$dir"/*.txt .

In casse_unix.sh line 9:
    n=$(( $(zcat $f | wc -l) / 4 ))
                 ^-- SC2086 (info): Double quote to prevent globbing and word splitting.
```

Ces variables sans guillemets casseraient le script le jour où un chemin
contiendrait un espace (chapitre 10).

**La version réparée**, qui prend aussi ses chemins en arguments pour
fonctionner depuis n'importe quel dossier :

```bash
#!/bin/bash
# Compte les reads (paires) de chaque échantillon du run.
# Usage : bash repare.sh DOSSIER_FASTQ FICHIER_SORTIE
set -euo pipefail

DOSSIER=$1
SORTIE=$2

for f in "$DOSSIER"/*_R1_001.fastq.gz; do
    n=$(( $(zcat "$f" | wc -l) / 4 ))
    echo "$f : $n paires de reads" >> "$SORTIE"
done
```

```bash
shellcheck repare.sh && echo "aucun avertissement"
cd ~/formation_linux
bash scripts/repare.sh run_sequencage/fastq comptes.txt
head -n 2 comptes.txt
```

```text
aucun avertissement
run_sequencage/fastq/P01_S1_L001_R1_001.fastq.gz : 300 paires de reads
run_sequencage/fastq/P02_S2_L001_R1_001.fastq.gz : 280 paires de reads
```

> **La méthode à retenir** : lire le message ; identifier qui parle, de
> quoi, et quel est le problème (chapitre 01) ; faire **une** correction ;
> relancer. Ne corrigez jamais trois choses à la fois au hasard.

---

## 10. Pour aller plus loin : traiter plusieurs échantillons en parallèle

Les échantillons sont indépendants : on peut les traiter simultanément sur
plusieurs cœurs (chapitre 09).

```bash
ls run_sequencage/fastq/*_R1_001.fastq.gz | xargs -P 4 -I {} sh -c 'echo "$(basename {}) $(( $(zcat {} | wc -l) / 4 ))"'
```

`xargs -P 4` lance jusqu'à 4 commandes à la fois, et `{}` est remplacé par
chaque nom de fichier. **GNU parallel** (`sudo apt install parallel`, ou via
conda) offre la même chose avec plus d'options :
`ls … | parallel -j 4 "commande {}"`. Les résultats arrivent dans le
désordre : triez-les. Pour des analyses réelles, les gestionnaires de
workflow (module 34 de la Partie II) gèrent ce parallélisme bien plus
sûrement.

---

## 11. Pièges fréquents

| Situation | Symptôme | Solution |
|---|---|---|
| pas de `set -e` | le script continue après une erreur | `set -euo pipefail` |
| `set -e` et `grep` sans résultat | arrêt silencieux | `… \|\| true` quand 0 résultat est valable |
| erreur dans un pipeline ignorée | résultat partiel | `pipefail` |
| `set -u` et argument optionnel absent | `unbound variable` sur `$2` | `${2:-défaut}` |
| outil qui renvoie 0 malgré une erreur | résultat absent mais script « réussi » | vérifier `[ -s sortie ]` |
| fichiers temporaires laissés après un échec | disque encombré | `trap 'rm -rf "$tmp"' EXIT` |
| `/usr/bin/env: 'bash\r'` | fins de ligne Windows | `tr -d '\r'` ; écrire ses scripts sous Linux |
| fonction appelée avant d'être définie | `command not found` | définir les fonctions en tête de script |
| `$1` dans une fonction | argument de la fonction, pas du script | passer `"$@"` ou des valeurs explicites |

---

## 12. À vous de jouer

Activez l'environnement : `conda activate formation_partie1`. Travaillez dans
`~/formation_linux`.

### Exercice 1 : rendre robuste

*Objectif : `set -euo pipefail` et check-list.*
Reprenez `scripts/compte_reads2.sh` (chapitre 12). Ajoutez
`set -euo pipefail`, faites-le échouer explicitement si le fichier n'est
pas une archive gzip valide (`gzip -t`), et vérifiez-le sur le R2 de P11.

<details>
<summary>Corrigé</summary>

```bash
#!/bin/bash
# Usage : bash compte_reads3.sh FICHIER.fastq.gz
set -euo pipefail
[ $# -eq 1 ] || { echo "Usage : $0 FICHIER.fastq.gz" >&2; exit 1; }
fichier=$1
[ -f "$fichier" ] || { echo "Erreur : fichier introuvable : $fichier" >&2; exit 1; }
gzip -t "$fichier" 2> /dev/null || { echo "Erreur : archive gzip invalide : $fichier" >&2; exit 1; }
n=$(( $(zcat "$fichier" | wc -l) / 4 ))
echo "$fichier : $n reads"
```

```bash
bash scripts/compte_reads3.sh run_sequencage/fastq/P11_S11_L001_R2_001.fastq.gz
echo "code $?"
```

```text
Erreur : archive gzip invalide : run_sequencage/fastq/P11_S11_L001_R2_001.fastq.gz
code 1
```
</details>

### Exercice 2 : ShellCheck sur vos scripts

*Objectif : analyse statique.*
Passez ShellCheck sur **tous** les scripts écrits au chapitre 12. Corrigez
chaque avertissement, en comprenant pourquoi il est émis (chaque code
`SCxxxx` renvoie à une page d'explication sur <https://www.shellcheck.net/wiki/>).

<details>
<summary>Corrigé</summary>

```bash
shellcheck scripts/*.sh
```

Sur les scripts du chapitre 12, ShellCheck signale par exemple :

```text
In scripts/inventaire.sh line 8:
cd - > /dev/null
^--------------^ SC2164 (warning): Use 'cd ... || exit' or 'cd ... || return' in case cd fails.

In scripts/inventaire.sh line 11:
while IFS=$'\t' read -r id patient condition replicat r1 r2; do
                           ^-----^ SC2034 (warning): patient appears unused. Verify use (or export if used externally).
```

| Code | Signification | Correction |
|---|---|---|
| SC2086, SC2231 | variable sans guillemets | `"$variable"` |
| SC2164 | un `cd` qui échoue laisserait le script continuer ailleurs (section 1) | `cd dossier \|\| exit 1`, ou `set -e` |
| SC2034 | variable lue mais jamais utilisée | nommer `_` les colonnes inutiles : `read -r id _ condition _ r1 r2` |

Un script « propre » ne produit aucune sortie de ShellCheck.
</details>

### Exercice 3 : fonctions et journal

*Objectif : organiser un script.*
Écrivez `scripts/bilan.sh`, qui :
1. définit une fonction `log` (section 5) écrivant dans `bilan.log` ;
2. définit une fonction `compter_reads FICHIER` ;
3. journalise le début, puis le nombre de reads de chaque R1 du run, puis la
   fin.

<details>
<summary>Corrigé</summary>

```bash
#!/bin/bash
set -euo pipefail
shopt -s nullglob

log() {
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a bilan.log >&2
}

compter_reads() {
    local fichier=$1
    echo $(( $(zcat "$fichier" | wc -l) / 4 ))
}

log "Début du bilan"
for f in run_sequencage/fastq/*_R1_001.fastq.gz; do
    log "$(basename "$f") : $(compter_reads "$f") reads"
done
log "Fin du bilan"
```

`bilan.log` contient 14 lignes horodatées : le début, 12 échantillons, la
fin.
</details>

### Exercice 4 : options nommées

*Objectif : `while`/`case`/`shift`.*
Transformez `scripts/repare.sh` pour qu'il s'utilise ainsi :
`bash scripts/repare2.sh --entree DOSSIER --sortie FICHIER`. Sans option,
ou avec une option inconnue, il doit afficher un usage et s'arrêter en
erreur.

<details>
<summary>Corrigé</summary>

```bash
#!/bin/bash
set -euo pipefail
shopt -s nullglob

usage() { echo "Usage : $0 --entree DOSSIER --sortie FICHIER" >&2; exit 1; }

while [ $# -gt 0 ]; do
    case "$1" in
        --entree) entree=$2; shift 2 ;;
        --sortie) sortie=$2; shift 2 ;;
        *) usage ;;
    esac
done
[ -n "${entree:-}" ] && [ -n "${sortie:-}" ] || usage
[ -d "$entree" ] || { echo "Erreur : dossier introuvable : $entree" >&2; exit 1; }

: > "$sortie"                       # crée ou vide le fichier de sortie
for f in "$entree"/*_R1_001.fastq.gz; do
    echo "$(basename "$f") : $(( $(zcat "$f" | wc -l) / 4 )) paires" >> "$sortie"
done
```

`: > fichier` vide le fichier (ou le crée) : relancer le script ne fait plus
s'accumuler les résultats, contrairement à `repare.sh`, qui ajoutait à
chaque exécution.
</details>

---

## 13. Défi : le script qui ne ment jamais

Écrivez `scripts/stats_sures.sh`, qui calcule avec `seqkit stats -T` les
statistiques de tous les FASTQ d'un dossier passé en option `--entree`, et
qui garantit que :

- les fichiers corrompus sont **détectés et exclus**, avec un message dans
  le journal ;
- le script **échoue** (code non nul) si aucun fichier valide n'est trouvé ;
- le tableau final n'est écrit que si tout s'est bien passé, via un fichier
  temporaire nettoyé par `trap`.

<details>
<summary>Indice</summary>

Accumulez les fichiers valides dans un **tableau** Bash :
`valides=()`, puis `valides+=("$f")`. Le nombre d'éléments est
`${#valides[@]}`, et `"${valides[@]}"` les passe tous en arguments à une
commande. Écrivez le résultat dans `"$tmp/stats.tsv"`, puis déplacez-le
avec `mv` seulement à la toute fin.
</details>

<details>
<summary>Corrigé</summary>

```bash
#!/bin/bash
# Statistiques seqkit des FASTQ valides d'un dossier.
# Usage : bash stats_sures.sh --entree DOSSIER [--sortie FICHIER]
set -euo pipefail
shopt -s nullglob

usage() { echo "Usage : $0 --entree DOSSIER [--sortie FICHIER]" >&2; exit 1; }
log() { printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a stats_sures.log >&2; }

sortie=stats.tsv
while [ $# -gt 0 ]; do
    case "$1" in
        --entree) entree=$2; shift 2 ;;
        --sortie) sortie=$2; shift 2 ;;
        *) usage ;;
    esac
done
[ -n "${entree:-}" ] || usage
[ -d "$entree" ] || { log "ERREUR dossier introuvable : $entree"; exit 1; }
command -v seqkit > /dev/null || { log "ERREUR seqkit introuvable"; exit 1; }

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

valides=()
for f in "$entree"/*.fastq.gz; do
    if gzip -t "$f" 2> /dev/null; then
        valides+=("$f")
    else
        log "EXCLU (archive corrompue) : $(basename "$f")"
    fi
done
[ ${#valides[@]} -gt 0 ] || { log "ERREUR aucun fichier valide dans $entree"; exit 1; }

log "${#valides[@]} fichiers valides analysés"
seqkit stats -T "${valides[@]}" > "$tmp/stats.tsv" 2> "$tmp/seqkit.err"
[ -s "$tmp/stats.tsv" ] || { log "ERREUR seqkit n'a rien produit"; cat "$tmp/seqkit.err" >&2; exit 1; }
mv "$tmp/stats.tsv" "$sortie"
log "Résultat : $sortie"
```

```bash
bash scripts/stats_sures.sh --entree run_sequencage/fastq
```

Le journal signale `EXCLU (archive corrompue) : P11_S11_L001_R2_001.fastq.gz`,
puis `23 fichiers valides analysés`, et `stats.tsv` contient 24 lignes
(l'en-tête et 23 fichiers). Sur un dossier vide, le script échoue avec
`aucun fichier valide`. Le fichier de sortie n'apparaît que si tout a
réussi : on ne trouve jamais un résultat à moitié écrit.
</details>

---

## L'essentiel

```text
set -euo pipefail          -e arrêt sur erreur · -u variable non définie · pipefail
  limites : if/&&/|| non concernés ; grep sans résultat → || true ; vérifier [ -s sortie ]
shopt -s nullglob          joker sans correspondance = rien
f() { local x=$1; …; echo résultat; }      n=$(f arg)
log() { printf '[%s] %s\n' "$(date …)" "$*" | tee -a journal.log >&2; }
tmp=$(mktemp -d) ; trap 'rm -rf "$tmp"' EXIT
while [ $# -gt 0 ]; do case "$1" in --opt) v=$2; shift 2;; *) usage;; esac; done
[ -d "$d" ] || { echo "Erreur …" >&2; exit 1; }    command -v outil > /dev/null
bash -n (syntaxe) · shellcheck (analyse) · bash -x (trace)
Un message → une correction → relancer.
```

### Auto-évaluation

- [ ] Tous mes scripts commencent par `set -euo pipefail`, et j'en connais les limites.
- [ ] J'organise un script en fonctions, avec `local`.
- [ ] Mon script accepte des options nommées et affiche un usage.
- [ ] Mon script journalise son exécution et nettoie ses fichiers temporaires.
- [ ] J'ai réparé `script_casse.sh` en lisant les messages un par un.
- [ ] ShellCheck ne signale plus rien sur mes scripts.

## Documentation officielle

- `set` (manuel de Bash, *The Set Builtin*) : <https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html>
- Fonctions (manuel de Bash) : <https://www.gnu.org/software/bash/manual/html_node/Shell-Functions.html>
- `trap` (manuel de Bash, *Bourne Shell Builtins*) : <https://www.gnu.org/software/bash/manual/html_node/Bourne-Shell-Builtins.html>
- ShellCheck : <https://www.shellcheck.net/> · wiki des avertissements : <https://www.shellcheck.net/wiki/>
- GNU parallel : <https://www.gnu.org/software/parallel/>

**Prochaine étape** : [Projet 2 — Mon premier pipeline Bash](../projet2_pipeline_bash/README.md).
