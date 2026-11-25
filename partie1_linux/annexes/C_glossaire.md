# Annexe C — Glossaire

Les termes techniques de la Partie I, avec le chapitre où ils sont
expliqués. Les équivalents anglais, que vous lirez dans les documentations,
sont indiqués entre parenthèses.

| Terme | Définition | Chapitre |
|---|---|---|
| **absolu (chemin)** | chemin qui part de la racine `/` (ou de `~`) et fonctionne d'où que l'on soit | [02](../02_systeme_de_fichiers/README.md) |
| **adaptateur** | courte séquence artificielle ajoutée aux fragments d'ADN pour le séquençage ; lue à tort quand le fragment est court | [04](../04_lire_inspecter/README.md), [06](../06_chercher_filtrer/README.md) |
| **alias** | raccourci pour une commande, défini dans `~/.bashrc` | [10](../10_environnement_shell/README.md) |
| **argument** | ce sur quoi agit une commande (souvent un nom de fichier) ; `$1`, `$2`… dans un script | [01](../01_premier_contact/README.md), [12](../12_scripts_bash_1/README.md) |
| **arrière-plan** (*background*) | exécution d'une commande qui rend la main au terminal (`&`) | [09](../09_processus/README.md) |
| **BAM** | version binaire, compressée et indexable du format SAM | [16](../16_formats_biologiques/README.md) |
| **BED** | format de régions génomiques, en coordonnées **0-based**, fin exclue | [16](../16_formats_biologiques/README.md) |
| **Bioconda** | canal conda spécialisé en logiciels de bioinformatique | [11](../11_installer_logiciels/README.md) |
| **branche** (*branch*) | ligne de développement parallèle dans un dépôt Git | [15](../15_git/README.md) |
| **CIGAR** | chaîne décrivant un alignement : `M` aligné, `I` insertion, `D` délétion… | [16](../16_formats_biologiques/README.md) |
| **clé SSH** | paire publique (à déposer sur les serveurs) / privée (à ne jamais partager) pour se connecter sans mot de passe | [14](../14_ssh/README.md) |
| **code de retour** (*exit status*) | nombre renvoyé par une commande : `0` = succès ; consultable avec `$?` | [05](../05_flux_redirections_pipes/README.md) |
| **commit** | enregistrement daté et commenté de l'état des fichiers dans Git | [15](../15_git/README.md) |
| **conda / mamba** | gestionnaires de paquets et d'environnements, utilisables sans droits administrateur | [11](../11_installer_logiciels/README.md) |
| **CRLF** | fin de ligne Windows (`\r\n`) ; Linux n'utilise que `\n` (LF) | [04](../04_lire_inspecter/README.md), [06](../06_chercher_filtrer/README.md) |
| **dossier courant** (*working directory*) | dossier où l'on se trouve, affiché par `pwd` | [02](../02_systeme_de_fichiers/README.md) |
| **environnement (conda)** | ensemble isolé de logiciels et de versions, activé avec `conda activate` | [11](../11_installer_logiciels/README.md) |
| **environnement (variables d')** | variables exportées, transmises aux programmes lancés (`PATH`, `HOME`…) | [10](../10_environnement_shell/README.md) |
| **expression régulière** (*regex*) | motif qui décrit une famille de textes (`^>`, `[ACGT]+`) | [06](../06_chercher_filtrer/README.md) |
| **FASTA** | format de séquences : en-tête `>id`, puis la séquence sur une ou plusieurs lignes | [04](../04_lire_inspecter/README.md) |
| **FASTQ** | format de reads : 4 lignes par read (identifiant, séquence, `+`, qualité) | [04](../04_lire_inspecter/README.md) |
| **flux standard** | les trois « tuyaux » d'une commande : entrée (0), sortie (1), erreurs (2) | [05](../05_flux_redirections_pipes/README.md) |
| **FLAG** | nombre qui code les propriétés d'un alignement SAM (non aligné, brin inverse…) | [16](../16_formats_biologiques/README.md) |
| **fonction** (Bash) | bloc de commandes nommé, réutilisable dans un script | [13](../13_scripts_bash_2/README.md) |
| **GFF3 / GTF** | formats d'annotation (gènes, exons…), en coordonnées **1-based** | [16](../16_formats_biologiques/README.md) |
| **glob, joker** (*wildcard*) | `*`, `?`, `[ ]` : motifs de noms de fichiers développés par le shell | [03](../03_gerer_fichiers/README.md) |
| **gzip, `.gz`** | format de compression standard des FASTQ | [04](../04_lire_inspecter/README.md) |
| **index** | fichier annexe (`.fai`, `.bai`, `.csi`) qui permet un accès direct à une région | [16](../16_formats_biologiques/README.md) |
| **invite** (*prompt*) | la ligne `marie@PC-LABO:~$` qui attend une commande | [01](../01_premier_contact/README.md) |
| **lien symbolique** (*symlink*) | petit fichier qui pointe vers un autre, pour l'utiliser sans le copier | [03](../03_gerer_fichiers/README.md) |
| **MAPQ** | qualité de l'alignement d'un read (60 : position sûre ; 0 : ambiguë) | [16](../16_formats_biologiques/README.md) |
| **md5sum, somme de contrôle** (*checksum*) | empreinte d'un fichier, qui permet de vérifier qu'il est intact | [04](../04_lire_inspecter/README.md) |
| **noyau** (*kernel*) | le cœur du système, qui gère le matériel | [01](../01_premier_contact/README.md) |
| **option** | modifie le comportement d'une commande (`-n 3`, `--lines=3`) | [01](../01_premier_contact/README.md) |
| **paired-end** | séquençage des deux extrémités d'un fragment : deux fichiers, R1 et R2 | [02](../02_systeme_de_fichiers/README.md), [04](../04_lire_inspecter/README.md) |
| **PATH** | liste des dossiers où le shell cherche les programmes | [10](../10_environnement_shell/README.md) |
| **permissions** | droits `r`, `w`, `x` du propriétaire, du groupe et des autres | [08](../08_permissions/README.md) |
| **Phred (score)** | qualité d'une base : Q30 = 1 erreur sur 1 000 ; caractère ASCII − 33 | [16](../16_formats_biologiques/README.md) |
| **PID** | numéro d'identification d'un processus | [09](../09_processus/README.md) |
| **pipe** `\|` | branche la sortie d'une commande sur l'entrée de la suivante | [05](../05_flux_redirections_pipes/README.md) |
| **processus** | programme en cours d'exécution | [09](../09_processus/README.md) |
| **racine** (*root directory*) | le dossier `/`, d'où part toute l'arborescence | [02](../02_systeme_de_fichiers/README.md) |
| **redirection** | envoie une sortie dans un fichier (`>`, `>>`, `2>`) ou lit l'entrée d'un fichier (`<`) | [05](../05_flux_redirections_pipes/README.md) |
| **relatif (chemin)** | chemin qui part du dossier courant | [02](../02_systeme_de_fichiers/README.md) |
| **reproductibilité** | capacité à refaire une analyse et à obtenir exactement le même résultat | [11](../11_installer_logiciels/README.md), [17](../17_organiser_projet/README.md) |
| **root** | l'administrateur du système, qui a tous les droits | [08](../08_permissions/README.md) |
| **SAM** | format texte des alignements de reads sur une référence | [16](../16_formats_biologiques/README.md) |
| **script** | fichier de commandes exécutées dans l'ordre | [12](../12_scripts_bash_1/README.md) |
| **shell** | programme qui interprète les commandes tapées (ici **bash**) | [01](../01_premier_contact/README.md) |
| **soft-masking** | régions en minuscules d'un FASTA, souvent des répétitions | [04](../04_lire_inspecter/README.md), [06](../06_chercher_filtrer/README.md) |
| **SSH** | protocole de connexion chiffrée à une machine distante | [14](../14_ssh/README.md) |
| **sudo** | exécute une commande avec les droits de root | [08](../08_permissions/README.md) |
| **terminal** | fenêtre dans laquelle on tape les commandes | [01](../01_premier_contact/README.md) |
| **tmux** | gestionnaire de sessions de terminal qui survivent à la déconnexion | [09](../09_processus/README.md) |
| **VCF** | format des variants génomiques, en coordonnées **1-based** | [16](../16_formats_biologiques/README.md) |
| **WSL** | sous-système Windows qui fait fonctionner un vrai Linux | [00](../00_bienvenue_installation/README.md) |

---

**Retour** : [sommaire de la Partie I](../README.md)
