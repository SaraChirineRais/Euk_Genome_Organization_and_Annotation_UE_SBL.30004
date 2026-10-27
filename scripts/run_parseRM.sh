#!/bin/bash
#SBATCH --job-name=parseRM
#SBATCH --partition=pibu_el8
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=02:00:00
#SBATCH --account=class-sbl-30004-ws-2026
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err

# Run the course parseRM script on a filtered RepeatMasker file.
# Original EDTA files are preserved.
# Results are written to results/TE_annotation/parseRM_results/.

set -euo pipefail

WORKDIR=/data/users/srais/genome_annotation_course
COURSEDIR=/data/courses/genome_annotation_resources/2026
CONTAINER="$COURSEDIR/containers/Annotation_analysis_R4.4.sif"

INPUT="$WORKDIR/results/TE_annotation/EDTA/ERR11437324_Altai-5.fa.mod.EDTA.anno/ERR11437324_Altai-5.fa.mod.EDTA.RM.out"
PARSER="$WORKDIR/scripts/05-parseRM.pl"
OUTDIR="$WORKDIR/results/TE_annotation/parseRM_results"
FILTERED="$OUTDIR/ERR11437324_Altai-5.fa.mod.EDTA.RM.nonzero.out"

# Check the input file and parser.
test -s "$INPUT"
test -s "$PARSER"

# Create the output directory.
mkdir -p "$OUTDIR"

# Keep the header and remove records with zero percent divergence.
awk 'NR == 1 || $2 != 0' "$INPUT" > "$FILTERED"

# Run parseRM from the output directory.
cd "$OUTDIR"

apptainer exec -C \
    --bind "$WORKDIR" --bind "$COURSEDIR" \
    --pwd "$OUTDIR" \
    "$CONTAINER" \
    perl "$PARSER" -i "$FILTERED" -l 50,1 -v

echo "Results directory: $OUTDIR"