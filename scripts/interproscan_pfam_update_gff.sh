#!/bin/bash
#SBATCH --job-name=interproscan_pfam_update_gff
#SBATCH --partition=pibu_el8
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=01:00:00
#SBATCH --account=class-sbl-30004-ws-2026
#SBATCH --reservation=class-sbl-30004-2026-10-28
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err

# =============================================================================
# Script: interproscan_pfam_update_gff.sh
# Purpose: Add the previous InterProScan/Pfam results to the renamed MAKER GFF.
# Tool: ipr_update_gff, provided in the MAKER container.
#
# Inputs in output/MAKER/final/:
#   assembly.all.maker.noseq.gff.renamed.gff
#   output.iprscan
#
# Output in output/MAKER/final/:
#   assembly.all.maker.noseq.gff.renamed.iprscan.gff
#
# Input files are preserved. No gene filtering is performed.
# =============================================================================

set -euo pipefail

# Project and software paths.
WORKDIR=/data/users/srais/genome_annotation_course
COURSEDIR=/data/courses/genome_annotation_resources/2026
FINALDIR="$WORKDIR/output/MAKER/final"
CONTAINER="$COURSEDIR/containers/MAKER_3.01.03.sif"

# Input and output files.
GFF="$FINALDIR/assembly.all.maker.noseq.gff.renamed.gff"
IPR="$FINALDIR/output.iprscan"
OUTPUT="$FINALDIR/assembly.all.maker.noseq.gff.renamed.iprscan.gff"

# Check that both input files exist and are not empty.
test -s "$GFF"
test -s "$IPR"

# Avoid overwriting an existing output.
if [ -e "$OUTPUT" ]; then
    echo "Output already exists: $OUTPUT" >&2
    exit 1
fi

mkdir -p "$FINALDIR/tmp"
cd "$FINALDIR"

# Add InterProScan annotations to a new GFF.
apptainer exec --cleanenv \
    --env TMPDIR=/tmp \
    --bind "$FINALDIR/tmp":/tmp \
    --bind "$COURSEDIR" --bind "$WORKDIR" \
    --pwd "$FINALDIR" \
    "$CONTAINER" \
    ipr_update_gff "$GFF" "$IPR" > "$OUTPUT"

echo "GFF update completed: $OUTPUT"