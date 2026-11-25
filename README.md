# Linux-command — Linux et bioinformatique pour biologistes

[![tests](https://github.com/DEDJIABDOUL/Linux-command/actions/workflows/tests.yml/badge.svg)](https://github.com/DEDJIABDOUL/Linux-command/actions/workflows/tests.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Une formation complète, progressive et pratique pour les étudiants en
biologie, génomique et bioinformatique qui n'ont **jamais utilisé la ligne
de commande**. Du premier `ls` jusqu'à une analyse de variants reproductible
exécutée sur un serveur, chaque notion est expliquée, démontrée sur des
données biologiques, et accompagnée d'exercices corrigés.

## Pour qui ?

- Étudiants en biologie sans aucune expérience de programmation.
- Personnes qui découvrent Linux.
- Futurs bioinformaticiens qui veulent devenir autonomes.
- Utilisateurs qui connaissent quelques commandes sans vraiment comprendre
  leur fonctionnement.

**Aucun prérequis.** Il faut seulement un ordinateur : Windows (avec WSL),
macOS ou Linux.

## Commencer en trois commandes

Suivez le [chapitre 00](partie1_linux/00_bienvenue_installation/README.md)
pour installer Linux si nécessaire, puis, dans un terminal Ubuntu :

```bash
git clone https://github.com/DEDJIABDOUL/Linux-command.git ~/Linux-command
bash ~/Linux-command/setup.sh
cd ~/formation_linux
```

Vous disposez alors de votre **bac à sable** : une copie des données
d'exercice, que vous pouvez abîmer sans risque et recréer en une commande
(`bash ~/Linux-command/setup.sh --reset`).

## Le parcours

### [Partie I — Linux pour biologistes](partie1_linux/README.md)

| Bloc | Chapitres |
|---|---|
| **A · Premiers pas** | 00 installation · 01 premier contact · 02 système de fichiers · 03 gérer fichiers et dossiers · 04 lire et inspecter (FASTA, FASTQ) |
| **B · La puissance d'Unix** | 05 flux, redirections et pipes · 06 chercher et filtrer · 07 awk et sed · ★ projet 1 : inventaire d'un run de séquençage |
| **C · Le système autour de vous** | 08 permissions · 09 processus et tmux · 10 environnement du shell · 11 installer des logiciels (Conda, Bioconda) |
| **D · Automatiser, travailler en professionnel** | 12-13 scripts Bash · ★ projet 2 : pipeline de QC · 14 SSH · 15 Git · 16 formats biologiques en pratique · 17 organiser un projet · ★ projet 3 : du gène au variant · ★ projet de synthèse |

Chaque chapitre suit la même trame : pourquoi apprendre la notion, une image
pour la comprendre, des démonstrations avec leurs **sorties réelles**, les
pièges fréquents, des exercices **corrigés**, un défi et un aide-mémoire.
Annexes : administration système, aide-mémoire, glossaire, lecture des
messages d'erreur.

### [Partie II — Bioinformatique appliquée](partie2_bioinfo/README.md)

Modules 18 à 36 : acquisition de données publiques, contrôle qualité,
trimming, assemblage, alignement, annotation, RNA-seq, ChIP-seq,
méthylation, GWAS, protéomique, métagénomique, variant calling, R et
Python, workflows (Snakemake, Nextflow), conteneurs, HPC, ainsi que deux
projets sur données réelles. *Ces modules n'ont pas encore été refondus
selon la charte de la Partie I.*

## Organisation du dépôt

| Emplacement | Contenu |
|---|---|
| [`partie1_linux/`](partie1_linux/README.md) | la Partie I : chapitres, projets, annexes |
| [`partie2_bioinfo/`](partie2_bioinfo/README.md) | la Partie II : modules 18 à 36 |
| [`projects/`](projects/README.md) | projets de la Partie II sur données réelles (Snakemake) |
| [`data/`](data/README.md) | données d'exercice synthétiques (run Illumina simulé, mini-génome annoté, fichiers pièges) |
| [`setup.sh`](setup.sh) | crée ou remet à neuf le bac à sable `~/formation_linux` |
| [`envs/`](envs/) | environnements conda : `formation_partie1.yml` pour la Partie I, un fichier par domaine pour la Partie II |
| [`scripts/`](scripts/README.md) | scripts d'exemple, dont un modèle de pipeline paramétrable |
| [`tests/`](tests/) | tests automatiques : chaque résultat annoncé dans le cours est vérifié |
| [`tools/`](tools/) | générateurs des données d'exercice et de l'aide-mémoire |
| [`docs/`](docs/) | [charte pédagogique](docs/charte_pedagogique.md), [référence des outils](docs/tools_reference.md), [documents de maintenance](docs/maintenance/) |
| [`legacy/`](legacy/README.md) | versions précédentes du cours, conservées pour référence |

## Un cours testé

Toutes les sorties montrées dans la Partie I ont été obtenues réellement sur
Ubuntu 24.04, et la suite `tests/run_all.sh` les vérifie à chaque
modification (GitHub Actions) : comptages, résultats des exercices, et
solutions complètes des projets, extraites telles quelles des pages du cours
et exécutées. Pour lancer les tests en local :

```bash
mamba env create -f envs/ci_tests.yml
conda activate ci_tests
bash tests/run_all.sh
```

## Contribuer

Les contributions suivent la [charte de rédaction](docs/charte_pedagogique.md) :
vouvoiement, sorties réelles, aucune notion utilisée avant d'être
expliquée, exercices corrigés, et un test pour chaque résultat annoncé.

## Licence

Publié sous licence [MIT](LICENSE) : réutilisation, modification et
redistribution libres, y compris à des fins commerciales, à condition de
conserver la mention de copyright et la licence.
