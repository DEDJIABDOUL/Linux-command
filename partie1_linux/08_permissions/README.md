# Chapitre 08 — Utilisateurs et permissions : protéger vos données

> **Durée estimée** : 1 h 30
> **Prérequis** : [chapitre 07](../07_awk_sed/README.md) (et le [projet 1](../projet1_inventaire_run/README.md))
> **Chapitre suivant** : [09 — Processus et ressources](../09_processus/README.md)

## Ce que vous saurez faire à la fin de ce chapitre

- Savoir qui vous êtes pour le système, et à quels groupes vous appartenez
  (`whoami`, `id`).
- Lire une chaîne de permissions (`-rwxr-xr--`) et sa forme numérique
  (`754`).
- Modifier les permissions avec `chmod`, en notation symbolique et en
  notation numérique.
- **Protéger vos données brutes contre l'effacement accidentel.**
- Rendre un script exécutable, et diagnostiquer un `Permission denied`.
- Comprendre ce qu'est `sudo`, et pourquoi vous n'en aurez pas sur un
  serveur.

---

## 1. Pourquoi

Un serveur de calcul est partagé par des dizaines, parfois des centaines
d'utilisateurs. Linux doit garantir que personne ne lit les données
confidentielles d'un autre, que personne ne détruit celles d'un autre par
erreur, et que personne ne casse le système. Le mécanisme qui assure tout
cela s'appelle les **permissions**.

Il vous sert aussi directement :

- au chapitre 03, vous avez appris qu'un `rm` est définitif. Les
  permissions permettent de rendre vos FASTQ bruts **impossibles à
  supprimer**, même par vous, même par erreur ;
- le message `Permission denied` est l'un des plus fréquents. Le comprendre,
  c'est le résoudre en quelques secondes.

---

## 2. Une image pour comprendre : les badges d'un institut

Dans un institut de recherche, chaque porte a un lecteur de badge, et les
droits dépendent de **qui** vous êtes :

| À l'institut | Sous Linux |
|---|---|
| votre badge personnel | votre **utilisateur** (`marie`) |
| votre équipe (tous les membres du labo de génomique) | un **groupe** (`genomique`) |
| les visiteurs | **les autres** utilisateurs |
| le directeur technique, qui a un passe-partout | **root**, l'administrateur |

Pour chaque fichier, trois catégories de personnes, et trois droits
possibles pour chacune : **lire**, **modifier**, **exécuter**.

> **Limite de l'image** : root n'a pas un simple passe-partout, il peut
> **tout** faire, y compris détruire le système. C'est pour cela qu'on ne
> travaille jamais en root au quotidien.

---

## 3. Qui suis-je ?

```bash
cd ~/formation_linux
whoami
id
```

```text
marie
uid=1000(marie) gid=1000(marie) groups=1000(marie),4(adm),24(cdrom),27(sudo),30(dip),46(plugdev),100(users)
```

- `uid=1000(marie)` : votre identifiant numérique d'utilisateur. Linux
  travaille avec ce numéro ; le nom n'est qu'une étiquette pratique.
- `gid=1000(marie)` : votre groupe principal. Sur Ubuntu, chaque
  utilisateur a un groupe personnel du même nom.
- `groups=…` : tous vos groupes. Le groupe `sudo` vous donne le droit
  d'administrer **votre** machine (section 8).

Sur un serveur, `id` affichera plutôt des groupes d'équipe ou de projet,
comme `genomique` ou `projet_arn`.

---

## 4. Lire les permissions

### 4.1 La chaîne de 10 caractères

```bash
ls -l genome.fasta
ls -ld formats
```

```text
-rw-r--r-- 1 marie marie 25447 Nov 24 23:47 genome.fasta
drwxr-xr-x 2 marie marie  4096 Nov 24 23:47 formats
```

```text
 -   rw-   r--   r--     marie   marie
 │   └┬┘   └┬┘   └┬┘     │       └ groupe propriétaire
 │    │     │     │      └ utilisateur propriétaire
 │    │     │     └ les autres (o, others)
 │    │     └ le groupe (g, group)
 │    └ le propriétaire (u, user)
 └ type : - fichier, d dossier, l lien
```

Chaque bloc de trois caractères se lit toujours dans le même ordre :

| Lettre | Droit | Sur un fichier | Sur un dossier |
|---|---|---|---|
| `r` | *read* | lire le contenu | **lister** les noms qu'il contient |
| `w` | *write* | modifier le contenu | **créer, renommer, supprimer** des fichiers dedans |
| `x` | *execute* | l'exécuter comme un programme | **y entrer** et accéder à son contenu |
| `-` | | droit absent | droit absent |

`genome.fasta` (`rw-r--r--`) : vous pouvez le lire et le modifier ; votre
groupe et les autres peuvent seulement le lire.

### 4.2 La notation numérique

Chaque droit vaut un nombre, et on additionne ces nombres pour chaque
bloc :

| r | w | x |
|---|---|---|
| 4 | 2 | 1 |

| Chaîne | Calcul | Nombre | Usage typique |
|---|---|---|---|
| `rw-r--r--` | 4+2, 4, 4 | **644** | fichier de données ordinaire |
| `rwxr-xr-x` | 4+2+1, 4+1, 4+1 | **755** | script, dossier |
| `rw-------` | 4+2, 0, 0 | **600** | fichier personnel confidentiel (clé SSH, chapitre 14) |
| `r--r--r--` | 4, 4, 4 | **444** | données en lecture seule |
| `rwxr-x---` | 7, 5, 0 | **750** | dossier d'équipe fermé aux autres |

`stat` affiche les deux formes :

```bash
stat -c "%A %a %n" genome.fasta formats
```

```text
-rw-r--r-- 644 genome.fasta
drwxr-xr-x 755 formats
```

### 4.3 D'où viennent les permissions par défaut ? `umask`

```bash
umask
touch nouveau.txt
mkdir nouveau_dossier
ls -ld nouveau.txt nouveau_dossier
```

```text
0022
-rw-r--r-- 1 marie marie    0 Nov 24 23:47 nouveau.txt
drwxr-xr-x 2 marie marie 4096 Nov 24 23:47 nouveau_dossier
```

Le **masque** `022` retire le droit d'écriture (2) au groupe et aux autres.
Un nouveau fichier naît donc en `644`, un nouveau dossier en `755`. Les
fichiers ne naissent jamais exécutables : il faut le demander
explicitement (section 6).

---

## 5. Modifier les permissions : `chmod`

### 5.1 La notation symbolique : qui, + ou −, quoi

```text
chmod  [u g o a]  [+ - =]  [r w x]  fichier
        qui        action    droits
```

`u` propriétaire, `g` groupe, `o` autres, `a` tous ; `+` ajouter, `-`
retirer, `=` fixer exactement.

| Commande | Effet |
|---|---|
| `chmod u+x script.sh` | le propriétaire peut l'exécuter |
| `chmod go-r fichier` | le groupe et les autres ne peuvent plus le lire |
| `chmod a-w fichier` | personne ne peut plus le modifier |
| `chmod u=rw,g=r,o= fichier` | fixe exactement `rw-r-----` |
| `chmod -R …  dossier` | applique à tout le contenu, récursivement |

### 5.2 La notation numérique

```bash
chmod 600 nouveau.txt
ls -l nouveau.txt
```

```text
-rw------- 1 marie marie 0 Nov 24 23:47 nouveau.txt
```

La forme symbolique **modifie** ce qui existe (`+x` ne touche pas aux
autres droits). La forme numérique **remplace** tout d'un coup. Les deux
sont courantes, et vous croiserez souvent `chmod 755` et `chmod 644` dans
les documentations.

---

## 6. Rendre un script exécutable

Créez un petit script (vous écrirez de vrais scripts au chapitre 12) :

```bash
printf '#!/bin/bash\necho Bonjour depuis un script\n' > bonjour.sh
ls -l bonjour.sh
./bonjour.sh
```

```text
-rw-r--r-- 1 marie marie 42 Nov 24 23:47 bonjour.sh
bash: ./bonjour.sh: Permission denied
```

Le fichier n'a pas le droit `x`. Deux solutions :

```bash
bash bonjour.sh
chmod u+x bonjour.sh
./bonjour.sh
```

```text
Bonjour depuis un script
Bonjour depuis un script
```

- `bash bonjour.sh` demande à bash de **lire** le fichier : le droit `r`
  suffit.
- `chmod u+x` rend le fichier exécutable : `./bonjour.sh` fonctionne. Le
  `./` signifie « le fichier `bonjour.sh` **du dossier courant** »
  (chapitre 10 : pourquoi il est nécessaire).

---

## 7. Protéger les données brutes

### 7.1 Le geste

La règle d'or d'un projet (chapitre 17) : **on ne modifie jamais les
données brutes**. Les permissions la rendent automatique :

```bash
mkdir -p projet/data/raw
cp run_sequencage/fastq/P01*.gz projet/data/raw/
chmod -R a-w projet/data/raw
ls -l projet/data/raw
ls -ld projet/data/raw
```

```text
total 56
-r--r--r-- 1 marie marie 27710 Nov 24 23:47 P01_S1_L001_R1_001.fastq.gz
-r--r--r-- 1 marie marie 27680 Nov 24 23:47 P01_S1_L001_R2_001.fastq.gz
dr-xr-xr-x 2 marie marie  4096 Nov 24 23:47 projet/data/raw
```

### 7.2 Le test : essayez de faire une bêtise

```bash
rm projet/data/raw/P01_S1_L001_R1_001.fastq.gz
echo test > projet/data/raw/nouveau.txt
gzip -d projet/data/raw/P01_S1_L001_R2_001.fastq.gz
```

```text
rm: cannot remove 'projet/data/raw/P01_S1_L001_R1_001.fastq.gz': Permission denied
bash: projet/data/raw/nouveau.txt: Permission denied
gzip: projet/data/raw/P01_S1_L001_R2_001.fastq: Permission denied
```

Les trois accidents classiques sont bloqués : supprimer, écrire dans le
dossier, et décompresser sur place (`gzip -d` aurait remplacé le `.gz` par
sa version décompressée). La **lecture**, elle, fonctionne toujours, et
c'est tout ce dont une analyse a besoin :

```bash
zcat projet/data/raw/P01_S1_L001_R1_001.fastq.gz | head -n 1
```

```text
@M07112:58:000000000-KX4LT:1:1101:1037:1511 1:N:0:1
```

> **Pourquoi `rm` échoue-t-il ?** Supprimer un fichier, c'est le **retirer
> du dossier** : c'est donc le droit `w` du **dossier** qui compte, pas
> celui du fichier. Si seul le fichier était protégé, `rm` vous
> demanderait `remove write-protected regular file?`, et un « oui »
> distrait suffirait à le perdre. Protégez toujours **le dossier et son
> contenu** (`-R`).

Pour lever la protection, volontairement :

```bash
chmod -R u+w projet/data/raw
```

### 7.3 Les droits d'un dossier, en détail

`r` et `x` sur un dossier ne jouent pas le même rôle :

```bash
mkdir secret
touch secret/a.txt
chmod a-x secret
cd secret
ls secret
cat secret/a.txt
```

```text
bash: cd: secret: Permission denied
a.txt
cat: secret/a.txt: Permission denied
```

Sans `x`, on peut **lire la liste des noms** (`r`), mais on ne peut ni
entrer dans le dossier ni ouvrir ce qu'il contient. À l'inverse, avec `x`
mais sans `r`, `ls secret` échoue, mais `cat secret/a.txt` fonctionne si
l'on connaît déjà le nom du fichier. En pratique, on donne `r` et `x`
ensemble (`755` ou `750`). Rétablissez le dossier : `chmod 755 secret`.

---

## 8. root, `sudo`, et ce que vous ne pouvez pas faire

### 8.1 Les limites d'un utilisateur ordinaire

```bash
ls -l /etc/shadow
head -n 1 /etc/shadow
ls /root
chown root nouveau.txt
```

```text
-rw-r----- 1 root shadow 798 Nov 24 13:12 /etc/shadow
head: cannot open '/etc/shadow' for reading: Permission denied
ls: cannot open directory '/root': Permission denied
chown: changing ownership of 'nouveau.txt': Operation not permitted
```

`/etc/shadow` contient les mots de passe chiffrés : seul root peut le lire.
`/root` est le dossier personnel de root. Et vous ne pouvez pas donner un
fichier à quelqu'un d'autre (`chown`) : seul root le peut. Ce sont ces
limites qui protègent un système partagé.

### 8.2 `sudo` : emprunter les pouvoirs de root

`sudo commande` exécute **une** commande en tant que root, après avoir
demandé **votre** mot de passe. C'est ce que vous avez fait au chapitre 00
avec `sudo apt install git`. Pour pouvoir le faire, il faut appartenir au
groupe `sudo` : c'est le cas sur votre propre machine.

> **Attention** :
> - **Sur votre machine**, réservez `sudo` aux installations de logiciels
>   système (chapitre 11). Ne l'utilisez jamais « pour que ça marche »
>   face à un `Permission denied` dans vos propres dossiers : vous créeriez
>   des fichiers appartenant à root, que vous ne pourriez plus modifier
>   ensuite.
> - **Sur un serveur partagé**, vous n'aurez **pas** `sudo`. Tenter de
>   l'utiliser affiche `marie is not in the sudoers file` et l'incident
>   est signalé aux administrateurs. On installe alors ses logiciels **sans
>   droits administrateur**, avec Conda (chapitre 11) ou les modules du
>   cluster.

L'administration d'une machine (créer des comptes, gérer le pare-feu, les
services) est présentée dans l'[annexe A](../annexes/A_administration_systeme.md),
à pratiquer uniquement sur une machine virtuelle.

---

## 9. En bioinformatique

- **Données brutes** : `chmod -R a-w data/raw/` dès leur arrivée et leur
  vérification (projet 1). C'est l'un des gestes les plus rentables de
  toute une carrière.
- **Dossiers d'équipe sur un serveur** : un dossier partagé typique est en
  `rwxr-x---` (750) et appartient au groupe du projet. Les membres de
  l'équipe peuvent lire, les autres utilisateurs ne voient rien.
  `chgrp equipe dossier` change le groupe d'un fichier qui vous appartient,
  si vous êtes membre de ce groupe.
- **Données sensibles** (données patients) : fermées à « les autres », et
  souvent soumises à des règles institutionnelles que les permissions
  servent à appliquer.
- **Scripts** : `chmod u+x` pour les lancer avec `./script.sh`.
- **Sous WSL**, les fichiers de `/mnt/c` apparaissent tous avec des
  permissions fantaisistes (souvent `rwx` partout) : Windows ne gère pas
  les permissions Linux. C'est une raison de plus de travailler dans votre
  dossier personnel Ubuntu (chapitre 00).

---

## 10. Pièges fréquents

| Message | Cause probable | Diagnostic | Solution |
|---|---|---|---|
| `./script.sh: Permission denied` | pas de droit `x` | `ls -l script.sh` | `chmod u+x script.sh`, ou `bash script.sh` |
| `cannot remove …: Permission denied` | dossier sans `w` | `ls -ld dossier` | c'est voulu ? sinon `chmod u+w dossier` |
| `cd: …: Permission denied` | dossier sans `x` pour vous | `ls -ld dossier` | demander l'accès au propriétaire |
| `cannot open …: Permission denied` sur le fichier d'un collègue | pas de droit `r` pour vous | `ls -l`, puis `id` | demander au propriétaire `chmod g+r` |
| `Operation not permitted` | action réservée à root (`chown`…) | — | ce n'est pas à vous de le faire |
| fichiers impossibles à modifier après un `sudo` | ils appartiennent à root | `ls -l` montre `root root` | éviter `sudo` dans vos dossiers ; sur votre machine, `sudo chown -R $USER dossier` |

---

## 11. À vous de jouer

Commencez par `cd ~/formation_linux`.

### Exercice 1 : décoder

*Objectif : lire les permissions.*
Pour chaque chaîne, dites qui peut faire quoi, et donnez la forme
numérique : `-rwxr-x---`, `-r--r--r--`, `drwx------`, `-rw-rw-r--`.

<details>
<summary>Corrigé</summary>

| Chaîne | Signification | Nombre |
|---|---|---|
| `-rwxr-x---` | fichier : le propriétaire lit, modifie, exécute ; le groupe lit et exécute ; les autres n'ont rien | 750 |
| `-r--r--r--` | fichier en lecture seule pour tous | 444 |
| `drwx------` | dossier privé : seul le propriétaire peut y entrer | 700 |
| `-rw-rw-r--` | fichier modifiable par le propriétaire et le groupe, lisible par tous | 664 |
</details>

### Exercice 2 : de la consigne à la commande

*Objectif : écrire `chmod` dans les deux notations.*
Donnez la commande, en notation symbolique **et** numérique, pour :
(a) un script que vous seul pouvez lire, modifier et exécuter ; (b) un
tableau de résultats lisible par tous et modifiable par vous seul ; (c) un
dossier d'équipe où le groupe peut entrer et lire, mais pas les autres.

<details>
<summary>Corrigé</summary>

(a) `chmod u=rwx,go= script.sh` ou `chmod 700 script.sh`.
(b) `chmod u=rw,go=r resultats.tsv` ou `chmod 644 resultats.tsv`.
(c) `chmod u=rwx,g=rx,o= dossier` ou `chmod 750 dossier`.
</details>

### Exercice 3 : protéger le run de séquençage

*Objectif : protéger des données et vérifier la protection.*
Copiez le dossier `run_sequencage/fastq` dans `brut_protege/`, protégez-le
contre toute modification, puis vérifiez que (1) vous pouvez toujours lire
un fichier compressé, (2) vous ne pouvez ni supprimer un fichier ni en
créer un nouveau.

<details>
<summary>Corrigé</summary>

```bash
cp -r run_sequencage/fastq brut_protege
chmod -R a-w brut_protege
zcat brut_protege/P07_S7_L001_R1_001.fastq.gz | head -n 1
rm brut_protege/P07_S7_L001_R1_001.fastq.gz
touch brut_protege/test.txt
```

La lecture fonctionne ; `rm` et `touch` échouent avec `Permission denied`.
Pour pouvoir supprimer ce dossier d'exercice plus tard :
`chmod -R u+w brut_protege`.
</details>

### Exercice 4 : diagnostiquer

*Objectif : relier un message d'erreur à une permission.*
Exécutez ces commandes, expliquez chaque erreur, puis corrigez-la **sans
`sudo`** :

```bash
printf '#!/bin/bash\necho ok\n' > test.sh
./test.sh
mkdir boite
chmod 000 boite
ls boite
```

<details>
<summary>Corrigé</summary>

- `./test.sh: Permission denied` : un fichier naît sans droit `x`
  (`umask`). Correction : `chmod u+x test.sh`.
- `ls: cannot open directory 'boite': Permission denied` : `000` retire
  tout, y compris à vous. Correction : `chmod 755 boite`. En tant que
  propriétaire, vous pouvez toujours modifier les permissions de vos
  propres fichiers.
</details>

---

## 12. Défi : préparer un dossier de projet partagé

Votre équipe va travailler à plusieurs sur un serveur. Préparez dans le bac
à sable un dossier `projet_equipe/` qui respecte ces règles :

- `data/raw/` : lisible par vous et votre groupe, **non modifiable par
  personne** ;
- `scripts/` : vous pouvez tout faire, le groupe peut lire et exécuter ;
- `resultats/` : vous et le groupe pouvez y créer des fichiers ;
- les autres utilisateurs n'ont accès à **rien**.

Vérifiez avec `ls -lR projet_equipe`.

<details>
<summary>Corrigé</summary>

```bash
mkdir -p projet_equipe/{data/raw,scripts,resultats}
cp run_sequencage/fastq/P07*.gz projet_equipe/data/raw/
chmod 750 projet_equipe projet_equipe/data projet_equipe/scripts
chmod 770 projet_equipe/resultats
chmod -R u=rX,g=rX,o= projet_equipe/data/raw
ls -lR projet_equipe
```

`X` (majuscule) donne le droit d'exécution **uniquement aux dossiers**
(et aux fichiers déjà exécutables), et non aux fichiers de données. C'est
pratique avec `-R`. Les dossiers parents sont en `750` : sans `x` pour
« les autres », personne d'extérieur ne peut même atteindre `resultats/`.

Sur un vrai serveur, il faudrait en plus donner le dossier au groupe
d'équipe (`chgrp -R equipe projet_equipe`).
</details>

---

## L'essentiel

```text
whoami   id   groups                 qui suis-je, quels groupes
-rwxr-xr--  type | u (propriétaire) | g (groupe) | o (autres)
r = 4 lire / lister   w = 2 modifier / créer-supprimer dedans   x = 1 exécuter / entrer
644 données   755 scripts et dossiers   600 privé   444 lecture seule   750 équipe
chmod u+x f   chmod go-w f   chmod a-w f   chmod 644 f   chmod -R …
umask 022 → fichiers 644, dossiers 755 ; un fichier ne naît jamais exécutable
Supprimer un fichier = droit w sur le DOSSIER
chmod -R a-w data/raw              protéger les données brutes
sudo : pour administrer SA machine, jamais pour « débloquer » ses fichiers
```

### Auto-évaluation

- [ ] Je lis une chaîne de permissions et sa forme numérique.
- [ ] J'écris `chmod` en notation symbolique et numérique.
- [ ] Je sais qu'on peut toujours lire un fichier protégé en écriture.
- [ ] J'ai protégé un dossier de données brutes et vérifié qu'on ne peut plus rien y supprimer.
- [ ] Je diagnostique un `Permission denied` en regardant `ls -l` et `ls -ld`.
- [ ] Je sais pourquoi je n'aurai pas `sudo` sur un serveur.

## Documentation officielle

- `chmod` (GNU Coreutils) : <https://www.gnu.org/software/coreutils/manual/html_node/chmod-invocation.html>
- Modes de fichiers (GNU Coreutils, *File permissions*) : <https://www.gnu.org/software/coreutils/manual/html_node/File-permissions.html>
- `sudo` : <https://www.sudo.ws/docs/man/sudo.man/>

**Prochaine étape** : [chapitre 09 — Processus et ressources](../09_processus/README.md).
