# Mini-projet — AMR, typage et phylogénie sur 3 isolats de *Klebsiella pneumoniae* résistants aux carbapénèmes

OBJECTIVE
------------------------------------------------------------
Guider pas à pas la construction d'un pipeline bactérien complet — QC,
assemblage, annotation, profilage AMR, typage moléculaire, SNP calling et
phylogénie — sur un jeu de données réel et vérifiable, avec une
architecture Snakemake déclarative (module 24) et des choix d'outils
justifiés pour l'organisme étudié (voir DECISIONS).

PREREQUISITES
------------------------------------------------------------
`07_project_organization/`, `08_data_acquisition/` (sections 5.1 et 5.2),
`09_quality_control/`, `10_adapter_trimming_filtering/`,
`11_de_novo_assembly/`, `13_assembly_quality/`, `14_genome_annotation/`,
`21_variant_analysis/` (principes de SNP calling), `24_workflows/`
(Snakemake), `25_reproducibility/` (Conda/Git). Aucune commande n'est
réexpliquée ici en détail — chaque étape renvoie vers le module qui
l'enseigne. Le profilage AMR, le typage moléculaire et la phylogénie par
SNP-core ne sont couverts par aucun module numéroté existant : ce
mini-projet introduit `envs/amr_typing.yml` pour combler ce manque,
ouvrant la voie à un futur module dédié.

BIOLOGICAL CONTEXT
------------------------------------------------------------
```text
Klebsiella pneumoniae résistante aux carbapénèmes (CRKP) est classée
priorité critique par l'OMS pour la recherche de nouveaux antibiotiques.
La résistance aux carbapénèmes provient le plus souvent d'une
carbapénémase acquise (KPC, NDM, OXA-48...) portée par un plasmide,
capable de se propager entre souches et entre espèces — contrairement à
une mutation chromosomique isolée. Ce mini-projet caractérise 3 isolats
cliniques réels d'une collection vietnamienne de 27 isolats CRKP, en
reproduisant les grandes lignes de la méthode publiée par les auteurs
(y compris leur choix de génome de référence pour l'appel de SNP), à
plus petite échelle pour rester accessible en exercice.
```

DATASET
------------------------------------------------------------
Voir `data/metadata/samples.tsv` pour le détail complet.

| Échantillon | Run accession (ENA/DDBJ) | BioSample | Taille brute |
|---|---|---|---|
| `kpn_01` | `DRR076969` | `SAMD00066874` | 179,4 Mpb |
| `kpn_02` | `DRR076945` | `SAMD00066850` | 181,3 Mpb |
| `kpn_03` | `DRR076958` | `SAMD00066863` | 181,6 Mpb |

Ces 3 échantillons proviennent de l'étude BioProject `PRJDB5317`
(soumission DDBJ `DRA005275`, 27 isolats cliniques de *K. pneumoniae*
résistants aux carbapénèmes, hôpital vietnamien, séquencés en Illumina
MiSeq paired-end), publiée par Tada et al. (2017) — voir SCIENTIFIC
REFERENCES. Les 3 accessions les plus légères de la collection ont été
retenues pour un exercice accessible (téléchargement total ≈ 540 Mo,
comparable au projet final `final_project_ltee_ecoli/`).

Référence pour l'appel de SNP : *Klebsiella pneumoniae* PMK1 (souche
productrice de NDM-1, ST15, génome complet), assemblage NCBI
`GCA_000764615.1` (https://www.ncbi.nlm.nih.gov/datasets/genome/GCA_000764615.1/).
Ce choix n'est pas arbitraire : c'est la référence utilisée par Tada et
al. (2017) eux-mêmes pour leur propre appel de SNP — la réutiliser ici
permet une comparaison honnête avec la méthode publiée plutôt qu'un choix
de référence non justifié.

VÉRITÉ DE TERRAIN PUBLIÉE (population entière, PAS par isolat)
------------------------------------------------------------
```text
Tada et al. (2017) rapportent, sur l'ENSEMBLE des 27 isolats de la
collection (pas spécifiquement sur les 3 retenus ici) :
  - chaque isolat porte l'un des gènes de carbapénémase suivants : KPC-2,
    NDM-1, NDM-4 ou OXA-48 ;
  - 13 isolats, résistants à l'arbékacine (CMI ≥256 mg/L) et à
    l'amikacine (CMI ≥512 mg/L), portent un gène de méthylase de l'ARNr
    16S (RmtB ou RmtC) ;
  - 18 isolats appartiennent au clone international ST15, 4 au ST16 ;
  - aucun isolat ne porte de facteur de résistance à la colistine connu.

Ce mini-projet NE PRÉ-ASSIGNE VOLONTAIREMENT AUCUNE de ces catégories à
kpn_01/02/03 : c'est au pipeline exécuté par le lecteur de les
déterminer. Cette distribution publiée sert de grille de plausibilité a
posteriori (section RÉSULTATS ATTENDUS), pas de réponse préchargée.
```

---

# 1. Pipeline

```text
config.yaml (échantillons, référence, checksums, seuils)
  ↓
get_reference + get_reads (08, §5.2 — méthode ENA)   : FASTA PMK1 + 3×(R1,R2), intégrité vérifiée (md5sum)
  ↓
fastqc_raw (09) → trim — fastp (10) → multiqc         : QC avant/après trimming, rapport agrégé
  ↓
assemble — SPAdes --isolate (11)                       : assemblage de novo par échantillon
  ↓
assembly_qc — QUAST + BUSCO (13)                       : statistiques + complétude
  ↓
annotate — Bakta (14)                                  : annotation structurale/fonctionnelle
  ↓
amr_abricate + amr_amrfinder + amr_consensus            : profilage AMR croisé (CARD vs AMRFinderPlus)
  ↓
typing_kleborate                                       : MLST + AMR + virulence spécifiques K. pneumoniae
  ↓
snippy (par échantillon) → snippy_core → build_tree     : SNP calling contre PMK1, arbre à 4 feuilles (FastTree)
```

Le pipeline est implémenté en Snakemake (`Snakefile`, module 24) : chaque
règle exécute une commande déjà enseignée (ou introduite explicitement
ci-dessous quand aucun module ne la couvre encore), avec une directive
`conda:` pointant vers un fichier `envs/*.yml` **existant** à la racine
du dépôt — sauf `envs/amr_typing.yml`, créé par ce mini-projet pour les
outils AMR/typage/phylogénie qu'aucun module ne couvrait.

---

# 2. Guide pas-à-pas (exécution manuelle, une fois, avant Snakemake)

Cette section déroule **une seule fois, à la main**, exactement ce que la
règle Snakemake correspondante automatise ensuite pour les 3 échantillons
— pour que le lecteur comprenne chaque étape avant de la voir orchestrée.
Toutes les commandes ci-dessous utilisent `kpn_01` (`DRR076969`) comme
exemple ; le Snakefile répète cela pour `kpn_02` et `kpn_03`.

## 2.1 Récupérer et vérifier les données (module 08, §5.2)

```bash
conda env create -f ../../envs/data_acquisition.yml   # non requis ici (méthode ENA directe)
mkdir -p data/raw data/reference

wget -c -O data/reference/PMK1.fasta.gz \
    "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/764/615/GCA_000764615.1_ASM76461v1/GCA_000764615.1_ASM76461v1_genomic.fna.gz"
echo "c5fafe339dda6beadbc573f649146bfe  data/reference/PMK1.fasta.gz" | md5sum -c -
gunzip data/reference/PMK1.fasta.gz

wget -c -O data/raw/kpn_01_1.fastq.gz \
    ftp://ftp.sra.ebi.ac.uk/vol1/fastq/DRR076/DRR076969/DRR076969_1.fastq.gz
wget -c -O data/raw/kpn_01_2.fastq.gz \
    ftp://ftp.sra.ebi.ac.uk/vol1/fastq/DRR076/DRR076969/DRR076969_2.fastq.gz
echo "8336af671dc1feed6761b6ddb33bd497  data/raw/kpn_01_1.fastq.gz" | md5sum -c -
echo "ce8039179fdbf45acf632c82a38b5d6a  data/raw/kpn_01_2.fastq.gz" | md5sum -c -
```

```text
COMMON ERRORS:
  - "md5sum: WARNING: 1 computed checksum did NOT match" → téléchargement
    interrompu ou incomplet ; relancer `wget -c` (reprise) puis
    revérifier — ne jamais enchaîner l'étape suivante sur un fichier dont
    la somme de contrôle n'a pas été confirmée.
EXERCISE: avant de continuer, exécuter `file data/reference/PMK1.fasta`
         (01_linux_basics/, section 3) et confirmer "ASCII text" — un
         fichier encore compressé ou tronqué serait détecté ici, avant
         de perdre du temps sur les étapes suivantes.
```

## 2.2 QC et trimming (modules 09-10)

```bash
conda env create -f ../../envs/qc.yml && conda activate qc
fastqc data/raw/kpn_01_1.fastq.gz data/raw/kpn_01_2.fastq.gz -o results/qc/fastqc_raw/kpn_01/

conda activate trimming   # ou : conda env create -f ../../envs/trimming.yml
fastp -i data/raw/kpn_01_1.fastq.gz -I data/raw/kpn_01_2.fastq.gz \
    -o results/trimmed/kpn_01_1.trim.fastq.gz -O results/trimmed/kpn_01_2.trim.fastq.gz \
    --detect_adapter_for_pe --html results/trimmed/kpn_01.fastp.html
```

## 2.3 Assemblage et contrôle qualité (modules 11, 13)

```bash
conda activate assembly   # envs/assembly.yml
spades.py --isolate \
    -1 results/trimmed/kpn_01_1.trim.fastq.gz -2 results/trimmed/kpn_01_2.trim.fastq.gz \
    -o results/assembly/kpn_01 -t 4

conda activate assembly_quality   # envs/assembly_quality.yml
quast.py results/assembly/kpn_01/contigs.fasta -r data/reference/PMK1.fasta \
    -o results/assembly_qc/kpn_01
busco -i results/assembly/kpn_01/contigs.fasta -o busco -l enterobacterales_odb10 \
    -m genome --out_path results/assembly_qc/kpn_01 --cpu 4
```

```text
EXERCISE: ouvrir results/assembly_qc/kpn_01/report.txt (QUAST) et
         identifier le N50 et le nombre de contigs de l'assemblage —
         comparer mentalement à un génome de K. pneumoniae typique
         (~5,3-5,5 Mpb, chromosome unique + plasmides) : un assemblage en
         plusieurs centaines de contigs signalerait une couverture ou une
         qualité de reads insuffisante à examiner avant de continuer.
```

## 2.4 Annotation (module 14)

```bash
conda activate annotation   # envs/annotation.yml
bakta_db download --output data/bakta_db --type light   # une seule fois, ~1,2 Go
bakta --db data/bakta_db --output results/annotation/kpn_01 --prefix kpn_01 \
    --threads 4 results/assembly/kpn_01/contigs.fasta
```

## 2.5 Profilage AMR croisé (ABRicate vs AMRFinderPlus)

```bash
conda env create -f ../../envs/amr_typing.yml && conda activate amr_typing
amrfinder -u   # une seule fois : télécharge la base AMRFinderPlus (petite)

abricate --db card results/assembly/kpn_01/contigs.fasta > results/amr/kpn_01.card.tsv
amrfinder -n results/assembly/kpn_01/contigs.fasta --organism Klebsiella_pneumoniae \
    -o results/amr/kpn_01.amrfinder.tsv --threads 4

conda activate python_bio   # envs/python_bio.yml
python3 scripts/arbitre_amr.py \
    --abricate-tsv results/amr/kpn_01.card.tsv --amrfinder-tsv results/amr/kpn_01.amrfinder.tsv \
    --sample-name kpn_01 --output-table results/amr/kpn_01.consensus.tsv \
    --output-plot results/amr/kpn_01.venn.png
```

```text
EXERCISE: ouvrir results/amr/kpn_01.consensus.tsv et repérer si un gène
         de carbapénémase (recherche du motif "bla" dans la colonne
         gene — KPC, NDM ou OXA) apparaît en high_confidence=True. C'est
         la première réponse concrète que ce mini-projet vous laisse
         découvrir vous-même plutôt que de vous la donner (voir VÉRITÉ DE
         TERRAIN PUBLIÉE).
```

## 2.6 Typage moléculaire (Kleborate)

```bash
kleborate --help   # vérifier la syntaxe de la version installée (v2 vs v3, voir DECISIONS)
kleborate --assemblies results/assembly/kpn_01/contigs.fasta data/reference/PMK1.fasta \
    --outfile results/typing/kleborate_report.txt --all
```

```text
EXERCISE: dans kleborate_report.txt, vérifier la ligne correspondant à
         PMK1.fasta : elle DOIT indiquer ST15 (voir DATASET). Si ce
         témoin positif ne sort pas correctement, le problème est dans
         l'installation ou la base Kleborate — pas dans vos échantillons
         — à corriger avant d'interpréter kpn_01/02/03.
```

## 2.7 SNP calling et phylogénie (Snippy + FastTree)

```bash
snippy --outdir results/phylo/snippy_kpn_01 --ref data/reference/PMK1.fasta \
    --R1 results/trimmed/kpn_01_1.trim.fastq.gz --R2 results/trimmed/kpn_01_2.trim.fastq.gz --cpus 4
# répéter pour kpn_02 et kpn_03, puis :
snippy-core --ref data/reference/PMK1.fasta --prefix results/phylo/core \
    results/phylo/snippy_kpn_01 results/phylo/snippy_kpn_02 results/phylo/snippy_kpn_03
fasttree -nt -gtr results/phylo/core.full.aln > results/phylo/tree.nwk
```

```text
EXERCISE: l'arbre obtenu a 4 feuilles (3 isolats + PMK1) — contrairement
         à un pipeline qui n'aligne qu'un seul isolat contre sa
         référence (2 feuilles seulement, une comparaison binaire sans
         vraie topologie). Ouvrir tree.nwk dans un visualiseur simple
         (ex. https://itol.embl.de/upload.cgi, ou `ete3`/`biopython` du
         module 23) et identifier quels 2 isolats, parmi les 3, sont les
         plus proches l'un de l'autre.
```

---

# 3. Comment exécuter (Snakemake, automatisation des 3 échantillons)

```bash
conda env create -f ../../envs/workflows.yml && conda activate workflows

cd projects/mini_project_amr_kpneumoniae
snakemake -n --configfile config.yaml           # dry-run : affiche le DAG, ne télécharge/exécute rien
snakemake --use-conda -j 4 --configfile config.yaml
```

```text
COMMON ERRORS:
  - lancer `snakemake --use-conda` sans conda/mamba dans le PATH →
    échec à la création des environnements (06_environment_management/).
  - espace disque insuffisant → prévoir au moins 5 Go (reads + 3
    assemblages + base Bakta light ~1,2 Go + base BUSCO) ; vérifier avec
    `df -h` avant de lancer (01_linux_basics/, section 6).
EXERCISE: avant l'exécution complète, `snakemake -n --configfile config.yaml`
         et compter le nombre de règles qui seront exécutées ; identifier
         dans la sortie que `get_reference` et `get_reads` n'ont aucune
         dépendance entre elles (parallélisables).
```

---

# 4. DECISIONS (choix méthodologiques justifiés)

```text
3 ISOLATS + 1 RÉFÉRENCE : un seul isolat aligné contre sa référence ne
         donne qu'un arbre à 2 feuilles, sans topologie interprétable.
         Avec 3 isolats + PMK1, l'arbre obtenu ici (section 2.7) a une
         vraie topologie à interpréter — condition nécessaire pour
         observer la diversité clonale (ST15/ST16/autres) qui est
         justement l'objet biologique de ce mini-projet.

SPADES DIRECT PLUTÔT QUE SHOVILL : Shovill est un simple orchestrateur
         trim+assemble+correct autour de SPAdes/Skesa/Megahit. Le
         trimming est déjà fait par fastp (section 2.2) ; passer par
         SPAdes directement (déjà documenté par envs/assembly.yml,
         module 11) évite de dupliquer un outil pour une valeur ajoutée
         ici redondante.

BAKTA PLUTÔT QUE DFAST+KofamScan : DFAST+KofamScan nécessitent des
         fichiers `profiles/` et `ko_list` KEGG à télécharger
         manuellement, une dépendance facile à oublier de documenter.
         Bakta (déjà recommandé par 14_genome_annotation/README.md,
         §1.1, comme remplaçant actif de Prokka) a une procédure de
         base de données documentée et explicite (`bakta_db download`,
         section 2.4 ci-dessus).

BUSCO PLUTÔT QUE CheckM : même raisonnement — CheckM exige une base de
         données externe (`checkm data setRoot`) à installer à part.
         BUSCO (déjà l'outil de envs/assembly_quality.yml, module 13)
         télécharge son jeu de données de lignage lui-même, de façon
         transparente, à la première exécution.

KLEBORATE PLUTÔT QUE mlst GÉNÉRIQUE + spaTyper : un typage MLST/AMR/
         virulence générique ne suffit pas ici. `spaTyper`, par exemple
         — un outil courant pour le typage de la protéine de surface
         spa — n'a tout simplement aucun sens pour Klebsiella pneumoniae
         : le gène spa n'existe pas chez cette espèce, il est spécifique
         à S. aureus. Kleborate est l'outil de référence conçu
         spécifiquement pour le complexe d'espèces K. pneumoniae (MLST +
         résistance + virulence + capsule en un seul outil) — le bon
         réflexe est de choisir l'outil pertinent pour l'organisme
         étudié, pas d'appliquer un typage générique par défaut.

TÉMOIN POSITIF (PMK1) DANS LE TYPAGE : PMK1 est un ST15 connu et publié
         (voir DATASET). L'inclure dans l'entrée de `typing_kleborate`
         fournit un contrôle de cohérence gratuit : si Kleborate ne
         retrouve pas ST15 pour PMK1, l'installation/la base est en
         cause avant même de regarder kpn_01/02/03.

CHECKSUMS MD5 EXPLICITES : un `wget -c` seul ne garantit rien sur
         l'intégrité du contenu téléchargé, seulement sur la reprise
         d'un téléchargement interrompu — un fichier tronqué ou corrompu
         passerait inaperçu jusqu'à un échec bien plus loin dans le
         pipeline. `config.yaml` fixe donc les sommes de contrôle
         ENA/NCBI officielles, vérifiées immédiatement après chaque
         téléchargement (section 2.1, règles get_reference/get_reads du
         Snakefile).

ARBITRE_AMR.PY : chemins d'entrée/sortie explicites en arguments
         (`--abricate-tsv`, `--amrfinder-tsv`, `--output-table`...)
         plutôt que des noms de fichiers relatifs supposant un dossier
         de travail précis, et `sys.exit(1)` sur toute erreur plutôt
         qu'un `except Exception` générique qui se contenterait
         d'imprimer un message — pour qu'un orchestrateur (Snakemake,
         `set -e`) puisse réellement détecter un échec de cette étape
         au lieu de le voir capturé et ignoré silencieusement.
```

---

# 5. LIMITATIONS

```text
CE MINI-PROJET EST LIVRÉ PRÊT À EXÉCUTER, PAS ENCORE EXÉCUTÉ : contrairement
         à `final_project_ltee_ecoli/`, dont le README documente déjà une
         exécution réelle avec des résultats chiffrés vérifiés, ce
         mini-projet n'a pas encore été exécuté de bout en bout au moment
         de la rédaction de ce README. Toutes les commandes, accessions,
         sommes de contrôle et références bibliographiques ont été
         vérifiées individuellement (requêtes ENA/NCBI/PubMed réelles),
         mais AUCUN chiffre de résultat (N50, nombre de gènes AMR,
         topologie exacte de l'arbre) n'est inventé ni pré-rempli ici —
         voir RÉSULTATS ATTENDUS. L'exécution réelle est prévue sur une
         machine dédiée ; cette section et RÉSULTATS ATTENDUS seront mis
         à jour avec les chiffres obtenus une fois disponibles, sur le
         modèle de la section ACTUAL RESULTS de
         `final_project_ltee_ecoli/README.md`.

3 isolats sur 27 : un sous-échantillon de cette taille suffit pour
         illustrer la méthode (assemblage, AMR, typage, phylogénie à
         plusieurs feuilles) mais pas pour reproduire statistiquement la
         distribution clonale complète de l'étude (18 ST15 / 4 ST16 / 5
         autres sur 27) — voir GO FURTHER pour étendre aux 27.

Aucune démultiplication de qualité par profondeur avant SNP calling
         (comme déjà noté dans final_project_ltee_ecoli/README.md,
         section LIMITATIONS, pour un principe identique) : si la
         profondeur diffère notablement entre kpn_01/02/03, en tenir
         compte avant toute conclusion sur les distances phylogénétiques
         observées.

Kleborate : interface en ligne de commande différente entre v2 et v3
         (voir envs/amr_typing.yml) — la commande de la section 2.6 vise
         la syntaxe v2 (`--all`) ; vérifier `kleborate --help` avant de
         lancer si une version plus récente est installée.
```

---

MESSAGE AUX LECTEURS — EXÉCUTEZ CE PIPELINE VOUS-MÊME
------------------------------------------------------------
```text
Ce README explique et vérifie chaque commande, accession et référence
bibliographique — mais il ne remplace jamais l'exécution réelle.
Volontairement, aucun chiffre de résultat n'est pré-rempli ici (voir la
grille ci-dessous) : le rapport QUAST/BUSCO, le diagramme de Venn AMR, le
rapport Kleborate et la topologie de l'arbre phylogénétique de VOS 3
isolats sont à produire par VOUS, avec `snakemake --use-conda -j 4`
(section 3) ou pas à pas à la main (section 2).

C'est la seule façon d'apprendre réellement ce que fait chaque étape :
lire un rapport qu'on vient de générer soi-même, comparer un ST Kleborate
à la distribution publiée, ouvrir un arbre Newick qu'on vient de
calculer, apprend infiniment plus qu'un résultat déjà interprété par
quelqu'un d'autre. Prenez le temps d'exécuter le pipeline en entier —
comptez plusieurs heures pour l'assemblage, l'annotation Bakta et le
téléchargement de la base BUSCO — puis comparez vos valeurs à la grille
de vérification ci-dessous AVANT de chercher une explication toute
faite.

En cas d'échec d'une étape, le premier réflexe n'est PAS de relancer à
l'aveugle : chaque règle Snakemake écrit désormais son propre journal
dans `logs/<règle>/<échantillon>.log` (ex. `logs/assemble/kpn_01.log`,
`logs/annotate/kpn_02.log`...). Lire ce fichier dit presque toujours
directement ce qui a échoué et pourquoi.
```

---

# RÉSULTATS ATTENDUS / GRILLE DE VÉRIFICATION (à remplir par le lecteur)

```text
Après exécution complète, chaque isolat DEVRAIT correspondre à l'une des
catégories publiées par Tada et al. (2017) — voir VÉRITÉ DE TERRAIN
PUBLIÉE. Utiliser le tableau suivant comme grille d'auto-vérification,
PAS comme résultat pré-rempli :

| Échantillon | Gène de carbapénémase (amr_consensus) | ST (Kleborate) | Méthylase 16S (si présente) |
|---|---|---|---|
| kpn_01 (DRR076969) | à déterminer | à déterminer | à déterminer |
| kpn_02 (DRR076945) | à déterminer | à déterminer | à déterminer |
| kpn_03 (DRR076958) | à déterminer | à déterminer | à déterminer |
| PMK1 (référence, témoin) | NDM-1 (connu, Tada et al. 2017) | ST15 (connu) | — |

Une valeur qui NE correspond à AUCUNE des 4 carbapénémases publiées
(KPC-2/NDM-1/NDM-4/OXA-48), ou un ST hors de la liste {15, 16, 147, 307,
395, 2353}, n'est pas nécessairement une erreur (l'étude ne prétend pas
que la collection est exhaustive de toute variation possible), mais
mérite une relecture des étapes précédentes avant d'être pris pour un
résultat biologique confirmé.
```

TROUBLESHOOTING
------------------------------------------------------------
```text
SYMPTOM: `md5sum -c` échoue juste après un téléchargement
CAUSE: téléchargement interrompu, ou serveur ENA/NCBI temporairement
       indisponible ayant renvoyé une page d'erreur au lieu du fichier.
DIAGNOSIS: `ls -lh` sur le fichier téléchargé — une taille nettement
           inférieure à celle attendue (voir DATASET) confirme un
           téléchargement incomplet.
SOLUTION: relancer le même `wget -c` (reprise de téléchargement) puis
          revérifier le md5 ; en dernier recours, essayer le miroir NCBI
          SRA (module 08, §5.1) pour les reads.
PREVENTION: ne jamais enchaîner une étape suivante avant que `md5sum -c`
            ait confirmé "OK".
```
```text
SYMPTOM: `bakta_db download` ou `busco` semble bloqué très longtemps
CAUSE: téléchargement de plusieurs centaines de Mo à ~1,2 Go en arrière-plan,
       sans barre de progression toujours visible selon le terminal.
DIAGNOSIS: `du -sh data/bakta_db/` (ou le dossier busco_downloads/) dans
           un second terminal pour confirmer que la taille progresse.
SOLUTION: patienter ; interrompre (Ctrl+C) uniquement si la taille ne
          progresse plus du tout après plusieurs minutes.
PREVENTION: lancer ces deux téléchargements avant de s'absenter, plutôt
            qu'en tout dernier au milieu d'une session chronométrée.
```
```text
SYMPTOM: `kleborate` échoue avec une erreur d'option inconnue (ex. --all)
CAUSE: version 3 installée, dont l'interface a changé vers un système de
       presets (-p/--preset) — voir envs/amr_typing.yml.
DIAGNOSIS: `kleborate --version` puis `kleborate --help`.
SOLUTION: adapter la commande de la section 2.6 selon la syntaxe
          affichée par --help (ex. `-p kpsc` en v3 pour le complexe
          d'espèces K. pneumoniae).
PREVENTION: toujours lancer `--help` sur un outil récemment mis à jour
            avant de copier une commande d'un README, y compris celui-ci.
```

GO FURTHER
------------------------------------------------------------
```text
Topic: étendre aux 27 isolats de l'étude
Topics to explore: ajouter les 24 accessions restantes de PRJDB5317 à
                    config.yaml (aucune autre modification du Snakefile
                    n'est nécessaire, voir section DECISIONS de
                    final_project_ltee_ecoli/README.md sur la même
                    logique de config.yaml sans valeur codée en dur) ;
                    comparer la distribution ST15/ST16 obtenue sur 27
                    isolats à celle publiée (18/4).

Topic: comparer Kleborate v2 et v3
Topics to explore: exécuter les deux versions sur les mêmes contigs et
                    comparer les rapports — utile pour comprendre
                    concrètement une migration de version d'outil en
                    conditions réelles (rappel du principe déjà illustré
                    par le statut Prokka → Bakta, 14_genome_annotation/).

Topic: validation croisée de phylogénie
Topics to explore: reconstruire l'arbre avec IQ-TREE (modèle sélectionné
                    automatiquement) plutôt que FastTree, et comparer les
                    topologies obtenues sur les mêmes 4 feuilles.
```

DOCUMENTATION
------------------------------------------------------------
- ENA Portal API (recherche de runs/études) — https://www.ebi.ac.uk/ena/portal/api/
- NCBI Datasets, GCA_000764615.1 — https://www.ncbi.nlm.nih.gov/datasets/genome/GCA_000764615.1/
- Bakta — https://github.com/oschwengers/bakta
- ABRicate — https://github.com/tseemann/abricate
- AMRFinderPlus — https://github.com/ncbi/amr/wiki
- Kleborate — https://github.com/klebgenomics/Kleborate
- Snippy — https://github.com/tseemann/snippy
- Snakemake — https://snakemake.readthedocs.io/

SCIENTIFIC REFERENCES
------------------------------------------------------------
- Tada T, Tsuchiya M, Shimada K, Nga TTT, Thu LTA, Phu TT, Ohmagari N,
  Kirikae T (2017). "Dissemination of Carbapenem-resistant Klebsiella
  pneumoniae clinical isolates with various combinations of
  Carbapenemases (KPC-2, NDM-1, NDM-4, and OXA-48) and 16S rRNA
  Methylases (RmtB and RmtC) in Vietnam." *BMC Infectious Diseases*,
  17(1):467. DOI: 10.1186/s12879-017-2570-y. PMC5496404. (source du jeu
  de données DRA005275/PRJDB5317 et de la référence PMK1 utilisée pour
  l'appel de SNP — voir DATASET et VÉRITÉ DE TERRAIN PUBLIÉE ci-dessus)

```text
NOTE DE VÉRIFICATION : les accessions (DRR076969, DRR076945, DRR076958),
         l'assemblage de référence (GCA_000764615.1), les sommes de
         contrôle MD5 (ENA/NCBI) et la citation ci-dessus ont tous été
         vérifiés par requête directe aux API publiques ENA/NCBI/PubMed
         au moment de la rédaction de ce README — aucune accession ni
         aucun chiffre n'a été deviné ou halluciné.
```
