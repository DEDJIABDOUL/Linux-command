#!/usr/bin/env bash
# Squelette de script de pipeline paramétrable et journalisé.
# Combine les patrons enseignés dans 04_bash_scripting/README.md,
# section 5 (arguments nommés, fonctions, exit codes, logging).
#
# Usage :
#   ./scripts/pipeline_template.sh --input DOSSIER --output DOSSIER [--threads N]
#
# Ce script ne fait rien d'utile tel quel : il sert de point de départ à
# copier/adapter pour un vrai pipeline (remplacer le corps de main()).
set -euo pipefail

usage() {
    echo "Usage: $0 --input DOSSIER --output DOSSIER [--threads N]" >&2
    exit 1
}

THREADS=4
while [[ $# -gt 0 ]]; do
    case "$1" in
        --input)   INPUT="$2";   shift 2 ;;
        --output)  OUTPUT="$2";  shift 2 ;;
        --threads) THREADS="$2"; shift 2 ;;
        *) usage ;;
    esac
done

[[ -z "${INPUT:-}"  ]] && usage
[[ -z "${OUTPUT:-}" ]] && usage
[[ -d "$INPUT" ]] || { echo "Erreur : dossier d'entrée introuvable : $INPUT" >&2; exit 1; }

mkdir -p "$OUTPUT" logs
LOG="logs/pipeline_$(date '+%Y%m%d_%H%M%S').log"

log() {
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" | tee -a "$LOG"
}

main() {
    log "Démarrage : entrée=$INPUT sortie=$OUTPUT threads=$THREADS"
    # --- remplacer ce qui suit par les étapes réelles du pipeline ---
    for f in "$INPUT"/*.fastq.gz; do
        [[ -e "$f" ]] || { log "Aucun .fastq.gz trouvé dans $INPUT"; break; }
        log "Traitement de $(basename "$f")"
    done
    log "Terminé."
}

main
