# 04 — Bash scripting pour pipelines bioinformatiques

OBJECTIVE
------------------------------------------------------------
Passer de la commande isolée au script réutilisable : variables,
conditions, boucles, fonctions, arguments en ligne de commande, gestion
d'erreurs, journalisation. C'est la dernière étape avant les workflows
formels (Snakemake/Nextflow, phases ultérieures).

PREREQUISITES
------------------------------------------------------------
`01_linux_basics/`, `02_linux_for_bioinformatics/`, `03_text_processing/`.

INPUT DATA
------------------------------------------------------------
`linux/*.fastq.gz` (3 échantillons compressés).

---

# 1. Variables

```bash
FILE="genome.fasta"
echo "$FILE"
ls -lh "$FILE"
```

```text
INTERPRETATION: toujours entourer une variable de guillemets doubles
         ("$FILE") lors de son utilisation. Sans guillemets, un nom de
         fichier contenant un espace serait scindé en plusieurs
         arguments par le shell — source classique de bugs silencieux.
DOCUMENTATION: https://www.gnu.org/software/bash/manual/bash.html
         (Bash Reference Manual, « Shell Parameters »)
```

Capturer la sortie d'une commande dans une variable (« command
substitution ») :

```bash
NB_READS=$(( $(wc -l < reads.fastq) / 4 ))
echo "Nombre de reads : $NB_READS"
```

---

# 2. Conditions

```bash
if [ -f "genome.fasta" ]; then
    echo "Le fichier existe."
else
    echo "Fichier introuvable." >&2
    exit 1
fi
```

```text
TESTS DE FICHIERS COURANTS:
  -f fichier    existe et est un fichier régulier
  -d dossier    existe et est un dossier
  -s fichier    existe et n'est PAS vide (taille > 0)
  -r / -w / -x  lisible / inscriptible / exécutable
INTERPRETATION: `>&2` redirige un message vers la sortie d'erreur
         (stderr) plutôt que la sortie standard — convention essentielle
         pour que les messages d'erreur ne polluent pas un résultat
         redirigé vers un fichier.
DOCUMENTATION: https://www.gnu.org/software/bash/manual/bash.html
         (« Bash Conditional Expressions »)
EXERCISE: écrire un test qui vérifie qu'un fichier FASTQ existe ET n'est
         pas vide avant de le traiter (combiner -f et -s avec &&).
```

---

# 3. Boucles — traiter plusieurs échantillons

```bash
for f in *.fastq.gz
do
    n=$(( $(zcat "$f" | wc -l) / 4 ))
    printf '%s\t%d reads\n' "$f" "$n"
done
```

```text
INTERPRETATION: le glob *.fastq.gz est développé par le shell AVANT
         l'exécution de la boucle, en une liste de noms de fichiers
         correspondants — pas par la commande for elle-même.
COMMON ERRORS: si aucun fichier ne correspond au motif, le glob n'est pas
         développé et la boucle reçoit littéralement la chaîne
         "*.fastq.gz" comme un seul élément. Activer `shopt -s nullglob`
         en tête de script pour éviter ce piège (la boucle ne s'exécute
         alors simplement pas si aucun fichier ne correspond).
DOCUMENTATION: https://www.gnu.org/software/bash/manual/bash.html
         (« Looping Constructs », « Filename Expansion »)
```

---

# 4. Écrire un script complet et robuste

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "=== FASTA ==="
for f in *.fasta; do
    printf '%s\t%s séquences\n' "$f" "$(grep -c '^>' "$f")"
done

echo "=== FASTQ ==="
for f in *.fastq.gz; do
    printf '%s\t%d reads\n' "$f" "$(( $(zcat "$f" | wc -l) / 4 ))"
done
```

```text
COMMAND: #!/usr/bin/env bash
PURPOSE: « shebang » — indique au système quel interpréteur utiliser pour
         exécuter le script directement (./script.sh). `env bash` plutôt
         que /bin/bash en dur rend le script portable si bash n'est pas
         installé exactement au même chemin sur tous les systèmes.
```

```text
COMMAND: set -euo pipefail
PURPOSE: rendre le script robuste par défaut face aux erreurs silencieuses.
EXPLICATION DÉTAILLÉE (chaque option séparément) :
  set -e          arrête immédiatement le script si une commande échoue
                  (code de sortie non nul), au lieu de continuer comme si
                  de rien n'était.
  set -u          transforme l'utilisation d'une variable non définie en
                  erreur fatale, au lieu de la traiter silencieusement
                  comme une chaîne vide (piège fréquent : une faute de
                  frappe dans un nom de variable).
  set -o pipefail fait échouer tout le pipeline (cmd1 | cmd2) si N'IMPORTE
                  LAQUELLE des commandes échoue, pas seulement la
                  dernière — par défaut, seul le code de sortie de la
                  DERNIÈRE commande d'un pipeline est pris en compte.
LIMITE À CONNAÎTRE: set -e ne se déclenche pas dans certains contextes
         (une commande utilisée dans une condition if, ou à gauche d'un
         &&/||) — ce n'est pas une garantie absolue, mais une bonne
         pratique par défaut à connaître en profondeur, pas une formule
         magique à copier sans comprendre.
DOCUMENTATION: https://www.gnu.org/software/bash/manual/bash.html
         (« The Set Builtin »)
```

Rendre exécutable et lancer :

```bash
chmod +x scripts/stats.sh
./scripts/stats.sh
```

Ce script existe réellement dans ce dépôt, testé sur le jeu de données
`linux/` : voir `scripts/stats.sh` et `scripts/README.md`.

---

# 5. Arguments, fonctions, exit codes

## 5.1 Arguments nommés

```bash
#!/usr/bin/env bash
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

echo "Entrée   : $INPUT"
echo "Sortie   : $OUTPUT"
echo "Threads  : $THREADS"
```

```text
INTERPRETATION: $# est le nombre d'arguments restants ; $1, $2... sont
         les arguments positionnels ; shift 2 décale les arguments de 2
         positions après avoir consommé --option valeur.
         "${INPUT:-}" fournit une valeur par défaut vide si INPUT n'est
         pas définie, ce qui évite que `set -u` fasse planter le test
         lui-même.
DOCUMENTATION: https://www.gnu.org/software/bash/manual/bash.html
         (« Special Parameters », « Bash Conditional Expressions »)
EXERCISE: appeler ce script avec seulement --input, sans --output, et
         vérifier que le message d'usage s'affiche bien au lieu de
         planter avec une erreur Bash brute.
```

## 5.2 Fonctions

```bash
count_reads() {
    local fastq="$1"
    echo $(( $(zcat "$fastq" | wc -l) / 4 ))
}

for f in *.fastq.gz; do
    n=$(count_reads "$f")
    echo "$f : $n reads"
done
```

```text
INTERPRETATION: `local` limite la portée de la variable à la fonction —
         sans local, une variable définie dans une fonction reste globale
         et peut entrer en conflit avec une autre variable du script.
DOCUMENTATION: https://www.gnu.org/software/bash/manual/bash.html
         (« Shell Functions »)
```

## 5.3 Codes de sortie (exit codes)

```text
CONCEPT: chaque commande retourne un code de sortie numérique : 0 = succès,
         toute autre valeur (1-255) = échec. $? contient le code de la
         dernière commande exécutée.
```

```bash
grep -q "^>" genome.fasta
if [ $? -eq 0 ]; then
    echo "Motif trouvé"
fi

# équivalent plus idiomatique, sans variable intermédiaire :
if grep -q "^>" genome.fasta; then
    echo "Motif trouvé"
fi
```

```text
DOCUMENTATION: https://www.gnu.org/software/bash/manual/bash.html
         (« Exit Status »)
EXERCISE: écrire une fonction qui retourne 1 (via `return 1`) si un
         fichier FASTQ est vide, 0 sinon, et l'utiliser dans un `if`.
```

## 5.4 Tableaux (arrays)

```bash
SAMPLES=(sample_01 sample_02 sample_03)
for s in "${SAMPLES[@]}"; do
    echo "Traitement de $s"
done
echo "Nombre d'échantillons : ${#SAMPLES[@]}"
```

```text
DOCUMENTATION: https://www.gnu.org/software/bash/manual/bash.html
         (« Arrays »)
```

## 5.5 Journalisation (logging)

```bash
LOG="logs/pipeline.log"
mkdir -p logs

log() {
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" | tee -a "$LOG"
}

log "Démarrage du pipeline"
```

```text
INTERPRETATION: `tee -a` affiche le message à l'écran ET l'ajoute au
         fichier de log en même temps — utile pour suivre l'exécution en
         direct tout en conservant une trace.
DOCUMENTATION: https://www.gnu.org/software/coreutils/manual/coreutils.html
         (tee, date)
```

La section 5 dans son ensemble (arguments nommés, fonctions, exit codes,
logging) est combinée dans un script réel et testé du dépôt :
`scripts/pipeline_template.sh` (voir `scripts/README.md`).

---

# 6. Tester la robustesse d'un script

```text
CONCEPT: avant de considérer un script terminé, vérifier sa syntaxe puis
         le tester contre des cas limites.
```

```bash
bash -n scripts/pipeline.sh     # vérifie la syntaxe SANS exécuter le script
```

Cas à tester systématiquement pour un script qui traite des fichiers
biologiques :

```text
[ ] fichier d'entrée manquant
[ ] fichier d'entrée vide
[ ] argument manquant ou mal orthographié
[ ] format de fichier inattendu (ex. FASTA passé à une commande FASTQ)
[ ] fichier de sortie déjà existant (écrase-t-on par erreur ?)
[ ] référence génomique manquante ou non indexée
[ ] fichiers paired-end mal appariés (R1/R2 incohérents)
```

```text
DOCUMENTATION: ShellCheck (analyseur statique de scripts shell) —
         https://www.shellcheck.net/ (site officiel) et dépôt source
         https://github.com/koalaman/shellcheck
EXERCISE: exécuter `bash -n` sur le script de la section 4, puis, si
         ShellCheck est installé, `shellcheck scripts/stats.sh` et
         corriger les avertissements signalés.
```

---

TROUBLESHOOTING
------------------------------------------------------------
```text
SYMPTOM: le script continue de s'exécuter après une erreur, produisant
         des résultats incomplets sans message clair
CAUSE: absence de `set -e` (ou une commande placée dans un contexte où
       set -e ne s'applique pas).
DIAGNOSIS: relire le script à la recherche de commandes sans vérification
           d'erreur.
SOLUTION: ajouter `set -euo pipefail` en tête de script et tester chaque
          cas limite de la section 6.
PREVENTION: adopter set -euo pipefail comme réflexe systématique dans
            tout nouveau script.
```
```text
SYMPTOM: "unbound variable" alors que la variable semble définie
CAUSE: faute de frappe dans le nom de la variable, ou variable définie
       dans une autre fonction/sous-shell.
DIAGNOSIS: set -u a révélé un bug qui serait resté silencieux sans lui.
SOLUTION: corriger le nom, ou fournir une valeur par défaut explicite
          avec ${VAR:-valeur_par_defaut} si l'absence est un cas valide.
PREVENTION: c'est précisément le rôle de set -u — le garder activé.
```

GO FURTHER
------------------------------------------------------------
```text
Command: bash (scripting)
Official documentation: https://www.gnu.org/software/bash/manual/bash.html
Topics to explore: trap (nettoyage à la sortie), here-documents,
                    substitution de processus, expansion de paramètres
                    avancée (${var%pattern}, ${var#pattern})
```

DOCUMENTATION
------------------------------------------------------------
- GNU Bash Reference Manual — https://www.gnu.org/software/bash/manual/bash.html
- GNU Coreutils Manual (tee, date) — https://www.gnu.org/software/coreutils/manual/coreutils.html
- ShellCheck — https://www.shellcheck.net/ · source : https://github.com/koalaman/shellcheck

NEXT MODULE
------------------------------------------------------------
`05_biological_formats/` — approfondir FASTA/FASTQ et découvrir SAM/BAM/
VCF/BED/GFF/GTF avant d'aborder les vrais pipelines d'analyse.
