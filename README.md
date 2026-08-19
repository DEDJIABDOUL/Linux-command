# Jeu de données d'entraînement — Linux pour la bioinformatique

Ce dossier contient les fichiers nécessaires pour exécuter **toutes** les commandes
du guide `linux_commands_beginner.md`.

## Contenu

| Fichier | Contenu | Sert à pratiquer |
|---|---|---|
| `exercice_sequences.fasta` | 22 séquences  | tout le guide |
| `genome.fasta` | copie identique, nommée comme dans le guide | sections 6, 8, 9, 10, 16 |
| `transcripts.fasta` | 40 ARNm | `find`, `du -sh *.fasta`, boucles |
| `proteins.fasta` | 25 protéines (alphabet acides aminés) | `file`, `grep`, comparaison ADN/protéine |
| `reads.fastq` | 500 reads de 100 pb | section 5.2, 7 |
| `sample_01/02/03.fastq.gz` | 1200 / 800 / 1500 reads compressés | sections 12, 21, 22 |
| `annotations.tsv` | 120 annotations, 6 colonnes | `cut`, `awk`, `sort`, `uniq` |


## Manipulations

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
mkdir -p bioinfo_exercises/{results,scripts}
cp *.fasta *.fastq *.fastq.gz annotations.tsv bioinfo_exercises/
cd bioinfo_exercises && ls -lh *.fasta
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
diff <(grep -n "ATGCGT" genome.fasta) <(grep -in "ATGCGT" genome.fasta)
```

### 6. Colorer et étiqueter (sections 9 et 10)
```bash
grep --color=always -E "ATGCGT|$" genome.fasta | less -R
grep --color=always -E "ATG|TAA|TAG|TGA|$" genome.fasta | less -R
sed '/^>/! s/ATGCGT/[ATGCGT]/g' genome.fasta > results/genome_annotated.fasta
diff <(grep -v "^>" genome.fasta | grep -o "ATGCGT" | wc -l) \
     <(grep -v "^>" results/genome_annotated.fasta | grep -o "\[ATGCGT\]" | wc -l)
```

### 7. FASTQ : compter les reads
```bash
echo $(( $(wc -l < reads.fastq) / 4 ))                    # → 500
echo $(( $(zcat sample_01.fastq.gz | wc -l) / 4 ))        # → 1200
echo $(( $(zcat sample_02.fastq.gz | wc -l) / 4 ))        # → 800
echo $(( $(zcat sample_03.fastq.gz | wc -l) / 4 ))        # → 1500
```
Les reads contiennent volontairement des **adaptateurs Illumina** et des **N**.
`awk 'NR%4==2'` isole la ligne de séquence de chaque read (les headers et les
lignes de qualité contiennent eux aussi des `A`, `C`, `G`, `N`) :
```bash
awk 'NR%4==2' reads.fastq | grep -c "AGATCGGAAGAGC"    # → 56 reads contaminés
awk 'NR%4==2' reads.fastq | grep -c "N"
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
mkdir -p results/split
awk '/^>/ { if (f) close(f); f = "results/split/" substr($1,2) ".fasta" }
     f    { print > f }' genome.fasta
ls results/split | wc -l        # → 22 fichiers
```
Note : `substr($1,2)` et non `substr($0,2)` — sinon le nom de fichier contiendrait
la description entière avec des espaces. Bon réflexe à prendre.
`close(f)` évite de garder tous les fichiers de sortie ouverts simultanément.

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
    printf '%s\t%d reads\n' "$f" "$n"
done
```

### 12. Script complet
```bash
cat > scripts/stats.sh <<'EOF'
#!/bin/bash
shopt -s nullglob
echo "=== FASTA ==="
for f in *.fasta; do
    printf '%s\t%s séquences\n' "$f" "$(grep -c '^>' "$f")"
done
echo "=== FASTQ ==="
for f in *.fastq.gz; do
    printf '%s\t%d reads\n' "$f" "$(( $(zcat "$f" | wc -l) / 4 ))"
done
EOF
chmod +x scripts/stats.sh
./scripts/stats.sh
```

### 13. SeqKit (si installé)
```bash
seqkit stats *.fasta *.fastq*
seqkit grep -s -i -p "ATGCGT" genome.fasta | grep -c "^>"
seqkit grep -p "chr1" genome.fasta
seqkit fx2tab -nli genome.fasta | sort -t$'\t' -k2,2n   # séquences triées par longueur
seqkit split -i genome.fasta                            # équivalent propre de l'exercice 9
```

---

## Piège utile à connaître

`grep -c "ATGCGT"` compte les **lignes** contenant le motif, pas les **occurrences**.
Pour compter les occurrences réelles :

```bash
grep -v "^>" genome.fasta | grep -o "ATGCGT" | wc -l
```

Et comme les séquences sont repliées à 60 caractères, un motif à cheval sur deux
lignes est **invisible** pour `grep`. C'est précisément la limite mentionnée dans la
section 8 du guide, et la raison d'être de `seqkit`. Pour t'en convaincre :

```bash
grep -v "^>" genome.fasta | grep -o "ATGCGT" | wc -l
seqkit locate -P -p "ATGCGT" genome.fasta | tail -n +2 | wc -l
```
