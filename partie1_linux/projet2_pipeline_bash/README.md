# Projet 2 — Mon premier pipeline Bash : le contrôle qualité automatique d'un run

> **Durée estimée** : 4 à 6 h
> **Prérequis** : chapitres [12](../12_scripts_bash_1/README.md) et [13](../13_scripts_bash_2/README.md), environnement `formation_partie1`
> **Mobilise** : arguments et options, conditions, boucles, `while read`, fonctions, `set -euo pipefail`, journal, awk, liens symboliques, ShellCheck
> **Suite** : [chapitre 14 — Travailler à distance (SSH)](../14_ssh/README.md)

## La situation

Le projet 1 a convaincu votre équipe : l'inventaire d'un run évite de
perdre du temps sur des données défectueuses. Mais il a demandé une
vingtaine de commandes tapées à la main, et la plateforme livre un nouveau
run chaque mois.

Votre encadrante vous demande donc un **outil** : un script que n'importe
qui dans l'équipe pourra lancer sur n'importe quel run, et qui produira
toujours les mêmes livrables. C'est votre premier **pipeline** : une chaîne
d'étapes automatisée, robuste et traçable.

---

## Le cahier des charges

### Utilisation

```bash
bash qc_run.sh --run DOSSIER_FASTQ --feuille ECHANTILLONS.tsv --sortie DOSSIER [--min-reads N]
```

`--min-reads` vaut 200 par défaut.

### Comportement attendu

1. **Check-list** : sans les trois options obligatoires, ou avec une option
   inconnue, le script affiche un usage et s'arrête avec le code 1. Il
   s'arrête aussi, avec un message clair, si le dossier ou la feuille
   n'existe pas.
2. **Intégrité** : si le dossier contient un `MD5SUMS.txt`, le script lance
   `md5sum -c`, enregistre le résultat, et journalise le nombre de fichiers
   non conformes.
3. **QC par échantillon**, piloté par la **feuille d'échantillons** (et non
   par un joker), avec un **verdict** pour chaque échantillon. Les critères
   sont testés dans cet ordre, et le premier vérifié l'emporte :

   | Verdict | Condition |
   |---|---|
   | `EXCLU:fichier_absent` | le R1 ou le R2 n'existe pas, ou est vide |
   | `EXCLU:archive_corrompue` | le R1 ou le R2 échoue à `gzip -t` |
   | `EXCLU:paires_incoherentes` | le R1 et le R2 n'ont pas le même nombre de reads |
   | `EXCLU:trop_peu_de_reads` | moins de `--min-reads` reads |
   | `EXCLU:trop_de_N` | plus de 50 % des reads du R1 contiennent un `N` |
   | `A_SURVEILLER:adaptateurs` | plus de 10 % des reads du R1 contiennent l'adaptateur `AGATCGGAAGAGC` |
   | `OK` | sinon |

4. **Livrables** dans le dossier de sortie :

   | Fichier | Contenu |
   |---|---|
   | `pipeline.log` | journal horodaté : début, intégrité, verdict de chaque échantillon, fin |
   | `controle_md5.txt` | résultat de `md5sum -c` |
   | `qc_echantillons.tsv` | `echantillon condition reads_R1 reads_R2 pct_N_R1 pct_adapt_R1 verdict` (`NA` si non calculable) |
   | `echantillons_valides.tsv` | la feuille d'échantillons, avec son en-tête, réduite aux échantillons **non exclus** |
   | `donnees_valides/` | des **liens symboliques** (en chemin absolu) vers les FASTQ des échantillons retenus |

5. **Robustesse** :
   - `set -euo pipefail`, et aucun avertissement de ShellCheck ;
   - le script fonctionne **depuis n'importe quel dossier** ;
   - **relancé** sur le même dossier de sortie, il produit les mêmes
     livrables, sans doublons ;
   - il échoue (code non nul) si **aucun** échantillon n'est retenu ;
   - les données brutes ne sont **jamais** modifiées.

> **Comment travailler.** Construisez le script **étape par étape**, en le
> testant à chaque étape sur le run du bac à sable. Chaque étape ci-dessous
> donne un objectif, des indices et un point de contrôle. La solution
> complète est repliée à la fin.

---

## Architecture conseillée

```text
qc_run.sh
├── en-tête : commentaire d'usage, set -euo pipefail, shopt -s nullglob
├── constantes : ADAPTATEUR, MAX_PCT_N, MAX_PCT_ADAPT
├── fonctions : usage, log, qc_fichier
├── 1. lecture des options et check-list
├── 2. intégrité (md5sum -c)
├── 3. boucle sur la feuille d'échantillons → verdict, tableau, liens
└── 4. bilan et code de retour
```

---

## Étape 1 — Le squelette : options, usage, check-list

Écrivez l'en-tête, les fonctions `usage` et `log`, puis la lecture des
options (chapitre 13, section 7) et la check-list. Le journal doit être
**vidé** au début de chaque exécution.

<details>
<summary>Indice : le journal dans le dossier de sortie</summary>

La fonction `log` écrit dans `"$sortie/pipeline.log"`. Elle ne peut donc
être appelée qu'**après** la lecture des options et le `mkdir -p "$sortie"`.
`: > "$sortie/pipeline.log"` vide le journal.
</details>

<details>
<summary>Indice : fonctionner depuis n'importe où</summary>

Les liens symboliques de l'étape 4 doivent pointer vers des chemins
**absolus** (chapitre 03). `run=$(realpath "$run")` transforme le chemin
reçu en chemin absolu.
</details>

**Points de contrôle** :

```bash
bash qc_run.sh
echo "code $?"
bash qc_run.sh --run nulle_part --feuille run_sequencage/echantillons.tsv --sortie qc
```

```text
Usage : qc_run.sh --run DOSSIER_FASTQ --feuille ECHANTILLONS.tsv --sortie DOSSIER [--min-reads N]
code 1
Erreur : dossier introuvable : nulle_part
```

---

## Étape 2 — L'intégrité

Si `"$run/MD5SUMS.txt"` existe, lancez `md5sum -c` **depuis ce dossier**,
enregistrez tout dans `"$sortie/controle_md5.txt"`, et journalisez le
résultat.

<details>
<summary>Indice : se déplacer sans perturber le reste du script</summary>

Des parenthèses créent un **sous-shell** : un `cd` fait à l'intérieur ne
change pas le dossier courant du script :
`(cd "$run" && md5sum -c MD5SUMS.txt) > "$sortie/controle_md5.txt" 2>&1`.
Comme `md5sum -c` échoue dès qu'un fichier n'est pas conforme, et que
`set -e` arrêterait alors le script, placez cette commande dans un `if`.
</details>

**Point de contrôle** : le journal contient
`Sommes MD5 : 1 fichier(s) non conforme(s)`.

---

## Étape 3 — Les statistiques d'un fichier

Écrivez une fonction `qc_fichier FICHIER.fastq.gz` qui affiche, séparés par
des tabulations : le nombre de reads, le pourcentage de reads qui
contiennent un `N` et le pourcentage de reads qui contiennent l'adaptateur,
avec une décimale.

<details>
<summary>Indice</summary>

`zcat "$fichier" | awk …` avec `NR % 4 == 2` (chapitre 07, section 7.3).
Passez l'adaptateur à awk avec `-v`, et utilisez `index($0, ad)`, qui
renvoie la position du motif dans la ligne (0 s'il est absent).
</details>

**Point de contrôle** : `qc_fichier run_sequencage/fastq/P09_S9_L001_R1_001.fastq.gz`
affiche `150	94.7	14.0`.

> Pour tester une fonction isolément, copiez sa définition dans le
> terminal, puis appelez-la.

---

## Étape 4 — La boucle et les verdicts

Lisez la feuille d'échantillons avec `while read` (chapitre 12, section 7)
et, pour chaque échantillon :

1. vérifiez l'existence et l'intégrité des deux fichiers ;
2. s'ils sont valides, calculez les statistiques du R1 et le nombre de
   reads du R2 ;
3. déterminez le verdict, dans l'ordre du cahier des charges ;
4. écrivez la ligne du tableau et journalisez le verdict ;
5. si l'échantillon n'est pas exclu, recopiez sa ligne de la feuille dans
   `echantillons_valides.tsv`, et créez les liens vers ses deux fichiers.

<details>
<summary>Indice : récupérer les trois valeurs de qc_fichier</summary>

`read -r reads_r1 pct_n pct_adapt < <(qc_fichier "$run/$r1")` : `read`
découpe la sortie de la fonction dans trois variables.
</details>

<details>
<summary>Indice : comparer des pourcentages à virgule</summary>

`[ … -gt … ]` ne connaît que les entiers. Faites faire la comparaison par
awk, dont le code de retour est utilisable par `if` :
`if awk -v p="$pct_n" -v m=50 'BEGIN { exit !(p > m) }'; then …`.
`exit !(condition)` sort avec le code 0, c'est-à-dire « vrai » pour `if`,
quand la condition est vraie.
</details>

<details>
<summary>Indice : tester le préfixe du verdict</summary>

`${verdict%%:*}` vaut `EXCLU` pour `EXCLU:trop_de_N` (chapitre 10,
section 3.3).
</details>

<details>
<summary>Indice : rester relançable</summary>

Au début de l'étape, réécrivez l'en-tête du tableau avec `>` (et non
`>>`), copiez l'en-tête de la feuille dans `echantillons_valides.tsv`, et
recréez un dossier `donnees_valides/` vide (`rm -rf`, puis `mkdir -p`). Ce
`rm -rf` ne vise que **votre** dossier de sortie, jamais les données.
</details>

**Point de contrôle** : `column -t qc/qc_echantillons.tsv` affiche :

```text
echantillon  condition  reads_R1  reads_R2  pct_N_R1  pct_adapt_R1  verdict
P01          temoin     300       300       8.3       5.0           OK
P02          temoin     280       280       12.5      3.2           OK
P03          temoin     350       350       22.3      5.7           OK
P04          temoin     310       310       8.1       3.5           OK
P05          temoin     260       260       16.9      4.6           OK
P06          temoin     330       330       6.7       2.4           OK
P07          traite     290       290       11.4      3.8           OK
P08          traite     340       340       20.6      4.4           OK
P09          traite     150       150       94.7      14.0          EXCLU:trop_peu_de_reads
P10          traite     320       320       9.7       1.9           OK
P11          traite     NA        NA        NA        NA            EXCLU:archive_corrompue
P12          traite     270       270       14.8      2.2           OK
```

`echantillons_valides.tsv` compte 11 lignes (l'en-tête et 10 échantillons),
et `donnees_valides/` contient 20 liens.

> **Pourquoi P09 est-il exclu pour « trop peu de reads » et non pour
> « trop de N » ?** Les deux sont vrais. C'est l'**ordre de priorité** du
> cahier des charges qui décide : le premier critère rencontré l'emporte.
> Documenter cet ordre, c'est rendre le résultat explicable.

---

## Étape 5 — Le bilan, et la recette

Terminez le script : s'il n'y a aucun échantillon valide, journalisez une
erreur et sortez avec le code 1 ; sinon, journalisez le nombre
d'échantillons retenus.

Faites ensuite la **recette**, c'est-à-dire la batterie de tests
d'acceptation :

| Test | Résultat attendu |
|---|---|
| `shellcheck qc_run.sh` | aucune sortie |
| lancement normal | `Fin : 10 échantillon(s) retenu(s) sur 12` |
| relance sur le même dossier de sortie | mêmes fichiers ; `qc_echantillons.tsv` a toujours 13 lignes et le journal 15 |
| `--min-reads 320` | 8 échantillons exclus : seuls P03, P06, P08 et P10 ont au moins 320 reads (P11, corrompu, est exclu de toute façon) |
| lancement depuis `/tmp`, avec des chemins absolus | fonctionne, et les liens sont valides |
| `zcat qc/donnees_valides/P07_S7_L001_R1_001.fastq.gz \| head -n 1` | affiche le premier en-tête de P07 |
| `md5sum -c` du run après le pipeline | toujours 23 OK et 1 FAILED : les données brutes n'ont pas bougé |

---

## Grille d'évaluation

| Critère | ✔ |
|---|---|
| usage et codes de retour conformes au cahier des charges | |
| `set -euo pipefail`, et ShellCheck ne signale rien | |
| la feuille d'échantillons pilote la boucle | |
| les sept verdicts sont implémentés, dans l'ordre de priorité | |
| les cinq livrables sont produits, au bon format | |
| le script est relançable, et fonctionne depuis n'importe quel dossier | |
| le journal permet de comprendre l'exécution sans relire le code | |
| les données brutes ne sont jamais modifiées | |

---

## Pour aller plus loin

- **Paramétrer les seuils** : ajoutez les options `--max-pct-n` et
  `--max-pct-adapt`.
- **Paralléliser** : la boucle traite les échantillons l'un après l'autre.
  Comment la paralléliser avec `xargs -P` (chapitre 13, section 10) sans
  mélanger les lignes du tableau ? (Indice : un fichier de résultat par
  échantillon, rassemblés à la fin.)
- **Du script au workflow** : votre script refait tout à chaque lancement.
  Un gestionnaire de workflow (Snakemake, Nextflow : module 24 de la
  Partie II) ne refait que ce qui a changé, reprend après une panne et
  parallélise tout seul. Vous en comprendrez d'autant mieux l'intérêt que
  vous aurez écrit ce pipeline à la main.

---

## Solution complète

> Ouvrez-la après avoir essayé. Votre solution est correcte si elle passe
> toute la recette de l'étape 5, même si elle est écrite autrement.

<details>
<summary>Afficher la solution</summary>

```bash
#!/bin/bash
# qc_run.sh — contrôle qualité d'un run de séquençage paired-end.
#
# Usage :
#   bash qc_run.sh --run DOSSIER_FASTQ --feuille ECHANTILLONS.tsv --sortie DOSSIER [--min-reads N]
#
# Produit dans DOSSIER :
#   pipeline.log               journal horodaté de l'exécution
#   controle_md5.txt           résultat de md5sum -c (si MD5SUMS.txt est présent)
#   qc_echantillons.tsv        une ligne par échantillon, avec un verdict
#   echantillons_valides.tsv   la feuille d'échantillons, réduite aux échantillons retenus
#   donnees_valides/           liens symboliques vers les FASTQ retenus
set -euo pipefail
shopt -s nullglob

ADAPTATEUR=AGATCGGAAGAGC
MAX_PCT_N=50
MAX_PCT_ADAPT=10

usage() {
    echo "Usage : $0 --run DOSSIER_FASTQ --feuille ECHANTILLONS.tsv --sortie DOSSIER [--min-reads N]" >&2
    exit 1
}

log() {
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$sortie/pipeline.log" >&2
}

# Affiche : reads  pct_N  pct_adaptateur   (pour un FASTQ compressé)
qc_fichier() {
    local fichier=$1
    zcat "$fichier" | awk -v ad="$ADAPTATEUR" '
        NR % 4 == 2 { n++; if ($0 ~ /N/) avecN++; if (index($0, ad)) adapt++ }
        END { printf "%d\t%.1f\t%.1f\n", n, 100 * avecN / n, 100 * adapt / n }'
}

# ----- 1. Arguments et check-list -------------------------------------------
min_reads=200
while [ $# -gt 0 ]; do
    case "$1" in
        --run)       run=$2;       shift 2 ;;
        --feuille)   feuille=$2;   shift 2 ;;
        --sortie)    sortie=$2;    shift 2 ;;
        --min-reads) min_reads=$2; shift 2 ;;
        -h|--aide)   usage ;;
        *) echo "Option inconnue : $1" >&2; usage ;;
    esac
done
[ -n "${run:-}" ] && [ -n "${feuille:-}" ] && [ -n "${sortie:-}" ] || usage
[ -d "$run" ]     || { echo "Erreur : dossier introuvable : $run" >&2; exit 1; }
[ -s "$feuille" ] || { echo "Erreur : feuille d'échantillons introuvable ou vide : $feuille" >&2; exit 1; }
run=$(realpath "$run")
mkdir -p "$sortie"
: > "$sortie/pipeline.log"
log "Début : run=$run feuille=$feuille sortie=$sortie min_reads=$min_reads"

# ----- 2. Intégrité ----------------------------------------------------------
if [ -f "$run/MD5SUMS.txt" ]; then
    if (cd "$run" && md5sum -c MD5SUMS.txt) > "$sortie/controle_md5.txt" 2>&1; then
        log "Sommes MD5 : toutes conformes"
    else
        log "Sommes MD5 : $(grep -c ': FAILED' "$sortie/controle_md5.txt") fichier(s) non conforme(s)"
    fi
else
    log "ATTENTION : pas de MD5SUMS.txt, intégrité vérifiée par gzip -t seulement"
fi

# ----- 3. QC par échantillon -------------------------------------------------
printf "echantillon\tcondition\treads_R1\treads_R2\tpct_N_R1\tpct_adapt_R1\tverdict\n" > "$sortie/qc_echantillons.tsv"
head -n 1 "$feuille" > "$sortie/echantillons_valides.tsv"
rm -rf "$sortie/donnees_valides"
mkdir -p "$sortie/donnees_valides"

nb_valides=0
while IFS=$'\t' read -r id _ condition _ r1 r2; do
    verdict=OK
    reads_r1=NA; reads_r2=NA; pct_n=NA; pct_adapt=NA

    for f in "$r1" "$r2"; do
        if [ ! -s "$run/$f" ]; then
            verdict="EXCLU:fichier_absent"
        elif ! gzip -t "$run/$f" 2> /dev/null; then
            verdict="EXCLU:archive_corrompue"
        fi
    done

    if [ "$verdict" = OK ]; then
        read -r reads_r1 pct_n pct_adapt < <(qc_fichier "$run/$r1")
        reads_r2=$(( $(zcat "$run/$r2" | wc -l) / 4 ))
        if [ "$reads_r1" -ne "$reads_r2" ]; then
            verdict="EXCLU:paires_incoherentes"
        elif [ "$reads_r1" -lt "$min_reads" ]; then
            verdict="EXCLU:trop_peu_de_reads"
        elif awk -v p="$pct_n" -v m="$MAX_PCT_N" 'BEGIN { exit !(p > m) }'; then
            verdict="EXCLU:trop_de_N"
        elif awk -v p="$pct_adapt" -v m="$MAX_PCT_ADAPT" 'BEGIN { exit !(p > m) }'; then
            verdict="A_SURVEILLER:adaptateurs"
        fi
    fi

    printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "$id" "$condition" "$reads_r1" "$reads_r2" "$pct_n" "$pct_adapt" "$verdict" >> "$sortie/qc_echantillons.tsv"
    log "$id : $verdict"

    if [ "${verdict%%:*}" != EXCLU ]; then
        grep -P "^${id}\t" "$feuille" >> "$sortie/echantillons_valides.tsv"
        ln -s "$run/$r1" "$run/$r2" "$sortie/donnees_valides/"
        nb_valides=$(( nb_valides + 1 ))
    fi
done < <(tail -n +2 "$feuille")

# ----- 4. Bilan --------------------------------------------------------------
[ "$nb_valides" -gt 0 ] || { log "ERREUR : aucun échantillon valide"; exit 1; }
log "Fin : $nb_valides échantillon(s) retenu(s) sur $(( $(wc -l < "$feuille") - 1 ))"
```

Lancement :

```bash
conda activate formation_partie1
cd ~/formation_linux
bash qc_run.sh --run run_sequencage/fastq --feuille run_sequencage/echantillons.tsv --sortie qc
```

Journal (l'horodatage est remplacé ici par `…`) :

```text
[…] Début : run=/home/marie/formation_linux/run_sequencage/fastq feuille=run_sequencage/echantillons.tsv sortie=qc min_reads=200
[…] Sommes MD5 : 1 fichier(s) non conforme(s)
[…] P01 : OK
[…] P02 : OK
…
[…] P09 : EXCLU:trop_peu_de_reads
[…] P10 : OK
[…] P11 : EXCLU:archive_corrompue
[…] P12 : OK
[…] Fin : 10 échantillon(s) retenu(s) sur 12
```

Quelques choix à remarquer :

- `read -r id _ condition _ r1 r2` : les colonnes inutiles sont nommées
  `_`, ce qui évite l'avertissement SC2034 de ShellCheck.
- Les comparaisons de pourcentages sont confiées à awk, qui sait comparer
  des nombres décimaux.
- `donnees_valides/` contient des **liens** et non des copies : sur un vrai
  run de plusieurs centaines de Go, copier serait impossible.
- Le script ne contient **aucun chemin en dur** : tout vient des options.
</details>
