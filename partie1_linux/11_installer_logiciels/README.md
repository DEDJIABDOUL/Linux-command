# Chapitre 11 — Installer des logiciels : apt, Conda, Mamba et Bioconda

> **Durée estimée** : 2 h (dont une partie de téléchargements)
> **Prérequis** : [chapitre 10](../10_environnement_shell/README.md)
> **Chapitre suivant** : [12 — Scripts Bash (I)](../12_scripts_bash_1/README.md)

## Ce que vous saurez faire à la fin de ce chapitre

- Distinguer les différentes façons d'installer un logiciel, et savoir
  laquelle choisir.
- Installer un outil système avec `apt` sur votre propre machine.
- Installer **Miniforge** (conda + mamba) et configurer les canaux
  **conda-forge** et **Bioconda**.
- Créer, activer, compléter, exporter et supprimer des **environnements**.
- Recréer à l'identique un environnement à partir d'un fichier
  `environment.yml`, la base de la reproductibilité.

---

## 1. Pourquoi

Les outils de bioinformatique se comptent par milliers, chacun avec ses
dépendances et ses versions. Deux problèmes se posent en permanence :

1. **Les droits** : sur un serveur, vous n'avez pas `sudo` (chapitre 08),
   et vous ne pouvez pas installer de logiciel dans le système.
2. **Les conflits et la reproductibilité** : le projet A a besoin de
   samtools 1.17, le projet B de samtools 1.25. Et dans un an, vous devrez
   pouvoir dire, et recréer, la version exacte de chaque outil utilisé pour
   votre article.

**Conda** résout les deux : il installe les logiciels **dans votre dossier
personnel**, sans droits administrateur, et dans des **environnements**
isolés, décrits dans un simple fichier texte.

---

## 2. Une image pour comprendre : les armoires de réactifs

| Au laboratoire | Logiciels |
|---|---|
| le magasin central de l'institut, géré par la logistique | le système, géré par `apt` (droits administrateur) |
| une armoire de réactifs **par projet**, avec ses lots et numéros de lot | un **environnement conda** par projet, avec ses outils et leurs versions |
| les fournisseurs | les **canaux** : conda-forge (outils généraux), Bioconda (outils de bioinformatique) |
| la liste des réactifs et numéros de lot dans le cahier de manip | le fichier `environment.yml` |

Ouvrir l'armoire du projet A ne mélange pas ses réactifs avec ceux du
projet B. **Activer** un environnement, c'est ouvrir son armoire.

---

## 3. Les façons d'installer un logiciel

| Méthode | Où ? | Droits | Quand l'utiliser |
|---|---|---|---|
| **apt** | dans le système (`/usr/bin`) | `sudo` | outils système de **votre** machine : `tree`, `htop`, `git` |
| **conda / mamba** | dans votre dossier personnel | aucun | **les outils scientifiques**, sur votre machine comme sur un serveur |
| **modules** du cluster (`module load`) | installés par les administrateurs | aucun | sur un cluster qui les propose (module 36 de la Partie II) |
| **conteneurs** (Apptainer, Docker) | une image contenant l'outil et tout son système | variable | pipelines, reproductibilité maximale (module 35) |
| binaire téléchargé, `pip`, compilation | variable | aucun | quand l'outil n'existe nulle part ailleurs |

**Règle pratique pour ce cours** : `apt` pour le système, **conda pour
tout le reste**.

---

## 4. `apt` : les logiciels du système (sur votre machine)

```bash
sudo apt update
sudo apt install tree htop
```

- `apt update` met à jour la **liste** des logiciels disponibles ; il
  n'installe rien. Faites-le avant d'installer.
- `apt install` installe les paquets demandés et leurs dépendances.
- `apt search mot` cherche un paquet, `apt show paquet` le décrit,
  `sudo apt upgrade` met à jour tout le système.

Sans `sudo`, `apt` refuse :

```text
E: Could not open lock file /var/lib/dpkg/lock-frontend - open (13: Permission denied)
E: Unable to acquire the dpkg frontend lock (/var/lib/dpkg/lock-frontend), are you root?
```

Vous pouvez maintenant utiliser `tree` (chapitre 02) et `htop`
(chapitre 09).

> **Pourquoi pas `apt install samtools` ?** Le paquet existe, mais dans
> **une seule** version, souvent ancienne, imposée à tout le système, et
> impossible à installer sur un serveur sans droits. Les outils
> scientifiques s'installent avec conda.

---

## 5. Installer Miniforge

**Miniforge** est la distribution recommandée par la documentation
Bioconda : elle installe `conda` et `mamba`, préconfigurés sur le canal
libre **conda-forge**.

> **Sous Windows**, ces commandes se tapent **dans Ubuntu (WSL)**. Bioconda
> ne fournit pas de paquets pour Windows. **Sous macOS**, la même procédure
> fonctionne : le script téléchargé correspond automatiquement à votre
> processeur (Intel ou Apple Silicon).

```bash
cd ~
curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
bash Miniforge3-$(uname)-$(uname -m).sh
```

`$(uname)` et `$(uname -m)` (chapitre 05) donnent votre système et votre
processeur, par exemple `Linux` et `x86_64` : le bon installateur est
téléchargé automatiquement.

L'installateur pose des questions :

1. il affiche la licence : **Entrée**, puis **q** pour sortir de
   l'afficheur, puis `yes` ;
2. il propose un dossier d'installation (`/home/marie/miniforge3`) :
   **Entrée** pour accepter ;
3. il demande s'il doit initialiser conda dans votre shell (*conda init*) :
   répondez **`yes`**.

**Fermez le terminal et ouvrez-en un nouveau.** L'installateur a ajouté des
lignes à votre `~/.bashrc` (chapitre 10), qui ne s'appliquent qu'aux
nouveaux terminaux. Votre invite commence maintenant par `(base)` :

```text
(base) marie@PC-LABO:~$
```

Vérifiez :

```bash
conda --version
mamba --version
```

```text
conda 26.9.4
2.9.0
```

Les numéros de version seront peut-être plus récents chez vous.

### Configurer les canaux

Une seule fois, réglez les canaux comme le recommande Bioconda :

```bash
conda config --add channels bioconda
conda config --add channels conda-forge
conda config --set channel_priority strict
conda config --show channels channel_priority
```

```text
channel_priority: strict
channels:
  - conda-forge
  - bioconda
```

`conda-forge` passe en premier et `bioconda` en second, avec une priorité
**stricte** : quand un paquet existe sur les deux canaux, il est pris sur
le premier, ce qui évite des mélanges incohérents. Ces réglages sont
enregistrés dans `~/.condarc`.

> **N'ajoutez pas le canal `defaults`**, que vous verrez dans d'anciens
> tutoriels : Bioconda ne le recommande plus. Il est soumis aux conditions
> commerciales d'Anaconda, et son mélange avec conda-forge provoque des
> conflits.

---

## 6. Les environnements

### 6.1 L'environnement `base` n'est pas un lieu de travail

`(base)` est l'environnement qui contient conda lui-même. **N'y installez
pas vos outils** : une mise à jour malheureuse pourrait casser conda.
Créez un environnement par projet ou par usage.

### 6.2 Créer, activer, utiliser

```bash
mamba create -n bioinfo_intro seqkit
```

`mamba` fait la même chose que `conda`, plus rapidement et avec un affichage
plus clair ; ses commandes sont identiques. Il calcule les dépendances,
affiche ce qu'il va installer, puis demande confirmation (`Y`). À la fin :

```text
To activate this environment, use

    mamba activate bioinfo_intro
```

```bash
conda activate bioinfo_intro
type seqkit
seqkit version
```

```text
seqkit is /home/marie/miniforge3/envs/bioinfo_intro/bin/seqkit
seqkit v2.14.0
```

L'invite affiche maintenant `(bioinfo_intro)`. Que s'est-il passé ? Comme
annoncé au chapitre 10, conda a placé le dossier `bin/` de l'environnement
**en tête du `PATH`** :

```bash
echo "$PATH" | tr ":" "\n" | head -n 2
```

```text
/home/marie/miniforge3/envs/bioinfo_intro/bin
/home/marie/miniforge3/condabin
```

`conda deactivate` retire ce dossier : `seqkit` redevient introuvable.

### 6.3 Votre premier outil de bioinformatique : SeqKit

SeqKit manipule FASTA et FASTQ, compressés ou non, en gérant correctement
les séquences repliées sur plusieurs lignes :

```bash
cd ~/formation_linux
seqkit stats genome.fasta reads.fastq sample_01.fastq.gz
```

```text
file                format  type  num_seqs  sum_len  min_len  avg_len  max_len
genome.fasta        FASTA   DNA         22   23,718       45  1,078.1    4,800
reads.fastq         FASTQ   DNA        500   49,603       76     99.2      100
sample_01.fastq.gz  FASTQ   DNA      1,200  119,065       73     99.2      100
```

En une commande, vous retrouvez les résultats des chapitres 05 à 07 :
22 séquences, 23 718 bases, 500 reads, une longueur moyenne de 99,2 pb.

Et la limite de `grep` (chapitre 06), le motif coupé par le repliement des
lignes, disparaît :

```bash
seqkit locate -p ATGCGT pieges/motif_coupe.fasta
```

```text
seqID	patternName	pattern	strand	start	end	matched
sequence_piege	ATGCGT	ATGCGT	+	11	16	ATGCGT
sequence_piege	ATGCGT	ATGCGT	+	37	42	ATGCGT
sequence_piege	ATGCGT	ATGCGT	+	118	123	ATGCGT
```

Les **trois** occurrences sont trouvées, avec leur position, y compris celle
à cheval sur deux lignes (positions 118 à 123). Pour les séquences,
utilisez un outil fait pour les séquences.

### 6.4 Compléter, lister, supprimer

| Commande | Effet |
|---|---|
| `conda env list` | la liste des environnements ; `*` marque l'environnement actif |
| `mamba install -n env outil` | ajoute un outil à un environnement existant |
| `conda list` | les paquets de l'environnement actif, avec leur version |
| `mamba search outil` | les versions disponibles |
| `mamba create -n env outil=1.21` | une version **précise** |
| `conda env remove -n env` | supprime un environnement |

---

## 7. La reproductibilité : le fichier `environment.yml`

### 7.1 Décrire un environnement

Un environnement se décrit dans un fichier YAML. Voici celui de la Partie I
de ce cours, `~/Linux-command/envs/formation_partie1.yml` :

```yaml
name: formation_partie1
channels:
  - conda-forge
  - bioconda
dependencies:
  - seqkit=2.14.0
  - samtools=1.25
  - bcftools=1.25
  - bedtools=2.31.1
  - shellcheck=0.11.0
```

Les versions y sont **figées** (`=2.14.0`) : ce sont celles avec lesquelles
toutes les sorties du cours ont été vérifiées. N'importe qui peut recréer
exactement le même environnement :

```bash
mamba env create -f ~/Linux-command/envs/formation_partie1.yml
conda activate formation_partie1
samtools --version | head -n 1
```

```text
samtools 1.25
```

**Créez-le maintenant** : il servira aux chapitres 13 et 16, et aux projets.

> **Le format YAML** est sensible à l'**indentation** : les tirets des
> listes doivent être alignés, avec des espaces et non des tabulations.

### 7.2 Exporter un environnement existant

```bash
conda env export --from-history -n bioinfo_intro
```

```text
name: bioinfo_intro
channels:
  - conda-forge
dependencies:
  - seqkit
prefix: /home/marie/miniforge3/envs/bioinfo_intro
```

`--from-history` n'exporte que ce que **vous** avez demandé, sans les
dizaines de dépendances. Deux corrections sont nécessaires avant de partager
ce fichier :

- **le canal `bioconda` manque** : il est absent de la liste, alors que
  seqkit vient de Bioconda. Ajoutez-le à la main ;
- **la version n'est pas figée** : ajoutez-la (`seqkit=2.14.0`, d'après
  `conda list`), et retirez la ligne `prefix:`, propre à votre machine.

Sans `--from-history`, `conda env export` liste **tous** les paquets avec
leur version exacte et leur numéro de build. C'est la description la plus
précise, mais elle est spécifique à votre système d'exploitation.

> **Bon réflexe de projet** : un fichier `environment.yml`, avec des versions
> figées, versionné avec vos scripts (chapitre 15). C'est ce que fait le
> dossier `envs/` de ce dépôt, qui contient un environnement par domaine pour
> la Partie II.

---

## 8. En bioinformatique

- **Un environnement par projet ou par domaine** (contrôle qualité,
  alignement…), jamais tout dans un seul : plus il y a d'outils, plus les
  conflits de dépendances sont probables.
- **Dans un script**, activez l'environnement explicitement
  (chapitre 12) : un script ne doit pas dépendre de l'environnement qui
  était actif dans votre terminal.
- **Sur un cluster**, conda s'installe de la même façon, dans votre dossier
  personnel. Certains clusters proposent aussi `module avail` et
  `module load samtools/1.25` (module 36), voire interdisent conda dans le
  dossier personnel à cause des quotas : lisez la documentation du centre.
- **Citez les versions** dans la partie Méthodes de vos rapports et
  articles : `conda list` vous les donne.

---

## 9. Pièges fréquents

| Message ou symptôme | Cause | Solution |
|---|---|---|
| `conda: command not found` après l'installation | le terminal n'a pas relu `.bashrc` | ouvrir un nouveau terminal ; sinon `~/miniforge3/bin/conda init`, puis rouvrir |
| `seqkit: command not found` | l'environnement n'est pas activé | `conda activate bioinfo_intro` ; vérifier avec `conda env list` |
| `EnvironmentNameNotFound: Could not find conda environment: …` | faute de frappe, ou environnement non créé | `conda env list` |
| `PackagesNotFoundInChannelsError` | nom de paquet erroné, ou canal `bioconda` absent | vérifier le nom sur <https://bioconda.github.io> ; `conda config --show channels` |
| résolution des dépendances très longue ou en échec | trop d'outils, versions incompatibles, canal `defaults` présent | `mamba` ; environnements plus petits ; retirer `defaults` |
| un outil marchait, il ne marche plus après une installation | une dépendance a changé de version | un environnement par projet ; recréer depuis le fichier `.yml` |
| `apt` : `are you root?` | `apt install` sans `sudo` | `sudo apt install …`, et seulement sur votre machine |
| outils installés dans `(base)` | — | les réinstaller dans un environnement dédié |

---

## 10. À vous de jouer

### Exercice 1 : installer et vérifier

*Objectif : un environnement de bout en bout.*
Si ce n'est pas déjà fait, installez Miniforge, configurez les canaux, et
créez l'environnement de la formation à partir de son fichier. Vérifiez les
versions de seqkit, samtools et bedtools.

<details>
<summary>Corrigé</summary>

```bash
mamba env create -f ~/Linux-command/envs/formation_partie1.yml
conda activate formation_partie1
seqkit version
samtools --version | head -n 1
bedtools --version
```

```text
seqkit v2.14.0
samtools 1.25
bedtools v2.31.1
```
</details>

### Exercice 2 : SeqKit sur le run

*Objectif : utiliser un outil Bioconda sur des données réelles du cours.*
Avec l'environnement `formation_partie1` actif, obtenez en **une seule
commande** les statistiques de tous les fichiers R1 du run. Retrouvez-vous
les nombres de reads du projet 1 ?

<details>
<summary>Corrigé</summary>

```bash
cd ~/formation_linux
seqkit stats run_sequencage/fastq/*_R1_*.fastq.gz
```

La colonne `num_seqs` donne le nombre de reads : 300 pour P01, 290 pour
P07, 150 pour P09… Les mêmes valeurs qu'au projet 1, obtenues en une ligne.
</details>

### Exercice 3 : le fichier tronqué vu par SeqKit

*Objectif : constater qu'un outil dédié signale l'erreur.*
Lancez `seqkit stats` sur le R2 de P11. Que se passe-t-il ? Comparez avec
le `zcat | wc -l` du chapitre 05, qui affichait 691 sans s'arrêter.

<details>
<summary>Corrigé</summary>

```bash
seqkit stats run_sequencage/fastq/P11_S11_L001_R2_001.fastq.gz
echo "code : $?"
```

```text
[ERRO] run_sequencage/fastq/P11_S11_L001_R2_001.fastq.gz: unexpected EOF
code : 0
```

SeqKit détecte que le fichier gzip est incomplet et **refuse de produire
une statistique** : aucune ligne de résultat n'est affichée. C'est mieux que
les 691 lignes de `zcat | wc -l`, qui ressemblaient à un vrai résultat.

Mais le code de retour vaut **0**, comme si tout s'était bien passé. Un
script qui ne testerait que `$?` ne verrait rien. Leçon : **lisez les
messages d'erreur**, et vérifiez qu'un résultat attendu a bien été produit
(chapitre 13), plutôt que de vous fier uniquement au code de retour d'un
outil.
</details>

### Exercice 4 : partager son environnement

*Objectif : produire un `environment.yml` correct.*
Créez un environnement `qc_test` contenant `seqkit`, exportez-le avec
`--from-history` dans `qc_test.yml`, corrigez le fichier avec nano (canal
`bioconda`, version figée, ligne `prefix` supprimée), puis supprimez
l'environnement et recréez-le **à partir du fichier**.

<details>
<summary>Corrigé</summary>

```bash
mamba create -n qc_test seqkit
conda env export --from-history -n qc_test > qc_test.yml
conda list -n qc_test seqkit
nano qc_test.yml
```

Fichier corrigé :

```yaml
name: qc_test
channels:
  - conda-forge
  - bioconda
dependencies:
  - seqkit=2.14.0
```

```bash
conda env remove -n qc_test
mamba env create -f qc_test.yml
conda activate qc_test && seqkit version
```
</details>

---

## 11. Défi : installer sans droits administrateur

Sans utiliser `sudo`, rendez disponible la commande `tree` (qui n'est pas
installée sur Ubuntu), puis affichez avec elle l'arborescence de
`~/formation_linux/run_sequencage`. Pourquoi cette méthode fonctionnerait-elle
aussi sur un serveur où vous n'êtes pas administrateur ?

<details>
<summary>Indice</summary>

conda-forge ne contient pas que des outils scientifiques.
</details>

<details>
<summary>Corrigé</summary>

```bash
mamba install -n formation_partie1 tree
conda activate formation_partie1
tree ~/formation_linux/run_sequencage
```

`tree` est installé dans `~/miniforge3/envs/formation_partie1/bin/`,
c'est-à-dire **dans votre dossier personnel**, où vous avez tous les
droits. Rien n'est écrit dans le système, donc aucun droit administrateur
n'est nécessaire : c'est exactement la situation d'un serveur partagé.
`tree -a` montre aussi le fichier caché `.run_termine`.
</details>

---

## L'essentiel

```text
apt (sudo)       outils système de VOTRE machine   sudo apt update ; sudo apt install tree
conda / mamba    outils scientifiques, sans droits, partout
Miniforge : curl -L -O …/Miniforge3-$(uname)-$(uname -m).sh ; bash … ; yes à conda init ; nouveau terminal
conda config --add channels bioconda ; --add channels conda-forge ; --set channel_priority strict
mamba create -n env outil=version     conda activate env     conda deactivate
mamba install -n env outil   conda list   conda env list   conda env remove -n env
mamba env create -f environment.yml   (versions figées = reproductible)
conda env export --from-history > env.yml   → ajouter bioconda, figer les versions, retirer prefix
Activer = mettre env/bin en tête du PATH ; jamais travailler dans (base)
```

### Auto-évaluation

- [ ] Je sais quand utiliser `apt` et quand utiliser conda.
- [ ] J'ai installé Miniforge et configuré conda-forge et Bioconda.
- [ ] Je crée, active, complète et supprime un environnement.
- [ ] J'explique ce que fait `conda activate` au `PATH`.
- [ ] Je recrée un environnement à partir d'un fichier `.yml` avec des versions figées.
- [ ] L'environnement `formation_partie1` est installé et fonctionne.

## Documentation officielle

- Miniforge : <https://github.com/conda-forge/miniforge>
- Bioconda (installation et canaux) : <https://bioconda.github.io/>
- Conda (gestion des environnements) : <https://docs.conda.io/projects/conda/en/stable/user-guide/tasks/manage-environments.html>
- Mamba : <https://mamba.readthedocs.io/>
- SeqKit : <https://bioinf.shenwei.me/seqkit/>
- Grüning B. *et al.* (2018), « Bioconda: sustainable and comprehensive software distribution for the life sciences », *Nature Methods* 15:475-476, DOI [10.1038/s41592-018-0046-7](https://doi.org/10.1038/s41592-018-0046-7)
- Shen W. *et al.* (2016), « SeqKit: A Cross-Platform and Ultrafast Toolkit for FASTA/Q File Manipulation », *PLOS ONE* 11(10):e0163962, DOI [10.1371/journal.pone.0163962](https://doi.org/10.1371/journal.pone.0163962)

**Prochaine étape** : [chapitre 12 — Scripts Bash (I)](../12_scripts_bash_1/README.md).
