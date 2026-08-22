============================================================
MODULE 19 — INTRODUCTION À LA PROTÉOMIQUE
============================================================

OBJECTIVE
------------------------------------------------------------
Comprendre le principe d'une analyse protéomique par spectrométrie de
masse (MS), de l'identification de peptides à la quantification
différentielle de protéines, et savoir situer les outils standards du
domaine — sans prétendre remplacer une formation dédiée à la
spectrométrie de masse elle-même.

PREREQUISITES
------------------------------------------------------------
`08_data_acquisition/` (UniProt), `07_project_organization/`.

BIOLOGICAL CONCEPT
------------------------------------------------------------
```text
peptide         fragment de protéine généré par digestion enzymatique
                 (typiquement la trypsine), unité réellement mesurée par
                 le spectromètre de masse.
PSM              Peptide-Spectrum Match : association entre un spectre de
                 masse observé et une séquence peptidique candidate.
protein inference   reconstruction de l'identité des protéines présentes
                 à partir des peptides identifiés — non trivial car un
                 même peptide peut appartenir à plusieurs protéines
                 partageant une région commune (protéines homologues,
                 isoformes).
DDA / DIA        Data-Dependent / Data-Independent Acquisition : deux
                 stratégies d'acquisition en spectrométrie de masse.
                 DDA sélectionne les ions les plus intenses pour
                 fragmentation (biais vers les protéines abondantes) ;
                 DIA fragmente systématiquement des fenêtres de masse
                 prédéfinies (couverture plus reproductible, traitement
                 informatique plus complexe).
```

WHY?
------------------------------------------------------------
Contrairement au séquençage d'acides nucléiques, la protéomique par MS
n'"lit" pas directement une séquence : elle mesure des masses et des
patrons de fragmentation, comparés statistiquement à une base de
séquences protéiques attendues (souvent UniProt, module 08) pour inférer
l'identité des peptides puis des protéines présentes.

---

# 1. Vue d'ensemble du pipeline

```text
données brutes MS (format propriétaire du spectromètre)
      ↓
conversion au format standard ouvert (mzML)
      ↓
QC
      ↓
identification de peptides (recherche contre une base de séquences)
      ↓
PSM (peptide-spectrum matches), contrôle FDR
      ↓
inférence de protéines
      ↓
quantification (label-free, TMT, DIA...)
      ↓
normalisation
      ↓
analyse différentielle
      ↓
interprétation fonctionnelle (14_genome_annotation/, annotation
fonctionnelle transposable aux protéines identifiées)
```

## 1.1 Format standard ouvert : mzML

```text
CONCEPT: les spectromètres de masse produisent des formats propriétaires
         par constructeur ; mzML est le format XML standard ouvert défini
         par la Proteomics Standards Initiative (PSI) de HUPO pour
         représenter spectres et listes de pics de façon interopérable
         entre logiciels.
DOCUMENTATION: https://github.com/HUPO-PSI (organisation officielle du
         standard) · conversion pratique : ProteoWizard/msconvert —
         https://proteowizard.sourceforge.io/formats/mzml.html
```

---

# 2. Identification et quantification — deux approches complètes

## 2.1 MaxQuant (DDA, label-free ou marquage isotopique)

```text
COMMAND: MaxQuant (interface graphique / ligne de commande via mono sous
         Linux)
PURPOSE: suite intégrée pour l'identification de peptides (moteur de
         recherche intégré Andromeda), le contrôle FDR, l'inférence de
         protéines et la quantification (label-free ou SILAC/TMT).
DOCUMENTATION: https://maxquant.org/ (site officiel) · documentation
         détaillée : https://coxdocs.org (« CoxDocs », maintenue par le
         laboratoire développeur)
ANALYSE STATISTIQUE COMPLÉMENTAIRE: Perseus, développé par la même
         équipe, pour l'exploration statistique post-MaxQuant (mentionné
         pour référence, hors périmètre détaillé de ce module).
```

## 2.2 FragPipe / MSFragger (DDA et DIA)

```text
COMMAND: FragPipe (interface graphique orchestrant MSFragger + Philosopher)
PURPOSE: plateforme complète construite autour du moteur de recherche
         MSFragger (indexation par ions fragments, très rapide, y compris
         en « recherche ouverte » pour détecter des modifications non
         anticipées), avec post-traitement (PeptideProphet/ProteinProphet
         via Philosopher) et quantification.
DOCUMENTATION: https://fragpipe.nesvilab.org/ (site officiel) · dépôt :
         https://github.com/Nesvilab/FragPipe
```

## 2.3 DIA-NN (DIA)

```text
COMMAND: diann
PURPOSE: traitement dédié aux données DIA, utilisant des réseaux de
         neurones pour la correction d'interférence spectrale et une
         couverture protéomique approfondie à haut débit.
DOCUMENTATION: https://github.com/vdemichev/DiaNN (dépôt officiel,
         contient le manuel GUI complet)
COMMON ERRORS: appliquer un pipeline conçu pour DDA (ex. MaxQuant en mode
         standard) directement à des données DIA sans adapter la
         stratégie d'analyse — DIA nécessite une bibliothèque spectrale
         (générée ou prédite) que DDA ne requiert pas de la même façon.
```

---

# 3. Analyse statistique différentielle : MSstats

```text
COMMAND: MSstats (package R/Bioconductor)
PURPOSE: quantification relative statistiquement rigoureuse des
         protéines/peptides entre conditions, à partir des sorties de
         MaxQuant/FragPipe/DIA-NN, via des modèles mixtes linéaires
         flexibles adaptés au design expérimental.
SYNTAX (R, aperçu conceptuel) :
        library(MSstats)
        resultats <- dataProcess(donnees_importees)
        comparaisons <- groupComparison(contrast.matrix = matrice_contrastes, data = resultats)
DOCUMENTATION: https://msstats.org/ (site officiel) · Bioconductor :
         https://bioconductor.org/packages/release/bioc/html/MSstats.html
         · dépôt : https://github.com/Vitek-Lab/MSstats
EXTENSIONS SPÉCIALISÉES: MSstatsTMT (marquage isobare TMT), MSstatsPTM
         (modifications post-traductionnelles) — même famille d'outils.
```

---

TROUBLESHOOTING
------------------------------------------------------------
```text
SYMPTOM: taux d'identification de peptides très faible
CAUSE: base de séquences protéiques inadaptée (mauvais organisme, base
       incomplète), ou paramètres de recherche (tolérance de masse,
       modifications autorisées) mal choisis pour l'instrument utilisé.
DIAGNOSIS: vérifier la correspondance organisme/base UniProt utilisée
           (module 08), et les paramètres de tolérance recommandés pour
           le type d'instrument (haute vs basse résolution).
SOLUTION: corriger la base de référence ou les paramètres de recherche.
PREVENTION: documenter systématiquement l'instrument et le protocole de
            digestion utilisés (07_project_organization/, data/metadata/).
```
```text
SYMPTOM: un peptide identifié ne permet pas de conclure à la présence
         d'une protéine spécifique
CAUSE: peptide partagé entre plusieurs protéines homologues/isoformes —
       problème d'inférence de protéines inhérent à la méthode, pas une
       erreur d'outil.
DIAGNOSIS: examiner le nombre de protéines candidates associées à ce
           peptide dans le rapport d'inférence.
SOLUTION: privilégier les conclusions basées sur des peptides
          "protéotypiques" (uniques à une seule protéine) pour toute
          affirmation forte sur l'identité protéique.
PREVENTION: ne jamais présenter une identification basée sur un seul
            peptide partagé comme une certitude.
```

GO FURTHER
------------------------------------------------------------
```text
Topic: protéomique par spectrométrie de masse
Official documentation:
  https://maxquant.org/
  https://fragpipe.nesvilab.org/
  https://github.com/vdemichev/DiaNN
  https://msstats.org/
Topics to explore: protéomique quantitative par marquage isobare (TMT/
                    iTRAQ), analyse des modifications post-traductionnelles,
                    protéomique de découverte vs ciblée (PRM/SRM)
```

DOCUMENTATION
------------------------------------------------------------
- mzML / HUPO-PSI — https://github.com/HUPO-PSI
- MaxQuant — https://maxquant.org/ · doc : https://coxdocs.org
- FragPipe / MSFragger — https://fragpipe.nesvilab.org/ · source : https://github.com/Nesvilab/FragPipe
- DIA-NN — https://github.com/vdemichev/DiaNN
- MSstats — https://msstats.org/ · Bioconductor : https://bioconductor.org/packages/release/bioc/html/MSstats.html
- UniProt (module 08) — https://www.uniprot.org/help/programmatic_access

SCIENTIFIC REFERENCES
------------------------------------------------------------
- Cox J, Mann M (2008). "MaxQuant enables high peptide identification
  rates, individualized p.p.b.-range mass accuracies and proteome-wide
  protein quantification." Nature Biotechnology, 26:1367-1372.
  DOI: 10.1038/nbt.1511
- Kong AT, Leprevost FV, Avtonomov DM, Mellacheruvu D, Nesvizhskii AI
  (2017). "MSFragger: ultrafast and comprehensive peptide identification
  in mass spectrometry-based proteomics." Nature Methods, 14:513-520.
  DOI: 10.1038/nmeth.4256
- Demichev V, Messner CB, Vernardis SI, Lilley KS, Ralser M (2020).
  "DIA-NN: neural networks and interference correction enable deep
  proteome coverage in high throughput." Nature Methods, 17:41-44.
  DOI: 10.1038/s41592-019-0638-x
- Choi M et al. (2014). "MSstats: an R package for statistical analysis
  of quantitative mass spectrometry-based proteomic experiments."
  Bioinformatics, 30(17):2524-2526. DOI: 10.1093/bioinformatics/btu305

NEXT MODULE
------------------------------------------------------------
`20_metagenomics/` — analyser un mélange d'organismes plutôt qu'un
échantillon isolé.
