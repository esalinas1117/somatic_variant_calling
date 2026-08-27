#!/bin/bash
# Description: Download GRCh38 primary assembly reference genome and build BWA index
set -e

BASE_DIR="$HOME/somatic_variant_calling"
REF_DIR="$BASE_DIR/data/reference"
LOG_DIR="$BASE_DIR/logs"

mkdir -p "$REF_DIR"
mkdir -p "$LOG_DIR"

LOG_FILE="$LOG_DIR/download_ref.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=== Reference Genome Setup: GRCh38 Whole Genome ==="
echo "Started at: $(date)"

REF_FASTA="$REF_DIR/GRCh38.primary_assembly.genome.fa"
URL="https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_44/GRCh38.primary_assembly.genome.fa.gz"

# Step 1: Download FASTA if not present
if [ ! -f "$REF_FASTA" ]; then
    echo "Downloading GRCh38 primary assembly FASTA from GENCODE..."
    wget -O "${REF_FASTA}.gz" "$URL"
    echo "Uncompressing reference FASTA..."
    gunzip "${REF_FASTA}.gz"
else
    echo "Reference FASTA already exists at $REF_FASTA. Skipping download."
fi

# Step 2: Index with BWA
if [ ! -f "${REF_FASTA}.bwt" ]; then
    echo "Building BWA index (this will take ~1 to 1.5 hours)..."
    bwa index "$REF_FASTA"
else
    echo "BWA index already exists. Skipping bwa index."
fi

echo "Completed at: $(date)"
echo "=== BWA Reference Indexing Complete! ==="
