# Jeu de données d'entraînement — Linux pour la bioinformatique

Ce dossier contient les fichiers nécessaires pour exécuter **toutes** les commandes
du guide `linux_commands_beginner.md`.

## Contenu

| Fichier | Contenu | Sert à pratiquer |
|---|---|---|
| `exercice_sequences.fasta` | 22 séquences (version enrichie de ton fichier d'origine) | tout le guide |
| `genome.fasta` | copie identique, nommée comme dans le guide | sections 6, 8, 9, 10, 16 |
| `transcripts.fasta` | 40 ARNm | `find`, `du -sh *.fasta`, boucles |
| `proteins.fasta` | 25 protéines (alphabet acides aminés) | `file`, `grep`, comparaison ADN/protéine |
| `reads.fastq` | 500 reads de 100 pb | section 5.2, 7 |
| `sample_01/02/03.fastq.gz` | 1200 / 800 / 1500 reads compressés | sections 12, 21, 22 |
| `annotations.tsv` | 120 annotations, 6 colonnes | `cut`, `awk`, `sort`, `uniq` |

## Ce qui a été ajouté par rapport au fichier d'origine

Ton fichier initial (5 séquences sur une seule ligne) ne permettait pas de tester
grand-chose. La version enrichie contient :

- **22 enregistrements** au lieu de 5, dont les 5 originaux conservés en tête
- des **longueurs variables** (45 pb à 4800 pb) → `seqkit stats`, `sort -n` deviennent utiles
- des **séquences repliées à 60 caractères** → `head`, `tail`, `wc -l`, `less` ont du sens
- des **headers structurés** : `>chr1 organism=... type=... length=...` → `cut`, `awk`, `sort | uniq -c`
- des **noms variés** (`chr1`…`chr4`, `plasmid_pUC19`, `mito_genome`, `contig_*`, `gene_*`, `scaffold_*`) → `find`, `seqkit grep`, découpage `awk`
- des **régions en minuscules** (soft-masked, comme un vrai génome répété) → différence entre `grep` et `grep -i`
- des **blocs de N** (bases indéterminées) → contrôle qualité
- des **ORF réalistes** (ATG … codon stop) → sections 9 et 10
- le motif **`ATGCGT` implanté volontairement** à des positions connues

---

## Exercices avec réponses attendues

> Les réponses sont données pour `genome.fasta`. Vérifie que tu obtiens la même chose.

### 1. Préparer l'espace de travail
```bash
mkdir -p bioinfo_exercises/{fasta,fastq,results,scripts}
cp *.fasta bioinfo_exercises/fasta/
cp *.fastq *.fastq.gz bioinfo_exercises/fastq/
cd bioinfo_exercises && ls -lh fasta/
```

### 2. Compter les séquences
```bash
grep -c "^>" genome.fasta          # → 22
grep -c "^>" transcripts.fasta     # → 40
grep -c "^>" proteins.fasta        # → 25
```

### 3. Compter les lignes et les bases
```bash
wc -l < genome.fasta                              # → 419
grep -v "^>" genome.fasta | tr -d '\n' | wc -c    # → 23718 bases
```

### 4. Exploiter les headers (`cut`, `sort`, `uniq`)
```bash
grep "^>" genome.fasta | cut -d' ' -f2 | sort | uniq -c
```
Résultat attendu :
```text
2 organism=Arabidopsis_thaliana
8 organism=Escherichia_coli
4 organism=Saccharomyces_cerevisiae
8 organism=synthetic
```
Puis par type :
```bash
grep "^>" genome.fasta | cut -d' ' -f3 | sort | uniq -c
```

### 5. Chercher un motif — et comprendre `-i`
```bash
grep -c  "ATGCGT" genome.fasta   # → 29 lignes
grep -ic "ATGCGT" genome.fasta   # → 31 lignes
```
La différence de 2 vient des régions **soft-masked en minuscules** : c'est exactement
la raison pour laquelle `-i` existe. Pour voir où :
```bash
grep -n "atgcgt" genome.fasta
```

### 6. Colorer et étiqueter (sections 9 et 10)
```bash
grep --color=always -E "ATGCGT|$" genome.fasta | less -R
grep --color=always -E "ATG|TAA|TAG|TGA|$" genome.fasta | less -R
sed 's/ATGCGT/[ATGCGT]/g' genome.fasta > results/genome_annotated.fasta
diff <(grep -c "\[" genome.fasta) <(grep -c "\[" results/genome_annotated.fasta)
```

### 7. FASTQ : compter les reads
```bash
echo $(( $(wc -l < reads.fastq) / 4 ))                    # → 500
echo $(( $(zcat sample_01.fastq.gz | wc -l) / 4 ))        # → 1200
echo $(( $(zcat sample_02.fastq.gz | wc -l) / 4 ))        # → 800
echo $(( $(zcat sample_03.fastq.gz | wc -l) / 4 ))        # → 1500
```
Les reads contiennent volontairement des **adaptateurs Illumina** et des **N** :
```bash
grep -c "AGATCGGAAGAGC" reads.fastq    # → 56 reads contaminés
grep -c "N" reads.fastq
```

### 8. Compression
```bash
gzip -k genome.fasta          # -k garde l'original
ls -lh genome.fasta*
zcat genome.fasta.gz | head
zgrep -c "^>" genome.fasta.gz  # → 22
du -sh *.fasta
```

### 9. Découper le FASTA par séquence (section 16)
```bash
mkdir -p results/split && cd results/split
awk '/^>/{f=substr($1,2)".fasta"} {print > f}' ../../genome.fasta
ls | wc -l        # → 22 fichiers
```
Note : `substr($1,2)` et non `substr($0,2)` — sinon le nom de fichier contiendrait
la description entière avec des espaces. Bon réflexe à prendre.

### 10. Le fichier TSV (`cut`, `awk`, `sort`, `uniq`)
```bash
head -1 annotations.tsv
cut -f5 annotations.tsv | tail -n +2 | sort | uniq -c | sort -rn
awk -F'\t' 'NR>1 {print $6}' annotations.tsv | sort -u
awk -F'\t' 'NR>1 && $3-$2 > 500 {print $1, $6, $3-$2}' annotations.tsv | head
```

### 11. Boucle Bash sur les échantillons
```bash
for f in *.fastq.gz
do
    n=$(( $(zcat "$f" | wc -l) / 4 ))
    echo -e "$f\t$n reads"
done
```

### 12. Script complet
```bash
cat > scripts/stats.sh <<'EOF'
#!/bin/bash
echo "=== FASTA ==="
for f in *.fasta; do
    echo -e "$f\t$(grep -c '^>' "$f") séquences"
done
echo "=== FASTQ ==="
for f in *.fastq.gz; do
    echo -e "$f\t$(( $(zcat "$f" | wc -l) / 4 )) reads"
done
EOF
chmod +x scripts/stats.sh
./scripts/stats.sh
```

### 13. SeqKit (si installé)
```bash
seqkit stats *.fasta *.fastq*
seqkit grep -s -p "ATGCGT" genome.fasta | grep -c "^>"
seqkit grep -p "chr1" genome.fasta
seqkit fx2tab -nl genome.fasta | sort -k2,2n     # séquences triées par longueur
seqkit split -i genome.fasta                     # équivalent propre de l'exercice 9
```

---

## Piège utile à connaître

`grep -c "ATGCGT"` compte les **lignes** contenant le motif, pas les **occurrences**.
Pour compter les occurrences réelles :

```bash
grep -o "ATGCGT" genome.fasta | wc -l
```

Et comme les séquences sont repliées à 60 caractères, un motif à cheval sur deux
lignes est **invisible** pour `grep`. C'est précisément la limite mentionnée dans la
section 8 du guide, et la raison d'être de `seqkit`. Pour t'en convaincre :

```bash
grep -o "ATGCGT" genome.fasta | wc -l
seqkit locate -p "ATGCGT" genome.fasta | wc -l
```
