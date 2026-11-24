#!/usr/bin/env bash
# Ce script contient VOLONTAIREMENT plusieurs erreurs.
# Objectif : compter les reads de chaque échantillon du run.
set -euo pipefail

DOSSIER=../run_sequencage/fastqs

for f in $DOSSIER/*_R1_001.fastq.gz; do
    n=$(( $(zcat $f | wc -l) / 4 ))
    echo "$f : $n paires de reads" >> $SORTIE
done
