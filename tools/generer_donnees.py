#!/usr/bin/env python3
"""Génère les jeux de données pédagogiques ajoutés lors de la refonte (lot 1).

Toutes les données produites sont SYNTHÉTIQUES : les séquences sont tirées au
hasard (graine fixe), seuls certains noms de gènes évoquent de vrais gènes
bactériens pour rendre les exercices parlants. Elles ne doivent jamais être
utilisées comme données biologiques réelles.

Le script est déterministe : le relancer produit exactement les mêmes octets.
Il n'utilise que la bibliothèque standard de Python 3.

Usage (depuis la racine du dépôt) :
    python3 tools/generer_donnees.py

Fichiers produits :
    linux/formats/        reference.fasta, annotation.gff3, annotation.gtf,
                          genes.bed, variants.vcf, alignements.sam
    linux/run_sequencage/ arborescence d'un run Illumina simulé (12 échantillons
                          paired-end) + feuille d'échantillons
    linux/pieges/         fichiers volontairement problématiques (exercices de
                          diagnostic)

Les fichiers existants du dossier linux/ (genome.fasta, reads.fastq, ...) ne
sont PAS modifiés.
"""

import gzip
import io
import os
import random

RACINE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "linux")
RNG = random.Random(2026)

COMPLEMENT = str.maketrans("ACGTNacgtn", "TGCANtgcan")
STOPS = {"TAA", "TAG", "TGA"}
ADAPT_R1 = "AGATCGGAAGAGCACACGTCTGAACTCCAGTCA"  # adaptateur TruSeq (lecture 1)
ADAPT_R2 = "AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT"  # adaptateur TruSeq (lecture 2)


def revcomp(seq):
    return seq.translate(COMPLEMENT)[::-1]


def seq_aleatoire(n, gc=0.5):
    poids = [(1 - gc) / 2, gc / 2, gc / 2, (1 - gc) / 2]
    return "".join(RNG.choices("ACGT", weights=poids, k=n))


def cds_aleatoire(n_codons):
    """ATG + codons sans stop interne + codon stop."""
    codons = ["ATG"]
    while len(codons) < n_codons - 1:
        c = seq_aleatoire(3)
        if c not in STOPS:
            codons.append(c)
    codons.append(RNG.choice(sorted(STOPS)))
    return "".join(codons)


def ecrire(chemin, texte, newline="\n"):
    os.makedirs(os.path.dirname(chemin), exist_ok=True)
    with open(chemin, "w", encoding="utf-8", newline=newline) as f:
        f.write(texte)


def ecrire_gz(chemin, texte):
    """gzip reproductible : pas de nom ni de date dans l'en-tête."""
    os.makedirs(os.path.dirname(chemin), exist_ok=True)
    tampon = io.BytesIO()
    with gzip.GzipFile(filename="", mode="wb", fileobj=tampon, mtime=0) as gz:
        gz.write(texte.encode("ascii"))
    with open(chemin, "wb") as f:
        f.write(tampon.getvalue())


def replier(seq, largeur=60):
    return "\n".join(seq[i:i + largeur] for i in range(0, len(seq), largeur))


def qualite(longueur, base_q=37, chute=0.12, bruit=3):
    """Chaîne Phred+33 dont la qualité baisse le long du read."""
    car = []
    for i in range(longueur):
        q = int(base_q - chute * i + RNG.randint(-bruit, bruit))
        q = max(2, min(41, q))
        car.append(chr(q + 33))
    return "".join(car)


# ---------------------------------------------------------------------------
# 1. Mini-génome de référence + annotations
# ---------------------------------------------------------------------------
# (type, longueur, nom, brin, produit) ; "ig" = région intergénique
PLAN = {
    "chrA": [
        ("ig", 150), ("gene", 900, "gyrA", "+", "sous-unité A de l'ADN gyrase"),
        ("ig", 120), ("gene", 750, "recA", "-", "protéine de recombinaison RecA"),
        ("ig", 200), ("gene", 1200, "rpoB", "+", "sous-unité bêta de l'ARN polymérase"),
        ("ig", 180), ("gene", 600, "katG", "-", "catalase-peroxydase"),
        ("ig", 250), ("gene", 960, "ompC", "+", "porine de membrane externe C"),
        ("ig", 690),
    ],
    "chrP": [
        ("ig", 100), ("gene", 861, "blaTEM", "+", "bêta-lactamase TEM"),
        ("ig", 200), ("gene", 600, "tetA", "-", "pompe d'efflux de la tétracycline"),
        ("ig", 639),
    ],
}

reference = {}
genes = []  # dicts : contig, debut (1-based), fin (1-based incluse), nom, brin, produit
for contig, blocs in PLAN.items():
    morceaux, pos = [], 0
    for bloc in blocs:
        if bloc[0] == "ig":
            morceaux.append(seq_aleatoire(bloc[1], gc=0.45))
            pos += bloc[1]
        else:
            _, longueur, nom, brin, produit = bloc
            cds = cds_aleatoire(longueur // 3)
            morceaux.append(cds if brin == "+" else revcomp(cds))
            genes.append(dict(contig=contig, debut=pos + 1, fin=pos + longueur,
                              nom=nom, brin=brin, produit=produit))
            pos += longueur
    reference[contig] = "".join(morceaux)

FORMATS = os.path.join(RACINE, "formats")
ecrire(os.path.join(FORMATS, "reference.fasta"),
       "".join(f">{c} organisme=synthetique longueur={len(s)}\n{replier(s)}\n"
               for c, s in reference.items()))

# GFF3 : gene -> mRNA -> exon + CDS (coordonnées 1-based, intervalles fermés)
gff = ["##gff-version 3"]
gff += [f"##sequence-region {c} 1 {len(s)}" for c, s in reference.items()]
gff.append("# Annotation SYNTHÉTIQUE produite par tools/generer_donnees.py")
gtf = ["# Annotation SYNTHÉTIQUE produite par tools/generer_donnees.py"]
bed = []
for i, g in enumerate(genes, start=1):
    gid, tid = f"gene{i:02d}", f"mrna{i:02d}"
    commun = f"{g['contig']}\tsynthese\t%s\t{g['debut']}\t{g['fin']}\t.\t{g['brin']}\t%s\t%s"
    produit = g["produit"].replace(" ", "%20")
    gff.append(commun % ("gene", ".", f"ID={gid};Name={g['nom']};product={produit}"))
    gff.append(commun % ("mRNA", ".", f"ID={tid};Parent={gid};Name={g['nom']}"))
    gff.append(commun % ("exon", ".", f"ID=exon{i:02d};Parent={tid}"))
    gff.append(commun % ("CDS", "0", f"ID=cds{i:02d};Parent={tid}"))
    attr = f'gene_id "{gid}"; transcript_id "{tid}"; gene_name "{g["nom"]}";'
    gtf.append(commun % ("transcript", ".", attr))
    gtf.append(commun % ("exon", ".", attr))
    gtf.append(commun % ("CDS", "0", attr))
    # BED : 0-based, demi-ouvert -> début - 1
    bed.append(f"{g['contig']}\t{g['debut'] - 1}\t{g['fin']}\t{g['nom']}\t0\t{g['brin']}")
ecrire(os.path.join(FORMATS, "annotation.gff3"), "\n".join(gff) + "\n")
ecrire(os.path.join(FORMATS, "annotation.gtf"), "\n".join(gtf) + "\n")
ecrire(os.path.join(FORMATS, "genes.bed"), "\n".join(bed) + "\n")

# ---------------------------------------------------------------------------
# 2. Variants (VCF 4.2, organisme haploïde) : deux souches évoluées
# ---------------------------------------------------------------------------
# Contigs : chrA = chromosome, chrP = plasmide.
# (contig, position 1-based, type, alt pour SNP / longueur d'indel, GT A, GT B)
PLAN_VARIANTS = [
    ("chrA", 95, "snp", 1, 1),     # intergénique
    ("chrA", 412, "snp", 1, 1),    # gyrA
    ("chrA", 655, "snp", 1, 0),    # gyrA
    ("chrA", 1388, "snp", 0, 1),   # recA
    ("chrA", 1702, "del2", 1, 0),  # recA (délétion de 2 pb)
    ("chrA", 2480, "snp", 1, 1),   # rpoB
    ("chrA", 2967, "ins1", 1, 0),  # rpoB (insertion de 1 pb)
    ("chrA", 3120, "snp", 1, 0),   # rpoB
    ("chrA", 3420, "snp", 0, 1),   # intergénique
    ("chrA", 3800, "snp", 1, 1),   # katG
    ("chrA", 4750, "snp", 1, 0),   # ompC
    ("chrA", 5600, "snp", 0, 1),   # intergénique
    ("chrP", 350, "snp", 1, 1),      # blaTEM
    ("chrP", 1500, "snp", 1, 0),     # tetA
]
variants = []
for contig, pos, typ, gta, gtb in PLAN_VARIANTS:
    seq = reference[contig]
    # Indels normalisés (alignés à gauche) : on décale la position tant que
    # l'indel pourrait être écrit plus à gauche (règle appliquée par bcftools norm).
    if typ == "del2":
        while seq[pos - 1] == seq[pos + 1]:
            pos += 1
    ref_base = seq[pos - 1]
    if typ == "snp":
        ref, alt = ref_base, RNG.choice([b for b in "ACGT" if b != ref_base])
    elif typ == "del2":
        ref, alt = reference[contig][pos - 1:pos + 2], ref_base
    else:  # ins1
        ref, alt = ref_base, ref_base + RNG.choice([b for b in "ACGT" if b != ref_base])
    qual = RNG.choice([18, 22, 45, 60, 87, 120, 150, 210])
    dp_a, dp_b = RNG.randint(8, 40), RNG.randint(8, 40)
    variants.append(dict(contig=contig, pos=pos, ref=ref, alt=alt, qual=qual,
                         filtre="PASS" if qual >= 30 else "LowQual",
                         dp=dp_a + dp_b, gta=gta, gtb=gtb, dpa=dp_a, dpb=dp_b))

vcf = ["##fileformat=VCFv4.2",
       "##source=tools/generer_donnees.py (donnees SYNTHETIQUES)",
       "##reference=reference.fasta"]
vcf += [f"##contig=<ID={c},length={len(s)}>" for c, s in reference.items()]
vcf += ['##FILTER=<ID=LowQual,Description="QUAL inferieure a 30">',
        '##INFO=<ID=DP,Number=1,Type=Integer,Description="Profondeur totale">',
        '##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype (haploide)">',
        '##FORMAT=<ID=DP,Number=1,Type=Integer,Description="Profondeur par echantillon">',
        "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tevolue_A\tevolue_B"]
for v in variants:
    vcf.append(f"{v['contig']}\t{v['pos']}\t.\t{v['ref']}\t{v['alt']}\t{v['qual']}\t"
               f"{v['filtre']}\tDP={v['dp']}\tGT:DP\t{v['gta']}:{v['dpa']}\t{v['gtb']}:{v['dpb']}")
ecrire(os.path.join(FORMATS, "variants.vcf"), "\n".join(vcf) + "\n")

# ---------------------------------------------------------------------------
# 3. Alignements SAM de la souche evolue_A (single-end, 100 pb)
# ---------------------------------------------------------------------------
def haplotype(contig, souche="gta"):
    """Liste de (base, position_ref_0based ou None si insérée)."""
    seq = reference[contig]
    par_pos = {v["pos"] - 1: v for v in variants if v["contig"] == contig and v[souche] == 1}
    jetons, i = [], 0
    while i < len(seq):
        v = par_pos.get(i)
        if v is None:
            jetons.append((seq[i], i))
            i += 1
        elif len(v["ref"]) == 1 and len(v["alt"]) == 1:      # SNP
            jetons.append((v["alt"], i))
            i += 1
        elif len(v["ref"]) > len(v["alt"]):                  # délétion
            jetons.append((seq[i], i))
            i += len(v["ref"])
        else:                                                # insertion
            jetons.append((seq[i], i))
            jetons += [(b, None) for b in v["alt"][1:]]
            i += 1
    return jetons


def cigar(jetons):
    ops, prec = [], None
    for _, rp in jetons:
        if rp is None:
            op = "I"
        else:
            if prec is not None and rp - prec > 1:
                ops.append(("D", rp - prec - 1))
            op, prec = "M", rp
        if ops and ops[-1][0] == op:
            ops[-1] = (op, ops[-1][1] + 1)
        else:
            ops.append((op, 1))
    return "".join(f"{n}{o}" for o, n in ops)


LONG = 100
lectures = []
for contig, n_reads in (("chrA", 600), ("chrP", 220)):
    hap = haplotype(contig)
    for _ in range(n_reads):
        while True:
            debut = RNG.randint(0, len(hap) - LONG)
            morceau = hap[debut:debut + LONG]
            if morceau[0][1] is not None:  # un read ne commence pas par une insertion
                break
        sequence = "".join(b for b, _ in morceau)
        flag = RNG.choice([0, 16])
        mapq = 60 if RNG.random() > 0.05 else RNG.choice([0, 3, 12])
        lectures.append([contig, morceau[0][1] + 1, flag, mapq, cigar(morceau), sequence])
lectures.sort(key=lambda r: (list(reference).index(r[0]), r[1]))

sam = ["@HD\tVN:1.6\tSO:coordinate"]
sam += [f"@SQ\tSN:{c}\tLN:{len(s)}" for c, s in reference.items()]
sam += ["@RG\tID:evolue_A\tSM:evolue_A\tPL:ILLUMINA",
        "@PG\tID:simulateur\tPN:generer_donnees.py\tVN:1.0\tCL:python3 tools/generer_donnees.py"]
for n, (contig, pos, flag, mapq, cig, seq) in enumerate(lectures, start=1):
    sam.append(f"read{n:04d}\t{flag}\t{contig}\t{pos}\t{mapq}\t{cig}\t*\t0\t0\t{seq}\t"
               f"{qualite(LONG)}\tRG:Z:evolue_A")
for k in range(1, 31):  # reads non alignés : FLAG 4, pas de position
    sam.append(f"nonaligne{k:02d}\t4\t*\t0\t0\t*\t*\t0\t0\t{seq_aleatoire(LONG)}\t"
               f"{qualite(LONG, base_q=25)}\tRG:Z:evolue_A")
ecrire(os.path.join(FORMATS, "alignements.sam"), "\n".join(sam) + "\n")

# ---------------------------------------------------------------------------
# 4. Run Illumina simulé : 12 échantillons paired-end
# ---------------------------------------------------------------------------
RUN = os.path.join(RACINE, "run_sequencage")
genome_concat = reference["chrA"] + reference["chrP"]


def paire_de_reads(taux_adapt, taux_n, base_q, longueur=100):
    insert = RNG.randint(60, 99) if RNG.random() < taux_adapt else RNG.randint(180, 400)
    debut = RNG.randint(0, len(genome_concat) - insert)
    fragment = genome_concat[debut:debut + insert]
    if RNG.random() < 0.5:
        fragment = revcomp(fragment)
    r1 = (fragment + ADAPT_R1 + "A" * longueur)[:longueur]
    r2 = (revcomp(fragment) + ADAPT_R2 + "A" * longueur)[:longueur]
    r1 = "".join("N" if RNG.random() < taux_n else b for b in r1)
    r2 = "".join("N" if RNG.random() < taux_n else b for b in r2)
    return r1, r2, qualite(longueur, base_q), qualite(longueur, base_q - 3)


ECHANTILLONS = [  # (patient, condition, nb de paires, taux adaptateurs, taux N, Q de départ)
    ("P01", "temoin", 300, 0.05, 0.001, 37), ("P02", "temoin", 280, 0.04, 0.001, 37),
    ("P03", "temoin", 350, 0.06, 0.002, 36), ("P04", "temoin", 310, 0.05, 0.001, 37),
    ("P05", "temoin", 260, 0.08, 0.002, 36), ("P06", "temoin", 330, 0.05, 0.001, 37),
    ("P07", "traite", 290, 0.05, 0.001, 37), ("P08", "traite", 340, 0.07, 0.002, 36),
    ("P09", "traite", 150, 0.30, 0.030, 24),  # échantillon de mauvaise qualité
    ("P10", "traite", 320, 0.05, 0.001, 37), ("P11", "traite", 300, 0.06, 0.001, 37),
    ("P12", "traite", 270, 0.05, 0.002, 36),
]
feuille = ["sample_id\tpatient\tcondition\treplicat\tfichier_R1\tfichier_R2"]
rep = {"temoin": 0, "traite": 0}
for num, (patient, cond, n, ta, tn, q) in enumerate(ECHANTILLONS, start=1):
    rep[cond] += 1
    prefixe = f"{patient}_S{num}_L001"
    blocs1, blocs2 = [], []
    for k in range(1, n + 1):
        r1, r2, q1, q2 = paire_de_reads(ta, tn, q)
        ident = f"@M07112:58:000000000-KX4LT:1:1101:{1000 + 37 * k}:{1500 + 11 * k}"
        blocs1.append(f"{ident} 1:N:0:{num}\n{r1}\n+\n{q1}\n")
        blocs2.append(f"{ident} 2:N:0:{num}\n{r2}\n+\n{q2}\n")
    ecrire_gz(os.path.join(RUN, "fastq", f"{prefixe}_R1_001.fastq.gz"), "".join(blocs1))
    ecrire_gz(os.path.join(RUN, "fastq", f"{prefixe}_R2_001.fastq.gz"), "".join(blocs2))
    feuille.append(f"{patient}\t{patient}\t{cond}\t{rep[cond]}\t"
                   f"{prefixe}_R1_001.fastq.gz\t{prefixe}_R2_001.fastq.gz")
ecrire(os.path.join(RUN, "echantillons.tsv"), "\n".join(feuille) + "\n")

# Leurre pour la « chasse au trésor » : un ancien run de test au même nom de fichier
ancien = "".join(f"@TEST:1:FC:1:1:{k}:{k} 1:N:0:7\n{seq_aleatoire(100)}\n+\n{qualite(100, 20)}\n"
                 for k in range(1, 51))
ecrire_gz(os.path.join(RUN, "archives", "2025-03_run_test", "P07_S7_L001_R1_001.fastq.gz"), ancien)
ecrire(os.path.join(RUN, "archives", "2025-03_run_test", "LISEZMOI.txt"),
       "Run de test de mars 2025 : NE PAS utiliser pour l'analyse.\n")
ecrire(os.path.join(RUN, "rapports", "run_info.txt"),
       "Instrument : MiSeq (simulation pédagogique)\n"
       "Run        : 2026-10-14_M07112_0058\n"
       "Chimie     : 2 x 100 pb, paired-end\n"
       "Echantillons : 12 (voir ../echantillons.tsv)\n"
       "Remarque   : le patient P09 a été prélevé dans de mauvaises conditions.\n")
ecrire(os.path.join(RUN, ".run_termine"), "Transfert terminé le 2026-10-15 à 07:42\n")

# ---------------------------------------------------------------------------
# 5. Pièges : fichiers volontairement problématiques
# ---------------------------------------------------------------------------
PIEGES = os.path.join(RACINE, "pieges")

# 5.1 FASTQ tronqué (téléchargement interrompu) : 40 reads complets + 1 incomplet
blocs = [f"@lecture_{k:02d}\n{seq_aleatoire(80)}\n+\n{qualite(80)}\n" for k in range(1, 41)]
blocs.append(f"@lecture_41\n{seq_aleatoire(80)}\n+\n")
ecrire(os.path.join(PIEGES, "fastq_tronque.fastq"), "".join(blocs))

# 5.2 Motif ATGCGT : 2 fois sur une même ligne + 1 fois coupé entre deux lignes
def sans_motif(n):
    while True:
        s = seq_aleatoire(n)
        if "ATGCGT" not in s and "ATG" not in s[-5:] and "CGT" not in s[:5]:
            return s

l1 = sans_motif(10) + "ATGCGT" + sans_motif(20) + "ATGCGT" + sans_motif(18)  # 60 car.
l2 = sans_motif(57) + "ATG"                                                     # 60 car.
l3 = "CGT" + sans_motif(37)                                                     # 40 car.
assert len(l1) == 60 and len(l2) == 60
ecrire(os.path.join(PIEGES, "motif_coupe.fasta"), f">sequence_piege\n{l1}\n{l2}\n{l3}\n")

# 5.3 Fichier aux fins de ligne Windows (CRLF)
ecrire(os.path.join(PIEGES, "mesures_windows.tsv"),
       "echantillon\tconcentration_ng_ul\nP01\t52.3\nP02\t48.9\nP03\t61.0\n", newline="\r\n")

# 5.4 Nom de fichier contenant des espaces
ecrire(os.path.join(PIEGES, "mes resultats finaux.txt"),
       "Ce fichier a un nom contenant des espaces.\n"
       "Essayez : cat mes resultats finaux.txt   (échoue)\n"
       "Puis    : cat \"mes resultats finaux.txt\" (fonctionne)\n")

# 5.5 Script contenant 5 erreurs typiques (exercice de débogage)
ecrire(os.path.join(PIEGES, "script_casse.sh"),
       "#!/usr/bin/env bash\n"
       "# Ce script contient VOLONTAIREMENT plusieurs erreurs.\n"
       "# Objectif : compter les reads de chaque échantillon du run.\n"
       "set -euo pipefail\n"
       "\n"
       "DOSSIER=../run_sequencage/fastqs\n"
       "\n"
       "for f in $DOSSIER/*_R1_001.fastq.gz; do\n"
       "    n=$(( $(zcat $f | wc -l) / 4 ))\n"
       "    echo \"$f : $n paires de reads\" >> $SORTIE\n"
       "done\n", newline="\r\n")

print("Données générées dans", os.path.normpath(RACINE))
