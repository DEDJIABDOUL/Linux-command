#!/usr/bin/env bash
# Exécute la recette du projet 2 avec la solution publiée dans le README.
# (sourcé par tests/run_all.sh)

P2_HOME="$(mktemp -d)"
P2_README="$DEPOT/partie1_linux/projet2_pipeline_bash/README.md"
awk '/Afficher la solution/ { dans = 1 }
     dans && /^```bash/ { code = 1; next }
     code && /^```/ { exit }
     code { print }' "$P2_README" > "$P2_HOME/qc_run.sh"
HOME="$P2_HOME" bash "$DEPOT/setup.sh" >/dev/null
B="$P2_HOME/formation_linux"
QC="bash '$P2_HOME/qc_run.sh' --run '$B/run_sequencage/fastq' --feuille '$B/run_sequencage/echantillons.tsv'"

echo "-- projet 2 (recette de la solution du README)"
verifier "solution extraite"              "1" "grep -c '^set -euo pipefail' '$P2_HOME/qc_run.sh'"
if besoin shellcheck; then
    verifier "shellcheck : aucun avertissement" "" "shellcheck '$P2_HOME/qc_run.sh'"
fi
verifier "sans option : code 1"           "1" "bash '$P2_HOME/qc_run.sh' >/dev/null 2>&1; echo \$?"
verifier "dossier absent : message"       "Erreur : dossier introuvable : nulle_part" "bash '$P2_HOME/qc_run.sh' --run nulle_part --feuille '$B/run_sequencage/echantillons.tsv' --sortie '$P2_HOME/x' 2>&1"
verifier "lancement normal : bilan"       "Fin : 10 échantillon(s) retenu(s) sur 12" "$QC --sortie '$B/qc' 2>&1 | tail -n 1 | cut -c 23-"
verifier "qc_echantillons : 13 lignes"    "13" "wc -l < '$B/qc/qc_echantillons.tsv'"
verifier "P09 : trop peu de reads"        "P09	traite	150	150	94.7	14.0	EXCLU:trop_peu_de_reads" "grep '^P09' '$B/qc/qc_echantillons.tsv'"
verifier "P11 : archive corrompue"        "P11	traite	NA	NA	NA	NA	EXCLU:archive_corrompue" "grep '^P11' '$B/qc/qc_echantillons.tsv'"
verifier "P01 : OK"                       "P01	temoin	300	300	8.3	5.0	OK" "grep '^P01' '$B/qc/qc_echantillons.tsv'"
verifier "qc_fichier P09 (étape 3)"       "150	94.7	14.0" "source <(sed -n '/^qc_fichier()/,/^}/p' '$P2_HOME/qc_run.sh'); ADAPTATEUR=AGATCGGAAGAGC; qc_fichier '$B/run_sequencage/fastq/P09_S9_L001_R1_001.fastq.gz'"
verifier "valides : 11 lignes"            "11" "wc -l < '$B/qc/echantillons_valides.tsv'"
verifier "20 liens valides"               "20" "find '$B/qc/donnees_valides' -type l -exec test -e {} \\; -print | wc -l"
verifier "MD5 journalisé"                 "1" "grep -c 'Sommes MD5 : 1 fichier(s) non conforme(s)' '$B/qc/pipeline.log'"
verifier "relance : journal 15 lignes"    "15 13" "$QC --sortie '$B/qc' >/dev/null 2>&1; echo \$(wc -l < '$B/qc/pipeline.log') \$(wc -l < '$B/qc/qc_echantillons.tsv')"
verifier "--min-reads 320 : 8 exclus"     "8" "$QC --sortie '$B/qc320' --min-reads 320 2>&1 | grep -c EXCLU"
verifier "depuis /tmp : 11 lignes"        "11" "cd /tmp && $QC --sortie '$P2_HOME/qc_ailleurs' >/dev/null 2>&1; wc -l < '$P2_HOME/qc_ailleurs/echantillons_valides.tsv'"
verifier "lien P07 lisible"               "@M07112:58:000000000-KX4LT:1:1101:1037:1511 1:N:0:7" "zcat '$B/qc/donnees_valides/P07_S7_L001_R1_001.fastq.gz' | head -n 1"
verifier "données brutes intactes"        "23 1" "cd '$B/run_sequencage/fastq' && echo \$(md5sum -c MD5SUMS.txt 2>/dev/null | grep -c ': OK\$') \$(md5sum -c MD5SUMS.txt 2>/dev/null | grep -c FAILED)"

rm -rf "$P2_HOME"
