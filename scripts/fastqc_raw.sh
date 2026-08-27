#!/bin/bash
# Description: Run FastQC on raw FASTQ files using 2 threads
set -e

# Unquote the tilde or use $HOME so Bash expands your home directory
BASE_DIR="$HOME/somatic_variant_calling"

RAW_DIR="$BASE_DIR/data/raw_fastq"
QC_DIR="$BASE_DIR/results/fastqc/raw"
LOG_DIR="$BASE_DIR/logs"

# Create output directory
mkdir -p "$QC_DIR"
mkdir -p "$LOG_DIR"

# Define log file
LOG_FILE="$LOG_DIR/fastqc_raw.log"

# Redirect stdout (1) and stderr (2) to the log file, while printing to terminal via tee
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=== Running FastQC on raw FASTQ files ==="
echo "Started at: $(date)"

fastqc "$RAW_DIR"/*.fastq.gz -o "$QC_DIR" -t 2

echo "Completed at: $(date)"
echo "=== FastQC analysis complete! Reports saved to $QC_DIR ==="
