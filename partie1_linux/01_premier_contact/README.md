# Chapitre 01 — Premier contact avec le terminal

> **Durée estimée** : 1 h 30
> **Prérequis** : [chapitre 00](../00_bienvenue_installation/README.md) (bac à sable installé)
> **Chapitre suivant** : 02 — Le système de fichiers *(en cours de rédaction)*

## Ce que vous saurez faire à la fin de ce chapitre

- Expliquer avec vos mots ce que sont Linux, le shell et le terminal.
- Lire l'invite de commande et décomposer n'importe quelle commande en
  *commande*, *options* et *arguments*.
- Utiliser les raccourcis qui évitent 90 % des erreurs de frappe
  (Tab, flèches, Ctrl+C).
- Trouver seul l'aide d'une commande (`--help`, `man`).
- Lire un message d'erreur et en déduire quoi corriger.

---

## 1. Pourquoi taper des commandes plutôt que cliquer ?

Imaginez la situation. Votre plateforme de séquençage vous envoie un dossier
contenant 24 fichiers de reads. Vous devez savoir combien de reads contient
chaque fichier, repérer l'échantillon raté, puis lancer le même contrôle
qualité sur tous les autres.

Avec la souris, il faudrait ouvrir les fichiers un par un, et beaucoup sont
trop gros pour un tableur. En ligne de commande, c'est une seule ligne, que
vous saurez écrire au chapitre 05.

Il y a trois raisons de fond :

1. **Les outils de bioinformatique n'ont souvent pas d'interface
   graphique.** On les pilote en tapant des commandes.
2. **Les serveurs de calcul n'ont pas d'écran.** On s'y connecte à
   distance, et seul un terminal est disponible (chapitre 14).
3. **Une commande écrite est un protocole reproductible.** Comme un
   protocole de paillasse, elle se note, se relit, se partage et se
   rejoue à l'identique. Une suite de clics ne laisse aucune trace.

---

## 2. Une image pour comprendre : Linux, le shell, le terminal

Imaginez un **laboratoire**.

| Dans le laboratoire | Sur l'ordinateur | Son rôle |
|---|---|---|
| Les services techniques du bâtiment (électricité, accès aux instruments, stockage) | Le **noyau** Linux (*kernel*) | Gère le matériel : processeur, mémoire, disque. On ne lui parle jamais directement |
| Le technicien qui lit vos demandes écrites et fait fonctionner les instruments | Le **shell** (ici **bash**) | Lit la commande que vous tapez, l'interprète et lance le bon programme |
| Les instruments (centrifugeuse, thermocycleur…) | Les **programmes** (`head`, `wc`, `samtools`…) | Font chacun une tâche précise |
| Le guichet où vous déposez vos demandes | Le **terminal** | La fenêtre où vous tapez et où les réponses s'affichent |

Quand vous tapez une commande, voici ce qui se passe : le **terminal**
transmet le texte au **shell**, qui le découpe, comprend quel
**programme** lancer, et le noyau exécute ce programme. Le résultat revient
ensuite s'afficher dans le terminal.

> **Limite de l'image** : le technicien (le shell) n'improvise jamais. Il
> exécute **exactement** ce que vous avez écrit, fautes comprises, sans
> deviner votre intention. C'est la principale différence avec un
> collègue humain, et la source de la plupart des erreurs de débutant.

« Linux » désigne, au sens strict, le noyau. Dans l'usage courant, le mot
désigne tout le système (noyau, shell et programmes). **Ubuntu** est une
**distribution** Linux, c'est-à-dire un assemblage prêt à l'emploi de tous
ces éléments.

---

## 3. Lire l'invite de commande

Ouvrez votre terminal Ubuntu. La ligne qui attend votre saisie s'appelle
l'**invite de commande** (*prompt*) :

```text
marie@PC-LABO:~$
```

| Partie | Signification |
|---|---|
| `marie` | votre nom d'utilisateur |
| `@PC-LABO` | le nom de la machine (utile quand on travaille sur plusieurs serveurs) |
| `:~` | le dossier où vous vous trouvez. `~` est un raccourci pour votre dossier personnel (chapitre 02) |
| `$` | « je suis prêt, j'attends une commande ». Il devient `#` si vous êtes administrateur (chapitre 08) |

Dans ce cours, les commandes sont écrites **sans** l'invite, pour que vous
puissiez les copier directement.

---

## 4. Vos premières commandes

Tapez la commande suivante et appuyez sur **Entrée** :

```bash
echo Bonjour
```

Sortie :

```text
Bonjour
```

`echo` affiche simplement le texte qu'on lui donne. Essayez maintenant :

```bash
whoami
date
```

Sortie (votre nom et la date du jour, bien sûr) :

```text
marie
Tue Nov 24 22:47:45 +00 2026
```

`whoami` (*who am I ?*) affiche votre nom d'utilisateur et `date` affiche
la date et l'heure. Après chaque réponse, l'invite réapparaît : le shell
attend la commande suivante.

> **Bon réflexe** : beaucoup de commandes **n'affichent rien quand tout se
> passe bien**. Pas de message ne veut pas dire que rien ne s'est passé :
> la plupart du temps, cela veut dire que tout s'est bien passé.

Rendez-vous maintenant dans votre bac à sable. Copiez cette commande telle
quelle ; la commande `cd` sera expliquée en détail au chapitre 02 :

```bash
cd ~/formation_linux
```

L'invite affiche maintenant `marie@PC-LABO:~/formation_linux$` : vous êtes
dans le dossier des exercices.

---

## 5. Anatomie d'une commande

### 5.1 Le principe

Toute commande suit la même structure, comme une phrase :

```text
commande   [options]   [arguments]
  verbe     adverbes     complément
```

- La **commande** est le nom du programme à lancer : *que faire ?*
- Les **options** modifient son comportement : *comment le faire ?*
  Elles commencent par un tiret.
- Les **arguments** indiquent sur quoi agir : *sur quoi ?* Ce sont
  souvent des noms de fichiers.
- Les **espaces** séparent ces éléments. Ils sont indispensables.

Les crochets `[ ]` signifient « facultatif » ; on ne les tape pas.

### 5.2 Démonstration : afficher le début d'un fichier de séquences

`head` affiche le début d'un fichier. **Avant d'exécuter la commande
suivante, essayez de prédire ce qu'elle va afficher.**

```bash
head -n 3 genome.fasta
```

Sortie :

```text
>seq_exercice_01 organism=synthetic type=demo length=51
ATGCGTACGTTAGCTAGCTAGCTAGGCTAACGTTACGTAGCTAGCTGATCG
>seq_exercice_02 organism=synthetic type=demo length=49
```

| Élément | Rôle | Type |
|---|---|---|
| `head` | afficher le début d'un fichier | commande |
| `-n 3` | « seulement 3 lignes » (10 par défaut) | option, avec sa valeur |
| `genome.fasta` | le fichier à lire | argument |

Vous venez de lire un fichier **FASTA**, le format le plus courant pour
stocker des séquences. Chaque séquence commence par une ligne d'en-tête
débutant par `>`, suivie de la séquence elle-même. Ce format sera étudié en
détail au chapitre 04.

### 5.3 Les variantes d'écriture des options

```bash
head --lines=3 genome.fasta
```

Cette commande donne exactement le même résultat. Beaucoup d'options
existent en deux versions :

| Forme | Exemple | Usage |
|---|---|---|
| **courte** : un tiret, une lettre | `-n 3` | rapide à taper |
| **longue** : deux tirets, un mot | `--lines=3` | plus lisible, idéale dans les scripts |

Plusieurs options courtes peuvent se regrouper derrière un seul tiret :
`ls -l -h` s'écrit aussi `ls -lh` (vous l'utiliserez au chapitre 02).

### 5.4 Plusieurs arguments

```bash
head -n 1 genome.fasta proteins.fasta
```

Sortie :

```text
==> genome.fasta <==
>seq_exercice_01 organism=synthetic type=demo length=51

==> proteins.fasta <==
>prot_001 organism=Homo_sapiens type=protein length=217
```

Avec plusieurs fichiers, `head` traite chacun d'eux et indique son nom
avant son contenu.

### 5.5 Deux règles qui piègent tous les débutants

**Règle 1 : Linux distingue les majuscules des minuscules.** `head` et
`HEAD` sont deux mots différents, tout comme `Genome.fasta` et
`genome.fasta`.

**Règle 2 : les espaces séparent les arguments.** Comparez :

```bash
echo Bonjour   le   monde
echo "Bonjour   le   monde"
```

Sortie :

```text
Bonjour le monde
Bonjour   le   monde
```

Sans guillemets, le shell voit trois arguments (`Bonjour`, `le`, `monde`) et
`echo` les réaffiche séparés par un seul espace. Avec guillemets, il n'y a
qu'**un seul** argument, espaces compris. Cette règle explique pourquoi
**les noms de fichiers ne doivent pas contenir d'espaces** : le shell
découperait le nom en plusieurs morceaux. Vous le vérifierez à
l'exercice 5, et le chapitre 10 approfondit les guillemets.

---

## 6. Le clavier : vos meilleurs alliés

Ces raccourcis vous feront gagner un temps considérable et vous éviteront
la plupart des fautes de frappe. Essayez chacun d'eux maintenant.

| Touche | Effet | Pourquoi c'est précieux |
|---|---|---|
| **Tab** | complète le nom de commande ou de fichier commencé | plus de fautes de frappe dans les noms de fichiers |
| **Tab Tab** (deux fois) | liste toutes les possibilités quand il y en a plusieurs | on découvre ce qui existe |
| **↑** / **↓** | remonte / redescend dans les commandes déjà tapées | on corrige une commande sans tout retaper |
| **Ctrl+R** | recherche dans l'historique (tapez un morceau de commande) | on retrouve une commande d'il y a une semaine |
| **Ctrl+C** | **interrompt** la commande en cours | on reprend la main sur un programme bloqué ou trop long |
| **Ctrl+L** | efface l'écran (comme la commande `clear`) | on y voit plus clair |
| **Ctrl+A** / **Ctrl+E** | va au début / à la fin de la ligne | on corrige le début d'une longue commande |

### Essayez la complétion

Tapez `head -n 2 trans` **sans appuyer sur Entrée**, puis appuyez sur
**Tab**. Le shell complète en `head -n 2 transcripts.fasta`, car c'est le
seul fichier qui commence par `trans`. Appuyez maintenant sur Entrée.

Tapez ensuite `head sa`, puis **Tab** deux fois. Rien ne se complète, car
trois fichiers commencent par `sa` : ils s'affichent tous les trois.
Ajoutez `mple_02` et terminez avec Tab.

> **Bon réflexe** : **si Tab ne complète pas, c'est un indice.** Soit le
> fichier n'existe pas à cet endroit, soit plusieurs noms correspondent.
> Ce simple réflexe prévient la plupart des erreurs
> `No such file or directory`.

### Essayez Ctrl+C

`sleep 100` attend 100 secondes sans rien faire. Lancez-le, constatez que
l'invite ne revient pas, puis appuyez sur **Ctrl+C** :

```bash
sleep 100
```

Sortie après Ctrl+C :

```text
^C
marie@PC-LABO:~/formation_linux$
```

`^C` est la façon dont le terminal note Ctrl+C. L'invite est revenue :
vous avez repris la main.

### Les deux « blocages » classiques, et comment en sortir

**Le terminal semble figé, sans invite.** Tapez `head` seul, sans nom de
fichier, puis Entrée : rien ne se passe. Le programme n'est pas planté, il
**attend que vous tapiez du texte** au clavier, faute de fichier à lire.
Appuyez sur **Ctrl+C** pour sortir.

**L'invite est devenue `>`.** Tapez `echo "bonjour` (guillemet non
refermé), puis Entrée :

```text
>
```

Le shell attend la suite de votre texte, car vous avez ouvert des
guillemets sans les refermer. Appuyez sur **Ctrl+C** pour abandonner.

| Ce que vous voyez | Ce qui se passe | Comment en sortir |
|---|---|---|
| Rien, pas d'invite | le programme travaille, ou attend du texte au clavier | **Ctrl+C** |
| Une invite `>` | guillemet ou parenthèse non refermé | **Ctrl+C** |
| Du texte avec `:` ou `(END)` en bas de l'écran | vous êtes dans un afficheur page par page (`man`, `less`) | **q** |

---

## 7. Trouver de l'aide seul

Personne ne retient toutes les options de toutes les commandes. Les
professionnels non plus : ils savent **où chercher**.

### 7.1 `--help` : le résumé rapide

```bash
wc --help
```

Sortie (début) :

```text
Usage: wc [OPTION]... [FILE]...
  or:  wc [OPTION]... --files0-from=F
Print newline, word, and byte counts for each FILE, and a total line if
more than one FILE is specified.  A word is a non-zero-length sequence of
...
  -l, --lines            print the newline counts
```

Comment lire la ligne `Usage` :

| Notation | Signification |
|---|---|
| `[OPTION]` | entre crochets : facultatif |
| `...` | peut être répété (plusieurs options, plusieurs fichiers) |
| `-l, --lines` | forme courte et forme longue de la même option |

Ici, `wc` (*word count*) compte les lignes, les mots et les octets d'un
fichier, et l'option `-l` limite l'affichage au nombre de lignes.

### 7.2 `man` : le manuel complet

```bash
man head
```

Le manuel s'ouvre en plein écran. Il est découpé en rubriques standard :
`NAME` (à quoi sert la commande), `SYNOPSIS` (la syntaxe), `DESCRIPTION`
(toutes les options) et `SEE ALSO` (commandes apparentées).

| Touche | Effet |
|---|---|
| Espace / **b** | page suivante / précédente |
| **/**mot puis Entrée | rechercher « mot » ; **n** pour l'occurrence suivante |
| **q** | quitter |

Pour un rappel en une ligne, utilisez `whatis` :

```bash
whatis wc
```

Sortie :

```text
wc (1)               - print newline, word, and byte counts for each file
```

### 7.3 Quand `man` ne trouve rien : les commandes internes

Certaines commandes ne sont pas des programmes séparés : elles sont
**intégrées au shell** (*builtins*). La commande `type` permet de savoir à
quelle catégorie appartient une commande :

```bash
type echo
type head
```

Sortie :

```text
echo is a shell builtin
head is /usr/bin/head
```

`head` est un programme, rangé dans le fichier `/usr/bin/head`. `echo` est
intégré au shell. Pour l'aide d'une commande intégrée, utilisez `help` (par
exemple `help cd`), car `man` ne la documente pas toujours.

> **Pour aller plus loin** : les outils de bioinformatique suivent les
> mêmes conventions. `samtools --help`, `seqkit --help` et
> `fastqc --help` affichent leur propre aide.

---

## 8. Lire un message d'erreur

Une erreur n'est pas un échec : c'est **le programme qui vous explique ce
qui ne va pas**. Encore faut-il savoir lire son message. Voici une méthode
en trois questions :

1. **Qui parle ?** Le nom avant le premier deux-points désigne le
   programme qui signale l'erreur.
2. **De quoi parle-t-il ?** L'élément entre guillemets est souvent le
   fichier ou la valeur en cause.
3. **Quel est le problème ?** La fin du message le décrit.

### Démonstration sur quatre erreurs réelles

**Erreur 1 : faute de frappe dans un nom de fichier**

```bash
wc -l transcript.fasta
```

```text
wc: transcript.fasta: No such file or directory
```

Qui ? `wc`. De quoi ? `transcript.fasta`. Problème : « aucun fichier ou
dossier de ce nom ». Le vrai fichier s'appelle `transcripts.fasta`, avec
un **s**. La touche Tab aurait évité l'erreur.

**Erreur 2 : faute de frappe dans le nom de la commande**

```bash
Head genome.fasta
```

```text
Command 'Head' not found, did you mean:
  command 'head' from deb coreutils (9.4-3ubuntu6.2)
Try: sudo apt install <deb name>
```

La commande `Head` n'existe pas, avec une majuscule. Ubuntu propose même la
bonne orthographe : `head`. **N'exécutez pas** la suggestion `sudo apt
install` : vous n'avez rien à installer, seulement une faute à corriger.

**Erreur 3 : une option reçoit une valeur incorrecte**

```bash
head -n deux genome.fasta
```

```text
head: invalid number of lines: ‘deux’
```

L'option `-n` attend un **nombre** de lignes écrit en chiffres : `-n 2`.

**Erreur 4 : une option qui n'existe pas**

```bash
ls -y
```

```text
ls: invalid option -- 'y'
Try 'ls --help' for more information.
```

L'option `-y` n'existe pas pour `ls`. Le message vous indique lui-même où
chercher la bonne : `ls --help`.

### Les messages que vous rencontrerez le plus souvent

| Message (en anglais) | Traduction | Cause habituelle | Première chose à vérifier |
|---|---|---|---|
| `No such file or directory` | fichier ou dossier introuvable | faute de frappe, ou mauvais dossier | Tab ; où suis-je ? (chapitre 02) |
| `command not found` | commande introuvable | faute de frappe, ou logiciel non installé | l'orthographe ; `type nom` |
| `invalid option` | option invalide | option inexistante pour cette commande | `commande --help` |
| `Is a directory` | c'est un dossier | vous avez donné un dossier là où un fichier est attendu | le nom fourni |
| `Permission denied` | permission refusée | droits insuffisants | chapitre 08 |
| `missing operand` | argument manquant | vous avez oublié le fichier ou la valeur | relire la ligne `Usage` |

> **Bon réflexe** : avant de chercher une erreur sur Internet,
> **relisez-la lentement en vous posant les trois questions**. La réponse
> se trouve dans le message dans la grande majorité des cas. Si vous
> cherchez quand même, copiez la partie générique du message
> (`invalid number of lines`), sans vos noms de fichiers.

---

## 9. Et en bioinformatique ?

Les outils que vous utiliserez plus tard suivent exactement la même
grammaire. Voici une vraie commande d'alignement, que vous n'avez pas à
exécuter :

```text
samtools  view  -b  -o alignements.bam  alignements.sam
```

Vous savez déjà la décomposer :

| Élément | Rôle |
|---|---|
| `samtools` | la commande (un programme) |
| `view` | une **sous-commande** : samtools regroupe plusieurs outils, comme `git` |
| `-b` | option : produire un fichier au format binaire BAM |
| `-o alignements.bam` | option avec valeur : le fichier de sortie |
| `alignements.sam` | argument : le fichier d'entrée |

Lire une commande inconnue de cette façon, élément par élément, puis
vérifier chaque option dans `--help`, est **la** compétence qui vous rendra
autonome face à n'importe quel outil.

---

## 10. À vous de jouer

Tous les exercices se font dans le bac à sable. Commencez par :

```bash
cd ~/formation_linux
```

### Exercice 1 : lire l'invite

*Objectif : interpréter l'invite.*
Que vous apprend l'invite `paul@cluster-bioinfo:~/projet_arn$` ?

<details>
<summary>Corrigé</summary>

L'utilisateur s'appelle `paul`. Il est connecté à une machine nommée
`cluster-bioinfo` (probablement un serveur de calcul), et il se trouve dans
le dossier `projet_arn`, situé dans son dossier personnel (`~`). Le `$`
indique un utilisateur ordinaire, prêt à recevoir une commande.
</details>

### Exercice 2 : décomposer et exécuter

*Objectif : distinguer commande, options et arguments.*
Affichez les 5 premières lignes de `transcripts.fasta`, puis la première
ligne de `proteins.fasta` et de `genome.fasta` **en une seule commande**.
Pour chaque commande, nommez la commande, les options et les arguments.

<details>
<summary>Corrigé</summary>

```bash
head -n 5 transcripts.fasta
head -n 1 proteins.fasta genome.fasta
```

Commande : `head`. Option : `-n` avec sa valeur (`5`, puis `1`).
Arguments : un fichier dans le premier cas, deux dans le second.
</details>

### Exercice 3 : trouver une option seul

*Objectif : utiliser `--help`.*
Le fichier `reads.fastq` contient des reads de séquençage. Grâce à
`wc --help`, trouvez comment afficher **uniquement son nombre de lignes**,
puis exécutez la commande.

<details>
<summary>Corrigé</summary>

```bash
wc -l reads.fastq
```

Sortie :

```text
2000 reads.fastq
```

Sans option, `wc reads.fastq` affiche trois nombres (lignes, mots,
octets) : `2000   2500 122651 reads.fastq`. L'option `-l` (ou `--lines`)
ne garde que les lignes. Au chapitre 04, vous verrez qu'un read FASTQ
occupe exactement 4 lignes, ce qui fait 500 reads ici.
</details>

### Exercice 4 : le détective des erreurs

*Objectif : diagnostiquer avec les trois questions.*
Exécutez chaque commande, lisez le message, puis corrigez la commande.

```bash
head -n 3 genom.fasta
wc -l proteins.FASTA
HEAD -n 2 reads.fastq
head run_sequencage
```

<details>
<summary>Corrigé</summary>

| Commande | Message | Correction |
|---|---|---|
| `head -n 3 genom.fasta` | `No such file or directory` : il manque un « e » | `head -n 3 genome.fasta` |
| `wc -l proteins.FASTA` | `No such file or directory` : la casse ne correspond pas | `wc -l proteins.fasta` |
| `HEAD -n 2 reads.fastq` | `command not found` : majuscules | `head -n 2 reads.fastq` |
| `head run_sequencage` | `error reading 'run_sequencage': Is a directory` | `run_sequencage` est un **dossier**, pas un fichier. Le chapitre 02 vous apprendra à regarder à l'intérieur |

Dans les trois premiers cas, la touche Tab aurait évité l'erreur.
</details>

### Exercice 5 : un nom de fichier avec des espaces

*Objectif : comprendre comment le shell découpe une commande.*
Le dossier `pieges` contient un fichier nommé `mes resultats finaux.txt`.
Exécutez les deux commandes suivantes et expliquez la différence :

```bash
head "pieges/mes resultats finaux.txt"
head pieges/mes resultats finaux.txt
```

<details>
<summary>Corrigé</summary>

La première commande affiche le contenu du fichier. La seconde produit
trois erreurs :

```text
head: cannot open 'pieges/mes' for reading: No such file or directory
head: cannot open 'resultats' for reading: No such file or directory
head: cannot open 'finaux.txt' for reading: No such file or directory
```

Sans guillemets, le shell a découpé le nom à chaque espace : `head` a reçu
**trois** arguments, et a cherché trois fichiers qui n'existent pas. C'est
la règle 2 de la section 5.5. Leçon pratique : **dans vos projets, nommez
vos fichiers sans espaces** (`mes_resultats_finaux.txt`).
</details>

### Exercice 6 : programme ou commande interne ?

*Objectif : utiliser `type`.*
Parmi `wc`, `cd`, `sleep` et `type`, lesquelles sont des commandes
internes du shell ?

<details>
<summary>Corrigé</summary>

```bash
type wc cd sleep type
```

`cd` et `type` sont des commandes internes (`shell builtin`). `wc` et
`sleep` sont des programmes rangés dans `/usr/bin/`. Pour obtenir l'aide de
`cd`, il faut donc taper `help cd` plutôt que `man cd`.
</details>

---

## 11. Défi

Un collègue affirme : « avec `head`, on ne peut compter qu'en lignes ».
Montrez-lui le contraire **en utilisant uniquement `man head` ou
`head --help`** : affichez les **100 premiers caractères** de
`genome.fasta`.

Observez ensuite le résultat : pourquoi la dernière ligne affichée
semble-t-elle coupée, et pourquoi l'invite apparaît-elle collée au texte ?

<details>
<summary>Indice</summary>

Cherchez dans l'aide une option dont la description mentionne *bytes*
(octets). Sur un fichier ne contenant que des lettres non accentuées, un
caractère occupe un octet.
</details>

<details>
<summary>Corrigé</summary>

```bash
head -c 100 genome.fasta
```

Sortie (l'invite apparaît juste après le dernier caractère affiché) :

```text
>seq_exercice_01 organism=synthetic type=demo length=51
ATGCGTACGTTAGCTAGCTAGCTAGGCTAACGTTACGTAGCTAGmarie@PC-LABO:~/formation_linux$
```

L'option `-c` (`--bytes`) compte en **octets**, pas en lignes. `head`
s'arrête au 100ᵉ octet, même au milieu d'une ligne de séquence. Il ne
reste donc pas de retour à la ligne final, et l'invite s'affiche collée au
texte. Cette option sert, par exemple, à jeter un œil au tout début d'un
fichier énorme ou inconnu sans risquer d'afficher une ligne de plusieurs
millions de caractères.
</details>

---

## L'essentiel

```text
commande [options] [arguments]     la grammaire de toutes les commandes
-n 3   --lines=3                    option courte / option longue
Tab, Tab Tab                        compléter / lister les possibilités
↑  Ctrl+R                           rappeler / rechercher une commande
Ctrl+C                              interrompre (programme bloqué, invite >)
q                                   quitter man ou less
commande --help    man commande     obtenir de l'aide
type commande      help commande    programme ou commande interne ?
Erreur : qui parle ? de quoi ? quel problème ?
```

### Auto-évaluation

- [ ] Je sais expliquer la différence entre le terminal, le shell et le noyau.
- [ ] Je décompose une commande inconnue en commande, options et arguments.
- [ ] J'utilise Tab systématiquement pour les noms de fichiers.
- [ ] Je sais sortir d'un programme qui ne rend pas la main.
- [ ] Je trouve une option dans `--help` ou `man` sans aide extérieure.
- [ ] Face à un message d'erreur, je sais identifier qui parle, de quoi, et quel est le problème.

Si une case reste vide, relisez la section correspondante et refaites
l'exercice associé : chaque chapitre suivant s'appuie sur celui-ci.

## Documentation officielle

- Manuel de Bash (GNU) : <https://www.gnu.org/software/bash/manual/bash.html>
- Manuel des GNU Coreutils (`head`, `wc`, `echo`…) : <https://www.gnu.org/software/coreutils/manual/coreutils.html>
- Pages de manuel Linux en ligne : <https://man7.org/linux/man-pages/>

**Prochaine étape** : chapitre 02 — Le système de fichiers *(en cours de rédaction)*.
