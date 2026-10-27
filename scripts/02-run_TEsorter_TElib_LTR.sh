#!/bin/bash
#SBATCH --job-name=TEsorter_intact_LTR
#SBATCH --partition=pibu_el8
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=04:00:00
#SBATCH --account=class-sbl-30004-ws-2026
#SBATCH --reservation=class-sbl-30004-2026-10-21
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err
set -euo pipefail
COURSEDIR=/data/courses/genome_annotation_resources/2026
WORKDIR=/data/users/srais/genome_annotation_course  # Directory in your /data/users/$USER/Folder.
# Use the intact-element FASTA
# Edit these two input paths to match your assembly's filename.
RAW="$WORKDIR/results/TE_annotation/EDTA"
# Expand the wildcard outside quotes;
shopt -s nullglob
FASTA=/data/users/srais/genome_annotation_course/results/TE_annotation/EDTA/ERR11437324_Altai-5.fa.mod.EDTA.TElib.fa


OUTDIR="$WORKDIR/results/TE_annotation/LTR_full_length"
unset SINGULARITY_BIND APPTAINER_BIND SINGULARITY_TMPDIR
mkdir -p "$OUTDIR/tmp"
# Work with copies so ongoing EDTA files are not changed.
cp "${FASTA[0]}" "$OUTDIR/TElib_LTR.fa"

cd "$OUTDIR"
apptainer exec -C --bind "$WORKDIR" --bind "$COURSEDIR" \
    --bind "$OUTDIR/tmp":/tmp --pwd "$OUTDIR" \
    "$COURSEDIR/containers/TEsorter_1.3.0.sif" \
    TEsorter TElib_LTR.fa -db rexdb-plant -p "$SLURM_CPUS_PER_TASK"
