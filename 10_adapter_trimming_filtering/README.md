============================================================
MODULE 10 — TRIMMING D'ADAPTATEURS ET FILTRAGE QUALITÉ
============================================================

OBJECTIVE
------------------------------------------------------------
Nettoyer des reads bruts (retrait d'adaptateurs, filtrage qualité/longueur)
en choisissant des outils **actuellement maintenus**, avec des paramètres
justifiés par la technologie et le protocole — jamais par une valeur
« habituelle » copiée sans réflexion.

PREREQUISITES
------------------------------------------------------------
`09_quality_control/` (ce module s'appuie directement sur les signaux de
QC interprétés précédemment).

RÈGLE DE PARAMÉTRAGE
------------------------------------------------------------
```text
Ne jamais écrire -q 20 ou --minimum-length 50 seulement parce que c'est
une valeur courante. Toujours pouvoir répondre à :
  Pourquoi cette valeur ?
  Basée sur quoi (le rapport QC du module 09, le protocole, la
  littérature, la documentation de l'outil) ?
  Adaptée à quelle technologie, quel objectif d'analyse ?
```

---

# 0. Environnement de ce module

```bash
conda env create -f envs/trimming.yml
conda activate trimming
```

```text
CONTENU: cutadapt, fastp, chopper (voir envs/trimming.yml pour le détail).
         Porechop/NanoFilt (section 1) ne sont pas inclus : ce sont des
         outils legacy non maintenus, à installer séparément uniquement
         pour reproduire le fichier `legacy/installation_and_execution.txt`.
```

# 1. Statut vérifié des outils Nanopore présents dans ce dépôt

Le fichier `legacy/installation_and_execution.txt` utilise Porechop puis
NanoFilt pour un pipeline Nanopore. **Statuts vérifiés le 2026-08-22**,
directement sur les dépôts officiels (voir `docs/tools_reference.md`) :

```text
Porechop (rrwick/Porechop)
  STATUT: abandonware, déclaré explicitement par l'auteur en octobre 2018
          (« I'm going to now officially declare Porechop as
          abandonware »), aucune mise à jour depuis.
  VALEUR PÉDAGOGIQUE: reste utile pour comprendre le PRINCIPE du trimming
          d'adaptateurs Nanopore par recherche de motifs connus.
  RECOMMANDATION PRODUCTION: NE PAS l'utiliser tel quel dans un nouveau
          pipeline sans en avoir conscience. Alternative maintenue :
          Porechop_ABI (fork communautaire, pas un successeur officiel de
          l'auteur original), qui ajoute une découverte automatique
          d'adaptateurs inconnus.
          Dépôt : https://github.com/bonsai-team/Porechop_ABI
          Publication : Bonenfant Q, Noé L, Touzet H (2023).
          "Porechop_ABI: discovering unknown adapters in Oxford Nanopore
          Technology sequencing reads for downstream trimming."
          Bioinformatics Advances, 3(1):vbac085.
          DOI: 10.1093/bioadv/vbac085
  NOTE COMPLÉMENTAIRE: les basecallers Nanopore récents intègrent de plus
          en plus une détection/retrait d'adaptateurs et de barcodes
          directement lors du basecalling — vérifier, au moment de
          construire un pipeline réel, si cette étape est déjà couverte
          en amont avant d'ajouter un outil de trimming séparé.
```

```text
NanoFilt (wdecoster/nanofilt)
  STATUT: explicitement déclaré non maintenu par l'auteur, qui recommande
          lui-même la migration vers son successeur direct.
  SUCCESSEUR OFFICIEL: chopper — réimplémentation en Rust de
          NanoFilt + NanoLyse par le même auteur, nettement plus rapide,
          fonctionnalités quasi équivalentes.
          Dépôt : https://github.com/wdecoster/chopper
          Publication : De Coster W, Rademakers R (2023). "NanoPack2:
          population-scale evaluation of long-read sequencing data."
          Bioinformatics, 39(5):btad311. DOI: 10.1093/bioinformatics/btad311
  RECOMMANDATION PRODUCTION: utiliser chopper pour tout nouveau pipeline.
          NanoFilt reste présenté ici pour comprendre le fichier legacy
          du dépôt, pas comme un choix recommandé aujourd'hui.
```

---

# 2. Trimming/filtrage — données Illumina (short reads)

## 2.1 Cutadapt

```text
COMMAND: cutadapt
PURPOSE: retirer des séquences d'adaptateurs/amorces/queues poly-A de
         façon tolérante aux erreurs, filtrer et modifier des reads.
SYNTAX: cutadapt -a ADAPTATEUR -o sortie.fastq.gz entree.fastq.gz
OPTIONS COURANTES:
  -a   adaptateur en 3' (simple ou paired-end R1)
  -q   seuil de qualité de trimming (à justifier, voir règle de paramétrage)
  -m   longueur minimale après trimming (à justifier également)
DOCUMENTATION: https://cutadapt.readthedocs.io/en/stable/
EXERCISE: sur linux/reads.fastq, retirer l'adaptateur Illumina identifié
         au module 02 (AGATCGGAAGAGC) et comparer le nombre de reads
         affectés au chiffre déjà obtenu par grep (56 reads).
```
```bash
cutadapt -a AGATCGGAAGAGC -o linux/reads_trimmed.fastq linux/reads.fastq
```

## 2.2 fastp — alternative tout-en-un

```text
COMMAND: fastp
PURPOSE: QC + trimming d'adaptateurs + filtrage qualité en une seule
         commande rapide (multi-threadée, écrite en C++), produisant
         aussi un rapport HTML de contrôle qualité avant/après.
SYNTAX: fastp -i entree.fastq.gz -o sortie.fastq.gz -h rapport.html
DOCUMENTATION: https://github.com/OpenGene/fastp
         (dépôt officiel, contient l'intégralité de la documentation)
EXERCISE: comparer, sur le même fichier, la sortie de cutadapt (2.1) et
         de fastp — les deux rapportent-ils le même nombre de reads
         affectés par le trimming d'adaptateurs ?
```

---

# 3. Trimming/filtrage — données Nanopore (long reads)

## 3.1 Retrait d'adaptateurs (reprise du principe de Porechop)

Le principe pédagogique (indépendant du statut de maintenance de
l'outil) : rechercher les séquences d'adaptateurs connues aux extrémités
de chaque read, et les retirer si trouvées avec un score de similarité
suffisant — approche directement comparable à un `cutadapt -a` mais
adaptée au taux d'erreur plus élevé des reads longs.

```text
DOCUMENTATION (pour comprendre le principe, statut abandonware assumé) :
  https://github.com/rrwick/Porechop
DOCUMENTATION (alternative maintenue avec découverte automatique) :
  https://github.com/bonsai-team/Porechop_ABI
```

## 3.2 Filtrage qualité/longueur avec chopper

```text
COMMAND: chopper
PURPOSE: filtrer des reads longs par qualité moyenne et longueur minimale
         (fonction équivalente à NanoFilt, en plus rapide).
SYNTAX: cat reads.fastq | chopper -q 10 -l 500 > reads_filtered.fastq
OPTIONS: -q qualité moyenne minimale, -l longueur minimale (valeurs à
         justifier par le protocole et le rapport de QC du module 09 —
         jamais par défaut)
DOCUMENTATION: https://github.com/wdecoster/chopper
```

---

TROUBLESHOOTING
------------------------------------------------------------
```text
SYMPTOM: après trimming, la quasi-totalité des reads sont éliminés
CAUSE: seuil de qualité ou de longueur minimale mal choisi pour la
       technologie utilisée (un seuil pensé pour Illumina, appliqué à du
       Nanopore, est presque toujours trop strict — le taux d'erreur brut
       par base diffère fortement entre technologies).
DIAGNOSIS: comparer la distribution de qualité réelle (rapport de QC,
           module 09) au seuil choisi avant de blâmer les données.
SOLUTION: ajuster le seuil en fonction de la distribution réelle observée,
          pas d'une valeur générique trouvée en ligne.
PREVENTION: toujours passer par le module 09 (QC) avant de choisir un
            paramètre de trimming.
```
```text
SYMPTOM: des reads contiennent encore un adaptateur après trimming
CAUSE: séquence d'adaptateur incorrecte fournie à l'outil, ou
       adaptateur non standard (kit de préparation de librairie
       différent de celui supposé).
DIAGNOSIS: ré-exécuter un QC (module 09) après trimming et vérifier la
           métrique "Adapter Content" — ne jamais supposer le nettoyage
           réussi sans re-contrôle.
SOLUTION: identifier la séquence d'adaptateur réellement utilisée
          (documentation du kit de préparation de librairie) et
          relancer le trimming avec la bonne séquence.
PREVENTION: toujours documenter, dès l'acquisition des données (module
            08), le kit de préparation de librairie utilisé.
```

GO FURTHER
------------------------------------------------------------
```text
Topic: retrait d'adaptateurs et filtrage qualité
Official documentation:
  https://cutadapt.readthedocs.io/en/stable/
  https://github.com/OpenGene/fastp
  https://github.com/wdecoster/chopper
Topics to explore: trimming paired-end (synchronisation R1/R2), poly-A/
                    poly-G trimming (biais spécifiques à certains
                    instruments Illumina), démultiplexage
```

DOCUMENTATION
------------------------------------------------------------
- Cutadapt — https://cutadapt.readthedocs.io/en/stable/
- fastp — https://github.com/OpenGene/fastp
- chopper — https://github.com/wdecoster/chopper
- Porechop (legacy, abandonware) — https://github.com/rrwick/Porechop
- Porechop_ABI (fork maintenu) — https://github.com/bonsai-team/Porechop_ABI
- NanoFilt (legacy, non maintenu) — https://github.com/wdecoster/nanofilt

SCIENTIFIC REFERENCES
------------------------------------------------------------
- Martin M (2011). "Cutadapt removes adapter sequences from
  high-throughput sequencing reads." EMBnet.journal, 17(1):10-12.
  DOI: 10.14806/ej.17.1.200
- Chen S, Zhou Y, Chen Y, Gu J (2018). "fastp: an ultra-fast all-in-one
  FASTQ preprocessor." Bioinformatics, 34(17):i884-i890.
  DOI: 10.1093/bioinformatics/bty560
- Bonenfant Q, Noé L, Touzet H (2023). "Porechop_ABI: discovering unknown
  adapters in Oxford Nanopore Technology sequencing reads for downstream
  trimming." Bioinformatics Advances, 3(1):vbac085.
  DOI: 10.1093/bioadv/vbac085
- De Coster W, Rademakers R (2023). "NanoPack2: population-scale
  evaluation of long-read sequencing data." Bioinformatics, 39(5):btad311.
  DOI: 10.1093/bioinformatics/btad311

NEXT MODULE
------------------------------------------------------------
`11_de_novo_assembly/` — assembler les reads nettoyés ici, avec le même
niveau de vérification appliqué au statut de Canu (déjà présent dans le
fichier legacy).
