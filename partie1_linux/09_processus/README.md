# Chapitre 09 — Processus et ressources : lancer, suivre et arrêter de longs calculs

> **Durée estimée** : 1 h 30
> **Prérequis** : [chapitre 08](../08_permissions/README.md)
> **Chapitre suivant** : [10 — L'environnement du shell](../10_environnement_shell/README.md)

## Ce que vous saurez faire à la fin de ce chapitre

- Lister les programmes en cours d'exécution (`ps`, `top`) et repérer ce
  qui consomme le processeur et la mémoire.
- Lancer une commande en **arrière-plan**, la suspendre, la reprendre
  (`&`, `jobs`, Ctrl+Z, `bg`, `fg`).
- Arrêter un programme proprement, ou de force (`kill`, `pkill`).
- Garder un calcul en vie **après avoir fermé le terminal** (`nohup`,
  `tmux`).
- Mesurer les ressources de la machine (`nproc`, `free`, `df`, `du`) et la
  durée d'une commande (`time`).

---

## 1. Pourquoi

Un assemblage de génome peut durer une nuit, un alignement plusieurs heures.
Pendant ce temps, vous voulez continuer à travailler dans le même terminal,
savoir si le calcul avance ou s'il est bloqué, l'arrêter s'il s'est trompé
de fichier, et surtout **ne pas le perdre** si votre connexion au serveur
se coupe ou si vous fermez votre ordinateur portable.

Il faut aussi savoir combien de cœurs et de mémoire demander à un outil
(`--threads 8`), et vérifier avant de lancer un calcul que le disque ne va
pas déborder.

---

## 2. Une image pour comprendre : les manips en cours au labo

Un **processus** est un programme en train de s'exécuter, comme une manip
en cours sur une paillasse :

| Au laboratoire | Sous Linux |
|---|---|
| une manip lancée, avec son numéro de cahier de labo | un **processus**, avec son numéro, le **PID** (*process identifier*) |
| la manip que vous surveillez en restant devant | un processus au **premier plan** : le terminal est occupé |
| la PCR qui tourne pendant que vous faites autre chose | un processus en **arrière-plan** |
| le tableau d'occupation des appareils | `top` |
| demander à un collègue d'arrêter sa manip proprement | `kill` (signal TERM) |
| débrancher l'appareil | `kill -9` (signal KILL) |

---

## 3. Voir les processus : `ps` et `top`

### 3.1 `ps`

```bash
ps
```

```text
    PID TTY          TIME CMD
    982 pts/0    00:00:00 bash
   1001 pts/0    00:00:00 ps
```

Sans option, `ps` montre les processus **de votre terminal** : le shell
(`bash`) et `ps` lui-même. Les numéros (PID) seront différents chez vous.

| Commande | Montre |
|---|---|
| `ps` | les processus du terminal courant |
| `ps -u $USER` | tous **vos** processus (`$USER` contient votre nom, chapitre 10) |
| `ps aux` | **tous** les processus de la machine, avec leur consommation |
| `pgrep -a nom` | les processus dont le nom contient `nom`, avec leur PID |

### 3.2 `top` : le tableau de bord en direct

```bash
top
```

```text
top - 23:52:35 up 5 min,  1 user,  load average: 0.03, 0.03, 0.00
Tasks:  34 total,   1 running,  33 sleeping,   0 stopped,   0 zombie
%Cpu(s):  0.0 us,  0.0 sy,  0.0 ni,100.0 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
MiB Mem :  15651.9 total,  14078.5 free,    654.3 used,   1138.3 buff/cache
MiB Swap:   4096.0 total,   4096.0 free,      0.0 used.  14997.6 avail Mem

    PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
      1 root      20   0   21756  13080   9700 S   0.0   0.1   0:00.64 systemd
```

L'affichage se met à jour toutes les 3 secondes. Ce qu'il faut regarder :

| Zone | Signification |
|---|---|
| `load average` | charge moyenne (sur 1, 5 et 15 min) : à comparer au nombre de cœurs |
| `MiB Mem … avail Mem` | mémoire totale et mémoire **disponible** |
| `%CPU` | 100 % = un cœur entier ; un outil qui tourne sur 8 cœurs peut afficher 800 % |
| `%MEM`, `RES` | mémoire utilisée par le processus |
| `S` | état : `R` en cours d'exécution, `S` en attente, `T` suspendu |

Touches utiles : **M** trie par mémoire, **P** par processeur, **u** puis
votre nom n'affiche que vos processus, **q** quitte.

> `htop` est une version plus lisible et colorée de `top`. Il n'est pas
> installé par défaut : `sudo apt install htop` sur votre machine. Il est
> souvent disponible sur les serveurs.

---

## 4. Premier plan et arrière-plan

### 4.1 Lancer en arrière-plan : `&`

Pour simuler un long calcul, nous utiliserons `sleep 300`, qui ne fait rien
pendant 300 secondes. Ajoutez `&` à la fin de la commande :

```bash
sleep 300 &
```

```text
[1] 1008
```

Le shell rend la main immédiatement. `[1]` est le **numéro de tâche**
(*job*) dans ce terminal, `1008` est le PID. Votre « calcul » tourne en
arrière-plan.

```bash
jobs
```

```text
[1]+  Running                 sleep 300 &
```

### 4.2 Suspendre, reprendre : Ctrl+Z, `bg`, `fg`

Vous avez lancé un long calcul **sans** `&`, et votre terminal est bloqué ?
Inutile de l'arrêter :

1. **Ctrl+Z** suspend le processus : `[1]+  Stopped                 sleep 300`
2. **`bg`** le relance en arrière-plan : `[1]+ sleep 300 &`
3. **`fg`** le ramène au premier plan si vous voulez de nouveau le
   surveiller (ou l'interrompre avec Ctrl+C).

Avec plusieurs tâches, on les désigne par leur numéro : `fg %2`, `kill %1`.

> **Attention** : un processus suspendu par Ctrl+Z **ne travaille plus**.
> Pensez à `bg` ! Un `jobs` qui affiche `Stopped` signale une analyse qui
> n'avance pas.

---

## 5. Arrêter un processus : `kill`

### 5.1 Les signaux

`kill` envoie un **signal** à un processus. Malgré son nom, il ne tue pas
forcément :

| Commande | Signal | Effet |
|---|---|---|
| `kill PID` ou `kill %1` | TERM (15) | demande poliment de s'arrêter ; le programme peut terminer proprement (fermer ses fichiers, effacer ses fichiers temporaires) |
| `kill -9 PID` | KILL (9) | arrêt immédiat et forcé, sans aucun nettoyage |
| Ctrl+C | INT (2) | interrompt le processus au premier plan |

```bash
sleep 300 &
kill %1
jobs
```

```text
[1] 1008
[1]+  Terminated              sleep 300
```

> **Bon réflexe** : toujours `kill` d'abord, `kill -9` seulement si le
> processus ne réagit pas après quelques secondes. Un outil tué par
> `kill -9` peut laisser un fichier de sortie à moitié écrit, qui ressemble
> à un vrai résultat.

### 5.2 Trouver le PID : `pgrep`, arrêter par le nom : `pkill`

```bash
sleep 400 &
sleep 500 &
pgrep -a sleep
pkill -f "sleep 400"
pgrep -a sleep
```

```text
1021 sleep 400
1022 sleep 500
1022 sleep 500
```

`pkill -f` cherche dans la ligne de commande complète. Vérifiez toujours
avec `pgrep -a` **avant** `pkill` : un motif trop large peut arrêter
d'autres programmes que celui visé.

### 5.3 Ce que vous ne pouvez pas arrêter

```bash
kill 1
```

```text
bash: kill: (1) - Operation not permitted
```

Comme pour les fichiers (chapitre 08), vous ne pouvez agir que sur **vos**
processus. Sur un serveur partagé, c'est ce qui empêche un utilisateur
d'arrêter les calculs des autres.

---

## 6. Survivre à la déconnexion : `nohup` et `tmux`

### 6.1 Le problème

Quand vous fermez un terminal, ou quand votre connexion SSH à un serveur se
coupe (chapitre 14), **tous les processus lancés depuis ce terminal sont
arrêtés**, même ceux en arrière-plan. Un alignement de 10 heures, perdu
parce que le Wi-Fi a décroché à la 9ᵉ heure : c'est un classique.

### 6.2 `nohup` : la solution minimale

```bash
nohup bash -c "sleep 60; echo calcul terminé" > calcul.log 2>&1 &
```

`nohup` (*no hang up*) rend la commande insensible à la fermeture du
terminal. On redirige systématiquement sa sortie vers un journal. Sans
redirection, `nohup` écrit dans un fichier `nohup.out` et affiche
`nohup: ignoring input and appending output to 'nohup.out'`.

Vous pouvez fermer le terminal ; plus tard, `cat calcul.log` montrera le
résultat.

### 6.3 `tmux` : un terminal qui continue sans vous

`tmux` crée une **session de terminal** qui continue de vivre en
arrière-plan. Vous pouvez vous en **détacher**, fermer la fenêtre, revenir
le lendemain et vous y **rattacher** : tout est là, y compris l'affichage
de votre calcul en cours.

| Action | Commande ou touches |
|---|---|
| créer une session nommée | `tmux new -s analyse` |
| se **détacher** (la session continue) | **Ctrl+B**, relâcher, puis **D** |
| lister les sessions | `tmux ls` |
| se **rattacher** | `tmux attach -t analyse` |
| fermer la session | `exit` dans la session |

Essayez :

1. `tmux new -s analyse`. Une barre verte apparaît en bas : vous êtes dans
   tmux.
2. Lancez `sleep 300` (au premier plan, sans `&`).
3. Faites **Ctrl+B** puis **D**. Le message `[detached (from session analyse)]`
   s'affiche, et vous retrouvez votre terminal normal.
4. `tmux ls` :

   ```text
   analyse: 1 windows (created Tue Nov 24 23:52:41 2026)
   ```

5. `tmux attach -t analyse` : vous retrouvez `sleep 300` en cours.
   Ctrl+C, puis `exit`, pour terminer.

> **Bon réflexe sur un serveur** : **tout calcul de plus de quelques
> minutes se lance dans tmux** (ou est soumis à l'ordonnanceur du cluster,
> module 36 de la Partie II). `screen` est un outil plus ancien qui joue le
> même rôle ; vous le croiserez sur certains serveurs.

---

## 7. Les ressources de la machine

| Question | Commande | Exemple de réponse |
|---|---|---|
| Combien de cœurs ? | `nproc` | `16` |
| Combien de mémoire ? | `free -h` | `Mem: 15Gi total, 14Gi available` |
| Quelle place sur le disque ? | `df -h ~` | `Avail 953G`, `Use% 1%` |
| Que pèse ce dossier ? | `du -sh dossier` | `716K run_sequencage` |
| Quels fichiers sont les plus gros ? | `du -sh * \| sort -h \| tail` | |
| Combien de temps prend cette commande ? | `time commande` | `real 0m0.006s` |

```bash
free -h
df -h ~
```

```text
               total        used        free      shared  buff/cache   available
Mem:            15Gi       654Mi        13Gi       4.2Mi       1.1Gi        14Gi
Swap:          4.0Gi          0B       4.0Gi
Filesystem      Size  Used Avail Use% Mounted on
/dev/sdd       1007G  3.1G  953G   1% /
```

Regardez la colonne **`available`** de `free`, pas `free` : Linux utilise
la mémoire libre comme cache, et la libère à la demande.

`sort -h` trie des tailles « humaines » (`124K` < `2.1M` < `1G`), comme
celles de `du -h` :

```bash
du -sh ~/formation_linux/* | sort -h | tail -n 3
```

```text
124K	/home/marie/formation_linux/sample_01.fastq.gz
244K	/home/marie/formation_linux/formats
716K	/home/marie/formation_linux/run_sequencage
```

**Mesurer la durée d'une commande** :

```bash
time (zcat sample_01.fastq.gz sample_02.fastq.gz sample_03.fastq.gz | wc -l)
```

```text
14000

real	0m0.006s
user	0m0.009s
sys	0m0.000s
```

`real` est la durée vécue (le temps de l'horloge murale). `user` et `sys`
sont le temps de calcul effectif du processeur, qui peut **dépasser**
`real` quand un outil travaille sur plusieurs cœurs à la fois.

---

## 8. En bioinformatique

- **Choisir le nombre de threads.** La plupart des outils ont une option
  `-t` ou `--threads`. Sur votre machine, ne dépassez pas `nproc`, et
  gardez un ou deux cœurs pour le reste du système. Sur un serveur, utilisez
  **le nombre que l'on vous a attribué**, pas celui de la machine.
- **Prévoir la mémoire.** Un assembleur ou un aligneur indexant un génome
  humain peut demander des dizaines de Go. Si la mémoire manque, le noyau
  arrête le processus (message `Killed`, souvent sans autre explication) :
  c'est le premier suspect quand un outil s'interrompt sans erreur claire.
- **Prévoir le disque.** Les fichiers intermédiaires (SAM, BAM non trié)
  pèsent souvent plusieurs fois la taille des FASTQ. `df -h` avant de
  lancer, et le message `No space left on device` après coup signifie un
  disque plein.
- **Ne jamais lancer de calcul lourd sur le nœud de connexion d'un
  cluster.** Les serveurs de calcul ont une machine d'accueil partagée par
  tous : on y édite des scripts, on soumet des jobs, mais on ne calcule pas
  (module 36).
- **Tout calcul long** : dans `tmux`, ou avec `nohup … > log 2>&1 &`, et
  toujours avec un journal.

---

## 9. Pièges fréquents

| Situation | Symptôme | Solution |
|---|---|---|
| calcul lancé sans `&`, terminal bloqué | pas d'invite | Ctrl+Z, puis `bg` |
| tâche suspendue oubliée | `jobs` affiche `Stopped` ; le calcul n'avance pas | `bg` ou `fg` |
| terminal fermé ou connexion coupée | calcul disparu | `tmux` ou `nohup` à l'avenir |
| `nohup` sans redirection | sortie dans `nohup.out` | `nohup cmd > log 2>&1 &` |
| `kill -9` d'emblée | fichiers de sortie corrompus | `kill` d'abord |
| `pkill` trop large | d'autres programmes arrêtés | `pgrep -a` d'abord |
| processus terminé avec `Killed` sans raison apparente | mémoire insuffisante | `free -h`, réduire les données ou les threads |
| `No space left on device` | disque plein | `df -h`, puis `du -sh * \| sort -h` pour trouver les gros fichiers |

---

## 10. À vous de jouer

### Exercice 1 : l'état de votre machine

*Objectif : mesurer les ressources.*
Combien votre machine a-t-elle de cœurs, de mémoire disponible et d'espace
libre dans votre dossier personnel ? Si un aligneur demande « 4 threads et
8 Go de mémoire », pouvez-vous le lancer ?

<details>
<summary>Corrigé</summary>

```bash
nproc
free -h
df -h ~
```

Comparez `nproc` à 4 et la colonne `available` de `free -h` à 8 Go. Les
valeurs dépendent de votre machine. Sous WSL, la mémoire visible est une
partie de celle de Windows.
</details>

### Exercice 2 : arrière-plan et suspension

*Objectif : `&`, Ctrl+Z, `jobs`, `bg`, `fg`, `kill`.*
1. Lancez `sleep 200` **au premier plan**. Suspendez-le, puis relancez-le en
   arrière-plan.
2. Lancez `sleep 300 &`.
3. Affichez vos tâches. Ramenez la seconde au premier plan, puis
   interrompez-la.
4. Arrêtez la première avec `kill`, et vérifiez avec `jobs`.

<details>
<summary>Corrigé</summary>

```bash
sleep 200        # puis Ctrl+Z
bg
sleep 300 &
jobs
fg %2            # puis Ctrl+C
kill %1
jobs
```

`jobs` affiche `[1]+  Terminated sleep 200`, puis plus rien : il ne reste
aucune tâche.
</details>

### Exercice 3 : un « calcul » qui survit

*Objectif : `nohup` et journal.*
Lancez avec `nohup`, en arrière-plan, une commande qui attend 30 secondes
puis compte les lignes de `reads.fastq`, et écrivez tout dans `calcul.log`.
Fermez le terminal, rouvrez-en un, et lisez le résultat.

<details>
<summary>Corrigé</summary>

```bash
cd ~/formation_linux
nohup bash -c "sleep 30; wc -l reads.fastq" > calcul.log 2>&1 &
```

Après 30 secondes, dans un nouveau terminal :

```bash
cat ~/formation_linux/calcul.log
```

```text
2000 reads.fastq
```

`bash -c "…"` lance plusieurs commandes comme une seule, ce qui permet de
toutes les placer sous `nohup`.
</details>

### Exercice 4 : la session tmux

*Objectif : se détacher et se rattacher.*
Créez une session tmux `qc`. Lancez-y `top`. Détachez-vous, vérifiez avec
`tmux ls` que la session existe, rattachez-vous, quittez `top` puis fermez
la session.

<details>
<summary>Corrigé</summary>

```bash
tmux new -s qc
top              # puis Ctrl+B, D
tmux ls
tmux attach -t qc
                 # q pour quitter top, puis :
exit
```

Après `exit`, `tmux ls` répond `no server running` : il ne reste plus
aucune session.
</details>

---

## 11. Défi : qui occupe le disque ?

Votre dossier personnel est presque plein. Trouvez, dans
`~/formation_linux`, les **5 fichiers les plus volumineux**, tous
sous-dossiers compris, avec leur taille lisible.

<details>
<summary>Indice</summary>

`find` (chapitre 03) liste tous les fichiers avec `-type f`. `du -h`
accepte plusieurs fichiers. Pour passer la liste produite par `find` en
arguments d'une commande, il faut `xargs` (voir le corrigé), ou l'option
`-exec` de `find`.
</details>

<details>
<summary>Corrigé</summary>

```bash
cd ~/formation_linux
find . -type f -exec du -h {} + | sort -h | tail -n 5
```

`find … -exec du -h {} +` lance `du -h` sur tous les fichiers trouvés
(`{}` est remplacé par leur liste). On peut écrire la même chose avec
`find . -type f | xargs du -h`, mais `xargs` se trompe sur les noms
contenant des espaces : `-exec` est plus sûr. Le résultat est trié par
taille, et `tail` garde les 5 plus gros. Ici, ce sont `alignements.sam` et
les FASTQ historiques (`reads.fastq`, `sample_0*.fastq.gz`).
</details>

---

## L'essentiel

```text
ps   ps -u $USER   ps aux   pgrep -a nom      voir les processus (PID)
top (M, P, u, q)    htop                       tableau de bord en direct
commande &         jobs   fg %n   bg   Ctrl+Z  arrière-plan, suspendre, reprendre
kill PID / %n (TERM)   kill -9 (KILL, dernier recours)   pkill -f motif
nohup cmd > log 2>&1 &                         survivre à la fermeture du terminal
tmux new -s nom · Ctrl+B D · tmux ls · tmux attach -t nom     sessions persistantes
nproc   free -h (available)   df -h   du -sh * | sort -h   time cmd
Killed = souvent la mémoire ; No space left on device = le disque
```

### Auto-évaluation

- [ ] Je trouve le PID d'un processus et je l'arrête proprement.
- [ ] Je débloque un terminal en mettant un calcul en arrière-plan.
- [ ] Je lance un calcul qui survit à la fermeture du terminal.
- [ ] Je me détache et me rattache à une session tmux.
- [ ] Je vérifie cœurs, mémoire et disque avant un calcul lourd.

## Documentation officielle

- Contrôle des tâches (manuel de Bash, *Job Control*) : <https://www.gnu.org/software/bash/manual/html_node/Job-Control.html>
- procps-ng (`ps`, `top`, `free`, `kill`, `pgrep`) : <https://gitlab.com/procps-ng/procps>
- `nohup` (GNU Coreutils) : <https://www.gnu.org/software/coreutils/manual/html_node/nohup-invocation.html>
- tmux : <https://github.com/tmux/tmux/wiki>

**Prochaine étape** : [chapitre 10 — L'environnement du shell](../10_environnement_shell/README.md).
