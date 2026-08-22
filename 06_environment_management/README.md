============================================================
MODULE 06 — GESTION DES ENVIRONNEMENTS : CONDA, MAMBA, BIOCONDA
============================================================

OBJECTIVE
------------------------------------------------------------
Comprendre pourquoi la reproductibilité scientifique exige des
environnements logiciels isolés et versionnés, et savoir créer, activer,
documenter et partager de tels environnements avec Conda/Mamba et le
canal Bioconda.

PREREQUISITES
------------------------------------------------------------
`01_linux_basics/` (notamment `$PATH`, section 7).

WHY?
------------------------------------------------------------
Deux personnes qui exécutent « le même » pipeline avec des versions
différentes d'un outil peuvent obtenir des résultats différents, parfois
silencieusement. Un environnement Conda fige un ensemble cohérent de
logiciels et de leurs dépendances, listable et partageable dans un
fichier texte (`environment.yml`) — condition nécessaire (mais non
suffisante à elle seule) à la reproductibilité (voir aussi
`legacy/installation_and_execution.txt`, qui illustre a contrario les
risques d'un environnement mal documenté).

---

# 1. Conda, Mamba, Miniforge, Bioconda : de quoi parle-t-on ?

```text
Conda       gestionnaire de paquets ET d'environnements, multi-langage
            (pas seulement Python), créé par Anaconda Inc.
Mamba       réimplémentation de Conda en C++, résolution de dépendances
            beaucoup plus rapide, interface en ligne de commande
            quasi identique (on peut littéralement remplacer `conda` par
            `mamba` dans la plupart des commandes).
Miniforge   distribution minimale qui installe conda + mamba avec
            conda-forge comme canal par défaut (pas le canal `defaults`
            d'Anaconda) — c'est la méthode d'installation actuellement
            recommandée par la documentation Bioconda (voir avertissement
            section 2).
Bioconda    un CANAL de paquets (pas un logiciel séparé) hébergeant des
            milliers d'outils bioinformatiques installables via conda/mamba.
```

```text
DOCUMENTATION:
  Conda (guide officiel)   — https://docs.conda.io/projects/conda/en/stable/
  Mamba (guide officiel)   — https://mamba.readthedocs.io/
  Miniforge (dépôt source) — https://github.com/conda-forge/miniforge
  Bioconda (guide officiel)— https://bioconda.github.io/
```

---

# 2. Installation — méthode actuellement recommandée

```text
AVERTISSEMENT DE MISE À JOUR (par rapport au fichier legacy/installation_and_execution.txt) :
ce fichier hérité de ce dépôt installe Miniconda puis exécute
`conda config --add channels defaults`. Depuis août 2024, la
documentation officielle Bioconda NE recommande PLUS l'usage du canal
`defaults` (lié aux conditions d'utilisation commerciales d'Anaconda) et
préconise à la place `conda-forge` + `bioconda` avec une priorité de
canal stricte, en installant de préférence Miniforge plutôt que
Miniconda classique. Source vérifiée : https://bioconda.github.io/
```

## 2.1 Installer Miniforge (Linux)

```bash
curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
bash "Miniforge3-$(uname)-$(uname -m).sh"
```

## 2.2 Configurer les canaux (méthode recommandée actuelle)

```bash
conda config --add channels bioconda
conda config --add channels conda-forge
conda config --set channel_priority strict
```

```text
INTERPRETATION: `channel_priority strict` évite les mélanges incohérents
         de versions entre canaux — Bioconda recommande explicitement ce
         réglage.
COMMON ERRORS: ajouter `defaults` par habitude (vu dans d'anciens
         tutoriels, y compris dans legacy/installation_and_execution.txt)
         — à éviter dans une configuration créée aujourd'hui.
DOCUMENTATION: https://bioconda.github.io/ (section « Set up channels »)
```

---

# 3. Créer et gérer un environnement

```text
COMMAND: conda create -n bioinfo
PURPOSE: créer un environnement isolé nommé « bioinfo », vide au départ.
SYNTAX: conda create -n nom [paquet=version ...]
OPTIONS: -n nom donne un nom explicite (alternative : -p chemin pour un
         emplacement personnalisé)
DOCUMENTATION: https://docs.conda.io/projects/conda/en/stable/commands/create.html
EXERCISE: créer un environnement nommé "bioinfo_intro" contenant seqkit :
```
```bash
conda create -n bioinfo_intro -c bioconda -c conda-forge seqkit
```

```text
COMMAND: conda activate / conda deactivate
PURPOSE: rendre actif (ou quitter) un environnement — modifie
         temporairement $PATH pour donner priorité aux exécutables de
         l'environnement (voir 01_linux_basics/, section 7).
SYNTAX: conda activate nom_environnement
        conda deactivate
DOCUMENTATION: https://docs.conda.io/projects/conda/en/stable/commands/activate.html
EXERCISE: activer bioinfo_intro, vérifier `which seqkit`, puis désactiver
         et vérifier que `which seqkit` ne retourne plus rien.
```

```text
COMMAND: conda list / conda env list / conda env export
PURPOSE: lister respectivement les paquets d'un environnement actif, tous
         les environnements existants, et exporter la définition complète
         d'un environnement dans un fichier réutilisable.
SYNTAX: conda list
        conda env list
        conda env export -n bioinfo_intro > envs/bioinfo_intro.yml
DOCUMENTATION: https://docs.conda.io/projects/conda/en/stable/commands/index.html
EXERCISE: exporter l'environnement créé plus haut et examiner le fichier
         YAML obtenu — comparer avec envs/core_tools.yml (section 4).
```

---

# 4. Environnements documentés du dépôt

Le dossier `envs/` centralise les définitions d'environnements par
domaine (pas un fichier par outil isolé — voir la charte du dépôt).
`envs/core_tools.yml` couvre les outils génériques de manipulation
FASTA/FASTQ utilisés dans les modules 02-05 (SeqKit). `envs/qc.yml`
(FastQC, MultiQC, NanoPlot) et `envs/trimming.yml` (Cutadapt, fastp,
chopper) couvrent respectivement les modules `09_quality_control/` et
`10_adapter_trimming_filtering/`. D'autres environnements par domaine
(assemblage, alignement...) seront ajoutés au fil des modules suivants.
Chaque fichier `.yml` documente lui-même, en commentaire d'en-tête, son
objectif, les outils inclus, la politique de version, l'installation et
l'usage — pas de fichier `.md` séparé par environnement.

```text
DOCUMENTATION SeqKit:
  Site officiel — https://bioinf.shenwei.me/seqkit/
  Dépôt source  — https://github.com/shenwei356/seqkit
EXERCISE: installer envs/core_tools.yml et vérifier :
```
```bash
conda env create -f envs/core_tools.yml
conda activate core_tools
seqkit version
seqkit stats linux/*.fasta linux/*.fastq linux/*.fastq.gz
```

---

# 5. Mamba — accélérer la résolution de dépendances

```bash
mamba create -n bioinfo_intro -c bioconda -c conda-forge seqkit
mamba env create -f envs/core_tools.yml
```

```text
INTERPRETATION: mamba utilise les mêmes fichiers d'environnement et la
         même syntaxe que conda — c'est un accélérateur, pas un
         changement de paradigme. Installer mamba dans l'environnement de
         base (Miniforge l'inclut déjà par défaut).
DOCUMENTATION: https://mamba.readthedocs.io/
```

---

TROUBLESHOOTING
------------------------------------------------------------
```text
SYMPTOM: "CondaError" ou blocage très long lors d'un `conda install`/
         `conda create`
CAUSE: résolution de dépendances lente, souvent aggravée par la présence
       du canal `defaults` en conflit avec conda-forge/bioconda.
DIAGNOSIS: vérifier les canaux configurés (`conda config --show channels`).
SOLUTION: retirer `defaults` (`conda config --remove channels defaults`),
          fixer `channel_priority strict`, ou utiliser mamba.
PREVENTION: suivre la configuration de la section 2 dès la création d'un
            nouvel environnement.
```
```text
SYMPTOM: `which seqkit` (ou tout autre outil) ne retourne rien après
         installation
CAUSE: l'environnement contenant l'outil n'est pas activé.
DIAGNOSIS: `conda env list` (repérer l'astérisque marquant l'environnement
           actif) et `echo $CONDA_DEFAULT_ENV`.
SOLUTION: `conda activate nom_environnement`
PREVENTION: toujours vérifier l'environnement actif avant de lancer un
            pipeline, en particulier dans un script (voir
            04_bash_scripting/, section sur la robustesse).
```

GO FURTHER
------------------------------------------------------------
```text
Topic: gestion d'environnements reproductibles
Official documentation:
  https://docs.conda.io/projects/conda/en/stable/
  https://mamba.readthedocs.io/
  https://bioconda.github.io/
Topics to explore: environnements verrouillés (lock files), Micromamba
                    (variante ultra-légère sans dépendance Python),
                    intégration avec Snakemake/Nextflow (phases ultérieures)
```

DOCUMENTATION
------------------------------------------------------------
- Conda — https://docs.conda.io/projects/conda/en/stable/
- Mamba — https://mamba.readthedocs.io/
- Miniforge — https://github.com/conda-forge/miniforge
- Bioconda — https://bioconda.github.io/
- SeqKit — https://bioinf.shenwei.me/seqkit/ · source : https://github.com/shenwei356/seqkit

SCIENTIFIC REFERENCES
------------------------------------------------------------
- Grüning B et al. (2018). "Bioconda: sustainable and comprehensive
  software distribution for the life sciences." Nature Methods,
  15:475-476. DOI: 10.1038/s41592-018-0046-7

RESSOURCE LIÉE
------------------------------------------------------------
`legacy/installation_and_execution.txt` — exemple historique
d'installation d'environnement à but pédagogique : comparer sa méthode
(canal `defaults`, versions figées anciennes) à celle recommandée dans ce
module, comme exercice de sens critique.

NEXT MODULE
------------------------------------------------------------
`07_project_organization/` — structurer un projet bioinformatique
complet à partir des environnements créés ici.
