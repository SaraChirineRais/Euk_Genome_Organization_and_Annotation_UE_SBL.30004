#!/bin/bash
#SBATCH --job-name=interproscan_pfam
#SBATCH --partition=pibu_el8
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --time=02:00:00
#SBATCH --account=class-sbl-30004-ws-2026
#SBATCH --reservation=class-sbl-30004-2026-10-28
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err

# Search for Pfam domains in renamed MAKER proteins using InterProScan.
# Input: output/MAKER/final/assembly.all.maker.proteins.fasta.renamed.fasta
# Output: output/MAKER/final/output.iprscan
# This script does not modify the proteins or filter gene models.

set -euo pipefail

WORKDIR=/data/users/srais/genome_annotation_course
COURSEDIR=/data/courses/genome_annotation_resources/2026
FINALDIR="$WORKDIR/output/MAKER/final"
INTERPROSCAN_SIF="$COURSEDIR/containers/InterProScan_5.70.sif"
PROTEIN="$FINALDIR/assembly.all.maker.proteins.fasta.renamed.fasta"
OUTPUT="$FINALDIR/output.iprscan"

# Check that the protein file exists and is not empty.
test -s "$PROTEIN"

# Stop rather than replace an existing result.
if [ -e "$OUTPUT" ]; then
    echo "Output already exists: $OUTPUT" >&2
    exit 1
fi

mkdir -p "$FINALDIR/tmp"
cd "$FINALDIR"

# Run InterProScan with the Pfam application.
apptainer exec --cleanenv \
    --pwd "$FINALDIR" \
    --bind "$COURSEDIR/data/interproscan-5.70-102.0/data":/opt/interproscan/data \
    --bind "$COURSEDIR" --bind "$WORKDIR" \
    --bind "$FINALDIR/tmp":/temp \
    "$INTERPROSCAN_SIF" \
    /opt/interproscan/interproscan.sh \
    -appl pfam \
    --disable-precalc \
    -f TSV \
    --goterms --iprlookup \
    --seqtype p \
    -cpu "$SLURM_CPUS_PER_TASK" \
    -i "$PROTEIN" \
    -o "$OUTPUT"