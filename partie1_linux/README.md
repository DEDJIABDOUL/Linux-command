# Partie I — Linux pour biologistes

Un parcours pour les étudiants en biologie qui n'ont **jamais utilisé la
ligne de commande**. À la fin, vous saurez explorer et filtrer des données
de séquençage, automatiser un traitement sur des dizaines d'échantillons,
travailler sur un serveur de calcul et rendre une analyse reproductible :
les fondations de toute la bioinformatique ([Partie II](../partie2_bioinfo/README.md)).

**Par où commencer ?** Par le [chapitre 00](00_bienvenue_installation/README.md),
qui installe votre poste et votre bac à sable d'exercices. Suivez ensuite les
chapitres dans l'ordre : chacun s'appuie sur les précédents.

## Le parcours

| Bloc | Chapitre | Vous saurez… | Durée |
|---|---|---|---|
| **A · Premiers pas** | [00 — Bienvenue : installer votre poste](00_bienvenue_installation/README.md) | disposer d'un Linux et d'un bac à sable d'exercices | 1 h |
| | [01 — Premier contact avec le terminal](01_premier_contact/README.md) | lire une commande, trouver de l'aide, lire une erreur | 1 h 30 |
| | [02 — Le système de fichiers](02_systeme_de_fichiers/README.md) | vous repérer, désigner n'importe quel fichier | 1 h 30 |
| | [03 — Gérer fichiers et dossiers](03_gerer_fichiers/README.md) | créer, copier, déplacer, supprimer sans risque ; jokers, liens, `find` | 2 h |
| | [04 — Lire et inspecter des fichiers](04_lire_inspecter/README.md) | explorer FASTA et FASTQ, compression, intégrité | 2 h |
| **B · La puissance d'Unix** | [05 — Flux, redirections et pipes](05_flux_redirections_pipes/README.md) | enchaîner des commandes, enregistrer des résultats | 2 h |
| | [06 — Chercher et filtrer](06_chercher_filtrer/README.md) | grep, expressions régulières, cut, sort, uniq, tr | 2 h 30 |
| | [07 — awk et sed](07_awk_sed/README.md) | calculer et transformer tableaux et séquences | 3 h |
| | [★ Projet 1 — Inventaire d'un run de séquençage](projet1_inventaire_run/README.md) | vérifier, compter et qualifier une livraison de 24 FASTQ | 3-4 h |
| **C · Le système autour de vous** | [08 — Utilisateurs et permissions](08_permissions/README.md) | protéger vos données brutes | 1 h 30 |
| | [09 — Processus et ressources](09_processus/README.md) | lancer, suivre, arrêter de longs calculs ; tmux | 1 h 30 |
| | [10 — L'environnement du shell](10_environnement_shell/README.md) | variables, guillemets, `PATH`, nano, `.bashrc` | 2 h |
| | [11 — Installer des logiciels](11_installer_logiciels/README.md) | apt, Conda, Mamba, Bioconda, environnements reproductibles | 2 h |
| **D · Automatiser, travailler en professionnel** | [12 — Scripts Bash (I)](12_scripts_bash_1/README.md) | écrire un script qui traite tous vos échantillons | 3 h |
| | [13 — Scripts Bash (II)](13_scripts_bash_2/README.md) | rendre un script robuste, journalisé, débogable | 3 h |
| | [★ Projet 2 — Mon premier pipeline Bash](projet2_pipeline_bash/README.md) | un outil de contrôle qualité réutilisable | 4-6 h |
| | [14 — Travailler à distance (SSH)](14_ssh/README.md) | vous connecter à un serveur, transférer des fichiers | 2 h |
| | [15 — Git pour biologistes](15_git/README.md) | versionner et partager vos scripts | 2 h |
| | [16 — Les formats biologiques en pratique](16_formats_biologiques/README.md) | SAM/BAM, VCF, BED, GFF avec samtools, bcftools, bedtools | 3 h |
| | [17 — Organiser un projet](17_organiser_projet/README.md) | une arborescence et une analyse reproductibles | 1 h 30 |
| | [★ Projet 3 — Du gène au variant](projet3_du_gene_au_variant/README.md) | des variants aux conséquences sur les protéines | 3-4 h |
| | [★ Projet de synthèse](projet_synthese/README.md) | une analyse complète, versionnée, exécutée sur un serveur | 1 jour |

## Annexes

- [A — Administration d'une machine Linux](annexes/A_administration_systeme.md) (réseau, comptes, pare-feu, services : à pratiquer dans une machine virtuelle)
- [B — Aide-mémoire](annexes/B_aide_memoire.md) : tous les encadrés « L'essentiel » sur une page
- [C — Glossaire](annexes/C_glossaire.md)
- [D — Lire un message d'erreur](annexes/D_lire_une_erreur.md) : la méthode, et les messages fréquents avec leurs causes

## Données d'exercice

Toutes les données se trouvent dans [`../data/`](../data/README.md) et sont
copiées dans votre bac à sable `~/formation_linux` par
[`setup.sh`](../setup.sh). Elles sont synthétiques et conçues pour le cours :
un run Illumina de 12 échantillons (avec un échantillon raté et un fichier
corrompu à découvrir), un mini-génome annoté avec ses variants et ses
alignements, et des fichiers « pièges » pour apprendre à diagnostiquer.

Les outils de la Partie I s'installent d'un coup avec
[`envs/formation_partie1.yml`](../envs/formation_partie1.yml) (chapitre 11).

## Pour les contributeurs

Les chapitres suivent la [charte de rédaction](../docs/charte_pedagogique.md).
Chaque résultat annoncé dans une leçon, et chaque solution de projet, est
vérifié par `bash tests/run_all.sh` (lancé automatiquement à chaque
modification). Après avoir modifié un encadré « L'essentiel », régénérez
l'aide-mémoire : `python3 tools/generer_annexes.py`.
