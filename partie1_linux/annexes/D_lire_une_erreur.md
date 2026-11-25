# Annexe D — Lire un message d'erreur : la méthode et les messages fréquents

## La méthode en quatre temps

1. **Qui parle ?** Le nom avant le premier `:` est le programme qui signale
   l'erreur (`head:`, `bash:`, `gzip:`, `samtools view:`).
2. **De quoi parle-t-il ?** Ce qui est entre guillemets est souvent le
   fichier ou la valeur en cause. Vérifiez son orthographe, sa casse, son
   chemin.
3. **Quel est le problème ?** La fin du message le dit, en anglais
   (traductions ci-dessous).
4. **Une correction, puis on relance.** Si le message change, c'est un
   progrès : on passe au suivant ([chapitre 13, section 9](../13_scripts_bash_2/README.md)).

Et quand il n'y a **pas** de message ? Vérifiez que le résultat existe et
qu'il est plausible : un nombre de reads supérieur au nombre de lignes ÷ 4,
un fichier vide (`[ -s fichier ]`), un code de retour non nul (`echo $?`).
Certains outils échouent en silence, ou signalent une erreur tout en
renvoyant 0 ([chapitre 11, exercice 3](../11_installer_logiciels/README.md)).

## Les messages les plus fréquents

| Message | Traduction | Causes habituelles | Chapitre |
|---|---|---|---|
| `No such file or directory` | fichier ou dossier introuvable | faute de frappe, casse, mauvais dossier courant, chemin relatif depuis le mauvais endroit | [01](../01_premier_contact/README.md), [02](../02_systeme_de_fichiers/README.md) |
| `command not found` | commande introuvable | faute de frappe, logiciel non installé, environnement conda non activé, `PATH` modifié, script sans `./` | [01](../01_premier_contact/README.md), [10](../10_environnement_shell/README.md), [11](../11_installer_logiciels/README.md) |
| `Permission denied` | permission refusée | script sans droit `x`, dossier protégé en écriture, fichier d'un autre utilisateur | [08](../08_permissions/README.md) |
| `Is a directory` / `Not a directory` | c'est un dossier / ce n'est pas un dossier | fichier et dossier confondus | [01](../01_premier_contact/README.md), [02](../02_systeme_de_fichiers/README.md) |
| `invalid option` / `invalid number of lines` | option ou valeur invalide | option inexistante pour cette commande, mot à la place d'un nombre | [01](../01_premier_contact/README.md) |
| `missing operand` | argument manquant | fichier oublié | [01](../01_premier_contact/README.md) |
| `cannot create directory … No such file or directory` | dossier parent absent | `mkdir` sans `-p` | [03](../03_gerer_fichiers/README.md) |
| `-r not specified; omitting directory` | dossier ignoré | `cp` d'un dossier sans `-r` | [03](../03_gerer_fichiers/README.md) |
| `Directory not empty` | dossier non vide | `rmdir` sur un dossier qui contient des fichiers | [03](../03_gerer_fichiers/README.md) |
| `paths must precede expression` | arguments de `find` incohérents | motif `-name` sans guillemets | [03](../03_gerer_fichiers/README.md) |
| `unexpected end of file` (gzip) | fin de fichier inattendue | archive tronquée, téléchargement interrompu | [04](../04_lire_inspecter/README.md) |
| `FAILED` / `computed checksum did NOT match` | somme de contrôle incorrecte | fichier corrompu : le re-télécharger | [04](../04_lire_inspecter/README.md) |
| `cannot overwrite existing file` | écrasement refusé | `noclobber` actif | [05](../05_flux_redirections_pipes/README.md) |
| `[150: command not found` | — | espace manquant dans `[ … ]` | [12](../12_scripts_bash_1/README.md) |
| `unary operator expected` | — | variable vide sans guillemets dans `[ … ]` | [12](../12_scripts_bash_1/README.md) |
| `unbound variable` | variable non définie | faute de frappe, argument manquant (avec `set -u`) | [13](../13_scripts_bash_2/README.md) |
| `syntax error: unexpected end of file` | fin de script inattendue | `if` sans `fi`, guillemet ou `{` non refermé | [13](../13_scripts_bash_2/README.md) |
| `/usr/bin/env: 'bash\r'` / `$'\r': command not found` | — | script aux fins de ligne Windows | [13](../13_scripts_bash_2/README.md) |
| `Killed` (sans autre explication) | processus arrêté par le système | mémoire insuffisante | [09](../09_processus/README.md) |
| `No space left on device` | plus de place | disque plein | [09](../09_processus/README.md) |
| `EnvironmentNameNotFound` | environnement conda introuvable | faute de frappe, environnement non créé | [11](../11_installer_logiciels/README.md) |
| `PackagesNotFoundInChannelsError` | paquet introuvable | nom erroné, canal `bioconda` manquant | [11](../11_installer_logiciels/README.md) |
| `are you root?` (apt) | droits administrateur requis | `apt install` sans `sudo` | [11](../11_installer_logiciels/README.md) |
| `Connection refused` | connexion refusée | serveur SSH arrêté, mauvais port | [14](../14_ssh/README.md) |
| `Permission denied (publickey)` | clé refusée | clé non installée sur le serveur, mauvais utilisateur | [14](../14_ssh/README.md) |
| `UNPROTECTED PRIVATE KEY FILE!` | clé privée trop ouverte | `chmod 600 ~/.ssh/id_ed25519` | [14](../14_ssh/README.md) |
| `Host key verification failed` | identité du serveur non vérifiée | première connexion en mode non interactif, ou empreinte changée (prudence) | [14](../14_ssh/README.md) |
| `fatal: not a git repository` | pas dans un dépôt Git | mauvais dossier | [15](../15_git/README.md) |
| `The following paths are ignored` | fichier ignoré par Git | il est dans `.gitignore` (voulu pour les données) | [15](../15_git/README.md) |
| `invalid region or unknown reference` (samtools) | région inconnue | nom de chromosome inexact | [16](../16_formats_biologiques/README.md) |
| `TAB delimited` (bedtools) | format incorrect | fichier BED séparé par des espaces | [16](../16_formats_biologiques/README.md) |

## Chercher de l'aide en ligne

1. Copiez la partie **générique** du message, sans vos noms de fichiers :
   `invalid number of lines`, et non `head: invalid number of lines: ‘deux’`.
2. Ajoutez le nom de l'outil : `samtools invalid region`.
3. Préférez la documentation officielle, puis les forums spécialisés
   ([Biostars](https://www.biostars.org/), Stack Overflow).
4. Pour demander de l'aide à quelqu'un, donnez : la **commande exacte**, le
   **message complet**, ce que vous attendiez, et ce que vous avez déjà
   essayé.

---

**Retour** : [sommaire de la Partie I](../README.md)
