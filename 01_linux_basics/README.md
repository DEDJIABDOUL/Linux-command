============================================================
MODULE 01 — LINUX POUR DÉBUTANT ABSOLU
============================================================

OBJECTIVE
------------------------------------------------------------
Devenir autonome dans un terminal Linux : se déplacer, explorer, créer,
copier, déplacer, supprimer des fichiers, comprendre les permissions, et
observer les processus en cours d'exécution. Ce module ne traite pas
encore de données biologiques : c'est l'objet du module `02_linux_for_bioinformatics/`.

PREREQUISITES
------------------------------------------------------------
Aucun. Un terminal Linux (ou WSL/Git Bash sous Windows, ou un terminal
macOS) suffit.

WHY?
------------------------------------------------------------
En bioinformatique, la quasi-totalité des outils (aligneurs, appelants de
variants, pipelines) s'exécutent en ligne de commande, souvent sur un
serveur distant (cluster HPC) sans interface graphique. Savoir naviguer et
manipuler des fichiers en Linux est un prérequis absolu, indépendant de
tout outil bioinformatique spécifique.

---

# 1. Structure générale d'une commande

```bash
commande [options] [argument]
```

Exemple :

```bash
ls -lh genome.fasta
```

Ici, `ls` est la commande, `-lh` regroupe les options (`-l` pour le
format long, `-h` pour des tailles lisibles par un humain), et
`genome.fasta` est l'argument, le fichier ciblé.

---

# 2. Navigation

## 2.1 `pwd` — afficher le dossier courant

```text
COMMAND: pwd
PURPOSE: afficher le chemin absolu du dossier dans lequel on se trouve
         (Print Working Directory).
SYNTAX: pwd
INPUT: aucun
OPTIONS: aucune option utile au niveau débutant
OUTPUT: un chemin absolu, ex. /home/user/bioinfo
INTERPRETATION: si le résultat n'est pas celui attendu, c'est probablement
         qu'un `cd` précédent ne s'est pas exécuté comme prévu.
COMMON ERRORS: aucune erreur possible — pwd ne peut pas échouer sur un
         système fonctionnel.
DOCUMENTATION: https://www.gnu.org/software/bash/manual/bash.html (pwd est
         un builtin Bash, documenté dans le manuel Bash, section
         « Bourne Shell Builtins »)
EXERCISE: ouvrir un terminal et exécuter `pwd`. Noter le résultat, puis se
         déplacer avec `cd ..` et exécuter à nouveau `pwd` pour observer
         le changement.
```

## 2.2 `ls` — lister le contenu d'un dossier

```text
COMMAND: ls
PURPOSE: lister les fichiers et dossiers présents dans le répertoire
         courant (ou un répertoire donné en argument).
SYNTAX: ls [options] [chemin]
INPUT: un chemin de dossier (optionnel, dossier courant par défaut)
OPTIONS:
  -l   format long (permissions, propriétaire, taille, date)
  -h   tailles lisibles (Ko, Mo, Go) — à combiner avec -l
  -a   affiche aussi les fichiers cachés (commençant par un point)
  -t   trie par date de modification
OUTPUT: liste de noms de fichiers/dossiers, ou tableau détaillé avec -l
INTERPRETATION: en sortie de `ls -lh`, la première colonne (ex. -rwxr-xr-x)
         indique le type et les permissions (voir section 6), les colonnes
         suivantes donnent propriétaire, groupe, taille lisible et date.
COMMON ERRORS:
  - "No such file or directory" → le chemin donné n'existe pas ou une
    faute de frappe s'est glissée dans le nom.
  - Un dossier semble vide alors qu'il contient des fichiers cachés
    → utiliser `ls -a`.
DOCUMENTATION: https://www.gnu.org/software/coreutils/manual/coreutils.html
         (GNU Coreutils Manual, section « ls: List directory contents »)
EXERCISE: exécuter `ls`, puis `ls -lh`, puis `ls -la`. Comparer les trois
         sorties et identifier au moins un fichier caché.
```

## 2.3 `cd` — changer de dossier

```text
COMMAND: cd
PURPOSE: se déplacer d'un dossier à un autre.
SYNTAX: cd chemin
INPUT: un chemin relatif (ex. data/raw) ou absolu (ex. /home/user/data)
OPTIONS: pas d'options au sens classique, mais des arguments spéciaux :
  cd ..   dossier parent
  cd ~    dossier personnel (HOME)
  cd -    dossier précédent
  cd      (sans argument) équivaut à cd ~
OUTPUT: aucune sortie affichée si la commande réussit
INTERPRETATION: utiliser `pwd` juste après `cd` pour confirmer la
         destination si un doute existe.
COMMON ERRORS:
  - "No such file or directory" → chemin inexistant ou faute de frappe.
  - "Not a directory" → le chemin pointe vers un fichier, pas un dossier.
DOCUMENTATION: https://www.gnu.org/software/bash/manual/bash.html
         (Bash Reference Manual, « Bourne Shell Builtins » → cd)
EXERCISE: partir du dossier personnel (`cd ~`), se déplacer dans un
         sous-dossier existant, revenir au parent avec `cd ..`, puis
         retourner directement au dossier précédent avec `cd -`.
```

## 2.4 `mkdir` — créer un dossier

```text
COMMAND: mkdir
PURPOSE: créer un nouveau dossier.
SYNTAX: mkdir [options] nom_du_dossier
INPUT: un ou plusieurs noms de dossiers à créer
OPTIONS:
  -p   crée aussi les dossiers parents manquants (utile pour créer une
       arborescence en une seule commande)
OUTPUT: aucune sortie si succès
INTERPRETATION: sans -p, mkdir échoue si un dossier intermédiaire du
         chemin n'existe pas encore.
COMMON ERRORS:
  - "File exists" → le dossier existe déjà.
  - "No such file or directory" (sans -p) → un dossier parent du chemin
    n'existe pas encore ; ajouter -p.
DOCUMENTATION: https://www.gnu.org/software/coreutils/manual/coreutils.html
         (GNU Coreutils Manual, « mkdir: Make directories »)
EXERCISE: créer en une seule commande l'arborescence suivante avec -p :
         projet/data/raw, projet/data/processed, projet/results
```
```bash
mkdir -p projet/data/{raw,processed} projet/results
```

## 2.5 `touch`, `cp`, `mv`, `rm`

```text
COMMAND: touch
PURPOSE: créer un fichier vide, ou mettre à jour sa date de modification
         s'il existe déjà.
SYNTAX: touch nom_du_fichier
OUTPUT: aucune sortie si succès
DOCUMENTATION: https://www.gnu.org/software/coreutils/manual/coreutils.html
EXERCISE: `touch notes.txt` puis vérifier avec `ls -l notes.txt`.
```

```text
COMMAND: cp
PURPOSE: copier un fichier ou un dossier.
SYNTAX: cp [options] source destination
OPTIONS:
  -r   copie récursive, obligatoire pour copier un dossier
INPUT: un fichier/dossier source existant
OUTPUT: aucune sortie si succès ; le fichier/dossier destination est créé
INTERPRETATION: si destination est un dossier existant, la copie est
         placée à l'intérieur ; si destination est un nom de fichier,
         c'est une copie renommée.
COMMON ERRORS:
  - "omitting directory" → tentative de copier un dossier sans -r.
  - une copie écrase silencieusement un fichier de même nom sans
    avertissement par défaut sur certains systèmes — vérifier avant.
DOCUMENTATION: https://www.gnu.org/software/coreutils/manual/coreutils.html
EXERCISE: `cp fichier.txt copie.txt` puis `cp -r dossier1 dossier2`.
```

```text
COMMAND: mv
PURPOSE: déplacer OU renommer un fichier/dossier (un renommage est un
         déplacement dans le même dossier).
SYNTAX: mv source destination
INPUT: un fichier/dossier source existant
OUTPUT: aucune sortie si succès
COMMON ERRORS: mv écrase la destination si elle existe déjà, sans
         confirmation par défaut — attention à ne pas perdre un fichier.
DOCUMENTATION: https://www.gnu.org/software/coreutils/manual/coreutils.html
EXERCISE: `mv ancien.txt nouveau.txt` (renommage), puis `mv nouveau.txt data/`
         (déplacement).
```

```text
COMMAND: rm
PURPOSE: supprimer définitivement un fichier (ou un dossier avec -r).
SYNTAX: rm [options] fichier
OPTIONS:
  -r   suppression récursive (nécessaire pour un dossier)
  -f   force, sans confirmation ni message d'erreur si le fichier n'existe pas
OUTPUT: aucune sortie si succès
INTERPRETATION / DANGER : rm ne place PAS les fichiers dans une corbeille.
         La suppression est immédiate et définitive. La combinaison
         `rm -rf` sur un mauvais chemin (en particulier avec les
         privilèges administrateur, `sudo rm -rf`) peut détruire des
         données irrécupérables. Toujours vérifier le chemin avec `ls`
         ou `pwd` avant d'exécuter un `rm -r`, et ne jamais exécuter une
         commande `rm -rf` copiée sans en comprendre chaque partie.
COMMON ERRORS:
  - "Is a directory" → tentative de supprimer un dossier sans -r.
  - Suppression accidentelle d'un fichier de travail non sauvegardé.
DOCUMENTATION: https://www.gnu.org/software/coreutils/manual/coreutils.html
EXERCISE: créer un fichier test avec `touch a_supprimer.txt`, vérifier sa
         présence avec `ls`, puis le supprimer avec `rm a_supprimer.txt`
         et confirmer sa disparition avec `ls`.
```

---

# 3. Explorer le contenu des fichiers

```text
COMMAND: cat
PURPOSE: afficher tout le contenu d'un fichier dans le terminal.
SYNTAX: cat fichier
INTERPRETATION: adapté aux petits fichiers ; pour un gros fichier (ex. un
         génome complet), préférer `less` qui ne charge pas tout en mémoire.
DOCUMENTATION: https://www.gnu.org/software/coreutils/manual/coreutils.html
EXERCISE: `cat notes.txt`
```

```text
COMMAND: less
PURPOSE: lire un fichier progressivement, page par page, sans le charger
         entièrement — indispensable pour les gros fichiers génomiques.
SYNTAX: less fichier
NAVIGATION DANS less:
  Espace   page suivante
  b        page précédente
  /motif   rechercher « motif » vers le bas
  n        occurrence suivante de la recherche
  q        quitter
DOCUMENTATION: https://www.greenwoodsoftware.com/less/ (site officiel du
         projet less) ; dépôt source officiel :
         https://github.com/gwsw/less
EXERCISE: ouvrir `linux/genome.fasta` (module 02) avec `less`, chercher le
         motif ATGCGT avec `/ATGCGT`, puis quitter avec `q`.
```

```text
COMMAND: head / tail
PURPOSE: afficher respectivement le début ou la fin d'un fichier.
SYNTAX: head fichier | head -n 20 fichier | tail -n 20 fichier
OUTPUT: par défaut, les 10 premières (head) ou dernières (tail) lignes.
DOCUMENTATION: https://www.gnu.org/software/coreutils/manual/coreutils.html
EXERCISE: comparer `head -n 5 fichier.txt` et `tail -n 5 fichier.txt`.
```

```text
COMMAND: wc
PURPOSE: compter les lignes, mots ou caractères d'un fichier (Word Count).
SYNTAX: wc [options] fichier
OPTIONS:
  -l   nombre de lignes
  -w   nombre de mots
  -c   nombre de caractères/octets
OUTPUT: un nombre (ou trois nombres sans option)
INTERPRETATION: `wc -l < fichier` (avec redirection d'entrée) affiche
         uniquement le nombre, sans le nom du fichier — pratique dans un
         script ou pour une capture dans une variable.
DOCUMENTATION: https://www.gnu.org/software/coreutils/manual/coreutils.html
EXERCISE: comparer `wc -l fichier.txt` et `wc -l < fichier.txt`.
```

```text
COMMAND: file
PURPOSE: identifier le type réel d'un fichier (texte, binaire, compressé...),
         indépendamment de son extension.
SYNTAX: file nom_du_fichier
OUTPUT: une description textuelle, ex. « ASCII text » ou « gzip compressed data »
INTERPRETATION: utile pour vérifier qu'un fichier téléchargé correspond
         bien au format attendu avant de le traiter.
DOCUMENTATION: https://www.gnu.org/software/coreutils/manual/coreutils.html
EXERCISE: `file linux/genome.fasta` puis `file linux/sample_01.fastq.gz`
         — observer la différence de sortie entre un fichier texte et un
         fichier compressé.
```

---

# 4. Rechercher des fichiers

```text
COMMAND: find
PURPOSE: rechercher des fichiers/dossiers selon des critères (nom, type,
         taille...), récursivement dans une arborescence.
SYNTAX: find chemin_de_depart [critères]
OPTIONS COURANTES:
  -name "motif"     recherche par nom (avec jokers entre guillemets)
  -type f           uniquement des fichiers
  -type d           uniquement des dossiers
  -size +1G         fichiers de plus de 1 Go
INPUT: un dossier de départ (souvent `.` pour le dossier courant)
OUTPUT: la liste des chemins correspondants
INTERPRETATION: `find . -name "*.fastq"` liste tous les FASTQ de
         l'arborescence courante — utile pour repérer un fichier oublié
         ou vérifier qu'un téléchargement a bien produit tous les
         fichiers attendus.
COMMON ERRORS:
  - Oublier les guillemets autour du motif → le shell essaie d'interpréter
    le joker `*` lui-même avant que find ne le reçoive, ce qui donne des
    résultats incorrects ou une erreur si aucun fichier ne correspond au
    nom littéral.
DOCUMENTATION: https://www.gnu.org/software/findutils/manual/ (GNU
         Findutils Manual, section find)
EXERCISE: `find . -name "*.fastq.gz"` puis `find . -type f -size +1G`
         (ne devrait rien retourner sur le jeu de données d'exercice, qui
         est volontairement petit).
```

---

# 5. Permissions

```text
COMMAND: chmod
PURPOSE: modifier les permissions d'un fichier (lecture, écriture,
         exécution) pour le propriétaire, le groupe, et les autres.
SYNTAX: chmod +x script.sh   (ajoute la permission d'exécution)
        chmod 755 script.sh  (notation octale équivalente)
INTERPRETATION: dans une sortie `ls -l`, la chaîne `-rwxr-xr-x` se lit
         par blocs de trois :
```

```text
-rwxr-xr-x
 │└┬┘└┬┘└┬┘
 │ │  │  └── autres (r-x : lecture + exécution)
 │ │  └───── groupe (r-x : lecture + exécution)
 │ └──────── propriétaire (rwx : lecture + écriture + exécution)
 └────────── type (- = fichier normal, d = dossier)
```

```text
COMMON ERRORS:
  - "Permission denied" en essayant d'exécuter `./script.sh` → la
    permission d'exécution n'a pas été accordée ; exécuter
    `chmod +x script.sh` d'abord.
DOCUMENTATION: https://www.gnu.org/software/coreutils/manual/coreutils.html
         (GNU Coreutils Manual, « chmod: Change permissions »)
EXERCISE: créer un script vide (`touch test.sh`), tenter `./test.sh`
         (erreur attendue), puis `chmod +x test.sh` et réessayer.
```

`chown` (changement de propriétaire) nécessite en général des privilèges
administrateur (`sudo`) et n'est pas utilisé au niveau débutant ; il est
mentionné ici pour référence : documentation dans le même manuel Coreutils.

---

# 6. Processus et ressources système

```text
COMMAND: ps / top / htop
PURPOSE: observer les processus en cours d'exécution et leur consommation
         de ressources — essentiel car l'analyse bioinformatique peut
         saturer le CPU, la RAM ou le disque.
SYNTAX: ps          liste des processus de la session courante
        top          vue interactive, mise à jour en continu
        htop         équivalent amélioré de top (souvent à installer)
INTERPRETATION: dans `top`/`htop`, les colonnes %CPU et %MEM indiquent la
         charge par processus ; `q` quitte l'affichage.
DOCUMENTATION:
  - ps/top (paquet procps-ng) : https://gitlab.com/procps-ng/procps
  - htop : https://htop.dev/ (site officiel) et dépôt source
    https://github.com/htop-dev/htop
EXERCISE: lancer `top` (ou `htop` si disponible), observer les processus
         actifs, puis quitter avec `q`.
```

```text
COMMAND: free -h / df -h / du -sh
PURPOSE: free = mémoire RAM disponible ; df = espace disque par partition ;
         du = taille réellement occupée par un fichier/dossier.
SYNTAX: free -h     (tailles lisibles)
        df -h
        du -sh fichier_ou_dossier
DOCUMENTATION: https://www.gnu.org/software/coreutils/manual/coreutils.html
         (df, du) — free appartient également au paquet procps-ng :
         https://gitlab.com/procps-ng/procps
EXERCISE: `df -h` puis `du -sh linux/` pour comparer l'espace disque total
         disponible à la taille du jeu de données d'exercice.
```

Contrôle de jobs en arrière-plan (`jobs`, `bg`, `fg`, `kill`) : ce sont des
fonctionnalités du shell Bash lui-même, documentées dans le Bash Reference
Manual, chapitre « Job Control » : https://www.gnu.org/software/bash/manual/bash.html

---

# 7. `PATH` et localisation des programmes

```text
COMMAND: which / command -v
PURPOSE: trouver l'emplacement exact d'un programme exécutable installé.
SYNTAX: which fastqc
        command -v fastqc
INTERPRETATION: si la commande ne retourne rien, le programme n'est pas
         installé ou n'est pas accessible depuis le PATH courant (par
         exemple un environnement Conda non activé).
DOCUMENTATION: `command -v` est un builtin POSIX documenté dans le Bash
         Reference Manual : https://www.gnu.org/software/bash/manual/bash.html
EXERCISE: `which ls` (doit toujours réussir) puis `which fastqc` (échouera
         tant que le module 06_environment_management/ n'aura pas créé
         l'environnement correspondant).
```

`$PATH` est une variable d'environnement listant les dossiers dans lesquels
le shell recherche les programmes exécutables :

```bash
echo "$PATH"
```

C'est pour cette raison qu'activer un environnement Conda (module 06)
« ajoute » de nouveaux outils : Conda modifie temporairement `$PATH` pour
y inclure le dossier `bin/` de l'environnement actif.

---

TROUBLESHOOTING
------------------------------------------------------------
```text
SYMPTOM: "command not found"
CAUSE: le programme n'est pas installé, ou n'est pas dans $PATH.
DIAGNOSIS: `command -v <programme>` ne retourne rien.
SOLUTION: installer le programme (souvent via Conda, module 06), ou
          activer l'environnement Conda qui le contient.
PREVENTION: toujours vérifier `which <outil>` avant de lancer un pipeline.
```
```text
SYMPTOM: "Permission denied" en exécutant ./script.sh
CAUSE: la permission d'exécution n'a pas été accordée au fichier.
DIAGNOSIS: `ls -l script.sh` montre l'absence du `x` dans les permissions.
SOLUTION: `chmod +x script.sh`
PREVENTION: rendre les scripts exécutables dès leur création.
```
```text
SYMPTOM: "No such file or directory"
CAUSE: chemin incorrect, faute de frappe, ou fichier non encore créé/téléchargé.
DIAGNOSIS: `pwd` puis `ls` pour vérifier l'emplacement réel et le contenu.
SOLUTION: corriger le chemin ; utiliser la complétion automatique du
          terminal (touche Tab) pour éviter les fautes de frappe.
PREVENTION: toujours utiliser Tab pour compléter les noms de fichiers.
```

GO FURTHER
------------------------------------------------------------
```text
Command: pwd, ls, cd, mkdir, cp, mv, rm, touch
Official documentation: https://www.gnu.org/software/coreutils/manual/coreutils.html
Topics to explore: options combinées (-lah), globs (*, ?), liens symboliques (ln -s)

Command: find
Official documentation: https://www.gnu.org/software/findutils/manual/
Topics to explore: -mtime, -exec, combinaison avec xargs

Command: chmod
Official documentation: https://www.gnu.org/software/coreutils/manual/coreutils.html
Topics to explore: notation octale complète, umask, permissions de dossier
```

DOCUMENTATION
------------------------------------------------------------
- GNU Coreutils Manual — https://www.gnu.org/software/coreutils/manual/coreutils.html
- GNU Findutils Manual — https://www.gnu.org/software/findutils/manual/
- GNU Bash Reference Manual — https://www.gnu.org/software/bash/manual/bash.html
- less (pager) — https://www.greenwoodsoftware.com/less/ · source : https://github.com/gwsw/less
- htop — https://htop.dev/ · source : https://github.com/htop-dev/htop
- procps-ng (ps, top, free) — https://gitlab.com/procps-ng/procps

NEXT MODULE
------------------------------------------------------------
`02_linux_for_bioinformatics/` — appliquer ces commandes aux tout premiers
fichiers FASTA et FASTQ du dépôt.
