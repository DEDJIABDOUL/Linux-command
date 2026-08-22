#!/usr/bin/env bash
# Compte les séquences FASTA et les reads FASTQ.gz du dossier courant.
# Enseigné et expliqué en détail dans 04_bash_scripting/README.md, section 4.
#
# Usage : ./scripts/stats.sh   (à exécuter depuis un dossier contenant des
#          fichiers .fasta et/ou .fastq.gz, par exemple Linux-command/linux/)
set -euo pipefail
shopt -s nullglob

echo "=== FASTA ==="
for f in *.fasta; do
    printf '%s\t%s séquences\n' "$f" "$(grep -c '^>' "$f")"
done

echo "=== FASTQ ==="
for f in *.fastq.gz; do
    printf '%s\t%d reads\n' "$f" "$(( $(zcat "$f" | wc -l) / 4 ))"
done
