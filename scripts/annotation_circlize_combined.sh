#!/bin/bash
#SBATCH --job-name=annotation_circlize_combined
#SBATCH --partition=pibu_el8
#SBATCH --nodes=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --time=01:00:00
#SBATCH --account=class-sbl-30004-ws-2026
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err

# =============================================================================
# Script: annotation_circlize_combined.sh
# Purpose: Run annotation_circlize_combined.R using the course R container.
#
# R script:
#   scripts/annotation_circlize_combined.R
#
# Expected output:
#   plots/TE_density/05-TE_density_combined.pdf
#
# Job messages are saved in logs/ using the job name and job ID.
# =============================================================================

set -euo pipefail

WORKDIR=/data/users/srais/genome_annotation_course
COURSEDIR=/data/courses/genome_annotation_resources/2026
CONTAINER="$COURSEDIR/containers/Annotation_analysis_R4.4.sif"
R_SCRIPT="$WORKDIR/scripts/annotation_circlize_combined.R"

# Check that the R script exists and is not empty.
test -s "$R_SCRIPT"

# Run the combined circular plot script.
cd "$WORKDIR"

apptainer exec -C \
    --bind "$WORKDIR" --bind "$COURSEDIR" \
    --pwd "$WORKDIR" \
    "$CONTAINER" \
    Rscript --vanilla "$R_SCRIPT"