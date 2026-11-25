# Annexe A — Administration d'une machine Linux

> **À lire, et à pratiquer uniquement dans une machine virtuelle ou sur une
> machine de test.** Ces commandes modifient le système : comptes, réseau,
> pare-feu, services, extinction. Sur un serveur partagé, vous n'aurez pas
> les droits pour les exécuter, et vous ne devez pas essayer. Sur votre
> propre machine, une erreur (un pare-feu mal réglé, un compte supprimé)
> peut la rendre difficile à utiliser.

Cette annexe reprend, **sans modification de fond**, les sections 13 à 16 de
l'ancien module `01_linux_basics` (conservé dans
[`legacy/anciens_modules/`](../../legacy/anciens_modules/)). Elles ont été
retirées du parcours principal, car un biologiste en a rarement besoin pour
analyser des données. Elles restent utiles pour comprendre une machine Linux
ou pour administrer un petit serveur d'équipe.

Elles suivent le format de fiche de l'ancien cours (COMMAND, PURPOSE,
SYNTAX…). Pour l'essentiel du quotidien, voir plutôt :

- installer des logiciels : [chapitre 11](../11_installer_logiciels/README.md) ;
- `sudo` et les droits : [chapitre 08](../08_permissions/README.md) ;
- le service SSH : [chapitre 14](../14_ssh/README.md).

> **Exercices** : les exercices des fiches qui créent des comptes
> (`adduser`), modifient le pare-feu (`ufw enable`) ou éteignent la machine
> (`shutdown`) ne doivent être faits **que dans une machine virtuelle**. Une
> solution simple : une seconde distribution WSL (`wsl --install -d Debian`)
> ou une machine virtuelle VirtualBox, que l'on peut supprimer ensuite.

## A.1 Réseau de base

```text
COMMAND: ping
PURPOSE: envoyer des paquets à une adresse ou un nom de domaine pour
         vérifier qu'il est joignable sur le réseau, et mesurer le temps
         de réponse.
SYNTAX: ping adresse_ou_domaine
        ping -c 4 adresse_ou_domaine   (limite à 4 paquets, recommandé)
OPTIONS:
  -c N   arrête après N paquets envoyés (sans -c, ping continue
         indéfiniment ; arrêter avec Ctrl+C)
OUTPUT: une ligne par paquet reçu, avec le temps de réponse (ex.
         time=12.3 ms), puis un résumé statistique
INTERPRETATION: en bioinformatique, ping sert surtout à diagnostiquer une
         panne réseau avant de soupçonner à tort un outil de
         téléchargement (curl, module 08 de la Partie II) de mal fonctionner.
COMMON ERRORS:
  - "Name or service not known" → le nom de domaine est incorrect ou le
    DNS ne répond pas.
  - aucune réponse alors que la machine est en ligne → un pare-feu (voir
    ufw/iptables, section A.4) peut bloquer les paquets ICMP sans que cela
    signifie une panne réelle.
DOCUMENTATION: https://man7.org/linux/man-pages/man8/ping.8.html
EXERCISE: `ping -c 4 8.8.8.8` (adresse publique de Google DNS) pour
         vérifier sa connexion Internet.
```

```text
COMMAND: ifconfig
PURPOSE: afficher (ou configurer) les interfaces réseau et leurs adresses
         IP — commande historique, remplacée sur les distributions
         récentes par `ip a`.
SYNTAX: ifconfig
OUTPUT: la liste des interfaces réseau (ex. eth0, wlan0, lo) avec leur
         adresse IP
INTERPRETATION: si la commande n'est pas trouvée, c'est le signe normal
         d'une distribution récente qui a migré vers `ip` (paquet
         iproute2) ; installer le paquet net-tools si l'usage de ifconfig
         est spécifiquement requis.
COMMON ERRORS:
  - "command not found" sur une distribution récente → utiliser `ip a` à
    la place, ou installer net-tools.
DOCUMENTATION: https://man7.org/linux/man-pages/man8/ifconfig.8.html
EXERCISE: essayer `ifconfig` ; si absent, comparer avec `ip a` ci-dessous.
```

```text
COMMAND: ip
PURPOSE: afficher et configurer les interfaces réseau, le remplaçant
         moderne de `ifconfig`, `route` et plusieurs autres commandes
         historiques (paquet iproute2).
SYNTAX: ip a    (ou ip addr — affiche les adresses de toutes les interfaces)
OUTPUT: la liste des interfaces avec leurs adresses IPv4/IPv6
INTERPRETATION: une interface « lo » (loopback, 127.0.0.1) est toujours
         présente et sert aux communications internes à la machine
         elle-même.
DOCUMENTATION: https://man7.org/linux/man-pages/man8/ip.8.html
EXERCISE: `ip a` puis identifier l'adresse IP de l'interface réseau
         principale de la machine.
```

```text
COMMAND: resolvectl
PURPOSE: afficher la configuration DNS active (systemd-resolved) — utile
         pour diagnostiquer un problème de résolution de nom de domaine.
SYNTAX: resolvectl status
OUTPUT: la liste des serveurs DNS utilisés par interface réseau
INTERPRETATION: si un domaine ne se résout pas (`ping domaine.com` échoue
         avec "Name or service not known") alors que l'adresse IP
         correspondante répond, le problème vient du DNS, pas du réseau
         lui-même.
COMMON ERRORS:
  - "command not found" → le système n'utilise pas systemd-resolved ;
    vérifier `/etc/resolv.conf` directement à la place.
DOCUMENTATION: https://www.freedesktop.org/software/systemd/man/latest/resolvectl.html
         (documentation officielle systemd)
EXERCISE: `resolvectl status` et identifier le serveur DNS utilisé par
         l'interface principale.
```

```text
COMMAND: netstat
PURPOSE: afficher les connexions réseau actives et les ports en écoute —
         commande historique, remplacée sur les distributions récentes
         par `ss`.
SYNTAX: netstat -tulpn
OPTIONS:
  -t   connexions TCP
  -u   connexions UDP
  -l   ports en écoute uniquement
  -p   affiche le programme associé à chaque connexion (nécessite
       souvent sudo)
  -n   affiche les adresses/ports numériques plutôt que de les résoudre
       en noms
OUTPUT: un tableau des connexions et ports
COMMON ERRORS:
  - "command not found" → paquet net-tools non installé sur les
    distributions récentes ; utiliser `ss` à la place.
DOCUMENTATION: https://man7.org/linux/man-pages/man8/netstat.8.html
EXERCISE: essayer `netstat -tulpn` (avec sudo si nécessaire) ; comparer
         avec `ss -tulpn` ci-dessous.
```

```text
COMMAND: ss
PURPOSE: afficher les connexions réseau (sockets) actives et les ports en
         écoute, le remplaçant moderne et plus rapide de `netstat`
         (paquet iproute2).
SYNTAX: ss -tulpn
OPTIONS: identiques dans l'esprit à netstat (-t TCP, -u UDP, -l écoute,
         -p programme, -n numérique)
OUTPUT: un tableau des connexions et ports, format similaire à netstat
INTERPRETATION: utile pour vérifier qu'un serveur local (ex. Jupyter
         Notebook, un serveur de visualisation) écoute bien sur le port
         attendu avant de tenter une connexion depuis un navigateur.
DOCUMENTATION: https://man7.org/linux/man-pages/man8/ss.8.html
EXERCISE: `ss -tulpn` et identifier les ports actuellement en écoute sur
         la machine.
```

---

## A.2 Gestion des paquets

```text
COMMAND: apt
PURPOSE: installer, mettre à jour et supprimer des logiciels sur les
         distributions basées sur Debian (dont Ubuntu) — le gestionnaire
         de paquets système.
SYNTAX: sudo apt update              (rafraîchit la liste des paquets disponibles)
        sudo apt upgrade             (met à jour les paquets déjà installés)
        sudo apt install nom_paquet  (installe un nouveau paquet)
OUTPUT: un journal texte de l'opération, avec confirmation demandée avant
         modification
INTERPRETATION: `apt update` ne met rien à jour lui-même — il actualise
         seulement la liste de ce qui est disponible ; il faut ensuite
         `apt upgrade` pour appliquer les mises à jour. En bioinformatique,
         Conda (chapitre 11) est en général préféré à apt pour les outils
         scientifiques eux-mêmes, car il permet des environnements
         isolés par projet ; apt reste utilisé pour les outils système
         de base.
COMMON ERRORS:
  - "Unable to locate package" → nom de paquet incorrect, ou `apt update`
    non exécuté récemment.
  - "Permission denied" → apt modifie le système, donc nécessite
    systématiquement sudo.
DOCUMENTATION: https://manpages.ubuntu.com/manpages/noble/en/man8/apt.8.html
         (documentation officielle Ubuntu/Debian)
EXERCISE: `sudo apt update` puis `apt list --upgradable` pour voir les
         paquets pouvant être mis à jour (sans les installer).
```

---

## A.3 Comptes et privilèges

```text
COMMAND: sudo
PURPOSE: exécuter une commande unique avec les privilèges de
         l'administrateur (root), après authentification par mot de
         passe — le mécanisme standard pour effectuer des opérations
         système sans rester connecté en root en permanence.
SYNTAX: sudo commande
OUTPUT: la sortie normale de la commande exécutée, précédée d'une demande
         de mot de passe (une fois par session, en général)
INTERPRETATION: contrairement à `su -` (fiche suivante), sudo n'ouvre pas
         une nouvelle session : il élève les privilèges pour une seule
         commande, ce qui est plus sûr (moins de risque d'oublier qu'on
         agit en administrateur).
COMMON ERRORS:
  - "user is not in the sudoers file" → l'utilisateur courant n'a pas les
    droits d'administration sur cette machine ; contacter l'administrateur
    système.
  - exécuter `sudo rm -rf` sans avoir vérifié le chemin au préalable →
    DANGER, voir la mise en garde sur `rm` du chapitre 03, aggravée ici
    par les privilèges administrateur qui suppriment toute protection.
DOCUMENTATION: https://www.sudo.ws/docs/man/sudo.man/ (documentation
         officielle du projet sudo)
EXERCISE: `sudo whoami` — la commande doit répondre `root`, confirmant
         l'élévation de privilèges pour cette seule commande.
```

```text
COMMAND: su
PURPOSE: ouvrir une nouvelle session sous l'identité d'un autre
         utilisateur (root par défaut sans argument), en restant connecté
         jusqu'à un `exit` explicite.
SYNTAX: su -            (bascule en root, avec l'environnement complet de root)
        su - utilisateur (bascule vers un utilisateur précis)
INTERPRETATION: le tiret (-) charge l'environnement complet de
         l'utilisateur cible (variables, dossier personnel) ; sans tiret,
         l'environnement de l'utilisateur d'origine est partiellement
         conservé, ce qui peut causer des comportements inattendus.
COMMON ERRORS:
  - rester connecté en root par oubli après une tâche ponctuelle →
    toujours `exit` dès la tâche terminée ; préférer sudo pour une
    commande isolée.
  - "Authentication failure" → mot de passe root incorrect, ou compte
    root désactivé (courant sur Ubuntu, qui privilégie sudo).
DOCUMENTATION: https://man7.org/linux/man-pages/man1/su.1.html
EXERCISE: sur une machine où le mot de passe root est connu, `su -` puis
         `whoami` (doit répondre `root`), puis `exit` pour revenir à
         l'utilisateur d'origine.
```

```text
COMMAND: adduser
PURPOSE: créer un nouveau compte utilisateur sur le système, de façon
         interactive (version conviviale de la commande bas niveau
         `useradd`).
SYNTAX: sudo adduser nom_utilisateur
OUTPUT: création du compte, de son dossier personnel (/home/nom_utilisateur),
         et de son groupe associé
INTERPRETATION: réservé aux administrateurs système ; sans lien avec le
         travail bioinformatique quotidien, mais utile à connaître pour
         configurer un serveur partagé ou une machine de calcul.
COMMON ERRORS:
  - "Permission denied" → nécessite sudo, car il s'agit d'une
    modification du système affectant tous les utilisateurs.
DOCUMENTATION: https://manpages.ubuntu.com/manpages/noble/en/man8/adduser.8.html
EXERCISE: (sur une machine de test, avec précaution) `sudo adduser test_user`
         et observer les questions posées.
```

```text
COMMAND: passwd
PURPOSE: changer le mot de passe de l'utilisateur courant (ou, avec
         sudo, celui d'un autre utilisateur).
SYNTAX: passwd                    (change son propre mot de passe)
        sudo passwd utilisateur   (change le mot de passe d'un autre utilisateur)
INTERPRETATION: demande l'ancien mot de passe avant le nouveau, sauf si
         exécuté avec sudo pour un autre compte.
COMMON ERRORS:
  - "password updated unsuccessfully" → le nouveau mot de passe ne
    respecte pas la politique de complexité du système.
DOCUMENTATION: https://man7.org/linux/man-pages/man1/passwd.1.html
EXERCISE: `passwd` et suivre les invites (annuler avec Ctrl+C si ce n'est
         qu'un test, pour ne pas changer réellement son mot de passe par
         erreur).
```

---

## A.4 Pare-feu et services système

```text
COMMAND: ufw
PURPOSE: gérer le pare-feu du système de façon simplifiée (Uncomplicated
         Firewall), en autorisant ou bloquant du trafic réseau par port
         ou service.
SYNTAX: sudo ufw status
        sudo ufw allow 22        (autorise un port, ex. SSH)
        sudo ufw enable / disable
OUTPUT: confirmation textuelle de la règle appliquée, ou l'état actuel
         avec status
INTERPRETATION: sur une machine de calcul distante (HPC, cloud),
         désactiver par erreur l'accès SSH via une règle ufw trop
         restrictive peut couper tout accès à la machine — à manier avec
         prudence, toujours en gardant une session active pendant les
         tests.
COMMON ERRORS:
  - bloquer son propre accès SSH par une règle mal réfléchie sur une
    machine distante sans accès console de secours → vérifier
    `sudo ufw status` avant enable.
DOCUMENTATION: https://manpages.ubuntu.com/manpages/noble/en/man8/ufw.8.html
         (documentation officielle Ubuntu)
EXERCISE: `sudo ufw status` pour observer l'état actuel du pare-feu
         (actif/inactif) sans modifier de règle.
```

```text
COMMAND: iptables
PURPOSE: configurer le pare-feu du noyau Linux (netfilter) au niveau le
         plus bas — plus puissant et plus complexe que ufw, qui n'en est
         qu'une surcouche simplifiée.
SYNTAX: sudo iptables -L    (liste les règles actives)
OUTPUT: les règles de filtrage actuellement appliquées, par chaîne
         (INPUT, OUTPUT, FORWARD)
INTERPRETATION: ufw génère en réalité des règles iptables en arrière-plan ;
         consulter `iptables -L` permet de voir l'effet concret des
         règles ufw définies plus haut.
COMMON ERRORS:
  - modifier directement les règles iptables alors que ufw est actif →
    les deux peuvent entrer en conflit ; choisir l'un ou l'autre comme
    outil de gestion principal.
DOCUMENTATION: https://man7.org/linux/man-pages/man8/iptables.8.html
EXERCISE: `sudo iptables -L` pour observer les règles actuellement
         actives sur la machine.
```

```text
COMMAND: systemctl
PURPOSE: démarrer, arrêter, activer ou consulter l'état des services
         gérés par systemd (le système d'initialisation des distributions
         Linux modernes).
SYNTAX: systemctl status nom_service
        sudo systemctl start/stop/restart nom_service
        sudo systemctl enable nom_service   (démarrage automatique au boot)
OUTPUT: l'état du service (actif/inactif, PID, journal récent) ou
         confirmation de l'action
INTERPRETATION: utile pour vérifier qu'un service dont dépend un outil
         (ex. un serveur de base de données local) est bien démarré avant
         de lancer une analyse qui en a besoin.
COMMON ERRORS:
  - "Unit ... not found" → nom de service incorrect, ou service non
    installé.
  - "Permission denied" → start/stop/restart/enable nécessitent sudo ;
    status seul ne le nécessite pas toujours.
DOCUMENTATION: https://www.freedesktop.org/software/systemd/man/latest/systemctl.html
         (documentation officielle systemd)
EXERCISE: `systemctl status ssh` (ou un autre service installé) pour
         observer son état sans le modifier.
```

```text
COMMAND: reboot / shutdown
PURPOSE: redémarrer (reboot) ou éteindre (shutdown) la machine.
SYNTAX: sudo reboot
        sudo shutdown now       (extinction immédiate)
        sudo shutdown -h +10    (extinction planifiée dans 10 minutes)
INTERPRETATION: sur une machine de calcul distante (serveur, cluster HPC)
         partagée avec d'autres utilisateurs, ces commandes interrompent
         tous les travaux en cours pour tout le monde — à n'exécuter
         qu'avec une autorisation explicite et jamais par réflexe pour
         « réessayer » un problème.
COMMON ERRORS:
  - redémarrer une machine partagée par erreur, interrompant des calculs
    en cours appartenant à d'autres utilisateurs → vérifier
    systématiquement qu'on est bien sur sa propre machine locale avant
    d'exécuter reboot/shutdown.
DOCUMENTATION: https://man7.org/linux/man-pages/man8/reboot.8.html ·
         https://man7.org/linux/man-pages/man8/shutdown.8.html
EXERCISE: `shutdown -h +10` puis annuler avec `sudo shutdown -c` avant
         l'échéance, pour observer le mécanisme sans réellement éteindre
         la machine.
```

---

**Retour** : [sommaire de la Partie I](../README.md)
