#!/bin/bash
#SBATCH --job-name=maker_extract_gene_features
#SBATCH --partition=pibu_el8
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=00:30:00
#SBATCH --account=class-sbl-30004-ws-2026
#SBATCH --reservation=class-sbl-30004-2026-10-28
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err

# Extract gene features from the quality-filtered MAKER GFF.
# Keep gene, mRNA, exon, CDS and UTR features.
# Preserve the input and count the retained genes.

# Keep gene features and subfeatures as specified in the course guide.
# Input: quality-filtered MAKER GFF.
# Output: output/MAKER/final/filtered.genes.renamed.gff3

set -euo pipefail

WORKDIR=/data/users/srais/genome_annotation_course
FINALDIR="$WORKDIR/output/MAKER/final"

INPUT="$FINALDIR/assembly.all.maker.noseq.gff_iprscan_quality_filtered.gff"
OUTPUT="$FINALDIR/filtered.genes.renamed.gff3"

test -s "$INPUT"

# Avoid overwriting an existing result.
if [ -e "$OUTPUT" ]; then
    echo "Output already exists: $OUTPUT" >&2
    exit 1
fi

cd "$FINALDIR"

# Select the feature types specified in the course guide.
grep -P "\tgene\t|\tCDS\t|\texon\t|\tfive_prime_UTR\t|\tthree_prime_UTR\t|\tmRNA\t" \
    "$INPUT" > "$OUTPUT"

# Add the GFF3 header.
sed -i '1i##gff-version 3' "$OUTPUT"

# Check the retained feature types.
cut -f3 "$OUTPUT" | sort | uniq

# Count retained genes.
echo "Number of retained genes:"
grep -cP "\tgene\t" "$OUTPUT"