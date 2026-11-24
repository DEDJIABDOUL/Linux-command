# Charte de rédaction — Partie I « Linux pour biologistes »

Cette charte s'applique à tous les chapitres de `partie1_linux/`. Elle
découle de l'audit pédagogique de novembre 2026.

## Public et ton

- Étudiants en biologie **sans aucune expérience** de la ligne de commande.
- **Vouvoiement**, français clair. Un terme technique anglais est donné une
  fois entre parenthèses (« invite de commande (*prompt*) »), puis employé
  librement s'il est d'usage courant (reads, pipeline).
- Les messages du système sont en anglais (Ubuntu par défaut) : on les
  montre **tels quels**, puis on les traduit et on les explique.

## Règle d'or : aucune notion utilisée avant d'être expliquée

Si une commande d'un chapitre utilise une notion vue plus tard, elle est
soit remplacée, soit signalée explicitement (« copiez cette ligne telle
quelle, elle sera expliquée au chapitre 05 »). Cette exception est réservée
à l'installation.

## Trame d'un chapitre

Adapter la profondeur au sujet ; regrouper les étapes quand c'est naturel.

1. **Ce que vous saurez faire** : 3 à 5 compétences observables.
2. **Pourquoi** : une situation réelle de laboratoire.
3. **Une image pour comprendre** : une analogie, puis ses limites.
4. **Démonstrations guidées** : commande, **sortie réelle**, explication.
   Avant une commande nouvelle, inviter à prédire : « Que va-t-il
   s'afficher selon vous ? ».
5. **En bioinformatique** : l'usage concret de la notion.
6. **Pièges fréquents** : le message d'erreur exact, sa cause, sa solution.
7. **À vous de jouer** : exercices avec objectif précis ; corrigés repliés
   dans `<details>`.
8. **Défi** : un problème ouvert qui demande de combiner les acquis.
9. **L'essentiel** : aide-mémoire court + grille d'auto-évaluation.

## Conventions d'écriture

- Bloc de commande : ```` ```bash ````, **une commande par ligne**, sans
  le `$` de l'invite (pour que le copier-coller fonctionne).
- Bloc de sortie : ```` ```text ````, précédé de « Sortie : ». Les sorties
  montrées sont **réellement obtenues** sur Ubuntu 24.04 avec les données du
  bac à sable ; si elles dépendent de la machine (nom, date), le dire.
- Toute valeur annoncée (« → 22 ») est vérifiée par `tests/run_all.sh`.
- Les exercices travaillent **dans `~/formation_linux`** (créé par
  `setup.sh`), jamais dans le dépôt lui-même.
- Encadrés : `> **Attention**` (risque de perte de données),
  `> **Bon réflexe**`, `> **Pour aller plus loin**` (facultatif).
- Pas de commande dangereuse en exercice (`sudo` sur le système, `rm -rf`
  hors du bac à sable, extinction de machine…). L'administration système
  est traitée en annexe, à pratiquer dans une machine virtuelle.

## Liens et références

- Documentation officielle uniquement, jamais d'URL inventée.
- Une référence par notion suffit ; la documentation détaillée va en fin
  de chapitre, pas au milieu de l'explication.
