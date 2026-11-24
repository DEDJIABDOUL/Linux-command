# Chapitre 05 — Flux, redirections et pipes : enchaîner les commandes

> **Durée estimée** : 2 h
> **Prérequis** : [chapitre 04](../04_lire_inspecter/README.md)
> **Chapitre suivant** : [06 — Chercher et filtrer](../06_chercher_filtrer/README.md)

## Ce que vous saurez faire à la fin de ce chapitre

- Brancher la sortie d'une commande sur l'entrée d'une autre avec le
  **pipe** `|`.
- Enregistrer un résultat dans un fichier (`>`, `>>`) sans écraser par
  erreur un fichier précieux.
- Séparer les résultats des messages d'erreur (`2>`, `2>&1`, `/dev/null`).
- Savoir si une commande a réussi (code de retour, `&&`, `||`).
- Insérer le résultat d'une commande dans une autre et faire des calculs
  (`$( )`, `$(( ))`) : par exemple, compter les reads d'un FASTQ compressé.

---

## 1. Pourquoi

Au chapitre 04, une question simple restait sans réponse : **combien de
reads contient un FASTQ compressé ?** `wc -l` sur le `.gz` donnait un nombre
absurde, et `zcat` affichait tout le fichier. Il manquait un moyen de
**donner la sortie de `zcat` à `wc`**.

C'est l'idée centrale d'Unix : chaque commande fait **une seule chose,
bien**, et on les **assemble** comme des briques. `zcat` décompresse, `wc`
compte, `head` coupe. Ensemble, elles répondent à des questions qu'aucune
ne sait traiter seule. La majorité des analyses rapides en bioinformatique
s'écrivent ainsi, en une ligne.

---

## 2. Une image pour comprendre : les trois tuyaux d'un instrument

Imaginez un appareil de laboratoire avec **trois raccords** :

- une **entrée**, par où arrive l'échantillon ;
- une **sortie des résultats** ;
- un **voyant d'alarme**, séparé, qui s'allume en cas de problème.

Chaque commande Linux possède exactement ces trois « tuyaux », qu'on
appelle des **flux** :

| Flux | Nom technique | Numéro | Par défaut, branché sur… |
|---|---|---|---|
| l'entrée | *standard input* (**stdin**) | 0 | le clavier |
| les résultats | *standard output* (**stdout**) | 1 | l'écran |
| les messages d'erreur | *standard error* (**stderr**) | 2 | l'écran aussi |

Les résultats et les erreurs arrivent tous deux à l'écran, si bien qu'on ne
les distingue pas. Mais ce sont **deux tuyaux différents**, et on peut les
rebrancher séparément :

- le **pipe** `|` raccorde la sortie d'une commande à l'entrée de la
  suivante, comme deux appareils reliés en série ;
- les **redirections** `>` et `2>` envoient la sortie ou les erreurs dans
  un fichier au lieu de l'écran.

---

## 3. Le pipe `|`

### 3.1 Premiers branchements

Combien de fichiers y a-t-il dans le dossier du run ? Au chapitre 02, vous
les comptiez à l'œil. Désormais :

```bash
cd ~/formation_linux
ls run_sequencage/fastq | wc -l
```

```text
25
```

`ls` produit la liste des fichiers, mais au lieu de l'afficher, il
l'envoie dans le pipe. `wc -l` lit cette liste sur son entrée et compte
les lignes. Avec un joker, on ne compte que les FASTQ :

```bash
ls run_sequencage/fastq/*.fastq.gz | wc -l
```

```text
24
```

> **Comment `wc` sait-il quoi lire ?** Quand une commande comme `wc`,
> `head` ou `less` ne reçoit **pas de nom de fichier**, elle lit son entrée
> standard. Au chapitre 01, `head` seul « attendait » le clavier ; ici, il
> lit ce qui arrive par le pipe.

### 3.2 Inspecter un fichier compressé

Le début d'un FASTQ compressé, sans rien décompresser sur le disque :

```bash
zcat run_sequencage/fastq/P07_S7_L001_R1_001.fastq.gz | head -n 4
```

```text
@M07112:58:000000000-KX4LT:1:1101:1037:1511 1:N:0:7
GTAGTCCCTGCCGACCTTGTTACTCTTCAACACTAGCCCGGGGACTACGCCCATGGGAAGTCGTTATCTTGCTACTGTTGCTCGTAGGCATTTAATAAGT
+
EGHCDEFBBGABDBFABD@ECA@FCACACCA@DAC>?B>C>@BAA?=B=@C?BA??=ABA=?<A@A>@>>:@=@:;==<?9=?>>>9:89;>=9788=7=
```

Le nombre de lignes de la version décompressée :

```bash
zcat run_sequencage/fastq/P07_S7_L001_R1_001.fastq.gz | wc -l
```

```text
1160
```

1160 lignes ÷ 4 = 290 reads. Le problème du chapitre 04 est résolu.

> **Bon réflexe** : `zcat fichier.gz | head` est instantané, même sur un
> fichier de 50 Go. Dès que `head` a reçu ses lignes, il s'arrête, et la
> décompression s'interrompt avec lui.

### 3.3 Enchaîner plus de deux commandes

Un pipeline peut compter autant de commandes que nécessaire. La séquence
du premier read de P09, l'échantillon de mauvaise qualité :

```bash
zcat run_sequencage/fastq/P09_S9_L001_R1_001.fastq.gz | head -n 2 | tail -n 1
```

```text
ACCGTCGGAGCATTAGGATCAGGGGATCACAGTTCCGATGNGCGAGTACAAAAACGGTCAGCGCACCCAGCTGAACGTTATTATACTCACGTTTCTCGCG
```

Lisez le pipeline de gauche à droite : décompresser, garder les 2
premières lignes, puis garder la dernière de ces deux lignes, c'est-à-dire
la séquence du premier read. On remarque au passage un `N`, une base que le
séquenceur n'a pas pu déterminer.

> **Méthode : construisez un pipeline pas à pas.** Écrivez la première
> commande, regardez sa sortie (avec `| head` si elle est longue), ajoutez
> la commande suivante, regardez à nouveau, et ainsi de suite. On ne
> devine pas un pipeline de cinq commandes d'un coup : on l'assemble.

---

## 4. Enregistrer un résultat : `>` et `>>`

### 4.1 Écrire dans un fichier

`>` redirige la sortie standard vers un fichier au lieu de l'écran :

```bash
ls run_sequencage/fastq > liste_fichiers.txt
head -n 3 liste_fichiers.txt
```

```text
MD5SUMS.txt
P01_S1_L001_R1_001.fastq.gz
P01_S1_L001_R2_001.fastq.gz
```

La première commande n'affiche rien : tout est parti dans le fichier.

### 4.2 Ajouter à la fin : `>>`

```bash
echo "Analyse du run 2026-10-14" > journal.txt
echo "Vérification MD5 : faite" >> journal.txt
cat journal.txt
```

```text
Analyse du run 2026-10-14
Vérification MD5 : faite
```

| Opérateur | Si le fichier n'existe pas | Si le fichier existe |
|---|---|---|
| `>` | il est créé | **il est vidé puis réécrit** |
| `>>` | il est créé | la sortie est **ajoutée à la fin** |

> **Attention : `>` écrase sans prévenir**, exactement comme `cp`
> (chapitre 03). `echo "écrasé" > journal.txt` efface tout le journal.

### 4.3 Le piège classique : lire et écrire le même fichier

```bash
cp run_sequencage/echantillons.tsv copie.tsv
head -n 3 copie.tsv > copie.tsv
wc -l copie.tsv
```

```text
0 copie.tsv
```

Le fichier est **vide**. Le shell prépare la redirection `> copie.tsv`
(et vide donc le fichier) **avant** de lancer `head`, qui ne trouve plus
rien à lire. **N'écrivez jamais dans le fichier que vous lisez** : écrivez
dans un nouveau fichier, puis renommez-le avec `mv` si besoin.

> **Pour aller plus loin** : `set -o noclobber` fait refuser à `>`
> l'écrasement d'un fichier existant (`cannot overwrite existing file`).
> `set +o noclobber` rétablit le comportement normal.

### 4.4 Concaténer des fichiers

`cat` signifie *concatenate*, et c'est sa vraie raison d'être : mettre
plusieurs fichiers bout à bout.

```bash
cat genome.fasta proteins.fasta > toutes.fasta
wc -l toutes.fasta
```

```text
522 toutes.fasta
```

419 + 103 = 522 lignes. Fusionner des FASTA de cette façon est une
opération courante, par exemple pour constituer une base de séquences de
référence.

---

## 5. Lire depuis un fichier : `<`

`<` branche un fichier sur l'**entrée** standard d'une commande :

```bash
wc -l reads.fastq
wc -l < reads.fastq
```

```text
2000 reads.fastq
2000
```

Avec `<`, `wc` ne connaît pas le nom du fichier : il ne voit qu'un flux de
lignes, et n'affiche donc que le nombre. C'est exactement ce dont vous aurez
besoin pour faire des calculs (section 8).

---

## 6. Les messages d'erreur : `2>`

### 6.1 Les erreurs ne passent pas par `>`

```bash
ls genome.fasta inexistant.fasta > sortie.txt
```

```text
ls: cannot access 'inexistant.fasta': No such file or directory
```

```bash
cat sortie.txt
```

```text
genome.fasta
```

Le résultat (`genome.fasta`) est parti dans le fichier, mais l'erreur s'est
quand même affichée à l'écran : elle est passée par le **flux 2**, que `>`
ne redirige pas. Cette séparation est voulue : un fichier de résultats ne
doit pas être pollué par des messages d'erreur.

### 6.2 Rediriger les erreurs

| Écriture | Effet |
|---|---|
| `2> erreurs.txt` | les erreurs vont dans `erreurs.txt` |
| `> tout.txt 2>&1` | les erreurs vont **au même endroit** que la sortie (« 2 vers là où va 1 ») |
| `&> tout.txt` | raccourci de Bash pour la ligne précédente |
| `2> /dev/null` | les erreurs sont **jetées** |

```bash
ls genome.fasta inexistant.fasta > sortie.txt 2> erreurs.txt
cat erreurs.txt
```

```text
ls: cannot access 'inexistant.fasta': No such file or directory
```

Rien ne s'affiche à l'écran : le résultat est dans `sortie.txt` et l'erreur
dans `erreurs.txt`.

> **L'ordre compte dans `> fichier 2>&1`** : on redirige d'abord la sortie
> vers le fichier, puis les erreurs « au même endroit que la sortie ».
> Écrit dans l'autre sens, `2>&1 > fichier`, les erreurs restent à l'écran.

### 6.3 `/dev/null` : la poubelle

`/dev/null` est un fichier spécial qui avale tout ce qu'on y écrit. Son
usage typique est de masquer des erreurs **attendues et sans intérêt**.
Cherchez par exemple les fichiers de configuration du système :

```bash
find /etc -name "*.conf"
```

La liste est noyée de lignes comme celles-ci, parce que vous n'avez pas le
droit de lire certains dossiers système :

```text
find: ‘/etc/polkit-1/rules.d’: Permission denied
find: ‘/etc/ssl/private’: Permission denied
```

```bash
find /etc -name "*.conf" 2> /dev/null
```

Seuls les résultats restent.

> **Attention** : `2> /dev/null` cache **toutes** les erreurs, y compris
> celles qui comptent. Ne l'utilisez que quand vous savez exactement quelles
> erreurs vous jetez. Et sous WSL, ne lancez pas `find /` : il parcourrait
> aussi tout votre disque Windows (`/mnt/c`), ce qui peut prendre des
> dizaines de minutes.

### 6.4 Une erreur au milieu d'un pipeline

Comptez les lignes du fichier tronqué identifié au chapitre 04 :

```bash
zcat run_sequencage/fastq/P11_S11_L001_R2_001.fastq.gz | wc -l
```

```text

gzip: run_sequencage/fastq/P11_S11_L001_R2_001.fastq.gz: unexpected end of file
691
```

`zcat` signale l'erreur sur stderr, mais `wc` compte quand même ce qu'il a
reçu avant la coupure : 691 lignes, alors que le R1 du même échantillon en
compte 1200. **Un pipeline ne s'arrête pas quand l'une de ses commandes
échoue.** Si le message d'erreur avait été jeté dans `/dev/null`, ou s'il
avait défilé sans que vous le lisiez, 691 aurait pu passer pour un vrai
résultat. Au chapitre 13, `set -o pipefail` rendra ce type d'échec
impossible à ignorer dans un script.

---

## 7. `tee` : enregistrer et continuer

`tee` est un raccord en T : il écrit ce qu'il reçoit dans un fichier **et**
le transmet à la suite du pipeline.

```bash
zcat run_sequencage/fastq/P07_S7_L001_R1_001.fastq.gz | head -n 8 | tee extrait.fastq | wc -l
```

```text
8
```

Les 8 lignes (2 reads) sont enregistrées dans `extrait.fastq`, et `wc`
les a comptées. `tee -a` ajoute au fichier au lieu de l'écraser, comme `>>`.
C'est l'outil idéal pour garder la trace de ce qu'on affiche à l'écran.

---

## 8. Réussi ou échoué ? Les codes de retour

### 8.1 `$?`

Chaque commande, en se terminant, renvoie un **code de retour** : `0`
signifie succès, toute autre valeur signale un échec. Le shell le range dans
la variable `$?`, que l'on consulte **juste après** la commande :

```bash
ls genome.fasta
echo $?
```

```text
genome.fasta
0
```

```bash
ls inexistant.fasta
echo $?
```

```text
ls: cannot access 'inexistant.fasta': No such file or directory
2
```

### 8.2 `&&` et `||` : agir selon le résultat

| Écriture | Signification |
|---|---|
| `A && B` | lancer B **seulement si** A a réussi |
| `A \|\| B` | lancer B **seulement si** A a échoué |
| `A ; B` | lancer B dans tous les cas |

```bash
mkdir -p resultats && cd resultats
```

Ici, `cd` ne s'exécute que si le dossier a bien été créé. Combinés,
`&&` et `||` donnent un diagnostic en une ligne :

```bash
cd ~/formation_linux
gzip -t run_sequencage/fastq/P10_S10_L001_R2_001.fastq.gz && echo "intact" || echo "CORROMPU"
gzip -t run_sequencage/fastq/P11_S11_L001_R2_001.fastq.gz 2> /dev/null && echo "intact" || echo "CORROMPU"
```

```text
intact
CORROMPU
```

Ici, `2> /dev/null` est légitime : le message d'erreur de `gzip` est
remplacé par notre propre verdict.

---

## 9. Insérer un résultat dans une commande : `$( )` et `$(( ))`

### 9.1 La substitution de commande `$( )`

Le shell exécute d'abord ce qui est entre `$( )`, puis **remplace** cette
expression par son résultat :

```bash
echo "Le dossier courant est $(pwd)"
```

```text
Le dossier courant est /home/marie/formation_linux
```

### 9.2 L'arithmétique `$(( ))`

Entre `$(( ))`, le shell calcule sur des **nombres entiers** :

```bash
echo $(( 1160 / 4 ))
```

```text
290
```

| Opérateur | Opération | Exemple | Résultat |
|---|---|---|---|
| `+ - *` | addition, soustraction, multiplication | `$(( 290 * 2 ))` | `580` |
| `/` | division **entière** (sans décimales) | `$(( 10 / 3 ))` | `3` |
| `%` | reste de la division | `$(( 691 % 4 ))` | `3` |
| `**` | puissance | `$(( 2 ** 10 ))` | `1024` |

> **Attention : pas de décimales.** `$(( 10 / 3 ))` vaut `3`. Pour des
> calculs à virgule (pourcentages, moyennes), vous utiliserez `awk` au
> chapitre 07.

### 9.3 Combiner les deux : compter des reads en une ligne

```bash
echo $(( $(zcat run_sequencage/fastq/P07_S7_L001_R1_001.fastq.gz | wc -l) / 4 ))
```

```text
290
```

Lisez de l'intérieur vers l'extérieur : `zcat … | wc -l` donne `1160`, la
substitution `$( )` met `1160` à sa place, puis `$(( 1160 / 4 ))` donne
`290`. Le reste `%` vérifie au passage qu'un FASTQ est bien formé : un
reste non nul signale un fichier abîmé.

```bash
echo $(( $(zcat run_sequencage/fastq/P11_S11_L001_R2_001.fastq.gz 2> /dev/null | wc -l) % 4 ))
```

```text
3
```

---

## 10. En bioinformatique

Vous retrouverez ces opérateurs dans presque toutes les commandes des
outils d'analyse :

```text
bwa mem reference.fasta R1.fastq.gz R2.fastq.gz > alignements.sam 2> bwa.log
samtools view -b alignements.sam | samtools sort -o alignements.trie.bam
fastqc echantillon.fastq.gz 2>&1 | tee qc.log
```

- La plupart des outils écrivent leur **résultat sur stdout** et leurs
  **messages de progression sur stderr**. On redirige l'un vers le fichier
  de résultats et l'autre vers un journal (*log*) : c'est la raison d'être
  de cette séparation.
- Des outils comme `samtools` lisent et écrivent dans des pipes, ce qui
  évite de créer des fichiers intermédiaires de plusieurs gigaoctets.
- Garder les journaux (`2> outil.log`) est une exigence de
  reproductibilité : ils indiquent la version de l'outil, ses paramètres et
  ses avertissements.

---

## 11. Pièges fréquents

| Situation | Symptôme | Solution |
|---|---|---|
| `commande fichier > fichier` | le fichier est vidé | écrire dans un nouveau fichier |
| `>` au lieu de `>>` | les résultats précédents disparaissent | `>>` pour ajouter ; `set -o noclobber` |
| les erreurs apparaissent malgré `>` | — | normal : elles passent par stderr ; `2>` |
| `2>&1 > fichier` | les erreurs restent à l'écran | `> fichier 2>&1` |
| `2> /dev/null` systématique | un vrai problème passe inaperçu | ne jeter que des erreurs connues |
| une commande échoue au milieu d'un pipe | résultat partiel présenté comme complet | lire les messages ; `pipefail` (chapitre 13) |
| `$(( 7 / 2 ))` donne `3` | pas de décimales | `awk` (chapitre 07) |
| espace autour de `=`, ou `$ ( )` | erreur de syntaxe | `$(commande)` et `$((calcul))`, sans espace après `$` |

---

## 12. À vous de jouer

Commencez par `cd ~/formation_linux`.

### Exercice 1 : compter sans compter à l'œil

*Objectif : `|` et `wc -l`.*
Combien y a-t-il de fichiers R1 dans le run ? De fichiers dans
`formats/` ? De lignes dans la feuille d'échantillons, en-tête exclu ?

<details>
<summary>Corrigé</summary>

```bash
ls run_sequencage/fastq/*_R1_* | wc -l
ls formats | wc -l
tail -n +2 run_sequencage/echantillons.tsv | wc -l
```

Résultats : `12`, `6` et `12`.
</details>

### Exercice 2 : le nombre de reads de trois échantillons

*Objectif : `$( )`, `$(( ))` et pipeline.*
Affichez le nombre de reads des fichiers R1 de P01, P07 et P09, sous la
forme `P01 : 300 reads`.

<details>
<summary>Corrigé</summary>

```bash
echo "P01 : $(( $(zcat run_sequencage/fastq/P01_S1_L001_R1_001.fastq.gz | wc -l) / 4 )) reads"
echo "P07 : $(( $(zcat run_sequencage/fastq/P07_S7_L001_R1_001.fastq.gz | wc -l) / 4 )) reads"
echo "P09 : $(( $(zcat run_sequencage/fastq/P09_S9_L001_R1_001.fastq.gz | wc -l) / 4 )) reads"
```

```text
P01 : 300 reads
P07 : 290 reads
P09 : 150 reads
```

Taper trois fois presque la même ligne est fastidieux. Une **boucle**
(chapitre 12) le fera pour les 24 fichiers d'un coup.
</details>

### Exercice 3 : tenir un journal d'analyse

*Objectif : `>` et `>>`.*
Créez `journal_run.txt`. Sa première ligne doit contenir la date du jour
(utilisez `$(date +%Y-%m-%d)`). Ajoutez ensuite une ligne qui indique le
nombre de fichiers FASTQ du run, puis une ligne `Contrôle MD5 : à faire`.
Affichez le journal.

<details>
<summary>Corrigé</summary>

```bash
echo "Journal d'analyse du $(date +%Y-%m-%d)" > journal_run.txt
echo "Fichiers FASTQ reçus : $(ls run_sequencage/fastq/*.fastq.gz | wc -l)" >> journal_run.txt
echo "Contrôle MD5 : à faire" >> journal_run.txt
cat journal_run.txt
```

```text
Journal d'analyse du 2026-11-24
Fichiers FASTQ reçus : 24
Contrôle MD5 : à faire
```

La première ligne utilise `>` (création), les suivantes `>>` (ajout).
</details>

### Exercice 4 : ranger les résultats et les erreurs

*Objectif : `>`, `2>` et `&&`.*
Placez-vous dans `run_sequencage/fastq`. Lancez `md5sum -c MD5SUMS.txt` en
envoyant le résultat dans `verification_md5.txt` et les avertissements dans
`verification_md5.err`. Affichez ensuite les deux fichiers. Combien de
lignes contient `verification_md5.txt` ?

<details>
<summary>Corrigé</summary>

```bash
cd ~/formation_linux/run_sequencage/fastq
md5sum -c MD5SUMS.txt > verification_md5.txt 2> verification_md5.err
cat verification_md5.err
wc -l verification_md5.txt
cd ~/formation_linux
```

`verification_md5.err` contient
`md5sum: WARNING: 1 computed checksum did NOT match`, et
`verification_md5.txt` contient 24 lignes, une par fichier, dont celle qui
se termine par `FAILED`. Le résultat et l'avertissement sont rangés
séparément, ce qui est exactement le rôle de stderr.
</details>

### Exercice 5 : le fichier tronqué, chiffres à l'appui

*Objectif : utiliser le reste `%` pour vérifier un FASTQ.*
Pour le R1 et le R2 de P11, calculez le nombre de lignes et le reste de sa
division par 4. Concluez.

<details>
<summary>Corrigé</summary>

```bash
zcat run_sequencage/fastq/P11_S11_L001_R1_001.fastq.gz | wc -l
zcat run_sequencage/fastq/P11_S11_L001_R2_001.fastq.gz | wc -l
echo $(( 1200 % 4 )) $(( 691 % 4 ))
```

R1 : 1200 lignes, reste 0, soit 300 reads complets. R2 : 691 lignes, avec
une erreur `unexpected end of file`, et un reste de 3. Le R2 est tronqué au
milieu d'un read et ne contient qu'environ 172 reads sur 300. Les paires ne
correspondent plus : ce fichier est inutilisable en l'état.
</details>

### Exercice 6 : un FASTA de toutes les séquences

*Objectif : concaténer avec `cat` et vérifier.*
Créez `toutes_sequences.fasta`, qui réunit `transcripts.fasta` et
`proteins.fasta`. Vérifiez que son nombre de lignes est la somme des deux.

<details>
<summary>Corrigé</summary>

```bash
cat transcripts.fasta proteins.fasta > toutes_sequences.fasta
wc -l transcripts.fasta proteins.fasta toutes_sequences.fasta
```

```text
  217 transcripts.fasta
  103 proteins.fasta
  320 toutes_sequences.fasta
  640 total
```

217 + 103 = 320. Mélanger des séquences nucléiques et protéiques n'aurait
pas de sens biologique : c'est un simple exercice de manipulation.
</details>

---

## 13. Défi : le bilan de deux échantillons historiques

En **une seule ligne de commande**, affichez le nombre total de reads
contenus dans `sample_01.fastq.gz` **et** `sample_02.fastq.gz` réunis,
sous la forme `Total : … reads`. Enregistrez en même temps cette phrase
dans `bilan.txt`, sans perdre l'affichage à l'écran.

<details>
<summary>Indice</summary>

`zcat` accepte plusieurs fichiers et les décompresse à la suite, comme
`cat`. Pour écrire dans un fichier tout en affichant, pensez à `tee`.
</details>

<details>
<summary>Corrigé</summary>

```bash
echo "Total : $(( $(zcat sample_01.fastq.gz sample_02.fastq.gz | wc -l) / 4 )) reads" | tee bilan.txt
```

```text
Total : 2000 reads
```

`zcat` met bout à bout les deux fichiers décompressés (8000 lignes), la
division donne 2000 reads, soit 1200 + 800. `tee` écrit la phrase dans
`bilan.txt` et l'affiche.
</details>

---

## L'essentiel

```text
A | B                 la sortie de A devient l'entrée de B
> fichier             écrire (ÉCRASE)       >> fichier   ajouter à la fin
< fichier             lire l'entrée depuis un fichier
2> fichier            les erreurs dans un fichier
> f 2>&1   ou  &> f   sortie ET erreurs dans le même fichier
2> /dev/null          jeter les erreurs (avec discernement)
tee fichier           enregistrer et transmettre
$?   A && B   A || B  code de retour (0 = succès), agir selon le résultat
$(commande)           insérer le résultat d'une commande
$(( calcul ))         arithmétique entière : + - * / % **
zcat f.gz | wc -l     lignes d'un fichier compressé ; ÷ 4 = reads FASTQ
Ne jamais écrire dans le fichier qu'on lit.
```

### Auto-évaluation

- [ ] J'explique la différence entre stdout et stderr, et pourquoi elle existe.
- [ ] Je construis un pipeline étape par étape, en vérifiant chaque sortie.
- [ ] Je sais quand utiliser `>` ou `>>`, et je ne lis jamais le fichier dans lequel j'écris.
- [ ] Je sépare les résultats et les erreurs d'une commande dans deux fichiers.
- [ ] Je compte les reads d'un FASTQ compressé en une ligne.
- [ ] Je sais pourquoi un pipeline peut produire un résultat faux sans s'arrêter.

## Documentation officielle

- Redirections (manuel de Bash) : <https://www.gnu.org/software/bash/manual/html_node/Redirections.html>
- Pipelines et listes `&&` / `||` : <https://www.gnu.org/software/bash/manual/html_node/Pipelines.html> · <https://www.gnu.org/software/bash/manual/html_node/Lists.html>
- Substitution de commande et arithmétique : <https://www.gnu.org/software/bash/manual/html_node/Command-Substitution.html> · <https://www.gnu.org/software/bash/manual/html_node/Arithmetic-Expansion.html>
- `tee` (GNU Coreutils) : <https://www.gnu.org/software/coreutils/manual/html_node/tee-invocation.html>

**Prochaine étape** : [chapitre 06 — Chercher et filtrer](../06_chercher_filtrer/README.md).
