#!/usr/bin/env bash
# Exécute TELLE QUELLE la solution publiée du projet 1 (extraite du README)
# dans un bac à sable neuf, puis vérifie les livrables.
# (sourcé par tests/run_all.sh)

P1_HOME="$(mktemp -d)"
P1_README="$DEPOT/partie1_linux/projet1_inventaire_run/README.md"

# Le premier bloc ```bash situé après « Afficher la solution »
awk '/Afficher la solution/ { dans = 1 }
     dans && /^```bash/ { code = 1; next }
     code && /^```/ { exit }
     code { print }' "$P1_README" > "$P1_HOME/solution.sh"

echo "-- projet 1 (solution du README)"
verifier "solution extraite non vide" "1" "test -s '$P1_HOME/solution.sh' && echo 1"
HOME="$P1_HOME" bash "$DEPOT/setup.sh" >/dev/null
HOME="$P1_HOME" bash "$P1_HOME/solution.sh" > "$P1_HOME/sortie.txt" 2>&1

R="$P1_HOME/formation_linux/projet1/resultats"
verifier "inventaire : 24 lignes"         "24" "wc -l < '$R/inventaire_run.tsv'"
verifier "inventaire : en-tête"           "echantillon	condition	lecture	reads	bases	pct_N	pct_adaptateur" "head -n 1 '$R/inventaire_run.tsv'"
verifier "inventaire : ligne P09 R1"      "P09	traite	R1	150	15000	94.7	14.0" "grep -P '^P09\ttraite\tR1' '$R/inventaire_run.tsv'"
verifier "inventaire : P11 R2 absent"     "0" "grep -c -P '^P11\t.*\tR2\t' '$R/inventaire_run.tsv'"
verifier "inventaire : P12 présent (2)"   "2" "grep -c '^P12' '$R/inventaire_run.tsv'"
verifier "détection : P09 (2 fichiers)"   "2" "grep -c -P '^P09\ttraite\tR[12]\t150' '$P1_HOME/sortie.txt'"
verifier "détection : P11 R2 absent"      "1" "grep -c '^P11 R2 absent$' '$P1_HOME/sortie.txt'"
verifier "conclusions : 24 reçus, 23 intègres" "Fichiers reçus : 24 ; intègres : 23" "sed -n 2p '$R/conclusions.txt'"
verifier "controle_md5 : avertissement inclus" "1" "grep -c WARNING '$R/controle_md5.txt'"
verifier "dossier travail supprimé"       "non" "test -d '$P1_HOME/formation_linux/projet1/travail' && echo oui || echo non"
verifier "données brutes intactes"        "1" "cd '$P1_HOME/formation_linux/run_sequencage/fastq' && md5sum -c MD5SUMS.txt 2>/dev/null | grep -c FAILED"
verifier "moyenne R1 hors P09/P11"        "temoin 305 traite 305" \
    "awk -F '\t' 'NR > 1 && \$3 == \"R1\" && \$1 != \"P09\" && \$1 != \"P11\" { s[\$2] += \$4; n[\$2]++ } END { for (c in s) printf \"%s %.0f\n\", c, s[c] / n[c] }' '$R/inventaire_run.tsv' | sort | tr '\n' ' ' | sed 's/ \$//'"
verifier "gunzip sans exclusion : 21 fichiers" "21" \
    "d=\$(mktemp -d); cp '$P1_HOME'/formation_linux/run_sequencage/fastq/*.fastq.gz \"\$d\"/; gunzip \"\$d\"/*.fastq.gz 2>/dev/null; ls \"\$d\"/*.fastq | wc -l; rm -r \"\$d\""

rm -rf "$P1_HOME"
