#!/usr/bin/env bash
# Vérifie les résultats annoncés dans les leçons pour le dossier data/.
# (sourcé par tests/run_all.sh : DEPOT et verifier sont déjà définis)

L="$DEPOT/data"

echo "-- jeu de données historique (modules 02/03, data/README.md)"
verifier "genome.fasta : 22 séquences"      "22"    "grep -c '^>' '$L/genome.fasta'"
verifier "transcripts.fasta : 40"           "40"    "grep -c '^>' '$L/transcripts.fasta'"
verifier "proteins.fasta : 25"              "25"    "grep -c '^>' '$L/proteins.fasta'"
verifier "genome.fasta : 419 lignes"        "419"   "wc -l < '$L/genome.fasta'"
verifier "genome.fasta : 23718 bases"       "23718" "grep -v '^>' '$L/genome.fasta' | tr -d '\n' | wc -c"
verifier "reads.fastq : 500 reads"          "500"   "echo \$(( \$(wc -l < '$L/reads.fastq') / 4 ))"
verifier "sample_01 : 1200 reads"           "1200"  "echo \$(( \$(zcat '$L/sample_01.fastq.gz' | wc -l) / 4 ))"
verifier "sample_02 : 800 reads"            "800"   "echo \$(( \$(zcat '$L/sample_02.fastq.gz' | wc -l) / 4 ))"
verifier "sample_03 : 1500 reads"           "1500"  "echo \$(( \$(zcat '$L/sample_03.fastq.gz' | wc -l) / 4 ))"
verifier "reads avec adaptateur : 56"       "56"    "awk 'NR%4==2' '$L/reads.fastq' | grep -c AGATCGGAAGAGC"
verifier "lignes avec ATGCGT : 29"          "29"    "grep -c ATGCGT '$L/genome.fasta'"
verifier "idem avec -i : 31"                "31"    "grep -ic ATGCGT '$L/genome.fasta'"
verifier "reads de 100 pb : 445 sur 500"    "445"   "awk 'NR%4==2 && length(\$0)==100' '$L/reads.fastq' | wc -l"
verifier "annotations.tsv : 121 lignes"     "121"   "wc -l < '$L/annotations.tsv'"

echo "-- run de séquençage simulé (data/run_sequencage)"
R="$L/run_sequencage"
verifier "24 fichiers FASTQ (12 paires)"    "24"    "ls '$R'/fastq/*.fastq.gz | wc -l"
verifier "feuille : 12 échantillons"        "12"    "tail -n +2 '$R/echantillons.tsv' | wc -l"
verifier "P07 R2 : 290 reads"               "290"   "echo \$(( \$(zcat '$R/fastq/P07_S7_L001_R2_001.fastq.gz' | wc -l) / 4 ))"
verifier "P09 : 150 reads"                  "150"   "echo \$(( \$(zcat '$R/fastq/P09_S9_L001_R1_001.fastq.gz' | wc -l) / 4 ))"
verifier "R1 et R2 ont les mêmes noms"      "0"     "diff <(zcat '$R/fastq/P01_S1_L001_R1_001.fastq.gz' | awk 'NR%4==1{print \$1}') <(zcat '$R/fastq/P01_S1_L001_R2_001.fastq.gz' | awk 'NR%4==1{print \$1}') | wc -l"
verifier "fichier caché .run_termine"       "1"     "ls -A '$R' | grep -c '^.run_termine$'"

echo "-- fichiers pièges (data/pieges)"
P="$L/pieges"
verifier "FASTQ tronqué : lignes % 4 = 3"   "3"     "echo \$(( \$(wc -l < '$P/fastq_tronque.fastq') % 4 ))"
verifier "motif : 1 ligne"                  "1"     "grep -c ATGCGT '$P/motif_coupe.fasta'"
verifier "motif : 2 occurrences visibles"   "2"     "grep -v '^>' '$P/motif_coupe.fasta' | grep -o ATGCGT | wc -l"
verifier "motif : 3 occurrences réelles"    "3"     "grep -v '^>' '$P/motif_coupe.fasta' | tr -d '\n' | grep -o ATGCGT | wc -l"
verifier "mesures_windows.tsv est en CRLF"  "4"     "grep -c \$'\r' '$P/mesures_windows.tsv'"
verifier "script_casse.sh est en CRLF"      "11"    "grep -c \$'\r' '$P/script_casse.sh'"

echo "-- formats biologiques (data/formats)"
F="$L/formats"
verifier "référence : 2 séquences"          "2"     "grep -c '^>' '$F/reference.fasta'"
verifier "BED : 7 gènes"                    "7"     "wc -l < '$F/genes.bed'"
verifier "GFF3 : 7 gènes"                   "7"     "awk -F'\t' '\$3==\"gene\"' '$F/annotation.gff3' | wc -l"
verifier "BED = GFF - 1 (début)"            "0"     "diff <(awk -F'\t' '\$3==\"gene\"{print \$1, \$4-1, \$5}' '$F/annotation.gff3') <(awk '{print \$1, \$2, \$3}' '$F/genes.bed') | wc -l"
verifier "VCF : 14 variants"                "14"    "grep -vc '^#' '$F/variants.vcf'"
verifier "SAM : 850 lectures"               "850"   "grep -vc '^@' '$F/alignements.sam'"
verifier "SAM : 30 non alignées (FLAG 4)"   "30"    "awk '!/^@/ && \$2==4' '$F/alignements.sam' | wc -l"

if besoin samtools; then
    verifier "samtools accepte le SAM"      "ok"    "samtools quickcheck '$F/alignements.sam' && echo ok"
fi
if besoin bcftools; then
    verifier "REF du VCF = référence"       "ok"    "bcftools norm --check-ref e -f '$F/reference.fasta' '$F/variants.vcf' -Ou -o /dev/null 2>/dev/null && echo ok"
    rm -f "$F/reference.fasta.fai"
fi
if besoin bedtools; then
    verifier "11 variants dans des gènes"   "11"    "bedtools intersect -u -a '$F/variants.vcf' -b '$F/genes.bed' | wc -l"
    verifier "gènes : ATG en tête"          "7"     "bedtools getfasta -s -fi '$F/reference.fasta' -bed '$F/genes.bed' | grep -v '^>' | grep -c '^ATG'"
    rm -f "$F/reference.fasta.fai"
fi
if besoin seqkit; then
    verifier "seqkit : 3 ATGCGT réels"      "3"     "seqkit locate -p ATGCGT '$P/motif_coupe.fasta' | tail -n +2 | wc -l"
fi
