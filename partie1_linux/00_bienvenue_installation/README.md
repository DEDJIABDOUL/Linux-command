# Chapitre 00 — Bienvenue : installer votre poste de travail

> **Durée estimée** : 45 minutes à 1 h 30 (selon votre ordinateur)
> **Prérequis** : aucun
> **Chapitre suivant** : [01 — Premier contact avec le terminal](../01_premier_contact/README.md)

## Ce que vous saurez faire à la fin de ce chapitre

- Disposer d'un vrai système Linux (Ubuntu) sur votre ordinateur, quel qu'il soit.
- Ouvrir un terminal et y coller une commande.
- Récupérer ce cours et ses données sur votre machine.
- Créer votre **bac à sable** : un dossier d'exercices que vous pouvez
  abîmer sans aucun risque, et remettre à neuf en une commande.

---

## 1. Bienvenue

Vous êtes biologiste, ou en passe de le devenir, et vous n'avez jamais
utilisé de « ligne de commande ». C'est exactement le public de ce cours.

À la fin de la Partie I, vous saurez explorer des fichiers de séquençage,
filtrer des milliers de lignes d'annotations en une commande, écrire un
script qui traite douze échantillons pendant que vous déjeunez, et
travailler sur un serveur de calcul à distance. Ce sont les compétences
dont dépend tout le reste de la bioinformatique.

### Comment ce cours est construit

Chaque chapitre suit la même logique : **pourquoi** apprendre la notion,
une **image** pour la comprendre, des **démonstrations** dont vous voyez le
résultat réel, des **pièges** fréquents, puis des **exercices corrigés**
et un **défi**. Les exemples portent sur des données biologiques :
séquences, reads, annotations, variants.

### Comment lire les encadrés de commandes

Une commande à taper (ou à copier-coller) apparaît ainsi :

```bash
echo "Bonjour"
```

Le résultat que vous devez obtenir apparaît juste après, annoncé par
« Sortie : » :

```text
Bonjour
```

Si votre résultat diffère, ce n'est pas grave : c'est même souvent
instructif. Les sections « Pièges fréquents » vous aident à comprendre
pourquoi.

---

## 2. Pourquoi Linux, et pourquoi pas Windows ou macOS directement ?

Presque tous les outils de bioinformatique (aligneurs, assembleurs,
appeleurs de variants…) sont écrits **pour Linux**, et les serveurs de
calcul des laboratoires et des universités fonctionnent **sous Linux**.
Apprendre sur Linux dès le départ, c'est apprendre dans l'environnement
où vous travaillerez réellement.

> **Attention aux faux amis.** « Git Bash » sous Windows ressemble à un
> terminal Linux, mais il lui manque des commandes essentielles (`man`,
> `apt`…) et il ne permet pas d'installer les outils Bioconda (chapitre 11).
> **Ne l'utilisez pas pour ce cours.**

---

## 3. Installer Linux : choisissez votre situation

| Votre ordinateur | Solution recommandée | Section |
|---|---|---|
| Windows 10 (version 2004 ou plus récente) ou Windows 11 | WSL2 + Ubuntu | [3.1](#31-sous-windows--wsl2-et-ubuntu) |
| macOS | Le Terminal intégré | [3.2](#32-sous-macos) |
| Déjà sous Linux (Ubuntu, Debian, Fedora…) | Rien à installer | [3.3](#33-déjà-sous-linux) |
| Ordinateur sans droits administrateur (salle informatique, poste d'entreprise) | GitHub Codespaces, dans le navigateur | [3.4](#34-sans-droits-administrateur--github-codespaces) |

### 3.1 Sous Windows : WSL2 et Ubuntu

**WSL** (*Windows Subsystem for Linux*) fait fonctionner un vrai Ubuntu à
l'intérieur de Windows, sans redémarrer sur un autre système.

1. Ouvrez le menu Démarrer, tapez **PowerShell**, faites un clic droit
   sur « Windows PowerShell » puis **Exécuter en tant qu'administrateur**.
2. Copiez la ligne suivante dans la fenêtre bleue, puis appuyez sur Entrée :

   ```powershell
   wsl --install -d Ubuntu-24.04
   ```

3. **Redémarrez l'ordinateur** quand Windows vous le demande.
4. Au redémarrage, une fenêtre Ubuntu s'ouvre et termine l'installation
   (quelques minutes). Elle vous demande ensuite :
   - un **nom d'utilisateur** (*username*) : en minuscules, sans espace
     ni accent, par exemple `marie` ;
   - un **mot de passe**, deux fois.

> **Le mot de passe ne s'affiche pas quand vous le tapez** : ni lettres,
> ni étoiles, rien. C'est normal et voulu sous Linux. Tapez-le à
> l'aveugle, puis appuyez sur Entrée. **Notez-le** : il vous sera
> demandé pour installer des logiciels.

5. Installez **Windows Terminal** depuis le Microsoft Store (il est
   déjà présent sous Windows 11). Il est plus confortable que la fenêtre
   d'origine. Pour ouvrir Ubuntu par la suite : lancez Windows Terminal,
   cliquez sur la flèche ˅ à côté de l'onglet, puis choisissez
   **Ubuntu-24.04**.

**Copier-coller dans Windows Terminal** : sélectionner du texte le copie
avec **Ctrl+Maj+C**, et **Ctrl+Maj+V** (ou un clic droit) le colle. Le simple
Ctrl+C a un autre rôle dans un terminal : vous le découvrirez au chapitre 01.

**Où sont mes fichiers ?**

- Vos fichiers Windows sont visibles depuis Ubuntu sous `/mnt/c/`. Par
  exemple, votre bureau est dans `/mnt/c/Users/VotreNom/Desktop`.
- Vos fichiers Ubuntu sont visibles depuis l'Explorateur Windows, dans
  la rubrique **Linux** du panneau de gauche.

> **Bon réflexe : travaillez dans votre dossier Ubuntu, pas dans `/mnt/c/`.**
> Les disques Windows vus depuis Linux sont plus lents et ne gèrent pas
> correctement les permissions Linux : tous les fichiers y apparaissent
> modifiables et exécutables par tout le monde. Le chapitre 08 vous
> montrera pourquoi c'est un problème. Ce cours vous fait donc travailler
> dans votre dossier personnel Ubuntu.

**Si l'installation échoue :**

| Message | Cause probable | Solution |
|---|---|---|
| Erreur mentionnant la **virtualisation** (souvent le code `0x80370102`) | La virtualisation du processeur est désactivée dans le BIOS/UEFI | Activez « Intel VT-x » ou « AMD-V / SVM » dans le BIOS (cherchez le modèle de votre ordinateur suivi de « activer virtualisation »), ou demandez de l'aide au service informatique |
| `wsl` n'est pas reconnu | Windows trop ancien | Faites les mises à jour Windows, ou utilisez la section 3.4 |
| La fenêtre Ubuntu se ferme aussitôt | Installation incomplète | Dans PowerShell : `wsl --update`, puis relancez Ubuntu |

Documentation officielle : <https://learn.microsoft.com/fr-fr/windows/wsl/install>

### 3.2 Sous macOS

macOS est un système de la famille Unix : son application **Terminal**
(dans Applications > Utilitaires) convient à la plupart des chapitres.

Deux différences à connaître :

- Le shell par défaut de macOS est **zsh**, et non **bash**. Les commandes
  de base sont les mêmes. Pour les chapitres de scripting (12 et 13), vous
  lancerez vos scripts avec `bash script.sh`.
- Certaines commandes de macOS (`sed`, `date`, `zcat`…) sont des versions
  BSD dont les options diffèrent légèrement de celles d'Ubuntu. Le cours
  signale ces différences quand elles comptent. Par exemple, utilisez
  `gzip -dc fichier.gz` à la place de `zcat fichier.gz`.

Si vous voulez un environnement **identique** à celui du cours, utilisez
la section 3.4.

### 3.3 Déjà sous Linux

Ouvrez un terminal (sous Ubuntu : **Ctrl+Alt+T**) et passez à la
section 4.

### 3.4 Sans droits administrateur : GitHub Codespaces

**GitHub Codespaces** fournit une machine Linux complète **dans votre
navigateur**, sans rien installer. Il faut un compte GitHub (gratuit), et
l'usage gratuit est limité à un quota d'heures par mois, largement
suffisant pour ce cours si vous arrêtez la machine après chaque séance.

1. Créez un compte sur <https://github.com>.
2. Ouvrez la page du dépôt <https://github.com/DEDJIABDOUL/Linux-command>.
3. Cliquez sur le bouton vert **Code**, onglet **Codespaces**, puis
   **Create codespace on main**.
4. Un éditeur s'ouvre, avec un terminal en bas de l'écran : c'est votre
   terminal Linux. Le dépôt y est déjà téléchargé : passez directement à
   la section 5, en remplaçant `~/Linux-command` par `/workspaces/Linux-command`.

Documentation officielle : <https://docs.github.com/fr/codespaces>

---

## 4. Récupérer le cours et ses données

Ouvrez votre terminal Ubuntu. Vous voyez une ligne qui ressemble à
ceci, suivie d'un curseur qui clignote :

```text
marie@PC-LABO:~$
```

C'est le terminal qui attend vos instructions. Le chapitre 01 vous
explique en détail ce que signifie cette ligne. Pour l'instant, **copiez
les commandes ci-dessous une par une**, en appuyant sur Entrée après
chacune. Vous comprendrez précisément ce qu'elles font dans les
prochains chapitres.

**Étape 1 : mettre à jour la liste des logiciels et installer Git.**
Votre mot de passe vous sera demandé (et ne s'affichera pas) :

```bash
sudo apt update
sudo apt install -y git
```

Des dizaines de lignes défilent, c'est normal. Si Git est déjà installé,
la dernière ligne l'indique (`git is already the newest version`).

**Étape 2 : télécharger le cours dans votre dossier personnel :**

```bash
cd ~
git clone https://github.com/DEDJIABDOUL/Linux-command.git
```

Sortie (les nombres peuvent varier) :

```text
Cloning into 'Linux-command'...
remote: Enumerating objects: ...
Receiving objects: 100% ...
Resolving deltas: 100% ...
```

---

## 5. Créer votre bac à sable

Le dépôt téléchargé contient les données d'exercice, mais **on n'y
travaille jamais directement** : on en fait une copie de travail, le
**bac à sable**, dans `~/formation_linux`.

```bash
bash ~/Linux-command/setup.sh
```

Sortie (avec votre propre nom d'utilisateur à la place de `marie`) :

```text
Bac à sable prêt : /home/marie/formation_linux
Contenu :
annotations.tsv
exercice_sequences.fasta
formats/
genome.fasta
pieges/
proteins.fasta
reads.fastq
run_sequencage/
sample_01.fastq.gz
sample_02.fastq.gz
sample_03.fastq.gz
transcripts.fasta

Étape suivante : tapez  cd /home/marie/formation_linux  puis suivez le chapitre 01.
```

Vous y trouvez des séquences (`.fasta`), des reads de séquençage
(`.fastq`, `.fastq.gz`), une table d'annotations (`.tsv`), et trois
dossiers : un run de séquençage simulé, des fichiers de formats
biologiques, et des fichiers « pièges » qui serviront à apprendre à
diagnostiquer les problèmes. **Toutes ces données sont synthétiques**,
c'est-à-dire fabriquées pour le cours.

### Le droit à l'erreur

Dans `~/formation_linux`, vous pouvez supprimer, écraser ou modifier
n'importe quel fichier : **c'est fait pour ça**. Si tout est cassé :

```bash
bash ~/Linux-command/setup.sh --reset
```

Le bac à sable est recréé à neuf, et l'ancien n'est pas effacé : il est
renommé `formation_linux.sauvegarde-DATE`, pour que vous puissiez y
récupérer votre travail.

### Trois règles de sécurité pour tout le cours

1. **Lisez une commande avant d'appuyer sur Entrée**, surtout si vous
   l'avez copiée sur Internet.
2. **N'utilisez `sudo` que lorsque le cours vous le demande.** Ce mot
   donne les pleins pouvoirs sur le système (chapitre 08). Dans le bac à
   sable, vous n'en aurez jamais besoin.
3. **Faites vos exercices dans `~/formation_linux`**, jamais ailleurs.

---

## 6. Vérification finale

Tapez :

```bash
ls ~/formation_linux
```

Si vous voyez la liste de fichiers de la section 5, **votre poste est
prêt**.

| Problème | Cause probable | Solution |
|---|---|---|
| `git: command not found` | L'étape 1 de la section 4 n'a pas abouti | Relancez `sudo apt update` puis `sudo apt install -y git` |
| `fatal: destination path 'Linux-command' already exists` | Le cours est déjà téléchargé | Rien à faire, passez à la section 5 |
| `bash: /home/marie/Linux-command/setup.sh: No such file or directory` | Le cours n'est pas dans votre dossier personnel | Refaites `cd ~` puis l'étape 2 de la section 4 |
| `Le bac à sable existe déjà` | Vous avez déjà lancé `setup.sh` | Tout va bien. Pour repartir à neuf : `--reset` |
| `ATTENTION : ... fins de ligne Windows (CRLF)` | Le dépôt a été téléchargé avec Git **pour Windows** | Téléchargez-le à nouveau depuis le terminal **Ubuntu** (section 4) |
| `sudo: ... incorrect password attempt` | Mot de passe mal tapé (rappel : il est invisible) | Réessayez lentement. En cas d'oubli sous WSL, cherchez « WSL réinitialiser mot de passe » dans la documentation Microsoft |

---

## L'essentiel

- Le cours se suit sous **Linux** : WSL2 + Ubuntu sous Windows, le Terminal
  sous macOS, ou Codespaces dans un navigateur.
- Le mot de passe ne s'affiche pas quand on le tape : c'est normal.
- On travaille dans **`~/formation_linux`**, une copie qu'on peut abîmer
  sans risque et recréer avec `bash ~/Linux-command/setup.sh --reset`.

### Auto-évaluation

- [ ] J'ouvre un terminal Ubuntu sans chercher.
- [ ] Je sais copier et coller une commande dans le terminal.
- [ ] `ls ~/formation_linux` m'affiche les fichiers d'exercice.
- [ ] Je sais comment remettre mon bac à sable à neuf.

**Prochaine étape** : [chapitre 01 — Premier contact avec le terminal](../01_premier_contact/README.md).
