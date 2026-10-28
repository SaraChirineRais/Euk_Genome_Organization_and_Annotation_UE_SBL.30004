#!/bin/bash
#SBATCH --job-name=maker_rename
#SBATCH --partition=pibu_el8
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=01:00:00
#SBATCH --account=class-sbl-30004-ws-2026
#SBATCH --reservation=class-sbl-30004-2026-10-28
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err

# Copy merged MAKER files and rename their identifiers consistently.
# Original merged files are preserved.
# Tools: maker_map_ids, map_gff_ids and map_fasta_ids.

set -euo pipefail

WORKDIR=/data/users/srais/genome_annotation_course
COURSEDIR=/data/courses/genome_annotation_resources/2026
OUTDIR="$WORKDIR/output/MAKER"
FINALDIR="$OUTDIR/final"
MAKER_SIF="$COURSEDIR/containers/MAKER_3.01.03.sif"

protein="assembly.all.maker.proteins.fasta"
transcript="assembly.all.maker.transcripts.fasta"
gff="assembly.all.maker.noseq.gff"
prefix=ALT

# Check the original merged files.
test -s "$OUTDIR/$gff"
test -s "$OUTDIR/$protein"
test -s "$OUTDIR/$transcript"

# Stop rather than overwrite an existing final directory.
if [ -e "$FINALDIR" ]; then
    echo "The final directory already exists. Check its contents before rerunning." >&2
    exit 1
fi

mkdir -p "$FINALDIR/tmp"

# Create working copies using the filenames specified in the course guide.
cp "$OUTDIR/$gff" "$FINALDIR/${gff}.renamed.gff"
cp "$OUTDIR/$protein" "$FINALDIR/${protein}.renamed.fasta"
cp "$OUTDIR/$transcript" "$FINALDIR/${transcript}.renamed.fasta"

cd "$FINALDIR"

# Create a shared identifier mapping with the accession prefix.
apptainer exec --cleanenv \
    --env TMPDIR=/tmp \
    --bind "$OUTDIR/tmp":/tmp \
    --bind "$COURSEDIR" --bind "$WORKDIR" \
    --pwd "$FINALDIR" "$MAKER_SIF" \
    maker_map_ids --prefix "$prefix" --justify 7 \
    "${gff}.renamed.gff" > id.map

test -s id.map

# Apply the same mapping to the GFF.
apptainer exec --cleanenv \
    --env TMPDIR=/tmp \
    --bind "$OUTDIR/tmp":/tmp \
    --bind "$COURSEDIR" --bind "$WORKDIR" \
    --pwd "$FINALDIR" "$MAKER_SIF" \
    map_gff_ids id.map "${gff}.renamed.gff"

# Apply the mapping to proteins.
apptainer exec --cleanenv \
    --env TMPDIR=/tmp \
    --bind "$OUTDIR/tmp":/tmp \
    --bind "$COURSEDIR" --bind "$WORKDIR" \
    --pwd "$FINALDIR" "$MAKER_SIF" \
    map_fasta_ids id.map "${protein}.renamed.fasta"

# Apply the mapping to transcripts.
apptainer exec --cleanenv \
    --env TMPDIR=/tmp \
    --bind "$OUTDIR/tmp":/tmp \
    --bind "$COURSEDIR" --bind "$WORKDIR" \
    --pwd "$FINALDIR" "$MAKER_SIF" \
    map_fasta_ids id.map "${transcript}.renamed.fasta"

echo "MAKER identifier renaming completed."