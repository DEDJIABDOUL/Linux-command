# Chapitre 15 — Git pour biologistes : versionner ses scripts

> **Durée estimée** : 2 h
> **Prérequis** : [chapitre 14](../14_ssh/README.md) (clés SSH, pour GitHub)
> **Chapitre suivant** : [16 — Les formats biologiques en pratique](../16_formats_biologiques/README.md)

## Ce que vous saurez faire à la fin de ce chapitre

- Expliquer ce qu'est un système de gestion de versions, et pourquoi un
  biologiste en a besoin.
- Créer un dépôt Git, enregistrer des versions (`add`, `commit`) et lire
  l'historique (`log`, `diff`).
- **Exclure les données** du dépôt avec `.gitignore`.
- Annuler une modification, et retrouver une ancienne version d'un fichier.
- Publier un dépôt sur GitHub et le récupérer sur une autre machine.

---

## 1. Pourquoi

Vous connaissez sans doute ces noms de fichiers :

```text
qc_run.sh
qc_run_v2.sh
qc_run_v2_corrige.sh
qc_run_FINAL.sh
qc_run_FINAL_vraiment.sh
```

Quelle version a produit les résultats du rapport de mars ? Qu'est-ce qui a
changé entre `v2` et `FINAL` ? Personne ne le sait. **Git** remplace ce
désordre par un **historique** : chaque version enregistrée, avec sa date,
son auteur et une phrase qui explique le changement. On peut comparer deux
versions, revenir à n'importe laquelle, et partager le tout.

Pour un scientifique, c'est la version informatique du **cahier de
laboratoire** : un enregistrement daté, signé et non falsifiable de ce qui a
été fait. Les revues demandent de plus en plus souvent le code associé à un
article, et ce code se publie presque toujours sur GitHub ou GitLab. Ce cours
lui-même est un dépôt Git (chapitre 00).

---

## 2. Une image pour comprendre : le cahier de labo et ses photos

| Cahier de laboratoire | Git |
|---|---|
| le cahier d'un projet | un **dépôt** (*repository*) |
| la paillasse où l'on prépare | le dossier de travail |
| le plateau où l'on dispose ce qu'on va photographier | la **zone de préparation** (*staging area*), remplie par `git add` |
| la photo datée, collée et légendée | un **commit**, créé par `git commit` |
| la légende de la photo | le **message** du commit |
| feuilleter le cahier | `git log` |

Un commit est une **photo de l'état de vos fichiers** à un instant donné.
Git garde toutes les photos, et vous pouvez revenir à n'importe laquelle.

---

## 3. Configurer Git (une seule fois)

Chaque commit porte le nom et l'e-mail de son auteur :

```bash
git config --global user.name "Marie Dupont"
git config --global user.email "marie.dupont@exemple.fr"
git config --global init.defaultBranch main
git config --global --list
```

```text
user.name=Marie Dupont
user.email=marie.dupont@exemple.fr
init.defaultbranch=main
```

Sans cette configuration, le premier `git commit` échoue avec le message
`Author identity unknown … Please tell me who you are`. La troisième ligne
nomme `main` la branche principale (section 7).

---

## 4. Le cycle de base : modifier, préparer, enregistrer

### 4.1 Créer un dépôt

```bash
cd ~/formation_linux
mkdir mon_analyse
cd mon_analyse
git init
ls -a
```

```text
Initialized empty Git repository in /home/marie/formation_linux/mon_analyse/.git/
.  ..  .git
```

Le dossier caché `.git` **est** le dépôt : il contient tout l'historique.
Ne le modifiez jamais à la main. Le supprimer, c'est perdre l'historique.

### 4.2 `git status` : la question à poser tout le temps

Placez dans le projet le script du projet 2, un README, des données et un
résultat :

```bash
cp ../qc_run.sh .
nano README.md                       # quelques lignes de description
mkdir data resultats
cp ../run_sequencage/fastq/P01_S1_L001_R1_001.fastq.gz data/
git status
```

```text
On branch main

No commits yet

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	README.md
	data/
	qc_run.sh
	resultats/
```

Git voit des fichiers **non suivis** (*untracked*) : il ne les surveille pas
encore. `git status` dit toujours où vous en êtes, et suggère même la
commande suivante.

### 4.3 `git add` puis `git commit`

```bash
git add README.md qc_run.sh
git commit -m "Ajoute le script de QC et le README"
```

```text
[main (root-commit) 646b314] Ajoute le script de QC et le README
 2 files changed, 6 insertions(+)
 create mode 100644 README.md
 create mode 100644 qc_run.sh
```

- `git add` place les fichiers dans la zone de préparation : **ce sont eux
  qui seront photographiés**.
- `git commit -m "message"` crée la photo. `646b314` est le début de son
  **identifiant** unique (un *hash*) : le vôtre sera différent, car il dépend
  de l'auteur, de la date et du contenu.

> **Un bon message de commit** dit **ce que** fait le changement, et si
> besoin **pourquoi**, à l'impératif présent : `Relève le seuil de reads à
> 300 (P09 passait à tort)`. Évitez `modif`, `test` ou `version finale`.

### 4.4 Lire l'historique

```bash
git log --oneline
```

```text
7a462b8 Seuil de reads relevé à 300
85574c5 Ignore les données et les résultats
646b314 Ajoute le script de QC et le README
```

`git log`, sans option, affiche aussi l'auteur et la date de chaque commit.
Le plus récent est en haut.

### 4.5 Voir ce qui a changé : `git diff`

Modifiez `qc_run.sh`, puis :

```bash
git status --short
git diff
```

```text
 M qc_run.sh
diff --git a/qc_run.sh b/qc_run.sh
index 72de3d8..c5ada4d 100644
--- a/qc_run.sh
+++ b/qc_run.sh
@@ -1,3 +1,4 @@
 #!/bin/bash
 set -euo pipefail
 echo "QC du run"
+echo "Version 2 : seuil à 300 reads"
```

Les lignes commençant par `+` ont été ajoutées, celles commençant par `-`
supprimées. `git diff` compare votre dossier de travail au dernier commit :
**relisez-le toujours avant de faire un commit**.

**Le cycle complet**, à répéter à chaque étape cohérente de votre travail :

```text
modifier  →  git status  →  git diff  →  git add fichiers  →  git commit -m "…"
```

---

## 5. Les données n'ont rien à faire dans Git : `.gitignore`

Git est conçu pour des fichiers **texte** que l'on écrit soi-même : scripts,
documentation, petites tables de métadonnées. Il **ne faut pas** y mettre :

- les **données brutes** (FASTQ, BAM) : trop volumineuses, et elles se
  téléchargent ou se régénèrent ;
- les **résultats** qui se recalculent à partir des scripts ;
- les **données personnelles ou sensibles** (données de patients) : un
  dépôt publié est public, et l'historique garde tout ;
- les **secrets** : mots de passe, clés privées SSH (chapitre 14), jetons
  d'accès.

Le fichier `.gitignore` liste ce que Git doit ignorer, avec des jokers :

```bash
nano .gitignore
```

```text
data/
resultats/
*.fastq.gz
*.bam
*.log
```

```bash
git status
```

```text
On branch main
Untracked files:
  (use "git add <file>..." to include in what will be committed)
	.gitignore
```

`data/` et `resultats/` ont disparu de la liste. Et si l'on tente quand même
d'ajouter un FASTQ :

```bash
git add data/P01_S1_L001_R1_001.fastq.gz
```

```text
The following paths are ignored by one of your .gitignore files:
data
hint: Use -f if you really want to add them.
```

Git refuse. N'utilisez pas `-f` pour passer outre. `git check-ignore -v
fichier` explique quelle règle ignore un fichier. Versionnez ensuite le
`.gitignore` lui-même (`git add .gitignore`, puis `git commit`).

> **Attention : ce qui est commité reste dans l'historique**, même si l'on
> supprime le fichier ensuite. Un mot de passe ou un fichier de patients
> commité, puis publié, doit être considéré comme **divulgué**. Le
> `.gitignore` se crée **avant** le premier commit.

---

## 6. Revenir en arrière

| Situation | Commande |
|---|---|
| annuler les modifications d'un fichier depuis le dernier commit | `git restore fichier` |
| retirer un fichier de la zone de préparation (sans perdre les modifications) | `git restore --staged fichier` |
| voir le contenu d'un fichier dans une ancienne version | `git show 646b314:qc_run.sh` |
| comparer deux versions | `git diff 646b314 7a462b8 -- qc_run.sh` |
| retrouver dans quel commit un fichier a changé | `git log --oneline -- fichier` |

```bash
echo "ligne cassée" >> qc_run.sh
git restore qc_run.sh
tail -n 1 qc_run.sh
```

```text
echo "Version 2 : seuil à 300 reads"
```

La modification ratée a disparu, et le fichier est revenu à l'état du
dernier commit.

> **Attention** : `git restore fichier` écrase vos modifications **non
> commitées**, sans possibilité de retour. Pour tout ce qui a été commité,
> en revanche, Git garde la trace : c'est la sécurité qu'il apporte.

`HEAD` désigne le dernier commit, et `HEAD~1` celui d'avant :
`git show HEAD~1:qc_run.sh` affiche le script tel qu'il était avant la
dernière modification.

---

## 7. Les branches, en bref

Une **branche** est une ligne de travail parallèle : vous essayez une idée
sans toucher à la version qui fonctionne.

```bash
git switch -c essai_seuil          # crée la branche et s'y place
# … modifications, puis git commit …
git switch main                    # revient sur la branche principale
git branch
```

```text
  essai_seuil
* main
```

Sur `main`, le script est intact. Si l'essai est concluant, on l'intègre
avec `git merge essai_seuil`. Pour un projet personnel, travailler sur `main`
suffit souvent ; les branches deviennent précieuses dès que l'on travaille à
plusieurs.

---

## 8. Partager : GitHub

**GitHub** (comme GitLab, souvent hébergé par les universités) héberge des
dépôts Git en ligne : sauvegarde, partage, publication avec un article.

### 8.1 Une fois : déclarer votre clé SSH

1. Créez un compte sur <https://github.com>.
2. Affichez votre clé **publique** (chapitre 14) : `cat ~/.ssh/id_ed25519.pub`.
3. Sur GitHub : **Settings → SSH and GPG keys → New SSH key**, collez la clé.
4. Testez : `ssh -T git@github.com`. Le message attendu est
   `Hi marie! You've successfully authenticated, but GitHub does not
   provide shell access.`

### 8.2 Publier un dépôt local

1. Sur GitHub, créez un dépôt **vide** nommé `mon_analyse` (bouton
   **New**, sans README).
2. Reliez-y votre dépôt local, puis envoyez votre historique :

```bash
git remote add origin git@github.com:marie/mon_analyse.git
git push -u origin main
```

`origin` est le nom usuel du dépôt distant. Ensuite, après chaque série de
commits, un simple `git push` suffit.

### 8.3 Récupérer sur une autre machine (le serveur de calcul)

```bash
git clone git@github.com:marie/mon_analyse.git
cd mon_analyse
git pull                            # plus tard : récupérer les nouveautés
```

C'est la manière propre d'avoir **les mêmes scripts** sur votre portable et
sur le cluster : on modifie d'un côté, `git push` ; de l'autre, `git pull`.
On ne copie plus des scripts à la main avec `scp`.

> **Dépôt public ou privé ?** GitHub permet les deux. Tant qu'un projet
> n'est pas publié, ou s'il touche à des données sensibles, choisissez
> **privé**.

---

## 9. Pièges fréquents

| Message ou situation | Cause | Solution |
|---|---|---|
| `fatal: not a git repository` | vous n'êtes pas dans le dossier du dépôt | `cd` dans le projet ; `git status` |
| `Author identity unknown` | Git n'est pas configuré | `git config --global user.name …` et `user.email …` |
| `nothing to commit, working tree clean` | aucun changement depuis le dernier commit | normal |
| `nothing added to commit but untracked files present` | oubli de `git add` | `git add fichier` |
| un éditeur (vim) s'ouvre au `git commit` | message `-m` oublié | Échap, `:q!`, puis recommencer avec `-m "…"` (chapitre 10) |
| `The following paths are ignored …` | le fichier est dans `.gitignore` | c'est voulu pour les données ; sinon corriger `.gitignore` |
| `git push` refusé : `Permission denied (publickey)` | clé SSH non déclarée sur GitHub | section 8.1 |
| `git push` refusé : `Updates were rejected` | le dépôt distant contient des commits que vous n'avez pas | `git pull`, puis `git push` |
| un gros fichier ou un secret commité | — | ne pas pousser ; demander de l'aide, car l'historique doit être réécrit |

---

## 10. À vous de jouer

### Exercice 1 : versionner le projet 2

*Objectif : le cycle de base.*
Créez un dépôt `~/formation_linux/qc_pipeline` contenant `qc_run.sh`, un
`README.md` qui explique comment l'utiliser, et un `.gitignore` adapté.
Faites au moins trois commits : le script, le README, le `.gitignore`.

<details>
<summary>Corrigé</summary>

```bash
mkdir -p ~/formation_linux/qc_pipeline
cd ~/formation_linux/qc_pipeline
git init
cp ../qc_run.sh .
git add qc_run.sh
git commit -m "Ajoute le pipeline de QC du projet 2"
nano README.md
git add README.md
git commit -m "Documente l'usage du pipeline"
printf 'qc/\n*.fastq.gz\n*.log\n' > .gitignore
git add .gitignore
git commit -m "Ignore les sorties et les données"
git log --oneline
```

Trois lignes dans `git log --oneline`. Le README doit au minimum indiquer
la commande à lancer, les entrées attendues, les livrables produits et
l'environnement conda nécessaire.
</details>

### Exercice 2 : une modification, de bout en bout

*Objectif : `diff`, `commit`, et retrouver l'ancienne version.*
Changez la valeur par défaut de `--min-reads` de 200 à 250 dans
`qc_run.sh`. Relisez le changement avec `git diff`, commitez-le avec un
message explicite, puis affichez la valeur qu'avait la ligne
`min_reads=` **avant** ce commit.

<details>
<summary>Corrigé</summary>

```bash
nano qc_run.sh                      # min_reads=250
git diff
git commit -am "Relève le seuil par défaut à 250 reads"
git show HEAD~1:qc_run.sh | grep "^min_reads="
```

```text
min_reads=200
```

`git commit -am` fait le `git add` de tous les fichiers **déjà suivis** qui
ont été modifiés, puis le commit. Il n'ajoute pas les nouveaux fichiers.
</details>

### Exercice 3 : le filet de sécurité

*Objectif : `git restore` et `.gitignore`.*
1. Supprimez par erreur `qc_run.sh` (`rm qc_run.sh`), puis récupérez-le.
2. Créez `donnees/patient07.tsv`. Faites en sorte que tout le dossier
   `donnees/` soit ignoré, et prouvez-le avec `git check-ignore`.

<details>
<summary>Corrigé</summary>

```bash
rm qc_run.sh
git status --short
git restore qc_run.sh
ls qc_run.sh
mkdir donnees && touch donnees/patient07.tsv
echo "donnees/" >> .gitignore
git check-ignore -v donnees/patient07.tsv
git commit -am "Ignore le dossier des données patients"
```

`git status --short` montre ` D qc_run.sh` (supprimé), et `git restore` le
fait revenir : il était commité. `git check-ignore` répond
`.gitignore:4:donnees/	donnees/patient07.tsv`.
</details>

---

## 11. Défi : publier et récupérer

Publiez le dépôt `qc_pipeline` sur GitHub, dans un dépôt **privé**. Puis,
en vous servant du « serveur » du chapitre 14, clonez-le dans
`~/serveur_simule/`, faites-y une modification (par exemple une ligne de
plus dans le README), commitez et poussez **depuis le serveur**, et
récupérez cette modification **sur votre machine** avec `git pull`.

<details>
<summary>Corrigé</summary>

```bash
# Machine locale
cd ~/formation_linux/qc_pipeline
git remote add origin git@github.com:VOTRE_COMPTE/qc_pipeline.git
git push -u origin main

# « Serveur »
ssh labo
cd ~/serveur_simule
git clone git@github.com:VOTRE_COMPTE/qc_pipeline.git
cd qc_pipeline
echo "Testé sur le serveur le $(date +%Y-%m-%d)." >> README.md
git commit -am "Note de test sur le serveur"
git push
exit

# Machine locale
cd ~/formation_linux/qc_pipeline
git pull
tail -n 1 README.md
```

Ici, le « serveur » et votre machine sont le même ordinateur, mais les deux
dossiers sont deux **copies indépendantes** du dépôt, synchronisées par
GitHub : exactement la situation d'un portable et d'un cluster. Sur un vrai
serveur, il faudrait aussi y déclarer une clé SSH auprès de GitHub.
</details>

---

## L'essentiel

```text
git config --global user.name "…" / user.email "…" / init.defaultBranch main
git init        git status        git add fichiers        git commit -m "message"
git log --oneline     git diff     git show HEAD~1:fichier    git log -- fichier
.gitignore : data/  resultats/  *.fastq.gz  *.bam  → JAMAIS de données, de résultats, de secrets
git restore f (annule les modifs non commitées)     git restore --staged f
git switch -c branche   git switch main   git merge branche
GitHub : clé SSH publique → git remote add origin git@github.com:moi/depot.git
git push -u origin main   ·   git clone …   ·   git pull
```

### Auto-évaluation

- [ ] J'explique la différence entre `git add` et `git commit`.
- [ ] Je relis `git diff` avant de commiter, et j'écris des messages explicites.
- [ ] Mon `.gitignore` exclut les données, les résultats et les secrets, et je sais pourquoi.
- [ ] Je récupère un fichier supprimé ou une ancienne version.
- [ ] J'ai publié un dépôt sur GitHub et je l'ai cloné ailleurs.

## Documentation officielle

- Git : <https://git-scm.com/doc> · le livre *Pro Git*, en français : <https://git-scm.com/book/fr/v2>
- GitHub : clés SSH : <https://docs.github.com/fr/authentication/connecting-to-github-with-ssh>
- Modèles de `.gitignore` : <https://github.com/github/gitignore>
- Perez-Riverol Y. *et al.* (2016), « Ten Simple Rules for Taking Advantage of Git and GitHub », *PLOS Computational Biology* 12(7):e1004947, DOI [10.1371/journal.pcbi.1004947](https://doi.org/10.1371/journal.pcbi.1004947)

**Prochaine étape** : [chapitre 16 — Les formats biologiques en pratique](../16_formats_biologiques/README.md).
