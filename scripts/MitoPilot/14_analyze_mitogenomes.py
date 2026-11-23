#!/usr/bin/env python3
"""
analyze_mitogenomes.py
Preliminary comparison of MitoPilot-exported Stenella mitogenomes.

Inputs : one or more MitoPilot export FASTAs (headers "ID [organism=...] ...").
         Optional --hybrids file (one ID per line) to label putative hybrids
         (otherwise "Stenella sp." in the header is treated as hybrid).
         Optional --mito-calls TSV (sample<TAB>species) from
         scripts/13_species_call_blast.sh to label each hybrid's mito lineage.
Outputs (in --out):
  alignment.fasta          FAMSA multiple alignment
  pairwise_differences.tsv full matrix (substitutions at sites with no gap in either)
  pairwise_pdistance.tsv   same, as p-distance
  group_summary.tsv        within/between group min/median/max differences
  nearest_relatives.tsv    each sample's closest other sample, and closest "pure" sample
  nj_tree.nwk              neighbour-joining tree (midpoint rooted)
  nj_tree.png / .pdf       tree figure coloured by group
Usage:
  python3 analyze_mitogenomes.py --fasta Stenella_batch1.fasta Stenella_batch2.fasta --out results
"""
import argparse, itertools, os, re, statistics, sys
from collections import OrderedDict, defaultdict

import numpy as np
import pyfamsa
from Bio import Phylo
from Bio.Phylo.TreeConstruction import DistanceMatrix, DistanceTreeConstructor


def read_fasta(path):
    seqs, cur = OrderedDict(), None
    with open(path) as fh:
        for line in fh:
            line = line.strip()
            if line.startswith(">"):
                header = line[1:]
                sid = header.split()[0]
                m = re.search(r"\[organism=([^\]]+)\]", header)
                cur = sid
                seqs[sid] = {"organism": m.group(1) if m else "NA", "seq": []}
            elif line:
                seqs[cur]["seq"].append(line.upper())
    for k in seqs:
        seqs[k]["seq"] = "".join(seqs[k]["seq"])
    return seqs


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--fasta", nargs="+", required=True)
    ap.add_argument("--out", default="results")
    ap.add_argument("--hybrids", help="file with one hybrid ID per line")
    ap.add_argument("--mito-calls", help="TSV sample<TAB>species (local BLAST species call)")
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)

    # ---- load -------------------------------------------------------------
    data = OrderedDict()
    for f in a.fasta:
        batch = os.path.basename(f).replace(".fasta", "")
        for k, v in read_fasta(f).items():
            if k in data:
                sys.exit(f"Duplicate ID {k}")
            v["batch"] = batch
            data[k] = v
    ids = list(data)
    hybrids = set()
    if a.hybrids:
        hybrids = {l.strip() for l in open(a.hybrids) if l.strip()}
    else:
        hybrids = {k for k, v in data.items() if v["organism"] == "Stenella sp."}
    mito = {}
    if a.mito_calls:
        for l in open(a.mito_calls):
            p = l.rstrip("\n").split("\t")
            if len(p) >= 2 and p[0] != "sample":
                mito[p[0]] = p[1]

    def group(k):
        if k in hybrids:
            return "hybrid"
        o = data[k]["organism"]
        return {"Stenella attenuata": "S. attenuata", "Stenella frontalis": "S. frontalis",
                "Stenella longirostris": "S. longirostris"}.get(o, o)

    groups = {k: group(k) for k in ids}

    # ---- align ------------------------------------------------------------
    aligner = pyfamsa.Aligner(guide_tree="upgma")
    msa = aligner.align([pyfamsa.Sequence(k.encode(), data[k]["seq"].encode()) for k in ids])
    aln = {s.id.decode(): s.sequence.decode() for s in msa}
    with open(os.path.join(a.out, "alignment.fasta"), "w") as fh:
        for k in ids:
            fh.write(f">{k}\n{aln[k]}\n")
    L = len(aln[ids[0]])
    A = np.array([list(aln[k]) for k in ids])  # n x L

    # ---- pairwise ---------------------------------------------------------
    n = len(ids)
    diff = np.zeros((n, n), dtype=int)
    comp = np.zeros((n, n), dtype=int)
    for i, j in itertools.combinations(range(n), 2):
        ok = (A[i] != "-") & (A[j] != "-")
        d = int(np.sum((A[i] != A[j]) & ok))
        diff[i, j] = diff[j, i] = d
        comp[i, j] = comp[j, i] = int(ok.sum())
    pd_ = np.divide(diff, np.where(comp == 0, 1, comp))

    def write_matrix(m, name, fmt):
        with open(os.path.join(a.out, name), "w") as fh:
            fh.write("ID\t" + "\t".join(ids) + "\n")
            for i, k in enumerate(ids):
                fh.write(k + "\t" + "\t".join(fmt(x) for x in m[i]) + "\n")
    write_matrix(diff, "pairwise_differences.tsv", lambda x: str(int(x)))
    write_matrix(pd_, "pairwise_pdistance.tsv", lambda x: f"{x:.5f}")

    # ---- group summary ----------------------------------------------------
    gnames = ["S. attenuata", "S. frontalis", "S. longirostris", "hybrid"]
    gnames = [g for g in gnames if g in groups.values()] + sorted(set(groups.values()) - set(gnames))
    idx = {g: [i for i, k in enumerate(ids) if groups[k] == g] for g in gnames}
    rows = []
    for g1, g2 in itertools.combinations_with_replacement(gnames, 2):
        if g1 == g2:
            vals = [diff[i, j] for i, j in itertools.combinations(idx[g1], 2)]
        else:
            vals = [diff[i, j] for i in idx[g1] for j in idx[g2]]
        if vals:
            rows.append((g1, g2, len(vals), min(vals), statistics.median(vals), max(vals)))
    with open(os.path.join(a.out, "group_summary.tsv"), "w") as fh:
        fh.write("group1\tgroup2\tn_pairs\tmin\tmedian\tmax\n")
        for r in rows:
            fh.write("\t".join(map(str, r)) + "\n")

    # ---- nearest relatives -------------------------------------------------
    pure = [i for i, k in enumerate(ids) if groups[k] != "hybrid"]
    with open(os.path.join(a.out, "nearest_relatives.tsv"), "w") as fh:
        fh.write("ID\tgroup\tmito_call\tnearest_any\tgroup_of_nearest\tdiffs\tnearest_pure\tgroup_of_pure\tdiffs_pure\n")
        for i, k in enumerate(ids):
            others = [j for j in range(n) if j != i]
            j1 = min(others, key=lambda j: diff[i, j])
            pp = [j for j in pure if j != i]
            j2 = min(pp, key=lambda j: diff[i, j])
            fh.write(f"{k}\t{groups[k]}\t{mito.get(k,'')}\t{ids[j1]}\t{groups[ids[j1]]}\t{diff[i,j1]}\t"
                     f"{ids[j2]}\t{groups[ids[j2]]}\t{diff[i,j2]}\n")

    # ---- NJ tree ------------------------------------------------------------
    lower = [[float(pd_[i, j]) for j in range(i + 1)] for i in range(n)]
    tree = DistanceTreeConstructor().nj(DistanceMatrix(ids, lower))
    tree.root_at_midpoint()
    tree.ladderize()
    for c in tree.find_clades():
        if not c.is_terminal():
            c.name = None
    Phylo.write(tree, os.path.join(a.out, "nj_tree.nwk"), "newick")
    plot_tree(tree, groups, mito, a.out)

    # ---- console report ------------------------------------------------------
    print(f"{n} sequences, alignment length {L}")
    print("\nGroup summary (substitution differences):")
    for r in rows:
        print(f"  {r[0]:16s} vs {r[1]:16s} n={r[2]:5d}  min={r[3]:4d}  median={r[4]:6.1f}  max={r[5]:4d}")


def plot_tree(tree, groups, mito, out):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    from matplotlib.lines import Line2D

    colors = {"S. attenuata": "#2b6cb0", "S. frontalis": "#c05621",
              "S. longirostris": "#2f855a", "hybrid": "#9b2c2c"}
    terms = tree.get_terminals()
    fig_h = max(8, 0.17 * len(terms))
    fig, ax = plt.subplots(figsize=(9, fig_h))

    def label(c):
        if not c.is_terminal():
            return None
        g = groups.get(c.name, "")
        if g == "hybrid":
            m = mito.get(c.name, "")
            tag = {"Stenella attenuata": "att-type", "Stenella frontalis": "fro-type"}.get(m, "")
            return f"{c.name}  [hybrid{', ' + tag if tag else ''}]"
        return c.name

    def lcol(lab):
        # Bio.Phylo passes the label string here, not the clade
        name = str(lab).split()[0] if lab else ""
        return colors.get(groups.get(name, ""), "black")

    Phylo.draw(tree, axes=ax, do_show=False, label_func=label, label_colors=lcol)
    for t in ax.texts:
        t.set_fontsize(6.5)
        if "[hybrid" in t.get_text():
            t.set_fontweight("bold")
    ax.set_ylabel("")
    ax.set_yticks([])
    for s in ["top", "right", "left"]:
        ax.spines[s].set_visible(False)
    ax.set_xlabel("p-distance (substitutions per site)")
    handles = [Line2D([0], [0], color=c, lw=0, marker="s", markersize=8, label=g)
               for g, c in colors.items() if g in groups.values()]
    ax.legend(handles=handles, loc="lower left", frameon=False, fontsize=8)
    ax.set_title("Stenella mitogenomes: neighbour-joining tree (midpoint rooted)", fontsize=10)
    fig.tight_layout()
    fig.savefig(os.path.join(out, "nj_tree.png"), dpi=200)
    fig.savefig(os.path.join(out, "nj_tree.pdf"))


if __name__ == "__main__":
    main()
