#!/bin/bash
#SBATCH --job-name=03_LTR_plots
#SBATCH --partition=pibu_el8
#SBATCH --nodes=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --time=1-00:00:00
#SBATCH --account=class-sbl-30004-ws-2026
#SBATCH --reservation=class-sbl-30004-2026-10-15
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err

set -euo pipefail

COURSEDIR=/data/courses/genome_annotation_resources/2026
WORKDIR=/data/users/srais/genome_annotation_course
OUTDIR="$WORKDIR/results/TE_annotation/LTR_full_length"

# Switch to the directory containing the TEsorter results.
cd "$OUTDIR"

# Check that the required input files and R script exist and are not empty.
test -s intact_LTR.gff3
test -s intact_LTR.fa.rexdb-plant.cls.tsv
test -s "$WORKDIR/scripts/03-full_length_LTRs_identity_copy.R"

# Run the R script using the course analysis container.
apptainer exec -C \
    --bind "$WORKDIR" --bind "$COURSEDIR" \
    --pwd "$OUTDIR" \
    "$COURSEDIR/containers/Annotation_analysis_R4.4.sif" \
    Rscript --vanilla \
    "$WORKDIR/scripts/03-full_length_LTRs_identity_copy.R"

# Copy the generated figures to the project's main plots directory.
mkdir -p "$WORKDIR/plots/LTR_full_length"
cp "$OUTDIR"/plots/*.png "$OUTDIR"/plots/*.pdf \
    "$WORKDIR/plots/LTR_full_length/"