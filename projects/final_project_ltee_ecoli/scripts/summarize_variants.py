#!/usr/bin/env python3
"""Compte les variants filtrés par échantillon et trace leur évolution
avec la génération (LTEE Ara-3 vs REL606).

Usage :
    python3 scripts/summarize_variants.py --config config.yaml \
        --output-table results/variant_summary.tsv \
        --output-plot results/variants_vs_generation.png

Entrée attendue par échantillon : results/{sample}.filtered.vcf.gz
(produit par la règle Snakemake filter_variants). Le nombre de variants
compté ici est un compte brut de lignes du VCF filtré — pas une mesure
de significativité biologique en soi (voir README, section
INTERPRETATION).
"""
import argparse
import sys

import pandas as pd
import pysam
import yaml
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt


def count_variants(vcf_path):
    with pysam.VariantFile(vcf_path) as vcf:
        return sum(1 for _ in vcf)


def build_summary(config, results_dir):
    rows = []
    for sample, accession in config["samples"].items():
        generation = config["generations"][sample]
        vcf_path = f"{results_dir}/{sample}.filtered.vcf.gz"
        n_variants = count_variants(vcf_path)
        rows.append(
            {
                "sample": sample,
                "sra_accession": accession,
                "generation": generation,
                "n_variants": n_variants,
            }
        )
    return pd.DataFrame(rows).sort_values("generation").reset_index(drop=True)


def plot_summary(df, output_plot):
    fig, ax = plt.subplots(figsize=(6, 4))
    ax.plot(df["generation"], df["n_variants"], marker="o")
    for _, row in df.iterrows():
        ax.annotate(row["sample"], (row["generation"], row["n_variants"]))
    ax.set_xlabel("Génération (population Ara-3)")
    ax.set_ylabel("Nombre de variants filtrés vs REL606")
    ax.set_title("Accumulation de variants dans la LTEE (Ara-3)")
    fig.tight_layout()
    fig.savefig(output_plot, dpi=150)
    plt.close(fig)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", required=True, help="config.yaml du projet")
    parser.add_argument("--output-table", required=True, help="TSV de sortie")
    parser.add_argument("--output-plot", required=True, help="PNG de sortie")
    args = parser.parse_args()

    with open(args.config) as fh:
        config = yaml.safe_load(fh)

    results_dir = config["paths"]["results"]
    df = build_summary(config, results_dir)
    df.to_csv(args.output_table, sep="\t", index=False)
    plot_summary(df, args.output_plot)

    print(df.to_string(index=False), file=sys.stderr)


if __name__ == "__main__":
    main()
