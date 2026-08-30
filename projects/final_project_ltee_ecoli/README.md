# Projet final — Accumulation de variants dans la Long-Term Evolution Experiment (Ara-3)

OBJECTIVE
------------------------------------------------------------
Mettre bout à bout tous les modules du dépôt (`01_linux_basics/` à
`26_hpc/`) sur une vraie question biologique : combien de mutations se
sont accumulées dans la population *Escherichia coli* Ara-3 de
l'expérience d'évolution à long terme de Lenski (LTEE), entre la
génération 5 000 et la génération 50 000, par rapport à l'ancêtre
REL606 ?

PREREQUISITES
------------------------------------------------------------
`07_project_organization/`, `08_data_acquisition/`, `09_quality_control/`,
`10_adapter_trimming_filtering/`, `12_sequence_alignment/`,
`21_variant_analysis/`, `23_python_bioinformatics/` (pysam/pandas),
`24_workflows/` (Snakemake), `25_reproducibility/` (Conda/Git). Aucune
commande n'est réexpliquée ici en détail : chaque étape du pipeline
renvoie vers le module qui l'enseigne.

BIOLOGICAL CONTEXT
------------------------------------------------------------
```text
Depuis 1988, le laboratoire de Richard Lenski propage 12 populations
d'E. coli issues d'un même ancêtre (REL606) en milieu minimal
glucose-limité. La population Ara-3 est devenue célèbre : vers la
génération 31 500-33 127, un clone a évolué la capacité inédite
d'utiliser le citrate en aérobiose (phénotype Cit+), un trait que la
souche ancestrale ne possède pas dans ces conditions. Ce projet
réutilise 3 clones séquencés d'Ara-3 (5 000, 15 000 et 50 000
générations) pour observer, par variant calling, la dynamique
d'accumulation de mutations dans le temps — sans chercher à
retrouver spécifiquement la mutation Cit+ elle-même (voir LIMITATIONS).
```

DATASET
------------------------------------------------------------
Voir `data/metadata/samples.tsv` pour la table complète (format du
module 08, section 5.3).

| Échantillon | Génération | Accession SRA |
|---|---|---|
| `gen5000` | 5 000 | `SRR2589044` |
| `gen15000` | 15 000 | `SRR2584863` |
| `gen50000` | 50 000 | `SRR2584866` |

Référence : *Escherichia coli* B str. REL606, séquence `CP000819.1`,
assemblage `GCA_000017985.1`
(https://www.ncbi.nlm.nih.gov/datasets/genome/GCA_000017985.1/).

Ce jeu de données (mêmes 3 accessions, même référence) est aussi celui
de la leçon officielle Data Carpentry *Wrangling and Processing for
Genomics* (https://datacarpentry.github.io/wrangling-genomics/) —
vérifiabilité double : littérature scientifique primaire (voir
SCIENTIFIC REFERENCES) et pédagogie internationale déjà éprouvée.

---

# 1. Pipeline

```text
config.yaml (échantillons, génération, seuils)
  ↓
get_reference (08)         : FASTA + GFF3 REL606
  ↓
get_reads (08, §5.1)        : prefetch + fasterq-dump, 3 échantillons
  ↓
fastqc_raw (09)               : QC des reads bruts
  ↓
trim — fastp (10)               : retrait d'adaptateurs, filtrage qualité
  ↓
align — bwa-mem2 (12)             : alignement contre REL606
  ↓
markdup — samtools (16, principe)   : marquage des doublons PCR
  ↓
call_variants — bcftools (21, §2.1)   : appel de variants
  ↓
filter_variants — bcftools (21, §3)    : filtrage QUAL/DP
  ↓
annotate_variants — bcftools csq         : effet fonctionnel (voir DECISIONS)
  ↓
summarize — pysam/pandas/matplotlib (23)   : table + graphique par génération
```

Le pipeline est implémenté en Snakemake (`Snakefile`, module 24) :
chaque règle exécute exactement une commande déjà enseignée, avec une
directive `conda:` qui pointe vers un fichier `envs/*.yml` **existant**
à la racine du dépôt (aucun outil n'est dupliqué).

---

# 2. Comment exécuter

```bash
conda env create -f ../../envs/workflows.yml
conda activate workflows

cd projects/final_project_ltee_ecoli
snakemake -n                       # dry-run : affiche le DAG, ne télécharge/exécute rien
snakemake --use-conda -j 4         # exécution réelle (crée un env par règle à la demande)
```

```text
COMMON ERRORS:
  - lancer `snakemake --use-conda` sans `conda`/`mamba` disponible dans
    le PATH → Snakemake échoue à la création des environnements ;
    vérifier `conda --version` avant de lancer (06_environment_management/).
  - espace disque insuffisant → les 3 échantillons bruts pèsent au total
    environ 1,6 Go (module 08, vérifier avec `df -h` avant de lancer,
    01_linux_basics/, section 6).
EXERCISE: avant l'exécution complète, lancer `snakemake -n` et
         identifier dans la sortie le nombre total de règles qui seront
         exécutées, ainsi que l'ordre de dépendance entre `get_reads` et
         `get_reference` (aucune dépendance entre elles — Snakemake
         peut les paralléliser).
```

---

# 3. DECISIONS (choix méthodologiques justifiés)

```text
bcftools csq PLUTÔT QUE VEP/SnpEff : VEP dépend de caches précompilés
         pour des génomes de référence répertoriés (essentiellement
         vertébrés) ; SnpEff nécessite de construire une base
         d'annotation dédiée pour un génome bactérien "custom" comme
         REL606. bcftools csq consomme directement un GFF3 déjà
         téléchargé, ce qui correspond exactement à ce projet. Un
         apprenant souhaitant comparer les trois approches peut le
         faire en exercice (voir 21_variant_analysis/, section 4).

samtools markdup PLUTÔT QUE Picard MarkDuplicates : évite une
         dépendance supplémentaire à envs/chipseq.yml pour une seule
         commande ; samtools est déjà requis pour l'alignement
         (envs/alignment.yml). Les deux outils répondent au même
         besoin (12_sequence_alignment/, 16_chipseq/ pour Picard).

Seuils de filtrage (QUAL<30, DP<10) : valeurs de départ raisonnables
         (module 21, §3) à VALIDER après la première exécution en
         observant la profondeur moyenne réelle obtenue
         (`bcftools stats` sur le VCF non filtré) — ne jamais les
         considérer comme définitifs sans cette vérification.
```

---

# 4. EXPECTED RESULTS / INTERPRETATION

```text
CE QUE CE PROJET PERMET D'OBSERVER: une tendance générale d'accumulation
         de variants avec la génération — mais pas nécessairement
         monotone d'un point à l'autre (voir ACTUAL RESULTS, section 5,
         pour le résultat réel obtenu et sa lecture, qui contredit une
         attente naïve de simple progression linéaire).
CE QUE CE PROJET NE PERMET PAS D'AFFIRMER SANS ANALYSE SUPPLÉMENTAIRE:
         quelle mutation précise est responsable du phénotype Cit+ (ce
         travail a nécessité, dans la littérature, un séquençage
         beaucoup plus profond et une analyse dédiée — voir Blount et
         al. 2012 en SCIENTIFIC REFERENCES) ; qu'un variant filtré ici
         est nécessairement fonctionnel (bcftools csq prédit un effet
         possible sur un transcrit, pas une preuve expérimentale) ;
         qu'une tendance obtenue sur 3 points seulement est
         statistiquement robuste — elle est illustrative, pas
         publiable en l'état.
```

---

# 5. ACTUAL RESULTS (exécution réelle du 2026-08-30)

Le pipeline a été exécuté de bout en bout contre les vraies données (les
~1,3 Go réels téléchargés depuis ENA, alignement bwa-mem2, variant
calling bcftools, filtrage QUAL<30/DP<10, `bcftools csq`).

| Échantillon | Génération | Profondeur moyenne | Variants filtrés (SNPs + indels) |
|---|---|---|---|
| `gen5000` | 5 000 | 56,7x | 42 (39 SNPs, 3 indels) |
| `gen15000` | 15 000 | 79,3x | 29 (23 SNPs, 6 indels) |
| `gen50000` | 50 000 | 141,7x | **812** (704 SNPs, 108 indels) |

```text
RÉSULTAT: PAS une progression monotone simple. gen15000 (29) a MOINS de
         variants que gen5000 (42), puis gen50000 explose à 812 — un
         bond d'un ordre de grandeur, bien supérieur à ce qu'expliquerait
         la seule hausse de profondeur de séquençage (×1,8 entre gen15000
         et gen50000, contre un bond de variants ×28).
```

```text
INTERPRETATION (vérifiée par recherche officielle, pas une supposition) :
         ce bond est cohérent avec un phénomène documenté indépendamment
         dans la littérature sur la LTEE — la population Ara-3 a évolué
         un phénotype hypermutateur par perte de fonction du système de
         réparation des mésappariements (défaut mutS), apparu vers la
         génération 34 750, c'est-à-dire ENTRE l'échantillon gen15000 et
         l'échantillon gen50000 de ce projet. Voir Maddamsetti & Grant
         (2020) en SCIENTIFIC REFERENCES. La baisse gen5000→gen15000
         (42→29), elle, reste dans la variation attendue à ce stade
         (pré-hypermutateur) et n'appelle pas d'explication particulière
         au-delà du bruit d'échantillonnage/profondeur (56,7x vs 79,3x).
```

```text
LIMITE DE CETTE LECTURE: la profondeur de séquençage diffère entre les 3
         échantillons (56,7x à 141,7x) — une comparaison rigoureuse
         exigerait un sous-échantillonnage à profondeur égale avant
         calling, non fait ici (voir LIMITATIONS). Le bond gen50000 est
         néanmoins trop important pour s'expliquer par la seule
         profondeur, ce qui rend l'hypothèse hypermutateur plausible sans
         la rendre définitivement prouvée par ce seul projet.
```

Reproductible avec `results/variant_summary.tsv` et
`results/variants_vs_generation.png` (non versionnés, `.gitignore`
racine — régénérés par `snakemake --use-conda -j 4`).

---

LIMITATIONS
------------------------------------------------------------
```text
- Aucun jeu de variants de "vérité terrain" publié n'existe pour ces 3
  clones précis (contrairement à un jeu de benchmark formel type
  Genome in a Bottle) — la validation ici repose sur la cohérence de
  la tendance obtenue avec la biologie connue de l'expérience, pas sur
  une comparaison chiffrée à un résultat attendu.
- `SRR2584863` (15 000 générations) pèse à lui seul plus de 700 Mo :
  sur un poste modeste, réduire d'abord le nombre de reads avec
  `fasterq-dump -X 500000` (option non incluse dans le Snakefile par
  défaut) pour une exécution d'essai rapide, avant de lancer le
  pipeline complet.
- Ce projet n'exécute pas la déduplication PCR selon les GATK Best
  Practices complètes (BaseRecalibrator, voir 21_variant_analysis/,
  §2.2) — le choix bcftools/samtools ici privilégie la lisibilité
  pédagogique du DAG plutôt que la rigueur clinique.
```

TROUBLESHOOTING
------------------------------------------------------------
```text
SYMPTOM: `snakemake --use-conda` échoue à la règle get_reads avec une
         erreur prefetch/fasterq-dump
CAUSE: SRA Toolkit non configuré (première utilisation) ou connexion
       réseau instable pour un run de plusieurs centaines de Mo.
DIAGNOSIS: exécuter manuellement `prefetch SRR2589044` en dehors de
           Snakemake pour isoler l'erreur (module 08, §5.1).
SOLUTION: relancer — prefetch reprend un téléchargement interrompu ;
          en dernier recours, utiliser la voie ENA (module 08, §5.2).
PREVENTION: tester la règle get_reference (petit volume) avant
            get_reads (gros volume) pour valider la configuration.
```
```text
SYMPTOM: le nombre de variants ne suit pas du tout la tendance attendue
         (ex. gen5000 > gen50000)
CAUSE: possible erreur d'association échantillon/génération dans
       config.yaml, ou couverture de séquençage très différente entre
       échantillons (un échantillon peu couvert produit moins de
       variants appelés, indépendamment de la biologie).
DIAGNOSIS: comparer la profondeur moyenne (`bcftools stats`,
           champ "average depth") entre échantillons avant toute
           interprétation biologique (rappel du module 21 : mapping
           rate ou profondeur ≠ conclusion biologique automatique).
SOLUTION: normaliser la comparaison par la profondeur si elle diffère
          significativement entre échantillons, ou le signaler
          explicitement dans l'interprétation plutôt que de l'ignorer.
PREVENTION: toujours documenter la profondeur obtenue à côté du compte
            de variants (déjà fait par variant_stats dans le Snakefile).
```

GO FURTHER
------------------------------------------------------------
```text
Topic: LTEE et évolution expérimentale
Topics to explore: comparer avec un séquençage plus profond publié pour
                    localiser précisément la duplication en tandem
                    décrite par Blount et al. 2012 ; étendre le
                    pipeline aux autres populations Ara (Ara-1 à
                    Ara-12, disponibles sur SRA sous le même
                    BioProject que ce projet documente).
```

DOCUMENTATION
------------------------------------------------------------
- Data Carpentry, *Wrangling and Processing for Genomics* — https://datacarpentry.github.io/wrangling-genomics/
- NCBI Datasets, GCA_000017985.1 — https://www.ncbi.nlm.nih.gov/datasets/genome/GCA_000017985.1/
- bcftools csq — https://samtools.github.io/bcftools/bcftools.html#csq
- Snakemake — https://snakemake.readthedocs.io/

SCIENTIFIC REFERENCES
------------------------------------------------------------
- Jeong H, Barbe V, Lee CH, et al. (2009). "Genome sequences of
  *Escherichia coli* B strains REL606 and BL21(DE3)." *Journal of
  Molecular Biology*, 394(4):644-652. DOI: 10.1016/j.jmb.2009.09.052
  (référence du génome REL606 utilisé comme réf.)
- Blount ZD, Borland CZ, Lenski RE (2008). "Historical contingency and
  the evolution of a key innovation in an experimental population of
  *Escherichia coli*." *PNAS*, 105(23):7899-7906. (découverte du
  phénotype Cit+ dans Ara-3 — référence fondatrice)
- Blount ZD, Barrick JE, Davidson CJ, Lenski RE (2012). "Genomic
  analysis of a key innovation in an experimental *Escherichia coli*
  population." *Nature*, 489:513-518. DOI: 10.1038/nature11514 (base
  génomique du trait Cit+ — état actuel/mécanisme, à citer conjointement
  avec la référence fondatrice de 2008)
- Maddamsetti R, Grant NA (2020). "Divergent evolution of mutation rates
  and biases in the long-term evolution experiment with *Escherichia
  coli*." *Genome Biology and Evolution*, 12(9):1591-1603. DOI:
  10.1093/gbe/evaa178 (documente le phénotype hypermutateur d'Ara-3,
  apparu vers la génération 34 750 — référence de la section ACTUAL
  RESULTS ci-dessus)

```text
NOTE DE VÉRIFICATION: Barrick et al. (2009, Nature, DOI
         10.1038/nature08480), bien que portant sur la même expérience
         LTEE, séquence la population Ara-1 et non Ara-3 — volontairement
         PAS cité ici pour éviter une confusion de population.
```
