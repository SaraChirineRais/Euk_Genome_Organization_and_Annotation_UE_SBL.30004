#!/bin/bash
#SBATCH --job-name=maker_merge
#SBATCH --partition=pibu_el8
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=01:00:00
#SBATCH --account=class-sbl-30004-ws-2026
#SBATCH --reservation=class-sbl-30004-2026-10-28
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err

# Merge MAKER results using gff3_merge and fasta_merge.
# Output: merged GFF, protein and transcript files in output/MAKER/.
# This script does not rerun MAKER.

set -euo pipefail

WORKDIR=/data/users/srais/genome_annotation_course
COURSEDIR=/data/courses/genome_annotation_resources/2026
MAKER_SIF="$COURSEDIR/containers/MAKER_3.01.03.sif"
OUTDIR="$WORKDIR/output/MAKER"

mkdir -p "$OUTDIR/tmp"
cd "$OUTDIR"

# Find exactly one MAKER master datastore index.
shopt -s nullglob
INDEXES=(*.maker.output/*_master_datastore_index.log)

if [ "${#INDEXES[@]}" -ne 1 ]; then
    echo "Expected one MAKER index; found ${#INDEXES[@]}." >&2
    exit 1
fi

INDEX="${INDEXES[0]}"
test -s "$INDEX"

# Merge GFF annotations with genomic sequences.
apptainer exec --cleanenv \
    --env TMPDIR=/tmp \
    --bind "$OUTDIR/tmp":/tmp \
    --bind "$COURSEDIR" --bind "$WORKDIR" \
    --pwd "$OUTDIR" \
    "$MAKER_SIF" \
    gff3_merge -d "$INDEX" -o assembly.all.maker.gff

# Merge GFF annotations without genomic sequences.
apptainer exec --cleanenv \
    --env TMPDIR=/tmp \
    --bind "$OUTDIR/tmp":/tmp \
    --bind "$COURSEDIR" --bind "$WORKDIR" \
    --pwd "$OUTDIR" \
    "$MAKER_SIF" \
    gff3_merge -n -d "$INDEX" -o assembly.all.maker.noseq.gff

# Merge protein and transcript sequences.
apptainer exec --cleanenv \
    --env TMPDIR=/tmp \
    --bind "$OUTDIR/tmp":/tmp \
    --bind "$COURSEDIR" --bind "$WORKDIR" \
    --pwd "$OUTDIR" \
    "$MAKER_SIF" \
    fasta_merge -d "$INDEX" -o assembly

echo "MAKER merge commands completed."