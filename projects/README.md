# Mini-projets et projet final

## Projet final : `final_project_ltee_ecoli/`

Le projet final intégrateur annoncé dans le README racine et dans
`docs/audit_report.md` est désormais livré. Il applique bout à bout le
parcours `01_linux_basics/` → `26_hpc/` sur une vraie question
biologique : combien de mutations se sont accumulées dans la population
*E. coli* Ara-3 (Long-Term Evolution Experiment, Lenski lab) entre les
générations 5 000, 15 000 et 50 000, par rapport à l'ancêtre REL606.

Voir [`final_project_ltee_ecoli/README.md`](final_project_ltee_ecoli/README.md)
pour le récit complet (contexte biologique, jeu de données, pipeline
Snakemake, décisions méthodologiques, limites, interprétation).

## Mini-projet : `mini_project_amr_kpneumoniae/`

Premier mini-projet livré : profilage AMR, typage moléculaire et
phylogénie par SNP sur 3 isolats cliniques réels de *Klebsiella
pneumoniae* résistants aux carbapénèmes (Tada et al. 2017). Conçu comme
guide pas-à-pas pour un lecteur découvrant ce type de pipeline, et comme
réécriture corrigée d'un pipeline externe audité au préalable (voir
`mini_project_amr_kpneumoniae/README.md`, sections ORIGINE ET
AVERTISSEMENT ANTI-PLAGIAT et DECISIONS, pour le détail de chaque défaut
identifié et corrigé). Introduit `envs/amr_typing.yml`, qui comble un
manque du dépôt (aucun module numéroté ne couvrait encore l'AMR/le
typage/la phylogénie de routine).

Voir [`mini_project_amr_kpneumoniae/README.md`](mini_project_amr_kpneumoniae/README.md)
pour le récit complet.

## Mini-projets par domaine — toujours planifiés

Un mini-projet par grand domaine couvert (QC, assemblage, RNA-seq,
ChIP-seq, GWAS...) reste une phase ultérieure distincte : chaque
mini-projet est ajouté et validé individuellement, dans le même esprit
incrémental que le reste du dépôt. Voir `docs/audit_report.md` pour la
feuille de route.
