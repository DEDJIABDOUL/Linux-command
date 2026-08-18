# Linux pour la bioinformatique — Guide pratique débutant

## Objectif

Ce guide rassemble les commandes Linux essentielles pour commencer à travailler avec des données de bioinformatique, notamment les fichiers **FASTA**, **FASTQ**, **FASTA/FASTQ compressés**, ainsi que les premières étapes d'automatisation avec Bash.

L'objectif n'est pas de mémoriser toutes les commandes, mais de comprendre leur rôle et de savoir les combiner.

---

# 1. Comprendre le terminal Linux

Un terminal permet d'interagir avec le système en exécutant des commandes.

Structure générale :

```bash
commande [options] [argument]
```

Exemple :

```bash
ls -lh genome.fasta
```

Ici :

- `ls` = commande
- `-lh` = options
- `genome.fasta` = fichier ciblé

---

# 2. Se déplacer dans les dossiers

## 2.1 Afficher le dossier courant

```bash
pwd
```

`pwd` signifie **Print Working Directory**.

## 2.2 Lister les fichiers

```bash
ls
```

Avec les détails :

```bash
ls -l
```

Avec des tailles lisibles :

```bash
ls -lh
```

Afficher également les fichiers cachés :

```bash
ls -la
```

## 2.3 Changer de dossier

```bash
cd dossier
```

Revenir au dossier parent :

```bash
cd ..
```

Revenir au dossier personnel :

```bash
cd ~
```

## 2.4 Créer un dossier

```bash
mkdir bioinfo
```

Créer plusieurs niveaux :

```bash
mkdir -p projet/data/raw
```

## 2.5 Créer un fichier vide

```bash
touch test.txt
```

## 2.6 Copier un fichier

```bash
cp fichier.txt copie.txt
```

Copier un dossier :

```bash
cp -r dossier1 dossier2
```

## 2.7 Déplacer ou renommer

```bash
mv ancien.txt nouveau.txt
```

Déplacer :

```bash
mv fichier.txt data/
```

## 2.8 Supprimer

```bash
rm fichier.txt
```

Supprimer un dossier et son contenu :

```bash
rm -r dossier
```

**Attention :** `rm` supprime directement les fichiers. Vérifier avant d'exécuter.

---

# 3. Explorer les fichiers

## 3.1 Afficher le début d'un fichier

```bash
head fichier.txt
```

Les 20 premières lignes :

```bash
head -n 20 fichier.txt
```

## 3.2 Afficher la fin

```bash
tail fichier.txt
```

Les 20 dernières lignes :

```bash
tail -n 20 fichier.txt
```

## 3.3 Lire progressivement un gros fichier

```bash
less fichier.txt
```

Dans `less` :

- `Space` : page suivante
- `b` : page précédente
- `/motif` : rechercher
- `q` : quitter

## 3.4 Afficher le contenu

```bash
cat fichier.txt
```

Pour les gros fichiers, préférer `less`.

## 3.5 Identifier un fichier

```bash
file fichier
```

## 3.6 Informations détaillées

```bash
stat fichier
```

---

# 4. Rechercher des fichiers

## 4.1 Rechercher un fichier par nom

```bash
find . -name "*.fastq"
```

Rechercher les FASTQ compressés :

```bash
find . -name "*.fastq.gz"
```

Rechercher tous les FASTA :

```bash
find . -name "*.fasta"
```

## 4.2 Rechercher les gros fichiers

```bash
find . -type f -size +1G
```

---

# 5. Mesurer le nombre de lignes

## 5.1 Compter les lignes

```bash
wc -l fichier.txt
```

Uniquement le nombre :

```bash
wc -l < fichier.txt
```

## 5.2 FASTQ : compter les reads

Un FASTQ classique contient 4 lignes par read :

```text
@READ_ID
SEQUENCE
+
QUALITY
```

Donc :

```bash
echo $(( $(wc -l < reads.fastq) / 4 ))
```

Pour un fichier FASTQ compressé :

```bash
echo $(( $(zcat reads.fastq.gz | wc -l) / 4 ))
```

**Attention :** cette méthode suppose un FASTQ valide avec quatre lignes par read.

---

# 6. FASTA : commandes essentielles

Un fichier FASTA ressemble à :

```text
>chr1
ATGCGTACGT...
>chr2
GCTAGCTAGC...
```

## 6.1 Afficher les headers

```bash
grep "^>" genome.fasta
```

## 6.2 Compter les séquences

```bash
grep -c "^>" genome.fasta
```

## 6.3 Afficher uniquement les séquences

```bash
grep -v "^>" genome.fasta
```

## 6.4 Afficher le début

```bash
head genome.fasta
```

---

# 7. FASTQ : commandes essentielles

Un fichier FASTQ contient :

```text
@READ_ID
ATGCGT...
+
FFFFFFFF
```

Afficher les premiers reads :

```bash
head -n 20 reads.fastq
```

Afficher les statistiques avec SeqKit :

```bash
seqkit stats reads.fastq
```

Pour un FASTQ compressé :

```bash
seqkit stats reads.fastq.gz
```

---

# 8. Rechercher un motif biologique

## 8.1 Recherche simple

```bash
grep -n "ATGCGT" sequence.fasta
```

`-n` affiche le numéro de ligne.

## 8.2 Recherche sans tenir compte des majuscules/minuscules

```bash
grep -ni "ATGCGT" sequence.fasta
```

## 8.3 Compter les lignes contenant un motif

```bash
grep -ic "ATGCGT" sequence.fasta
```

## 8.4 Rechercher uniquement dans les séquences

```bash
grep -v "^>" sequence.fasta | grep -n "ATGCGT"
```

**Important :** `grep` recherche du texte. Dans un vrai projet bioinformatique, `seqkit` est souvent préférable pour manipuler correctement les enregistrements FASTA/FASTQ.

---

# 9. Colorer un motif dans le terminal

Pour afficher un motif en couleur :

```bash
grep --color=always -E "ATGCGT|$" sequence.fasta
```

Plusieurs motifs :

```bash
grep --color=always -E "ATG|TAA|TAG|TGA|$" sequence.fasta
```

La couleur dépend du terminal et de sa configuration.

---

# 10. Étiqueter un motif

Supposons :

```text
ATGCGTACGTTAG
```

On souhaite entourer `CGT` :

```text
ATG[CGT]ACGTTAG
```

Utiliser :

```bash
sed 's/CGT/[CGT]/g' sequence.fasta
```

Sauvegarder le résultat :

```bash
sed 's/CGT/[CGT]/g' sequence.fasta > sequence_annotated.fasta
```

**Attention :** cette méthode est une manipulation textuelle. Pour annoter réellement des coordonnées génomiques, utiliser plutôt des formats et outils adaptés comme BED/bedtools.

---

# 11. Taille et poids des fichiers

## 11.1 Taille lisible

```bash
ls -lh sequence.fasta
```

## 11.2 Taille du fichier

```bash
du -h sequence.fasta
```

## 11.3 Taille totale

```bash
du -sh sequence.fasta
```

## 11.4 Taille de plusieurs fichiers

```bash
du -sh *.fasta
```

## 11.5 Espace disque disponible

```bash
df -h
```

---

# 12. Compression FASTA/FASTQ

Les fichiers génomiques sont souvent compressés :

```text
genome.fasta.gz
reads.fastq.gz
```

## 12.1 Compresser

```bash
gzip genome.fasta
```

## 12.2 Décompresser

```bash
gunzip genome.fasta.gz
```

## 12.3 Lire un fichier compressé

```bash
zcat reads.fastq.gz | head
```

## 12.4 Lire avec navigation

```bash
zless reads.fastq.gz
```

## 12.5 Rechercher dans un fichier compressé

```bash
zgrep "ATG" genome.fasta.gz
```

**Conseil :** éviter de décompresser inutilement les gros fichiers. Beaucoup d'outils bioinformatiques acceptent directement `.gz`.

---

# 13. Redirections Linux

Les redirections sont fondamentales.

## 13.1 `>`

Créer ou remplacer un fichier :

```bash
grep "^>" genome.fasta > chromosomes.txt
```

## 13.2 `>>`

Ajouter à un fichier :

```bash
grep "^>" genome.fasta >> chromosomes.txt
```

## 13.3 `<`

Utiliser un fichier comme entrée :

```bash
wc -l < genome.fasta
```

---

# 14. Le pipeline `|`

Le caractère `|` permet d'envoyer la sortie d'une commande vers une autre.

Exemple :

```bash
grep "^>" genome.fasta | wc -l
```

Logique :

```text
genome.fasta
     ↓
grep "^>"
     ↓
headers
     ↓
wc -l
     ↓
nombre de séquences
```

Autre exemple :

```bash
grep "^>" genome.fasta | sort
```

---

# 15. Manipulation de texte

## 15.1 `cut`

Extraire une colonne :

```bash
cut -f 1 fichier.tsv
```

## 15.2 `sort`

Trier :

```bash
sort fichier.txt
```

Trier numériquement :

```bash
sort -n fichier.txt
```

## 15.3 `uniq`

Supprimer les répétitions consécutives :

```bash
sort fichier.txt | uniq
```

Compter les occurrences :

```bash
sort fichier.txt | uniq -c
```

## 15.4 `tr`

Transformer des caractères :

```bash
tr 'a-z' 'A-Z' < sequence.txt
```

## 15.5 `sed`

Remplacer un texte :

```bash
sed 's/ancien/nouveau/g' fichier.txt
```

## 15.6 `awk`

Afficher une colonne :

```bash
awk '{print $1}' fichier.txt
```

---

# 16. Séparer un FASTA par chromosome

Supposons :

```text
>chr1
ATGC...
>chr2
ATGC...
>chr3
ATGC...
```

## 16.1 Séparation simple

```bash
awk '/^>/{filename=substr($0,2) ".fasta"} {print > filename}' genome.fasta
```

Résultat :

```text
chr1.fasta
chr2.fasta
chr3.fasta
```

## 16.2 Un dossier par chromosome

```bash
awk '
/^>/ {
    name=substr($0,2)
    gsub(/[[:space:]].*/, "", name)
    dir=name
    system("mkdir -p \"" dir "\"")
    file=dir "/" name ".fasta"
}
{
    print >> file
}
' genome.fasta
```

Résultat :

```text
genome/
├── chr1/
│   └── chr1.fasta
├── chr2/
│   └── chr2.fasta
└── chr3/
    └── chr3.fasta
```

Pour les données biologiques réelles, une solution spécialisée comme `seqkit` peut être préférable.

---

# 17. SeqKit : outil essentiel pour FASTA/FASTQ

Installation avec Conda :

```bash
conda install -c bioconda seqkit
```

Vérifier l'installation :

```bash
seqkit version
```

## 17.1 Statistiques

```bash
seqkit stats genome.fasta
```

```bash
seqkit stats reads.fastq.gz
```

Les statistiques peuvent inclure :

- nombre de séquences
- longueur totale
- longueur minimale
- longueur moyenne
- longueur maximale
- informations sur les bases

## 17.2 Rechercher un motif

```bash
seqkit grep -s -p "ATGCGT" genome.fasta
```

## 17.3 Extraire une séquence par identifiant

```bash
seqkit grep -p "chr1" genome.fasta
```

## 17.4 Séparer un fichier

```bash
seqkit split genome.fasta
```

Consulter l'aide :

```bash
seqkit --help
```

Pour une commande particulière :

```bash
seqkit grep --help
```

---

# 18. Gestion des processus et ressources

La génomique peut consommer beaucoup de CPU, RAM et stockage.

## 18.1 CPU

```bash
lscpu
```

## 18.2 RAM

```bash
free -h
```

## 18.3 Processus

```bash
ps
```

## 18.4 Surveillance

```bash
top
```

Si disponible :

```bash
htop
```

## 18.5 Temps depuis le démarrage

```bash
uptime
```

---

# 19. Permissions Linux

## 19.1 Voir les permissions

```bash
ls -l
```

Exemple :

```text
-rwxr-xr-x
```

Signification :

```text
r = read
w = write
x = execute
```

## 19.2 Rendre un script exécutable

```bash
chmod +x script.sh
```

Puis :

```bash
./script.sh
```

## 19.3 Changer le propriétaire

```bash
chown utilisateur fichier
```

`chown` nécessite souvent des privilèges administrateur.

---

# 20. Variables Bash

Une variable permet de réutiliser facilement une valeur.

```bash
FILE="genome.fasta"
```

Afficher :

```bash
echo "$FILE"
```

Utiliser :

```bash
ls -lh "$FILE"
```

---

# 21. Boucles Bash

Les boucles sont essentielles pour traiter plusieurs échantillons.

```bash
for file in *.fastq.gz
do
    echo "$file"
done
```

Exemple avec SeqKit :

```bash
for file in *.fastq.gz
do
    echo "Processing $file"
    seqkit stats "$file"
done
```

---

# 22. Écrire un script Bash

Créer :

```bash
touch pipeline.sh
```

Éditer avec un éditeur, puis commencer par :

```bash
#!/bin/bash
```

Exemple :

```bash
#!/bin/bash

echo "Starting analysis..."

for file in *.fastq.gz
do
    echo "Processing $file"
    seqkit stats "$file"
done

echo "Analysis completed."
```

Rendre exécutable :

```bash
chmod +x pipeline.sh
```

Exécuter :

```bash
./pipeline.sh
```

---

# 23. Trouver les logiciels installés

## 23.1 Localiser une commande

```bash
which fastqc
```

Ou :

```bash
command -v fastqc
```

## 23.2 Afficher le PATH

```bash
echo "$PATH"
```

Le `PATH` indique les répertoires dans lesquels Linux recherche les programmes.

---

# 24. Conda pour l'environnement bioinformatique

Conda permet de créer des environnements isolés.

## 24.1 Voir les environnements

```bash
conda env list
```

## 24.2 Créer un environnement

```bash
conda create -n bioinfo
```

## 24.3 Activer

```bash
conda activate bioinfo
```

## 24.4 Désactiver

```bash
conda deactivate
```

## 24.5 Installer un logiciel

```bash
conda install -c bioconda seqkit
```

## 24.6 Voir les logiciels installés

```bash
conda list
```

---

# 25. Outils bioinformatiques importants à connaître

Après les commandes Linux, il est utile de connaître les outils spécialisés suivants.

## Contrôle qualité

```text
FastQC
MultiQC
Fastp
Cutadapt
FastQ Screen
```

## FASTA / FASTQ

```text
SeqKit
Seqtk
```

## Alignement

```text
BWA
Bowtie2
Minimap2
STAR
HISAT2
```

## SAM/BAM

```text
Samtools
```

Commandes importantes :

```bash
samtools view
samtools sort
samtools index
samtools flagstat
samtools stats
```

## Variants

```text
BCFtools
```

## Régions génomiques

```text
Bedtools
```

## Recherche de similarité

```text
BLAST
blastn
blastp
```

---

# 26. Workflow conseillé pour débuter en RNA-seq

Un workflow conceptuel typique :

```text
Données FASTQ
      ↓
Contrôle qualité
      ↓
FastQC
      ↓
MultiQC
      ↓
Trimming / Filtering
      ↓
Fastp / Cutadapt
      ↓
Contrôle qualité
      ↓
Alignement
      ↓
STAR / HISAT2
      ↓
SAM/BAM
      ↓
Samtools
      ↓
Quantification
      ↓
FeatureCounts
      ↓
Analyse statistique
      ↓
R / DESeq2 / edgeR
```

Pour ton apprentissage, il est préférable de maîtriser chaque étape avant d'automatiser tout le pipeline.

---

# 27. Les commandes à apprendre en priorité

Ne cherche pas à mémoriser immédiatement tout le guide.

## Niveau 1 — Linux fondamental

```bash
pwd
ls
cd
mkdir
cp
mv
rm
find
```

## Niveau 2 — Fichiers

```bash
cat
less
head
tail
wc
grep
```

## Niveau 3 — Manipulation

```bash
awk
sed
cut
sort
uniq
tr
```

## Niveau 4 — Flux Linux

```bash
|
>
>>
<
```

## Niveau 5 — Compression

```bash
gzip
gunzip
zcat
zless
zgrep
```

## Niveau 6 — Ressources

```bash
du
df
free
top
htop
lscpu
```

## Niveau 7 — Automatisation

```bash
chmod
for
echo
variables Bash
scripts .sh
```

## Niveau 8 — Bioinformatique

```bash
seqkit
fastqc
multiqc
fastp
samtools
bedtools
bcftools
blast
```

---

# 28. Exercices pratiques recommandés

Pour apprendre efficacement, crée un dossier :

```bash
mkdir -p bioinfo_exercises/{fasta,fastq,results,scripts}
cd bioinfo_exercises
```

Puis pratique progressivement.

### Exercice 1 — Explorer

```bash
pwd
ls
ls -lh
```

### Exercice 2 — FASTA

```bash
grep "^>" genome.fasta
grep -c "^>" genome.fasta
head genome.fasta
```

### Exercice 3 — Motif

```bash
grep -n "ATG" genome.fasta
grep --color=always -E "ATG|$" genome.fasta
```

### Exercice 4 — Taille

```bash
ls -lh genome.fasta
du -sh genome.fasta
```

### Exercice 5 — FASTQ

```bash
wc -l reads.fastq
echo $(( $(wc -l < reads.fastq) / 4 ))
```

### Exercice 6 — Compression

```bash
gzip genome.fasta
zcat genome.fasta.gz | head
zgrep "^>" genome.fasta.gz
```

### Exercice 7 — SeqKit

```bash
seqkit stats genome.fasta
seqkit stats reads.fastq.gz
```

### Exercice 8 — Pipeline

```bash
grep "^>" genome.fasta | wc -l
```

### Exercice 9 — Automatisation

```bash
for file in *.fastq.gz
do
    seqkit stats "$file"
done
```

---

# 29. Les trois principes à retenir

## Principe 1 — Linux manipule des fichiers

```text
fichier → commande → résultat
```

## Principe 2 — Les commandes peuvent être combinées

```bash
commande1 | commande2 | commande3
```

## Principe 3 — L'automatisation vient ensuite

```text
commande
   ↓
pipeline
   ↓
script Bash
   ↓
workflow reproductible
```

En bioinformatique, cette progression est beaucoup plus importante que la mémorisation brute des commandes.

---

# 30. Référence rapide

| Besoin | Commande |
|---|---|
| Où suis-je ? | `pwd` |
| Lister | `ls` |
| Taille lisible | `ls -lh` |
| Changer de dossier | `cd` |
| Créer dossier | `mkdir` |
| Copier | `cp` |
| Déplacer | `mv` |
| Supprimer | `rm` |
| Rechercher fichier | `find` |
| Lire fichier | `less` |
| Début | `head` |
| Fin | `tail` |
| Compter lignes | `wc -l` |
| Rechercher motif | `grep` |
| Remplacer texte | `sed` |
| Manipuler colonnes | `awk`, `cut` |
| Trier | `sort` |
| Compter doublons | `uniq -c` |
| Compresser | `gzip` |
| Lire `.gz` | `zcat` |
| Taille dossier | `du -sh` |
| Espace disque | `df -h` |
| RAM | `free -h` |
| CPU | `lscpu` |
| Processus | `top`, `htop` |
| Exécuter script | `./script.sh` |
| Permissions | `chmod` |
| Stats FASTA/FASTQ | `seqkit stats` |
| Rechercher séquence | `seqkit grep` |
| QC | `fastqc` |
| Rapport QC | `multiqc` |
| Trimming | `fastp`, `cutadapt` |
| SAM/BAM | `samtools` |
| BED | `bedtools` |
| VCF | `bcftools` |
| Similarité | `blastn`, `blastp` |

---

## Conclusion

Pour un débutant en bioinformatique, la progression recommandée est :

```text
Linux
  ↓
Fichiers et dossiers
  ↓
grep / awk / sed
  ↓
Pipelines avec |
  ↓
FASTA / FASTQ
  ↓
gzip
  ↓
Bash
  ↓
Conda
  ↓
SeqKit
  ↓
FastQC / MultiQC
  ↓
Samtools / Bedtools / BCFtools
  ↓
Pipelines bioinformatiques complets
```

L'objectif final est de pouvoir passer d'une opération manuelle à une analyse reproductible :

```text
commande simple
      ↓
plusieurs commandes
      ↓
pipeline
      ↓
script Bash
      ↓
workflow bioinformatique reproductible
```
