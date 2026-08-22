============================================================
MODULE 14 — ANNOTATION DE GÉNOME
============================================================

OBJECTIVE
------------------------------------------------------------
Passer d'un assemblage (suite de séquences sans signification biologique
connue) à un génome annoté : localiser les gènes (annotation
structurale), puis leur attribuer une fonction probable (annotation
fonctionnelle), en choisissant des outils adaptés au règne du vivant
étudié (procaryote vs eucaryote — les pipelines ne sont PAS interchangeables).

PREREQUISITES
------------------------------------------------------------
`11_de_novo_assembly/`, `13_assembly_quality/` (annoter un assemblage non
contrôlé produit une annotation invérifiable).

WHY?
------------------------------------------------------------
```text
génome assemblé
      ↓
prédiction de gènes (structural annotation)
      ↓
annotation fonctionnelle (à quoi sert chaque gène ?)
      ↓
contrôle qualité de l'annotation
```
Un assemblage brut n'est qu'une suite de lettres ; l'annotation est ce qui
le transforme en une ressource biologiquement interprétable (localisation
des gènes, des ARN, des éléments répétés, et hypothèses fonctionnelles).

RÈGLE FONDAMENTALE
------------------------------------------------------------
```text
L'annotation de génomes PROCARYOTES (bactéries, archées) et EUCARYOTES
diffère fondamentalement : les gènes procaryotes n'ont pas d'introns
(structure simple), alors que les gènes eucaryotes ont une structure
exon/intron complexe nécessitant des modèles statistiques entraînés
(HMM) et souvent des preuves RNA-seq. Un pipeline conçu pour l'un des
deux règnes ne doit PAS être utilisé sur l'autre.
```

---

# 1. Annotation structurale et fonctionnelle — génomes procaryotes

## 1.1 Statut vérifié : Prokka → Bakta

```text
COMMAND: prokka
STATUT VÉRIFIÉ (2026-08-22) : l'auteur original (Torsten Seemann) a
         déclaré publiquement ne plus pouvoir maintenir Prokka et
         recommande EXPLICITEMENT, en ses propres mots, de le remplacer
         par Bakta dans les pipelines d'analyse : « I can no longer
         maintain it, so, with my blessing and gratitude, Oliver
         Schwengers has taken the bacterial annotation torch and
         developed Bakta ».
RECOMMANDATION: utiliser Bakta pour tout nouveau projet d'annotation
         bactérienne. Prokka reste utile pour comprendre le principe
         historique (mêmes grandes étapes : ARNr/ARNt, gènes codants,
         attribution fonctionnelle par comparaison à des bases connues).
DOCUMENTATION (legacy): https://github.com/tseemann/prokka
```

```text
COMMAND: bakta
PURPOSE: annotation rapide et standardisée de génomes bactériens (et
         plasmides/MAGs), par identification de séquence sans alignement
         complet (plus rapide et plus reproductible que les approches
         BLAST classiques).
SYNTAX: bakta --db chemin_vers_base_bakta genome_bacterien.fasta -o resultats_bakta/
OUTPUT: fichiers GFF3 et flatfiles compatibles INSDC, plus un JSON complet
         pour l'analyse automatisée en aval.
STATUT VÉRIFIÉ (2026-08-22) : activement maintenu.
DOCUMENTATION: https://github.com/oschwengers/bakta
```

---

# 2. Annotation structurale — génomes eucaryotes

```text
COMMAND: braker.pl (BRAKER2/BRAKER3)
PURPOSE: pipeline automatisé de prédiction de gènes eucaryotes, combinant
         GeneMark-ES/ET/EP/ETP et AUGUSTUS, entraîné automatiquement à
         partir de preuves RNA-seq et/ou d'homologie protéique.
SYNTAX (aperçu conceptuel — la préparation des preuves RNA-seq est traitée
         en détail dans 15_rnaseq/, phase ultérieure) :
        braker.pl --genome=genome.fasta --prot_seq=proteines_proches.fasta --threads=8
DOCUMENTATION: https://github.com/Gaius-Augustus/BRAKER (dépôt officiel,
         wiki détaillé : https://github.com/Gaius-Augustus/BRAKER/wiki)
```

```text
COMMAND: augustus
PURPOSE: prédicteur de gènes eucaryotes basé sur un modèle de Markov
         caché (HMM), généralement utilisé À L'INTÉRIEUR de BRAKER plutôt
         que directement — mentionné ici pour comprendre le principe
         algorithmique sous-jacent.
DOCUMENTATION: intégré et documenté au sein de BRAKER (voir ci-dessus) ;
         dépôt propre : https://github.com/Gaius-Augustus/Augustus
```

```text
COMMON ERRORS: utiliser Bakta/Prokka (procaryote) sur un génome eucaryote,
         ou BRAKER (eucaryote) sur un génome bactérien — les deux
         approches reposent sur des hypothèses biologiques incompatibles
         avec l'autre règne et produiront une annotation erronée sans
         nécessairement signaler d'erreur explicite.
```

---

# 3. Annotation fonctionnelle — attribuer une fonction aux gènes prédits

## 3.1 Recherche de similarité (BLAST / DIAMOND)

```text
COMMAND: blastp
PURPOSE: recherche de similarité protéique par alignement local, contre
         une base de référence (ex. UniProt, module 08).
SYNTAX: blastp -query proteines_predites.fasta -db base_uniprot -out resultats.tsv -outfmt 6
DOCUMENTATION: https://www.ncbi.nlm.nih.gov/books/NBK279690/ (manuel
         officiel BLAST+ Command Line Applications, NCBI Bookshelf)
```

```text
COMMAND: diamond blastp
PURPOSE: alternative à blastp, compatible avec les mêmes bases et formats
         de sortie, mais des ordres de grandeur plus rapide sur de gros
         volumes de séquences (protéomes complets, métagénomique).
SYNTAX: diamond makedb --in base_uniprot.fasta -d base_diamond
        diamond blastp -q proteines_predites.fasta -d base_diamond -o resultats.tsv
DOCUMENTATION: https://github.com/bbuchfink/diamond (wiki officiel :
         https://github.com/bbuchfink/diamond/wiki)
COMMON ERRORS: comparer directement des résultats blastp et diamond sans
         vérifier que les mêmes paramètres de sensibilité ont été
         utilisés — DIAMOND propose plusieurs modes de sensibilité qui
         influencent directement la comparabilité des résultats.
```

## 3.2 Domaines protéiques et orthologie

```text
COMMAND: interproscan.sh
PURPOSE: recherche de domaines/motifs protéiques connus à travers
         plusieurs bases combinées (Pfam, PROSITE, SMART...), avec
         attribution de termes Gene Ontology (GO).
DOCUMENTATION: https://interproscan-docs.readthedocs.io/ (documentation
         officielle) — nécessite un accès réseau vers ebi.ac.uk pour
         certaines fonctionnalités.
```

```text
COMMAND: emapper.py (eggNOG-mapper)
PURPOSE: annotation fonctionnelle par assignation d'orthologie
         précalculée (base eggNOG) — attribution de GO, KEGG, description
         fonctionnelle, à grande échelle (génomes complets, métagénomique).
SYNTAX: emapper.py -i proteines_predites.fasta -o resultats_eggnog --cpu 8
DOCUMENTATION: https://github.com/eggnogdb/eggnog-mapper (wiki officiel)
```

```text
CONCEPTS À DISTINGUER:
  homologie    similarité de séquence due à une ascendance commune
  orthologie   homologie entre gènes séparés par un événement de
               spéciation (fonction souvent conservée)
  domaine       région protéique structurellement/fonctionnellement
               autonome, réutilisée dans plusieurs protéines
  GO (Gene Ontology)   vocabulaire structuré décrivant fonction
               moléculaire, processus biologique, composant cellulaire
  KEGG          base de voies métaboliques et de signalisation
```

---

TROUBLESHOOTING
------------------------------------------------------------
```text
SYMPTOM: BRAKER échoue ou produit très peu de gènes prédits
CAUSE: absence de preuves suffisantes (ni RNA-seq, ni protéines de
       référence proches), ou génome en réalité procaryote/viral pour
       lequel BRAKER n'est pas conçu.
DIAGNOSIS: vérifier le règne de l'organisme et la disponibilité de preuves.
SOLUTION: fournir des protéines homologues d'espèces proches (mode
          protein-only) si aucune donnée RNA-seq n'est disponible ; pour
          un génome procaryote, utiliser Bakta plutôt que BRAKER.
PREVENTION: toujours confirmer le règne du vivant AVANT de choisir un
            pipeline d'annotation structurale.
```
```text
SYMPTOM: une grande proportion de gènes prédits restent "hypothetical
         protein" / sans fonction attribuée
CAUSE: normal pour de nombreux organismes peu étudiés — une proportion
       significative de gènes n'a, à ce jour, aucun homologue caractérisé
       dans les bases publiques.
DIAGNOSIS: comparer le taux obtenu à des organismes proches déjà annotés
           dans la littérature avant de conclure à un problème technique.
SOLUTION: pas nécessairement d'action requise — documenter le taux
          observé comme un résultat biologique, pas un échec de pipeline.
PREVENTION: ne pas viser artificiellement 100% de gènes fonctionnellement
            annotés — ce n'est réaliste pour aucun organisme.
```

GO FURTHER
------------------------------------------------------------
```text
Topic: annotation de génome
Official documentation:
  https://github.com/oschwengers/bakta
  https://github.com/Gaius-Augustus/BRAKER
  https://interproscan-docs.readthedocs.io/
  https://github.com/eggnogdb/eggnog-mapper
Topics to explore: annotation d'ARN non codants (tRNAscan-SE), éléments
                    répétés (RepeatMasker), annotation de génomes viraux
                    (cas particulier, hors procaryote/eucaryote classique)
```

DOCUMENTATION
------------------------------------------------------------
- Prokka (legacy, transition recommandée) — https://github.com/tseemann/prokka
- Bakta — https://github.com/oschwengers/bakta
- BRAKER — https://github.com/Gaius-Augustus/BRAKER
- Augustus — https://github.com/Gaius-Augustus/Augustus
- BLAST+ — https://www.ncbi.nlm.nih.gov/books/NBK279690/
- DIAMOND — https://github.com/bbuchfink/diamond
- InterProScan — https://interproscan-docs.readthedocs.io/
- eggNOG-mapper — https://github.com/eggnogdb/eggnog-mapper

SCIENTIFIC REFERENCES
------------------------------------------------------------
- Seemann T (2014). "Prokka: rapid prokaryotic genome annotation."
  Bioinformatics, 30(14):2068-2069. DOI: 10.1093/bioinformatics/btu153
- Schwengers O et al. (2021). "Bakta: rapid and standardized annotation
  of bacterial genomes via alignment-free sequence identification."
  Microbial Genomics, 7(11):000685. DOI: 10.1099/mgen.0.000685
- Brůna T, Hoff KJ, Lomsadze A, Stanke M, Borodovsky M (2021). "BRAKER2:
  automatic eukaryotic genome annotation with GeneMark-EP+ and AUGUSTUS
  supported by a protein database." NAR Genomics and Bioinformatics,
  3(1):lqaa108. DOI: 10.1093/nargab/lqaa108
- Altschul SF, Gish W, Miller W, Myers EW, Lipman DJ (1990). "Basic local
  alignment search tool." Journal of Molecular Biology, 215(3):403-410.
  DOI: 10.1016/S0022-2836(05)80360-2
- Buchfink B, Xie C, Huson DH (2015). "Fast and sensitive protein
  alignment using DIAMOND." Nature Methods, 12:59-60.
  DOI: 10.1038/nmeth.3176
- Cantalapiedra CP, Hernández-Plaza A, Letunic I, Bork P, Huerta-Cepas J
  (2021). "eggNOG-mapper v2: Functional Annotation, Orthology
  Assignments, and Domain Prediction at the Metagenomic Scale."
  Molecular Biology and Evolution, 38(12):5825-5829.
  DOI: 10.1093/molbev/msab293

NEXT MODULE
------------------------------------------------------------
`15_rnaseq/` — premier module de la série « omiques », entièrement
nouveau, sans matériau legacy à reprendre.
