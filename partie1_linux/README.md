# Partie I — Linux pour biologistes

Un parcours pour les étudiants en biologie qui n'ont **jamais utilisé la
ligne de commande**. À la fin, vous saurez explorer et filtrer des données
de séquençage, automatiser un traitement sur des dizaines d'échantillons,
et travailler sur un serveur de calcul : les fondations de toute la
bioinformatique (Partie II).

**Par où commencer ?** Par le [chapitre 00](00_bienvenue_installation/README.md),
qui installe votre poste et votre bac à sable d'exercices.

## Le parcours

| Bloc | Chapitre | Vous saurez… | État |
|---|---|---|---|
| **A · Premiers pas** | [00 — Bienvenue : installer votre poste](00_bienvenue_installation/README.md) | disposer d'un Linux et d'un bac à sable d'exercices | ✅ rédigé |
| | [01 — Premier contact avec le terminal](01_premier_contact/README.md) | lire une commande, trouver de l'aide, lire une erreur | ✅ rédigé |
| | [02 — Le système de fichiers](02_systeme_de_fichiers/README.md) | vous repérer dans l'arborescence, désigner n'importe quel fichier | ✅ rédigé |
| | [03 — Gérer fichiers et dossiers](03_gerer_fichiers/README.md) | créer, copier, déplacer, supprimer sans risque ; jokers | ✅ rédigé |
| | [04 — Lire et inspecter des fichiers](04_lire_inspecter/README.md) | explorer FASTA, FASTQ, fichiers compressés | ✅ rédigé |
| **B · La puissance d'Unix** | 05 — Flux, redirections et pipes | enchaîner des commandes, enregistrer des résultats | en préparation |
| | 06 — Chercher et filtrer | grep, expressions régulières, cut, sort, uniq | en préparation |
| | 07 — awk et sed pour les données biologiques | calculer et transformer des tableaux et des séquences | en préparation |
| | ★ Projet 1 — Inventaire d'un run de séquençage | | en préparation |
| **C · Le système autour de vous** | 08 — Utilisateurs et permissions | protéger vos données brutes | en préparation |
| | 09 — Processus et ressources | lancer, suivre et arrêter de longs calculs | en préparation |
| | 10 — L'environnement du shell | variables, PATH, guillemets, personnaliser son shell | en préparation |
| | 11 — Installer des logiciels | apt, Conda/Mamba/Bioconda | en préparation |
| **D · Automatiser, travailler en professionnel** | 12 — Scripts Bash (I) | écrire un script qui traite tous vos échantillons | en préparation |
| | 13 — Scripts Bash (II) | rendre un script robuste et journalisé | en préparation |
| | ★ Projet 2 — Mon premier pipeline Bash | | en préparation |
| | 14 — Travailler à distance (SSH) | vous connecter à un serveur, transférer des fichiers | en préparation |
| | 15 — Git pour biologistes | versionner vos scripts | en préparation |
| | 16 — Les formats biologiques en pratique | SAM/BAM, VCF, BED, GFF avec samtools, bcftools, bedtools | en préparation |
| | 17 — Organiser un projet | arborescence, métadonnées, bonnes pratiques | en préparation |
| | ★ Projet 3 — Du gène au variant · ★ Projet de synthèse | | en préparation |

## Données d'exercice

Toutes les données se trouvent dans [`../linux/`](../linux/README.md) et
sont copiées dans votre bac à sable `~/formation_linux` par
[`setup.sh`](../setup.sh). Elles sont synthétiques et conçues pour le cours.

## Pour les contributeurs

Les chapitres suivent la [charte de rédaction](../docs/charte_pedagogique.md).
Chaque résultat annoncé dans une leçon est vérifié par `bash tests/run_all.sh`.
