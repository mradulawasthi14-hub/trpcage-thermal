"""Plot Trp-cage 300 K vs 400 K comparison and write summary.csv."""
import csv, os
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

RES = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "results")
TEMPS = {300: "tab:blue", 400: "tab:red"}

def load(name):
    p = os.path.join(RES, name)
    return np.loadtxt(p, comments=["#", "@"]) if os.path.exists(p) else None

def smooth(y, n=20):
    return np.convolve(y, np.ones(n) / n, mode="valid") if len(y) > n else y

fig, ax = plt.subplots(1, 4, figsize=(20, 4.2))
rows = []
for T, c in TEMPS.items():
    rmsd, rg, rmsf, hb = (load(f"{k}_{T}.xvg") for k in ("rmsd", "rg", "rmsf", "hbond"))
    if rmsd is None:
        continue
    t = rmsd[:, 0] / 1000  # ps -> ns
    sm = smooth(rmsd[:, 1])
    ax[0].plot(t, rmsd[:, 1], c=c, alpha=.25)
    ax[0].plot(t[:len(sm)], sm, c=c, label=f"{T} K")
    ax[1].plot(rg[:, 0] / 1000, rg[:, 1], c=c, alpha=.8, label=f"{T} K")
    ax[2].plot(rmsf[:, 0], rmsf[:, 1], c=c, marker="o", ms=3, label=f"{T} K")
    if hb is not None:
        ax[3].plot(hb[:, 0] / 1000, hb[:, 1], c=c, alpha=.7, label=f"{T} K")
    h = len(rmsd) // 2  # stats on 2nd half of the run
    rows.append([T, rmsd[h:, 1].mean(), rmsd[h:, 1].std(), rg[h:, 1].mean(), rg[h:, 1].std(), rmsf[:, 1].mean()])

ax[0].set(title="Backbone RMSD", xlabel="Time (ns)", ylabel="RMSD (nm)")
ax[1].set(title="Radius of gyration", xlabel="Time (ns)", ylabel="Rg (nm)")
ax[2].set(title="RMSF per residue (C-alpha)", xlabel="Residue", ylabel="RMSF (nm)")
ax[3].set(title="Intramolecular H-bonds", xlabel="Time (ns)", ylabel="count")
for a in ax:
    a.legend(); a.grid(alpha=.25)
fig.suptitle("Trp-cage (1L2Y): 300 K vs 400 K, AMBER99SB-ILDN / TIP3P", y=1.02)
plt.tight_layout()
plt.savefig(os.path.join(RES, "comparison.png"), dpi=300, bbox_inches="tight")

with open(os.path.join(RES, "summary.csv"), "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["T_K", "RMSD_mean_nm", "RMSD_sd_nm", "Rg_mean_nm", "Rg_sd_nm", "RMSF_mean_nm"])
    w.writerows([[r[0]] + [round(x, 4) for x in r[1:]] for r in rows])
print(open(os.path.join(RES, "summary.csv")).read())
