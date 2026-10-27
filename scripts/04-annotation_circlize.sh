#!/bin/bash
#SBATCH --job-name=04_annotation_circlize
#SBATCH --partition=pibu_el8
#SBATCH --nodes=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --time=01:00:00
#SBATCH --account=class-sbl-30004-ws-2026
#SBATCH --reservation=class-sbl-30004-2026-10-21
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err

set -euo pipefail

COURSEDIR=/data/courses/genome_annotation_resources/2026
WORKDIR=/data/users/srais/genome_annotation_course
GENOME="$WORKDIR/data/assemblies/ERR11437324_Altai-5.fa"
GFF="$WORKDIR/results/TE_annotation/EDTA/ERR11437324_Altai-5.fa.mod.EDTA.TEanno.gff3"
OUTDIR="$WORKDIR/plots/TE_density"
CONTAINER="$COURSEDIR/containers/Annotation_analysis_R4.4.sif"

# Check that the required files exist and are not empty.
test -s "$GENOME"
test -s "$GFF"
test -s "$WORKDIR/scripts/04-annotation_circlize.R"

# Create the directory for the plot.
mkdir -p "$OUTDIR"

# Create the FASTA index containing scaffold names and lengths.
apptainer exec -C \
    --bind "$WORKDIR" \
    "$CONTAINER" \
    samtools faidx "$GENOME"

# Run the R script from the plot output directory.
cd "$OUTDIR"

apptainer exec -C \
    --bind "$WORKDIR" --bind "$COURSEDIR" \
    --pwd "$OUTDIR" \
    "$CONTAINER" \
    Rscript --vanilla \
    "$WORKDIR/scripts/04-annotation_circlize.R"