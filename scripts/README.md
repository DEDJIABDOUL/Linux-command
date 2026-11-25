# Scripts du dépôt

Ces deux scripts sont les versions réelles, testées et exécutables, des
exemples expliqués en détail dans `partie1_linux/12_scripts_bash_1/`. Aucun
des deux n'est un outil bioinformatique : ce sont des squelettes
pédagogiques à lire, exécuter, puis adapter.

| Script | Rôle | Testé sur |
|---|---|---|
| `stats.sh` | Compte les séquences FASTA et les reads FASTQ.gz du dossier courant | `data/` (voir `partie1_linux/12_scripts_bash_1/README.md`, section 6) |
| `pipeline_template.sh` | Squelette de script paramétrable et journalisé (arguments nommés, logging, exit codes) | `data/` (voir `partie1_linux/13_scripts_bash_2/README.md`, section 7) |

Utilisation :

```bash
cd data/
../scripts/stats.sh

cd ..
./scripts/pipeline_template.sh --input linux --output resultats_test
```

Avant d'utiliser `pipeline_template.sh` pour un vrai pipeline, remplacer
le corps de la fonction `main()` par les étapes réelles (voir les modules
`partie2_bioinfo/19_controle_qualite/` à `partie2_bioinfo/22_appel_variants/` pour des commandes
concrètes à y insérer).
