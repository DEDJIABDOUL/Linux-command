# Scripts du dépôt

Ces deux scripts sont les versions réelles, testées et exécutables, des
exemples expliqués en détail dans `04_bash_scripting/README.md`. Aucun
des deux n'est un outil bioinformatique : ce sont des squelettes
pédagogiques à lire, exécuter, puis adapter.

| Script | Rôle | Testé sur |
|---|---|---|
| `stats.sh` | Compte les séquences FASTA et les reads FASTQ.gz du dossier courant | `linux/` (voir `04_bash_scripting/README.md`, section 4) |
| `pipeline_template.sh` | Squelette de script paramétrable et journalisé (arguments nommés, logging, exit codes) | `linux/` (voir `04_bash_scripting/README.md`, section 5) |

Utilisation :

```bash
cd linux/
../scripts/stats.sh

cd ..
./scripts/pipeline_template.sh --input linux --output resultats_test
```

Avant d'utiliser `pipeline_template.sh` pour un vrai pipeline, remplacer
le corps de la fonction `main()` par les étapes réelles (voir les modules
`09_quality_control/` à `21_variant_analysis/` pour des commandes
concrètes à y insérer).
