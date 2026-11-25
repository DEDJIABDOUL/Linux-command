#!/usr/bin/env bash
# Projet 3 et chapitre 16 : exécute la solution publiée (extraite du README).
# Nécessite samtools, bcftools, bedtools et seqkit (ignoré sinon).
# (sourcé par tests/run_all.sh)

echo "-- chapitre 16 et projet 3"
if besoin samtools && besoin bcftools && besoin bedtools && besoin seqkit; then
    P3_HOME="$(mktemp -d)"
    awk '/Afficher la solution/ { dans = 1 }
         dans && /^```bash/ { code = 1; next }
         code && /^```/ { exit }
         code { print }' "$DEPOT/partie1_linux/projet3_du_gene_au_variant/README.md" > "$P3_HOME/du_gene_au_variant.sh"
    HOME="$P3_HOME" bash "$DEPOT/setup.sh" >/dev/null
    B="$P3_HOME/formation_linux"
    F="$B/formats"

    # Chapitre 16
    verifier "faidx chrA:151-153 = ATG"     "ATG" "samtools faidx '$F/reference.fasta' chrA:151-153 | tail -n 1"
    verifier "BED 150-153 = ATG"            "ATG" "bedtools getfasta -fi '$F/reference.fasta' -bed <(printf 'chrA\t150\t153\n') | tail -n 1"
    verifier "BED 151-153 = TG (piège)"     "TG"  "bedtools getfasta -fi '$F/reference.fasta' -bed <(printf 'chrA\t151\t153\n') | tail -n 1"
    verifier "stop de blaTEM = TAG"         "TAG" "samtools faidx '$F/reference.fasta' chrP:959-961 | tail -n 1"
    verifier "SAM : 820 alignées, 30 non"   "820 30" "echo \$(samtools view -c -F 4 '$F/alignements.sam') \$(samtools view -c -f 4 '$F/alignements.sam')"
    verifier "SAM : 782 MAPQ>=30, 409 inverse" "782 409" "echo \$(samtools view -c -q 30 '$F/alignements.sam') \$(samtools view -c -f 16 '$F/alignements.sam')"
    verifier "mpileup 412 : 11 G"           "chrA	412	A	11" "samtools sort -o '$P3_HOME/a.bam' '$F/alignements.sam' 2>/dev/null && samtools index '$P3_HOME/a.bam' && samtools mpileup -f '$F/reference.fasta' -r chrA:412-412 '$P3_HOME/a.bam' 2>/dev/null | cut -f 1-4"
    verifier "12 reads chrA:400-420"        "12" "samtools view -c '$P3_HOME/a.bam' chrA:400-420"
    verifier "Phred : I = Q40"              "40" "echo \$(( \$(printf '%d' \"'I\") - 33 ))"
    verifier "piège -s/-i : 14 au lieu de 8" "14 8" "echo \$(bcftools view -H -s evolue_B -i 'GT=\"alt\"' '$F/variants.vcf' | wc -l) \$(bcftools view -s evolue_B '$F/variants.vcf' | bcftools view -H -i 'GT=\"alt\"' | wc -l)"
    verifier "PASS : A 7, B 6, communs 4"   "7 6 4" "bcftools view -f PASS '$F/variants.vcf' | bcftools query -f '[%GT\t]\n' | awk '\$1 == 1 { a++ } \$2 == 1 { b++ } \$1 == 1 && \$2 == 1 { ab++ } END { print a, b, ab }'"
    verifier "3 variants intergéniques"     "3" "bedtools intersect -a '$F/variants.vcf' -b '$F/genes.bed' -v | wc -l"

    # Projet 3
    cd "$B" || return
    sortie_a="$(bash "$P3_HOME/du_gene_au_variant.sh" evolue_A 2>&1)"
    sortie_b="$(bash "$P3_HOME/du_gene_au_variant.sh" evolue_B 2>&1)"
    cd - >/dev/null || return
    R="$B/projet3"
    verifier "A : 7 variants PASS"          "Variants PASS portés par evolue_A : 7" "echo '$sortie_a' | head -n 1"
    verifier "B : 6 variants PASS"          "Variants PASS portés par evolue_B : 6" "echo '$sortie_b' | head -n 1"
    verifier "A : changements protéiques"   "gyrA I88V|katG S101P|ompC Y134H|blaTEM R84W|tetA V88F" "tr '\t' ' ' < '$R/evolue_A/changements_proteiques.tsv' | paste -sd '|'"
    verifier "A : rapport rpoB"             "rpoB	2967	A	AG	10	decalage_du_cadre(1pb)" "grep '^rpoB' '$R/evolue_A/rapport.tsv'"
    verifier "A : rapport ompC"             "ompC	4750	T	C	5	Y134H" "grep '^ompC' '$R/evolue_A/rapport.tsv'"
    verifier "B : 3 gènes, reads NA"        "3 3" "echo \$(tail -n +2 '$R/evolue_B/rapport.tsv' | wc -l) \$(tail -n +2 '$R/evolue_B/rapport.tsv' | cut -f 5 | grep -c NA)"
    verifier "A : 1 intergénique (chrA 95)" "chrA	95	T	C" "cat '$R/evolue_A/variants_intergeniques.tsv'"
    verifier "Y134H à la main : TAC → CAC"  "TAC CAC" "echo \$(samtools faidx '$R/evolue_A/ref.fasta' chrA:4750-4752 | tail -n 1) \$(samtools faidx '$R/evolue_A/consensus_snps.fasta' chrA:4750-4752 | tail -n 1)"
    verifier "protéines : 1 seul stop chacune" "7" "awk -F '\t' 'gsub(/\\*/, \"\", \$2) == 1' '$R/evolue_A/proteines_ref.tsv' | wc -l"
    verifier "artefact avec indels : 6001 pb" "6001" "bcftools consensus -f '$R/evolue_A/ref.fasta' '$R/evolue_A/variants.vcf.gz' 2>/dev/null | seqkit fx2tab -n -l | head -n 1 | cut -f 2"
    verifier "artefact : katG M1W"          "katG	M1W" "bcftools consensus -f '$R/evolue_A/ref.fasta' '$R/evolue_A/variants.vcf.gz' 2>/dev/null > '$P3_HOME/tout.fa' && samtools faidx '$P3_HOME/tout.fa' && bedtools getfasta -s -name -fi '$P3_HOME/tout.fa' -bed '$F/genes.bed' | seqkit translate | seqkit fx2tab | cut -f 1,2 | paste '$R/evolue_A/proteines_ref.tsv' - | awk -F '\t' '{ g = \$1; sub(/::.*/, \"\", g); if (g == \"katG\") { print g \"\t\" substr(\$2, 1, 1) 1 substr(\$4, 1, 1); exit } }'"
    if besoin shellcheck; then
        verifier "shellcheck : projet 3"    "" "shellcheck '$P3_HOME/du_gene_au_variant.sh'"
    fi
    rm -rf "$P3_HOME"
fi
