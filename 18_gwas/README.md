# 18 — GWAS (Genome-Wide Association Study)

OBJECTIVE
------------------------------------------------------------
Conduire une étude d'association pangénomique : du génotypage brut au
contrôle qualité, à la détection et la correction de la structure de
population, jusqu'au test d'association et son interprétation prudente.

PREREQUISITES
------------------------------------------------------------
`05_biological_formats/` (VCF), `08_data_acquisition/`.

BIOLOGICAL CONCEPT
------------------------------------------------------------
```text
genotype               combinaison d'allèles portée par un individu à
                        une position variante donnée.
MAF                     Minor Allele Frequency : fréquence de l'allèle le
                        moins commun à une position — les variants trop
                        rares manquent de puissance statistique pour une
                        association fiable.
HWE                      Hardy-Weinberg Equilibrium : un fort écart à
                        l'équilibre HWE à une position peut signaler une
                        erreur de génotypage plutôt qu'un signal biologique.
LD (Linkage Disequilibrium)  non-indépendance statistique entre variants
                        proches sur le génome — complique l'identification
                        du variant CAUSAL parmi plusieurs variants associés.
population structure    différences de fréquences alléliques entre
                        sous-populations, qui peuvent produire de fausses
                        associations (confusion) si non corrigées.
```

WHY?
------------------------------------------------------------
Un GWAS teste des centaines de milliers à des millions de variants
simultanément contre un phénotype — un contrôle qualité rigoureux et une
correction de la structure de population sont indispensables, faute de
quoi la majorité des associations "significatives" obtenues seront des
faux positifs dus au bruit technique ou à la stratification de population,
pas à une réalité biologique.

---

# 0. Environnement de ce module

```bash
conda env create -f envs/gwas.yml
conda activate gwas
```

```text
CONTENU: plink2, bcftools, vcftools, admixture — voir envs/gwas.yml pour
         le détail.
```

# 1. Pipeline général

```text
génotypes bruts (VCF/PLINK binaire)
      ↓
QC : missingness, MAF, HWE
      ↓
PCA / structure de population
      ↓
test d'association (ajusté sur les composantes de structure)
      ↓
correction de tests multiples
      ↓
Manhattan plot / QQ plot
      ↓
variants candidats
      ↓
interprétation fonctionnelle (14_genome_annotation/)
```

---

# 2. Contrôle qualité du génotypage

```text
COMMAND: plink2 --missing
PURPOSE: calculer le taux de données manquantes par variant et par
         individu — un taux élevé signale souvent un problème technique
         de génotypage.
SYNTAX: plink2 --bfile donnees --missing --out qc_missing
```

```text
COMMAND: plink2 --freq
PURPOSE: calculer la fréquence allélique (MAF) de chaque variant, pour
         filtrer les variants trop rares pour être testés de façon fiable.
SYNTAX: plink2 --bfile donnees --freq --out qc_freq
```

```text
COMMAND: plink2 --hardy
PURPOSE: tester l'écart à l'équilibre de Hardy-Weinberg par variant.
SYNTAX: plink2 --bfile donnees --hardy --out qc_hwe
```

```text
FILTRAGE TYPIQUE (seuils À JUSTIFIER selon le jeu de données, jamais
         appliqués par défaut sans réflexion — voir
         10_adapter_trimming_filtering/, règle de paramétrage) :
```
```bash
plink2 --bfile donnees --geno 0.05 --maf 0.01 --hwe 1e-6 \
       --mind 0.05 --make-bed --out donnees_filtrees
```

```text
DOCUMENTATION: https://www.cog-genomics.org/plink/2.0/ (documentation
         officielle PLINK 2.0) · dépôt source :
         https://github.com/chrchang/plink-ng
COMMON ERRORS: appliquer un seuil HWE strict sur TOUT l'échantillon sans
         distinguer cas/témoins — un écart HWE peut être un signal
         biologique réel dans le groupe cas pour certaines maladies, et
         ne doit être utilisé comme filtre qu'au sein du groupe témoin.
```

---

# 3. Structure de population

```text
COMMAND: plink2 --pca
PURPOSE: calculer une Analyse en Composantes Principales sur la matrice
         de génotypes, pour visualiser et quantifier la structure de
         population (ascendance) entre individus.
SYNTAX: plink2 --bfile donnees_filtrees --pca 10 --out pca_resultats
INTERPRETATION: les premières composantes principales sont
         systématiquement incluses comme covariables dans le test
         d'association (section 4) pour corriger la confusion par
         structure de population.
```

```text
COMMAND: admixture
PURPOSE: estimer, pour un nombre K de populations ancestrales supposées,
         la proportion d'ascendance de chaque individu — complémentaire à
         la PCA pour caractériser la structure de population.
SYNTAX: admixture donnees_filtrees.bed 3   (K=3 populations supposées)
DOCUMENTATION: https://dalexander.github.io/admixture/ (site officiel,
         manuel PDF officiel lié depuis cette page)
```

---

# 4. Test d'association

```text
COMMAND: plink2 --glm
PURPOSE: tester l'association entre chaque variant et le phénotype
         (quantitatif ou binaire), via un modèle linéaire/logistique
         généralisé, ajusté sur les covariables (dont les composantes
         PCA de la section 3).
SYNTAX: plink2 --bfile donnees_filtrees --pheno phenotypes.txt \
               --covar pca_resultats.eigenvec --glm --out association
DOCUMENTATION: https://www.cog-genomics.org/plink/2.0/assoc
```

```text
CONCEPTS À DISTINGUER:
  p-value        probabilité d'observer une association aussi extrême
                 sous l'hypothèse nulle d'absence d'effet.
  effect size     amplitude estimée de l'effet du variant (odds ratio ou
                 beta) — une p-value très significative peut correspondre
                 à un effet biologiquement minime sur un très grand
                 échantillon ; toujours regarder les deux ensemble.
  seuil de significativité génome-entier  classiquement autour de 5×10⁻⁸
                 pour les études humaines à densité SNP standard — une
                 convention issue du nombre effectif de tests
                 indépendants estimé empiriquement, pas une constante
                 universelle valable pour tout organisme/densité de
                 marqueurs.
```

---

# 5. Correction de tests multiples et visualisation

```text
CONCEPT: tester des centaines de milliers de variants exige une
         correction de tests multiples (Bonferroni, ou plus couramment
         un contrôle du FDR) — ne jamais interpréter une p-value brute
         individuelle sans cette correction.
```

```text
Manhattan plot   représentation de -log10(p-value) le long du génome,
                 permettant d'identifier visuellement les loci associés.
QQ plot           compare la distribution des p-values observées à la
                 distribution attendue sous l'hypothèse nulle — une
                 déviation systématique (inflation) dès les p-values
                 modérées signale souvent une structure de population mal
                 corrigée plutôt qu'un signal biologique diffus.
```

---

# 6. Interprétation prudente — rappel des pièges (§80)

```text
Association ≠ causation. Un variant associé à un phénotype peut être en
déséquilibre de liaison avec le VRAI variant causal, sans lui-même avoir
d'effet fonctionnel. Une interprétation fonctionnelle sérieuse (module
14_genome_annotation/, ou une étude de fine-mapping dédiée) est
nécessaire avant de conclure à un mécanisme biologique.
```

---

TROUBLESHOOTING
------------------------------------------------------------
```text
SYMPTOM: QQ plot montre une forte inflation dès les p-values modérées
CAUSE: structure de population insuffisamment corrigée, ou apparentement
       non contrôlé entre individus de l'échantillon.
DIAGNOSIS: vérifier le nombre de composantes PCA incluses comme
           covariables (section 3), et vérifier l'absence d'individus
           apparentés non filtrés.
SOLUTION: ajouter davantage de composantes PCA au modèle, ou filtrer les
          individus apparentés avant l'analyse (plink2 --king-cutoff).
PREVENTION: toujours examiner le QQ plot avant d'interpréter le Manhattan
            plot.
```
```text
SYMPTOM: aucun variant n'atteint le seuil de significativité génome-entier
CAUSE: puissance statistique insuffisante (taille d'échantillon trop
       faible pour l'effet recherché), MAF trop restrictive au filtrage,
       ou effet biologique réellement diffus (polygénique).
DIAGNOSIS: comparer la taille d'échantillon à des études GWAS publiées
           sur un phénotype comparable.
SOLUTION: pas d'action bioinformatique "corrective" légitime pour forcer
          un résultat — un résultat négatif bien contrôlé reste un
          résultat scientifique valide.
PREVENTION: estimer la puissance statistique attendue AVANT de lancer
            l'étude, pas après.
```

GO FURTHER
------------------------------------------------------------
```text
Topic: GWAS
Official documentation:
  https://www.cog-genomics.org/plink/2.0/
  https://samtools.github.io/bcftools/
  https://dalexander.github.io/admixture/
Topics to explore: méta-analyse GWAS multi-cohortes, scores de risque
                    polygénique (PRS), fine-mapping statistique
```

DOCUMENTATION
------------------------------------------------------------
- PLINK 2.0 — https://www.cog-genomics.org/plink/2.0/ · source : https://github.com/chrchang/plink-ng
- bcftools — https://samtools.github.io/bcftools/ · source : https://github.com/samtools/bcftools
- VCFtools — https://vcftools.github.io/ (activité de mise à jour réduite ces
  dernières années — pour les opérations courantes VCF, bcftools est
  aujourd'hui l'option la plus activement maintenue ; VCFtools reste
  largement cité dans la littérature GWAS historique)
- ADMIXTURE — https://dalexander.github.io/admixture/

SCIENTIFIC REFERENCES
------------------------------------------------------------
- Purcell S et al. (2007). "PLINK: a tool set for whole-genome association
  and population-based linkage analyses." American Journal of Human
  Genetics, 81(3):559-575. DOI: 10.1086/519795
- Chang CC et al. (2015). "Second-generation PLINK: rising to the
  challenge of larger and richer datasets." GigaScience, 4:7.
  DOI: 10.1186/s13742-015-0047-8
- Danecek P et al. (2011). "The variant call format and VCFtools."
  Bioinformatics, 27(15):2156-2158. DOI: 10.1093/bioinformatics/btr330
- Danecek P et al. (2021). "Twelve years of SAMtools and BCFtools."
  GigaScience, 10(2):giab008. DOI: 10.1093/gigascience/giab008
- Alexander DH, Novembre J, Lange K (2009). "Fast model-based estimation
  of ancestry in unrelated individuals." Genome Research, 19(9):1655-1664.
  DOI: 10.1101/gr.094052.109

NEXT MODULE
------------------------------------------------------------
`19_proteomics/` — changer d'échelle omique, du génotype à la protéine.
Le présent module GWAS suppose des génotypes déjà appelés en entrée ;
l'appel de variants proprement dit est traité séparément dans
`21_variant_analysis/`.
