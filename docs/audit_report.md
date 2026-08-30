# Rapport d'audit initial — dépôt `Linux-command`

Date de l'audit : 2026-08-22
Dépôt : https://github.com/DEDJIABDOUL/Linux-command (branche `main`, working tree propre)

Ce rapport constitue la **Phase 1 (Audit)** du programme de transformation du dépôt en
parcours universitaire Linux → Bioinformatique. Aucune restructuration massive n'a été
effectuée : conformément à la consigne, ce document précède toute implémentation.

---

## 1. CURRENT STRUCTURE

```text
Linux-command/                      (repo git, origin = DEDJIABDOUL/Linux-command)
├── README.md                       (6.9 Ko — décrit le jeu de données linux/, PAS un README de projet)
├── linux_commands_beginner.md      (18.3 Ko — guide débutant Linux → FASTA/FASTQ → Bash → Conda)
└── linux/                          (jeu de données d'entraînement)
    ├── annotations.tsv             (121 lignes, 6 colonnes)
    ├── exercice_sequences.fasta    (419 lignes, 22 séquences)
    ├── genome.fasta                (419 lignes, copie de exercice_sequences.fasta)
    ├── proteins.fasta              (103 lignes, 25 protéines)
    ├── reads.fastq                 (2000 lignes = 500 reads)
    ├── sample_01.fastq.gz          (1200 reads compressés)
    ├── sample_02.fastq.gz          (800 reads compressés)
    ├── sample_03.fastq.gz          (1500 reads compressés)
    └── transcripts.fasta           (217 lignes, 40 ARNm)
```

Hors dépôt, dans le dossier parent (`C:\Users\PC\Music\pipeline\`, **non versionné, non
inclus dans le repo Git**) :

```text
installation_and_execution.txt      (4.2 Ko — notes brutes d'installation/exécution
                                      LongQC, Porechop, NanoFilt, Canu, Minimap2,
                                      Racon, QUAST pour un test SARS-CoV-2 Nanopore)
```

**Point d'attention n°1** : ce fichier n'est pas dans le dépôt Git. Il faudra décider
avec l'utilisateur s'il doit être (a) intégré au dépôt (probablement dans un module
`09_quality_control/` ou `11_de_novo_assembly/` légacy), (b) archivé tel quel comme
référence historique, ou (c) laissé hors dépôt. Je ne le déplace pas sans confirmation.

---

## 2. CURRENT CONTENT — synthèse

### `README.md`
Sert en réalité de documentation du jeu de données `linux/`. Contient un tableau des
fichiers, une description des particularités volontaires du jeu de données (longueurs
variables, régions soft-maskées, motif implanté, adaptateurs Illumina dans les reads),
puis 13 exercices corrigés (comptage de séquences, `cut`/`sort`/`uniq` sur headers,
`grep -i`, coloration, FASTQ, compression, split par séquence, TSV, boucle Bash, script
complet, SeqKit, piège `grep -c` vs occurrences réelles).

**Qualité** : contenu correct, pédagogiquement solide, réponses vérifiables. Mais ce
n'est pas un README de projet — un visiteur du dépôt sur GitHub n'a aucune vue
d'ensemble du projet, de son objectif, ni de son plan d'apprentissage.

### `linux_commands_beginner.md`
Guide en 30 sections : terminal, navigation, exploration de fichiers, `find`, `wc`,
FASTA, FASTQ, `grep`, coloration, `sed`, tailles/`du`/`df`, compression `gzip`/`zcat`,
redirections, pipes, `cut`/`sort`/`uniq`/`tr`/`awk`, split FASTA par chromosome,
SeqKit, gestion des processus/ressources, permissions, variables Bash, boucles,
script Bash, `which`/`PATH`, Conda, panorama des outils bioinfo (FastQC, MultiQC,
fastp, Cutadapt, SeqKit, BWA, Bowtie2, Minimap2, STAR, HISAT2, Samtools, BCFtools,
Bedtools, BLAST), workflow RNA-seq conceptuel, ordre d'apprentissage recommandé,
tableau de référence rapide, conclusion.

**Qualité** : très bonne base pédagogique, progression logique, exemples concrets.
Correspond en gros aux modules cibles `01_linux_basics` à `04_bash_scripting` +
un aperçu de `05_biological_formats`, `06_environment_management` et `09_quality_control`.

### `linux/` (dataset)
Jeu de données synthétique bien conçu : diversité d'organismes, longueurs variables,
régions soft-maskées, blocs de N, motif `ATGCGT` implanté à positions connues,
adaptateurs Illumina intégrés aux reads. Sert de base réutilisable pour les futurs
modules `03_text_processing`, `05_biological_formats`, `09_quality_control`.

### `installation_and_execution.txt` (hors dépôt)
Notes d'installation/exécution non structurées (mélange français/anglais), sans
explication de commande, avec des chemins placeholders (`/path/to/...`), pour un
pipeline Nanopore : Miniconda → LongQC → Porechop → NanoFilt → Canu → Minimap2 →
Racon → QUAST, appliqué à un test SARS-CoV-2 (SRA `SRR18392380`, accession réelle
et vérifiable). Contient une section troubleshooting minimale (curl/git/make/pip/gcc
manquants).

---

## 3. STRENGTHS

La base pédagogique en français est déjà solide et correcte sur les
fondamentaux Linux/Bash. Le jeu de données synthétique est bien pensé et
réutilisable pour plusieurs modules futurs. Les exercices proposent des
réponses attendues et vérifiables, une méthodologie déjà alignée avec la
charte pédagogique demandée (OBJECTIVE → COMMAND → EXPECTED RESULT →
INTERPRETATION). Les limites des outils textuels sont explicitement
mentionnées (`grep`/`awk` face à `seqkit` pour un motif à cheval sur deux
lignes), dans l'esprit exact de la consigne « ne jamais présenter un
outil comme universel ». Une accession SRA réelle et vérifiable est déjà
utilisée (`SRR18392380`), cohérente avec l'exigence de ne jamais inventer
d'accession. Enfin, le dépôt Git est propre et connecté à un remote
GitHub existant.

## 4. WEAKNESSES

Aucun lien vers une documentation officielle n'apparaît nulle part dans
le dépôt, en violation de l'exigence §44 : chaque outil cité (FastQC,
MultiQC, fastp, Cutadapt, BWA, Bowtie2, Minimap2, STAR, HISAT2, Samtools,
BCFtools, Bedtools, BLAST, Conda, SeqKit) est dépourvu d'URL de
référence. Aucune référence scientifique n'est présente (aucun DOI,
aucune publication citée). Le format pédagogique détaillé demandé
(COMMAND / PURPOSE / SYNTAX / INPUT / OPTIONS / OUTPUT / INTERPRETATION /
COMMON ERRORS / DOCUMENTATION / EXERCISE) n'est pas appliqué : le guide
actuel reste plus proche d'un aide-mémoire commenté que d'un support
universitaire complet par commande. Aucune section Troubleshooting
structurée (SYMPTOM/CAUSE/DIAGNOSIS/SOLUTION/PREVENTION) n'existe dans
les fichiers `.md` actuels. Le `README.md` du dépôt ne joue pas son rôle
de vitrine/plan de cours (§68). Aucune arborescence de modules
(`01_linux_basics/`, etc.) n'existe : tout est plat, avec deux fichiers
`.md` à la racine. Aucun `.gitignore` n'est en place, ce qui expose au
risque de committer par erreur de gros fichiers bruts si des
téléchargements réels sont ajoutés plus tard. Aucun environnement Conda
n'est documenté (`envs/*.yml`), ni aucun script d'automatisation
(`scripts/`), workflow Snakemake/Nextflow ou test (`bash -n`,
ShellCheck). Enfin, `installation_and_execution.txt` n'est pas dans le
dépôt et n'est pas structuré pédagogiquement : ni explication de
commande, ni interprétation de sortie.

## 5. OUTDATED / TO-VERIFY CONTENT

Dans `installation_and_execution.txt` :

| Élément | Constat | Statut |
|---|---|---|
| `python=3.7` | Version Python très ancienne (EOL) | À remplacer par une version supportée lors de la réécriture du module environnements |
| `pandas=0.24.0`, `matplotlib=2.1.2` | Pins très anciens hérités d'une doc d'installation LongQC historique | À revérifier — probablement obsolètes |
| `minimap2 v2.24` (lien de téléchargement figé) | Version figée dans un lien de release GitHub | À revérifier — une version plus récente existe très probablement |
| Porechop | Outil de l'auteur rrwick ; **de mémoire générale, ce dépôt a été marqué comme non maintenu par son auteur**, qui oriente vers des alternatives (p. ex. un fork maintenu, ou le trimming d'adaptateurs intégré aux basecallers récents) | **NE PAS AFFIRMER SANS VÉRIFICATION WEB** — à confirmer par recherche officielle avant d'écrire le module Nanopore QC (§50 de la charte) |
| NanoFilt | Même auteur (wdecoster) ; **de mémoire générale, un successeur plus rapide (réécriture) existe** | **À vérifier officiellement** avant recommandation |
| LongQC | Outil plus confidentiel, activité de maintenance incertaine | **À vérifier officiellement** (dernière release, issues ouvertes) |

**Je ne certifie aucun de ces statuts dans ce rapport** : ce sont des signaux à
vérifier via recherche officielle (dépôt GitHub, PyPI/Bioconda, documentation) au
moment d'écrire le module QC Nanopore, conformément à la règle « ne jamais présenter
un outil obsolète comme moderne sans avertissement » et « ne jamais inventer un statut ».

> **MISE À JOUR (2026-08-22, lors de la rédaction de `09_quality_control/` et
> `10_adapter_trimming_filtering/`)** — statuts vérifiés directement sur les dépôts
> officiels (fetch GitHub + flux de releases) :
> - **Porechop** : confirmé abandonware, déclaré par l'auteur en octobre 2018.
>   Alternative maintenue identifiée : Porechop_ABI (fork communautaire, publié dans
>   *Bioinformatics Advances* 2023, DOI 10.1093/bioadv/vbac085).
> - **NanoFilt** : confirmé non maintenu ; successeur officiel identifié : chopper
>   (même auteur, décrit dans *Bioinformatics* 2023, DOI 10.1093/bioinformatics/btad311).
> - **LongQC** : **contrairement à l'hypothèse de prudence ci-dessus, LongQC est
>   activement maintenu** — dernière release 1.2.3 publiée le 2026-03-25 (vérifié via
>   le flux de releases GitHub officiel). Il ne doit pas être présenté comme obsolète.
> Détail complet dans `docs/tools_reference.md` et dans les deux modules concernés.

> **MISE À JOUR (2026-08-22, lors de la rédaction de `11_de_novo_assembly/`,
> `12_sequence_alignment/`, `13_assembly_quality/`)** — statuts des outils restants du
> fichier legacy, vérifiés directement sur les dépôts officiels :
> - **Canu** : les développeurs ont déclaré la release v2.3 (2024-12-17) comme
>   définitivement la dernière (« Canu is all but obsolete now »). Recommandation
>   actualisée : Flye pour tout nouvel assemblage long-read.
> - **Minimap2** : actif, mais la version figée dans le fichier legacy (v2.24, 2022)
>   est très en retard sur la version actuelle (2.31, 2026-05-19).
> - **Racon** : le dépôt `isovic/racon` référencé dans le fichier legacy n'est plus
>   maintenu et redirige vers le nouveau dépôt officiel `lbcb-sci/racon`.
> - **QUAST** : actif, version actuelle 5.3.0 — aucune alerte.
> Ceci clôt la reprise complète du pipeline documenté dans
> `legacy/installation_and_execution.txt`.

## 6. INCORRECT CONTENT

Aucune commande manifestement fausse détectée dans `linux_commands_beginner.md` ou
`README.md`. Le contenu Linux/Bash de base est techniquement correct. Aucune correction
requise à ce stade sur ces deux fichiers.

## 7. MISSING CONTENT (par rapport à l'architecture cible)

Modules totalement absents du dépôt à ce jour :
`00_orientation`, `02_linux_for_bioinformatics` (partiellement couvert), `06_environment_management`
(Conda mentionné mais non structuré en environnements dédiés), `07_project_organization`,
`08_data_acquisition` (aucun téléchargement réel documenté — pas de SRA Toolkit, ENA,
NCBI datasets), `09_quality_control` → `26_hpc`, `datasets/` structuré, `scripts/`,
`envs/`, `workflows/`, `docs/` (créé aujourd'hui, vide sauf ce rapport), `projects/`.

Aucun des domaines suivants n'est encore couvert : QC Illumina/Nanopore/PacBio structuré,
trimming argumenté, assemblage, alignement, annotation, RNA-seq, ChIP-seq, méthylation,
GWAS, variant calling, protéomique, métagénomique, Snakemake, Nextflow, nf-core,
conteneurs, Git/GitHub pédagogique, tableaux de référence (`docs/tools_reference.md`,
`docs/formats_reference.md`, etc.), projets de fin de module.

## 8. TOOL STATUS (aperçu, à approfondir module par module)

| Outil déjà mentionné | Où | Statut apparent |
|---|---|---|
| SeqKit, FastQC, MultiQC, fastp, Cutadapt, BWA, Bowtie2, Minimap2, STAR, HISAT2, Samtools, BCFtools, Bedtools, BLAST, Conda | `linux_commands_beginner.md` (liste, sans lien) | Outils standards actifs, réputation solide — liens de doc officielle à ajouter et versions à vérifier lors de la rédaction du module correspondant |
| Canu, Racon, QUAST | `installation_and_execution.txt` | Outils actifs, maintenus — liens déjà présents dans le fichier (GitHub Canu, ReadTheDocs Canu, GitHub Racon, QUAST sourceforge) mais à re-vérifier |
| LongQC, Porechop, NanoFilt | `installation_and_execution.txt` | Statut de maintenance incertain — **à vérifier avant réutilisation en contenu "moderne"** (voir §5) |

## 9. DOCUMENTATION STATUS

Aucun lien de documentation officielle n'est actuellement présent dans les fichiers
`.md` du dépôt. Trois URLs figurent dans `installation_and_execution.txt` (Canu ×2,
Racon, QUAST) mais sans le format à trois niveaux demandé (doc officielle / dépôt
source / publication scientifique).

## 10. SCIENTIFIC REFERENCES

Aucune référence scientifique (DOI, auteur, année, journal) n'est présente dans le
dépôt actuel. Ce chantier est entièrement à construire, outil par outil, module par
module, en respectant la règle de non-invention des références (§98).

## 11. PEDAGOGICAL GAPS

Aucune section « objectif biologique » ne précède les commandes (§79).
Aucune mise en garde méthodologique n'est formulée (§80 : mapping rate
élevé ≠ conclusion biologique correcte, etc.), le guide restant
actuellement au niveau syntaxique. Aucun exercice n'utilise de vraies
données publiques, au-delà de l'accession SRA citée dans les notes
d'installation. Aucun mini-projet structuré n'existe (§57). Enfin,
aucun tableau central n'est présent (`docs/tools_reference.md`,
`docs/formats_reference.md`, `docs/linux_commands_reference.md`,
`docs/pipelines_reference.md`).

---

## 12. PROPOSED ARCHITECTURE (adaptée à l'existant)

Le contenu actuel n'est pas à jeter : il correspond à une bonne ébauche des tout
premiers modules. Proposition de mapping vers l'architecture cible :

```text
Linux-command/
│
├── README.md                    ← À RÉÉCRIRE en vitrine de projet (§68)
├── docs/
│   ├── audit_report.md          ← CE FICHIER (créé)
│   ├── tools_reference.md       ← à créer progressivement
│   ├── formats_reference.md     ← à créer progressivement
│   ├── linux_commands_reference.md
│   └── pipelines_reference.md
│
├── 00_orientation/               ← à créer (objectifs, prérequis, plan de cours)
├── 01_linux_basics/               ← extraire les sections 1–5, 18–19, 23 de
│                                    linux_commands_beginner.md, réécrire au format complet
├── 02_linux_for_bioinformatics/   ← sections 6–8 (FASTA/FASTQ) reformattées
├── 03_text_processing/            ← sections 13–16 (grep/sed/awk/cut/sort/uniq appliqués)
├── 04_bash_scripting/             ← sections 20–22
├── 05_biological_formats/         ← nouveau : FASTA/FASTQ approfondi + SAM/BAM/VCF/BED/GFF/GTF
├── 06_environment_management/     ← section 24 + reprise structurée de
│                                    installation_and_execution.txt (Conda/Mamba/Bioconda)
├── 07_project_organization/       ← nouveau
├── 08_data_acquisition/           ← nouveau (SRA Toolkit, ENA, NCBI — inclut l'accession
│                                    SRR18392380 déjà utilisée dans le fichier hors-dépôt)
├── 09_quality_control/            ← reprise structurée de LongQC/Porechop/NanoFilt
│                                    (avec statut de maintenance vérifié) + FastQC/MultiQC
├── 10_adapter_trimming_filtering/ ← Porechop/NanoFilt remis en contexte + fastp/Cutadapt
├── 11_de_novo_assembly/           ← Canu (repris) + Flye/SPAdes/MEGAHIT
├── 12_sequence_alignment/         ← Minimap2 (repris) + BWA-MEM2/Bowtie2/STAR/HISAT2
├── 13_assembly_quality/           ← QUAST (repris) + BUSCO
├── 14_genome_annotation/ … 26_hpc/  ← nouveaux modules, aucun contenu existant à migrer
│
├── linux/                        ← CONSERVÉ tel quel (dataset déjà bien conçu)
├── datasets/                     ← nouveau (autres datasets par domaine, au besoin)
├── scripts/                      ← nouveau
├── envs/                         ← nouveau (qc.yml, assembly.yml, etc.)
├── workflows/                    ← nouveau (Snakemake/Nextflow, plus tard)
├── .gitignore                    ← à créer (exclure *.fastq(.gz), *.bam, *.cram, *.sra, refs volumineuses)
└── projects/                     ← nouveau (mini-projets + projet final)
```

Rien n'est supprimé : `linux_commands_beginner.md` et le contenu de `README.md` actuel
seront **répartis** dans les modules 01–06 (avec enrichissement selon la charte), pas
effacés. `installation_and_execution.txt` sera **intégré** (pas simplement copié) dans
`06_environment_management/` et `09_quality_control/`/`10_adapter_trimming_filtering/`/
`11_de_novo_assembly/`/`12_sequence_alignment/`/`13_assembly_quality/`, une fois les
statuts d'outils vérifiés.

## 13. IMPLEMENTATION ROADMAP (proposée, incrémentale)

1. Confirmer avec l'utilisateur le périmètre de démarrage (voir question posée en fin
   de message — le programme complet représente ~27 phases, largement au-delà d'une
   seule session).
2. Créer le squelette d'architecture minimal (dossiers vides + `README.md` projet +
   `.gitignore`) — action réversible, non destructive.
3. Migrer/enrichir `01_linux_basics` à `04_bash_scripting` à partir du contenu existant,
   au format pédagogique complet, avec liens de documentation officielle vérifiés.
4. Vérifier par recherche officielle le statut de LongQC/Porechop/NanoFilt avant de
   rédiger `09_quality_control` et `10_adapter_trimming_filtering`.
5. Construire `05_biological_formats` à `13_assembly_quality` en réutilisant/étendant
   `installation_and_execution.txt`.
6. Poursuivre module par module selon les phases 14 à 27 du programme, chacune validée
   avant de passer à la suivante.

---

**Conclusion de l'audit** : le dépôt dispose d'une base pédagogique correcte mais
partielle (≈ 15 % du programme cible), sans documentation officielle liée, sans
références scientifiques, sans architecture modulaire, et avec un fichier
d'installation utile mais non versionné et non structuré. La transformation complète
en parcours universitaire est un chantier de grande ampleur qui doit être mené module
par module, jamais en une seule passe.

---

## 14. CLÔTURE DE LA FEUILLE DE ROUTE 01→26 (mise à jour 2026-08-22)

Depuis la rédaction de l'audit ci-dessus, les 26 modules de l'architecture cible
(section 12) ont été rédigés intégralement, dans l'ordre, chacun avec le format
pédagogique complet (OBJECTIVE/COMMAND/PURPOSE/.../TROUBLESHOOTING/DOCUMENTATION/
SCIENTIFIC REFERENCES), des liens de documentation officielle vérifiés
individuellement par recherche web avant citation (aucune URL inventée), des
références scientifiques vérifiées individuellement (auteurs, année, DOI), et,
pour chaque outil issu du fichier `legacy/installation_and_execution.txt`
(LongQC, Porechop, NanoFilt, Canu, Minimap2, Racon, QUAST), un statut de
maintenance vérifié à la date de rédaction (voir mises à jour ci-dessus et
`docs/tools_reference.md`).

Découvertes notables lors de cette vérification systématique : LongQC est
activement maintenu, contrairement à l'hypothèse prudente initiale. Porechop
est officiellement abandonware depuis 2018, déclaré comme tel par l'auteur.
NanoFilt est officiellement remplacé par chopper, du même auteur. Canu a
atteint sa dernière release (v2.3, déclarée définitive par les développeurs) ;
Flye est recommandé pour tout nouvel assemblage long-read. Prokka est
officiellement remplacé par Bakta, une transition annoncée par l'auteur de
Prokka lui-même. Racon a changé de dépôt officiel (`isovic/racon` puis
`lbcb-sci/racon`). Enfin, le développement de MACS s'est déplacé de MACS2 vers
MACS3.

Le fichier `legacy/installation_and_execution.txt` a été mis à jour (note de
provenance) pour pointer vers chacun des modules qui reprennent désormais son
contenu de façon vérifiée et modernisée.

**Reste à faire** (non traité dans cette session, volontairement laissé pour une
phase ultérieure) : `projects/` (mini-projets par domaine + projet final
intégrateur, voir `projects/README.md`), les tableaux centraux complémentaires
(`docs/formats_reference.md`, `docs/linux_commands_reference.md`,
`docs/pipelines_reference.md` — seul `docs/tools_reference.md` a été construit,
au fil des modules), et le commit Git de l'ensemble de ce travail (resté en
attente, à la demande explicite de l'utilisateur qui commit manuellement).

---

## 15. CORRECTIONS DE COHÉRENCE (mise à jour 2026-08-22)

Après relecture demandée par l'utilisateur, deux passes de correction ont été
effectuées sur l'ensemble du dépôt :

1. **Nettoyage stylistique** : suppression des puces de prose superflues (listes
   à tiret converties en phrases fluides) dans `README.md`, `00_orientation/README.md`,
   ce rapport, et deux modules (`02_linux_for_bioinformatics/`, `05_biological_formats/`).
   Les listes légitimes (DOCUMENTATION, SCIENTIFIC REFERENCES) ont été conservées.
   Aucun emoji n'a jamais été présent dans le dépôt (vérifié).
2. **Correction d'incohérences factuelles** : plusieurs sections « NEXT MODULE »
   et une note dans `12_sequence_alignment/` renvoyaient encore vers des modules
   marqués « planifié », alors que ces modules avaient depuis été rédigés dans la
   même session. Corrigé dans `06`, `08`, `12`, `13`, `14`, `15`, `16`, `17`, `18`,
   `19`, `20`, `21`, `23`, `24`, `25`, ainsi que dans `00_orientation/README.md`
   (phrase d'introduction de la feuille de route) et `docs/tools_reference.md`
   (paragraphe d'introduction).
3. **Ajout de `scripts/`** : dossier promis dans l'architecture proposée
   (section 12 ci-dessus) mais jamais livré. Contient désormais `stats.sh` et
   `pipeline_template.sh`, les versions réelles et testées (`bash -n` +
   exécution sur `linux/`) des scripts expliqués dans `04_bash_scripting/README.md`,
   plus `scripts/README.md`. Référencé depuis le module 04 et depuis
   `README.md` (table « Architecture du dépôt »).

## 16. RÈGLES DE STYLE ET DE RÉFÉRENCEMENT (mise à jour 2026-08-22)

Sur demande explicite de l'utilisateur, deux règles supplémentaires s'appliquent
désormais à tous les modules, passés et futurs :

1. **Pas de bannière `====`** : les titres de module utilisent un simple
   titre Markdown (`# NN — Titre`), jamais un encadrement en `====`. Retiré
   des 26 modules (`01_linux_basics/` à `26_hpc/`), y compris le bloc de
   clôture de `26_hpc/README.md`.
2. **Références toujours à jour** : quand un outil dispose d'un article
   fondateur ancien ET d'un article de mise à jour plus récent décrivant la
   version réellement utilisée aujourd'hui, les DEUX doivent être cités,
   avec une note distinguant leur rôle (fondateur / état actuel) — jamais
   l'un à la place de l'autre (voir §52 de la charte pédagogique originale :
   FOUNDATIONAL PAPER vs RECENT RECOMMENDATION). Appliqué rétroactivement à
   BLAST (Altschul 1990 + Camacho et al. 2009 pour BLAST+), et à SAMtools
   (Li et al. 2009 + Danecek et al. 2021 « Twelve years of SAMtools and
   BCFtools ») dans `05_biological_formats/` et `12_sequence_alignment/`.
   Cette règle continuera d'être appliquée à chaque nouvelle citation.

## 17. PROJET FINAL INTÉGRATEUR LIVRÉ (mise à jour 2026-08-30)

Le premier des deux chantiers listés en section 14 (« Reste à faire »)
est désormais livré : `projects/final_project_ltee_ecoli/`, un projet
qui applique bout à bout le parcours `01_linux_basics/` → `26_hpc/` sur
une vraie question biologique.

**Choix du sujet** : accumulation de mutations dans la population
*Escherichia coli* Ara-3 de la Long-Term Evolution Experiment (Lenski
lab), entre les générations 5 000, 15 000 et 50 000, par rapport à
l'ancêtre REL606. Choisi après comparaison avec deux autres candidats
(RNA-seq différentiel chez la levure ; assemblage/annotation Nanopore
réutilisant `SRR18392380`), retenu pour sa couverture maximale du
parcours (acquisition → QC → trimming → alignement → variant calling →
annotation → synthèse statistique) et pour l'existence d'une vérité
biologique publiée et vérifiable, plutôt qu'un simple VCF isolé sans
contexte interprétable.

**Données et références, vérifiées par recherche officielle avant
utilisation** (jamais d'accession ni de DOI inventés) :
- 3 accessions SRA réelles (`SRR2589044`, `SRR2584863`, `SRR2584866`),
  également utilisées par la leçon officielle Data Carpentry
  *Wrangling and Processing for Genomics* — double vérifiabilité.
- Référence *E. coli* B str. REL606 : `CP000819.1` /
  assemblage `GCA_000017985.1`.
- Trois références scientifiques à rôles distincts : Jeong et al. 2009
  *J Mol Biol* (génome de référence), Blount et al. 2008 *PNAS*
  (découverte fondatrice du phénotype Cit+ dans Ara-3), Blount et al.
  2012 *Nature* (base génomique du trait, état actuel/mécanisme).

**Piège de citation écarté pendant la vérification** : Barrick et al.
2009 (*Nature*, DOI 10.1038/nature08480), qui porte sur la même
expérience LTEE mais séquence la population **Ara-1** et non Ara-3, a
été identifié comme non pertinent pour ce projet et volontairement
exclu des références — malgré une ressemblance de sujet qui aurait pu
conduire à une citation incorrecte.

**Décisions méthodologiques documentées dans le README du projet** :
`bcftools csq` choisi plutôt que VEP/SnpEff pour l'annotation
fonctionnelle (génome bactérien custom sans base précompilée) ;
`samtools markdup` choisi plutôt que Picard MarkDuplicates pour éviter
une dépendance croisée à `envs/chipseq.yml`.

**Fichiers créés** : `projects/final_project_ltee_ecoli/{README.md,
config.yaml, Snakefile, data/metadata/samples.tsv,
scripts/summarize_variants.py}`, `envs/data_acquisition.yml` (nouveau —
comblait un manque réel : le module 08 documentait `prefetch`/
`fasterq-dump` sans environnement Conda dédié). `envs/python_bio.yml`
étendu avec `matplotlib` et `pyyaml`, utilisés par
`scripts/summarize_variants.py` (les deux ajoutés à
`docs/tools_reference.md`, avec documentation officielle vérifiée).
`projects/README.md` et `README.md` (racine) mis à jour en conséquence.

**Limite explicitement documentée dans le projet** : aucun jeu de
variants de vérité terrain publié n'existe pour ces 3 clones précis —
contrairement à un jeu de benchmark formel. L'interprétation attendue
reste une tendance illustrative (accumulation croissante de variants
avec la génération), pas un résultat statistiquement validé en soi.

**Vérification effectuée dans cette session (rédaction)** : aucun outil
bioinformatique n'étant installé au moment de la rédaction, seule une
vérification à froid a été menée : `scripts/summarize_variants.py`
testé de bout en bout contre un VCF synthétique local, `Snakefile` relu
manuellement contre la syntaxe du module 24 et la documentation
officielle Snakemake. Cette relecture a détecté et corrigé un vrai bug
de correction biologique : la règle `align` triait par coordonnée avant
`samtools fixmate`, qui exige des reads groupés par nom — corrigé en
retirant le tri prématuré (voir commentaires dans le `Snakefile`,
règles `align`/`markdup`).

**Exécution réelle effectuée ensuite, sur demande explicite de
l'utilisateur** (mise à jour 2026-08-30, même session) : bwa-mem2,
samtools, bcftools, fastp installés via Conda ; les 3 échantillons réels
téléchargés depuis ENA (confirmés : 263/374/634 Mo, total 1,27 Go,
tailles identiques à celles annoncées par l'API ENA avant
téléchargement) ; pipeline complet exécuté (trimming → alignement →
dédoublonnage → variant calling → filtrage → annotation) en ~4 minutes
sur les 3 échantillons. Résultat réel : 42 variants filtrés (gen5000),
29 (gen15000), 812 (gen50000) — profondeurs moyennes respectives 56,7x,
79,3x, 141,7x. Le bond à gen50000 (×28, très supérieur au facteur de
profondeur ×1,8) a été recoupé avec la littérature (recherche officielle
menée avant toute affirmation) : Maddamsetti & Grant (2020, *Genome
Biology and Evolution*, DOI 10.1093/gbe/evaa178) documentent un
phénotype hypermutateur (défaut *mutS*) apparu dans Ara-3 vers la
génération 34 750 — entre les échantillons gen15000 et gen50000 de ce
projet, ce qui rend le résultat observé cohérent avec une explication
biologique publiée plutôt qu'un simple artefact. Détail complet et
limites (profondeurs inégales, non contrôlées) dans
`projects/final_project_ltee_ecoli/README.md`, section 5 (ACTUAL
RESULTS). Fichiers de résultats (`results/`) volontairement non
versionnés (`.gitignore`), conservés localement uniquement.

**Reste à faire** : les mini-projets par domaine (toujours en attente,
voir `projects/README.md`) et les trois tableaux de référence
complémentaires (`docs/formats_reference.md`,
`docs/linux_commands_reference.md`, `docs/pipelines_reference.md`),
non traités dans cette session — hors périmètre de la demande.
