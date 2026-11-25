# Projet de synthèse — Une analyse complète, reproductible, menée sur un serveur

> **Durée estimée** : une journée
> **Prérequis** : toute la Partie I, dont les projets [1](../projet1_inventaire_run/README.md), [2](../projet2_pipeline_bash/README.md) et [3](../projet3_du_gene_au_variant/README.md)
> **Suite** : la [Partie II — Bioinformatique appliquée](../../partie2_bioinfo/README.md)

## La situation

Votre stage se termine. Votre encadrante vous demande de **laisser derrière
vous une analyse que n'importe qui pourra rejouer**, sur le serveur de
l'équipe, à partir des seules données brutes :

> « Je veux un dépôt Git propre, un environnement figé, et une seule
> commande qui refait tout : le contrôle qualité du run, puis l'analyse des
> mutations des deux souches. Lance-la sur le serveur, rapatrie les
> résultats, et écris-moi une page de conclusions. »

Ce projet ne demande **aucune commande nouvelle** : il demande d'assembler
proprement tout ce que vous savez faire. C'est précisément la compétence
attendue d'un bioinformaticien autonome.

Le « serveur » est celui du chapitre 14 : votre machine, jointe par
`ssh labo`, avec un espace de travail dans `~/serveur_simule/`.

---

## Le cahier des charges

### Le livrable : un dépôt `analyse_souches/`

```text
analyse_souches/
├── README.md                    question, données, comment reproduire, conclusions
├── .gitignore
├── envs/environment.yml         versions figées
├── data/
│   ├── raw/                     liens vers les données (non versionnés)
│   └── metadata/echantillons.tsv
├── scripts/
│   ├── 01_qc_run.sh             le pipeline du projet 2
│   ├── 02_du_gene_au_variant.sh le script du projet 3, adapté (voir étape 3)
│   └── run_all.sh               enchaîne tout, avec journaux
└── results/  logs/              produits par run_all.sh (non versionnés)
```

### Les exigences

1. `bash scripts/run_all.sh` refait **toute** l'analyse, **depuis n'importe
   quel dossier**, et s'arrête à la première erreur.
2. Les chemins sont relatifs à la racine du projet : **aucun chemin propre à
   votre machine** dans les scripts.
3. Le dépôt Git ne contient ni données ni résultats ; ShellCheck ne signale
   rien sur les scripts.
4. L'analyse est **exécutée sur le serveur**, dans tmux, et les résultats
   sont rapatriés avec rsync, puis leur intégrité est vérifiée.
5. Le `README.md` permet à un inconnu de reproduire l'analyse, et présente
   les conclusions en distinguant l'**observé** du **supposé**.

---

## Étape 1 — Créer le projet (chapitre 17)

Avec `nouveau_projet.sh`, créez `analyse_souches/`. Remplissez `data/`
(liens vers le run et vers `formats/`, copie de la feuille d'échantillons)
et `envs/`.

> **Une décision à prendre** : où placer les fichiers de `formats/`
> (référence, annotations, variants, alignements) ? La référence et les
> annotations vont dans `data/reference/`. Les variants et les alignements
> sont des **données d'entrée** de l'analyse : ils vont dans `data/raw/`.
> Justifiez votre choix dans le README.

---

## Étape 2 — Le contrôle qualité (projet 2)

Copiez `qc_run.sh` dans `scripts/01_qc_run.sh`. Il ne doit pas être modifié :
il prend déjà tous ses chemins en options.

---

## Étape 3 — L'analyse des mutations (projet 3), à rendre portable

Le script du projet 3 contient des chemins **en dur** (`F=formats`,
`S=projet3/$souche`) qui supposent qu'on le lance depuis `~/formation_linux`.
Transformez-le en `scripts/02_du_gene_au_variant.sh`, qui accepte des
options nommées (chapitre 13) :

```bash
bash scripts/02_du_gene_au_variant.sh --souche evolue_A --donnees data --sortie results/02_variants
```

**Point de contrôle** : lancé sur les deux souches, le script produit les
mêmes rapports qu'au projet 3.

---

## Étape 4 — Le script maître

Écrivez `scripts/run_all.sh` (chapitre 17, section 7) :

1. se placer à la racine du projet ;
2. vérifier les outils et l'environnement ;
3. lancer le QC, puis l'analyse des deux souches, chaque étape avec son
   journal dans `logs/` ;
4. écrire dans `results/RESUME.txt` un résumé : nombre d'échantillons
   retenus par le QC, et les changements protéiques de chaque souche.

**Point de contrôle** : après `rm -rf results logs`, `bash scripts/run_all.sh`
régénère tout, et `md5sum` montre que les rapports sont identiques à ceux
d'avant (défi du chapitre 17).

---

## Étape 5 — Versionner (chapitre 15)

Commitez le projet par étapes cohérentes (structure, scripts, README).
`git status` ne doit montrer ni `results/`, ni `logs/`, ni les liens de
`data/raw/`. Passez ShellCheck sur `scripts/*.sh`. Publiez sur GitHub dans
un dépôt **privé**.

---

## Étape 6 — Exécuter sur le serveur (chapitres 09 et 14)

1. Sur le serveur, clonez le dépôt (`git clone`), créez l'environnement
   (`mamba env create -f envs/environment.yml`), et envoyez les données
   brutes avec `rsync` (vérifiez-les avec `md5sum -c`).
2. Recréez les liens de `data/raw/` vers ces données. Pourquoi ne sont-ils
   pas dans le dépôt ?
3. Lancez `run_all.sh` **dans une session tmux**, détachez-vous,
   déconnectez-vous.
4. Revenez, vérifiez le journal, et rapatriez `results/` sur votre machine
   avec `rsync`.

**Point de contrôle** : `results/RESUME.txt` rapatrié de votre machine est
identique à celui produit en local (`md5sum`).

---

## Étape 7 — Conclure

Complétez le `README.md` : la question, les données (avec leur provenance et
le contrôle d'intégrité), la commande de reproduction, et les conclusions,
en reprenant les éléments des projets 1 à 3. Une page suffit.

---

## Grille d'évaluation

| Critère | Compétence | ✔ |
|---|---|---|
| l'arborescence est standard ; les données brutes sont protégées ou liées | chapitres 02, 03, 08, 17 | |
| `run_all.sh` refait tout, depuis n'importe où, et s'arrête sur erreur | chapitres 12, 13 | |
| aucun chemin propre à une machine dans les scripts | chapitres 10, 13 | |
| l'environnement est figé et recréé sur le serveur | chapitre 11 | |
| le dépôt est propre (ni données, ni résultats, ni secrets) ; ShellCheck ne signale rien | chapitres 13, 15 | |
| l'analyse a tourné sur le serveur dans tmux ; les résultats ont été rapatriés et vérifiés | chapitres 04, 09, 14 | |
| les résultats sont identiques d'une exécution à l'autre | chapitre 17 | |
| le README permet de reproduire, et les conclusions séparent l'observé du supposé | chapitre 17, projet 3 | |

Si tous les critères sont remplis, vous avez acquis **les fondations
complètes** du travail en bioinformatique. La Partie II vous apprendra les
outils d'analyse : contrôle qualité, alignement, assemblage, RNA-seq,
variants, workflows. Vous savez maintenant les utiliser proprement.

---

## Éléments de solution

<details>
<summary>Étape 3 : le début du script portable</summary>

```bash
#!/bin/bash
# Usage : bash 02_du_gene_au_variant.sh --souche NOM --donnees DOSSIER --sortie DOSSIER
set -euo pipefail

usage() { echo "Usage : $0 --souche NOM --donnees DOSSIER --sortie DOSSIER" >&2; exit 1; }
while [ $# -gt 0 ]; do
    case "$1" in
        --souche)  souche=$2;  shift 2 ;;
        --donnees) donnees=$2; shift 2 ;;
        --sortie)  sortie=$2;  shift 2 ;;
        *) usage ;;
    esac
done
[ -n "${souche:-}" ] && [ -n "${donnees:-}" ] && [ -n "${sortie:-}" ] || usage

REF=$donnees/reference/reference.fasta
GENES=$donnees/reference/genes.bed
VCF=$donnees/raw/variants.vcf
SAM=$donnees/raw/alignements.sam
S=$sortie/$souche
for f in "$REF" "$GENES" "$VCF" "$SAM"; do
    [ -s "$f" ] || { echo "Erreur : fichier introuvable : $f" >&2; exit 1; }
done
# … puis le corps du script du projet 3, en remplaçant "$F/reference.fasta"
#   par "$REF", "$F/genes.bed" par "$GENES", etc.
```
</details>

<details>
<summary>Étape 4 : run_all.sh</summary>

```bash
#!/bin/bash
# Reproduit toute l'analyse : QC du run, puis mutations des deux souches.
set -euo pipefail
cd "$(dirname "$0")/.."
for outil in samtools bcftools bedtools seqkit; do
    command -v "$outil" > /dev/null || { echo "Erreur : $outil introuvable (conda activate …)" >&2; exit 1; }
done
mkdir -p logs results

bash scripts/01_qc_run.sh --run data/raw/fastq --feuille data/metadata/echantillons.tsv \
    --sortie results/01_qc 2>&1 | tee logs/01_qc.log
for souche in evolue_A evolue_B; do
    bash scripts/02_du_gene_au_variant.sh --souche "$souche" --donnees data \
        --sortie results/02_variants 2>&1 | tee "logs/02_variants_$souche.log"
done

{
    echo "Analyse du $(date +%Y-%m-%d)"
    tail -n 1 results/01_qc/pipeline.log | cut -d ']' -f 2-
    for souche in evolue_A evolue_B; do
        echo "$souche : $(cut -f 2 "results/02_variants/$souche/changements_proteiques.tsv" | paste -sd ' ')"
    done
} > results/RESUME.txt
cat results/RESUME.txt
```

Le bloc `{ … } > fichier` redirige d'un coup la sortie de plusieurs
commandes. `RESUME.txt` contient une date : pour le comparer entre deux
exécutions, comparez plutôt les fichiers de `results/02_variants/` et
`results/01_qc/qc_echantillons.tsv`.
</details>

<details>
<summary>Étape 6 : pourquoi les liens de data/raw/ ne sont-ils pas dans Git ?</summary>

Un lien symbolique pointe vers un chemin **de la machine où il a été
créé** (`/home/marie/formation_linux/…`). Sur le serveur, les données sont
ailleurs : le lien serait cassé. On versionne donc la **description** des
données (README, feuille d'échantillons, sommes MD5), et l'on recrée les
liens sur chaque machine. Une petite étape `scripts/00_lier_donnees.sh
DOSSIER_DES_DONNEES` peut automatiser ce geste.
</details>
