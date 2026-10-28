#!/bin/bash
#SBATCH --job-name=Pfam_by_AED
#SBATCH --partition=pshort_el8
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=00:30:00
#SBATCH --account=class-sbl-30004-ws-2026
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err

# Calculate the proportion of retained proteins with Pfam domains,
# overall and within AED <= 0.5 and AED > 0.5 groups.
# R script: scripts/Pfam_by_AED.R
# Results: output/MAKER/final/Pfam_by_AED/

set -euo pipefail

WORKDIR=/data/users/srais/genome_annotation_course
COURSEDIR=/data/courses/genome_annotation_resources/2026
CONTAINER="$COURSEDIR/containers/Annotation_analysis_R4.4.sif"
R_SCRIPT="$WORKDIR/scripts/Pfam_by_AED.R"

test -s "$R_SCRIPT"
cd "$WORKDIR"

apptainer exec -C \
    --bind "$WORKDIR" --bind "$COURSEDIR" \
    --pwd "$WORKDIR" \
    "$CONTAINER" \
    Rscript --vanilla "$R_SCRIPT"