# Chapitre 14 — Travailler à distance : SSH, clés, scp et rsync

> **Durée estimée** : 2 h
> **Prérequis** : [projet 2](../projet2_pipeline_bash/README.md) (et les chapitres [08](../08_permissions/README.md) sur les permissions et [09](../09_processus/README.md) sur tmux)
> **Chapitre suivant** : [15 — Git pour biologistes](../15_git/README.md)

## Ce que vous saurez faire à la fin de ce chapitre

- Vous connecter à une machine distante avec **SSH**, y exécuter des
  commandes et vous déconnecter.
- Créer une **paire de clés** SSH et l'installer pour vous connecter sans
  mot de passe, en sécurité.
- Simplifier vos connexions avec le fichier `~/.ssh/config`.
- Transférer des fichiers dans les deux sens avec **`scp`** et **`rsync`**,
  et reprendre un transfert interrompu.
- Lancer un calcul sur un serveur, vous déconnecter, et revenir chercher le
  résultat.

> **Sans serveur ? Aucun problème.** Ce chapitre vous fait installer un
> serveur SSH **sur votre propre machine**, et vous y connecter avec
> `ssh localhost`. Les commandes, les messages et les gestes sont
> exactement ceux que vous utiliserez sur le cluster d'un centre de calcul :
> seul le nom de la machine changera.

---

## 1. Pourquoi

Les analyses de génomique demandent des ressources que n'a pas un
ordinateur portable : des dizaines de cœurs, des centaines de Go de
mémoire, des To de disque. Elles tournent donc sur des **serveurs de
calcul**, souvent à l'autre bout du campus ou du pays. Vous y accéderez
**toujours** de la même façon : un terminal, et la commande `ssh`.

SSH (*Secure Shell*) ouvre un shell sur une machine distante, à travers une
connexion **chiffrée**. Tout ce que vous avez appris dans les chapitres
précédents fonctionne à l'identique de l'autre côté : `ls`, `cd`, vos
scripts, conda, tmux…

---

## 2. Une image pour comprendre : la clé, le cadenas et le registre

- **Se connecter**, c'est entrer dans un bâtiment distant. Vous prouvez votre
  identité par un **mot de passe**, ou mieux, par une **clé**.
- Une **paire de clés SSH**, c'est un **cadenas** et sa **clé** :
  - la **clé publique** (le cadenas) peut être distribuée à tout le monde :
    on la pose sur la porte du serveur ;
  - la **clé privée** (la clé) ne quitte **jamais** votre ordinateur. Seule
    elle ouvre le cadenas.
- Le fichier **`known_hosts`** est votre **registre des bâtiments vérifiés**.
  À la première visite, vous notez l'empreinte du serveur ; si un jour elle
  change, SSH vous alerte : vous êtes peut-être devant un imposteur.

---

## 3. Mettre en place le « serveur » : votre propre machine

Sur un vrai serveur, l'administrateur a déjà installé et démarré le service
SSH. Sur votre machine, faites-le une fois :

```bash
sudo apt update
sudo apt install -y openssh-server
sudo systemctl enable --now ssh
```

Vérifiez que le service écoute sur le port 22, le port standard de SSH :

```bash
ss -tln | grep ':22 '
```

Une ligne contenant `LISTEN` et `:22` doit s'afficher.

> **Si `systemctl` affiche `System has not been booted with systemd`**
> (anciennes versions de WSL), démarrez le service avec
> `sudo service ssh start`, à relancer après chaque redémarrage de WSL.
>
> **Sécurité** : ce serveur n'accepte que les connexions **depuis votre
> machine** tant que vous n'ouvrez pas votre réseau. Sous WSL, il n'est pas
> joignable depuis l'extérieur. Quand vous n'en avez plus besoin :
> `sudo systemctl disable --now ssh`.

---

## 4. Première connexion

```bash
ssh localhost
```

`localhost` désigne « cette machine-ci ». Sur un vrai serveur, vous
taperiez `ssh marie@cluster.universite.fr`. À la **première** connexion,
SSH ne connaît pas encore le serveur, et vous demande de vérifier son
empreinte :

```text
The authenticity of host 'localhost (127.0.0.1)' can't be established.
ED25519 key fingerprint is SHA256:Vb4lQ…(suite de l'empreinte)…
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added 'localhost' (ED25519) to the list of known hosts.
marie@localhost's password:
```

- Tapez **`yes`** (en entier). Sur un vrai serveur, comparez l'empreinte à
  celle publiée par le centre de calcul **avant** de répondre.
- Tapez votre mot de passe Ubuntu. Il ne s'affiche pas (chapitre 00).

Un message d'accueil s'affiche, puis une invite. Vous êtes « sur le
serveur ». Ici, c'est la même machine, mais **c'est un nouveau shell, dans
une nouvelle session** :

```bash
hostname
whoami
exit
```

```text
PC-LABO
marie
logout
Connection to localhost closed.
```

`exit` (ou **Ctrl+D**) ferme la session et vous ramène dans votre terminal
local.

> **Le réflexe vital : savoir où l'on est.** Avec plusieurs terminaux
> ouverts, l'un local, l'autre sur un serveur, lisez l'invite (chapitre 01)
> avant de taper une commande : `marie@PC-LABO` ou `marie@cluster-bioinfo` ?
> Un `rm` lancé sur la mauvaise machine a les mêmes conséquences que sur la
> bonne.

### Exécuter une seule commande à distance

```bash
ssh localhost 'hostname; ls ~/formation_linux | head -n 3'
```

Sans ouvrir de session interactive, SSH exécute la commande, affiche le
résultat et rend la main. Le **code de retour** de la commande distante est
transmis : `ssh localhost 'exit 3'; echo $?` affiche `3`. C'est utile dans
les scripts.

---

## 5. Les clés SSH : sans mot de passe, et plus sûr

### 5.1 Créer la paire de clés

```bash
ssh-keygen -t ed25519 -C "marie@formation"
```

```text
Generating public/private ed25519 key pair.
Enter file in which to save the key (/home/marie/.ssh/id_ed25519):
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /home/marie/.ssh/id_ed25519
Your public key has been saved in /home/marie/.ssh/id_ed25519.pub
The key fingerprint is:
SHA256:…(empreinte)… marie@formation
The key's randomart image is:
+--[ED25519 256]--+
|       B.        |
|      + =.       |
…
+----[SHA256]-----+
```

- **Entrée** pour accepter l'emplacement proposé.
- Une **phrase de passe** (*passphrase*) chiffre votre clé privée : si
  quelqu'un vole le fichier, il ne pourra pas s'en servir. **Mettez-en
  une.** Elle ne vous sera demandée qu'une fois par session (section 5.3).
- `-t ed25519` choisit un algorithme moderne et sûr ; `-C` ajoute un
  commentaire pour reconnaître la clé.

```bash
ls -l ~/.ssh
```

```text
-rw------- 1 marie marie 419 Nov 25 00:13 id_ed25519
-rw-r--r-- 1 marie marie 105 Nov 25 00:13 id_ed25519.pub
-rw-r--r-- 1 marie marie 142 Nov 25 00:12 known_hosts
```

| Fichier | Rôle | Permissions |
|---|---|---|
| `id_ed25519` | la clé **privée** : **ne jamais la copier, l'envoyer ni la versionner** | `600` : lisible par vous seul |
| `id_ed25519.pub` | la clé **publique**, à déposer sur les serveurs | `644` |
| `known_hosts` | les empreintes des serveurs déjà vérifiés | `644` |

### 5.2 Déposer la clé publique sur le serveur

```bash
ssh-copy-id localhost
```

Votre mot de passe vous est demandé **une dernière fois**, puis :

```text
Number of key(s) added: 1

Now try logging into the machine, with: "ssh 'localhost'"
and check to make sure that only the key(s) you wanted were added.
```

`ssh-copy-id` a ajouté votre clé publique au fichier
`~/.ssh/authorized_keys` **du serveur**. Désormais, `ssh localhost` vous
demande la phrase de passe de votre clé, et non plus votre mot de passe.

> **Sur un vrai cluster**, la méthode varie : certains centres acceptent
> `ssh-copy-id`, d'autres demandent de **déposer la clé publique sur un
> portail web**, sans mot de passe SSH. Lisez leur documentation. Dans tous
> les cas, on ne transmet **que le fichier `.pub`**.

### 5.3 Ne taper la phrase de passe qu'une fois : l'agent SSH

```bash
eval "$(ssh-agent)"
ssh-add
```

L'agent garde votre clé déverrouillée en mémoire pendant la session : les
connexions suivantes ne demandent plus rien. Sur un poste de bureau Ubuntu,
un agent tourne souvent déjà.

---

## 6. Simplifier : `~/.ssh/config`

Taper `ssh -p 2222 marie@calcul.universite.fr` à chaque fois est fastidieux
et source d'erreurs. Le fichier `~/.ssh/config` définit des **alias** :

```bash
nano ~/.ssh/config
```

```text
Host formation
    HostName localhost
    User marie
    IdentityFile ~/.ssh/id_ed25519

Host cluster
    HostName login.cluster.universite.fr
    User mdupont
    Port 22
```

```bash
chmod 600 ~/.ssh/config
ssh formation hostname
```

```text
PC-LABO
```

L'alias marche aussi pour `scp` et `rsync` : `scp fichier formation:`. Le
bloc `cluster` est un **exemple** de ce que vous écrirez avec les
informations de votre centre de calcul.

---

## 7. Transférer des fichiers

Pour simuler l'espace de travail d'un serveur, créez un dossier
`~/serveur_simule`. Sur un vrai serveur, ce serait par exemple
`/scratch/mdupont`.

```bash
mkdir -p ~/serveur_simule
```

### 7.1 `scp` : copier, comme `cp`, à travers SSH

```text
scp  SOURCE  DESTINATION          une machine distante s'écrit  machine:chemin
```

| Commande | Sens |
|---|---|
| `scp fichier formation:~/serveur_simule/` | **envoyer** (local → distant) |
| `scp formation:~/serveur_simule/fichier .` | **récupérer** (distant → local, `.` = ici) |
| `scp -r dossier formation:~/serveur_simule/` | un dossier entier (`-r`, comme `cp`) |

```bash
cd ~/formation_linux
scp formats/genes.bed formation:~/serveur_simule/
ssh formation 'ls ~/serveur_simule'
```

```text
genes.bed                                     100%  167   …KB/s   00:00
genes.bed
```

> **Le deux-points fait toute la différence.** `scp f formation:` envoie
> vers le serveur. `scp f formation`, **sans** `:`, crée une copie locale
> nommée `formation`, sans aucun message d'erreur.

### 7.2 `rsync` : synchroniser, l'outil des gros volumes

`rsync` ne transfère **que ce qui a changé** et sait reprendre un transfert
interrompu : c'est l'outil de choix pour les données de séquençage.

```bash
rsync -av run_sequencage/fastq/ formation:~/serveur_simule/fastq/
```

```text
sending incremental file list
created directory /home/marie/serveur_simule/fastq
./
MD5SUMS.txt
P01_S1_L001_R1_001.fastq.gz
…
sent 641,559 bytes  received 564 bytes  1,284,246.00 bytes/sec
total size is 639,465  speedup is 1.00
```

Relancez **exactement** la même commande :

```text
sending incremental file list

sent 968 bytes  received 12 bytes  653.33 bytes/sec
total size is 639,465  speedup is 652.52
```

Aucun fichier n'est retransféré : `rsync` a comparé les tailles et les dates,
et constaté que tout était déjà à jour. Sur un run de 500 Go, cette
différence se compte en heures.

| Option | Effet |
|---|---|
| `-a` | mode archive : récursif, conserve dates et permissions |
| `-v` | affiche les fichiers transférés |
| `-P` | affiche la progression, **et garde les fichiers partiels** pour reprendre un transfert interrompu |
| `-n` | simulation (*dry run*) : affiche ce qui **serait** fait, sans rien faire |
| `--delete` | supprime dans la destination ce qui n'existe pas dans la source |

### 7.3 Le piège de la barre finale

```bash
rsync -av run_sequencage/fastq/ formation:~/serveur_simule/A/
rsync -av run_sequencage/fastq  formation:~/serveur_simule/B/
```

- **Avec** `/` (`fastq/`) : le **contenu** de `fastq` est copié dans `A/`.
- **Sans** `/` (`fastq`) : le **dossier** `fastq` est copié dans `B/`, ce
  qui donne `B/fastq/…`.

Ce n'est pas une erreur, mais une source fréquente de dossiers imbriqués
inattendus. Prenez une convention (par exemple : toujours `source/` vers
`destination/`) et tenez-vous-y.

### 7.4 `--delete` : toujours simuler d'abord

`--delete` rend la destination **identique** à la source, en **supprimant**
ce qui manque à la source. Une inversion de source et de destination, et
ce sont **vos données** qui disparaissent. Simulez toujours avec `-n` :

```bash
rsync -avn --delete formats/ formation:~/serveur_simule/fastq/
```

```text
sending incremental file list
deleting P12_S12_L001_R2_001.fastq.gz
deleting P12_S12_L001_R1_001.fastq.gz
deleting P11_S11_L001_R2_001.fastq.gz
…
```

Cette simulation révèle l'erreur : on s'apprêtait à remplacer le dossier
des FASTQ par celui des formats, en **effaçant les reads**. Rien n'a été
supprimé, grâce à `-n`.

> **Après un transfert de données brutes, vérifiez toujours les sommes de
> contrôle de l'autre côté** (chapitre 04) :
> `ssh formation 'cd ~/serveur_simule/fastq && md5sum -c MD5SUMS.txt'`.

---

## 8. Travailler sur le serveur : le cycle complet

Le scénario de tous les jours :

```bash
# 1. Envoyer les données et le script
rsync -av ~/formation_linux/run_sequencage/ formation:~/serveur_simule/run/
scp ~/formation_linux/qc_run.sh formation:~/serveur_simule/

# 2. Se connecter, lancer le calcul dans tmux (chapitre 09)
ssh formation
tmux new -s qc
cd ~/serveur_simule
bash qc_run.sh --run run/fastq --feuille run/echantillons.tsv --sortie qc
# Ctrl+B puis D : se détacher ; puis exit : se déconnecter

# 3. Plus tard : revenir voir
ssh formation
tmux attach -t qc

# 4. Rapatrier les résultats, depuis la machine locale
rsync -av formation:~/serveur_simule/qc/ ~/formation_linux/qc_serveur/
```

Grâce à tmux, le calcul **continue** quand vous vous déconnectez. C'est
indispensable sur un vrai serveur, où une coupure réseau arrêterait sinon
votre analyse.

> **Sur un cluster**, on ne lance pas les calculs lourds sur la machine de
> connexion, mais on les **soumet** à un ordonnanceur (SLURM : module 36 de
> la Partie II). L'enchaînement « envoyer, se connecter, lancer, rapatrier »
> reste le même.

---

## 9. Sécurité : les règles non négociables

1. **La clé privée ne quitte jamais votre machine.** On ne l'envoie pas par
   e-mail, on ne la copie pas sur une clé USB partagée, on ne la met jamais
   dans un dépôt Git (chapitre 15).
2. **Une phrase de passe sur la clé**, et `chmod 600 ~/.ssh/id_ed25519`
   (SSH refuse d'ailleurs une clé trop ouverte, voir ci-dessous).
3. **Une alerte sur l'identité du serveur n'est jamais anodine.** Si SSH
   affiche `WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!`, **ne
   contournez pas** l'alerte : contactez d'abord les administrateurs. Le
   serveur a peut-être été réinstallé, ou quelqu'un se fait peut-être passer
   pour lui. S'ils confirment un changement légitime, retirez l'ancienne
   empreinte avec `ssh-keygen -R nom_du_serveur`.
4. **Les identifiants sont personnels** : on ne partage pas un compte de
   cluster.

---

## 10. Pièges fréquents

| Message | Cause probable | Solution |
|---|---|---|
| `ssh: connect to host localhost port 22: Connection refused` | aucun serveur SSH ne tourne, ou mauvais port | `sudo systemctl start ssh` ; vérifier le port (`-p`, ou `Port` dans `config`) |
| `Permission denied (publickey).` | clé non installée sur le serveur, mauvais utilisateur, ou mauvaise clé | `ssh-copy-id` ; vérifier `User` et `IdentityFile` |
| `WARNING: UNPROTECTED PRIVATE KEY FILE! … Permissions 0644 … are too open.` | clé privée lisible par les autres | `chmod 600 ~/.ssh/id_ed25519` |
| `Host key verification failed.` | empreinte inconnue en mode non interactif, ou empreinte qui a changé | se connecter une fois en interactif ; en cas de changement, contacter l'administrateur (section 9) |
| `ssh: Could not resolve hostname formation: Name or service not known` | alias mal écrit ou absent de `~/.ssh/config` | vérifier le fichier `config` |
| la connexion reste bloquée, puis `Connection timed out` | réseau, pare-feu, VPN de l'établissement non connecté | se connecter au VPN ; vérifier l'adresse |
| `scp` sans `:` | fichier copié en local sous le nom du serveur | `machine:chemin` |
| `rsync` crée `dossier/dossier/` | barre finale omise dans la source | `source/` |

---

## 11. À vous de jouer

### Exercice 1 : la première connexion

*Objectif : installer, se connecter, se repérer.*
Installez et démarrez le serveur SSH, connectez-vous à `localhost`, affichez
le nom de la machine, la date et le dossier courant, puis déconnectez-vous.
Où se trouve maintenant l'empreinte du serveur ?

<details>
<summary>Corrigé</summary>

```bash
sudo apt install -y openssh-server
sudo systemctl enable --now ssh
ssh localhost
hostname; date; pwd
exit
cat ~/.ssh/known_hosts
```

`pwd` affiche `/home/marie` : une session SSH commence dans votre dossier
personnel. L'empreinte du serveur a été enregistrée dans
`~/.ssh/known_hosts`.
</details>

### Exercice 2 : la connexion par clé

*Objectif : `ssh-keygen`, `ssh-copy-id`, `chmod`.*
Créez une paire de clés **avec une phrase de passe**, installez-la sur
`localhost`, et vérifiez que la connexion ne demande plus votre mot de passe
Ubuntu. Expliquez pourquoi `chmod 644 ~/.ssh/id_ed25519` empêche ensuite la
connexion par clé, puis rétablissez les bonnes permissions.

<details>
<summary>Corrigé</summary>

```bash
ssh-keygen -t ed25519 -C "marie@formation"
ssh-copy-id localhost
ssh localhost hostname
chmod 644 ~/.ssh/id_ed25519
ssh localhost hostname
chmod 600 ~/.ssh/id_ed25519
```

Avec `644`, SSH affiche `WARNING: UNPROTECTED PRIVATE KEY FILE!` et
**ignore** la clé : une clé lisible par d'autres utilisateurs est
considérée comme compromise. Selon la configuration du serveur, il revient
alors au mot de passe ou refuse la connexion.
</details>

### Exercice 3 : un alias

*Objectif : `~/.ssh/config`.*
Créez l'alias `labo`, qui pointe vers `localhost` avec votre utilisateur et
votre clé. Vérifiez avec `ssh labo hostname`, puis exécutez à distance,
sans ouvrir de session, le comptage des séquences de `genome.fasta`.

<details>
<summary>Corrigé</summary>

Dans `~/.ssh/config` :

```text
Host labo
    HostName localhost
    User marie
    IdentityFile ~/.ssh/id_ed25519
```

```bash
chmod 600 ~/.ssh/config
ssh labo hostname
ssh labo 'grep -c "^>" ~/formation_linux/genome.fasta'
```

```text
PC-LABO
22
```

Les apostrophes empêchent votre shell **local** d'interpréter les
guillemets et le `~` : la commande entière est transmise au serveur, qui
l'interprète lui-même.
</details>

### Exercice 4 : transférer un run, vérifier

*Objectif : `rsync`, `-n`, et le contrôle d'intégrité.*
Envoyez le dossier `run_sequencage/fastq/` dans `~/serveur_simule/fastq/`
via l'alias `labo` : simulez d'abord avec `-n`, puis transférez. Relancez
le transfert et observez la différence. Enfin, vérifiez les sommes MD5
**côté serveur**.

<details>
<summary>Corrigé</summary>

```bash
cd ~/formation_linux
rsync -avn run_sequencage/fastq/ labo:~/serveur_simule/fastq/
rsync -av  run_sequencage/fastq/ labo:~/serveur_simule/fastq/
rsync -av  run_sequencage/fastq/ labo:~/serveur_simule/fastq/
ssh labo 'cd ~/serveur_simule/fastq && md5sum -c MD5SUMS.txt | grep -c ": OK$"'
```

Le second transfert n'envoie aucun fichier (`speedup` élevé). Le contrôle
donne `23` : comme au départ, seul le fichier déjà corrompu à la livraison
échoue. Le transfert n'a rien abîmé.
</details>

---

## 12. Défi : le calcul qui survit à la déconnexion

Rejouez le cycle de la section 8 avec le pipeline du projet 2 :

1. envoyez le run et `qc_run.sh` sur le « serveur » (`~/serveur_simule`) ;
2. lancez le pipeline **dans une session tmux du serveur**, précédé d'un
   `sleep 60` pour simuler un long calcul ;
3. **déconnectez-vous pendant le calcul**, et fermez même le terminal ;
4. reconnectez-vous, vérifiez que le calcul s'est terminé, et rapatriez
   `qc/` sur votre machine, dans `~/formation_linux/qc_serveur/`.

<details>
<summary>Corrigé</summary>

```bash
cd ~/formation_linux
rsync -av run_sequencage/ labo:~/serveur_simule/run/
scp qc_run.sh labo:~/serveur_simule/

ssh labo
tmux new -s qc
cd ~/serveur_simule
sleep 60; bash qc_run.sh --run run/fastq --feuille run/echantillons.tsv --sortie qc
# Ctrl+B puis D, puis exit, puis fermer le terminal

# Nouveau terminal, au moins une minute plus tard :
ssh labo 'tmux ls; tail -n 1 ~/serveur_simule/qc/pipeline.log'
rsync -av labo:~/serveur_simule/qc/ ~/formation_linux/qc_serveur/
```

Le journal se termine par `Fin : 10 échantillon(s) retenu(s) sur 12` : le
calcul a continué en votre absence. Si `tmux ls` affiche encore la session,
rattachez-vous (`tmux attach -t qc`) et fermez-la avec `exit`. Les liens de
`donnees_valides/` pointent vers des chemins du serveur : ils sont cassés
sur votre machine, ce qui est normal (chapitre 03).
</details>

---

## L'essentiel

```text
sudo apt install openssh-server ; sudo systemctl enable --now ssh    (le « serveur » local)
ssh localhost   ssh utilisateur@machine   exit / Ctrl+D   ssh machine 'commande'
1re connexion : vérifier l'empreinte, yes → ~/.ssh/known_hosts
ssh-keygen -t ed25519 (avec phrase de passe) ; ssh-copy-id machine
id_ed25519 = PRIVÉE (600, ne jamais partager) ; id_ed25519.pub = publique
eval "$(ssh-agent)" ; ssh-add                    phrase de passe une seule fois
~/.ssh/config : Host alias / HostName / User / Port / IdentityFile
scp f machine:chemin/   scp machine:chemin/f .   scp -r
rsync -av source/ machine:dest/   -P reprise   -n simulation   --delete (simuler d'abord !)
Calcul long à distance : tmux ; après transfert : md5sum -c
```

### Auto-évaluation

- [ ] Je me connecte à une machine distante et je sais toujours sur quelle machine je tape.
- [ ] J'ai créé une paire de clés protégée par une phrase de passe, et je sais quel fichier ne jamais partager.
- [ ] J'utilise un alias défini dans `~/.ssh/config`.
- [ ] Je transfère des fichiers dans les deux sens avec `scp` et `rsync`.
- [ ] Je simule un `rsync --delete` avant de le lancer.
- [ ] J'ai lancé un calcul distant dans tmux et récupéré son résultat après déconnexion.

## Documentation officielle

- OpenSSH (manuels de `ssh`, `ssh-keygen`, `ssh_config`, `scp`) : <https://www.openssh.com/manual.html>
- Serveur OpenSSH sous Ubuntu 24.04 (page de manuel de `sshd`) : <https://manpages.ubuntu.com/manpages/noble/man8/sshd.8.html>
- rsync : <https://download.samba.org/pub/rsync/rsync.1>

**Prochaine étape** : [chapitre 15 — Git pour biologistes](../15_git/README.md).
