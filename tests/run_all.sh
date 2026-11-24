#!/usr/bin/env bash
# Lance tous les tests du dépôt.  Usage : bash tests/run_all.sh
# Les tests qui demandent seqkit/samtools/bcftools/bedtools/shellcheck sont
# ignorés si ces outils ne sont pas installés (ils tournent tous en CI).
set -uo pipefail

DEPOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export DEPOT
# shellcheck source=tests/lib.sh
source "$DEPOT/tests/lib.sh"

for fichier in "$DEPOT"/tests/test_*.sh; do
    printf '\n== %s\n' "$(basename "$fichier")"
    # shellcheck disable=SC1090
    source "$fichier"
done

bilan
