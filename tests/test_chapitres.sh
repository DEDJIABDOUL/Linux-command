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

rm -rf "$(dirname "$BAC")"
