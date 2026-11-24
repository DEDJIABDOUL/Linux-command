#!/usr/bin/env bash
# Petite bibliothèque de tests : chaque résultat annoncé dans le cours est
# vérifié ici. Si une leçon affiche « → 22 », un test doit le confirmer.

NB_OK=0
NB_ECHEC=0
NB_IGNORE=0

# verifier "description" "résultat attendu" commande_shell
verifier() {
    local description="$1" attendu="$2" commande="$3" obtenu
    obtenu="$(bash -o pipefail -c "$commande" 2>&1 | tr -d '\r')" || true
    if [[ "$obtenu" == "$attendu" ]]; then
        NB_OK=$((NB_OK + 1))
        printf '  ok      %s\n' "$description"
    else
        NB_ECHEC=$((NB_ECHEC + 1))
        printf '  ÉCHEC   %s\n          attendu : %s\n          obtenu  : %s\n' \
            "$description" "$attendu" "$obtenu"
    fi
}

# besoin outil : renvoie faux (et compte un test ignoré) si l'outil manque
besoin() {
    if command -v "$1" >/dev/null 2>&1; then
        return 0
    fi
    NB_IGNORE=$((NB_IGNORE + 1))
    printf '  ignoré  (%s absent)\n' "$1"
    return 1
}

bilan() {
    printf '\n%d réussi(s), %d échec(s), %d ignoré(s)\n' "$NB_OK" "$NB_ECHEC" "$NB_IGNORE"
    [[ $NB_ECHEC -eq 0 ]]
}
