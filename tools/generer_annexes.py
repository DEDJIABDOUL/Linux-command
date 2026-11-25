#!/usr/bin/env python3
"""Régénère partie1_linux/annexes/B_aide_memoire.md à partir des encadrés
« L'essentiel » de chaque chapitre de la Partie I.

Usage (depuis la racine du dépôt) : python3 tools/generer_annexes.py
À relancer après toute modification d'un encadré « L'essentiel ».
"""
import io
import os
import re

DEPOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
PARTIE1 = os.path.join(DEPOT, "partie1_linux")

chapitres = sorted(d for d in os.listdir(PARTIE1) if re.match(r"\d\d_", d))
lignes = ["# Annexe B — Aide-mémoire de la Partie I", "",
          "Cette page rassemble les encadrés « L'essentiel » de tous les chapitres.",
          "Elle est **générée automatiquement** à partir des chapitres par",
          "`tools/generer_annexes.py` : ne la modifiez pas à la main.", ""]
for d in chapitres:
    texte = io.open(os.path.join(PARTIE1, d, "README.md"), encoding="utf-8").read()
    titre = texte.split("\n", 1)[0].lstrip("# ").strip()
    bloc = re.search(r"## L'essentiel\n\n```text\n(.*?)\n```", texte, re.S)
    if bloc:
        lignes += [f"## [{titre}](../{d}/README.md)", "", "```text", bloc.group(1), "```", ""]
lignes += ["---", "", "**Retour** : [sommaire de la Partie I](../README.md)", ""]

os.makedirs(os.path.join(PARTIE1, "annexes"), exist_ok=True)
with io.open(os.path.join(PARTIE1, "annexes", "B_aide_memoire.md"), "w", encoding="utf-8", newline="\n") as f:
    f.write("\n".join(lignes))
print("Aide-mémoire régénéré :", len([l for l in lignes if l.startswith("## [")]), "chapitres")
