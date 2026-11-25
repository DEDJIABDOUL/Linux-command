# Chapitre 17 — Organiser un projet de bioinformatique

> **Durée estimée** : 1 h 30
> **Prérequis** : [chapitre 16](../16_formats_biologiques/README.md)
> **Suite** : [Projet 3 — Du gène au variant](../projet3_du_gene_au_variant/README.md), puis le [projet de synthèse](../projet_synthese/README.md)

## Ce que vous saurez faire à la fin de ce chapitre

- Créer pour chaque analyse une **arborescence standard**, que tout le monde
  comprend sans explication.
- Séparer ce qui est **précieux** (données brutes, scripts, métadonnées) de
  ce qui est **régénérable** (résultats, fichiers intermédiaires).
- Rédiger le `README` d'un projet et une feuille de métadonnées.
- Rendre une analyse **reproductible de bout en bout** : un environnement
  figé, des scripts versionnés, un script maître.
- Créer en une commande la structure d'un nouveau projet.

---

## 1. Pourquoi

Six mois après une analyse, un relecteur demande : « Avec quelle version de
l'aligneur avez-vous obtenu la figure 3, et sur quels échantillons ? » Si
les fichiers bruts, les scripts et les résultats sont mélangés dans un même
dossier, avec des noms comme `test2_final.tsv`, la réponse est impossible.

Toutes les compétences des chapitres précédents convergent ici : chemins,
permissions, scripts, environnements, Git. Une bonne organisation, c'est ce
qui fait d'une suite de commandes une **analyse reproductible**, au même
titre qu'un cahier de laboratoire bien tenu fait d'une manip une expérience
publiable.

---

## 2. Une image pour comprendre : l'organisation d'un laboratoire

| Au laboratoire | Dans un projet |
|---|---|
| le congélateur à −80 °C des échantillons d'origine, sous clé | `data/raw/` : en lecture seule, jamais modifié |
| le registre des échantillons | `data/metadata/` : la feuille d'échantillons |
| les protocoles validés | `scripts/` et `envs/`, versionnés avec Git |
| les tubes intermédiaires | `results/` (et `work/`) : se refont à partir des protocoles |
| le cahier de laboratoire | `README.md` et les journaux dans `logs/` |

La règle qui en découle : **si l'on perd `results/`, on relance les
scripts ; si l'on perd `data/raw/`, le projet est perdu.**

---

## 3. L'arborescence type

```text
projet_amr_2026/
├── README.md              ce qu'est le projet, et comment le reproduire
├── data/
│   ├── raw/               données brutes, en LECTURE SEULE (ou liens vers elles)
│   ├── reference/         génome et annotation de référence
│   └── metadata/          echantillons.tsv : la feuille d'échantillons
├── envs/
│   └── environment.yml    les outils et leurs versions figées
├── scripts/
│   ├── 01_qc.sh           une étape par script, numérotée dans l'ordre
│   ├── 02_variants.sh
│   └── run_all.sh         le script maître, qui enchaîne tout
├── results/               tout ce que produisent les scripts
│   ├── 01_qc/
│   └── 02_variants/
├── logs/                  les journaux d'exécution
└── .gitignore             data/, results/, logs/ : hors de Git
```

| Dossier | Contient | Précieux ? | Dans Git ? |
|---|---|---|---|
| `data/raw/` | FASTQ, données reçues | **oui** : irremplaçable | **non** (trop gros) : sauvegardé à part |
| `data/reference/` | FASTA, GFF de référence | non : se retélécharge (noter la source et la version) | non |
| `data/metadata/` | feuille d'échantillons | **oui** | **oui** (petit fichier texte) |
| `envs/` | `environment.yml` | **oui** | **oui** |
| `scripts/` | le code | **oui** | **oui** |
| `results/`, `logs/` | sorties | non : se régénère | non |
| `README.md` | documentation | **oui** | **oui** |

> **Une variante courante** : les données brutes restent dans un espace de
> stockage central (sur un serveur, `/data/plateforme/run_2026-10-14/`), et
> `data/raw/` ne contient que des **liens symboliques** vers elles
> (chapitre 03). On ne les copie jamais dans chaque projet.

---

## 4. Les règles d'or

1. **Les données brutes sont en lecture seule** : `chmod -R a-w data/raw`
   (chapitre 08), dès qu'elles ont été vérifiées (`md5sum -c`, chapitre 04).
2. **Tout résultat est produit par un script**, jamais par une commande
   tapée à la main et oubliée. Le script est le protocole.
3. **Les chemins sont relatifs à la racine du projet** : les scripts se
   lancent depuis la racine (`bash scripts/01_qc.sh`), ou prennent les
   chemins en options. Le projet peut alors être déplacé ou partagé.
4. **Chaque étape écrit dans son propre dossier** (`results/01_qc/`), et
   n'écrit **jamais** dans `data/`.
5. **L'environnement est figé** dans `envs/environment.yml`, avec des
   versions précises (chapitre 11).
6. **Les scripts, les métadonnées et la documentation sont versionnés**
   avec Git ; les données et les résultats sont exclus par `.gitignore`
   (chapitre 15).
7. **Les noms sont explicites et triables** : `2026-10-14_run`,
   `01_qc.sh`, `P07_R1.fastq.gz`, sans espaces ni accents (chapitre 02).

---

## 5. Le README d'un projet

Le `README.md` est la **première chose que lit** un collègue, un relecteur,
ou vous-même dans un an. Un modèle minimal :

```markdown
# Résistance aux antibiotiques chez des souches évoluées — run 2026-10-14

## Question
Quelles mutations les souches evolue_A et evolue_B ont-elles acquises ?

## Données
- Reads : run 2026-10-14_M07112_0058, 12 échantillons paired-end 2 × 100 pb,
  dans /data/plateforme/run_2026-10-14 (liens dans data/raw/).
  Intégrité vérifiée le 2026-10-15 (md5sum -c : 23 OK, P11 R2 renvoyé).
- Référence : data/reference/reference.fasta (source, version, date de téléchargement).
- Métadonnées : data/metadata/echantillons.tsv.

## Reproduire l'analyse
    mamba env create -f envs/environment.yml
    conda activate projet_amr
    bash scripts/run_all.sh

## Résultats
- results/01_qc/qc_echantillons.tsv : bilan qualité par échantillon
- results/02_variants/ : variants par souche

## Journal
- 2026-10-15 : QC ; P09 exclu (prélèvement défectueux), P11 R2 redemandé.
```

---

## 6. La feuille de métadonnées

La feuille d'échantillons est le **pivot** de l'analyse (chapitre 12) : elle
dit quels échantillons existent, à quelle condition ils appartiennent, et
quels fichiers leur correspondent. Bonnes pratiques :

- un format **tabulé** (`.tsv`), avec une ligne d'en-tête, et une ligne par
  échantillon ;
- des identifiants **sans espaces**, identiques à ceux des noms de fichiers ;
- une colonne par information (condition, réplicat, date, lot…), jamais
  deux informations dans une même case ;
- pas de couleurs ni de cellules fusionnées : si elle est préparée dans un
  tableur, l'exporter en TSV et vérifier les fins de ligne (`file`,
  chapitre 04).

---

## 7. Un script maître : `run_all.sh`

Chaque étape est un script autonome, et un **script maître** les enchaîne
dans l'ordre :

```bash
#!/bin/bash
# Reproduit toute l'analyse, de data/ à results/.
set -euo pipefail
cd "$(dirname "$0")/.."            # se placer à la racine du projet, d'où qu'on lance le script
mkdir -p logs
bash scripts/01_qc.sh       2>&1 | tee logs/01_qc.log
bash scripts/02_variants.sh 2>&1 | tee logs/02_variants.log
echo "Analyse terminée : voir results/"
```

`cd "$(dirname "$0")/.."` place le script dans le dossier parent de
`scripts/`, c'est-à-dire à la racine du projet : les chemins relatifs des
étapes fonctionnent alors, d'où que l'on lance `run_all.sh`.

> **Quand le projet grandit** (des dizaines d'étapes, des centaines
> d'échantillons, la reprise après une panne), on passe à un gestionnaire de
> workflow, Snakemake ou Nextflow (module 34 de la Partie II). Ils
> reprennent exactement cette organisation, en l'automatisant.

---

## 8. Sauvegarder

Seules les données **précieuses** ont besoin d'une vraie sauvegarde, ce qui
est l'un des grands bénéfices de cette organisation :

- **Scripts, métadonnées, environnement, README** : poussés sur GitHub ou
  GitLab (chapitre 15). C'est leur sauvegarde.
- **Données brutes** : au moins **deux copies sur deux supports différents**,
  dont une hors du bâtiment (stockage institutionnel, archive), vérifiées par
  les sommes de contrôle. À terme, elles sont déposées dans une base
  publique (SRA, ENA : module 18 de la Partie II).
- **Résultats** : pas de sauvegarde indispensable, puisqu'ils se
  régénèrent. Gardez ceux qui ont demandé des jours de calcul, ou ceux qui
  figurent dans une publication.

Les principes **FAIR** (*Findable, Accessible, Interoperable, Reusable*),
que demandent de plus en plus les financeurs et les revues, reposent sur ces
mêmes gestes : des formats standard, des métadonnées, une documentation, un
dépôt public.

---

## 9. Pièges fréquents

| Situation | Conséquence | Prévention |
|---|---|---|
| un script écrit dans `data/` | données brutes écrasées | règle 4 ; `chmod -R a-w data/raw` |
| résultats obtenus « à la main » | impossible de les reproduire | règle 2 : tout passe par un script |
| chemins absolus propres à votre machine dans les scripts | le projet ne marche pas ailleurs | chemins relatifs à la racine, ou options |
| `results_final_v3/` | on ne sait plus quelle version est la bonne | Git pour les scripts ; un seul `results/`, régénérable |
| environnement non noté | résultats impossibles à reproduire dans un an | `envs/environment.yml` avec versions figées |
| feuille d'échantillons modifiée sans trace | incohérences entre scripts et données | métadonnées versionnées avec Git |
| tout est dans Git, FASTQ compris | dépôt énorme, impossible à pousser | `.gitignore` dès le premier commit |

---

## 10. À vous de jouer

### Exercice 1 : un générateur de projet

*Objectif : un script qui crée la structure standard.*
Écrivez `~/bin/nouveau_projet.sh NOM`, qui crée dans le dossier courant
l'arborescence de la section 3, un `README.md` minimal contenant le nom du
projet et la date, un `.gitignore` adapté, et qui initialise un dépôt Git
avec un premier commit. Le script doit refuser d'écraser un dossier
existant.

<details>
<summary>Corrigé</summary>

```bash
#!/bin/bash
# Crée l'arborescence standard d'un projet de bioinformatique.
# Usage : nouveau_projet.sh NOM_DU_PROJET
set -euo pipefail

[ $# -eq 1 ] || { echo "Usage : $0 NOM_DU_PROJET" >&2; exit 1; }
nom=$1
[ ! -e "$nom" ] || { echo "Erreur : $nom existe déjà" >&2; exit 1; }

mkdir -p "$nom"/{data/{raw,reference,metadata},envs,scripts,results,logs}

cat > "$nom/README.md" << FIN
# $nom

Créé le $(date +%Y-%m-%d) par $USER.

## Question

## Données

## Reproduire l'analyse

## Résultats

## Journal
FIN

printf 'data/raw/\ndata/reference/\nresults/\nlogs/\n*.fastq.gz\n*.bam\n' > "$nom/.gitignore"

cd "$nom"
git init -q
git add README.md .gitignore
git commit -q -m "Crée la structure du projet"
echo "Projet $nom créé dans $(pwd)"
```

```bash
chmod u+x ~/bin/nouveau_projet.sh
cd ~/formation_linux
nouveau_projet.sh projet_amr_2026
ls -F projet_amr_2026
```

```text
Projet projet_amr_2026 créé dans /home/marie/formation_linux/projet_amr_2026
README.md  data/  envs/  logs/  results/  scripts/
```

`cat > fichier << FIN … FIN` (un *here-document*) écrit plusieurs lignes
d'un coup dans un fichier ; les variables comme `$nom` et `$(date …)` y sont
remplacées. `data/metadata/` n'est pas dans le `.gitignore` : la feuille
d'échantillons doit être versionnée.
</details>

### Exercice 2 : ranger le projet 2

*Objectif : appliquer l'organisation à un vrai travail.*
Avec `nouveau_projet.sh`, créez `qc_run_2026-10-14`. Placez-y :
des **liens** vers les FASTQ du run dans `data/raw/`, une copie de la
feuille dans `data/metadata/`, `formation_partie1.yml` dans `envs/`, et
`qc_run.sh` dans `scripts/`. Écrivez `scripts/run_all.sh`, qui lance le QC
et écrit dans `results/01_qc/`. Lancez l'analyse, vérifiez que `git status`
ne montre que des fichiers à versionner, et commitez.

<details>
<summary>Corrigé</summary>

```bash
cd ~/formation_linux
nouveau_projet.sh qc_run_2026-10-14
cd qc_run_2026-10-14
ln -s ~/formation_linux/run_sequencage/fastq/* data/raw/
cp ~/formation_linux/run_sequencage/echantillons.tsv data/metadata/
cp ~/Linux-command/envs/formation_partie1.yml envs/environment.yml
cp ~/formation_linux/qc_run.sh scripts/
nano scripts/run_all.sh
```

`scripts/run_all.sh` :

```bash
#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p logs
bash scripts/qc_run.sh --run data/raw --feuille data/metadata/echantillons.tsv --sortie results/01_qc 2>&1 | tee logs/01_qc.log
```

```bash
bash scripts/run_all.sh
git status --short
git add envs scripts data/metadata
git commit -m "Ajoute le pipeline de QC et ses entrées"
```

`git status --short` ne montre que `?? data/`, `?? envs/` et `?? scripts/`.
Dans `data/`, seul `metadata/` est pris en compte : les liens de
`data/raw/`, ainsi que `results/` et `logs/`, sont ignorés. Le projet
contient tout ce qu'il faut pour être rejoué, et rien de superflu dans Git.
</details>

---

## 11. Défi : la reproductibilité à l'épreuve

Prouvez que le projet de l'exercice 2 est **reproductible** :

1. supprimez entièrement `results/` et `logs/` ;
2. relancez **uniquement** `bash scripts/run_all.sh`, depuis un autre
   dossier que la racine du projet ;
3. montrez que le nouveau `results/01_qc/qc_echantillons.tsv` est
   **identique** à celui d'avant la suppression.

<details>
<summary>Indice</summary>

Avant de supprimer, mettez de côté l'empreinte du fichier avec `md5sum`.
</details>

<details>
<summary>Corrigé</summary>

```bash
cd ~/formation_linux/qc_run_2026-10-14
md5sum results/01_qc/qc_echantillons.tsv > /tmp/empreinte_qc.txt
rm -r results logs
cd /tmp
bash ~/formation_linux/qc_run_2026-10-14/scripts/run_all.sh > /dev/null 2>&1
cd ~/formation_linux/qc_run_2026-10-14
md5sum -c /tmp/empreinte_qc.txt
```

```text
results/01_qc/qc_echantillons.tsv: OK
```

Le même script, les mêmes données et le même environnement donnent
**exactement** le même résultat, octet pour octet. C'est la définition
pratique de la reproductibilité. Seul le journal diffère, à cause de
l'horodatage, ce qui est normal.
</details>

---

## L'essentiel

```text
data/raw (lecture seule) · data/reference · data/metadata · envs · scripts · results · logs · README.md
Précieux = données brutes, scripts, métadonnées, environnement, README
Régénérable = results/, logs/, fichiers intermédiaires
Tout résultat vient d'un script ; chemins relatifs à la racine ; chaque étape dans son dossier
Git : scripts, métadonnées, envs, README    .gitignore : data/raw, data/reference, results, logs
run_all.sh : cd "$(dirname "$0")/.." puis les étapes dans l'ordre, avec journaux
Données brutes : 2 copies, 2 supports, 1 hors site, vérifiées par md5sum
```

### Auto-évaluation

- [ ] Je crée l'arborescence d'un projet en une commande.
- [ ] Je sais ce qui est précieux, ce qui se régénère, et ce qui va dans Git.
- [ ] Mes données brutes sont en lecture seule ou référencées par des liens.
- [ ] Mon projet a un README qui explique comment le reproduire.
- [ ] J'ai supprimé les résultats d'un projet et je les ai régénérés à l'identique.

## Pour aller plus loin

- Noble W. S. (2009), « A Quick Guide to Organizing Computational Biology Projects », *PLOS Computational Biology* 5(7):e1000424, DOI [10.1371/journal.pcbi.1000424](https://doi.org/10.1371/journal.pcbi.1000424)
- Wilson G. *et al.* (2017), « Good enough practices in scientific computing », *PLOS Computational Biology* 13(6):e1005510, DOI [10.1371/journal.pcbi.1005510](https://doi.org/10.1371/journal.pcbi.1005510)
- Wilkinson M. D. *et al.* (2016), « The FAIR Guiding Principles for scientific data management and stewardship », *Scientific Data* 3:160018, DOI [10.1038/sdata.2016.18](https://doi.org/10.1038/sdata.2016.18)

**Prochaine étape** : [Projet 3 — Du gène au variant](../projet3_du_gene_au_variant/README.md).
