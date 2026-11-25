# Chapitre 10 — L'environnement du shell : variables, guillemets, PATH et .bashrc

> **Durée estimée** : 2 h
> **Prérequis** : [chapitre 09](../09_processus/README.md)
> **Chapitre suivant** : [11 — Installer des logiciels](../11_installer_logiciels/README.md)

## Ce que vous saurez faire à la fin de ce chapitre

- Créer et utiliser des **variables** du shell, et transformer un nom de
  fichier (`${f%.fastq.gz}`).
- Choisir entre guillemets doubles, apostrophes et absence de guillemets,
  et savoir **pourquoi**.
- Comprendre comment le shell trouve les programmes (`PATH`), et pourquoi
  `./` est parfois nécessaire.
- Distinguer une variable ordinaire d'une variable d'**environnement**
  (`export`).
- Éditer un fichier texte dans le terminal avec **nano**, et personnaliser
  votre shell (`~/.bashrc`, alias).

---

## 1. Pourquoi

Les chapitres suivants vont vous faire écrire des **scripts** (chapitre 12)
et installer des **logiciels** (chapitre 11). Les deux reposent sur ce
chapitre :

- un script qui traite 12 échantillons manipule des **variables** :
  `$echantillon`, `$fichier_R1`… ;
- la moitié des bugs de scripts viennent de **guillemets** mal choisis ;
- « J'ai installé l'outil, mais j'obtiens `command not found` » : c'est
  presque toujours une question de **`PATH`**.

---

## 2. Une image pour comprendre : le carnet de paillasse et l'annuaire

- Une **variable** est une étiquette sur un flacon : `echantillon=P07`
  colle l'étiquette `echantillon` sur le contenu `P07`. Ensuite,
  `$echantillon` signifie « le contenu du flacon étiqueté `echantillon` ».
- Le **`PATH`** est l'**annuaire** que consulte le shell pour trouver un
  programme : une liste de dossiers, parcourue dans l'ordre. Un programme
  installé dans un dossier absent de l'annuaire est introuvable, même s'il
  existe bel et bien.

---

## 3. Les variables

### 3.1 Créer et utiliser

```bash
cd ~/formation_linux
echantillon=P07
echo $echantillon
echo "Analyse de $echantillon"
```

```text
P07
Analyse de P07
```

- **Pas d'espace autour de `=`.** Sinon, le shell croit que `echantillon`
  est une commande :

  ```text
  $ echantillon = P07
  echantillon: command not found
  ```

- On **lit** une variable avec `$` devant son nom.
- Les noms contiennent des lettres, des chiffres et `_`, et ne commencent
  pas par un chiffre. Par convention, les variables qu'on crée soi-même
  sont en minuscules.

Une variable rend une commande réutilisable :

```bash
fichier=run_sequencage/fastq/P07_S7_L001_R1_001.fastq.gz
zcat "$fichier" | head -n 1
echo "$(( $(zcat "$fichier" | wc -l) / 4 )) reads dans $fichier"
```

### 3.2 Les accolades : délimiter le nom

```bash
e=P07
echo "$e_R1"
echo "${e}_R1"
```

```text

P07_R1
```

La première ligne est **vide** : le shell a cherché une variable nommée
`e_R1`, qui n'existe pas, puisque `_` peut faire partie d'un nom.
`${e}` délimite clairement le nom. **Écrivez `${variable}` dès qu'un
caractère suit directement le nom.**

### 3.3 Transformer un nom de fichier

Le shell sait découper le contenu d'une variable. C'est indispensable pour
fabriquer le nom d'un fichier de sortie à partir de celui d'un fichier
d'entrée :

```bash
f=P07_S7_L001_R1_001.fastq.gz
echo "${f%.fastq.gz}"
echo "${f%%_*}"
echo "${f/R1/R2}"
echo "${#f}"
```

```text
P07_S7_L001_R1_001
P07
P07_S7_L001_R2_001.fastq.gz
27
```

| Écriture | Effet | Usage typique |
|---|---|---|
| `${f%motif}` | retire le **plus court** `motif` à la **fin** | retirer une extension : `${f%.fastq.gz}` |
| `${f%%motif}` | retire le **plus long** `motif` à la fin | garder le nom d'échantillon : `${f%%_*}` |
| `${f#motif}` | retire le plus court `motif` au **début** | retirer un préfixe ou un chemin : `${f#*/}` |
| `${f##*/}` | retire tout jusqu'au dernier `/` | le nom du fichier sans son dossier |
| `${f/a/b}` | remplace la première occurrence de `a` par `b` | du nom du R1 déduire celui du R2 |
| `${#f}` | longueur | |
| `${v:-défaut}` | `défaut` si `v` est vide ou non définie | valeur par défaut d'un paramètre |

Dans les motifs, `*` a le même sens que pour les jokers (chapitre 03).

### 3.4 Supprimer une variable

`unset echantillon` la supprime. Une variable inexistante est **vide**,
sans message d'erreur : c'est une source de bugs silencieux, et c'est
pourquoi le chapitre 13 vous apprendra `set -u`.

---

## 4. Les guillemets : la règle qui évite la moitié des bugs

### 4.1 Trois comportements

```bash
echo "$HOME"
echo '$HOME'
echo \$HOME
```

```text
/home/marie
$HOME
$HOME
```

| Écriture | Ce que le shell fait à l'intérieur | Usage |
|---|---|---|
| `"guillemets doubles"` | remplace `$variable`, `$( )` et `$(( ))` ; **ne découpe pas** aux espaces | **par défaut**, autour de toute variable |
| `'apostrophes'` | **rien** : tout est pris littéralement | programmes `awk` et `sed`, regex, texte contenant `$` |
| sans guillemets | remplace **et découpe** aux espaces, développe les jokers | rarement souhaitable avec une variable |
| `\` devant un caractère | rend ce caractère littéral | `\$`, `\"` |

### 4.2 Pourquoi `"$variable"` et pas `$variable`

```bash
nom="mes resultats finaux.txt"
head -n 1 pieges/$nom
head -n 1 "pieges/$nom"
```

```text
head: cannot open 'pieges/mes' for reading: No such file or directory
head: cannot open 'resultats' for reading: No such file or directory
head: cannot open 'finaux.txt' for reading: No such file or directory
Ce fichier a un nom contenant des espaces.
```

Sans guillemets, le contenu de la variable est découpé aux espaces, comme au
chapitre 01. **Règle : entourez toujours vos variables de guillemets
doubles**, `"$fichier"`, sauf raison précise.

### 4.3 Pourquoi les apostrophes autour d'awk

Dans `awk '{ print $1 }'`, le `$1` doit arriver **intact** à awk. Avec des
guillemets doubles, le shell le remplacerait d'abord par sa propre variable
`$1` (vide au terminal), et awk recevrait `{ print  }`. C'était la règle
annoncée au chapitre 07 : **programme awk ou sed entre apostrophes**.

Pour passer une variable du shell à awk, utilisez `-v` :

```bash
seuil=800
awk -v s="$seuil" '$3 - $2 > s { print $4 }' formats/genes.bed
```

---

## 5. `PATH` : comment le shell trouve les programmes

### 5.1 L'annuaire

```bash
echo "$PATH" | tr ":" "\n"
```

Sur un Ubuntu ordinaire, la sortie commence ainsi :

```text
/usr/local/sbin
/usr/local/bin
/usr/sbin
/usr/bin
/sbin
/bin
...
```

Quand vous tapez `ls`, le shell cherche un fichier exécutable nommé `ls`
dans chacun de ces dossiers, **dans l'ordre**, et lance le premier trouvé.
`type` et `which` disent lequel :

```bash
type ls
which ls
```

```text
ls is /usr/bin/ls
/usr/bin/ls
```

> **Sous WSL**, votre `PATH` contient aussi des dizaines de dossiers
> Windows (`/mnt/c/WINDOWS/system32`…), qui permettent de lancer des
> programmes Windows depuis Linux. C'est normal. Mais c'est aussi pourquoi
> il faut vérifier avec `type` qu'on utilise bien la version Linux d'un
> outil (par exemple `python3`), et non sa version Windows.

### 5.2 Pourquoi `./` ?

```bash
printf '#!/bin/bash\necho Bonjour\n' > salut
chmod u+x salut
salut
./salut
```

```text
salut: command not found
Bonjour
```

Le dossier courant **n'est pas** dans le `PATH` : c'est une mesure de
sécurité, qui évite qu'un fichier piégé nommé `ls` déposé dans un dossier
soit lancé à la place du vrai `ls`. `./salut` donne un **chemin**, ce qui
dispense de consulter l'annuaire.

### 5.3 Ajouter un dossier au `PATH`

On range souvent ses propres scripts dans `~/bin` :

```bash
mkdir -p ~/bin
mv salut ~/bin/
PATH="$HOME/bin:$PATH"
salut
type salut
```

```text
Bonjour
salut is /home/marie/bin/salut
```

`PATH="$HOME/bin:$PATH"` **ajoute** `~/bin` au début de l'annuaire, en
conservant le reste. Écrire `PATH=~/bin` **remplacerait** tout l'annuaire,
et plus aucune commande ne serait trouvée :

```text
$ bash -c 'PATH=/nulle/part; ls'
bash: line 1: ls: command not found
```

Si cela vous arrive au terminal, fermez-le et ouvrez-en un nouveau : la
modification ne dure que le temps de la session (section 7 pour la rendre
permanente).

> **C'est exactement ce que fait Conda** (chapitre 11) : « activer » un
> environnement place son dossier `bin/` en tête du `PATH`, et le
> « désactiver » le retire.

---

## 6. Variables d'environnement et `export`

Une variable créée au terminal n'existe **que dans ce shell**. Les
programmes qu'il lance (un script, un autre `bash`) ne la voient pas, sauf
si on l'**exporte** :

```bash
couleur=rouge
bash -c 'echo "enfant : [$couleur]"'
export couleur
bash -c 'echo "enfant : [$couleur]"'
```

```text
enfant : []
enfant : [rouge]
```

Les variables exportées forment l'**environnement**, transmis à chaque
programme lancé. Quelques variables importantes existent déjà :

| Variable | Contenu |
|---|---|
| `HOME` | votre dossier personnel (`~` en est le raccourci) |
| `USER` | votre nom d'utilisateur |
| `PWD` | le dossier courant |
| `PATH` | l'annuaire des programmes |
| `SHELL` | votre shell (`/bin/bash`) |
| `LANG` | la langue et l'encodage des caractères |

`env` les affiche toutes, et `env | grep PATH` en filtre une.

---

## 7. Éditer un fichier : nano

Jusqu'ici, vous avez écrit dans des fichiers avec `echo` et `>`. Pour un
vrai texte (un script, un fichier de configuration), il faut un **éditeur
de texte** dans le terminal. **nano** est le plus simple, et il est
installé partout.

```bash
nano notes.txt
```

L'éditeur occupe tout le terminal. Tapez du texte normalement : les
flèches déplacent le curseur. Les raccourcis sont rappelés en bas de
l'écran, où `^` signifie **Ctrl** :

| Touches | Action |
|---|---|
| **Ctrl+O** puis Entrée | enregistrer (*Write Out*) |
| **Ctrl+X** | quitter ; nano demande s'il faut enregistrer les modifications (`Y` / `N`) |
| **Ctrl+W** | rechercher |
| **Ctrl+K** / **Ctrl+U** | couper la ligne / coller |
| **Alt+U** | annuler la dernière modification |

> **vim**, l'autre éditeur omniprésent sur les serveurs, est bien plus
> puissant mais déroutant au début. Si vous vous retrouvez dedans par
> accident (par exemple après une commande `git`), appuyez sur **Échap**,
> tapez `:q!` puis Entrée pour quitter sans rien enregistrer. Pour
> l'apprendre plus tard : la commande `vimtutor`.

---

## 8. Personnaliser son shell : `~/.bashrc` et les alias

### 8.1 Le fichier `~/.bashrc`

À chaque ouverture d'un terminal, bash lit le fichier caché `~/.bashrc` et
exécute les commandes qu'il contient. C'est là qu'on place ce qui doit
devenir **permanent** : ajouts au `PATH`, alias, réglages.

```bash
ls -a ~
```

Vous y voyez `.bashrc`, `.profile`, `.bash_history` (votre historique de
commandes)… Ouvrez-le avec `nano ~/.bashrc` : Ubuntu y a déjà placé des
réglages commentés (les lignes qui commencent par `#` sont des
commentaires, ignorées par bash).

### 8.2 Les alias

Un **alias** est un raccourci pour une commande :

```bash
alias ll='ls -lhF'
ll formats
```

Le `.bashrc` d'Ubuntu en définit déjà quelques-uns, dont
`alias ll='ls -alF'`. Pour rendre un alias permanent, ajoutez-le **à la
fin** de `~/.bashrc`, avec nano, puis relisez le fichier dans le terminal
courant :

```bash
source ~/.bashrc
```

Sans `source`, le changement ne s'appliquera qu'aux **prochains**
terminaux.

> **Attention** : modifier `.bashrc` modifie **tous** vos futurs
> terminaux. Une erreur de syntaxe s'affichera à chaque ouverture. En cas
> de problème, rouvrez le fichier avec `nano ~/.bashrc` et corrigez-le.
> Avant une modification importante, faites une copie de sauvegarde :
> `cp ~/.bashrc ~/.bashrc.sauvegarde`.

### 8.3 Ce qu'on met typiquement dans `.bashrc`

```bash
# Mes scripts personnels
export PATH="$HOME/bin:$PATH"

# Raccourcis
alias ll='ls -lhF'
alias formation='cd ~/formation_linux'
```

Sur un serveur, on y ajoute souvent des réglages propres au centre de calcul
(chargement de modules, chapitre 11). Conda y écrit aussi automatiquement
ses propres lignes lors de son installation.

---

## 9. Pièges fréquents

| Situation | Symptôme | Solution |
|---|---|---|
| `var = valeur` | `var: command not found` | `var=valeur`, sans espace |
| `"$e_R1"` au lieu de `"${e}_R1"` | variable vide | accolades |
| variable sans guillemets contenant des espaces | `No such file or directory` en plusieurs morceaux | `"$variable"` |
| programme awk entre guillemets doubles | `$1` vide ou erreur de syntaxe awk | apostrophes ; `awk -v` pour passer une variable |
| `PATH=~/bin` | plus aucune commande trouvée | `PATH="$HOME/bin:$PATH"` ; ouvrir un nouveau terminal |
| script dans le dossier courant | `command not found` | `./script` |
| variable invisible dans un script lancé | elle est vide dans le script | `export`, ou la passer en argument (chapitre 12) |
| modification de `.bashrc` sans effet | — | `source ~/.bashrc`, ou nouveau terminal |
| outil installé mais introuvable | `command not found` | `type outil` ; vérifier le `PATH` (environnement Conda actif ? chapitre 11) |

---

## 10. À vous de jouer

Commencez par `cd ~/formation_linux`.

### Exercice 1 : un nom d'échantillon dans une variable

*Objectif : variables et `${ }`.*
Mettez `P09` dans une variable `ech`. En n'utilisant que cette variable,
affichez le nombre de reads de son fichier R1, sous la forme
`P09 : 150 reads`.

<details>
<summary>Corrigé</summary>

```bash
ech=P09
r1=$(ls run_sequencage/fastq/${ech}_*_R1_001.fastq.gz)
echo "${ech} : $(( $(zcat "$r1" | wc -l) / 4 )) reads"
```

```text
P09 : 150 reads
```

Changer `ech=P09` en `ech=P10` suffit pour refaire le calcul : c'est
exactement ce que fera une boucle au chapitre 12.
</details>

### Exercice 2 : fabriquer des noms de fichiers

*Objectif : `${f%…}`, `${f%%…}`, `${f/…/…}`.*
À partir de `f=P07_S7_L001_R1_001.fastq.gz`, affichez : (a) le nom du
fichier R2 correspondant ; (b) le nom d'échantillon seul ; (c) un nom de
fichier de sortie `P07_S7_L001_R1_001.stats.txt`.

<details>
<summary>Corrigé</summary>

```bash
f=P07_S7_L001_R1_001.fastq.gz
echo "${f/R1/R2}"
echo "${f%%_*}"
echo "${f%.fastq.gz}.stats.txt"
```
</details>

### Exercice 3 : prédire avant d'exécuter

*Objectif : guillemets.*
Prédisez la sortie de chaque ligne, puis vérifiez :

```bash
x=GGATCC
echo "Site : $x"
echo 'Site : $x'
echo "Prix : 5 \$, site : $x"
grep -c "$x" formats/reference.fasta
awk -v m="$x" '$0 ~ m' formats/reference.fasta | wc -l
```

<details>
<summary>Corrigé</summary>

```text
Site : GGATCC
Site : $x
Prix : 5 $, site : GGATCC
5
5
```

Les apostrophes empêchent le remplacement ; `\$` affiche un dollar
littéral. Les deux dernières commandes comptent les lignes qui contiennent
le site BamHI, l'une avec grep, l'autre avec awk.
</details>

### Exercice 4 : votre propre commande

*Objectif : `PATH` et `~/bin`.*
Créez `~/bin/compte_fasta`, un script qui affiche le nombre de séquences
du fichier FASTA donné en argument (`$1` désigne le premier argument d'un
script, chapitre 12). Rendez-le utilisable depuis n'importe quel dossier,
**de façon permanente**.

<details>
<summary>Corrigé</summary>

```bash
mkdir -p ~/bin
nano ~/bin/compte_fasta
```

Contenu du fichier :

```bash
#!/bin/bash
grep -c "^>" "$1"
```

Puis :

```bash
chmod u+x ~/bin/compte_fasta
nano ~/.bashrc                 # ajouter à la fin : export PATH="$HOME/bin:$PATH"
source ~/.bashrc
cd /tmp
compte_fasta ~/formation_linux/genome.fasta
```

```text
22
```

Sur Ubuntu, le fichier `~/.profile` ajoute déjà `~/bin` au `PATH` s'il
existe au moment de la connexion. Ajouter la ligne à `.bashrc` rend la
configuration explicite et fiable dans tous les cas.
</details>

### Exercice 5 : un alias de formation

*Objectif : `.bashrc` et alias.*
Créez un alias permanent `bac` qui vous place dans votre bac à sable et
affiche son contenu.

<details>
<summary>Corrigé</summary>

Ajoutez à la fin de `~/.bashrc` :

```bash
alias bac='cd ~/formation_linux && ls -F'
```

Puis `source ~/.bashrc`, et tapez `bac` depuis n'importe où.
</details>

---

## 11. Défi : le détective du `PATH`

1. Quel est le **premier** dossier du `PATH` qui contient `python3` sur
   votre machine ? Existe-t-il d'autres `python3` plus loin dans le
   `PATH` ?
2. Créez dans `~/bin` un script nommé `ls` qui affiche `Je ne suis pas le
   vrai ls !`. Après avoir placé `~/bin` en tête du `PATH`, que se passe-t-il
   quand vous tapez `ls` ? Comment le voir avec `type` ? Supprimez ensuite
   ce faux `ls`.

<details>
<summary>Indice</summary>

`type -a commande` affiche **toutes** les versions d'une commande trouvées
dans le `PATH`, dans l'ordre.
</details>

<details>
<summary>Corrigé</summary>

```bash
type -a python3
```

La première ligne indique la version utilisée (`/usr/bin/python3`). Sous
WSL, d'autres lignes peuvent montrer des versions Windows dans `/mnt/c/…`.

```bash
printf '#!/bin/bash\necho "Je ne suis pas le vrai ls !"\n' > ~/bin/ls
chmod u+x ~/bin/ls
export PATH="$HOME/bin:$PATH"
hash -r
ls
type -a ls
rm ~/bin/ls
hash -r
```

Le faux `ls` est exécuté, car `~/bin` est le premier dossier de
l'annuaire. `hash -r` vide la mémoire du shell, qui retient l'emplacement
des commandes déjà utilisées. Bash la vide de lui-même quand on modifie
`PATH`, mais pas quand on supprime un programme : sans le second
`hash -r`, le shell chercherait encore `~/bin/ls`, qui n'existe plus. C'est précisément pour éviter ce genre de
piège que le dossier courant n'est **jamais** dans le `PATH`, et qu'on
ajoute toujours ses propres dossiers en connaissance de cause.
</details>

---

## L'essentiel

```text
var=valeur (sans espace)     "$var"   "${var}_suite"   unset var
${f%.fastq.gz}  ${f%%_*}  ${f##*/}  ${f/R1/R2}  ${#f}  ${v:-défaut}
"doubles"  : remplace $var et $( ), ne découpe pas → par défaut
'simples'  : littéral → awk, sed, regex
PATH : annuaire des programmes ; type -a cmd ; ./script si hors PATH
PATH="$HOME/bin:$PATH"      ajouter (jamais remplacer)
export VAR                  transmettre aux programmes lancés ; env
nano fichier   Ctrl+O enregistrer · Ctrl+X quitter    (vim : Échap :q!)
~/.bashrc : réglages permanents ; alias nom='commande' ; source ~/.bashrc
```

### Auto-évaluation

- [ ] Je crée une variable et je l'utilise entre guillemets doubles.
- [ ] Je fabrique un nom de fichier de sortie à partir d'un nom d'entrée.
- [ ] Je sais quand utiliser des apostrophes plutôt que des guillemets.
- [ ] J'explique pourquoi `./script` est nécessaire et ce que contient `PATH`.
- [ ] J'édite un fichier avec nano, j'enregistre et je quitte.
- [ ] J'ai ajouté un alias ou un dossier au `PATH` de façon permanente.

## Documentation officielle

- Paramètres et expansions (manuel de Bash) : <https://www.gnu.org/software/bash/manual/html_node/Shell-Parameter-Expansion.html>
- Guillemets (manuel de Bash, *Quoting*) : <https://www.gnu.org/software/bash/manual/html_node/Quoting.html>
- Fichiers de démarrage de Bash : <https://www.gnu.org/software/bash/manual/html_node/Bash-Startup-Files.html>
- GNU nano : <https://www.nano-editor.org/docs.php>

**Prochaine étape** : [chapitre 11 — Installer des logiciels](../11_installer_logiciels/README.md).
