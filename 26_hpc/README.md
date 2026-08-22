# 26 — Calcul haute performance (HPC)

OBJECTIVE
------------------------------------------------------------
Exécuter les pipelines déjà maîtrisés (modules 09 à 25) sur un cluster de
calcul partagé, en soumettant des jobs à un ordonnanceur, en demandant
des ressources justifiées, et en intégrant Snakemake/Nextflow à
l'infrastructure du cluster plutôt qu'en lançant tout manuellement.

PREREQUISITES
------------------------------------------------------------
`01_linux_basics/` (section 6, ressources système), `24_workflows/`,
`25_reproducibility/` (conteneurs, souvent requis sur cluster).

WHY?
------------------------------------------------------------
Les analyses des modules précédents (assemblage, alignement, GWAS,
métagénomique) peuvent dépasser largement les ressources d'un poste de
travail individuel. Un cluster HPC mutualise des ressources considérables
entre de nombreux utilisateurs, via un ORDONNANCEUR (job scheduler) qui
arbitre l'accès au CPU, à la RAM et au temps de calcul — jamais en accès
direct et illimité comme sur une machine personnelle.

---

# 0. Environnement de ce module

```text
EXCEPTION AU PATRON DES MODULES PRÉCÉDENTS: SLURM et Lmod sont des
         infrastructures installées et administrées par l'équipe du
         cluster HPC, jamais par un utilisateur individuel via Conda —
         il n'y a donc pas d'envs/*.yml pour ce module. L'utilisateur se
         contente d'utiliser les commandes SLURM déjà présentes sur le
         cluster (section 2), et charge ses propres outils via `module
         load` (section 3) ou via un environnement Conda créé avec les
         fichiers des modules précédents, activé DANS le script de job.
```

# 1. Ressources système — rappel et approfondissement (module 01)

```bash
nproc          # nombre de coeurs CPU disponibles
lscpu          # détail du processeur
free -h        # mémoire RAM disponible
df -h          # espace disque par partition
du -sh dossier # taille réellement occupée par un dossier
```

```text
INTERPRETATION: sur un cluster, ces commandes reflètent souvent les
         ressources du NOEUD DE CONNEXION (login node), pas celles
         effectivement allouées à un job — ne jamais lancer de calcul
         lourd directement sur le noeud de connexion (voir
         troubleshooting).
```

---

# 2. Soumettre un job avec SLURM

```text
CONCEPT: SLURM (Simple Linux Utility for Resource Management) est
         l'ordonnanceur de jobs le plus répandu en HPC académique.
```

```text
COMMAND: sbatch
PURPOSE: soumettre un script de job à l'ordonnanceur, qui l'exécutera dès
         que les ressources demandées seront disponibles — jamais
         immédiatement ni de façon garantie.
SYNTAX: sbatch script_job.sh
```

```bash
#!/usr/bin/env bash
#SBATCH --job-name=assemblage_flye
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=08:00:00
#SBATCH --output=logs/assemblage_%j.log

set -euo pipefail
flye --nanopore-raw reads.fastq.gz --out-dir resultats_flye/ --threads "${SLURM_CPUS_PER_TASK}"
```

```text
INTERPRETATION DES DIRECTIVES #SBATCH:
  --cpus-per-task   nombre de coeurs alloués — doit correspondre au
                     --threads réellement passé à l'outil (Flye ici),
                     jamais choisi indépendamment.
  --mem              mémoire maximale allouée — un job qui dépasse cette
                     limite est généralement tué par l'ordonnateur
                     (out-of-memory), pas juste ralenti.
  --time              durée maximale allouée — un job dépassant ce délai
                     est interrompu, quel que soit son état d'avancement.
COMMON ERRORS: demander des ressources arbitrairement excessives "pour
         être sûr" — cela retarde souvent le démarrage du job (attente
         plus longue avant que ces ressources soient disponibles) sans
         bénéfice réel ; demander des ressources trop justes tue le job
         avant qu'il ne termine. Les deux erreurs se corrigent en
         estimant les besoins réels (essai sur un sous-échantillon,
         section 4).
DOCUMENTATION: https://slurm.schedmd.com/documentation.html
         (documentation officielle complète) · guide de démarrage rapide :
         https://slurm.schedmd.com/quickstart.html
```

```text
COMMAND: squeue / scancel / sacct
PURPOSE: squeue liste les jobs en attente/en cours ; scancel annule un
         job ; sacct consulte l'historique et les ressources réellement
         consommées par un job terminé.
SYNTAX: squeue -u $USER
        scancel numero_job
        sacct -j numero_job --format=JobID,Elapsed,MaxRSS,State
INTERPRETATION: sacct est l'outil de diagnostic essentiel pour ajuster
         --mem et --time lors d'une prochaine soumission — comparer la
         mémoire réellement utilisée (MaxRSS) à celle demandée.
```

---

# 3. Gestion des logiciels sur cluster : modules environnement

```text
COMMAND: module load / module avail / module list
PURPOSE: sur de nombreux clusters, les logiciels ne sont pas installés
         globalement dans $PATH mais chargés à la demande via un
         gestionnaire de modules (souvent Lmod), en complément ou en
         alternative à Conda (module 06).
SYNTAX: module avail            # logiciels disponibles sur ce cluster
        module load samtools/1.17
        module list              # modules actuellement chargés
DOCUMENTATION: https://lmod.readthedocs.io/ (documentation officielle de
         Lmod, le gestionnaire de modules le plus répandu)
COMMON ERRORS: supposer qu'un outil installé via Conda dans un
         environnement (module 06) est automatiquement visible dans un
         job SLURM — l'activation de l'environnement Conda doit être
         explicitement refaite DANS le script de job, elle n'est pas
         héritée de la session interactive.
```

---

# 4. Bonnes pratiques HPC

```text
RÈGLE 1 — ne jamais calculer sur le noeud de connexion. Le noeud de
          connexion (login node) est un service PARTAGÉ pour éditer des
          fichiers et soumettre des jobs — pas pour exécuter un
          alignement ou un assemblage, qui doit toujours passer par
          sbatch (ou une session interactive dédiée, srun --pty bash).

RÈGLE 2 — tester sur un sous-échantillon avant de soumettre en pleine
          échelle. Extraire quelques milliers de reads (seqkit, module
          06) permet d'estimer temps et mémoire nécessaires avant de
          lancer le jeu de données complet.

RÈGLE 3 — intégrer Snakemake/Nextflow avec l'ordonnanceur plutôt que
          soumettre chaque étape à la main. Les deux moteurs de workflow
          (module 24) savent nativement soumettre chaque règle/process
          comme un job SLURM séparé (profils d'exécution dédiés),
          récupérant automatiquement le parallélisme du cluster.

RÈGLE 4 — attention au système de fichiers partagé. Un cluster HPC a
          souvent plusieurs espaces de stockage aux performances très
          différentes (home, scratch temporaire à haute performance,
          stockage de projet à long terme) — écrire des fichiers
          temporaires volumineux au mauvais endroit peut considérablement
          ralentir un job ou saturer un quota partagé entre tous les
          utilisateurs.
```

---

TROUBLESHOOTING
------------------------------------------------------------
```text
SYMPTOM: un job SLURM échoue immédiatement avec "command not found" pour
         un outil qui fonctionne en session interactive
CAUSE: l'environnement Conda (module 06) ou le module logiciel (section 3)
       n'a pas été (re)chargé À L'INTÉRIEUR du script sbatch — chaque job
       démarre dans un environnement propre, indépendant de la session
       qui l'a soumis.
DIAGNOSIS: vérifier que le script de job contient bien `conda activate ...`
           ou `module load ...` avant d'appeler l'outil.
SOLUTION: ajouter l'activation explicite en tête de script.
PREVENTION: toujours tester le script de job lui-même (pas seulement la
            commande finale) sur un petit cas avant soumission à grande échelle.
```
```text
SYMPTOM: job tué avec un message lié à la mémoire (OOM, Out Of Memory)
CAUSE: --mem demandé inférieur à la mémoire réellement nécessaire à l'outil.
DIAGNOSIS: consulter sacct (section 2) sur une exécution précédente, ou
           la documentation de l'outil pour ses besoins mémoire typiques
           selon la taille du jeu de données.
SOLUTION: augmenter --mem lors d'une nouvelle soumission.
PREVENTION: toujours prévoir une marge raisonnable au-delà de l'estimation,
            sans excès (voir Règle 2 ci-dessus).
```

GO FURTHER
------------------------------------------------------------
```text
Topic: calcul haute performance
Official documentation:
  https://slurm.schedmd.com/documentation.html
  https://lmod.readthedocs.io/
Topics to explore: job arrays (soumettre un job par échantillon en une
                    seule commande), profils d'exécution Nextflow/
                    Snakemake dédiés à SLURM (module 24), calcul dans le
                    cloud (AWS Batch, Google Cloud Life Sciences) comme
                    alternative à un cluster institutionnel
```

DOCUMENTATION
------------------------------------------------------------
- SLURM — https://slurm.schedmd.com/documentation.html
- Lmod — https://lmod.readthedocs.io/ · source : https://github.com/TACC/Lmod

SCIENTIFIC REFERENCES
------------------------------------------------------------
- Yoo AB, Jette MA, Grondona M (2003). "SLURM: Simple Linux Utility for
  Resource Management." In: Job Scheduling Strategies for Parallel
  Processing (JSSPP 2003), Lecture Notes in Computer Science, 2862:44-60.
  DOI: 10.1007/10968987_3

---

## Fin de la feuille de route numérotée (01 → 26)

Ce module clôt le parcours structuré Linux → bioinformatique
professionnelle. Voir `docs/audit_report.md` pour la trajectoire complète
du dépôt et `00_orientation/README.md` pour la vue d'ensemble. Les
mini-projets et le projet final intégrateur (combinant plusieurs modules
sur un vrai jeu de données public, de bout en bout) constituent la suite
naturelle, à construire dans `projects/`.
