#!/usr/bin/env bash
# Partie II : les workflows doivent au moins construire leur graphe de tâches.
# - projets Snakemake : dry-run (aucun téléchargement, aucune exécution)
# - exemples du module 34 : snakemake -n et nextflow -stub-run sur des fichiers factices
# (sourcé par tests/run_all.sh)

echo "-- Partie II : workflows (dry-run)"
if besoin snakemake; then
    for projet in final_project_ltee_ecoli:28 mini_project_amr_kpneumoniae:41; do
        nom=${projet%%:*}; attendu=${projet##*:}
        WF="$(mktemp -d)"
        cp -r "$DEPOT/projects/$nom" "$WF/" && cp -r "$DEPOT/envs" "$WF/"
        verifier "dry-run $nom : $attendu tâches" "$attendu" \
            "cd '$WF/$nom' && snakemake -n --quiet rules 2>&1 | awk '\$1 == \"total\" { print \$2; exit }'"
        rm -rf "$WF"
    done
    WF="$(mktemp -d)"
    cp "$DEPOT/partie2_bioinfo/34_workflows/exemples/Snakefile" "$WF/"
    mkdir -p "$WF/data/raw"
    for s in A B; do for r in 1 2; do echo | gzip > "$WF/data/raw/${s}_R$r.fastq.gz"; done; done
    verifier "module 34 : exemple Snakemake (5 tâches)" "5" \
        "cd '$WF' && snakemake -n --quiet rules 2>&1 | awk '\$1 == \"total\" { print \$2; exit }'"
    if besoin nextflow; then
        cp "$DEPOT/partie2_bioinfo/34_workflows/exemples/main.nf" "$WF/"
        verifier "module 34 : exemple Nextflow (-stub-run)" "4" \
            "cd '$WF' && NXF_HOME='$WF/.nxf' nextflow run main.nf -stub-run -ansi-log false 2>&1 | grep -c 'Submitted process'"
    fi
    rm -rf "$WF"
fi
