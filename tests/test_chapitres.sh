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

rm -rf "$(dirname "$BAC")"
