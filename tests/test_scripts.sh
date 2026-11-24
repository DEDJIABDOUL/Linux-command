#!/usr/bin/env bash
# Vérifie setup.sh et les scripts du dossier scripts/.
# (sourcé par tests/run_all.sh)

TMP_TEST="$(mktemp -d)"

echo "-- setup.sh"
verifier "création du bac à sable"          "ok" \
    "bash '$DEPOT/setup.sh' --dossier '$TMP_TEST/bac' >/dev/null && test -f '$TMP_TEST/bac/genome.fasta' && echo ok"
verifier "deuxième lancement : rien n'est écrasé" "Le bac à sable existe déjà : $TMP_TEST/bac" \
    "bash '$DEPOT/setup.sh' --dossier '$TMP_TEST/bac' | head -1"
verifier "--reset conserve une sauvegarde"  "1" \
    "touch '$TMP_TEST/bac/mon_travail.txt'; bash '$DEPOT/setup.sh' --dossier '$TMP_TEST/bac' --reset >/dev/null; ls -d '$TMP_TEST'/bac.sauvegarde-*/mon_travail.txt | wc -l"
verifier "--reset refuse un dossier étranger" "1" \
    "mkdir -p '$TMP_TEST/perso'; bash '$DEPOT/setup.sh' --dossier '$TMP_TEST/perso' --reset >/dev/null 2>&1; echo \$?"
verifier "script_casse.sh non exécutable"   "non" \
    "test -x '$TMP_TEST/bac/pieges/script_casse.sh' && echo oui || echo non"

echo "-- scripts/"
verifier "stats.sh sur linux/"              "sample_03.fastq.gz	1500 reads" \
    "cd '$DEPOT/linux' && bash ../scripts/stats.sh | tail -1"
verifier "pipeline_template sans argument → usage" "1" \
    "bash '$DEPOT/scripts/pipeline_template.sh' >/dev/null 2>&1; echo \$?"
for s in "$DEPOT"/setup.sh "$DEPOT"/scripts/*.sh "$DEPOT"/tests/*.sh; do
    verifier "syntaxe : $(basename "$s")"   ""   "bash -n '$s'"
done
if besoin shellcheck; then
    for s in "$DEPOT"/setup.sh "$DEPOT"/scripts/*.sh; do
        verifier "shellcheck : $(basename "$s")" "" "shellcheck '$s'"
    done
fi

rm -rf "$TMP_TEST"
