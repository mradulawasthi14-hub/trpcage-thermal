#!/usr/bin/env bash
# Trp-cage thermal stress test: build system once, then equilibrate + run at each temperature.
# Usage:  bash scripts/run_all.sh
# Options (env vars): NSTEPS=250000 (500 ps quick test)  TEMPS="300 350 400"  MDRUN_FLAGS="-nb gpu"  GMX=gmx_mpi
set -euo pipefail
cd "$(dirname "$0")/.."

GMX=${GMX:-gmx}
NSTEPS=${NSTEPS:-5000000}
TEMPS=${TEMPS:-"300 400"}
MDRUN_FLAGS=${MDRUN_FLAGS:-""}
export TEMPS GMX

mkdir -p data work results

echo "==> 1. Structure (PDB 1L2Y, NMR model 1)"
[ -f data/1L2Y.pdb ] || wget -q -O data/1L2Y.pdb https://files.rcsb.org/download/1L2Y.pdb
sed -n '/^MODEL        1/,/^ENDMDL/p' data/1L2Y.pdb | grep '^ATOM' > work/trpcage.pdb

cd work

echo "==> 2. Topology (AMBER99SB-ILDN + TIP3P)"
$GMX pdb2gmx -f trpcage.pdb -o processed.gro -ff amber99sb-ildn -water tip3p -ignh

echo "==> 3. Box + solvent"
$GMX editconf -f processed.gro -o boxed.gro -c -d 1.0 -bt cubic
$GMX solvate -cp boxed.gro -cs spc216.gro -o solvated.gro -p topol.top

echo "==> 4. Ions (neutralise + 0.15 M NaCl)"
$GMX grompp -f ../mdp/ions.mdp -c solvated.gro -p topol.top -o ions.tpr -maxwarn 1
echo SOL | $GMX genion -s ions.tpr -o solv_ions.gro -p topol.top -pname NA -nname CL -neutral -conc 0.15

echo "==> 5. Energy minimisation"
$GMX grompp -f ../mdp/em.mdp -c solv_ions.gro -p topol.top -o em.tpr
$GMX mdrun -v -deffnm em $MDRUN_FLAGS

for T in $TEMPS; do
  echo "==================== ${T} K ===================="
  mkdir -p T$T
  cp topol.top posre.itp T$T/
  cd T$T
  sed "s/@TEMP@/$T/g" ../../mdp/nvt.mdp > nvt.mdp
  sed "s/@TEMP@/$T/g" ../../mdp/npt.mdp > npt.mdp
  sed "s/@TEMP@/$T/g; s/@NSTEPS@/$NSTEPS/g" ../../mdp/md.mdp > md.mdp

  echo "==> NVT ($T K)"
  $GMX grompp -f nvt.mdp -c ../em.gro -r ../em.gro -p topol.top -o nvt.tpr
  $GMX mdrun -deffnm nvt $MDRUN_FLAGS

  echo "==> NPT ($T K)"
  $GMX grompp -f npt.mdp -c nvt.gro -r nvt.gro -t nvt.cpt -p topol.top -o npt.tpr
  $GMX mdrun -deffnm npt $MDRUN_FLAGS

  echo "==> Production ($T K)"
  $GMX grompp -f md.mdp -c npt.gro -t npt.cpt -p topol.top -o md.tpr
  $GMX mdrun -deffnm md -v $MDRUN_FLAGS
  cd ..
done

cd ..
bash scripts/analyze.sh
python3 analysis/plot.py
echo "Done. See results/comparison.png and results/summary.csv"
