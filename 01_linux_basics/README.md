# 01 — Linux pour débutant absolu

OBJECTIVE
------------------------------------------------------------
Devenir autonome dans un terminal Linux : se déplacer, explorer, créer,
copier, déplacer, supprimer des fichiers, comprendre les permissions, et
observer les processus en cours d'exécution. Ce module couvre aussi les
bases de l'administration d'une machine Linux (comptes, réseau, pare-feu,
services système) : des notions qui ne servent pas tous les jours à
l'analyse de données, mais qui deviennent indispensables dès qu'on
travaille sur un serveur ou un cluster HPC partagé. Ce module ne traite pas
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

## 2.6 `echo`, `clear` — afficher du texte, effacer l'écran

```text
COMMAND: echo
PURPOSE: afficher une chaîne de texte ou le contenu d'une variable dans le
         terminal ; utilisé aussi pour écrire du texte dans un fichier via
         une redirection.
SYNTAX: echo "texte"
        echo "$VARIABLE"
INPUT: une chaîne de caractères ou une variable shell
OPTIONS:
  -e   interprète les séquences d'échappement (ex. \n pour un saut de ligne)
  -n   n'ajoute pas de retour à la ligne final
OUTPUT: le texte donné, tel quel (ou une ligne vide si la variable n'existe pas)
INTERPRETATION: `echo "$PATH"` affiche le contenu de la variable PATH (voir
         section 7) ; sans guillemets, une variable contenant des espaces
         peut être mal interprétée par le shell.
COMMON ERRORS:
  - oublier les guillemets autour d'une variable contenant des espaces ou
    des jokers (*, ?) → le résultat peut être fragmenté de façon inattendue.
DOCUMENTATION: https://www.gnu.org/software/bash/manual/bash.html (echo est
         un builtin Bash, « Bourne Shell Builtins »)
EXERCISE: `echo "Bonjour"` puis `echo "$HOME"` pour afficher son propre
         dossier personnel.
```

```text
COMMAND: clear
PURPOSE: effacer l'affichage du terminal pour repartir sur un écran vide,
         sans effacer l'historique des commandes ni interrompre quoi que
         ce soit en cours.
SYNTAX: clear
OUTPUT: aucune sortie ; l'écran est simplement vidé
INTERPRETATION: le raccourci clavier Ctrl+L produit le même effet sans
         taper la commande.
COMMON ERRORS: aucune ; clear ne peut pas échouer sur un terminal fonctionnel.
DOCUMENTATION: https://www.gnu.org/software/ncurses/ (clear fait partie du
         paquet ncurses, qui fournit les capacités terminal utilisées par
         clear/tput)
EXERCISE: exécuter plusieurs commandes pour remplir l'écran, puis `clear`
         (ou Ctrl+L) pour repartir sur un écran vide.
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

```text
COMMAND: diff
PURPOSE: afficher les différences ligne par ligne entre deux fichiers
         texte — utile pour comparer deux versions d'un script, d'un
         fichier de configuration ou d'un résultat.
SYNTAX: diff fichier1 fichier2
OPTIONS:
  -u   format unifié (le plus lisible, celui utilisé par git et les patchs)
  -q   indique seulement si les fichiers diffèrent, sans détailler
OUTPUT: les lignes différentes, précédées de < (fichier1) ou > (fichier2) ;
         aucune sortie si les fichiers sont identiques
INTERPRETATION: une sortie vide et un code de retour 0 signifient que les
         fichiers sont identiques ; un code de retour 1 signifie qu'ils
         diffèrent (vérifiable avec `echo $?` juste après).
COMMON ERRORS:
  - comparer deux fichiers binaires avec diff sans -a/--text → message
    générique « Binary files ... differ » sans détail.
DOCUMENTATION: https://www.gnu.org/software/diffutils/manual/diffutils.html
         (GNU Diffutils Manual, section « diff »)
EXERCISE: `cp fichier.txt fichier2.txt`, modifier une ligne de
         fichier2.txt, puis `diff -u fichier.txt fichier2.txt`.
```

```text
COMMAND: cmp
PURPOSE: déterminer si deux fichiers (texte ou binaires) sont strictement
         identiques, et localiser le premier octet où ils diffèrent.
SYNTAX: cmp fichier1 fichier2
OUTPUT: rien si les fichiers sont identiques ; sinon la position (octet,
         ligne) de la première différence
INTERPRETATION: plus adapté que diff pour vérifier l'intégrité d'un fichier
         binaire ou compressé (ex. vérifier que deux téléchargements du
         même fichier .gz sont identiques).
COMMON ERRORS:
  - utiliser cmp pour obtenir le détail de toutes les différences d'un
    fichier texte → préférer diff, plus lisible dans ce cas.
DOCUMENTATION: https://www.gnu.org/software/diffutils/manual/diffutils.html
         (GNU Diffutils Manual, section « cmp »)
EXERCISE: `cp fichier.txt copie_identique.txt` puis
         `cmp fichier.txt copie_identique.txt` (aucune sortie attendue).
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

```text
COMMAND: chown
PURPOSE: changer le propriétaire et/ou le groupe propriétaire d'un fichier
         ou d'un dossier.
SYNTAX: sudo chown utilisateur:groupe fichier
        sudo chown -R utilisateur:groupe dossier   (récursif)
OPTIONS:
  -R   applique le changement récursivement à tout un dossier
OUTPUT: aucune sortie si succès
INTERPRETATION: nécessite en général les privilèges administrateur (sudo),
         sauf cas particulier où l'utilisateur courant possède déjà les
         droits suffisants.
COMMON ERRORS:
  - "Operation not permitted" → absence des privilèges nécessaires ;
    ajouter sudo.
  - "invalid user" / "invalid group" → le nom donné n'existe pas sur le
    système (voir section 8, comptes et privilèges).
DOCUMENTATION: https://www.gnu.org/software/coreutils/manual/coreutils.html
         (GNU Coreutils Manual, « chown: Change file owner and group »)
EXERCISE: `ls -l fichier.txt` pour observer le propriétaire actuel, puis
         (si les droits le permettent) `sudo chown $USER fichier.txt`.
```

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

Contrôle de jobs en arrière-plan (`jobs`, `bg`, `fg`) : ce sont des
fonctionnalités du shell Bash lui-même, documentées dans le Bash Reference
Manual, chapitre « Job Control » : https://www.gnu.org/software/bash/manual/bash.html

```text
COMMAND: kill
PURPOSE: envoyer un signal à un processus, le plus souvent pour l'arrêter,
         en le désignant par son PID (identifiant numérique).
SYNTAX: kill PID
        kill -9 PID   (arrêt forcé, signal SIGKILL)
OPTIONS:
  -9 / -KILL   arrêt immédiat et forcé, sans laisser le programme se
               terminer proprement
  -15 / -TERM  (par défaut) demande un arrêt propre, que le programme peut
               intercepter
OUTPUT: aucune sortie si succès
INTERPRETATION: toujours essayer `kill` (signal par défaut, TERM) avant
         `kill -9`, pour laisser au programme une chance de sauvegarder
         son état et de libérer proprement ses ressources.
COMMON ERRORS:
  - "No such process" → le PID n'existe plus (processus déjà terminé) ou
    faute de frappe.
  - "Operation not permitted" → tentative d'arrêter un processus
    appartenant à un autre utilisateur sans privilèges suffisants.
DOCUMENTATION: kill est documenté dans le Bash Reference Manual
         (« Job Control ») et dans le paquet procps-ng :
         https://gitlab.com/procps-ng/procps
EXERCISE: lancer `sleep 300 &` (processus en arrière-plan), noter son PID
         affiché, puis l'arrêter avec `kill PID` et vérifier sa
         disparition avec `ps`.
```

```text
COMMAND: pkill
PURPOSE: envoyer un signal à un ou plusieurs processus désignés par leur
         nom, sans avoir à chercher leur PID au préalable.
SYNTAX: pkill nom_du_programme
OPTIONS:
  -9   arrêt forcé, comme pour kill
  -f   applique la recherche à la ligne de commande complète, pas
       seulement au nom du processus
OUTPUT: aucune sortie si succès
INTERPRETATION: plus rapide que kill quand le PID est inconnu, mais plus
         risqué : un motif trop large peut arrêter plusieurs processus à
         la fois.
COMMON ERRORS:
  - arrêter accidentellement un processus non visé à cause d'un nom trop
    générique → vérifier avec `pgrep nom_du_programme` avant d'exécuter
    pkill.
DOCUMENTATION: https://gitlab.com/procps-ng/procps (paquet procps-ng,
         comme ps/kill/pgrep)
EXERCISE: lancer `sleep 300 &`, puis l'arrêter directement avec
         `pkill sleep` (sans connaître son PID).
```

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

# 8. Éditeurs de texte en ligne de commande

```text
COMMAND: nano
PURPOSE: créer ou modifier un fichier texte directement dans le terminal,
         avec les raccourcis affichés en bas de l'écran — l'éditeur
         recommandé pour un débutant.
SYNTAX: nano fichier
NAVIGATION DANS nano:
  Ctrl+O   sauvegarder (Write Out)
  Ctrl+X   quitter
  Ctrl+K   couper une ligne
  Ctrl+W   rechercher
OUTPUT: aucune sortie dans le terminal ; le fichier est créé/modifié sur
         disque après sauvegarde
INTERPRETATION: si le fichier n'existe pas encore, nano le crée à la
         sauvegarde ; s'il existe, il est ouvert tel quel.
COMMON ERRORS:
  - quitter avec Ctrl+X sans sauvegarder (Ctrl+O) au préalable → les
    modifications sont perdues.
DOCUMENTATION: https://www.nano-editor.org/dist/latest/nano.html
         (documentation officielle de GNU nano)
EXERCISE: `nano notes.txt`, écrire une ligne de texte, sauvegarder avec
         Ctrl+O, quitter avec Ctrl+X, puis vérifier avec `cat notes.txt`.
```

```text
COMMAND: vim
PURPOSE: éditeur de texte modal avancé, utilisant des modes (normal,
         insertion, commande) — omniprésent sur les serveurs Linux/HPC,
         plus exigeant à apprendre que nano mais plus rapide à l'usage
         une fois maîtrisé.
SYNTAX: vim fichier
NAVIGATION DE BASE DANS vim:
  i        passer en mode insertion (pour écrire)
  Échap    revenir en mode normal
  :w       sauvegarder (write)
  :q       quitter
  :wq      sauvegarder puis quitter
  :q!      quitter sans sauvegarder, en forçant
OUTPUT: aucune sortie dans le terminal ; le fichier est créé/modifié sur
         disque après :w
INTERPRETATION: contrairement à nano, vim s'ouvre en mode normal (les
         touches sont des commandes, pas du texte) — appuyer directement
         sur des lettres sans passer en mode insertion (i) modifie ou
         déplace le curseur sans écrire de texte.
COMMON ERRORS:
  - se retrouver « bloqué » dans vim en tapant du texte en mode normal →
    appuyer sur Échap puis taper `:q!` pour quitter sans sauvegarder.
DOCUMENTATION: https://www.vim.org/docs.php (documentation officielle) ;
         `vimtutor` (tutoriel interactif installé avec vim) est le point
         d'entrée recommandé.
EXERCISE: `vim notes.txt`, appuyer sur `i`, écrire une ligne, appuyer sur
         Échap, puis `:wq` pour sauvegarder et quitter.
```

---

# 9. Liens et suppression avancée

```text
COMMAND: rmdir
PURPOSE: supprimer un dossier, uniquement s'il est vide — une alternative
         plus sûre que `rm -r` quand on ne veut pas risquer de supprimer
         du contenu par erreur.
SYNTAX: rmdir dossier
OUTPUT: aucune sortie si succès
INTERPRETATION: contrairement à `rm -r`, rmdir refuse d'agir si le dossier
         contient encore des fichiers — c'est une protection, pas une
         limitation à contourner sans réflexion.
COMMON ERRORS:
  - "Directory not empty" → le dossier contient encore des fichiers ; les
    supprimer d'abord, ou utiliser `rm -r` en connaissance de cause.
DOCUMENTATION: https://www.gnu.org/software/coreutils/manual/coreutils.html
         (GNU Coreutils Manual, « rmdir: Remove empty directories »)
EXERCISE: `mkdir dossier_vide` puis `rmdir dossier_vide` ; vérifier avec `ls`.
```

```text
COMMAND: ln
PURPOSE: créer un lien vers un fichier, pour y accéder depuis un autre
         emplacement sans dupliquer son contenu.
SYNTAX: ln -s cible nom_du_lien   (lien symbolique, le plus courant)
OPTIONS:
  -s   crée un lien symbolique (raccourci pointant vers le chemin cible)
       plutôt qu'un lien physique
OUTPUT: aucune sortie si succès ; `ls -l` affiche le lien avec une flèche
         vers sa cible
INTERPRETATION: un lien symbolique cassé (cible déplacée ou supprimée)
         reste visible mais devient inutilisable.
COMMON ERRORS:
  - supprimer la cible d'un lien symbolique sans le savoir → le lien
    devient orphelin (« broken symlink »).
  - confondre un lien symbolique avec une copie : modifier le lien
    modifie le fichier cible.
DOCUMENTATION: https://www.gnu.org/software/coreutils/manual/coreutils.html
         (GNU Coreutils Manual, « ln: Make links between files »)
EXERCISE: `ln -s genome.fasta lien_genome.fasta` puis
         `ls -l lien_genome.fasta` pour observer la flèche vers la cible.
```

```text
COMMAND: shred
PURPOSE: écraser le contenu d'un fichier avant de le supprimer, pour
         rendre sa récupération beaucoup plus difficile qu'avec un simple
         `rm` (qui ne fait que retirer l'entrée du fichier, sans effacer
         les données sur le disque).
SYNTAX: shred -u fichier
OPTIONS:
  -u   supprime le fichier après l'avoir écrasé (sans -u, shred écrase le
       contenu mais laisse le fichier, vide, sur le disque)
  -n N écrase le fichier N fois (par défaut 3 passes)
OUTPUT: aucune sortie si succès
INTERPRETATION: sur un disque SSD moderne ou un système de fichiers
         journalisé, l'effacement garanti par shred n'est pas toujours
         certain (le matériel peut réécrire les données ailleurs) — utile
         en connaissance de cette limite, mais pas une garantie absolue.
COMMON ERRORS:
  - utiliser shred en pensant supprimer un dossier → shred agit sur des
    fichiers, pas des dossiers (pas d'option récursive fiable).
DOCUMENTATION: https://www.gnu.org/software/coreutils/manual/coreutils.html
         (GNU Coreutils Manual, « shred: Delete files more securely »)
EXERCISE: `touch secret.txt && echo "donnée sensible" > secret.txt`, puis
         `shred -u secret.txt` et vérifier sa disparition avec `ls`.
```

---

# 10. Archives

```text
COMMAND: zip
PURPOSE: regrouper un ou plusieurs fichiers/dossiers dans une archive
         compressée au format .zip, un format multiplateforme pratique
         pour partager des fichiers avec des collègues sous Windows/macOS.
SYNTAX: zip archive.zip fichier1 fichier2
        zip -r archive.zip dossier/   (récursif, pour un dossier entier)
OPTIONS:
  -r   inclut récursivement le contenu d'un dossier
OUTPUT: création du fichier archive.zip
INTERPRETATION: en bioinformatique, les formats .gz et .tar.gz (module 08)
         sont plus courants pour les données (meilleure compression,
         standard des outils du domaine) ; .zip reste utile pour partager
         des résultats avec des personnes hors du monde Unix.
COMMON ERRORS:
  - "zip: command not found" → paquet non installé (`sudo apt install zip`).
DOCUMENTATION: https://infozip.sourceforge.net/Zip.html (documentation
         officielle du projet Info-ZIP)
EXERCISE: `zip -r resultats.zip dossier_resultats/` puis vérifier la
         taille de l'archive avec `ls -lh resultats.zip`.
```

```text
COMMAND: unzip
PURPOSE: extraire le contenu d'une archive .zip dans le dossier courant
         (ou un dossier choisi).
SYNTAX: unzip archive.zip
        unzip archive.zip -d dossier_destination
OPTIONS:
  -d   choisit le dossier de destination de l'extraction
  -l   liste le contenu de l'archive sans l'extraire
OUTPUT: les fichiers et dossiers contenus dans l'archive, extraits sur disque
COMMON ERRORS:
  - "command not found" → paquet non installé (`sudo apt install unzip`).
  - écraser des fichiers existants sans confirmation dans certains
    contextes non interactifs → vérifier avec `unzip -l` avant d'extraire
    dans un dossier déjà occupé.
DOCUMENTATION: https://infozip.sourceforge.net/UnZip.html (documentation
         officielle du projet Info-ZIP)
EXERCISE: `unzip -l resultats.zip` pour lister le contenu, puis
         `unzip resultats.zip -d verification/` pour l'extraire ailleurs.
```

---

# 11. Aide et historique

```text
COMMAND: man
PURPOSE: afficher la documentation officielle, installée localement,
         d'une commande — la première ressource à consulter en cas de
         doute sur une syntaxe ou une option.
SYNTAX: man commande
NAVIGATION DANS man (utilise less en arrière-plan):
  Espace   page suivante
  /motif   rechercher « motif »
  q        quitter
OUTPUT: une page de manuel structurée (NAME, SYNOPSIS, DESCRIPTION, OPTIONS...)
INTERPRETATION: la section SYNOPSIS montre la syntaxe précise, avec les
         arguments optionnels entre crochets [ ] et obligatoires sans
         crochets.
COMMON ERRORS:
  - "No manual entry for ..." → la commande n'a pas de page de manuel
    installée (cas fréquent des builtins Bash comme `cd`, voir `help cd`
    à la place).
DOCUMENTATION: https://man7.org/linux/man-pages/ (Linux man-pages project,
         référence des pages de manuel Linux)
EXERCISE: `man ls`, chercher la description de l'option -h avec `/-h`,
         puis quitter avec `q`.
```

```text
COMMAND: whatis
PURPOSE: afficher la description en une ligne d'une commande, extraite de
         la section NAME de son manuel — utile pour un rappel rapide sans
         ouvrir toute la page man.
SYNTAX: whatis commande
OUTPUT: une ligne, ex. « ls (1) - list directory contents »
COMMON ERRORS:
  - "nothing appropriate" → la base de données whatis n'est pas à jour ;
    exécuter `sudo mandb` pour la reconstruire.
DOCUMENTATION: https://man7.org/linux/man-pages/man1/whatis.1.html
EXERCISE: `whatis ls` puis `whatis grep`.
```

```text
COMMAND: history
PURPOSE: afficher les commandes précédemment exécutées dans le terminal,
         numérotées.
SYNTAX: history
        history | grep motif   (rechercher une commande passée)
OUTPUT: une liste numérotée des commandes exécutées
INTERPRETATION: `!42` réexécute la commande numéro 42 de l'historique ; la
         flèche du haut ↑ parcourt l'historique le plus récent en premier.
COMMON ERRORS:
  - s'attendre à retrouver une commande d'une session précédente déjà
    fermée sans sauvegarde explicite (`history -a`) selon la
    configuration du shell.
DOCUMENTATION: https://www.gnu.org/software/bash/manual/bash.html (Bash
         Reference Manual, « Bash History Facilities »)
EXERCISE: exécuter quelques commandes, puis `history | tail -n 5` pour
         revoir les cinq dernières.
```

---

# 12. Identité et informations système

```text
COMMAND: whoami
PURPOSE: afficher le nom de l'utilisateur actuellement connecté dans le
         terminal.
SYNTAX: whoami
OUTPUT: un nom d'utilisateur, ex. abdoul
INTERPRETATION: utile pour confirmer son identité après un `su` ou une
         connexion SSH à un serveur partagé.
DOCUMENTATION: https://www.gnu.org/software/coreutils/manual/coreutils.html
         (GNU Coreutils Manual, « whoami »)
EXERCISE: `whoami` puis comparer avec la variable `echo "$USER"`.
```

```text
COMMAND: uname
PURPOSE: afficher des informations sur le système (noyau, architecture,
         nom de la machine) — utile pour vérifier la compatibilité d'un
         outil bioinformatique avant installation.
SYNTAX: uname -a
OPTIONS:
  -a   affiche toutes les informations disponibles
  -r   version du noyau uniquement
  -m   architecture matérielle (ex. x86_64)
OUTPUT: une ou plusieurs lignes décrivant le système
INTERPRETATION: l'architecture (-m) est essentielle avant de télécharger
         un binaire précompilé : un binaire x86_64 ne fonctionnera pas sur
         une architecture arm64.
DOCUMENTATION: https://www.gnu.org/software/coreutils/manual/coreutils.html
         (GNU Coreutils Manual, « uname: Print system information »)
EXERCISE: `uname -a` puis noter séparément le résultat de `uname -m`.
```

```text
COMMAND: cal
PURPOSE: afficher un calendrier dans le terminal — utilitaire mineur,
         pratique pour vérifier rapidement une date sans quitter le
         terminal.
SYNTAX: cal
        cal 2026        (calendrier annuel)
        cal 9 2026       (mois précis)
OUTPUT: un calendrier en texte
DOCUMENTATION: https://man7.org/linux/man-pages/man1/cal.1.html
EXERCISE: `cal` pour le mois courant, puis `cal 2026` pour l'année complète.
```

```text
COMMAND: neofetch
PURPOSE: afficher un résumé du système (distribution, noyau, mémoire,
         résolution...) accompagné du logo de la distribution en ASCII
         art — purement informatif, sans usage bioinformatique direct.
SYNTAX: neofetch
OUTPUT: un bloc d'informations système avec logo ASCII
INTERPRETATION: outil de confort, souvent absent par défaut ; à installer
         via `sudo apt install neofetch` si souhaité.
COMMON ERRORS:
  - "command not found" → paquet non installé.
DOCUMENTATION: https://github.com/dylanaraps/neofetch (dépôt source
         officiel du projet, archivé mais toujours largement utilisé)
EXERCISE: installer puis exécuter `neofetch` pour visualiser un résumé de
         son propre système.
```

---

# 13. Réseau de base

```text
COMMAND: ping
PURPOSE: envoyer des paquets à une adresse ou un nom de domaine pour
         vérifier qu'il est joignable sur le réseau, et mesurer le temps
         de réponse.
SYNTAX: ping adresse_ou_domaine
        ping -c 4 adresse_ou_domaine   (limite à 4 paquets, recommandé)
OPTIONS:
  -c N   arrête après N paquets envoyés (sans -c, ping continue
         indéfiniment ; arrêter avec Ctrl+C)
OUTPUT: une ligne par paquet reçu, avec le temps de réponse (ex.
         time=12.3 ms), puis un résumé statistique
INTERPRETATION: en bioinformatique, ping sert surtout à diagnostiquer une
         panne réseau avant de soupçonner à tort un outil de
         téléchargement (curl, module 08) de mal fonctionner.
COMMON ERRORS:
  - "Name or service not known" → le nom de domaine est incorrect ou le
    DNS ne répond pas.
  - aucune réponse alors que la machine est en ligne → un pare-feu (voir
    ufw/iptables, section 17) peut bloquer les paquets ICMP sans que cela
    signifie une panne réelle.
DOCUMENTATION: https://man7.org/linux/man-pages/man8/ping.8.html
EXERCISE: `ping -c 4 8.8.8.8` (adresse publique de Google DNS) pour
         vérifier sa connexion Internet.
```

```text
COMMAND: ifconfig
PURPOSE: afficher (ou configurer) les interfaces réseau et leurs adresses
         IP — commande historique, remplacée sur les distributions
         récentes par `ip a`.
SYNTAX: ifconfig
OUTPUT: la liste des interfaces réseau (ex. eth0, wlan0, lo) avec leur
         adresse IP
INTERPRETATION: si la commande n'est pas trouvée, c'est le signe normal
         d'une distribution récente qui a migré vers `ip` (paquet
         iproute2) ; installer le paquet net-tools si l'usage de ifconfig
         est spécifiquement requis.
COMMON ERRORS:
  - "command not found" sur une distribution récente → utiliser `ip a` à
    la place, ou installer net-tools.
DOCUMENTATION: https://man7.org/linux/man-pages/man8/ifconfig.8.html
EXERCISE: essayer `ifconfig` ; si absent, comparer avec `ip a` ci-dessous.
```

```text
COMMAND: ip
PURPOSE: afficher et configurer les interfaces réseau, le remplaçant
         moderne de `ifconfig`, `route` et plusieurs autres commandes
         historiques (paquet iproute2).
SYNTAX: ip a    (ou ip addr — affiche les adresses de toutes les interfaces)
OUTPUT: la liste des interfaces avec leurs adresses IPv4/IPv6
INTERPRETATION: une interface « lo » (loopback, 127.0.0.1) est toujours
         présente et sert aux communications internes à la machine
         elle-même.
DOCUMENTATION: https://man7.org/linux/man-pages/man8/ip.8.html
EXERCISE: `ip a` puis identifier l'adresse IP de l'interface réseau
         principale de la machine.
```

```text
COMMAND: resolvectl
PURPOSE: afficher la configuration DNS active (systemd-resolved) — utile
         pour diagnostiquer un problème de résolution de nom de domaine.
SYNTAX: resolvectl status
OUTPUT: la liste des serveurs DNS utilisés par interface réseau
INTERPRETATION: si un domaine ne se résout pas (`ping domaine.com` échoue
         avec "Name or service not known") alors que l'adresse IP
         correspondante répond, le problème vient du DNS, pas du réseau
         lui-même.
COMMON ERRORS:
  - "command not found" → le système n'utilise pas systemd-resolved ;
    vérifier `/etc/resolv.conf` directement à la place.
DOCUMENTATION: https://www.freedesktop.org/software/systemd/man/latest/resolvectl.html
         (documentation officielle systemd)
EXERCISE: `resolvectl status` et identifier le serveur DNS utilisé par
         l'interface principale.
```

```text
COMMAND: netstat
PURPOSE: afficher les connexions réseau actives et les ports en écoute —
         commande historique, remplacée sur les distributions récentes
         par `ss`.
SYNTAX: netstat -tulpn
OPTIONS:
  -t   connexions TCP
  -u   connexions UDP
  -l   ports en écoute uniquement
  -p   affiche le programme associé à chaque connexion (nécessite
       souvent sudo)
  -n   affiche les adresses/ports numériques plutôt que de les résoudre
       en noms
OUTPUT: un tableau des connexions et ports
COMMON ERRORS:
  - "command not found" → paquet net-tools non installé sur les
    distributions récentes ; utiliser `ss` à la place.
DOCUMENTATION: https://man7.org/linux/man-pages/man8/netstat.8.html
EXERCISE: essayer `netstat -tulpn` (avec sudo si nécessaire) ; comparer
         avec `ss -tulpn` ci-dessous.
```

```text
COMMAND: ss
PURPOSE: afficher les connexions réseau (sockets) actives et les ports en
         écoute, le remplaçant moderne et plus rapide de `netstat`
         (paquet iproute2).
SYNTAX: ss -tulpn
OPTIONS: identiques dans l'esprit à netstat (-t TCP, -u UDP, -l écoute,
         -p programme, -n numérique)
OUTPUT: un tableau des connexions et ports, format similaire à netstat
INTERPRETATION: utile pour vérifier qu'un serveur local (ex. Jupyter
         Notebook, un serveur de visualisation) écoute bien sur le port
         attendu avant de tenter une connexion depuis un navigateur.
DOCUMENTATION: https://man7.org/linux/man-pages/man8/ss.8.html
EXERCISE: `ss -tulpn` et identifier les ports actuellement en écoute sur
         la machine.
```

---

# 14. Gestion des paquets

```text
COMMAND: apt
PURPOSE: installer, mettre à jour et supprimer des logiciels sur les
         distributions basées sur Debian (dont Ubuntu) — le gestionnaire
         de paquets système.
SYNTAX: sudo apt update              (rafraîchit la liste des paquets disponibles)
        sudo apt upgrade             (met à jour les paquets déjà installés)
        sudo apt install nom_paquet  (installe un nouveau paquet)
OUTPUT: un journal texte de l'opération, avec confirmation demandée avant
         modification
INTERPRETATION: `apt update` ne met rien à jour lui-même — il actualise
         seulement la liste de ce qui est disponible ; il faut ensuite
         `apt upgrade` pour appliquer les mises à jour. En bioinformatique,
         Conda (module 06) est en général préféré à apt pour les outils
         scientifiques eux-mêmes, car il permet des environnements
         isolés par projet ; apt reste utilisé pour les outils système
         de base.
COMMON ERRORS:
  - "Unable to locate package" → nom de paquet incorrect, ou `apt update`
    non exécuté récemment.
  - "Permission denied" → apt modifie le système, donc nécessite
    systématiquement sudo.
DOCUMENTATION: https://manpages.ubuntu.com/manpages/noble/en/man8/apt.8.html
         (documentation officielle Ubuntu/Debian)
EXERCISE: `sudo apt update` puis `apt list --upgradable` pour voir les
         paquets pouvant être mis à jour (sans les installer).
```

---

# 15. Comptes et privilèges

```text
COMMAND: sudo
PURPOSE: exécuter une commande unique avec les privilèges de
         l'administrateur (root), après authentification par mot de
         passe — le mécanisme standard pour effectuer des opérations
         système sans rester connecté en root en permanence.
SYNTAX: sudo commande
OUTPUT: la sortie normale de la commande exécutée, précédée d'une demande
         de mot de passe (une fois par session, en général)
INTERPRETATION: contrairement à `su -` (fiche suivante), sudo n'ouvre pas
         une nouvelle session : il élève les privilèges pour une seule
         commande, ce qui est plus sûr (moins de risque d'oublier qu'on
         agit en administrateur).
COMMON ERRORS:
  - "user is not in the sudoers file" → l'utilisateur courant n'a pas les
    droits d'administration sur cette machine ; contacter l'administrateur
    système.
  - exécuter `sudo rm -rf` sans avoir vérifié le chemin au préalable →
    DANGER, voir la mise en garde de la section 2.5 sur `rm`, aggravée ici
    par les privilèges administrateur qui suppriment toute protection.
DOCUMENTATION: https://www.sudo.ws/docs/man/sudo.man/ (documentation
         officielle du projet sudo)
EXERCISE: `sudo whoami` — la commande doit répondre `root`, confirmant
         l'élévation de privilèges pour cette seule commande.
```

```text
COMMAND: su
PURPOSE: ouvrir une nouvelle session sous l'identité d'un autre
         utilisateur (root par défaut sans argument), en restant connecté
         jusqu'à un `exit` explicite.
SYNTAX: su -            (bascule en root, avec l'environnement complet de root)
        su - utilisateur (bascule vers un utilisateur précis)
INTERPRETATION: le tiret (-) charge l'environnement complet de
         l'utilisateur cible (variables, dossier personnel) ; sans tiret,
         l'environnement de l'utilisateur d'origine est partiellement
         conservé, ce qui peut causer des comportements inattendus.
COMMON ERRORS:
  - rester connecté en root par oubli après une tâche ponctuelle →
    toujours `exit` dès la tâche terminée ; préférer sudo pour une
    commande isolée.
  - "Authentication failure" → mot de passe root incorrect, ou compte
    root désactivé (courant sur Ubuntu, qui privilégie sudo).
DOCUMENTATION: https://man7.org/linux/man-pages/man1/su.1.html
EXERCISE: sur une machine où le mot de passe root est connu, `su -` puis
         `whoami` (doit répondre `root`), puis `exit` pour revenir à
         l'utilisateur d'origine.
```

```text
COMMAND: adduser
PURPOSE: créer un nouveau compte utilisateur sur le système, de façon
         interactive (version conviviale de la commande bas niveau
         `useradd`).
SYNTAX: sudo adduser nom_utilisateur
OUTPUT: création du compte, de son dossier personnel (/home/nom_utilisateur),
         et de son groupe associé
INTERPRETATION: réservé aux administrateurs système ; sans lien avec le
         travail bioinformatique quotidien, mais utile à connaître pour
         configurer un serveur partagé ou une machine de calcul.
COMMON ERRORS:
  - "Permission denied" → nécessite sudo, car il s'agit d'une
    modification du système affectant tous les utilisateurs.
DOCUMENTATION: https://manpages.ubuntu.com/manpages/noble/en/man8/adduser.8.html
EXERCISE: (sur une machine de test, avec précaution) `sudo adduser test_user`
         et observer les questions posées.
```

```text
COMMAND: passwd
PURPOSE: changer le mot de passe de l'utilisateur courant (ou, avec
         sudo, celui d'un autre utilisateur).
SYNTAX: passwd                    (change son propre mot de passe)
        sudo passwd utilisateur   (change le mot de passe d'un autre utilisateur)
INTERPRETATION: demande l'ancien mot de passe avant le nouveau, sauf si
         exécuté avec sudo pour un autre compte.
COMMON ERRORS:
  - "password updated unsuccessfully" → le nouveau mot de passe ne
    respecte pas la politique de complexité du système.
DOCUMENTATION: https://man7.org/linux/man-pages/man1/passwd.1.html
EXERCISE: `passwd` et suivre les invites (annuler avec Ctrl+C si ce n'est
         qu'un test, pour ne pas changer réellement son mot de passe par
         erreur).
```

---

# 16. Pare-feu et services système

```text
COMMAND: ufw
PURPOSE: gérer le pare-feu du système de façon simplifiée (Uncomplicated
         Firewall), en autorisant ou bloquant du trafic réseau par port
         ou service.
SYNTAX: sudo ufw status
        sudo ufw allow 22        (autorise un port, ex. SSH)
        sudo ufw enable / disable
OUTPUT: confirmation textuelle de la règle appliquée, ou l'état actuel
         avec status
INTERPRETATION: sur une machine de calcul distante (HPC, cloud),
         désactiver par erreur l'accès SSH via une règle ufw trop
         restrictive peut couper tout accès à la machine — à manier avec
         prudence, toujours en gardant une session active pendant les
         tests.
COMMON ERRORS:
  - bloquer son propre accès SSH par une règle mal réfléchie sur une
    machine distante sans accès console de secours → vérifier
    `sudo ufw status` avant enable.
DOCUMENTATION: https://manpages.ubuntu.com/manpages/noble/en/man8/ufw.8.html
         (documentation officielle Ubuntu)
EXERCISE: `sudo ufw status` pour observer l'état actuel du pare-feu
         (actif/inactif) sans modifier de règle.
```

```text
COMMAND: iptables
PURPOSE: configurer le pare-feu du noyau Linux (netfilter) au niveau le
         plus bas — plus puissant et plus complexe que ufw, qui n'en est
         qu'une surcouche simplifiée.
SYNTAX: sudo iptables -L    (liste les règles actives)
OUTPUT: les règles de filtrage actuellement appliquées, par chaîne
         (INPUT, OUTPUT, FORWARD)
INTERPRETATION: ufw génère en réalité des règles iptables en arrière-plan ;
         consulter `iptables -L` permet de voir l'effet concret des
         règles ufw définies plus haut.
COMMON ERRORS:
  - modifier directement les règles iptables alors que ufw est actif →
    les deux peuvent entrer en conflit ; choisir l'un ou l'autre comme
    outil de gestion principal.
DOCUMENTATION: https://man7.org/linux/man-pages/man8/iptables.8.html
EXERCISE: `sudo iptables -L` pour observer les règles actuellement
         actives sur la machine.
```

```text
COMMAND: systemctl
PURPOSE: démarrer, arrêter, activer ou consulter l'état des services
         gérés par systemd (le système d'initialisation des distributions
         Linux modernes).
SYNTAX: systemctl status nom_service
        sudo systemctl start/stop/restart nom_service
        sudo systemctl enable nom_service   (démarrage automatique au boot)
OUTPUT: l'état du service (actif/inactif, PID, journal récent) ou
         confirmation de l'action
INTERPRETATION: utile pour vérifier qu'un service dont dépend un outil
         (ex. un serveur de base de données local) est bien démarré avant
         de lancer une analyse qui en a besoin.
COMMON ERRORS:
  - "Unit ... not found" → nom de service incorrect, ou service non
    installé.
  - "Permission denied" → start/stop/restart/enable nécessitent sudo ;
    status seul ne le nécessite pas toujours.
DOCUMENTATION: https://www.freedesktop.org/software/systemd/man/latest/systemctl.html
         (documentation officielle systemd)
EXERCISE: `systemctl status ssh` (ou un autre service installé) pour
         observer son état sans le modifier.
```

```text
COMMAND: reboot / shutdown
PURPOSE: redémarrer (reboot) ou éteindre (shutdown) la machine.
SYNTAX: sudo reboot
        sudo shutdown now       (extinction immédiate)
        sudo shutdown -h +10    (extinction planifiée dans 10 minutes)
INTERPRETATION: sur une machine de calcul distante (serveur, cluster HPC)
         partagée avec d'autres utilisateurs, ces commandes interrompent
         tous les travaux en cours pour tout le monde — à n'exécuter
         qu'avec une autorisation explicite et jamais par réflexe pour
         « réessayer » un problème.
COMMON ERRORS:
  - redémarrer une machine partagée par erreur, interrompant des calculs
    en cours appartenant à d'autres utilisateurs → vérifier
    systématiquement qu'on est bien sur sa propre machine locale avant
    d'exécuter reboot/shutdown.
DOCUMENTATION: https://man7.org/linux/man-pages/man8/reboot.8.html ·
         https://man7.org/linux/man-pages/man8/shutdown.8.html
EXERCISE: `shutdown -h +10` puis annuler avec `sudo shutdown -c` avant
         l'échéance, pour observer le mécanisme sans réellement éteindre
         la machine.
```

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
```text
SYMPTOM: "user is not in the sudoers file" ou "Permission denied" avec sudo/apt/chown
CAUSE: l'utilisateur courant n'a pas les privilèges administrateur requis
       sur cette machine.
DIAGNOSIS: `sudo -l` liste ce que l'utilisateur courant est autorisé à
           exécuter avec sudo.
SOLUTION: contacter l'administrateur de la machine pour obtenir les droits
          nécessaires ; ne jamais tenter de contourner cette limitation.
PREVENTION: vérifier ses droits (`sudo -l`) avant de bâtir un script qui
            en dépend.
```
```text
SYMPTOM: "Name or service not known" avec ping/curl, ou timeout réseau
CAUSE: problème de résolution DNS, de connexion réseau, ou pare-feu
       bloquant le trafic.
DIAGNOSIS: `ping -c 4 8.8.8.8` (teste le réseau par adresse IP directe) puis
           `resolvectl status` (teste la résolution DNS) pour isoler
           laquelle des deux couches est en cause.
SOLUTION: selon le diagnostic, vérifier la connexion réseau elle-même, la
          configuration DNS, ou les règles `ufw`/`iptables` en vigueur.
PREVENTION: tester `ping` vers une adresse connue avant de suspecter à
            tort un outil de téléchargement bioinformatique.
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

Command: vim
Official documentation: https://www.vim.org/docs.php
Topics to explore: vimtutor, macros, édition multi-fichiers (buffers, splits)

Command: ss / ip
Official documentation: https://man7.org/linux/man-pages/man8/ss.8.html
Topics to explore: iproute2 en profondeur (routage, VLAN, espaces de noms réseau)

Command: systemctl
Official documentation: https://www.freedesktop.org/software/systemd/man/latest/systemctl.html
Topics to explore: journalctl (journaux de service), unités timer, services utilisateur
```

DOCUMENTATION
------------------------------------------------------------
- GNU Coreutils Manual — https://www.gnu.org/software/coreutils/manual/coreutils.html
- GNU Findutils Manual — https://www.gnu.org/software/findutils/manual/
- GNU Diffutils Manual — https://www.gnu.org/software/diffutils/manual/diffutils.html
- GNU Bash Reference Manual — https://www.gnu.org/software/bash/manual/bash.html
- less (pager) — https://www.greenwoodsoftware.com/less/ · source : https://github.com/gwsw/less
- htop — https://htop.dev/ · source : https://github.com/htop-dev/htop
- procps-ng (ps, top, free, kill) — https://gitlab.com/procps-ng/procps
- GNU nano — https://www.nano-editor.org/dist/latest/nano.html
- Vim — https://www.vim.org/docs.php
- Linux man-pages project — https://man7.org/linux/man-pages/
- sudo — https://www.sudo.ws/docs/man/sudo.man/
- iproute2 (ip, ss) — https://man7.org/linux/man-pages/man8/ip.8.html
- systemd (systemctl, resolvectl) — https://www.freedesktop.org/software/systemd/man/latest/systemctl.html
- Ubuntu/Debian manpages (apt, adduser, ufw) — https://manpages.ubuntu.com/

NEXT MODULE
------------------------------------------------------------
`02_linux_for_bioinformatics/` — appliquer ces commandes aux tout premiers
fichiers FASTA et FASTQ du dépôt.
