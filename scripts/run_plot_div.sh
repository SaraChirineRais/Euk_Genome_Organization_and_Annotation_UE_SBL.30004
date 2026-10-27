#!/bin/bash
#SBATCH --job-name=plot_div
#SBATCH --partition=pibu_el8
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=01:00:00
#SBATCH --account=class-sbl-30004-ws-2026
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err

# Run the TE divergence plotting script.
# Output: plots/TE_divergence/01_TE_divergence.pdf

set -euo pipefail

WORKDIR=/data/users/srais/genome_annotation_course
COURSEDIR=/data/courses/genome_annotation_resources/2026
CONTAINER="$COURSEDIR/containers/Annotation_analysis_R4.4.sif"
R_SCRIPT="$WORKDIR/scripts/06-plot_div.R"

test -s "$R_SCRIPT"
cd "$WORKDIR"

apptainer exec -C \
    --bind "$WORKDIR" --bind "$COURSEDIR" \
    --pwd "$WORKDIR" \
    "$CONTAINER" \
    Rscript --vanilla "$R_SCRIPT"