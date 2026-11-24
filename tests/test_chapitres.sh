#!/usr/bin/env bash
# Vérifie les sorties montrées dans les chapitres de partie1_linux/,
# exécutées dans un bac à sable neuf (comme le ferait un étudiant).
# (sourcé par tests/run_all.sh)

BAC="$(mktemp -d)/formation_linux"
bash "$DEPOT/setup.sh" --dossier "$BAC" >/dev/null

echo "-- chapitre 01"
verifier "head -n 3 genome.fasta (3e ligne)" ">seq_exercice_02 organism=synthetic type=demo length=49" \
    "cd '$BAC' && head -n 3 genome.fasta | tail -1"
verifier "--lines=3 identique à -n 3"   "0" \
    "cd '$BAC' && diff <(head -n 3 genome.fasta) <(head --lines=3 genome.fasta) | wc -l"
verifier "head -n 1 sur deux fichiers"  "==> proteins.fasta <==" \
    "cd '$BAC' && head -n 1 genome.fasta proteins.fasta | sed -n 4p"
verifier "echo sans guillemets"         "Bonjour le monde" "echo Bonjour   le   monde"
verifier "wc -l reads.fastq"            "2000 reads.fastq" "cd '$BAC' && wc -l reads.fastq"
verifier "complétion : 'trans' est unique" "1" "cd '$BAC' && ls -d trans* | wc -l"
verifier "complétion : 3 fichiers en 'sa'" "3" "cd '$BAC' && ls -d sa* | wc -l"
verifier "nom avec espaces : 3 erreurs"  "3" \
    "cd '$BAC' && head pieges/mes resultats finaux.txt 2>&1 | grep -c 'No such file'"
verifier "head -c 100 : pas de saut final" "G" \
    "cd '$BAC' && head -c 100 genome.fasta | tail -c 1"
verifier "head sur un dossier"          "head: error reading 'run_sequencage': Is a directory" \
    "cd '$BAC' && head run_sequencage"

echo "-- chapitre 02"
verifier "ls -a run_sequencage : fichier caché" ".run_termine" "ls -A '$BAC/run_sequencage' | head -1"
verifier "25 fichiers dans fastq/"      "25" "ls '$BAC/run_sequencage/fastq' | wc -l"
verifier "plus gros fichier du run"     "P03_S3_L001_R1_001.fastq.gz" "ls -S '$BAC/run_sequencage/fastq' | head -1"
verifier "les 4 plus petits"            "P11_S11_L001_R2_001.fastq.gz P09_S9_L001_R2_001.fastq.gz P09_S9_L001_R1_001.fastq.gz MD5SUMS.txt" \
    "ls -S '$BAC/run_sequencage/fastq' | tail -4 | tr '\n' ' ' | sed 's/ \$//'"
verifier "ls -S formats : alignements en tête" "alignements.sam" "ls -S '$BAC/formats' | head -1"
verifier "chemin ../../formats depuis fastq" "chrA	150	1050	gyrA	0	+" \
    "cd '$BAC/run_sequencage/fastq' && head -n 1 ../../formats/genes.bed"
verifier "fichier leurre : LISEZMOI"    "Run de test de mars 2025 : NE PAS utiliser pour l'analyse." \
    "head '$BAC/run_sequencage/archives/2025-03_run_test/LISEZMOI.txt'"

echo "-- chapitre 03"
verifier "accolades imbriquées (ex. 1)" "8" \
    "cd \"\$(mktemp -d)\" && mkdir -p projet_amr/{data/{raw,metadata},scripts,results/{qc,variants}} && find projet_amr -type d | wc -l"
verifier "joker témoins P0[1-6] R1"     "6" "cd '$BAC' && ls run_sequencage/fastq/P0[1-6]_*_R1_* | wc -l"
verifier "jokers traités (ex. 3)"       "12" "cd '$BAC' && ls run_sequencage/fastq/P0[7-9]_*.fastq.gz run_sequencage/fastq/P1[0-2]_*.fastq.gz | wc -l"
verifier "accolades P{08,10,12} R1"     "3" "cd '$BAC' && ls run_sequencage/fastq/P{08,10,12}_*_R1_001.fastq.gz | wc -l"
verifier "find P07 : 3 fichiers"        "3" "cd '$BAC' && find run_sequencage -name 'P07*' | wc -l"
verifier "find .fastq.gz > 100k : 2"    "2" "cd '$BAC' && find . -name '*.fastq.gz' -size +100k | wc -l"
verifier "find -iname lisez"            "./run_sequencage/archives/2025-03_run_test/LISEZMOI.txt" "cd '$BAC' && find . -iname '*lisez*'"

echo "-- chapitre 04"
verifier "wc -l des trois FASTA"        "739 total" "cd '$BAC' && wc -l genome.fasta transcripts.fasta proteins.fasta | tail -1 | sed 's/^ *//'"
verifier "run_info : 310 octets"        "310" "wc -c < '$BAC/run_sequencage/rapports/run_info.txt'"
verifier "run_info : 304 caractères"    "304" "LC_ALL=C.UTF-8 wc -m < '$BAC/run_sequencage/rapports/run_info.txt'"
verifier "SAM : 5 lignes d'en-tête"     "5" "grep -c '^@' '$BAC/formats/alignements.sam'"
verifier "SAM : 855 lignes"             "855" "wc -l < '$BAC/formats/alignements.sam'"
verifier "1er read : adaptateur présent" "1" "sed -n 2p '$BAC/reads.fastq' | grep -c AGATCGGAAGAGC"
verifier "2e read : pas d'adaptateur"   "0" "sed -n 6p '$BAC/reads.fastq' | grep -c AGATCGGAAGAGC"
verifier "fastq_tronque : 163 lignes"   "163" "wc -l < '$BAC/pieges/fastq_tronque.fastq'"
verifier "wc -l absurde sur sample_01.gz" "404" "wc -l < '$BAC/sample_01.fastq.gz'"
verifier "genome = exercice_sequences (md5)" "1" "cd '$BAC' && md5sum genome.fasta exercice_sequences.fasta | cut -d' ' -f1 | sort -u | wc -l"
verifier "md5sum -c : seul P11 R2 échoue" "P11_S11_L001_R2_001.fastq.gz: FAILED" \
    "cd '$BAC/run_sequencage/fastq' && md5sum -c MD5SUMS.txt 2>/dev/null | grep -v ': OK\$'"
verifier "gzip -t : P11 R2 tronqué"     "1" "gzip -t '$BAC/run_sequencage/fastq/P11_S11_L001_R2_001.fastq.gz' 2>/dev/null; echo \$?"
verifier "gzip -t : sample_02 intact"   "0" "gzip -t '$BAC/sample_02.fastq.gz'; echo \$?"
verifier "sample_02 : 3200 lignes"      "3200" "zcat '$BAC/sample_02.fastq.gz' | wc -l"
verifier "R1/R2 : même identifiant"     "@M07112:58:000000000-KX4LT:1:1101:1037:1511" \
    "zcat '$BAC/run_sequencage/fastq/P07_S7_L001_R2_001.fastq.gz' | head -1 | cut -d' ' -f1"
verifier "cat -A : CRLF visible"        "P01^I52.3^M\$" "sed -n 2p '$BAC/pieges/mesures_windows.tsv' | cat -A"

echo "-- chapitre 05"
verifier "ls | wc -l : 25"                "25" "ls '$BAC/run_sequencage/fastq' | wc -l"
verifier "P07 R1 : 1160 lignes"           "1160" "zcat '$BAC/run_sequencage/fastq/P07_S7_L001_R1_001.fastq.gz' | wc -l"
verifier "P07 R1 : 290 reads"             "290" "echo \$(( \$(zcat '$BAC/run_sequencage/fastq/P07_S7_L001_R1_001.fastq.gz' | wc -l) / 4 ))"
verifier "P01 R1 : 300 reads"             "300" "echo \$(( \$(zcat '$BAC/run_sequencage/fastq/P01_S1_L001_R1_001.fastq.gz' | wc -l) / 4 ))"
verifier "P11 R2 tronqué : 691 lignes"    "691" "zcat '$BAC/run_sequencage/fastq/P11_S11_L001_R2_001.fastq.gz' 2>/dev/null | wc -l"
verifier "P11 R1 : 1200 lignes"           "1200" "zcat '$BAC/run_sequencage/fastq/P11_S11_L001_R1_001.fastq.gz' | wc -l"
verifier "cat genome+proteins : 522"      "522" "cat '$BAC/genome.fasta' '$BAC/proteins.fasta' | wc -l"
verifier "transcripts+proteins : 320"     "320" "cat '$BAC/transcripts.fasta' '$BAC/proteins.fasta' | wc -l"
verifier "head > même fichier : vide"     "0" "d=\$(mktemp -d); cp '$BAC/run_sequencage/echantillons.tsv' \"\$d/c.tsv\"; head -n 3 \"\$d/c.tsv\" > \"\$d/c.tsv\"; wc -l < \"\$d/c.tsv\"; rm -r \"\$d\""
verifier "md5sum -c : 24 lignes de résultat" "24" "cd '$BAC/run_sequencage/fastq' && md5sum -c MD5SUMS.txt 2>/dev/null | wc -l"
verifier "sample_01+02 : 2000 reads"      "2000" "echo \$(( \$(zcat '$BAC/sample_01.fastq.gz' '$BAC/sample_02.fastq.gz' | wc -l) / 4 ))"
verifier "gzip -t && || : CORROMPU"       "CORROMPU" "gzip -t '$BAC/run_sequencage/fastq/P11_S11_L001_R2_001.fastq.gz' 2>/dev/null && echo intact || echo CORROMPU"

echo "-- chapitre 06"
verifier "grep -c ^> sur 3 FASTA"         "genome.fasta:22 transcripts.fasta:40 proteins.fasta:25" "cd '$BAC' && grep -c '^>' genome.fasta transcripts.fasta proteins.fasta | tr '\n' ' ' | sed 's/ \$//'"
verifier "motif coupé : 1 / 2 / 3"        "1 2 3" "cd '$BAC' && echo \$(grep -c ATGCGT pieges/motif_coupe.fasta) \$(grep -o ATGCGT pieges/motif_coupe.fasta | wc -l) \$(grep -v '^>' pieges/motif_coupe.fasta | tr -d '\n' | grep -o ATGCGT | wc -l)"
verifier "VCF : 14 variants, 9 PASS"      "14 9" "cd '$BAC' && echo \$(grep -vc '^#' formats/variants.vcf) \$(grep -v '^#' formats/variants.vcf | grep -wc PASS)"
verifier "VCF : 5 LowQual (6 avec en-tête)" "5 6" "cd '$BAC' && echo \$(grep -v '^#' formats/variants.vcf | grep -wc LowQual) \$(grep LowQual formats/variants.vcf | wc -l)"
verifier "EcoRI absent : code 1"          "1" "grep -q GAATTC '$BAC/formats/reference.fasta'; echo \$?"
verifier "BamHI : 5 sites"                "5" "grep -o GGATCC '$BAC/formats/reference.fasta' | wc -l"
verifier "lignes ACGT pures : 371"        "371" "grep -c -E '^[ACGT]+\$' '$BAC/genome.fasta'"
verifier "lignes avec minuscules : 41"    "41" "grep -c '[acgt]' '$BAC/genome.fasta'"
verifier "piège N : 292 lignes"           "292" "zcat '$BAC/run_sequencage/fastq/P09_S9_L001_R1_001.fastq.gz' | grep -c N"
verifier "P09 : 142 reads avec N"         "142" "zcat '$BAC/run_sequencage/fastq/P09_S9_L001_R1_001.fastq.gz' | paste - - - - | cut -f 2 | grep -c N"
verifier "P01 : 25 reads avec N"          "25" "zcat '$BAC/run_sequencage/fastq/P01_S1_L001_R1_001.fastq.gz' | paste - - - - | cut -f 2 | grep -c N"
verifier "P09 : 21 reads avec adaptateur" "21" "zcat '$BAC/run_sequencage/fastq/P09_S9_L001_R1_001.fastq.gz' | paste - - - - | cut -f 2 | grep -c AGATCGGAAGAGC"
verifier "P01 : 15 reads avec adaptateur" "15" "zcat '$BAC/run_sequencage/fastq/P01_S1_L001_R1_001.fastq.gz' | paste - - - - | cut -f 2 | grep -c AGATCGGAAGAGC"
verifier "conditions : 6 / 6"             "6 temoin 6 traite" "cut -f 3 '$BAC/run_sequencage/echantillons.tsv' | tail -n +2 | sort | uniq -c | sed 's/^ *//' | tr '\n' ' ' | sed 's/ \$//'"
verifier "features : repeat en tête (25)" "25 repeat" "cut -f 5 '$BAC/annotations.tsv' | tail -n +2 | sort | uniq -c | sort -rn | head -n 1 | sed 's/^ *//'"
verifier "annotations par brin"           "66 + 54 -" "cut -f 4 '$BAC/annotations.tsv' | tail -n +2 | sort | uniq -c | sed 's/^ *//' | tr '\n' ' ' | sed 's/ \$//'"
verifier "top gène : gyrA (21)"           "21 gyrA" "cut -f 6 '$BAC/annotations.tsv' | tail -n +2 | sort | uniq -c | sort -rn | head -n 1 | sed 's/^ *//'"
verifier "reverse complement adaptateur"  "GCTCTTCCGATCT" "echo AGATCGGAAGAGC | rev | tr ACGT TGCA"
verifier "tr -d CR : plus de CRLF"        "ASCII text" "tr -d '\r' < '$BAC/pieges/mesures_windows.tsv' | file -b -"
verifier "défi organismes (comptes)"      "8 8 4 2" "grep '^>' '$BAC/genome.fasta' | cut -d ' ' -f 2 | cut -d '=' -f 2 | sort | uniq -c | sort -rn | awk '{ print \$1 }' | tr '\n' ' ' | sed 's/ \$//'"

echo "-- chapitre 07"
verifier "longueur totale des gènes"      "Longueur totale : 5871 pb ; moyenne : 838.714 pb" "awk '{ total += \$3 - \$2 } END { print \"Longueur totale :\", total, \"pb ; moyenne :\", total / NR, \"pb\" }' '$BAC/formats/genes.bed'"
verifier "gènes > 800 pb"                 "gyrA rpoB ompC blaTEM" "awk '\$3 - \$2 > 800 { print \$4 }' '$BAC/formats/genes.bed' | tr '\n' ' ' | sed 's/ \$//'"
verifier "variants QUAL >= 30 : 9"        "9" "awk -F '\t' '!/^#/ && \$6 >= 30' '$BAC/formats/variants.vcf' | wc -l"
verifier "indels : 2"                     "2" "awk -F '\t' '!/^#/ && length(\$4) != length(\$5)' '$BAC/formats/variants.vcf' | wc -l"
verifier "GC chrA / chrP"                 "chrA 6000 49.6|chrP 2400 48.2" "awk '/^>/ { if (id) printf \"%s %d %.1f\n\", id, len, 100 * gc / len; id = substr(\$1, 2); len = 0; gc = 0; next } { len += length(\$0); gc += gsub(/[GCgc]/, \"\") } END { printf \"%s %d %.1f\n\", id, len, 100 * gc / len }' '$BAC/formats/reference.fasta' | tr '\n' '|' | sed 's/|\$//'"
verifier "reads.fastq : moyenne 99.2 pb"  "500 reads, longueur moyenne 99.2 pb" "awk 'NR % 4 == 2 { n++; s += length(\$0) } END { printf \"%d reads, longueur moyenne %.1f pb\n\", n, s / n }' '$BAC/reads.fastq'"
verifier "P09 : 94.7 % avec N"            "142/150 reads avec N (94.7 %)" "zcat '$BAC/run_sequencage/fastq/P09_S9_L001_R1_001.fastq.gz' | awk 'NR % 4 == 2 { n++; if (\$0 ~ /N/) a++ } END { printf \"%d/%d reads avec N (%.1f %%)\n\", a, n, 100 * a / n }'"
verifier "P01 : rapport adaptateur (ex. 3)" "300 reads, 30000 bases, 5.0 % avec adaptateur" "zcat '$BAC/run_sequencage/fastq/P01_S1_L001_R1_001.fastq.gz' | awk 'NR % 4 == 2 { n++; b += length(\$0); if (\$0 ~ /AGATCGGAAGAGC/) a++ } END { printf \"%d reads, %d bases, %.1f %% avec adaptateur\n\", n, b, 100 * a / n }'"
verifier "GFF -> BED identique (ex. 4)"   "IDENTIQUES" "awk -F '\t' 'BEGIN { OFS = \"\t\" } \$3 == \"gene\" { split(\$9, a, \";\"); sub(\"Name=\", \"\", a[2]); print \$1, \$4 - 1, \$5, a[2], 0, \$7 }' '$BAC/formats/annotation.gff3' | diff - '$BAC/formats/genes.bed' && echo IDENTIQUES"
verifier "top 3 longueurs (ex. 2)"        "chr1 4800|chr2 3600|chr3 2880" "awk '/^>/ { if (id) print id, len; id = substr(\$1, 2); len = 0; next } { len += length(\$0) } END { print id, len }' '$BAC/genome.fasta' | sort -k 2,2nr | head -n 3 | tr '\n' '|' | sed 's/|\$//'"
verifier "sed en-têtes courts (ex. 5)"    "22 419" "sed -E 's/^>([^ ]+) .*/>\1/' '$BAC/genome.fasta' | awk '/^>/ { h++ } END { print h, NR }'"
verifier "NR==FNR : annotation"           "P01	300	temoin|P09	150	traite" "awk -F '\t' 'NR == FNR { c[\$1] = \$3; next } { print \$0 \"\t\" c[\$1] }' '$BAC/run_sequencage/echantillons.tsv' <(printf 'P01\t300\nP09\t150\n') | tr '\n' '|' | sed 's/|\$//'"
verifier "défi tableau de bord"           "chrA	6000	49.6	5|chrP	2400	48.2	2" "awk '/^>/ { if (id) printf \"%s\t%d\t%.1f\n\", id, len, 100 * gc / len; id = substr(\$1, 2); len = 0; gc = 0; next } { len += length(\$0); gc += gsub(/[GCgc]/, \"\") } END { printf \"%s\t%d\t%.1f\n\", id, len, 100 * gc / len }' '$BAC/formats/reference.fasta' | awk -F '\t' 'NR == FNR { g[\$1]++; next } { print \$0 \"\t\" g[\$1] }' '$BAC/formats/genes.bed' - | tr '\n' '|' | sed 's/|\$//'"
verifier "piège en-tête comparé en texte" "3" "awk -F '\t' '\$2 > 50' '$BAC/pieges/mesures_windows.tsv' | wc -l"

rm -rf "$(dirname "$BAC")"
