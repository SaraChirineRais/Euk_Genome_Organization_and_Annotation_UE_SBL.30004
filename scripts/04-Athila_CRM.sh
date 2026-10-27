#!/bin/bash
#SBATCH --job-name=04_Athila_CRM
#SBATCH --partition=pibu_el8
#SBATCH --nodes=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --time=01:00:00
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err

set -euo pipefail

COURSEDIR=/data/courses/genome_annotation_resources/2026
WORKDIR=/data/users/srais/genome_annotation_course
CONTAINER="$COURSEDIR/containers/Annotation_analysis_R4.4.sif"

# Check that the R script exists and is not empty.
test -s "$WORKDIR/scripts/04-Athila_CRM.R"

# Run the R script using the course analysis container.
apptainer exec -C \
    --bind "$WORKDIR" --bind "$COURSEDIR" \
    "$CONTAINER" \
    Rscript --vanilla \
    "$WORKDIR/scripts/04-Athila_CRM.R"