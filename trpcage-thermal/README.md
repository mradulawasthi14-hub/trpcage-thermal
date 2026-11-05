# Does a tiny protein survive the heat? Trp-cage thermal stress test (GROMACS)

Molecular dynamics of the 20-residue miniprotein **Trp-cage (PDB 1L2Y)** at **300 K vs 400 K**, comparing structural stability through RMSD, radius of gyration, per-residue RMSF and H-bond count.
Thermostability is a core question in enzyme engineering, so this is a small-scale version of a real biotech problem.

![comparison](results/comparison.png)

> Replace the figure and the table below with your own results after running.

| T (K) | RMSD (nm) | Rg (nm) | RMSF mean (nm) |
|-------|-----------|---------|----------------|
| 300   | _fill in_ | _fill in_ | _fill in_ |
| 400   | _fill in_ | _fill in_ | _fill in_ |

(Numbers come from `results/summary.csv`.)

## Methods
- Structure: PDB 1L2Y, NMR model 1
- Force field AMBER99SB-ILDN, water TIP3P
- Cubic box, 1.0 nm solute-box distance, 0.15 M NaCl plus neutralising ions
- Minimisation: steepest descent (Fmax < 1000 kJ/mol/nm)
- Equilibration: 100 ps NVT + 100 ps NPT, protein position-restrained, V-rescale thermostat, C-rescale barostat
- Production: 10 ns, 2 fs timestep, H-bond constraints (LINCS), PME electrostatics, 1.0 nm cutoffs
- Software: GROMACS _<your version from `gmx --version`>_, Python 3, NumPy, Matplotlib

## Reproduce
```bash
conda install -c conda-forge gromacs numpy matplotlib    # or: sudo apt install gromacs (WSL/Ubuntu)
NSTEPS=250000 bash scripts/run_all.sh                    # 500 ps smoke test first
bash scripts/run_all.sh                                  # full 10 ns x 2 temperatures
MDRUN_FLAGS="-nb gpu" bash scripts/run_all.sh            # with an NVIDIA GPU
```
Outputs land in `results/`. Raw trajectories stay in `work/` and are git-ignored.

## Limitations
- One replica per temperature and 10 ns: **preliminary**, not statistically rigorous.
- 400 K is far above Trp-cage's experimental melting point (~315 K), so unfolding is expected; rates and pathways would need many replicas or replica exchange.
- Fixed-charge force fields and TIP3P are not tuned for high-temperature behaviour.

## Next steps
- 3+ replicas with different seeds, report mean +/- SD
- Intermediate temperatures (325, 350, 375 K) to bracket the melting transition
- Stabilising mutant vs wild type
- Secondary-structure timeline and free-energy landscape on RMSD/Rg

## Layout
```
mdp/       parameter templates (@TEMP@, @NSTEPS@ filled in by the script)
scripts/   run_all.sh (full pipeline), analyze.sh
analysis/  plot.py
results/   .xvg data, comparison.png, summary.csv, final snapshots
work/      raw GROMACS output (git-ignored)
```
