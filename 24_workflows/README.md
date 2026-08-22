============================================================
MODULE 24 — WORKFLOWS FORMELS : SNAKEMAKE, NEXTFLOW, NF-CORE
============================================================

OBJECTIVE
------------------------------------------------------------
Transformer les pipelines manuels déjà compris (modules 09 à 21) en
workflows formels, déclaratifs, parallélisables et reproductibles, avec
Snakemake et Nextflow — puis situer nf-core comme un écosystème de
pipelines Nextflow déjà écrits, jamais comme une boîte noire à exécuter
sans comprendre son fonctionnement interne.

PREREQUISITES
------------------------------------------------------------
`04_bash_scripting/` (scripts multi-échantillons), et idéalement avoir
déjà exécuté manuellement au moins un pipeline complet (ex. `15_rnaseq/`
ou `09`→`13`, la filière assemblage).

WHY?
------------------------------------------------------------
```text
commande simple
      ↓
plusieurs commandes
      ↓
script Bash (04_bash_scripting/)
      ↓
script Bash multi-échantillons (boucle for)
      ↓
WORKFLOW FORMEL (ce module)
      ↓
pipeline bioinformatique reproductible
```
Un script Bash multi-échantillons devient vite fragile dès que le
pipeline comporte de nombreuses étapes interdépendantes : reprise après
échec, parallélisation, gestion des dépendances entre fichiers, exécution
distribuée sur un cluster (module 26) sont difficiles à implémenter
proprement à la main. Un moteur de workflow résout ces problèmes de façon
générique.

RÈGLE FONDAMENTALE (rappel du module 15, §32 de la charte pédagogique)
------------------------------------------------------------
```text
Ne jamais exécuter `nextflow run nf-core/rnaseq ...` (ou tout autre
pipeline nf-core) comme une boîte noire. Ce module explique D'ABORD les
concepts de Snakemake et Nextflow eux-mêmes (règles/process, dépendances,
DAG), AVANT de présenter nf-core comme une couche d'accélération
construite sur ces mêmes concepts.
```

---

# 1. Snakemake

```text
CONCEPT: un workflow Snakemake est défini par des RÈGLES, chacune
         spécifiant des fichiers d'entrée, des fichiers de sortie, et la
         commande qui transforme les uns en les autres. Snakemake
         construit automatiquement un graphe de dépendances (DAG) entre
         règles à partir des noms de fichiers, et détermine l'ordre
         d'exécution ainsi que les possibilités de parallélisation.
```

```python
# Snakefile — exemple minimal, reprenant featureCounts (module 15)
rule align:
    input:
        r1="data/raw/{sample}_R1.fastq.gz",
        r2="data/raw/{sample}_R2.fastq.gz"
    output:
        "results/{sample}.sorted.bam"
    threads: 8
    shell:
        "STAR --genomeDir index/ --readFilesIn {input.r1} {input.r2} "
        "--readFilesCommand zcat --outSAMtype BAM SortedByCoordinate "
        "--runThreadN {threads} --outFileNamePrefix results/{wildcards.sample}_"

rule count:
    input:
        "results/{sample}.sorted.bam"
    output:
        "results/{sample}.counts.txt"
    shell:
        "featureCounts -a annotation.gtf -o {output} {input}"
```

```text
INTERPRETATION DES ÉLÉMENTS CLÉS:
  wildcard    {sample} est déduit automatiquement des noms de fichiers
              présents — la même règle s'applique à tous les échantillons
              sans boucle explicite à écrire.
  input/output  chaque règle déclare ce qu'elle consomme et produit ;
              Snakemake en déduit l'ordre d'exécution et évite de
              relancer une étape dont la sortie est déjà à jour.
  threads      nombre de threads alloués à l'étape, exploité par
              Snakemake pour la planification sur les ressources
              disponibles.
EXÉCUTION:
```
```bash
snakemake --cores 8 results/echantillon1.counts.txt
snakemake --cores 8 --dry-run   # aperçu du plan d'exécution sans rien lancer
```
```text
DOCUMENTATION: https://snakemake.readthedocs.io/ (documentation
         officielle complète, tutoriel inclus)
```

---

# 2. Nextflow

```text
CONCEPT: un workflow Nextflow est composé de PROCESS (unités de calcul,
         chacune avec ses entrées/sorties déclarées) reliés entre eux par
         des CHANNELS (flux de données asynchrones) au sein d'un
         WORKFLOW qui orchestre l'ensemble.
```

```groovy
// main.nf — exemple minimal, même logique que l'exemple Snakemake ci-dessus
process ALIGN {
    input:
    tuple val(sample_id), path(r1), path(r2)

    output:
    tuple val(sample_id), path("${sample_id}.sorted.bam")

    script:
    """
    STAR --genomeDir ${params.index} --readFilesIn ${r1} ${r2} \
         --readFilesCommand zcat --outSAMtype BAM SortedByCoordinate \
         --runThreadN ${task.cpus} --outFileNamePrefix ${sample_id}_
    """
}

process COUNT {
    input:
    tuple val(sample_id), path(bam)

    output:
    path("${sample_id}.counts.txt")

    script:
    "featureCounts -a ${params.gtf} -o ${sample_id}.counts.txt ${bam}"
}

workflow {
    samples_ch = Channel.fromFilePairs("data/raw/*_R{1,2}.fastq.gz")
    ALIGN(samples_ch) | COUNT
}
```

```text
INTERPRETATION DES ÉLÉMENTS CLÉS:
  process       unité de calcul isolée, avec ses propres entrées/sorties
                déclarées — comparable en esprit à une règle Snakemake.
  channel        flux de données entre process, permettant un traitement
                asynchrone et une parallélisation naturelle des
                échantillons.
  params         paramètres globaux du workflow (ex. params.index,
                params.gtf), typiquement définis dans un fichier de
                configuration séparé — jamais codés en dur dans le script.
  profils d'exécution   Nextflow permet de basculer entre exécution
                locale, cluster HPC (module 26), ou conteneurs
                (module 25) via un simple paramètre `-profile`, sans
                modifier le workflow lui-même.
DOCUMENTATION: https://www.nextflow.io/docs/latest/ (documentation
         officielle complète)
```

```text
SNAKEMAKE vs NEXTFLOW — QUAND CHOISIR QUOI:
  Snakemake   syntaxe proche de Python/Make, populaire en recherche
              académique, bonne intégration Conda par règle.
  Nextflow    modèle de flux de données asynchrone, écosystème nf-core
              très large de pipelines déjà écrits et maintenus,
              intégration native avec conteneurs et clusters cloud.
Le choix dépend souvent de l'écosystème de l'équipe/laboratoire plutôt
que d'une supériorité technique absolue de l'un sur l'autre.
```

---

# 3. nf-core — un écosystème, pas une boîte noire

```text
CONCEPT: nf-core est une collection communautaire de pipelines Nextflow
         déjà écrits, revus par les pairs, testés et maintenus selon un
         gabarit commun (ex. nf-core/rnaseq reprend, en substance, la
         chaîne QC → trimming → alignement → quantification déjà apprise
         manuellement au module 15_rnaseq/).
```

```bash
nextflow run nf-core/rnaseq -profile docker --input samplesheet.csv --outdir resultats/
```

```text
AVANT D'EXÉCUTER CETTE COMMANDE, l'étudiant ayant suivi ce dépôt sait déjà
répondre à :
  - quelles étapes ce pipeline exécute-t-il probablement, et dans quel
    ordre (comparer à 15_rnaseq/, section 1) ?
  - quels outils sont vraisemblablement utilisés à chaque étape ?
  - comment interpréter les fichiers de sortie produits ?
  - comment diagnostiquer un échec à une étape donnée ?
C'est précisément l'objectif de ce dépôt : ne jamais lancer un tel
pipeline sans cette compréhension préalable.
DOCUMENTATION: https://nf-co.re/docs (documentation officielle complète)
         · dépôts des pipelines : https://github.com/nf-core
```

---

TROUBLESHOOTING
------------------------------------------------------------
```text
SYMPTOM: Snakemake ne relance pas une règle après modification d'un
         script utilisé dans le shell:, alors que le résultat devrait
         changer
CAUSE: Snakemake détermine la nécessité de relancer une règle en
       comparant les dates de modification des fichiers input/output
       déclarés — un script externe modifié mais non déclaré comme input
       n'est pas surveillé.
DIAGNOSIS: vérifier que tous les fichiers dont dépend réellement la règle
           (scripts inclus) sont listés en input.
SOLUTION: ajouter le script comme dépendance explicite dans input:, ou
          utiliser `snakemake --touch`/`--forcerun` ponctuellement.
PREVENTION: déclarer systématiquement toute dépendance réelle d'une règle,
            pas seulement les données biologiques.
```
```text
SYMPTOM: un pipeline nf-core échoue à une étape sans message clair
CAUSE: souvent un problème d'entrée (samplesheet mal formée, référence
       manquante) plutôt qu'un bug du pipeline lui-même.
DIAGNOSIS: consulter le fichier .nextflow.log et le dossier work/ de
           l'étape en échec — Nextflow y conserve tous les fichiers
           intermédiaires et la commande exacte exécutée.
SOLUTION: reproduire la commande de l'étape en échec manuellement, en
          s'appuyant sur la compréhension acquise dans les modules
          correspondants (09-21) pour diagnostiquer le problème réel.
PREVENTION: ne jamais lancer un pipeline nf-core sur un nouveau jeu de
            données sans avoir vérifié le format exact attendu de la
            samplesheet et des références.
```

GO FURTHER
------------------------------------------------------------
```text
Topic: workflows formels
Official documentation:
  https://snakemake.readthedocs.io/
  https://www.nextflow.io/docs/latest/
  https://nf-co.re/docs
Topics to explore: gestion d'environnements Conda par règle/process,
                    exécution sur cluster HPC (module 26_hpc/),
                    reprise après échec (--rerun-incomplete pour
                    Snakemake, -resume pour Nextflow)
```

DOCUMENTATION
------------------------------------------------------------
- Snakemake — https://snakemake.readthedocs.io/
- Nextflow — https://www.nextflow.io/docs/latest/ · source : https://github.com/nextflow-io/nextflow
- nf-core — https://nf-co.re/docs · organisation GitHub : https://github.com/nf-core

SCIENTIFIC REFERENCES
------------------------------------------------------------
- Köster J, Rahmann S (2012). "Snakemake—a scalable bioinformatics
  workflow engine." Bioinformatics, 28(19):2520-2522.
  DOI: 10.1093/bioinformatics/bts480
- Di Tommaso P et al. (2017). "Nextflow enables reproducible
  computational workflows." Nature Biotechnology, 35:316-319.
  DOI: 10.1038/nbt.3820
- Ewels PA et al. (2020). "The nf-core framework for community-curated
  bioinformatics pipelines." Nature Biotechnology, 38(3):276-278.
  DOI: 10.1038/s41587-020-0439-x

NEXT MODULE
------------------------------------------------------------
`25_reproducibility/` — conteneurs (Docker/Apptainer) et Git/GitHub, les
deux piliers restants de la reproductibilité.
