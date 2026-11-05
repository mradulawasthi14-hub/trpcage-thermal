#!/usr/bin/env bash
# Trajectory analysis: RMSD, radius of gyration, RMSF per residue, H-bonds, for every T that was run.
set -euo pipefail
cd "$(dirname "$0")/.."
GMX=${GMX:-gmx}
TEMPS=${TEMPS:-"300 400"}
mkdir -p results

for T in $TEMPS; do
  echo "==> Analysing ${T} K"
  cd work/T$T
  # fix periodic-boundary jumps, centre protein
  printf "Protein\nSystem\n" | $GMX trjconv -s md.tpr -f md.xtc -o md_center.xtc -pbc mol -center
  printf "Backbone\nBackbone\n" | $GMX rms    -s md.tpr -f md_center.xtc -o ../../results/rmsd_$T.xvg
  printf "Protein\n"            | $GMX gyrate -s md.tpr -f md_center.xtc -o ../../results/rg_$T.xvg
  printf "C-alpha\n"            | $GMX rmsf   -s md.tpr -f md_center.xtc -o ../../results/rmsf_$T.xvg -res
  printf "Protein\nProtein\n"   | $GMX hbond  -s md.tpr -f md_center.xtc -num ../../results/hbond_$T.xvg
  # last frame as PDB for rendering in PyMOL/VMD
  printf "Protein\n"            | $GMX trjconv -s md.tpr -f md_center.xtc -o ../../results/final_$T.pdb -dump 1000000
  cd ../..
done
