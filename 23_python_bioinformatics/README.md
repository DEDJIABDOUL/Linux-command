============================================================
MODULE 23 — PYTHON POUR LA BIOINFORMATIQUE
============================================================

OBJECTIVE
------------------------------------------------------------
Présenter l'équivalent Python de l'écosystème R/Bioconductor du module
précédent : Biopython pour la manipulation de séquences, pandas/NumPy/
SciPy pour l'analyse de données tabulaires et numériques, pysam pour
l'interaction directe avec SAM/BAM/VCF.

PREREQUISITES
------------------------------------------------------------
`22_r_statistics/`, `05_biological_formats/`, `06_environment_management/`
(installation via Conda/Mamba).

WHY?
------------------------------------------------------------
Python et R coexistent en bioinformatique plutôt que de s'exclure : R/
Bioconductor domine l'analyse statistique différentielle (déjà vu,
modules 15-21), tandis que Python est souvent préféré pour l'écriture de
scripts d'automatisation généralistes, le traitement de très gros
volumes de données, et l'intégration avec des pipelines (Snakemake, phase
ultérieure, est lui-même écrit en Python).

---

# 1. Biopython — manipuler des séquences biologiques

```text
COMMAND: SeqIO.parse()
PURPOSE: lire/écrire des fichiers FASTA/FASTQ/GenBank et bien d'autres
         formats, avec un objet Seq offrant les opérations biologiques
         courantes (complément inverse, traduction).
SYNTAX (Python) :
```
```python
from Bio import SeqIO

for record in SeqIO.parse("linux/genome.fasta", "fasta"):
    print(record.id, len(record.seq))
```
```text
DOCUMENTATION: https://biopython.org/docs/latest/Tutorial/ (tutoriel/
         cookbook officiel) · dépôt : https://github.com/biopython/biopython
EXERCISE: reproduire avec Biopython le comptage de séquences déjà fait
         avec grep -c "^>" (module 02) sur linux/genome.fasta, et
         confirmer l'obtention du même résultat (22).
```

---

# 2. pandas — données tabulaires

```text
COMMAND: pandas.read_csv()
PURPOSE: charger, filtrer et transformer des données tabulaires (ex.
         linux/annotations.tsv, déjà manipulé avec cut/awk en module 03)
         de façon vectorisée, en mémoire.
SYNTAX (Python) :
```
```python
import pandas as pd

annotations = pd.read_csv("linux/annotations.tsv", sep="\t")
resultat = annotations[annotations["length"] > 500]
```
```text
DOCUMENTATION: https://pandas.pydata.org/docs/ (documentation officielle)
INTERPRETATION: pandas n'est pas un remplacement de awk/cut pour les
         traitements simples en ligne de commande (module 03) — il
         devient pertinent dès que la logique de traitement dépasse ce
         qu'un pipeline shell exprime clairement, ou pour l'intégration
         avec des bibliothèques d'analyse/visualisation Python.
```

---

# 3. NumPy et SciPy — calcul numérique et statistique

```text
COMMAND: numpy.array() / scipy.stats
PURPOSE: NumPy fournit des tableaux numériques efficaces (base de la
         quasi-totalité de l'écosystème scientifique Python, y compris
         pandas) ; SciPy fournit des routines statistiques et
         numériques (tests statistiques, optimisation, algèbre linéaire).
SYNTAX (Python) :
```
```python
import numpy as np
from scipy import stats

qualites = np.array([30, 32, 28, 35, 31])
print(qualites.mean(), qualites.std())
stat, p_value = stats.ttest_ind(groupe_a, groupe_b)
```
```text
DOCUMENTATION: https://numpy.org/doc/ (NumPy) · https://docs.scipy.org/doc/scipy/ (SciPy)
```

---

# 4. pysam — interagir directement avec SAM/BAM/VCF/BCF

```text
COMMAND: pysam.AlignmentFile() / pysam.VariantFile()
PURPOSE: lire/écrire directement des fichiers SAM/BAM/CRAM et VCF/BCF
         (05_biological_formats/) depuis un script Python, via une
         interface à htslib — la même bibliothèque sous-jacente que
         samtools/bcftools (12_sequence_alignment/, 21_variant_analysis/).
SYNTAX (Python) :
```
```python
import pysam

bam = pysam.AlignmentFile("alignement.sorted.bam", "rb")
for read in bam.fetch("chr1", 1000, 2000):
    print(read.query_name, read.mapping_quality)
```
```text
DOCUMENTATION: https://pysam.readthedocs.io/ (documentation officielle) ·
         dépôt : https://github.com/pysam-developers/pysam
COMMON ERRORS: itérer un fichier BAM non indexé avec .fetch() sur une
         région précise échoue — un index (.bai, déjà vu en
         05_biological_formats/ et 12_sequence_alignment/) est requis
         pour l'accès par région.
EXERCISE: écrire un script Python utilisant pysam pour compter le nombre
         de reads alignés avec une qualité de mapping (MAPQ) supérieure à
         30 dans un BAM, et comparer au résultat de
         `samtools view -c -q 30` (module 12) sur le même fichier.
```

---

TROUBLESHOOTING
------------------------------------------------------------
```text
SYMPTOM: ImportError lors de l'import de Biopython/pandas/pysam
CAUSE: package installé dans un environnement Conda différent de celui
       actuellement activé (voir 06_environment_management/, section sur
       $PATH et activation).
DIAGNOSIS: `python -c "import sys; print(sys.executable)"` pour vérifier
           quel interpréteur Python est réellement utilisé.
SOLUTION: activer le bon environnement Conda avant de lancer le script.
PREVENTION: documenter systématiquement, dans le fichier d'environnement
            (envs/*.yml), les packages Python requis par un script.
```

GO FURTHER
------------------------------------------------------------
```text
Topic: Python pour la bioinformatique
Official documentation:
  https://biopython.org/docs/latest/Tutorial/
  https://pandas.pydata.org/docs/
  https://pysam.readthedocs.io/
Topics to explore: scikit-learn (apprentissage automatique appliqué à des
                    données biologiques), Snakemake (module suivant,
                    écrit en Python), Jupyter notebooks pour l'analyse
                    exploratoire reproductible
```

DOCUMENTATION
------------------------------------------------------------
- Biopython — https://biopython.org/docs/latest/Tutorial/ · source : https://github.com/biopython/biopython
- pandas — https://pandas.pydata.org/docs/
- NumPy — https://numpy.org/doc/
- SciPy — https://docs.scipy.org/doc/scipy/
- pysam — https://pysam.readthedocs.io/ · source : https://github.com/pysam-developers/pysam

SCIENTIFIC REFERENCES
------------------------------------------------------------
- Cock PJA et al. (2009). "Biopython: freely available Python tools for
  computational molecular biology and bioinformatics." Bioinformatics,
  25(11):1422-1423. DOI: 10.1093/bioinformatics/btp163
- Harris CR et al. (2020). "Array programming with NumPy." Nature,
  585:357-362. DOI: 10.1038/s41586-020-2649-2
- Virtanen P et al. (2020). "SciPy 1.0: fundamental algorithms for
  scientific computing in Python." Nature Methods, 17:261-272.
  DOI: 10.1038/s41592-019-0686-2
- McKinney W (2010). "Data Structures for Statistical Computing in
  Python." Proceedings of the 9th Python in Science Conference, 56-61.
  DOI: 10.25080/Majora-92bf1922-00a

NEXT MODULE
------------------------------------------------------------
`24_workflows/` — Snakemake et Nextflow, pour automatiser formellement
les pipelines déjà compris manuellement dans les modules précédents.
