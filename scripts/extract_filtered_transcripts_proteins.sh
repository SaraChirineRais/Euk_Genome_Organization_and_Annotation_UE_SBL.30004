#!/bin/bash
#SBATCH --job-name=extract_filtered_transcripts_proteins
#SBATCH --partition=pibu_el8
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=00:30:00
#SBATCH --account=class-sbl-30004-ws-2026
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err

# =============================================================================
# Extract retained mRNA IDs from filtered.genes.renamed.gff3.
# Use seqkit grep to select corresponding transcripts and proteins.
#
# Outputs in output/MAKER/final/:
#   list.txt
#   assembly.all.maker.transcripts.fasta.renamed.filtered.fasta
#   assembly.all.maker.proteins.fasta.renamed.filtered.fasta
#
# Original FASTA files are preserved.
# =============================================================================

set -euo pipefail

WORKDIR=/data/users/srais/genome_annotation_course
COURSEDIR=/data/courses/genome_annotation_resources/2026
FINALDIR="$WORKDIR/output/MAKER/final"
ANALYSIS_SIF="$COURSEDIR/containers/Annotation_analysis_R4.4.sif"

protein="assembly.all.maker.proteins.fasta"
transcript="assembly.all.maker.transcripts.fasta"

cd "$FINALDIR"

# Check the input files.
test -s filtered.genes.renamed.gff3
test -s "${protein}.renamed.fasta"
test -s "${transcript}.renamed.fasta"

# Avoid overwriting existing results.
for file in list.txt \
    "${transcript}.renamed.filtered.fasta" \
    "${protein}.renamed.filtered.fasta"
do
    if [ -e "$file" ]; then
        echo "Output already exists: $file" >&2
        exit 1
    fi
done

# Extract retained mRNA IDs using the course commands.
grep -P "\tmRNA\t" filtered.genes.renamed.gff3 \
    | awk '{print $9}' \
    | cut -d ';' -f1 \
    | sed 's/ID=//g' > list.txt

test -s list.txt

# Extract retained transcripts.
apptainer exec --cleanenv \
    --bind "$COURSEDIR" --bind "$WORKDIR" \
    --pwd "$FINALDIR" \
    "$ANALYSIS_SIF" \
    seqkit grep -f list.txt \
    "${transcript}.renamed.fasta" \
    -o "${transcript}.renamed.filtered.fasta"

# Extract retained proteins.
apptainer exec --cleanenv \
    --bind "$COURSEDIR" --bind "$WORKDIR" \
    --pwd "$FINALDIR" \
    "$ANALYSIS_SIF" \
    seqkit grep -f list.txt \
    "${protein}.renamed.fasta" \
    -o "${protein}.renamed.filtered.fasta"

# Count IDs and extracted sequences.
echo "Retained mRNA IDs:"
wc -l < list.txt

echo "Extracted transcripts:"
grep -c '^>' "${transcript}.renamed.filtered.fasta"

echo "Extracted proteins:"
grep -c '^>' "${protein}.renamed.filtered.fasta"