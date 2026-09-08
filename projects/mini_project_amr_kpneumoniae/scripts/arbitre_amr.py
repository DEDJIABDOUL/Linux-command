#!/usr/bin/env python3
"""Croise les gènes de résistance détectés par ABRicate (CARD) et par
AMRFinderPlus pour un même isolat, et retient les gènes confirmés par les
deux outils comme des appels à haute confiance.

Usage :
    python3 scripts/arbitre_amr.py \
        --abricate-tsv results/amr/{sample}.card.tsv \
        --amrfinder-tsv results/amr/{sample}.amrfinder.tsv \
        --sample-name {sample} \
        --min-coverage 90.0 --min-identity 90.0 \
        --output-table results/amr/{sample}.consensus.tsv \
        --output-plot results/amr/{sample}.venn.png

Corrige deux défauts du script de référence critiqué (voir README.md,
section DECISIONS) :
  1. les chemins d'entrée/sortie sont des arguments explicites, jamais
     des noms de fichiers relatifs supposant un dossier de travail précis
     (le script d'origine lisait "resultats_card.tsv" sans préfixe de
     dossier alors que le pipeline appelant l'exécutait depuis un autre
     répertoire — échec systématique) ;
  2. toute erreur (fichier manquant, colonne absente...) termine le
     script avec un code de sortie non nul (sys.exit), pour qu'un
     orchestrateur (Snakemake, `set -e`) puisse réellement détecter
     l'échec plutôt que de le voir capturé et ignoré silencieusement.
"""
import argparse
import sys

import pandas as pd
from matplotlib_venn import venn2
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt


def load_abricate_genes(tsv_path, min_coverage, min_identity):
    df = pd.read_csv(tsv_path, sep="\t")
    filtered = df[(df["%COVERAGE"] >= min_coverage) & (df["%IDENTITY"] >= min_identity)]
    return set(filtered["GENE"].dropna().tolist())


def load_amrfinder_genes(tsv_path, min_coverage, min_identity):
    df = pd.read_csv(tsv_path, sep="\t")
    filtered = df[
        (df["% Coverage of reference"] >= min_coverage)
        & (df["% Identity to reference"] >= min_identity)
    ]
    return set(filtered["Element symbol"].dropna().tolist())


def write_consensus_table(sample_name, genes_abricate, genes_amrfinder, output_table):
    all_genes = sorted(genes_abricate | genes_amrfinder)
    rows = [
        {
            "sample": sample_name,
            "gene": gene,
            "abricate_card": gene in genes_abricate,
            "amrfinderplus": gene in genes_amrfinder,
            "high_confidence": gene in genes_abricate and gene in genes_amrfinder,
        }
        for gene in all_genes
    ]
    pd.DataFrame(rows).to_csv(output_table, sep="\t", index=False)


def plot_venn(sample_name, genes_abricate, genes_amrfinder, output_plot):
    plt.figure(figsize=(8, 6))
    venn2([genes_abricate, genes_amrfinder], ("ABRicate (CARD)", "AMRFinderPlus"))
    plt.title(f"Gènes de résistance — {sample_name}")
    plt.savefig(output_plot, dpi=300, bbox_inches="tight")
    plt.close()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--abricate-tsv", required=True, help="TSV ABRicate (--db card)")
    parser.add_argument("--amrfinder-tsv", required=True, help="TSV AMRFinderPlus")
    parser.add_argument("--sample-name", required=True, help="Identifiant de l'échantillon")
    parser.add_argument("--min-coverage", type=float, default=90.0)
    parser.add_argument("--min-identity", type=float, default=90.0)
    parser.add_argument("--output-table", required=True, help="TSV de consensus en sortie")
    parser.add_argument("--output-plot", required=True, help="PNG du diagramme de Venn en sortie")
    args = parser.parse_args()

    try:
        genes_abricate = load_abricate_genes(args.abricate_tsv, args.min_coverage, args.min_identity)
        genes_amrfinder = load_amrfinder_genes(args.amrfinder_tsv, args.min_coverage, args.min_identity)
    except FileNotFoundError as exc:
        print(f"[{args.sample_name}] fichier introuvable : {exc}", file=sys.stderr)
        sys.exit(1)
    except KeyError as exc:
        print(
            f"[{args.sample_name}] colonne attendue absente ({exc}) — "
            "une mise à jour d'ABRicate ou d'AMRFinderPlus a peut-être "
            "renommé ses colonnes de sortie, voir README.md, section DECISIONS.",
            file=sys.stderr,
        )
        sys.exit(1)

    commun = genes_abricate & genes_amrfinder
    print(f"[{args.sample_name}] ABRicate (CARD) : {len(genes_abricate)} gène(s)", file=sys.stderr)
    print(f"[{args.sample_name}] AMRFinderPlus   : {len(genes_amrfinder)} gène(s)", file=sys.stderr)
    print(f"[{args.sample_name}] Haute confiance (les deux outils) : {len(commun)} gène(s)", file=sys.stderr)
    if commun:
        print(f"[{args.sample_name}]  -> {', '.join(sorted(commun))}", file=sys.stderr)

    write_consensus_table(args.sample_name, genes_abricate, genes_amrfinder, args.output_table)
    plot_venn(args.sample_name, genes_abricate, genes_amrfinder, args.output_plot)


if __name__ == "__main__":
    main()
