#!/bin/bash
#SBATCH --job-name=maker_AED_distribution
#SBATCH --partition=pibu_el8
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=01:00:00
#SBATCH --account=class-sbl-30004-ws-2026
#SBATCH --reservation=class-sbl-30004-2026-10-28
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err

# Summarize MAKER AED values using AED_cdf_generator.pl.
#
# Input: renamed MAKER GFF.
# Output: output/MAKER/final/assembly.all.maker.renamed.gff.AED.txt
#
# This script does not modify or filter the gene annotations.

set -euo pipefail

WORKDIR=/data/users/srais/genome_annotation_course
COURSEDIR=/data/courses/genome_annotation_resources/2026
FINALDIR="$WORKDIR/output/MAKER/final"
CONTAINER="$COURSEDIR/containers/MAKER_3.01.03.sif"

GFF="$FINALDIR/assembly.all.maker.noseq.gff.renamed.gff"
OUTPUT="$FINALDIR/assembly.all.maker.renamed.gff.AED.txt"

# Check the input.
test -s "$GFF"

# Avoid replacing an existing result.
if [ -e "$OUTPUT" ]; then
    echo "Output already exists: $OUTPUT" >&2
    exit 1
fi

mkdir -p "$FINALDIR/tmp"
cd "$FINALDIR"

# Generate the cumulative AED distribution with the course bin width.
apptainer exec --cleanenv \
    --env TMPDIR=/tmp \
    --bind "$FINALDIR/tmp":/tmp \
    --bind "$COURSEDIR" --bind "$WORKDIR" \
    --pwd "$FINALDIR" \
    "$CONTAINER" \
    perl /usr/local/bin/AED_cdf_generator.pl \
    -b 0.025 "$GFF" > "$OUTPUT"

test -s "$OUTPUT"
echo "AED distribution saved to: $OUTPUT"