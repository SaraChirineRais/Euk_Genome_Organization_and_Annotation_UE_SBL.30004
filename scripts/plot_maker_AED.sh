#!/bin/bash
#SBATCH --job-name=plot_maker_AED
#SBATCH --partition=pibu_el8
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=00:30:00
#SBATCH --account=class-sbl-30004-ws-2026
#SBATCH --reservation=class-sbl-30004-2026-10-28
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err

# Plot the cumulative MAKER AED distribution using R.
# Output: plots/MAKER_quality/01_MAKER_AED_cumulative.pdf

set -euo pipefail

WORKDIR=/data/users/srais/genome_annotation_course
COURSEDIR=/data/courses/genome_annotation_resources/2026
CONTAINER="$COURSEDIR/containers/Annotation_analysis_R4.4.sif"
R_SCRIPT="$WORKDIR/scripts/plot_maker_AED.R"

test -s "$R_SCRIPT"
cd "$WORKDIR"

apptainer exec -C \
    --bind "$WORKDIR" --bind "$COURSEDIR" \
    --pwd "$WORKDIR" \
    "$CONTAINER" \
    Rscript --vanilla "$R_SCRIPT"