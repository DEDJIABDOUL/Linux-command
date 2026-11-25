#!/usr/bin/env bash
# setup.sh — installe (ou remet à zéro) votre « bac à sable » de formation.
#
# Le bac à sable est une COPIE des données d'exercice (dossier data/ du
# dépôt) dans votre dossier personnel. Vous pouvez y faire toutes les erreurs
# que vous voulez : il se recrée en une commande.
#
# Usage :
#   bash setup.sh                 crée ~/formation_linux (s'il n'existe pas)
#   bash setup.sh --reset         remet le bac à sable à neuf ; l'ancien est
#                                 CONSERVÉ sous le nom ~/formation_linux.sauvegarde-DATE
#   bash setup.sh --dossier CHEMIN  utilise un autre emplacement que ~/formation_linux
#   bash setup.sh --aide          affiche cette aide
#
# Ce script ne supprime jamais rien et n'a pas besoin de sudo.
set -euo pipefail

DEPOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$DEPOT/data"
DESTINATION="$HOME/formation_linux"
MARQUEUR=".bac_a_sable_formation_linux"
RESET=0

aide() { sed -n '2,15p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }
erreur() { echo "ERREUR : $*" >&2; exit 1; }

while [[ $# -gt 0 ]]; do
    case "$1" in
        --reset)   RESET=1; shift ;;
        --dossier) [[ $# -ge 2 ]] || erreur "--dossier attend un chemin"; DESTINATION="$2"; shift 2 ;;
        --aide|-h|--help) aide; exit 0 ;;
        *) erreur "option inconnue : $1 (voir : bash setup.sh --aide)" ;;
    esac
done

[[ -d "$SOURCE" ]] || erreur "dossier de données introuvable : $SOURCE"

if [[ "$(id -u)" -eq 0 ]]; then
    echo "ATTENTION : vous exécutez ce script en tant que root (administrateur)." >&2
    echo "            Ce n'est pas nécessaire. Relancez-le sans sudo." >&2
    exit 1
fi

# Fichiers aux fins de ligne Windows (clone fait sans .gitattributes) ?
if grep -q $'\r' "$SOURCE/genome.fasta"; then
    echo "ATTENTION : les fichiers du dépôt ont des fins de ligne Windows (CRLF)." >&2
    echo "            Clonez le dépôt depuis le terminal Linux (voir chapitre 00)." >&2
fi

if [[ -e "$DESTINATION" ]]; then
    if [[ $RESET -eq 0 ]]; then
        echo "Le bac à sable existe déjà : $DESTINATION"
        echo "Pour le remettre à neuf : bash setup.sh --reset"
        exit 0
    fi
    [[ -f "$DESTINATION/$MARQUEUR" ]] \
        || erreur "$DESTINATION existe mais n'a pas été créé par ce script : je n'y touche pas."
    SAUVEGARDE="$DESTINATION.sauvegarde-$(date '+%Y%m%d-%H%M%S')"
    mv "$DESTINATION" "$SAUVEGARDE"
    echo "Ancien bac à sable conservé sous : $SAUVEGARDE"
fi

mkdir -p "$DESTINATION"
cp -r "$SOURCE"/. "$DESTINATION"/
rm -f "$DESTINATION/README.md"   # la documentation reste dans le dépôt
# Permissions propres et prévisibles, même si le dépôt est sur un disque Windows
# (où tout apparaît en rwxrwxrwx) : fichiers en 644, dossiers en 755.
find "$DESTINATION" -type d -exec chmod 755 {} +
find "$DESTINATION" -type f -exec chmod 644 {} +
echo "Bac à sable créé le $(date '+%Y-%m-%d %H:%M') depuis $DEPOT" > "$DESTINATION/$MARQUEUR"

echo
echo "Bac à sable prêt : $DESTINATION"
echo "Contenu :"
ls -F "$DESTINATION"
echo
echo "Étape suivante : tapez  cd $DESTINATION  puis suivez le chapitre 01."
