#!/usr/bin/env bash
# Chapitres 08 à 17 : sorties annoncées et solutions publiées (extraites des README).
# (sourcé par tests/run_all.sh)

# extraire_bloc FICHIER "motif de ligne" : le 1er bloc ```bash qui suit la ligne
extraire_bloc() {
    awk -v m="$2" 'index($0, m) { dans = 1 }
                   dans && /^```bash/ { code = 1; next }
                   code && /^```/ { exit }
                   code { print }' "$1"
}

C2_HOME="$(mktemp -d)"
HOME="$C2_HOME" bash "$DEPOT/setup.sh" >/dev/null
B="$C2_HOME/formation_linux"
P1="$DEPOT/partie1_linux"

echo "-- chapitre 08"
verifier "umask 022 : fichier en 644"     "644" "cd '$C2_HOME' && umask 022 && touch f && stat -c %a f"
verifier "données protégées : rm refusé"  "1" "d=\$(mktemp -d); mkdir \"\$d/raw\"; touch \"\$d/raw/a.fastq.gz\"; chmod -R a-w \"\$d/raw\"; rm -f \"\$d/raw/a.fastq.gz\" 2>/dev/null; ls \"\$d/raw\" | wc -l; chmod -R u+w \"\$d\"; rm -rf \"\$d\""
verifier "script sans x : code 126"       "126" "d=\$(mktemp -d); printf '#!/bin/bash\necho ok\n' > \"\$d/s.sh\"; \"\$d/s.sh\" 2>/dev/null; echo \$?; rm -rf \"\$d\""
verifier "défi : X ne rend pas les fichiers exécutables" "-r--r----- dr-xr-x---" "d=\$(mktemp -d); mkdir -p \"\$d/raw\"; touch \"\$d/raw/f\"; chmod -R u=rX,g=rX,o= \"\$d/raw\"; echo \$(stat -c %A \"\$d/raw/f\") \$(stat -c %A \"\$d/raw\"); chmod -R u+w \"\$d\"; rm -rf \"\$d\""

echo "-- chapitre 09"
verifier "défi : les 5 plus gros fichiers (1er)" "alignements.sam" "cd '$B' && find . -type f -exec du -b {} + | sort -n | tail -n 1 | cut -f 2 | xargs basename"

echo "-- chapitre 10"
verifier "\${f%.fastq.gz}"                "P07_S7_L001_R1_001" "f=P07_S7_L001_R1_001.fastq.gz; echo \"\${f%.fastq.gz}\""
verifier "\${f%%_*} et \${f/R1/R2}"       "P07 P07_S7_L001_R2_001.fastq.gz" "f=P07_S7_L001_R1_001.fastq.gz; echo \"\${f%%_*}\" \"\${f/R1/R2}\""
verifier "\"\$e_R1\" vide, \"\${e}_R1\""  "[] [P07_R1]" "e=P07; echo \"[\$e_R1] [\${e}_R1]\""
verifier "export vers un sous-shell"      "[] [rouge]" "couleur=rouge; a=\$(bash -c 'echo \"[\$couleur]\"'); export couleur; b=\$(bash -c 'echo \"[\$couleur]\"'); echo \"\$a \$b\""
verifier "awk -v seuil 800"               "gyrA rpoB ompC blaTEM" "seuil=800; awk -v s=\"\$seuil\" '\$3 - \$2 > s { print \$4 }' '$B/formats/genes.bed' | paste -sd ' '"
verifier "ex. 1 : P09 en variable"        "P09 : 150 reads" "cd '$B' && ech=P09; r1=\$(ls run_sequencage/fastq/\${ech}_*_R1_001.fastq.gz); echo \"\${ech} : \$(( \$(zcat \"\$r1\" | wc -l) / 4 )) reads\""

echo "-- chapitre 12"
verifier "compte_run : 13 lignes, P09 150" "13 150" "cd '$B' && t=\$(mktemp); printf 'printf \"echantillon\\\\treads_R1\\\\n\"\nfor f in run_sequencage/fastq/*_R1_001.fastq.gz; do nom=\$(basename \"\$f\"); ech=\${nom%%%%_*}; printf \"%%s\\\\t%%d\\\\n\" \"\$ech\" \"\$(( \$(zcat \"\$f\" | wc -l) / 4 ))\"; done\n' > \"\$t\"; bash \"\$t\" > \"\$t.out\"; echo \$(wc -l < \"\$t.out\") \$(awk '\$1==\"P09\"{print \$2}' \"\$t.out\"); rm -f \"\$t\" \"\$t.out\""
verifier "while read sans pipe : 12"      "12" "cd '$B' && c=0; while read -r l; do c=\$((c+1)); done < <(tail -n +2 run_sequencage/echantillons.tsv); echo \$c"
verifier "while read après pipe : 0"      "0" "cd '$B' && c=0; tail -n +2 run_sequencage/echantillons.tsv | while read -r l; do c=\$((c+1)); done; echo \$c"
extraire_bloc "$P1/12_scripts_bash_1/README.md" "## 12. Défi" > "$C2_HOME/inventaire.sh"
verifier "défi 12 : inventaire 24 lignes" "24" "cd '$B' && bash '$C2_HOME/inventaire.sh' >/dev/null 2>&1; wc -l < resultats_inventaire/inventaire.tsv"
verifier "défi 12 : P11 R2 signalé"       "ATTENTION : P11_S11_L001_R2_001.fastq.gz corrompu, non compté" "cd '$B' && bash '$C2_HOME/inventaire.sh' 2>&1 >/dev/null"

echo "-- chapitre 13"
verifier "pipefail : code 1 sur P11 R2"   "1" "cd '$B' && bash -c 'set -eo pipefail; n=\$(zcat run_sequencage/fastq/P11_S11_L001_R2_001.fastq.gz | wc -l)' 2>/dev/null; echo \$?"
verifier "sans pipefail : code 0"         "0" "cd '$B' && bash -c 'set -e; n=\$(zcat run_sequencage/fastq/P11_S11_L001_R2_001.fastq.gz | wc -l)' 2>/dev/null; echo \$?"
verifier "grep sans résultat + set -e"    "1" "cd '$B' && bash -c 'set -euo pipefail; n=\$(grep -c GAATTC formats/reference.fasta); echo \$n'; echo \$?"
verifier "script cassé : bash\\r"         "1" "cd '$B/pieges' && cp script_casse.sh /tmp/c_\$\$.sh && chmod u+x /tmp/c_\$\$.sh && /tmp/c_\$\$.sh 2>&1 | grep -c \"bash.r\"; rm -f /tmp/c_\$\$.sh"
extraire_bloc "$P1/13_scripts_bash_2/README.md" "**La version réparée**" > "$C2_HOME/repare.sh"
verifier "repare.sh : 12 lignes"          "12" "cd '$B' && rm -f comptes.txt && bash '$C2_HOME/repare.sh' run_sequencage/fastq comptes.txt && wc -l < comptes.txt"
extraire_bloc "$P1/13_scripts_bash_2/README.md" "## 13. Défi" > "$C2_HOME/stats_sures.sh"
if besoin seqkit; then
    verifier "défi 13 : 23 fichiers valides" "24" "cd '$B' && bash '$C2_HOME/stats_sures.sh' --entree run_sequencage/fastq 2>/dev/null; wc -l < stats.tsv"
    verifier "défi 13 : dossier vide → code 1" "1" "cd '$B' && mkdir -p vide && bash '$C2_HOME/stats_sures.sh' --entree vide 2>/dev/null; echo \$?"
fi
if besoin shellcheck; then
    verifier "shellcheck : repare.sh et stats_sures.sh" "" "shellcheck '$C2_HOME/repare.sh' '$C2_HOME/stats_sures.sh'"
fi

echo "-- chapitre 17"
mkdir -p "$C2_HOME/bin"
extraire_bloc "$P1/17_organiser_projet/README.md" "### Exercice 1" > "$C2_HOME/bin/nouveau_projet.sh"
verifier "nouveau_projet : arborescence"  "README.md data/ envs/ logs/ results/ scripts/" \
    "cd '$B' && HOME='$C2_HOME' GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t bash '$C2_HOME/bin/nouveau_projet.sh' p_test >/dev/null && ls -F p_test | paste -sd ' '"
verifier "nouveau_projet : refuse d'écraser" "1" "cd '$B' && HOME='$C2_HOME' bash '$C2_HOME/bin/nouveau_projet.sh' p_test >/dev/null 2>&1; echo \$?"
verifier "nouveau_projet : 1 commit"      "1" "git -C '$B/p_test' rev-list --count HEAD"

rm -rf "$C2_HOME"
