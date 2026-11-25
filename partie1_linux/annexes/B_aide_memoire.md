# Annexe B — Aide-mémoire de la Partie I

Cette page rassemble les encadrés « L'essentiel » de tous les chapitres.
Elle est **générée automatiquement** à partir des chapitres par
`tools/generer_annexes.py` : ne la modifiez pas à la main.

## [Chapitre 01 — Premier contact avec le terminal](../01_premier_contact/README.md)

```text
commande [options] [arguments]     la grammaire de toutes les commandes
-n 3   --lines=3                    option courte / option longue
Tab, Tab Tab                        compléter / lister les possibilités
↑  Ctrl+R                           rappeler / rechercher une commande
Ctrl+C                              interrompre (programme bloqué, invite >)
q                                   quitter man ou less
commande --help    man commande     obtenir de l'aide
type commande      help commande    programme ou commande interne ?
Erreur : qui parle ? de quoi ? quel problème ?
```

## [Chapitre 02 — Le système de fichiers : se repérer et se déplacer](../02_systeme_de_fichiers/README.md)

```text
/                      la racine : tout part d'ici
~                      votre dossier personnel (/home/marie)
.   ..                 le dossier courant / le dossier parent
pwd                    où suis-je ?
ls   -l -h -a -F -t -S  qu'y a-t-il ici ? (détails, tailles, cachés, types, tri)
cd chemin    cd ..    cd    cd -    se déplacer
Chemin absolu : commence par / (ou ~), fonctionne depuis partout
Chemin relatif : part du dossier courant
Noms de fichiers : sans espace, sans accent, dates en AAAA-MM-JJ
```

## [Chapitre 03 — Gérer fichiers et dossiers sans rien perdre](../03_gerer_fichiers/README.md)

```text
mkdir -p a/{b,c}/d        créer une arborescence
touch fichier             créer un fichier vide
cp  -r  -i                copier (dossier : -r ; confirmer : -i)
mv  -i                    déplacer ou renommer
rm  -i   rm -r   rmdir    supprimer : DÉFINITIF, pas de corbeille
*   ?   [1-6]   {a,b}     jokers et accolades, développés par le shell
ln -s CIBLE LIEN          lien symbolique : pointer plutôt que copier
find . -name "*.sam" -type f -size +1G      chercher (guillemets !)
Avant rm : vérifier avec ls ou echo.  Jamais rm -rf sans vérifier.
```

## [Chapitre 04 — Lire et inspecter des fichiers : premiers pas avec FASTA et FASTQ](../04_lire_inspecter/README.md)

```text
cat  less (-S)  head  tail (-n +2, -f)   afficher selon la taille
wc -l -w -c -m        compter lignes, mots, octets, caractères
du -sh                poids réel d'un dossier
file                  vrai type d'un fichier (gzip ? texte ? CRLF ?)
FASTA : >en-tête puis séquence sur une ou plusieurs lignes
FASTQ : 4 lignes par read (@id, séquence, +, qualité) → lignes ÷ 4 = reads
zcat  zless  gzip (-k -l -t)  gunzip      fichiers .gz
md5sum -c SOMMES.txt  gzip -t             vérifier l'intégrité
cat -A                voir tabulations (^I), fins de ligne ($), CRLF (^M)
tar -czf / -tzf / -xzf (-C dossier)       créer, lister, extraire une archive
```

## [Chapitre 05 — Flux, redirections et pipes : enchaîner les commandes](../05_flux_redirections_pipes/README.md)

```text
A | B                 la sortie de A devient l'entrée de B
> fichier             écrire (ÉCRASE)       >> fichier   ajouter à la fin
< fichier             lire l'entrée depuis un fichier
2> fichier            les erreurs dans un fichier
> f 2>&1   ou  &> f   sortie ET erreurs dans le même fichier
2> /dev/null          jeter les erreurs (avec discernement)
tee fichier           enregistrer et transmettre
$?   A && B   A || B  code de retour (0 = succès), agir selon le résultat
$(commande)           insérer le résultat d'une commande
$(( calcul ))         arithmétique entière : + - * / % **
zcat f.gz | wc -l     lignes d'un fichier compressé ; ÷ 4 = reads FASTQ
Ne jamais écrire dans le fichier qu'on lit.
```

## [Chapitre 06 — Chercher et filtrer : grep, expressions régulières, cut, sort, uniq](../06_chercher_filtrer/README.md)

```text
grep "motif" f      -c compter  -v inverser  -i casse  -n numéros  -o occurrences
                    -w mot entier  -l fichiers  -r récursif  -A/-B contexte  -E étendue
Regex : ^ début  $ fin  . un caractère  [ACGT] un parmi  [^ACGT] aucun de
        * 0+   (avec -E) + 1+  ? 0-1  {n,m}  a|b  ( )   \. point littéral
grep -c "^>" f.fasta              nombre de séquences
grep -vc "^#" f.vcf               nombre de variants
zcat f.fastq.gz | paste - - - - | cut -f 2    les séquences d'un FASTQ
cut -f 1,3   -d " "   -c 2-        colonnes, séparateur, caractères
sort -n -r -u -k 2,2n -t           trier
sort | uniq -c | sort -rn          compter les valeurs distinctes
tr "acgt" "ACGT"    rev | tr ACGT TGCA    tr -d "\r"
column -t                          aligner pour lire
```

## [Chapitre 07 — awk et sed : calculer et transformer des données biologiques](../07_awk_sed/README.md)

```text
awk 'CONDITION { ACTION }' f       pour chaque ligne : si condition, alors action
$0 ligne  $1 $2 champs  $NF dernier  NF nb champs  NR n° ligne  FNR  FILENAME
-F '\t'   BEGIN { OFS = "\t" }    séparateurs d'entrée et de sortie
== != < > ~ && || !  /regex/       conditions
BEGIN { }  END { }  x += …         initialiser, conclure, cumuler (avec décimales)
printf "%s\t%d\t%.1f\n", …         sortie formatée
n[$5]++ ; for (k in n) …           compter par catégorie
length()  substr()  gsub()  split()  sub()   fonctions utiles
NR % 4 == 2                        les séquences d'un FASTQ
NR == FNR { …; next }              mémoriser un 1er fichier, annoter le 2e
GFF (1-based) → BED (0-based) : début − 1
sed 's/a/b/g'   sed -E 's/(x)…/\1/'   sed -n '5,8p'   sed '/^#/d'   sed -i.bak
```

## [Chapitre 08 — Utilisateurs et permissions : protéger vos données](../08_permissions/README.md)

```text
whoami   id   groups                 qui suis-je, quels groupes
-rwxr-xr--  type | u (propriétaire) | g (groupe) | o (autres)
r = 4 lire / lister   w = 2 modifier / créer-supprimer dedans   x = 1 exécuter / entrer
644 données   755 scripts et dossiers   600 privé   444 lecture seule   750 équipe
chmod u+x f   chmod go-w f   chmod a-w f   chmod 644 f   chmod -R …
umask 022 → fichiers 644, dossiers 755 ; un fichier ne naît jamais exécutable
Supprimer un fichier = droit w sur le DOSSIER
chmod -R a-w data/raw              protéger les données brutes
sudo : pour administrer SA machine, jamais pour « débloquer » ses fichiers
```

## [Chapitre 09 — Processus et ressources : lancer, suivre et arrêter de longs calculs](../09_processus/README.md)

```text
ps   ps -u $USER   ps aux   pgrep -a nom      voir les processus (PID)
top (M, P, u, q)    htop                       tableau de bord en direct
commande &         jobs   fg %n   bg   Ctrl+Z  arrière-plan, suspendre, reprendre
kill PID / %n (TERM)   kill -9 (KILL, dernier recours)   pkill -f motif
nohup cmd > log 2>&1 &                         survivre à la fermeture du terminal
tmux new -s nom · Ctrl+B D · tmux ls · tmux attach -t nom     sessions persistantes
nproc   free -h (available)   df -h   du -sh * | sort -h   time cmd
Killed = souvent la mémoire ; No space left on device = le disque
```

## [Chapitre 10 — L'environnement du shell : variables, guillemets, PATH et .bashrc](../10_environnement_shell/README.md)

```text
var=valeur (sans espace)     "$var"   "${var}_suite"   unset var
${f%.fastq.gz}  ${f%%_*}  ${f##*/}  ${f/R1/R2}  ${#f}  ${v:-défaut}
"doubles"  : remplace $var et $( ), ne découpe pas → par défaut
'simples'  : littéral → awk, sed, regex
PATH : annuaire des programmes ; type -a cmd ; ./script si hors PATH
PATH="$HOME/bin:$PATH"      ajouter (jamais remplacer)
export VAR                  transmettre aux programmes lancés ; env
nano fichier   Ctrl+O enregistrer · Ctrl+X quitter    (vim : Échap :q!)
~/.bashrc : réglages permanents ; alias nom='commande' ; source ~/.bashrc
```

## [Chapitre 11 — Installer des logiciels : apt, Conda, Mamba et Bioconda](../11_installer_logiciels/README.md)

```text
apt (sudo)       outils système de VOTRE machine   sudo apt update ; sudo apt install tree
conda / mamba    outils scientifiques, sans droits, partout
Miniforge : curl -L -O …/Miniforge3-$(uname)-$(uname -m).sh ; bash … ; yes à conda init ; nouveau terminal
conda config --add channels bioconda ; --add channels conda-forge ; --set channel_priority strict
mamba create -n env outil=version     conda activate env     conda deactivate
mamba install -n env outil   conda list   conda env list   conda env remove -n env
mamba env create -f environment.yml   (versions figées = reproductible)
conda env export --from-history > env.yml   → ajouter bioconda, figer les versions, retirer prefix
Activer = mettre env/bin en tête du PATH ; jamais travailler dans (base)
```

## [Chapitre 12 — Scripts Bash (I) : automatiser un traitement sur tous vos échantillons](../12_scripts_bash_1/README.md)

```text
#!/bin/bash   # commentaire        bash script.sh   ou   chmod u+x + ./script.sh
$0 $1 $2 $# "$@"                   nom, arguments, nombre, tous
if [ test ]; then …; elif …; else …; fi      espaces dans [ ] obligatoires
-f -d -s ! -z   = !=   -eq -ne -lt -le -gt -ge      tests fichiers, textes, nombres
exit 1 (échec)   echo "…" >&2 (message d'erreur)    usage si arguments manquants
for f in dossier/*_R1_*.fastq.gz; do … "$f" … done  boucle sur des fichiers
r2=${f/_R1_/_R2_}   nom=$(basename "$f")   ech=${nom%%_*}
while IFS=$'\t' read -r c1 c2 …; do … done < <(tail -n +2 feuille.tsv)
case "$x" in motif) …;; *) …;; esac
Afficher (echo) avant d'exécuter une opération en série.
```

## [Chapitre 13 — Scripts Bash (II) : des scripts robustes, journalisés et débogables](../13_scripts_bash_2/README.md)

```text
set -euo pipefail          -e arrêt sur erreur · -u variable non définie · pipefail
  limites : if/&&/|| non concernés ; grep sans résultat → || true ; vérifier [ -s sortie ]
shopt -s nullglob          joker sans correspondance = rien
f() { local x=$1; …; echo résultat; }      n=$(f arg)
log() { printf '[%s] %s\n' "$(date …)" "$*" | tee -a journal.log >&2; }
tmp=$(mktemp -d) ; trap 'rm -rf "$tmp"' EXIT
while [ $# -gt 0 ]; do case "$1" in --opt) v=$2; shift 2;; *) usage;; esac; done
[ -d "$d" ] || { echo "Erreur …" >&2; exit 1; }    command -v outil > /dev/null
bash -n (syntaxe) · shellcheck (analyse) · bash -x (trace)
Un message → une correction → relancer.
```

## [Chapitre 14 — Travailler à distance : SSH, clés, scp et rsync](../14_ssh/README.md)

```text
sudo apt install openssh-server ; sudo systemctl enable --now ssh    (le « serveur » local)
ssh localhost   ssh utilisateur@machine   exit / Ctrl+D   ssh machine 'commande'
1re connexion : vérifier l'empreinte, yes → ~/.ssh/known_hosts
ssh-keygen -t ed25519 (avec phrase de passe) ; ssh-copy-id machine
id_ed25519 = PRIVÉE (600, ne jamais partager) ; id_ed25519.pub = publique
eval "$(ssh-agent)" ; ssh-add                    phrase de passe une seule fois
~/.ssh/config : Host alias / HostName / User / Port / IdentityFile
scp f machine:chemin/   scp machine:chemin/f .   scp -r
rsync -av source/ machine:dest/   -P reprise   -n simulation   --delete (simuler d'abord !)
Calcul long à distance : tmux ; après transfert : md5sum -c
```

## [Chapitre 15 — Git pour biologistes : versionner ses scripts](../15_git/README.md)

```text
git config --global user.name "…" / user.email "…" / init.defaultBranch main
git init        git status        git add fichiers        git commit -m "message"
git log --oneline     git diff     git show HEAD~1:fichier    git log -- fichier
.gitignore : data/  resultats/  *.fastq.gz  *.bam  → JAMAIS de données, de résultats, de secrets
git restore f (annule les modifs non commitées)     git restore --staged f
git switch -c branche   git switch main   git merge branche
GitHub : clé SSH publique → git remote add origin git@github.com:moi/depot.git
git push -u origin main   ·   git clone …   ·   git pull
```

## [Chapitre 16 — Les formats biologiques en pratique : FASTA, FASTQ, SAM/BAM, BED, GFF, VCF](../16_formats_biologiques/README.md)

```text
FASTA   samtools faidx ref.fa ; samtools faidx ref.fa chrA:151-180      (1-based, bornes incluses)
FASTQ   Q = code ASCII − 33 ; Q30 = 1 erreur / 1000 ; seqkit fx2tab -q
SAM     QNAME FLAG RNAME POS MAPQ CIGAR … SEQ QUAL    samtools flags N
        samtools view -c  -f 4 / -F 4  -q 30  ;  samtools flagstat
        CIGAR : M aligné, I insertion, D délétion, S coupé, N intron
BAM     samtools sort -o f.bam f.sam ; samtools index f.bam ; samtools view f.bam chrA:400-420
        samtools coverage ; samtools mpileup -f ref.fa -r chrA:412-412 f.bam
BED     0-based, fin exclue ; GFF/GTF/VCF/SAM : 1-based, fin incluse → début − 1
VCF     bcftools view -H / -f PASS / -i 'QUAL>=30' / -v snps|indels / -s échantillon
        bcftools query -f '%CHROM\t%POS\t%REF\t%ALT[\t%GT]\n' ; bcftools view -Oz ; bcftools index
bedtools intersect -wa -wb / -v / -c ; getfasta -s -name ; coverage
```

## [Chapitre 17 — Organiser un projet de bioinformatique](../17_organiser_projet/README.md)

```text
data/raw (lecture seule) · data/reference · data/metadata · envs · scripts · results · logs · README.md
Précieux = données brutes, scripts, métadonnées, environnement, README
Régénérable = results/, logs/, fichiers intermédiaires
Tout résultat vient d'un script ; chemins relatifs à la racine ; chaque étape dans son dossier
Git : scripts, métadonnées, envs, README    .gitignore : data/raw, data/reference, results, logs
run_all.sh : cd "$(dirname "$0")/.." puis les étapes dans l'ordre, avec journaux
Données brutes : 2 copies, 2 supports, 1 hors site, vérifiées par md5sum
```

---

**Retour** : [sommaire de la Partie I](../README.md)
