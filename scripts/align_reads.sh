#!/bin/bash
# Description: Align Normal and Tumor FASTQ reads to GRCh38 using BWA-MEM (Raw SAM output)
set -euo pipefail

BASE_DIR="$HOME/somatic_variant_calling"
REF="$BASE_DIR/data/reference/GRCh38.primary_assembly.genome.fa"
FASTQ_DIR="$BASE_DIR/data/raw_fastq"
ALIGNED_DIR="$BASE_DIR/data/aligned"
LOG_DIR="$BASE_DIR/logs"

mkdir -p "$ALIGNED_DIR"

LOG_FILE="$LOG_DIR/align_reads.log"
exec > >(tee -a "$LOG_FILE") 2>&1

# Auto-detect available CPU threads
THREADS=$(nproc)
if [ "$THREADS" -gt 2 ]; then
    BWA_THREADS=$((THREADS - 1))
else
    BWA_THREADS=$THREADS
fi

echo "=== Starting Read Alignment (BWA-MEM) ==="
echo "Execution time: $(date)"
echo "Utilizing CPU threads: $BWA_THREADS"

# Function to run bwa mem alignment to SAM format
align_sample() {
    local sample_name=$1
    local r1_file=$2
    local r2_file=$3
    local read_group=$4
    
    local output_sam="$ALIGNED_DIR/${sample_name}.sam"

    echo "----------------------------------------"
    echo "Processing sample: ${sample_name}"
    echo "Input R1: ${r1_file}"
    echo "Input R2: ${r2_file}"
    echo "Output SAM: ${output_sam}"

    if [ ! -f "$output_sam" ]; then
        bwa mem -M -t "$BWA_THREADS" -R "$read_group" "$REF" "$r1_file" "$r2_file" > "$output_sam"
        echo "Alignment complete for ${sample_name}."
    else
        echo "SAM file already exists for ${sample_name}. Skipping alignment."
    fi
}

# 1. Align Normal Sample
align_sample \
    "normal" \
    "$FASTQ_DIR/normal_R1.fastq.gz" \
    "$FASTQ_DIR/normal_R2.fastq.gz" \
    "@RG\tID:HCMCWDRX2.1\tSM:NORMAL\tLB:SRX25330419\tPL:ILLUMINA\tPU:HCMCWDRX2.1.SRR29788251"

# 2. Align Tumor Sample
align_sample \
    "tumor" \
    "$FASTQ_DIR/tumor_R1.fastq.gz" \
    "$FASTQ_DIR/tumor_R2.fastq.gz" \
    "@RG\tID:HCLTMDSX3.1\tSM:TUMOR\tLB:SRX25330418\tPL:ILLUMINA\tPU:HCLTMDSX3.1.SRR29788252"

echo "----------------------------------------"
echo "Execution completed at: $(date)"
echo "=== BWA-MEM Alignment Complete ==="
