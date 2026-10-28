#!/bin/bash
#SBATCH --job-name=maker_gff_quality_filter
#SBATCH --partition=pibu_el8
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=01:00:00
#SBATCH --account=class-sbl-30004-ws-2026
#SBATCH --reservation=class-sbl-30004-2026-10-28
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err

# =============================================================================
# Script: maker_gff_quality_filter.sh
# Purpose: Filter the MAKER GFF enriched with InterProScan annotations.
# Tool: quality_filter.pl -s, provided in the MAKER container.
# Course criterion: retain transcripts with AED < 1 and/or a Pfam domain.
#
# Input in output/MAKER/final/:
#   assembly.all.maker.noseq.gff.renamed.iprscan.gff
#
# Output in output/MAKER/final/:
#   assembly.all.maker.noseq.gff_iprscan_quality_filtered.gff
#
# The input file is preserved.
# =============================================================================

set -euo pipefail

# Project and software paths.
WORKDIR=/data/users/srais/genome_annotation_course
COURSEDIR=/data/courses/genome_annotation_resources/2026
FINALDIR="$WORKDIR/output/MAKER/final"
CONTAINER="$COURSEDIR/containers/MAKER_3.01.03.sif"

# Input and output files.
INPUT="$FINALDIR/assembly.all.maker.noseq.gff.renamed.iprscan.gff"
OUTPUT="$FINALDIR/assembly.all.maker.noseq.gff_iprscan_quality_filtered.gff"

# Check that the input exists and is not empty.
test -s "$INPUT"

# Avoid overwriting an existing result.
if [ -e "$OUTPUT" ]; then
    echo "Output already exists: $OUTPUT" >&2
    exit 1
fi

mkdir -p "$FINALDIR/tmp"
cd "$FINALDIR"

# Filter the enriched MAKER annotations.
apptainer exec --cleanenv \
    --env TMPDIR=/tmp \
    --bind "$FINALDIR/tmp":/tmp \
    --bind "$COURSEDIR" --bind "$WORKDIR" \
    --pwd "$FINALDIR" \
    "$CONTAINER" \
    perl /usr/local/bin/quality_filter.pl \
    -s "$INPUT" > "$OUTPUT"

test -s "$OUTPUT"
echo "Quality-filtered annotations saved to: $OUTPUT"